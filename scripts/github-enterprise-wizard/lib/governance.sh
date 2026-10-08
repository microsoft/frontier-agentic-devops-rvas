#!/usr/bin/env bash

WIZARD_GOVERNANCE_LIB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WIZARD_GOVERNANCE_ROOT=$(cd "$WIZARD_GOVERNANCE_LIB_DIR/.." && pwd)

wizard_governance_catalog() {
  jq . "$WIZARD_GOVERNANCE_ROOT/governance.json"
}

wizard_governance_profile_values() {
  local profile="$1"
  jq -ce --arg profile "$profile" '
    def expand($profiles; $name):
      $profiles[$name] as $profile |
      if $profile == null then error("unknown governance profile: " + $name)
      elif ($profile.inherits // "") == "" then $profile.values
      else (expand($profiles; $profile.inherits) * $profile.values)
      end;
    expand(.profiles; $profile)
  ' "$WIZARD_GOVERNANCE_ROOT/governance.json"
}

wizard_governance_profile_choices() {
  jq -c '
    [.profiles | to_entries[] |
      {value:.key,label:.value.label,description:.value.description}]
  ' "$WIZARD_GOVERNANCE_ROOT/governance.json"
}

wizard_governance_enterprise_scopes() {
  jq -cn '[
    {value:"repository_management",label:"Repository management",description:"Repository creation, visibility, collaborator, forking, deletion, transfer, and default-branch policy."},
    {value:"identity",label:"Identity",description:"Enterprise authentication, managed-user, two-factor, and offboarding controls."},
    {value:"network",label:"Network",description:"IP allow lists and supported network-access policy."},
    {value:"actions",label:"Actions",description:"Actions policy, workflow permissions, fork safeguards, runners, retention, and cache."},
    {value:"audit",label:"Audit",description:"Audit export, event visibility, and supported streaming controls."},
    {value:"applications",label:"Applications",description:"OAuth App, GitHub App, and installation governance."},
    {value:"pat",label:"Personal access tokens",description:"Classic and fine-grained PAT policy."},
    {value:"codespaces",label:"Codespaces",description:"Codespaces access and supported enterprise constraints."},
    {value:"custom_properties",label:"Custom properties",description:"Enterprise repository metadata schemas."},
    {value:"rulesets",label:"Rulesets",description:"Enterprise repository and push rulesets."},
    {value:"offboarding",label:"Offboarding",description:"Removal of users who leave their last organization."},
    {value:"copilot",label:"Copilot",description:"Enterprise Copilot sources and protective policy."}
  ]'
}

wizard_governance_expand_profile() {
  local config="$1" profile="$2" values
  values="$(wizard_governance_profile_values "$profile")" || return 1
  jq -cn --argjson config "$config" --arg profile "$profile" --argjson values "$values" '
    $config
    | .enterprise.governance_profile = $profile
    | .enterprise.policies = (($values.enterprise // {}) * (.enterprise.policies // {}))
    | .defaults = (($values.defaults // {}) * (.defaults // {}))
    | .organizations |= map(
        .collaborators = (($values.organization.collaborators // {}) * (.collaborators // {}))
        | .repository_defaults = (($values.defaults.repository // {}) * (.repository_defaults // {})))
  '
}

wizard_governance_effective_config() {
  local config="$1"
  jq -cn --argjson config "$config" '
    def control($id;$scope;$subject;$desired;$effective;$source;$locked;$contributors;$warnings):
      {control:$id,scope:$scope,subject:$subject,desired:$desired,effective:$effective,
       source:$source,locked:$locked,contributors:$contributors,warnings:$warnings};
    [
      control("repository.creation";"enterprise";$config.enterprise.slug;
        $config.enterprise.policies.repository.member_repository_creation;
        $config.enterprise.policies.repository.member_repository_creation;
        "enterprise";false;[];[]),
      control("repository.user_namespace_creation";"enterprise";$config.enterprise.slug;
        $config.enterprise.policies.repository.user_namespace_repository_creation;
        (if $config.enterprise.identity=="emu"
         then $config.enterprise.policies.repository.user_namespace_repository_creation
         else "not_applicable" end);
        "enterprise";false;[];
        (if $config.enterprise.identity!="emu" and
            $config.enterprise.policies.repository.user_namespace_repository_creation=="blocked"
         then ["Blocking user-namespace repositories is an EMU-only enterprise control."]
         else [] end))
    ] +
    [$config.organizations[] as $org |
      control("repository.visibility_changes";"organization";$org.login;
        ($org.settings.members_can_change_repo_visibility //
          $config.defaults.settings.members_can_change_repo_visibility // false);
        ($org.settings.members_can_change_repo_visibility //
          $config.defaults.settings.members_can_change_repo_visibility // false);
        "organization";false;
        ["enterprise.repository.creation","organization.repository.visibility_changes"];
        (if ($org.settings.members_can_create_public_repositories //
              $config.defaults.settings.members_can_create_public_repositories // false)==false and
            ($org.settings.members_can_change_repo_visibility //
              $config.defaults.settings.members_can_change_repo_visibility // false)==true
         then ["Public creation is disabled, but repository administrators may still change existing visibility."]
         else [] end)),
      control("repository.base_permission";"organization";$org.login;
        ($org.settings.default_repository_permission //
          $config.defaults.settings.default_repository_permission // "read");
        ($org.settings.default_repository_permission //
          $config.defaults.settings.default_repository_permission // "read");
        "organization";false;
        ["enterprise.repository.base_permission","organization.default_repository_permission"];
        (if ($org.collaborators.teams_first // true) and
            (($org.settings.default_repository_permission //
              $config.defaults.settings.default_repository_permission // "read") | IN("write","admin"))
         then ["Teams-first access conflicts with broad ambient write permission."]
         else [] end)),
      control("repository.collaborators";"organization";$org.login;
        $org.collaborators;
        $org.collaborators;
        "organization";false;
        ["base_permission","team_grants","direct_grants","outside_collaborators"];
        (if ($org.collaborators.teams_first // true) and
            ($org.collaborators.direct_collaborators // "restricted")=="allowed"
         then ["Teams-first access still permits direct repository collaborators."]
         else [] end)),
      control("actions.workflow_token";"organization";$org.login;
        ($org.actions.workflow_permissions // null);
        ($org.actions.workflow_permissions // null);
        "organization";false;
        ["enterprise.actions.permissions","organization.actions.workflow_permissions"];
        (if (($org.actions.workflow_permissions.default_workflow_permissions // "read")=="write")
         then ["The default workflow token has write permission."]
         else [] end)),
      control("actions.cache";"organization";$org.login;
        {retention_days:($org.actions.cache_retention_days // null),
         storage_gb:($org.actions.cache_size_gb // null)};
        {retention_days:($org.actions.cache_retention_days //
            $config.enterprise.policies.actions.cache_retention_days // null),
         storage_gb:($org.actions.cache_size_gb //
            $config.enterprise.policies.actions.cache_size_gb // null)};
        "organization";false;
        ["enterprise.actions.cache","organization.actions.cache"];
        ((if ($org.actions.cache_retention_days // 0) >
              ($config.enterprise.policies.actions.cache_retention_days // 999999)
           then ["Organization cache retention exceeds the enterprise ceiling."] else [] end) +
         (if ($org.actions.cache_size_gb // 0) >
              ($config.enterprise.policies.actions.cache_size_gb // 999999)
           then ["Organization cache storage exceeds the enterprise ceiling."] else [] end)))
    ] +
    [$config.organizations[] as $org | $org.repositories[]? as $repo |
      control("enforcement.stack";"repository";($org.login+"/"+$repo.name);
        {rulesets:($repo.rulesets // []),environments:($repo.environments // [])};
        {rulesets:($repo.rulesets // []),environments:($repo.environments // [])};
        "stacked";false;
        (([$repo.rulesets[]?.name] + [$repo.environments[]?.name]) | map(select(. != null)));
        (if (($repo.rulesets // [])|length)>1
         then ["Multiple repository rulesets apply independently; verify overlapping rules and bypass lists."]
         else [] end))
    ] | flatten
  '
}
