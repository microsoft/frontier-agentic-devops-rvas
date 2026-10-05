#!/usr/bin/env bash

# Enterprise policies use the first configured organization as the action scope.
# The API paths remain enterprise-scoped.
wizard_enterprise_actions() {
  local config
  config="$1"
  jq -cn --argjson config "$config" '
    ($config.organizations[0]) as $anchor |
    ($config.enterprise.slug) as $enterprise |
    ($config.enterprise.policies // null) as $p |
    def base($resource;$kind;$deps):
      {id:("enterprise:policy:"+$resource),package:"enterprise",org:$anchor.login,kind:$kind,depends_on:$deps};
    def ensure($resource;$path;$body;$desired;$deps;$method):
      base($resource;"ensure";$deps)+{
        read_path:$path,desired:$desired,adopt:true,
        update:{method:$method,path:$path,body:$body}
      };
    def manual($resource;$owner;$source;$message;$deps):
      base($resource;"manual";$deps)+{owner:$owner,source:$source,message:$message};
    def report($resource;$path;$paginate;$deps):
      base($resource;"report";$deps)+{read_path:$path,paginate:$paginate};
    if $p == null then empty else
      manual("repository-policy";"enterprise owner";
        "https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-repository-management-policies-in-your-enterprise";
        ("Apply the recorded enterprise repository policy: default branch "+$p.repository.default_branch+
         ", base permission "+$p.repository.base_permission+
         ", member creation "+$p.repository.member_repository_creation+
         ", public creation "+($p.repository.public_repository_creation|tostring)+
         ", and owner-controlled invitations, visibility changes, deletion, and transfer. Verify organization overrides before attesting.");
        []),
      report("pat-inventory";"/enterprises/"+$enterprise+"/personal-access-tokens?per_page=100";true;[]),
      report("pat-requests";"/enterprises/"+$enterprise+"/personal-access-token-requests?per_page=100";true;[]),
      (if $p.pat.enforcement_confirmed then
        manual("pat-policy";"enterprise owner";
          "https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-personal-access-tokens-in-your-enterprise";
          ("The operator confirmed the PAT enforcement risk. Block classic PAT access, require administrator approval for fine-grained PATs, and set a maximum lifetime of "+
           ($p.pat.maximum_lifetime_days|tostring)+" days. Review the exported token and request inventories before applying the policy in enterprise settings.");
          ["enterprise:policy:pat-inventory","enterprise:policy:pat-requests"])
       else empty end),
      (if any($config.organizations[];
          ((.packages // $config.defaults.packages // [])|index("actions")) != null) then
        ensure("actions-permissions";"/enterprises/"+$enterprise+"/actions/permissions";
          $p.actions.permissions;$p.actions.permissions;[];"PUT"),
        ensure("actions-selected";"/enterprises/"+$enterprise+"/actions/permissions/selected-actions";
          $p.actions.selected_actions;$p.actions.selected_actions;["enterprise:policy:actions-permissions"];"PUT"),
        ensure("actions-workflow";"/enterprises/"+$enterprise+"/actions/permissions/workflow";
          $p.actions.workflow_permissions;$p.actions.workflow_permissions;["enterprise:policy:actions-permissions"];"PUT"),
        ensure("actions-retention";"/enterprises/"+$enterprise+"/actions/permissions/artifact-and-log-retention";
          {days:$p.actions.retention_days};{days:$p.actions.retention_days};["enterprise:policy:actions-permissions"];"PUT"),
        ensure("actions-fork-approval";"/enterprises/"+$enterprise+"/actions/permissions/fork-pr-contributor-approval";
          {approval_policy:$p.actions.fork_approval_policy};{approval_policy:$p.actions.fork_approval_policy};
          ["enterprise:policy:actions-permissions"];"PUT"),
        ensure("actions-private-forks";"/enterprises/"+$enterprise+"/actions/permissions/fork-pr-workflows-private-repos";
          $p.actions.private_fork_workflows;$p.actions.private_fork_workflows;
          ["enterprise:policy:actions-permissions"];"PUT"),
        ensure("actions-repository-runners";"/enterprises/"+$enterprise+"/actions/permissions/self-hosted-runners";
          {disable_self_hosted_runners_for_all_orgs:$p.actions.disable_repository_runners};
          {disable_self_hosted_runners_for_all_orgs:$p.actions.disable_repository_runners};
          ["enterprise:policy:actions-permissions"];"PUT"),
        manual("actions-cache";"enterprise Actions owner";
          "https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/enforcing-policies-for-github-actions-in-your-enterprise";
          ("Set Actions cache retention to "+($p.actions.cache_retention_days|tostring)+
           " days and the repository cache limit to "+($p.actions.cache_size_gb|tostring)+
           " GB. Review high-usage repositories before lowering existing limits.");
          ["enterprise:policy:actions-permissions"])
       else empty end),
      ($p.custom_properties[] as $property |
        ($property.property_name) as $name |
        ($property | del(.property_name)) as $body |
        ensure("property:"+$name;"/enterprises/"+$enterprise+"/properties/schema/"+$name;
          $body;$body;[];"PUT")+
          {create:{method:"PUT",path:("/enterprises/"+$enterprise+"/properties/schema/"+$name),body:$body}}),
      ($p.rulesets[] as $ruleset |
        ($ruleset |
          .conditions.org_name = .conditions.organization_name |
          del(.conditions.organization_name)) as $ruleset_body |
        ensure("ruleset:"+$ruleset.name;"/enterprises/"+$enterprise+"/rulesets";
          $ruleset_body;$ruleset;[];"PUT")+
          {lookup:{match:{name:$ruleset.name},detail_path:("/enterprises/"+$enterprise+"/rulesets/{id}")},
           create:{method:"POST",path:("/enterprises/"+$enterprise+"/rulesets"),body:$ruleset_body},
           update:{method:"PUT",path:("/enterprises/"+$enterprise+"/rulesets/{id}"),body:$ruleset_body}}),
      (if $p.audit.export then
        report("audit-export";"/enterprises/"+$enterprise+"/audit-log?include=all&per_page=100";true;[])
       else empty end),
      manual("audit-readiness";"enterprise audit owner";
        "https://docs.github.com/en/enterprise-cloud@latest/admin/monitoring-activity-in-your-enterprise";
        "Enable source-IP disclosure and API request events. Configure enterprise audit and Git-event streaming to a customer-managed receiver, keep receiver credentials outside the wizard, and verify delivery and alerting. Copilot usage-record streaming is intentionally excluded.";
        (if $p.audit.export then ["enterprise:policy:audit-export"] else [] end)),
      ($config.organizations[] as $o |
        (if (($o.packages // $config.defaults.packages // [])|index("actions")) != null then
          report("codespaces:"+$o.login;"/orgs/"+$o.login+"/codespaces?per_page=100";true;[$o.login+":workspace:organization"])
         else empty end)),
      (if $p.codespaces.enforcement_confirmed then
        ($config.organizations[] as $o |
          if (($o.packages // $config.defaults.packages // [])|index("actions")) != null then
            base("codespaces-access:"+$o.login;"request";["enterprise:policy:codespaces:"+$o.login])+
              {apply:{method:"PUT",path:("/orgs/"+$o.login+"/codespaces/access"),body:{visibility:"all_members"}},
               success_message:"GitHub accepted Codespaces access for all organization members."}
          else empty end),
        manual("codespaces-policy";"enterprise developer-platform owner";
          "https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization";
          ("The operator confirmed the Codespaces policy risk. Allow "+($p.codespaces.machine_types|map(tostring+"-core")|join(" and "))+
           " machines, private forwarded ports, a "+($p.codespaces.idle_timeout_minutes|tostring)+
           "-minute idle timeout, "+($p.codespaces.retention_days|tostring)+
           "-day retention, at most "+($p.codespaces.maximum_per_user|tostring)+
           " codespaces per user, and reviewed base images. Apply these constraints in each organization after reviewing billing and the exported inventory.");
          [$config.organizations[] as $o |
            if (($o.packages // $config.defaults.packages // [])|index("actions")) != null
            then "enterprise:policy:codespaces-access:"+$o.login else empty end])
       else empty end),
      (if $config.enterprise.identity=="personal" and $p.offboarding.enforcement_confirmed then
        manual("offboarding";"enterprise identity owner";
          "https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-your-enterprise/control-offboarding";
          "The operator confirmed the offboarding risk. Review direct enterprise roles, enterprise-team membership, and Copilot licenses, then disable unaffiliated users so people are removed after leaving their last organization.";
          [])
       else empty end),
      ($config.organizations[] as $o |
        if $p.applications.inventory then
          report("applications:"+$o.login;"/orgs/"+$o.login+"/installations?per_page=100";false;[$o.login+":workspace:organization"])
        else empty end),
      (if $p.applications.enforcement_confirmed then
        manual("application-policy";"enterprise application owner";
          "https://docs.github.com/en/enterprise-cloud@latest/admin/enforcing-policies/enforcing-policies-for-apps-in-your-enterprise";
          "The operator confirmed the application-policy risk. Require owner approval for OAuth and GitHub App requests, prevent repository administrators from installing apps without review, and review the installation inventory and requested permissions. Enabling OAuth restrictions can revoke existing app access and require replacement SSH or deploy keys.";
          (if $p.applications.inventory then [$config.organizations[] | "enterprise:policy:applications:"+.login] else [] end))
       else empty end),
      (if $config.enterprise.identity=="personal" and $p.authentication.enforcement_confirmed then
        ($config.organizations[] as $o |
          report("two-factor-readiness:"+$o.login;
            "/orgs/"+$o.login+"/members?filter=2fa_disabled&role=all&per_page=100";true;
            [$o.login+":workspace:organization"])),
        base("two-factor-authentication";"enterprise_setting";
          [$config.organizations[] | "enterprise:policy:two-factor-readiness:"+.login])+
          {setting:"two_factor_authentication_required",value:true}
       else empty end),
      (if ($p.copilot.source_organization // "") != "" then
        ($p.copilot.source_organization) as $source |
        ($config.organizations[] | select(.login==$source)) as $source_org |
        ([$source_org.repositories[]? | select((.name|ascii_downcase)==".github-private") | .name][0] // "") as $source_repo |
        base("copilot-agent-source";"copilot_source";
          ([$source+":workspace:organization"]+
           (if ($source_org.copilot.agents // []|length)>0 and $source_repo!=""
            then [$source+":copilot:files:"+$source_repo] else [] end)))+
          {read_path:("/enterprises/"+$enterprise+"/copilot/custom-agents/source"),
           source_organization:$source,create_ruleset:$p.copilot.create_protective_ruleset}
       else empty end)
    end
  '
}
