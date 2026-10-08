#!/usr/bin/env bash

wizard_actions_actions() {
  local config
  config="$1"
  jq -cn --argjson config "$config" '
    def ensure($id;$org;$deps;$path;$desired;$adopt;$create;$update):
      {id:$id,package:"actions",org:$org,kind:"ensure",depends_on:$deps,
       read_path:$path,desired:$desired,adopt:$adopt,required_scope:"actions"}
      + (if $create==null then {} else {create:$create} end)
      + (if $update==null then {} else {update:$update} end);
    def manual($id;$org;$deps;$message):
      {id:$id,package:"actions",org:$org,kind:"manual",depends_on:$deps,
       message:$message,owner:"org-owner"};
    def policy($org;$base;$id;$deps;$settings;$adopt):
      ($base |
        if startswith("/orgs/") then sub("^/orgs/";"/organizations/")
        else . end) as $cache_base |
      (if (($settings.permissions // {})|length)>0 then
        ensure($id+":permissions";$org;$deps;$base+"/permissions";$settings.permissions;$adopt;null;
          {method:"PUT",path:($base+"/permissions"),body:$settings.permissions})
      else empty end),
      (if (($settings.workflow_permissions // {})|length)>0 then
        ensure($id+":workflow-permissions";$org;$deps;$base+"/permissions/workflow";
          $settings.workflow_permissions;$adopt;null;
          {method:"PUT",path:($base+"/permissions/workflow"),body:$settings.workflow_permissions})
      else empty end),
      (if (($settings.selected_actions // {})|length)>0 then
        ensure($id+":selected-actions";$org;
          ($deps+if (($settings.permissions // {})|length)>0 then [$id+":permissions"] else [] end);
          $base+"/permissions/selected-actions";$settings.selected_actions;$adopt;null;
          {method:"PUT",path:($base+"/permissions/selected-actions"),body:$settings.selected_actions})
      else empty end),
      (if $settings.run_data_retention_days then
        ensure($id+":retention";$org;$deps;
          $base+"/permissions/artifact-and-log-retention";{days:$settings.run_data_retention_days};$adopt;null;
          {method:"PUT",path:($base+"/permissions/artifact-and-log-retention"),body:{days:$settings.run_data_retention_days}})
      else empty end),
      (if $settings.cache_retention_days then
        ensure($id+":cache-retention";$org;$deps;
          $cache_base+"/cache/retention-limit";
          {max_cache_retention_days:$settings.cache_retention_days};$adopt;
          {method:"PUT",path:($cache_base+"/cache/retention-limit"),
           body:{max_cache_retention_days:$settings.cache_retention_days}};
          {method:"PUT",path:($cache_base+"/cache/retention-limit"),
           body:{max_cache_retention_days:$settings.cache_retention_days}})
      else empty end),
      (if $settings.cache_size_gb then
        ensure($id+":cache-storage";$org;$deps;
          $cache_base+"/cache/storage-limit";
          {max_cache_size_gb:$settings.cache_size_gb};$adopt;
          {method:"PUT",path:($cache_base+"/cache/storage-limit"),
           body:{max_cache_size_gb:$settings.cache_size_gb}};
          {method:"PUT",path:($cache_base+"/cache/storage-limit"),
           body:{max_cache_size_gb:$settings.cache_size_gb}})
      else empty end);
    def workflows($r):
      ($r.workflows // []) as $selected |
      if ($selected|length)>0 then $selected
      elif ($r.stack=="node" or $r.stack=="python") then [{workflow:"ci.yml",ref:"main",inputs:{}}]
      else [] end;
    def files_exist($r):
      (($r.stack=="node" or $r.stack=="python") or
       (($r.files // [])|length)>0 or (($r.codeowners // [])|length)>0 or
       $r.devcontainer!=null or ($r.template==null and ($r.adopt // false)==false));
    def package_selected($o;$package):
      (($o.packages // $config.defaults.packages // [])|index($package))!=null;
    def security_ready_selected($o;$r):
      (($o.security // {})+($r.security // {})) as $s |
      package_selected($o;"security") and
      (($s.codeql!="advanced" and
        ($s.codeql=="default" or $r.code_scanning!=null or $s.code_scanning!=null) and
        (($r.code_scanning.state // $s.code_scanning.state // "configured")=="configured")) or
       ($s.codeql=="advanced" and
        ($r.stack=="node" or $r.stack=="python" or (($r.code_scanning.languages // [])|length)>0)));
    def quality_ready_selected($o;$r):
      (($o.quality // {})+($r.quality // {})) as $q |
      package_selected($o;"quality") and $q.state!="unconfigured" and
      (($q.enabled // false) or $q.state=="configured") and ($q.live_analysis // false);
    def capability_dependencies($o;$r;$ruleset):
      [if any($ruleset.rules[]?; .type=="code_scanning") and security_ready_selected($o;$r) then
         $o.login+":security:analysis-ready:"+$r.name
       else empty end,
       if any($ruleset.rules[]?; .type=="code_quality" or .type=="code_coverage") and quality_ready_selected($o;$r) then
         $o.login+":quality:setup:"+$r.name,
         $o.login+":quality:analysis:"+$r.name
       else empty end];
    def gates($org;$base;$prefix;$deps;$rulesets;$adopt;$ref;$o;$repositories):
      ($rulesets // [])[] as $ruleset |
      ($ruleset.id // $ruleset.name|tostring) as $key |
      (($base|startswith("/orgs/")) and
        (($ruleset.conditions.repository_name.include // []) as $names |
          (($names|length)>0 and
           all($names[]; . as $name | [$repositories[].name]|index($name)!=null))|not)) as $scope_unproven |
      (($ruleset.conditions.repository_property.include // [])+
        ($ruleset.conditions.repository_property.exclude // []) |
        map(select((.source // "custom")=="custom")|.name)|unique) as $target_properties |
      ($deps+[$repositories[] | capability_dependencies($o;.;$ruleset)[]]+
        [($o.property_schema // [])[] | .property_name as $name |
          select($target_properties|index($name)) | $org+":workspace:property-schema:"+$name]+
        [$repositories[] | select(any((.properties // {})|keys[]; . as $name | $target_properties|index($name))) |
          $org+":workspace:repo:"+.name+":properties"]|unique) as $prerequisites |
      (any($ruleset.rules[]?; .type=="code_scanning") and
        ($scope_unproven or any($repositories[]; security_ready_selected($o;.)|not))) as $security_pending |
      (any($ruleset.rules[]?; .type=="code_quality" or .type=="code_coverage") and
        ($scope_unproven or any($repositories[]; quality_ready_selected($o;.)|not))) as $quality_pending |
      any($ruleset.rules[]?; .type=="code_coverage") as $coverage_pending |
      ($ruleset.rules // [] | map(select(.type=="required_status_checks")) |
        [.[].parameters.required_status_checks[]?] | unique) as $checks |
      (if ($checks|length)>0 then [$prefix+":required-checks:"+$key] else [] end) as $checkdeps |
      ($ruleset|del(.id,.enforcement_approved) |
        if $adopt and ($ruleset.enforcement_approved // false|not) and .enforcement!="evaluate" then
          .enforcement="disabled"
        else . end) as $body |
      (if ($checks|length)>0 and ($base|startswith("/repos/")) then
        ensure($prefix+":required-checks:"+$key;$org;$prerequisites;
          $base+"/commits/"+($ref|@uri)+"/check-runs?filter=latest&per_page=100";
          {check_runs:($checks|map({name:.context,conclusion:"success",status:"completed"}
            + if (.integration_id // -1)>0 then {app:{id:.integration_id}} else {} end))};false;null;null)
       elif ($checks|length)>0 then
        manual($prefix+":required-checks:"+$key;$org;$prerequisites;
          "Verify successful required checks on every repository targeted by organization ruleset "+
          $ruleset.name+": "+($checks|map(.context)|join(", ")))
       else empty end),
      (if any($ruleset.rules[]?; .type=="workflows") then
        manual($prefix+":workflow-identity:"+$key;$org;$prerequisites;
          "Verify support for workflow-identity rules and successful execution of the exact workflows selected in ruleset "+
          $ruleset.name+". A same-named status check does not prove workflow identity.")
      else empty end),
      (if $security_pending then
        manual($prefix+":security-readiness:"+$key;$org;$prerequisites;
          "Configure CodeQL analysis for every repository targeted by ruleset "+$ruleset.name+
          " and verify a completed analysis before enabling its code-scanning gate."+
          (if $scope_unproven then " Verify the full organization target scope, including repositories outside this configuration." else "" end))
      else empty end),
      (if $quality_pending then
        manual($prefix+":quality-readiness:"+$key;$org;$prerequisites;
          "Configure Code Quality for repositories targeted by ruleset "+$ruleset.name+
          " and verify a completed analysis before enabling quality gates. Setup inventory reports do not prove readiness."+
          (if $scope_unproven then " Verify the full organization target scope, including repositories outside this configuration." else "" end))
      else empty end),
      (if $coverage_pending then
        manual($prefix+":coverage-results:"+$key;$org;$prerequisites;
          "Upload real test coverage results for repositories targeted by ruleset "+$ruleset.name+
          " and verify that Code Quality accepted them. This wizard cannot prove uploaded coverage through its API adapters; the coverage gate remains pending.")
      else empty end),
      (ensure($prefix+":ruleset:"+$key;$org;
        ($prerequisites+(if $body.enforcement=="active" then $checkdeps+
          (if any($ruleset.rules[]?; .type=="workflows") then [$prefix+":workflow-identity:"+$key] else [] end)+
          (if $security_pending then [$prefix+":security-readiness:"+$key] else [] end)+
          (if $quality_pending then [$prefix+":quality-readiness:"+$key] else [] end)+
          (if $coverage_pending then [$prefix+":coverage-results:"+$key] else [] end)
          else [] end));
        ($base+"/rulesets"+if $ruleset.id then "/"+($ruleset.id|tostring) else "?includes_parents=false" end);
        $body;$adopt;
        (if $ruleset.id then null else {method:"POST",path:($base+"/rulesets"),body:$body} end);
        {method:"PUT",path:($base+"/rulesets/"+(if $ruleset.id then ($ruleset.id|tostring) else "{id}" end)),body:$body})
        + if $ruleset.id then {} else
          {lookup:{items_path:[],match:{name:$ruleset.name},detail_path:($base+"/rulesets/{id}")},paginate:true}
          end),
      (if $adopt and $ruleset.enforcement=="active" and ($ruleset.enforcement_approved // false|not) then
        manual($prefix+":enforce-ruleset:"+$key;$org;[$prefix+":ruleset:"+$key];
          "Review the staged ruleset "+$ruleset.name+" and successful prerequisite checks. Set enforcement_approved=true and approve a new plan to activate enforcement.")
      else empty end);
    $config.organizations[] | select((.packages // ["actions"])|index("actions")) | . as $o |
    $o.login as $org |
    ($org+":workspace:organization") as $oid |
    ($org+":actions:organization") as $aid |
    policy($org;"/orgs/"+$org+"/actions";$aid;[$oid];($o.actions // {});($o.update_scopes.actions // false)),
    (($o.actions.runner_groups // [])[] as $group |
      ($group|del(.id)) as $body |
      ($group.id // $group.name|tostring) as $key |
      ("/orgs/"+$org+"/actions/runner-groups") as $base |
      (ensure($aid+":runner-group:"+$key;$org;[$oid];
        ($base+if $group.id then "/"+($group.id|tostring) else "" end);$body;($o.update_scopes.actions // false);
        (if $group.id then null else {method:"POST",path:$base,body:$body} end);
        {method:"PATCH",path:($base+"/"+(if $group.id then ($group.id|tostring) else "{id}" end)),body:$body})
        + if $group.id then {} else {lookup:{items_path:["runner_groups"],match:{name:$group.name}},paginate:true} end),
      manual($aid+":runner-infrastructure:"+$key;$org;[$aid+":runner-group:"+$key];
        "Provision and register customer-managed runners for group "+$group.name+"; verify an approved workflow on those runners.")),
    (($o.repositories // [])[] as $r |
      ($org+"/"+$r.name) as $repo |
      ($org+":workspace:repo:"+$r.name) as $rid |
      ($org+":workspace:files:"+$r.name) as $fid |
      ($org+":actions:repo:"+$r.name) as $pid |
      (($r.adopt // false) and ($o.update_scopes.actions // false)) as $adopt |
      policy($org;"/repos/"+$repo+"/actions";$pid;[$rid];($r.actions // {});$adopt),
      (($r.environments // [])[] as $env |
        ($env|del(.name,.deployment_branch_policies,.can_admins_bypass)) as $body |
        ("/repos/"+$repo+"/environments/"+($env.name|@uri)) as $path |
        (ensure($pid+":environment:"+$env.name;$org;[$rid];$path;($body+{name:$env.name});$adopt;
          {method:"PUT",path:$path,body:$body};{method:"PUT",path:$path,body:$body})
          + {read_projection:"environment",merge_update:true}),
        (if $env|has("can_admins_bypass") then
          manual($pid+":environment-admin-bypass:"+$env.name;$org;[$pid+":environment:"+$env.name];
            "Set administrator bypass to "+($env.can_admins_bypass|tostring)+" for environment "+$env.name+
            " in GitHub environment protection settings.")
        else empty end),
        (($env.deployment_branch_policies // [])[] as $branch |
          (ensure($pid+":environment-branch:"+$env.name+":"+$branch.type+":"+$branch.name;
            $org;[$pid+":environment:"+$env.name];$path+"/deployment-branch-policies";$branch;$adopt;
            {method:"POST",path:($path+"/deployment-branch-policies"),body:$branch};
            {method:"PUT",path:($path+"/deployment-branch-policies/{id}"),body:$branch})
            + {lookup:{items_path:["branch_policies"],match:{name:$branch.name,type:$branch.type}},paginate:true}))),
      (workflows($r)|to_entries[] | .key as $index | .value as $w |
        {id:($pid+":workflow:"+($index|tostring)),package:"actions",org:$org,kind:"workflow",
         repo:$repo,workflow:($w.workflow // $w.name),ref:($w.ref // "main"),inputs:($w.inputs // {}),
         depends_on:([$rid]+if files_exist($r) then [$fid] else [] end
           + if ($adopt|not) and (files_exist($r) or $r.template!=null) then [$rid+":default-branch"] else [] end
           + if (($r.actions.permissions // {})|length)>0 then [$pid+":permissions"] else [] end
           + if (($r.actions.workflow_permissions // {})|length)>0 then [$pid+":workflow-permissions"] else [] end
           + if (($r.actions.selected_actions // {})|length)>0 then [$pid+":selected-actions"] else [] end
           + if (($o.actions.permissions // {})|length)>0 then [$aid+":permissions"] else [] end
           + if (($o.actions.workflow_permissions // {})|length)>0 then [$aid+":workflow-permissions"] else [] end
           + if (($o.actions.selected_actions // {})|length)>0 then [$aid+":selected-actions"] else [] end)}),
      gates($org;"/repos/"+$repo;$pid;
        ([$rid]+[workflows($r)|keys[] | $pid+":workflow:"+(.|tostring)]);
        $r.rulesets;$adopt;(workflows($r)|.[0].ref // "main");$o;[$r]),
      (if $r.oidc then
        manual($pid+":oidc";$org;
          ([$rid]+if $r.oidc.environment then [$pid+":environment:"+$r.oidc.environment] else [] end);
          "Configure "+$r.oidc.provider+" trust for repository "+$repo+
          ", environment "+$r.oidc.environment+", ref "+$r.oidc.ref+
          ". Restrict the audience and GitHub token subject; verify a customer-approved deployment. No cloud resources are provisioned.")
      else empty end)),
    gates($org;"/orgs/"+$org;$aid;
      ([$oid]+[($o.repositories // [])[] as $r | workflows($r)|keys[] |
        $org+":actions:repo:"+$r.name+":workflow:"+(.|tostring)]);
      $o.rulesets;($o.update_scopes.actions // false);"main";$o;($o.repositories // []))
  '
}
