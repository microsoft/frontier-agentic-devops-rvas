#!/usr/bin/env bash

wizard_workspace_templates() {
  local root
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)" || return
  jq -cn \
    --rawfile node_package "$root/node/package.json" \
    --rawfile node_source "$root/node/src/index.js" \
    --rawfile node_test "$root/node/test/index.test.js" \
    --rawfile node_build "$root/node/scripts/build.js" \
    --rawfile node_ci "$root/node/ci.yml" \
    --rawfile node_ignore "$root/node/gitignore" \
    --rawfile python_source "$root/python/starter.py" \
    --rawfile python_test "$root/python/test_starter.py" \
    --rawfile python_project "$root/python/pyproject.toml" \
    --rawfile python_ci "$root/python/ci.yml" \
    --rawfile python_ignore "$root/python/gitignore" \
    '{node:[{path:"package.json",content:$node_package},{path:"src/index.js",content:$node_source},
      {path:"test/index.test.js",content:$node_test},{path:"scripts/build.js",content:$node_build},
      {path:".github/workflows/ci.yml",content:$node_ci},{path:".gitignore",content:$node_ignore}],
      python:[{path:"starter.py",content:$python_source},{path:"test_starter.py",content:$python_test},
      {path:"pyproject.toml",content:$python_project},{path:".github/workflows/ci.yml",content:$python_ci},
      {path:".gitignore",content:$python_ignore}]}'
}

wizard_workspace_actions() {
  local config templates
  config="$1"
  templates="$(wizard_workspace_templates)" || return
  jq -cn --argjson config "$config" --argjson templates "$templates" '
    def ensure($id;$org;$deps;$path;$desired;$adopt;$create;$update):
      {id:$id,package:"workspace",org:$org,kind:"ensure",depends_on:$deps,
       read_path:$path,desired:$desired,adopt:$adopt,
       required_scope:(
         if ($id|contains(":team:") and contains(":repo:")) then "repository_access"
         elif ($id|contains(":team:") and contains(":member:")) then "teams"
         elif ($id|contains(":team:")) then "teams"
         elif ($id|contains(":owner:")) then "owners"
         elif ($id|contains(":repo:")) then "repository"
         else "organization_settings" end)}
      + (if $create == null then {} else {create:$create} end)
      + (if $update == null then {} else {update:$update} end);
    def manual($id;$org;$deps;$message):
      {id:$id,package:"workspace",org:$org,kind:"manual",depends_on:$deps,
       message:$message,owner:"org-owner"};
    $config.organizations[] | select((.packages // ["workspace"])|index("workspace")) | . as $o |
    $o.login as $org |
    ($org + ":workspace:organization") as $oid |
    (if (($o.settings // {})|length)>0 then
      ensure($org+":workspace:settings";$org;[$oid];"/orgs/"+$org;$o.settings;
        ($o.update_scopes.organization_settings // false);null;{method:"PATCH",path:("/orgs/"+$org),body:$o.settings})
    else empty end),
    (($o.property_schema // [])[] as $property |
      ($property|del(.property_name)) as $body |
      ("/orgs/"+$org+"/properties/schema/"+($property.property_name|@uri)) as $path |
      ensure($org+":workspace:property-schema:"+$property.property_name;$org;[$oid];
        $path;($body+{property_name:$property.property_name});($o.update_scopes.organization_settings // false);
        {method:"PUT",path:$path,body:$body};{method:"PUT",path:$path,body:$body})),
    (($o.owners // [])[] as $owner |
      if $config.enterprise.identity == "emu" then
        manual($org+":workspace:owner:"+$owner;$org;[$oid];
          "Assign enterprise-managed organization owner "+$owner+" through the identity provider; verify organization ownership.")
      else ensure($org+":workspace:owner:"+$owner;$org;[$oid];
        "/orgs/"+$org+"/memberships/"+$owner;{role:"admin",state:"active"};($o.update_scopes.owners // false);
        {method:"PUT",path:("/orgs/"+$org+"/memberships/"+$owner),body:{role:"admin"}};
        {method:"PUT",path:("/orgs/"+$org+"/memberships/"+$owner),body:{role:"admin"}})
      end),
    (($o.teams // [])[] as $t |
      ($org+":workspace:team:"+$t.slug) as $tid |
      ({name:$t.name} + ($t|{description,privacy,parent_team_id}|with_entries(select(.value!=null)))) as $body |
      ensure($tid;$org;[$oid];"/orgs/"+$org+"/teams/"+$t.slug;
        ($body|del(.parent_team_id));($o.update_scopes.teams // false);
        {method:"POST",path:("/orgs/"+$org+"/teams"),body:$body};
        {method:"PATCH",path:("/orgs/"+$org+"/teams/"+$t.slug),body:$body}),
      (($t.members // [])[] as $member |
        (if ($member|type)=="string" then {login:$member,role:"member"} else $member end) as $m |
        if $config.enterprise.identity=="emu" or ($t.idp_managed // false) then
          manual($tid+":member:"+$m.login;$org;[$tid];
            "Assign "+$m.login+" to team "+$t.slug+" through the identity provider; verify team membership.")
        else ensure($tid+":member:"+$m.login;$org;[$tid];
          "/orgs/"+$org+"/teams/"+$t.slug+"/memberships/"+$m.login;
          {role:($m.role // "member"),state:"active"};($o.update_scopes.teams // false);
          {method:"PUT",path:("/orgs/"+$org+"/teams/"+$t.slug+"/memberships/"+$m.login),body:{role:($m.role // "member")}};
          {method:"PUT",path:("/orgs/"+$org+"/teams/"+$t.slug+"/memberships/"+$m.login),body:{role:($m.role // "member")}})
        end),
      (($t.repositories // [])[] as $r |
        ensure($tid+":repository:"+$r.name;$org;[$tid,$org+":workspace:repo:"+$r.name];
          "/orgs/"+$org+"/teams/"+$t.slug+"/repos/"+$org+"/"+$r.name;
          {permissions:{($r.permission // "pull"):true}};($o.update_scopes.repository_access // false);
          {method:"PUT",path:("/orgs/"+$org+"/teams/"+$t.slug+"/repos/"+$org+"/"+$r.name),body:{permission:($r.permission // "pull")}};
          {method:"PUT",path:("/orgs/"+$org+"/teams/"+$t.slug+"/repos/"+$org+"/"+$r.name),body:{permission:($r.permission // "pull")}}))),
    (($o.repositories // [])[] as $r |
      ($org+"/"+$r.name) as $repo |
      ($org+":workspace:repo:"+$r.name) as $rid |
      ($org+":workspace:files:"+$r.name) as $fid |
      ($r.adopt // false) as $adopt |
      ({name:$r.name,visibility:($r.visibility // "private")}
        + ($r|{description,has_issues,has_projects,has_wiki,has_discussions,allow_squash_merge,allow_merge_commit,allow_rebase_merge,delete_branch_on_merge}
          |with_entries(select(.value!=null)))) as $body |
      (if $r.template and ($adopt|not) then {name:$r.name,visibility:"private"} else $body end) as $initial |
      ensure($rid;$org;[$oid];"/repos/"+$repo;$initial;$adopt;
        (if $r.template then
          {method:"POST",path:("/repos/"+$r.template+"/generate"),
           body:{owner:$org,name:$r.name,description:($r.description // ""),private:true,include_all_branches:false}}
        else {method:"POST",path:("/orgs/"+$org+"/repos"),body:($body+{auto_init:true})} end);
        {method:"PATCH",path:("/repos/"+$repo),body:$initial}),
      (if $r.template and ($adopt|not) then
        ensure($rid+":settings";$org;[$rid];"/repos/"+$repo;$body;false;null;
          {method:"PATCH",path:("/repos/"+$repo),body:$body})
      else empty end),
      (($templates[$r.stack // "none"] // [])
        + (if ($r.codeowners // []|length)>0 then
            [{path:".github/CODEOWNERS",content:
              (($r.codeowners|map(.pattern+" "+(.teams|map("@"+$org+"/"+.)|join(" ")))|join("\n"))+"\n")}]
           else [] end)
        + (if $r.devcontainer then [{path:($r.devcontainer.path // ".devcontainer/devcontainer.json"),content:$r.devcontainer.content}] else [] end)
        + ($r.files // [])
        | reduce .[] as $f ([]; map(select(.path!=$f.path))+[$f])
        | if length==0 and $r.template==null and ($r.adopt // false)==false then
            [{path:"README.md",content:("# "+$r.name+"\n")}]
          else . end) as $files |
      (if ($files|length)>0 then
        {id:$fid,package:"workspace",org:$org,kind:"files",repo:$repo,files:$files,adopt:$adopt,
         depends_on:([$rid]+(if $r.template and ($adopt|not) then [$rid+":settings"] else [] end)+[
           ($r.codeowners // [])[]?.teams[]? as $slug |
           $org+":workspace:team:"+$slug,
           (($o.teams // [])[] | select(.slug==$slug) |
            (.repositories // [])[] | select(.name==$r.name) |
            $org+":workspace:team:"+$slug+":repository:"+$r.name)])|unique}
        + (if $adopt then {} else {ref:"main"} end)
      else empty end),
      (if (($files|length)>0 or $r.template) and ($adopt|not) then
        ensure($rid+":default-branch";$org;
          ([$rid]+if ($files|length)>0 then [$fid] else [] end
            + if $r.template then [$rid+":settings"] else [] end);
          "/repos/"+$repo;{default_branch:($r.default_branch // "main")};$adopt;null;
          {method:"PATCH",path:("/repos/"+$repo),body:{default_branch:($r.default_branch // "main")}})
      else empty end),
      (($r.labels // [])[] as $label |
        ensure($rid+":label:"+$label.name;$org;[$rid];
          "/repos/"+$repo+"/labels/"+($label.name|@uri);$label;$adopt;
          {method:"POST",path:("/repos/"+$repo+"/labels"),body:$label};
          {method:"PATCH",path:("/repos/"+$repo+"/labels/"+($label.name|@uri)),body:$label})),
      (if (($r.properties // {})|length)>0 then
        ($r.properties|to_entries|map({property_name:.key,value:.value})) as $properties |
        (ensure($rid+":properties";$org;
          ([$rid]+[($o.property_schema // [])[] | .property_name as $name |
            select(($r.properties // {})|has($name)) | $org+":workspace:property-schema:"+$name]);
          "/repos/"+$repo+"/properties/values";{properties:$properties};$adopt;null;
          {method:"PATCH",path:("/repos/"+$repo+"/properties/values"),body:{properties:$properties}})
          + {read_projection:"properties"})
      else empty end),
      (($r.manual_handoffs // [])|to_entries[] |
        manual($rid+":handoff:"+(.key|tostring);$org;[$rid];.value.message)+
          (.value|{owner,source,control,recorded_at,accepted}))),
    (($o.manual_handoffs // [])|to_entries[] |
      manual($org+":workspace:handoff:"+(.key|tostring);$org;[$oid];.value.message)+
        (.value|{owner,source,control,recorded_at,accepted}))
  '
}
