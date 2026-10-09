def diagnostic_value:
  if type == "string" then
    if length > 160 or test("github_pat_|gh[pousr]_|AKIA[A-Z0-9]{16}|PRIVATE KEY|(?i:bearer\\s|token\\s*[=:]|password\\s*[=:]|secret\\s*[=:]|authorization\\s*[=:]|api[_-]?key\\s*[=:])|https?://[^/@\\s]+:[^/@\\s]+@")
    then "\"[REDACTED]\"" else tojson end
  elif type == "object" or type == "array" then
    "[" + type + ", " + (length | tostring) + " entries; contents omitted]"
  else tojson end;
def fail($where; $message): error("config " + $where + ": " + $message + "; input type=" + type);
def check($condition; $where; $message):
  if $condition then . else fail($where; $message) end;
def check_field($key; predicate; $where; $message):
  if has($key) and (.[$key] | predicate) then .
  else fail($where + "." + $key; $message + "; actual=" +
    (if has($key) then (.[$key] | diagnostic_value) else "[missing]" end) +
    "; actual type=" + (if has($key) then (.[$key] | type) else "missing" end)) end;
def keys_only($allowed; $where):
  check(type == "object"; $where; "expected an object")
  | check((keys - $allowed | length) == 0; $where; "unknown keys: " + ((keys - $allowed) | join(", ")));
def str: type == "string" and length > 0 and (test("[\u0000-\u001f]") | not);
def login: str and length <= 39 and test("^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$") and (contains("--") | not);
def user_login: str and length <= 100 and test("^[A-Za-z0-9][A-Za-z0-9_-]*$") and (contains("--") | not);
def slug: str and length <= 100 and test("^[A-Za-z0-9][A-Za-z0-9_-]*$");
def repo_name: str and length <= 100 and test("^[A-Za-z0-9_.-]+$") and . != "." and (contains("..") | not);
def strings: type == "array" and all(.[]; str) and length == (unique | length);
def logins: strings and all(.[]; user_login) and length == (map(ascii_downcase) | unique | length);
def enum($values): . as $v | $values | index($v) != null;
def optional($key; predicate): if has($key) then .[$key] | predicate else true end;
def packages:
  strings and all(.[]; enum(["workspace","actions","identity","copilot","security","quality","ghaw","migration","integrations","billing","audit","lifecycle","drift","publishing","release","license","innersource","vendors","lfs","sre"]));
def verification($where):
  keys_only(["status","source","checked_at","resource_id","message"]; $where)
  | check(.status | enum(["verified","missing","insufficient_permission","unavailable","unverified","manual_prerequisite"]); $where; "invalid verification status")
  | check(optional("source"; str) and optional("checked_at"; str)
      and optional("resource_id"; type == "string" or type == "number")
      and optional("message"; type == "string"); $where; "invalid verification evidence");
def update_scopes($where):
  keys_only(["organization_settings","owners","teams","repository_access","actions","identity","copilot","security","quality","ghaw","migration","integrations","billing","audit","lifecycle","drift","publishing","release","license","innersource","vendors","lfs","sre"]; $where)
  | check(all(.[]; type == "boolean"); $where; "update scopes must be booleans");
def enterprise_update_scopes($where):
  keys_only(["repository_management","identity","network","actions","audit","applications","pat","codespaces","custom_properties","rulesets","offboarding","copilot"]; $where)
  | check(all(.[]; type == "boolean"); $where; "enterprise update scopes must be booleans");
def path:
  str and (startswith("/") | not) and (test("(^|/)(\\.\\.|\\.git)(/|$)|\\\\") | not)
  and (test("^[A-Za-z]:|[?#%]") | not) and (contains("..") | not);
def no_literal_credentials:
  test("github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}") | not;
def unique_by_key($key): length == (map(.[$key] | ascii_downcase) | unique | length);
def property_name: str and length <= 75 and test("^[A-Za-z0-9_-]+$");
def property_value($schema):
  if . == null then true
  elif $schema.value_type == "multi_select" then
    strings and all(.[]; . as $value | ($schema.allowed_values | index($value)) != null)
  elif $schema.value_type == "true_false" then enum(["true","false"])
  elif $schema.value_type == "single_select" then
    str and (. as $value | ($schema.allowed_values | index($value)) != null)
  else type == "string" end;
def property_schema($where):
  check(type == "array"; $where; "property_schema must be an array")
  | map(keys_only(["property_name","value_type","required","default_value","allowed_values","description"]; $where)
    | check(.property_name | property_name; $where; "invalid property_name")
    | check(.value_type | enum(["string","single_select","multi_select","true_false"]); $where; "invalid property value_type")
    | check(optional("required"; type == "boolean") and optional("description"; type == "string") and optional("allowed_values"; strings and length <= 200); $where; "invalid property schema metadata")
    | check((if .value_type == "single_select" or .value_type == "multi_select" then has("allowed_values") and (.allowed_values | length) > 0 else has("allowed_values") | not end); $where; "select properties need allowed_values; other property types must omit them")
    | . as $schema
    | check(optional("default_value"; property_value($schema)); $where; "default_value does not match its property type or allowed values"))
  | check(unique_by_key("property_name"); $where; "duplicate property schemas");
def property_condition($where):
  keys_only(["include","exclude"]; $where)
  | reduce ["include","exclude"][] as $key
      (. ; if has($key) then .[$key] |= (
        check(type == "array"; $where; "property conditions must be arrays")
        | map(keys_only(["name","source","property_values"]; $where)
          | check(.name | property_name; $where; "invalid condition property name")
          | check(.property_values | strings; $where; "property_values must be strings")
          | check(optional("source"; enum(["custom","system"])); $where; "property source must be custom or system"))) else . end);
def credential_key:
  (enum(["secret_protection","secret_scanning","secret_scanning_push_protection","secret_scanning_non_provider_patterns","secret_scanning_ai_detection","secret_scanning_validity_checks","secret_scanning_generic_secrets","secret_scanning_delegated_alert_dismissal","secret_scanning_extended_metadata","secret_scanning_delegated_bypass","secret_scanning_delegated_bypass_options","send_write_tokens_to_workflows","send_secrets_and_variables"]) | not)
  and test("(^|_)(tokens?|passwords?|secrets?|credentials?|private_key|api_key|authorization)(_|$)|tokens?$|passwords?$|secrets?$|credentials?$|private[_-]?key$|api[_-]?key$|authorization$"; "i");
def settings($where):
  keys_only(["default_repository_permission","members_can_create_repositories","members_can_create_public_repositories","members_can_create_private_repositories","members_can_create_internal_repositories","members_can_fork_private_repositories","members_can_delete_repositories","members_can_change_repo_visibility","members_can_create_pages","members_can_create_public_pages","members_can_create_private_pages","web_commit_signoff_required"]; $where)
  | check(optional("default_repository_permission"; enum(["none","read","write","admin"])); $where; "invalid default_repository_permission")
  | check(all(to_entries[] | select(.key != "default_repository_permission"); .value | type == "boolean"); $where; "settings must be booleans");
def file($where):
  keys_only(["path","content"]; $where)
  | check_field("path"; path; $where; "invalid file path; expected a relative path without traversal, .git, or URL escapes")
  | check(.content | type == "string"; $where; "content must be a string")
  | check(.content | no_literal_credentials; $where; "literal GitHub credentials are forbidden; reference environment secrets instead");
def workflow($where):
  keys_only(["name","workflow","ref","inputs"]; $where)
  | check((.workflow // .name) | str; $where; "workflow name or workflow is required")
  | check(optional("name"; str) and optional("workflow"; str) and optional("ref"; path); $where; "invalid workflow")
  | check(optional("inputs"; type == "object" and all(.[]; type == "string")); $where; "workflow inputs must be strings");
def environment($where):
  keys_only(["name","wait_timer","reviewers","prevent_self_review","deployment_branch_policy","can_admins_bypass","deployment_branch_policies"]; $where)
  | check(.name | str; $where; "environment name is required")
  | check(optional("wait_timer"; type == "number" and floor == . and . >= 0 and . <= 43200); $where; "invalid wait_timer")
  | check(optional("prevent_self_review"; type == "boolean") and optional("can_admins_bypass"; type == "boolean"); $where; "invalid environment protection")
  | if has("reviewers") then .reviewers |= (check(type == "array" and length <= 6; $where; "at most six reviewers")
      | map(keys_only(["type","id"]; $where)
        | check(.type | enum(["User","Team"]); $where; "invalid reviewer type")
        | check(.id | type == "number" and floor == . and . > 0; $where; "invalid reviewer ID"))) else . end
  | if has("deployment_branch_policies") then .deployment_branch_policies |= (
      check(type == "array"; $where; "deployment_branch_policies must be an array")
      | map(keys_only(["name","type"]; $where)
        | check(.name | str; $where; "branch policy name is required")
        | check(.type | enum(["branch","tag"]); $where; "invalid branch policy type"))) else . end
  | if has("deployment_branch_policy") then .deployment_branch_policy |=
      (keys_only(["protected_branches","custom_branch_policies"]; $where)
       | check(.protected_branches | type == "boolean"; $where; "protected_branches must be boolean")
       | check(.custom_branch_policies | type == "boolean"; $where; "custom_branch_policies must be boolean")
       | check((.protected_branches and .custom_branch_policies) | not; $where; "choose one deployment branch policy"))
    else . end;
def options($where; $allowed):
  keys_only($allowed + ["owner","source"]; $where)
  | check(optional("owner"; user_login) and optional("source"; str); $where; "invalid owner or source")
  | check(all(.. | objects | keys[]; credential_key | not); $where; "credentials must stay outside configuration");
def actions($where):
  options($where; ["permissions","workflow_permissions","selected_actions","run_data_retention_days","cache_retention_days","cache_size_gb","runner_groups"])
  | check(optional("run_data_retention_days"; type == "number" and floor == . and . >= 1 and . <= 400); $where; "invalid run_data_retention_days")
  | check(optional("cache_retention_days"; type == "number" and floor == . and . >= 1 and . <= 365); $where; "invalid cache_retention_days")
  | check(optional("cache_size_gb"; type == "number" and floor == . and . >= 1 and . <= 10000); $where; "invalid cache_size_gb")
  | if has("permissions") then .permissions |= (
      keys_only(["enabled_repositories","enabled","allowed_actions","sha_pinning_required"]; $where + ".permissions")
      | check(optional("enabled_repositories"; enum(["all","none","selected"])) and optional("enabled"; type == "boolean") and optional("allowed_actions"; enum(["all","local_only","selected"])) and optional("sha_pinning_required"; type == "boolean"); $where; "invalid Actions permissions")) else . end
  | if has("workflow_permissions") then .workflow_permissions |= (
      keys_only(["default_workflow_permissions","can_approve_pull_request_reviews"]; $where)
      | check(optional("default_workflow_permissions"; enum(["read","write"])) and optional("can_approve_pull_request_reviews"; type == "boolean"); $where; "invalid workflow permissions")) else . end
  | if has("selected_actions") then .selected_actions |= (
      keys_only(["github_owned_allowed","verified_allowed","patterns_allowed"]; $where)
      | check(optional("github_owned_allowed"; type == "boolean") and optional("verified_allowed"; type == "boolean") and optional("patterns_allowed"; strings); $where; "invalid selected actions")) else . end
  | if has("runner_groups") then .runner_groups |= (
      check(type == "array"; $where; "runner_groups must be an array")
      | map(keys_only(["id","name","visibility","allows_public_repositories","restricted_to_workflows","selected_workflows"]; $where)
        | check(.name | str; $where; "runner group name is required")
        | check(optional("id"; type == "number" and floor == . and . > 0) and optional("visibility"; enum(["all","selected","private"])) and optional("allows_public_repositories"; type == "boolean") and optional("restricted_to_workflows"; type == "boolean") and optional("selected_workflows"; strings); $where; "invalid runner group"))) else . end;
def enterprise_actions($where):
  keys_only(["permissions","selected_actions","workflow_permissions","run_data_retention_days","fork_approval_policy","private_fork_workflows","disable_repository_runners","cache_retention_days","cache_size_gb"]; $where)
  | check(.permissions | type == "object"; $where; "enterprise Actions permissions are required")
  | .permissions |= (
      keys_only(["enabled_organizations","allowed_actions","sha_pinning_required"]; $where + ".permissions")
      | check(.enabled_organizations | enum(["all","none","selected"]); $where; "invalid enabled_organizations")
      | check(optional("allowed_actions"; enum(["all","local_only","selected"])) and optional("sha_pinning_required"; type == "boolean"); $where; "invalid enterprise Actions permissions"))
  | if has("selected_actions") then .selected_actions |= (
      keys_only(["github_owned_allowed","verified_allowed","patterns_allowed"]; $where + ".selected_actions")
      | check(optional("github_owned_allowed"; type == "boolean") and optional("verified_allowed"; type == "boolean") and optional("patterns_allowed"; strings); $where; "invalid enterprise selected actions")) else . end
  | if has("workflow_permissions") then .workflow_permissions |= (
      keys_only(["default_workflow_permissions","can_approve_pull_request_reviews"]; $where + ".workflow_permissions")
      | check(optional("default_workflow_permissions"; enum(["read","write"])) and optional("can_approve_pull_request_reviews"; type == "boolean"); $where; "invalid enterprise workflow permissions")) else . end
  | if has("private_fork_workflows") then .private_fork_workflows |= (
      keys_only(["run_workflows_from_fork_pull_requests","send_write_tokens_to_workflows","send_secrets_and_variables","require_approval_for_fork_pr_workflows"]; $where + ".private_fork_workflows")
      | check(all(.[]; type == "boolean"); $where; "private fork workflow settings must be boolean")) else . end
  | check(optional("run_data_retention_days"; type == "number" and floor == . and . >= 1 and . <= 400); $where; "invalid enterprise run_data_retention_days")
  | check(optional("fork_approval_policy"; enum(["first_time_contributors","first_time_contributors_new_to_github","all_external_contributors"])); $where; "invalid fork approval policy")
  | check(optional("disable_repository_runners"; type == "boolean"); $where; "invalid repository runner policy")
  | check(optional("cache_retention_days"; type == "number" and floor == . and . >= 1 and . <= 365); $where; "invalid cache retention")
  | check(optional("cache_size_gb"; type == "number" and floor == . and . >= 1 and . <= 10000); $where; "invalid cache size");
def enterprise_rulesets($where):
  check(type == "array"; $where; "rulesets must be an array")
  | map(keys_only(["name","target","enforcement","conditions","rules"]; $where)
      | check(.name | str; $where; "ruleset name is required")
      | check(.target | enum(["branch","tag","push"]); $where; "invalid enterprise ruleset target")
      | check(.enforcement | enum(["disabled","evaluate","active"]); $where; "invalid enterprise ruleset enforcement")
      | .conditions |= (
          keys_only(["organization_name","repository_name","repository_property","ref_name"]; $where + ".conditions")
          | check(has("organization_name"); $where; "enterprise rulesets need organization_name targeting")
          | .organization_name |= (
              keys_only(["include","exclude"]; $where)
              | check(.include | strings and length > 0; $where; "organization_name include is required")
              | check(optional("exclude"; strings); $where; "invalid organization exclusions"))
          | if has("repository_name") then .repository_name |= (
              keys_only(["include","exclude","protected"]; $where)
              | check(.include | strings and length > 0; $where; "repository_name include is required")
              | check(optional("exclude"; strings) and optional("protected"; type == "boolean"); $where; "invalid repository targeting")) else . end
          | if has("repository_property") then .repository_property |= property_condition($where) else . end
          | if has("ref_name") then .ref_name |= (
              keys_only(["include","exclude"]; $where)
              | check(.include | strings and length > 0; $where; "ref_name include is required")
              | check(optional("exclude"; strings); $where; "invalid ref exclusions")) else . end)
      | .rules |= (
          check(type == "array" and length > 0; $where; "enterprise ruleset needs rules")
          | map(keys_only(["type","parameters"]; $where)
            | check(.type | enum(["creation","update","deletion","required_linear_history","required_signatures","pull_request","required_status_checks","non_fast_forward","file_path_restriction","file_extension_restriction","max_file_size","code_scanning","code_quality"]); $where; "invalid enterprise rule type")
            | if has("parameters") then .parameters |= (
                check(type == "object"; $where; "rule parameters must be an object")
                | check(all(.. | objects | keys[]; credential_key | not); $where; "credentials are forbidden in rule parameters")) else . end)));
def enterprise_policies($where):
  keys_only(["repository","pat","network","audit","actions","codespaces","custom_properties","rulesets","offboarding","applications","authentication","copilot"]; $where)
  | .repository |= (
      keys_only(["default_branch","base_permission","member_repository_creation","public_repository_creation","user_namespace_repository_creation","outside_collaborator_invitations","direct_collaborators","visibility_changes","deletion","transfer","private_forking"]; $where + ".repository")
      | check(.default_branch | path; $where; "invalid default branch")
      | check(.base_permission | enum(["none","read","write","admin"]); $where; "invalid base permission")
      | check(.member_repository_creation | enum(["private_internal","private","disabled"]); $where; "invalid repository creation policy")
      | check(.public_repository_creation | type == "boolean"; $where; "public repository creation must be boolean")
      | check(.user_namespace_repository_creation | enum(["allowed","blocked"]); $where; "invalid user namespace repository policy")
      | check(.direct_collaborators | enum(["allowed","restricted","blocked"]); $where; "invalid direct collaborator policy")
      | check(.private_forking | enum(["allowed","disabled"]); $where; "invalid private forking policy")
      | check(all([.outside_collaborator_invitations,.visibility_changes,.deletion,.transfer][]; enum(["enterprise_owners","organization_owners"])); $where; "invalid repository administrator policy"))
  | .pat |= (
      keys_only(["classic_access","fine_grained_access","approval_required","maximum_lifetime_days","enforcement_confirmed"]; $where + ".pat")
      | check(.classic_access | enum(["blocked","restricted"]); $where; "invalid classic PAT policy")
      | check(.fine_grained_access | enum(["allowed","blocked"]); $where; "invalid fine-grained PAT policy")
      | check(.approval_required | type == "boolean"; $where; "PAT approval must be boolean")
      | check(.maximum_lifetime_days | type == "number" and floor == . and . >= 1 and . <= 366; $where; "invalid PAT lifetime")
      | check(.enforcement_confirmed | type == "boolean"; $where; "PAT enforcement confirmation is required"))
  | .network |= (
      keys_only(["ip_allow_list","idp_ip_allow_list","enforcement_confirmed"]; $where + ".network")
      | check(.ip_allow_list | enum(["disabled","review","required"]); $where; "invalid IP allow list policy")
      | check(.idp_ip_allow_list | enum(["manual","disabled"]); $where; "invalid identity-provider IP allow list policy")
      | check(optional("enforcement_confirmed"; type == "boolean"); $where; "invalid network enforcement confirmation"))
  | .audit |= (
      keys_only(["export","streaming","source_ip_disclosure","api_request_events"]; $where + ".audit")
      | check(all(.[]; type == "boolean"); $where; "audit settings must be boolean"))
  | .actions |= enterprise_actions($where + ".actions")
  | .codespaces |= (
      keys_only(["access","machine_types","port_visibility","idle_timeout_minutes","retention_days","maximum_per_user","approved_images_only","enforcement_confirmed"]; $where + ".codespaces")
      | check(.access | enum(["selected_organizations","all_organizations","disabled"]); $where; "invalid Codespaces access")
      | check(.machine_types | type == "array" and all(.[]; type == "number" and floor == . and . >= 2 and . <= 32) and length > 0; $where; "invalid Codespaces machine types")
      | check(.port_visibility | enum(["private","organization","public"]); $where; "invalid Codespaces port visibility")
      | check(.idle_timeout_minutes | type == "number" and floor == . and . >= 5 and . <= 240; $where; "invalid Codespaces idle timeout")
      | check(.retention_days | type == "number" and floor == . and . >= 0 and . <= 30; $where; "invalid Codespaces retention")
      | check(.maximum_per_user | type == "number" and floor == . and . >= 1 and . <= 20; $where; "invalid Codespaces user limit")
      | check(.approved_images_only | type == "boolean"; $where; "approved_images_only must be boolean")
      | check(.enforcement_confirmed | type == "boolean"; $where; "Codespaces enforcement confirmation is required"))
  | .custom_properties |= property_schema($where + ".custom_properties")
  | .rulesets |= enterprise_rulesets($where + ".rulesets")
  | .offboarding |= (
      keys_only(["remove_unaffiliated_users","impact_review_required","enforcement_confirmed"]; $where + ".offboarding")
      | check(all(.[]; type == "boolean"); $where; "offboarding settings must be boolean"))
  | .applications |= (
      keys_only(["oauth_app_requests","github_app_requests","repository_admin_installations","inventory","enforcement_confirmed"]; $where + ".applications")
      | check(all([.oauth_app_requests,.github_app_requests][]; enum(["approval_required","blocked","allowed"])); $where; "invalid application request policy")
      | check((.repository_admin_installations | type == "boolean") and (.inventory | type == "boolean") and (.enforcement_confirmed | type == "boolean"); $where; "invalid application policy"))
  | .authentication |= (
      keys_only(["require_two_factor","readiness_review_required","enforcement_confirmed"]; $where + ".authentication")
      | check(all(.[]; type == "boolean"); $where; "authentication settings must be boolean"))
  | .copilot |= (
      keys_only(["source_organization","create_protective_ruleset"]; $where + ".copilot")
      | check(optional("source_organization"; login) and (.create_protective_ruleset | type == "boolean"); $where; "invalid Copilot custom-agent source"));
def manual($where):
  check(type == "array"; $where; "manual_handoffs must be an array")
  | map(keys_only(["control","owner","source","recorded_at","accepted","message"]; $where)
      | check(.control | str; $where; "manual handoff control is required")
      | check(.owner | user_login; $where; "manual handoff owner is required")
      | check(.source | str; $where; "manual handoff source is required")
      | check(.recorded_at | str; $where; "manual handoff recorded_at is required")
      | check(.accepted | type == "boolean"; $where; "manual handoff acceptance is required")
      | check(.message | str; $where; "manual handoff message is required"));
def collaborator_policy($where):
  keys_only(["teams_first","direct_collaborators","outside_collaborators"]; $where)
  | check(.teams_first | type == "boolean"; $where; "teams_first must be boolean")
  | check(.direct_collaborators | enum(["allowed","restricted","blocked"]); $where; "invalid direct collaborator policy")
  | check(.outside_collaborators | enum(["allowed","owner_approval","blocked","idp_managed"]); $where; "invalid outside collaborator policy");
def repository_defaults($where):
  keys_only(["default_branch","has_issues","has_projects","has_wiki","has_discussions","allow_squash_merge","allow_merge_commit","allow_rebase_merge","delete_branch_on_merge"]; $where)
  | check(.default_branch | path; $where; "invalid default branch")
  | check(all(to_entries[] | select(.key!="default_branch"); .value | type=="boolean"); $where; "repository defaults must be booleans");
def project($where):
  keys_only(["number","title","owner","adopt","template","verification"]; $where)
  | check(.title | str; $where; "project title is required")
  | check(.owner | user_login; $where; "project owner is required")
  | check(.adopt | type=="boolean"; $where; "project adopt must be boolean")
  | check(optional("number"; type=="number" and floor==. and .>0) and optional("template"; str); $where; "invalid project")
  | check((.adopt and has("number")) or ((.adopt|not) and (has("number")|not)); $where; "adopted projects need a number; new projects must omit it")
  | if has("verification") then .verification |= verification($where + ".verification") else . end;
def rulesets($where):
  check(type == "array"; $where; "rulesets must be an array")
  | map(keys_only(["id","name","target","enforcement","enforcement_approved","conditions","rules","bypass_actors"]; $where)
      | check(.name | str; $where; "ruleset name is required")
      | check(optional("id"; type == "number" and floor == . and . > 0) and optional("target"; enum(["branch","tag","push"])) and optional("enforcement"; enum(["disabled","evaluate","active"])) and optional("enforcement_approved"; type == "boolean"); $where; "invalid ruleset")
      | if has("conditions") then .conditions |= (
          keys_only(["ref_name","repository_name","repository_id","repository_property"]; $where)
          | if has("repository_property") then .repository_property |= property_condition($where) else . end
          | if has("ref_name") then .ref_name |= (
              keys_only(["include","exclude"]; $where)
              | check(optional("include"; strings) and optional("exclude"; strings); $where; "invalid ref conditions")) else . end
          | if has("repository_name") then .repository_name |= (
              keys_only(["include","exclude","protected"]; $where)
              | check(optional("include"; strings) and optional("exclude"; strings) and optional("protected"; type == "boolean"); $where; "invalid repository conditions")) else . end
          | if has("repository_id") then .repository_id |= (
              keys_only(["repository_ids"]; $where)
              | check(.repository_ids | type == "array" and all(.[]; type == "number" and floor == . and . > 0); $where; "invalid repository IDs")) else . end) else . end
      | if has("rules") then .rules |= (
          check(type == "array"; $where; "rules must be an array")
          | map(keys_only(["type","parameters"]; $where)
            | check(.type | enum(["creation","update","deletion","required_linear_history","required_deployments","required_signatures","pull_request","required_status_checks","non_fast_forward","commit_message_pattern","commit_author_email_pattern","committer_email_pattern","branch_name_pattern","tag_name_pattern","file_path_restriction","max_file_path_length","file_extension_restriction","max_file_size","code_scanning","code_quality","code_coverage","copilot_code_review","workflows"]); $where; "invalid rule type")
            | if has("parameters") then .parameters |= (
                keys_only(["required_deployment_environments","dismiss_stale_reviews_on_push","require_code_owner_review","require_last_push_approval","required_approving_review_count","required_review_thread_resolution","allowed_merge_methods","required_status_checks","strict_required_status_checks_policy","do_not_enforce_on_create","name","negate","operator","pattern","restricted_file_paths","max_file_path_length","restricted_file_extensions","max_file_size","code_scanning_tools","severity","minimum_coverage","max_coverage_drop","review_draft_pull_requests","review_on_push","workflows"]; $where)
                | check(optional("required_deployment_environments"; strings) and optional("allowed_merge_methods"; strings) and optional("restricted_file_paths"; strings) and optional("restricted_file_extensions"; strings); $where; "invalid rule lists")
                | check(all(to_entries[] | select(.key | enum(["dismiss_stale_reviews_on_push","require_code_owner_review","require_last_push_approval","required_review_thread_resolution","strict_required_status_checks_policy","do_not_enforce_on_create","negate","review_draft_pull_requests","review_on_push"])); .value | type == "boolean"); $where; "invalid rule switches")
                | check(optional("severity"; enum(["errors","warnings","notes","all"])); $where; "invalid Code Quality severity")
                | check(optional("minimum_coverage"; type == "number" and . >= 0 and . <= 100) and optional("max_coverage_drop"; type == "number" and . >= 0 and . <= 100); $where; "coverage percentages must be between 0 and 100")
                | check(all(to_entries[] | select(.key | enum(["required_approving_review_count","max_file_path_length","max_file_size"])); .value | type == "number" and floor == . and . >= 0); $where; "invalid rule counts")
                | check(all(to_entries[] | select(.key | enum(["name","operator","pattern"])); .value | str); $where; "invalid rule pattern")
                | if has("required_status_checks") then .required_status_checks |= (
                    check(type == "array"; $where; "required_status_checks must be an array")
                    | map(keys_only(["context","integration_id"]; $where)
                      | check(.context | str; $where; "check context is required")
                      | check(optional("integration_id"; type == "number" and floor == . and . > 0); $where; "invalid integration_id"))) else . end
                | if has("code_scanning_tools") then .code_scanning_tools |= (
                    check(type == "array"; $where; "code_scanning_tools must be an array")
                    | map(keys_only(["tool","security_alerts_threshold","alerts_threshold"]; $where)
                      | check(.tool | str; $where; "scanning tool is required")
                      | check(optional("security_alerts_threshold"; enum(["none","critical","high_or_higher","medium_or_higher","all"])) and optional("alerts_threshold"; enum(["none","errors","errors_and_warnings","all"])); $where; "invalid scanning threshold"))) else . end
                | if has("workflows") then .workflows |= (
                    check(type == "array"; $where; "ruleset workflows must be an array")
                    | map(keys_only(["repository_id","path","ref"]; $where)
                      | check(.repository_id | type == "number" and floor == . and . > 0; $where; "workflow repository ID is required")
                      | check(.path | path; $where; "invalid workflow path")
                      | check(optional("ref"; path); $where; "invalid workflow ref"))) else . end) else . end)) else . end
      | if has("bypass_actors") then .bypass_actors |= (
          check(type == "array"; $where; "bypass_actors must be an array")
          | map(keys_only(["actor_id","actor_type","bypass_mode"]; $where)
            | check(.actor_type | enum(["Integration","OrganizationAdmin","RepositoryRole","Team","DeployKey"]); $where; "invalid bypass actor")
            | check((if .actor_type == "DeployKey" then .actor_id == null and (.bypass_mode // "always") == "always" else optional("actor_id"; type == "number" and floor == . and . > 0) end)
                and optional("bypass_mode"; enum(["always","pull_request"])); $where; "DeployKey bypass requires a null actor_id and always mode; other actor IDs must be positive")
            | check((.actor_type | enum(["Integration","RepositoryRole","Team"]) | not) or has("actor_id"); $where; "bypass actor ID is required"))) else . end);
def copilot($where):
  options($where; ["users","teams","instructions","agents","code_review","setup_steps","purchase","mcp","models","features"])
  | check(optional("users"; logins) and optional("teams"; strings); $where; "invalid seat recipients")
  | check(optional("purchase"; type == "boolean") and optional("code_review"; type == "boolean"); $where; "purchase/code_review must be boolean")
  | check(.purchase != true or ((.users // [] | length) + (.teams // [] | length) > 0); $where; "Copilot purchase needs explicit users or teams")
  | if has("mcp") then .mcp |= (
      keys_only(["enabled","approved_servers_only"]; $where + ".mcp")
      | check(optional("enabled"; type == "boolean") and optional("approved_servers_only"; type == "boolean"); $where; "invalid MCP policy")) else . end
  | if has("models") then .models |= (
      keys_only(["default_availability","kimi","fable"]; $where + ".models")
      | check(optional("default_availability"; type == "boolean") and optional("kimi"; type == "boolean") and optional("fable"; type == "boolean"); $where; "invalid model policy")) else . end
  | if has("features") then .features |= (
      keys_only(["github_com","cli","cloud_agent","code_review","review_effort","copilot_approvals","public_code_suggestions","feedback_collection","preview_features"]; $where + ".features")
      | check(optional("github_com"; type == "boolean") and optional("cli"; type == "boolean")
          and optional("cloud_agent"; enum(["all","selected","disabled"]))
          and optional("code_review"; type == "boolean")
          and optional("review_effort"; enum(["lite","balanced"]))
          and optional("copilot_approvals"; type == "boolean")
          and optional("public_code_suggestions"; enum(["allow","block"]))
          and optional("feedback_collection"; type == "boolean")
          and optional("preview_features"; type == "boolean"); $where; "invalid Copilot feature policy")) else . end
  | if has("instructions") then .instructions |= (check(type == "array"; $where; "instructions must be an array") | map(file($where))) else . end
  | if has("agents") then .agents |= (check(type == "array"; $where; "agents must be an array") | map(file($where))) else . end
  | if has("setup_steps") then .setup_steps |= file($where) else . end;
def security_settings($where):
  keys_only(["description","advanced_security","code_security","secret_protection","dependency_graph","dependency_graph_autosubmit_action","dependency_graph_autosubmit_action_options","dependabot_alerts","dependabot_security_updates","dependabot_delegated_alert_dismissal","code_scanning_options","code_scanning_default_setup","code_scanning_default_setup_options","code_scanning_delegated_alert_dismissal","secret_scanning","secret_scanning_push_protection","secret_scanning_delegated_bypass","secret_scanning_delegated_bypass_options","secret_scanning_validity_checks","secret_scanning_non_provider_patterns","secret_scanning_generic_secrets","secret_scanning_delegated_alert_dismissal","secret_scanning_extended_metadata","private_vulnerability_reporting","enforcement"]; $where)
  | check(optional("description"; type == "string") and optional("advanced_security"; enum(["enabled","disabled","code_security","secret_protection"])) and optional("enforcement"; enum(["enforced","unenforced"])); $where; "invalid security configuration metadata")
  | check(all(to_entries[] | select(.key | enum(["code_security","secret_protection","dependency_graph","dependency_graph_autosubmit_action","dependabot_alerts","dependabot_security_updates","dependabot_delegated_alert_dismissal","code_scanning_default_setup","code_scanning_delegated_alert_dismissal","secret_scanning","secret_scanning_push_protection","secret_scanning_delegated_bypass","secret_scanning_validity_checks","secret_scanning_non_provider_patterns","secret_scanning_generic_secrets","secret_scanning_delegated_alert_dismissal","secret_scanning_extended_metadata","private_vulnerability_reporting"])); .value | enum(["enabled","disabled","not_set"])); $where; "security configuration statuses must be enabled, disabled or not_set")
  | if has("dependency_graph_autosubmit_action_options") then .dependency_graph_autosubmit_action_options |= (
      keys_only(["labeled_runners"]; $where)
      | check(optional("labeled_runners"; type == "boolean"); $where; "labeled_runners must be boolean")) else . end
  | if has("code_scanning_options") and .code_scanning_options != null then .code_scanning_options |= (
      keys_only(["allow_advanced"]; $where)
      | check(optional("allow_advanced"; type == "boolean" or . == null); $where; "allow_advanced must be boolean or null")) else . end
  | if has("code_scanning_default_setup_options") and .code_scanning_default_setup_options != null then .code_scanning_default_setup_options |= (
      keys_only(["runner_type","runner_label"]; $where)
      | check(optional("runner_type"; enum(["standard","labeled","not_set"])) and optional("runner_label"; str or . == null); $where; "invalid CodeQL runner options")
      | check(.runner_type != "labeled" or (.runner_label | str); $where; "labeled CodeQL runners need runner_label")) else . end
  | if has("secret_scanning_delegated_bypass_options") then .secret_scanning_delegated_bypass_options |= (
      keys_only(["reviewers"]; $where)
      | if has("reviewers") then .reviewers |= (
          check(type == "array"; $where; "delegated bypass reviewers must be an array")
          | map(keys_only(["reviewer_id","reviewer_type","mode"]; $where)
            | check(.reviewer_id | type == "number" and floor == . and . > 0; $where; "reviewer_id must be positive")
            | check(.reviewer_type | enum(["TEAM","ROLE"]); $where; "reviewer_type must be TEAM or ROLE")
            | check(optional("mode"; enum(["ALWAYS","EXEMPT"])); $where; "invalid reviewer bypass mode"))) else . end) else . end;
def feature($name; $where):
  if $name == "identity" then
    options($where; ["require_two_factor"])
    | check(optional("require_two_factor"; type == "boolean"); $where; "invalid identity options")
  elif $name == "security" then
    options($where; ["dependency_graph","dependabot_alerts","dependabot_security_updates","secret_scanning","push_protection","code_scanning","codeql","configuration_id","configuration_name","settings","repository_id","purchase","campaigns","triage","dependency_review","security_and_analysis"])
    | check(all(to_entries[] | select(.key | enum(["dependency_graph","dependabot_alerts","dependabot_security_updates","secret_scanning","push_protection","purchase","triage","dependency_review"])); .value | type == "boolean"); $where; "security switches must be boolean")
    | check(optional("codeql"; enum(["none","default","advanced"])) and optional("configuration_id"; type == "number" and floor == . and . > 0) and optional("campaigns"; strings); $where; "invalid security options")
    | check(optional("repository_id"; type == "number" and floor == . and . > 0); $where; "invalid repository_id")
    | check(optional("configuration_name"; str); $where; "configuration_name must be nonempty")
    | check((has("settings") | not) or has("configuration_id") or has("configuration_name"); $where; "configuration settings need configuration_id or configuration_name")
    | if has("settings") then .settings |= security_settings($where + ".settings") else . end
    | if has("code_scanning") then .code_scanning |= (
        keys_only(["state","query_suite","languages"]; $where)
        | check(optional("state"; enum(["configured","not-configured"])) and optional("query_suite"; enum(["default","extended"])) and optional("languages"; strings); $where; "invalid CodeQL setup")) else . end
    | if has("security_and_analysis") then .security_and_analysis |= (
        keys_only(["advanced_security","code_security","secret_scanning","secret_scanning_push_protection","secret_scanning_non_provider_patterns","secret_scanning_ai_detection","secret_scanning_validity_checks"]; $where)
        | with_entries(.value |= (
            keys_only(["status"]; $where)
            | check(.status | enum(["enabled","disabled"]); $where; "invalid security status")))) else . end
  elif $name == "quality" then
    options($where; ["enabled","purchase","live_analysis","coverage","required_checks","enforce","state","languages"])
    | check(optional("enabled"; type == "boolean") and optional("purchase"; type == "boolean") and optional("live_analysis"; type == "boolean") and optional("enforce"; type == "boolean") and optional("coverage"; type == "number" and . >= 0 and . <= 100) and optional("required_checks"; strings); $where; "invalid quality options")
    | check(optional("state"; enum(["configured","not-configured"])) and optional("languages"; strings and all(.[]; enum(["csharp","go","java-kotlin","javascript-typescript","python","ruby"]))); $where; "invalid quality setup")
  elif $name == "ghaw" then
    if type == "array" then map(
      options($where; ["name","type","engine","model","auth_mode","run","output_limit"])
      | check(.name | repo_name; $where; "gh-aw workflow name is required")
      | check(.type | enum(["issue-triage","ci-doctor","docs","tests","review","summary"]); $where; "invalid gh-aw pilot")
      | check(optional("engine"; enum(["copilot","claude","codex"])) and optional("model"; str) and optional("auth_mode"; str) and optional("run"; type == "boolean") and optional("output_limit"; type == "number" and floor == . and . > 0 and . <= 20); $where; "invalid gh-aw options"))
      | check(unique_by_key("name"); $where; "duplicate gh-aw workflows")
    else options($where; ["pilots","engine","model","schedule","schedule_approved","run","output_limit"])
    | check(optional("pilots"; strings and all(.[]; enum(["issue-triage","ci-diagnosis","documentation","regression-tests","review-assistance","summaries"]))) and optional("engine"; enum(["copilot","claude","codex"])) and optional("model"; str) and optional("schedule"; str) and optional("schedule_approved"; type == "boolean") and optional("run"; type == "boolean") and optional("output_limit"; type == "number" and floor == . and . > 0 and . <= 20); $where; "invalid gh-aw options")
    | check((has("schedule") | not) or .schedule_approved == true; $where; "schedule requires explicit schedule_approved")
    end
  elif $name == "migration" then
    options($where; ["inventory"])
    | check(optional("inventory"; type == "boolean"); $where; "inventory must be boolean")
  elif $name == "integrations" then
    options($where; ["webhooks","apps"])
    | check(optional("apps"; strings); $where; "apps must be strings")
    | if has("webhooks") then .webhooks |= (
        check(type == "array"; $where; "webhooks must be an array")
        | map(keys_only(["id","name","url","events","active"]; $where)
          | check(.id | type == "number" and floor == . and . > 0; $where; "existing webhook ID is required")
          | check(optional("name"; str); $where; "invalid webhook name")
          | check(.url | str and test("^https://[^/?#@]+(/[^#]*)?$") and (test("[?&](token|password|secret|key)="; "i") | not); $where; "webhook URL must be HTTPS without credentials")
          | check(.events | strings and length > 0; $where; "webhook events are required")
          | check(optional("active"; type == "boolean"); $where; "webhook active must be boolean"))
        | check(length == (map(.id) | unique | length); $where; "duplicate webhook IDs")) else . end
  elif $name == "billing" then
    options($where; ["usage","budgets"])
    | check(optional("usage"; type == "boolean") and optional("budgets"; type == "boolean"); $where; "invalid billing options")
  elif $name == "audit" then
    options($where; ["export","streaming"])
    | check(optional("export"; type == "boolean") and optional("streaming"; type == "boolean"); $where; "invalid audit options")
  elif $name == "lifecycle" or $name == "drift" then
    options($where; ["inventory"])
    | check(optional("inventory"; type == "boolean"); $where; "inventory must be boolean")
  elif $name == "publishing" then
    options($where; ["pages","packages","files","container"])
    | check(optional("packages"; type == "boolean"); $where; "packages must be boolean")
    | if has("files") then .files |= (
        check(type == "array"; $where; "files must be an array")
        | map(file($where)) | check(unique_by_key("path"); $where; "duplicate file paths")) else . end
    | if has("container") then .container |= (
        keys_only(["context","dockerfile","run"]; $where)
        | check(.context | path; $where; "container context is required")
        | check(.dockerfile | path; $where; "customer Dockerfile path is required")
        | check(optional("run"; type == "boolean"); $where; "container run must be boolean")) else . end
    | if has("pages") and (.pages | type) == "object" then .pages |= (
        keys_only(["build_type","source"]; $where)
        | check(optional("build_type"; enum(["legacy","workflow"])); $where; "invalid Pages build_type")
        | if has("source") then .source |= (
            keys_only(["branch","path"]; $where)
            | check(.branch | path; $where; "Pages branch is required")
            | check(.path | enum(["/","/docs"]); $where; "Pages path must be / or /docs")) else . end)
      else check(optional("pages"; type == "boolean"); $where; "pages must be boolean or a Pages configuration") end
  elif $name == "vendors" then
    options($where; ["review"])
    | check(optional("review"; type == "boolean"); $where; "review must be boolean")
  else
    options($where; ["files"] + (if $name == "sre" then ["handoff"] elif $name == "lfs" then ["patterns"] elif $name == "license" then ["deny_licenses"] elif $name == "release" then ["run"] else [] end))
    | check(optional("handoff"; type == "boolean"); $where; "handoff must be boolean")
    | check(optional("run"; type == "boolean"); $where; "run must be boolean")
    | check(optional("patterns"; strings) and optional("deny_licenses"; strings); $where; "patterns/deny_licenses must be strings")
    | if has("files") then .files |= (
        check(type == "array"; $where; "files must be an array")
        | map(file($where)) | check(unique_by_key("path"); $where; "duplicate file paths")) else . end
  end;
def features($where):
  reduce ["identity","security","quality","ghaw","migration","integrations","billing","audit","lifecycle","drift","publishing","release","license","innersource","vendors","lfs","sre"][] as $name
    (. ; if has($name) then .[$name] |= feature($name; $where + "." + $name) else . end)
  | if has("actions") then .actions |= actions($where + ".actions") else . end
  | if has("copilot") then .copilot |= copilot($where + ".copilot") else . end;
def repository($where):
  keys_only(["name","adopt","verification","visibility","stack","template","files","labels","properties","environments","workflows","copilot_users","description","default_branch","has_issues","has_projects","has_wiki","has_discussions","delete_branch_on_merge","allow_squash_merge","allow_merge_commit","allow_rebase_merge","topics","codeowners","required_checks","enforce","rulesets","actions","copilot","security","quality","ghaw","publishing","release","license","innersource","lfs","sre","devcontainer","manual_handoffs","oidc","integrations"]; $where)
  | check_field("name"; repo_name; $where; "invalid repository name; expected 1-100 letters, digits, dots, underscores or hyphens, excluding . and names containing ..")
  | check(optional("adopt"; type == "boolean") and optional("visibility"; enum(["private","internal","public"])) and optional("stack"; enum(["node","python","none"])); $where; "invalid repository choice")
  | if has("verification") then .verification |= verification($where + ".verification") else . end
  | check(optional("template"; str and test("^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$")); $where; "template must be owner/name")
  | check(optional("description"; type == "string") and optional("default_branch"; path) and optional("topics"; strings) and optional("copilot_users"; logins) and optional("required_checks"; strings); $where; "invalid repository metadata")
  | if has("codeowners") then .codeowners |= (
      check(type == "array"; $where; "codeowners must be an array")
      | map(keys_only(["pattern","teams"]; $where)
        | check(.pattern | str and (test("[\r\n]") | not); $where; "invalid CODEOWNERS pattern")
        | check(.teams | strings and all(.[]; slug); $where; "invalid CODEOWNERS teams"))) else . end
  | if has("devcontainer") then .devcontainer |= (
      keys_only(["path","content"]; $where)
      | check(optional("path"; path) and (.content | type == "string"); $where; "invalid devcontainer")
      | check(.content | no_literal_credentials; $where; "literal GitHub credentials are forbidden")) else . end
  | if has("manual_handoffs") then .manual_handoffs |= manual($where) else . end
  | if has("oidc") then .oidc |= (
      keys_only(["environment","ref","provider"]; $where)
      | check(optional("environment"; str) and optional("ref"; path) and optional("provider"; str); $where; "invalid OIDC handoff")) else . end
  | check(all(to_entries[] | select(.key | enum(["has_issues","has_projects","has_wiki","has_discussions","delete_branch_on_merge","allow_squash_merge","allow_merge_commit","allow_rebase_merge","enforce"])); .value | type == "boolean"); $where; "repository switches must be boolean")
  | if has("files") then .files |= (
      check(type == "array"; $where + ".files"; "files must be an array")
      | to_entries | map(.key as $index | .value | file($where + ".files[" + ($index | tostring) + "]"))
      | check(unique_by_key("path"); $where + ".files"; "duplicate file paths")) else . end
  | if has("labels") then .labels |= (check(type == "array"; $where; "labels must be an array") | map(
      keys_only(["name","color","description"]; $where + ".labels")
      | check(.name | str and length <= 50 and (test("[/?#%\\\\]") | not) and (contains("..") | not); $where; "label name must be a safe URL segment of at most 50 characters")
      | check(.color | type == "string" and test("^[0-9A-Fa-f]{6}$"); $where; "label color needs six hex digits")
      | check(optional("description"; type == "string"); $where; "invalid label description"))
      | check(unique_by_key("name"); $where; "duplicate labels")) else . end
  | check(optional("properties"; type == "object" and all(.[]; type == "string" or type == "boolean" or (type == "array" and all(.[]; type == "string")))); $where; "invalid property values")
  | if has("environments") then .environments |= (
      check(type == "array"; $where + ".environments"; "environments must be an array")
      | to_entries | map(.key as $index | .value | environment($where + ".environments[" + ($index | tostring) + "]"))
      | check(unique_by_key("name"); $where + ".environments"; "duplicate environments")) else . end
  | if has("workflows") then .workflows |= (
      check(type == "array"; $where + ".workflows"; "workflows must be an array")
      | to_entries | map(.key as $index | .value | workflow($where + ".workflows[" + ($index | tostring) + "]"))) else . end
  | if has("rulesets") then .rulesets |= rulesets($where) else . end
  | features($where)
  | check(optional("actions"; has("runner_groups") | not); $where; "runner_groups belong on organization Actions settings")
  | check(optional("security"; (has("configuration_name") or has("settings")) | not); $where; "named security configuration settings belong on organizations")
  | check(optional("ghaw"; type == "array"); $where; "repository ghaw must be an array of pilots")
  | check(optional("publishing"; optional("pages"; type == "object")); $where; "repository Pages needs a configuration object");
def team($where):
  keys_only(["name","slug","members","repositories","description","privacy","parent_team_id","idp_managed"]; $where)
  | check_field("name"; str; $where; "team name is required; expected a non-empty string")
  | check_field("slug"; slug; $where; "team slug is required; expected 1-100 letters, digits, underscores or hyphens")
  | check((.name | test("^[A-Za-z0-9]+([ -][A-Za-z0-9]+)*$"))
      and .slug == (.name | ascii_downcase | gsub(" ";"-"));
      $where; "use a team name with letters, numbers, single spaces or hyphens; slug must match its lowercase hyphenated name; name=" + (.name | diagnostic_value) + "; slug=" + (.slug | diagnostic_value))
  | check(optional("description"; type == "string") and optional("privacy"; enum(["closed","secret"])) and optional("idp_managed"; type == "boolean") and optional("parent_team_id"; type == "number" and floor == . and . > 0); $where; "invalid team")
  | if has("members") then .members |= (
      check(type == "array"; $where; "members must be an array")
      | map(if type == "string" then check(user_login; $where; "invalid member login") else
          keys_only(["login","role"]; $where)
          | check(.login | user_login; $where; "invalid member login")
          | check(optional("role"; enum(["member","maintainer"])); $where; "invalid team role") end)
      | check(length == (map((if type == "string" then . else .login end) | ascii_downcase) | unique | length); $where; "duplicate team members")) else . end
  | if has("repositories") then .repositories |= (
      check(type == "array"; $where + ".repositories"; "team repositories must be an array")
      | to_entries | map(.key as $index | .value
        | ($where + ".repositories[" + ($index | tostring) + "]") as $grant_where
        | keys_only(["name","permission"]; $grant_where)
        | check_field("name"; repo_name; $grant_where; "invalid team repository; expected only the repository name, 1-100 letters, digits, dots, underscores or hyphens, excluding . and names containing ..; edit Repository name within this organization")
        | check_field("permission"; enum(["pull","triage","push","maintain","admin"]); $grant_where; "invalid team permission; expected pull, triage, push, maintain or admin; edit Team repository permission"))
      | check(unique_by_key("name"); $where + ".repositories"; "duplicate team repository")) else . end;
def organization($where):
  keys_only(["login","create","verification","update_scopes","billing_email","owners","settings","packages","teams","repositories","actions","identity","copilot","security","quality","ghaw","migration","integrations","billing","audit","lifecycle","drift","publishing","release","license","innersource","vendors","lfs","sre","rulesets","manual_handoffs","property_schema","collaborators","repository_defaults","projects"]; $where)
  | check_field("login"; login; $where; "invalid organization login; expected 1-39 letters, digits or single hyphens")
  | check(optional("create"; type == "boolean"); $where; "create must be boolean")
  | if has("verification") then .verification |= verification($where + ".verification") else . end
  | if has("update_scopes") then .update_scopes |= update_scopes($where + ".update_scopes") else . end
  | check(optional("owners"; logins) and optional("packages"; packages); $where; "invalid owners or packages")
  | check(optional("billing_email"; str and test("^[^ @]+@[^ @]+\\.[^ @]+$")); $where; "invalid billing_email")
  | check(.create != true or ((.owners // [] | length) > 0 and has("billing_email")); $where; "organization creation needs owners and billing_email")
  | if has("settings") then .settings |= settings($where + ".settings") else . end
  | if has("collaborators") then .collaborators |= collaborator_policy($where + ".collaborators") else . end
  | if has("repository_defaults") then .repository_defaults |= repository_defaults($where + ".repository_defaults") else . end
  | if has("projects") then .projects |= (
      check(type=="array"; $where + ".projects"; "projects must be an array")
      | to_entries | map(.key as $index | .value | project($where + ".projects[" + ($index|tostring) + "]"))
      | check(length==(map(.title|ascii_downcase)|unique|length); $where + ".projects"; "duplicate project titles")) else . end
  | if has("property_schema") then .property_schema |= property_schema($where + ".property_schema") else . end
  | if has("rulesets") then .rulesets |= rulesets($where) else . end
  | if has("manual_handoffs") then .manual_handoffs |= manual($where) else . end
  | if has("teams") then .teams |= (
      check(type == "array"; $where + ".teams"; "teams must be an array")
      | to_entries | map(.key as $index | .value | team($where + ".teams[" + ($index | tostring) + "]"))
      | check(unique_by_key("slug"); $where + ".teams"; "duplicate teams")) else . end
  | if has("repositories") then .repositories |= (
      check(type == "array"; $where + ".repositories"; "repositories must be an array")
      | to_entries | map(.key as $index | .value | repository($where + ".repositories[" + ($index | tostring) + "]"))
      | check(unique_by_key("name"); $where + ".repositories"; "duplicate repositories")) else . end
  | . as $org
  | if has("teams") then .teams |= (
      to_entries | map(.key as $team_index | .value
        | if has("repositories") then .repositories |= (
            to_entries | map(.key as $repository_index | .value
              | check(.name as $name | any($org.repositories[]?;
                  (.name | ascii_downcase) == ($name | ascii_downcase));
                  $where + ".teams[" + ($team_index | tostring) + "].repositories[" +
                    ($repository_index | tostring) + "].name";
                  "team repository must reference a configured organization repository")))
          else . end))
    else . end
  | check(all(.repositories[]? | (.properties // {}) | to_entries[];
      . as $entry
      | all($org.property_schema[]? | select(.property_name == $entry.key);
          . as $schema | $entry.value | property_value($schema)));
      $where; "repository property value does not match its configured schema")
  | check(all(.repositories[]?;
      . as $repo
      | all(.codeowners[]?.teams[];
          . as $team_slug
          | any($org.teams[]?;
              (.slug | ascii_downcase) == ($team_slug | ascii_downcase) and (.privacy // "closed") != "secret"
              and any(.repositories[]?; (.name | ascii_downcase) == ($repo.name | ascii_downcase) and (.permission | enum(["push","maintain","admin"]))))));
      $where; "CODEOWNERS teams need configured, visible teams with write access to this repository")
  | features($where)
  | check(optional("ghaw"; type == "object"); $where; "organization ghaw must be a pilot selection object")
  | check(optional("publishing"; optional("pages"; type == "boolean") and (has("container") | not)); $where; "organization publishing uses Pages/Packages choices; container configuration belongs on repositories")
  | check(optional("security"; has("repository_id") | not); $where; "repository_id belongs on repository security");
if length != 1 then fail("$"; "expected exactly one JSON document") else .[0] end
| keys_only(["schema_version","host","actor","enterprise","defaults","organizations"]; "$")
| check_field("schema_version"; . == 1; "$"; "schema_version must be 1")
| check_field("host"; type == "string" and length<=71 and (. == "github.com" or test("^[a-z0-9]([a-z0-9-]*[a-z0-9])?\\.ghe\\.com$")); "$"; "host must be github.com or a customer subdomain.ghe.com with at most 63 characters in its subdomain")
| check_field("actor"; user_login; "$"; "actor must be the expected GitHub login")
| .enterprise |= (keys_only(["slug","identity","verification","governance_profile","update_scopes","policies"]; "$.enterprise")
    | check(.slug | slug; "$.enterprise"; "enterprise slug is required")
    | check(.identity | enum(["personal","emu"]); "$.enterprise"; "identity must be personal or emu")
    | check(.governance_profile | enum(["balanced","regulated","inner_source","emu_vendor"]); "$.enterprise"; "invalid governance profile")
    | if has("verification") then .verification |= verification("$.enterprise.verification") else . end
    | if has("update_scopes") then .update_scopes |= enterprise_update_scopes("$.enterprise.update_scopes") else . end
    | if has("policies") then .policies |= enterprise_policies("$.enterprise.policies") else . end)
| if has("defaults") then .defaults |= (
    keys_only(["packages","repository_visibility","settings","repository"]; "$.defaults")
    | check(optional("packages"; packages) and optional("repository_visibility"; enum(["private","internal","public"])); "$.defaults"; "invalid defaults")
    | if has("settings") then .settings |= settings("$.defaults.settings") else . end
    | if has("repository") then .repository |= repository_defaults("$.defaults.repository") else . end) else . end
| .organizations |= (check(type == "array" and length > 0; "$.organizations"; "at least one organization is required")
    | to_entries | map(.key as $index | .value | organization("$.organizations[" + ($index | tostring) + "]"))
    | check(unique_by_key("login"); "$.organizations"; "duplicate organizations"))
| check(all(.. | objects | keys[]; credential_key | not); "$"; "credentials must stay outside configuration")
| . as $root
| check(all(.organizations[];
    . as $org
    | (.packages // $root.defaults.packages // []) as $packages
    | (if (.property_schema // [] | length) > 0 then ($packages | index("workspace") != null) else true end)
    and (if (.rulesets // [] | length) > 0 then ($packages | index("actions") != null) else true end)
    and all(.repositories[]?;
        (if (.stack // "none") != "none" then
          ($packages | index("workspace") != null and index("actions") != null) else true end)
        and (if ((.workflows // [] | length) + (.rulesets // [] | length)) > 0 then ($packages | index("actions") != null) else true end)));
    "$"; "property schemas require workspace; Node/Python starters require workspace and actions; workflows and rulesets require actions")
| check(.enterprise.identity != "emu" or (
    (.defaults.repository_visibility // "private") != "public"
    and ((.enterprise.policies.repository.user_namespace_repository_creation //
      (if .enterprise.governance_profile == "emu_vendor" then "blocked" else "allowed" end)) == "blocked")
    and all(.organizations[].repositories[]?;
      (.visibility // $root.defaults.repository_visibility // "private") != "public")); "$"; "EMU repositories cannot be public")
| check((.enterprise.policies.copilot.source_organization // "") as $source
    | $source == "" or any(.organizations[]; .login == $source);
    "$.enterprise.policies.copilot.source_organization"; "Copilot source organization must be configured")
| check(.enterprise.identity != "emu" or (
    (.enterprise.policies.offboarding.remove_unaffiliated_users // false) == false
    and (.enterprise.policies.authentication.require_two_factor // false) == false);
    "$.enterprise.policies"; "EMU offboarding and authentication enforcement belong to the identity provider")
| check(all(.organizations[];
    (.actions.cache_retention_days // 0) <=
      ($root.enterprise.policies.actions.cache_retention_days // 365)
    and (.actions.cache_size_gb // 0) <=
      ($root.enterprise.policies.actions.cache_size_gb // 10000));
    "$.organizations"; "organization Actions cache limits cannot exceed the enterprise ceiling")
| check(all(.organizations[];
    . as $org | all(.repositories[]?;
      (.actions.cache_retention_days // 0) <=
        ($org.actions.cache_retention_days //
          $root.enterprise.policies.actions.cache_retention_days // 365)
      and (.actions.cache_size_gb // 0) <=
        ($org.actions.cache_size_gb //
          $root.enterprise.policies.actions.cache_size_gb // 10000)));
    "$.organizations[].repositories"; "repository Actions cache limits cannot exceed the organization or enterprise ceiling")
| true
