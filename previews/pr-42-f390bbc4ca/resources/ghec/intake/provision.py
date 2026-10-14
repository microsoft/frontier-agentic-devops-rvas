"""Approved GitHub.com repository intake. Uses only the Python standard library."""

import hashlib
import html
import json
import os
from pathlib import Path
import re
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


ENVIRONMENT = "repository-provisioning"


class IntakeError(RuntimeError):
    pass


class ApiError(IntakeError):
    def __init__(self, method, path, status):
        self.status = status
        super().__init__(f"GitHub {method} {path} failed (HTTP {status}).")


class Api:
    def __init__(self, token):
        if not token:
            raise IntakeError("Missing installation or intake token.")
        self.token = token

    def call(self, method, path, data=None, accept="application/vnd.github+json"):
        request = Request(
            "https://api.github.com" + path,
            data=None if data is None else json.dumps(data).encode(),
            method=method,
            headers={
                "Authorization": "Bearer " + self.token,
                "Accept": accept,
                "X-GitHub-Api-Version": "2022-11-28",
                "Content-Type": "application/json",
            },
        )
        try:
            with urlopen(request, timeout=30) as response:
                body = response.read()
                try:
                    return json.loads(body) if body else None
                except json.JSONDecodeError as error:
                    raise IntakeError(f"GitHub {method} {path} returned invalid JSON.") from error
        except HTTPError as error:
            raise ApiError(method, path, error.code) from error
        except (URLError, TimeoutError, ConnectionError) as error:
            raise IntakeError(f"GitHub {method} {path} connection failed; do not blindly retry a write.") from error

    def get(self, path, accept="application/vnd.github+json"):
        return self.call("GET", path, accept=accept)


def require(condition, message):
    if not condition:
        raise IntakeError(message)


def request_values(event, config):
    org = config["organization"]
    require(re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9-]*", org), "Invalid organization.")
    require(config["intake_repository"] == event["repository"]["full_name"],
            "Event does not belong to the configured intake repository.")
    for key in ("intake_repository", "template_repository"):
        require(re.fullmatch(re.escape(org) + r"/[a-zA-Z0-9_.-]+", config[key]),
                f"{key} must be in the configured organization.")
    require(re.fullmatch(r"[0-9a-f]{40}", config["template_commit"]),
            "Configure the reviewed template commit.")
    require(config["required_checks"] and all(
        isinstance(check, str) and check and not check.startswith("REPLACE_")
        for check in config["required_checks"]), "Configure actual required CI checks.")
    require(config["approved_teams"] and all(
        isinstance(team, str) and re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", team)
        for team in config["approved_teams"]), "Configure approved team slugs.")
    require(re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", config["approver_team"]),
            "Configure the approver team slug.")
    issue = event["issue"]
    require(isinstance(issue["number"], int) and issue["number"] > 0, "Invalid issue number.")
    require(issue["state"] == "open" and "pull_request" not in issue, "Request must be an open issue.")
    body = issue.get("body") or ""
    headings = re.findall(r"^### ([^\r\n]+)\r?$", body, re.M)
    require(headings == ["Service name", "Owning team", "Purpose"], "Use the installed request form.")
    sections = re.split(r"^### .+\r?$", body, flags=re.M)
    require(not sections[0].strip(), "Unexpected text before the request fields.")
    service, team, purpose = (part.strip() for part in sections[1:])
    require(len(service) <= 50 and re.fullmatch(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*", service),
            "Service name must be lowercase kebab-case, start with a letter, and fit 50 characters.")
    require(team in config["approved_teams"], "Requested team is not administrator-approved.")
    require(purpose and purpose != "_No response_" and len(purpose) <= 2000, "Supply a purpose of at most 2000 characters.")
    name = team + "-" + service
    require(len(name) <= 100, "Combined repository name exceeds 100 characters.")
    return {
        "name": name, "team": team, "purpose": purpose,
        "body_hash": hashlib.sha256(body.encode()).hexdigest(),
    }


def unchanged(live, snapshot):
    require(live["state"] == "open" and "pull_request" not in live, "Request is no longer open.")
    require(all(live.get(key) == snapshot.get(key) for key in ("id", "body", "title")),
            "Request changed after this run started. Approve the new run.")
    require(live["user"]["id"] == snapshot["user"]["id"], "Requester identity changed.")


def active_member(api, org, team, user):
    login = quote(user["login"], safe="")
    membership = api.get(f"/orgs/{org}/memberships/{login}")
    require(membership["state"] == "active" and membership["user"]["id"] == user["id"],
            "User is not a current organization member.")
    team_membership = api.get(f"/orgs/{org}/teams/{team}/memberships/{login}")
    require(team_membership["state"] == "active", "User is not a current member of the required team.")


def approved(app, intake, config, issue, run_id):
    repo = config["intake_repository"]
    environment = intake.get(f"/repos/{repo}/environments/{ENVIRONMENT}")
    reviews = intake.get(f"/repos/{repo}/actions/runs/{run_id}/approvals")
    relevant = [review for review in reviews if any(
        item["id"] == environment["id"] for item in review["environments"])]
    require(relevant and relevant[-1]["state"] == "approved", "No approved environment review for this run.")
    approvals = [review for review in relevant if review["state"] == "approved"]
    require(len(approvals) == 1, "Ambiguous approvals; start a fresh request review.")
    user = approvals[0]["user"]
    require(user["id"] != issue["user"]["id"], "Requesters cannot approve their own requests.")
    active_member(app, config["organization"], config["approver_team"], user)
    permission = app.get(f"/repos/{repo}/collaborators/{quote(user['login'], safe='')}/permission")
    require(permission["user"]["id"] == user["id"] and permission["role_name"] in ("maintain", "admin"),
            "Approver must currently have Maintain or Admin access to intake.")


def template_head(api, repository):
    repo = api.get(f"/repos/{repository}")
    require(repo["is_template"], "Configured starter is not a template.")
    branch = quote(repo["default_branch"], safe="")
    head = api.get(f"/repos/{repository}/commits/{branch}")
    return repo, head


def baseline(api, repository, branch, checks):
    rules = api.get(f"/repos/{repository}/rules/branches/{quote(branch, safe='')}")
    require(any(rule["type"] == "pull_request"
                and rule["parameters"]["required_approving_review_count"] >= 1 for rule in rules),
            "Repository lacks the inherited independent-review rule.")
    contexts = {check["context"] for rule in rules if rule["type"] == "required_status_checks"
                for check in rule["parameters"]["required_status_checks"]}
    require(set(checks) <= contexts, "Repository lacks the configured required CI checks.")


def created_files(api, repository, repository_id):
    for attempt in range(5):
        try:
            destination = api.get(f"/repos/{repository}")
            require(destination["id"] == repository_id and destination["visibility"] == "internal",
                    "Repository identity or visibility does not match creation.")
            branch = quote(destination["default_branch"], safe="")
            return destination, api.get(f"/repos/{repository}/commits/{branch}")
        except ApiError as error:
            if error.status not in (404, 409) or attempt == 4:
                raise
            print(f"Created repository files are not ready; retrying read {attempt + 1}/4.", flush=True)
            time.sleep(2 ** attempt)


def summary(text):
    print(text, flush=True)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as output:
            output.write(text + "\n")


def provision(event, config, app, intake, run_id):
    values = request_values(event, config)
    issue = event["issue"]
    repo = config["intake_repository"]
    org = config["organization"]
    issue_path = f"/repos/{repo}/issues/{issue['number']}"
    unchanged(intake.get(issue_path), issue)
    active_member(app, org, values["team"], issue["user"])
    approved(app, intake, config, issue, run_id)
    template, source = template_head(app, config["template_repository"])
    require(source["sha"] == config["template_commit"], "Template moved from its reviewed commit.")
    baseline(app, config["template_repository"], template["default_branch"], config["required_checks"])
    target = org + "/" + values["name"]
    try:
        app.get(f"/repos/{target}")
    except ApiError as error:
        if error.status != 404:
            raise
    else:
        raise IntakeError("Requested name already exists. Do not adopt or change that repository.")
    # Recheck after the read-only preflight. The original issue snapshot remains the authority.
    unchanged(intake.get(issue_path), issue)
    mutation = """
    mutation($input: CloneTemplateRepositoryInput!) {
      cloneTemplateRepository(input: $input) {
        repository { id databaseId name visibility owner { login } }
      }
    }
    """
    try:
        result = app.call("POST", "/graphql", {
            "query": mutation,
            "variables": {"input": {
                "ownerId": template["owner"]["node_id"],
                "repositoryId": template["node_id"],
                "name": values["name"],
                "visibility": "INTERNAL",
                "includeAllBranches": False,
                "description": f"Provisioned through {repo}#{issue['number']}",
            }},
        })
        require(isinstance(result, dict), "Creation returned an invalid response.")
        require(not result.get("errors"), "GitHub rejected template creation. Check App permissions and repository policies.")
        created = result["data"]["cloneTemplateRepository"]["repository"]
        require(created and type(created["databaseId"]) is int and created["databaseId"] > 0,
                "Creation did not return a repository ID.")
    except (IntakeError, KeyError, TypeError) as error:
        raise IntakeError(f"Creation failed ({error}). It may have succeeded; an owner must inspect {target} before retrying.") from error
    repository_id = created["databaseId"]
    url = f"https://github.com/{target}"
    summary(f"Created {url}; numeric repository ID: {repository_id}. Configuration is not yet complete.")
    require(created["owner"]["login"].lower() == org.lower()
            and created["name"] == values["name"] and created["visibility"] == "INTERNAL",
            "Created repository does not match the approved target.")
    destination, head = created_files(app, target, repository_id)
    require(head["commit"]["tree"]["sha"] == source["commit"]["tree"]["sha"],
            "Copied files differ from the approved template; do not grant team access.")
    _, current_source = template_head(app, config["template_repository"])
    require(current_source["sha"] == config["template_commit"], "Template changed during creation.")
    baseline(app, target, destination["default_branch"], config["required_checks"])
    unchanged(intake.get(issue_path), issue)
    active_member(app, org, values["team"], issue["user"])
    approved(app, intake, config, issue, run_id)
    require(app.get(f"/repos/{target}")["id"] == repository_id, "Created repository was replaced.")
    team_path = f"/orgs/{org}/teams/{values['team']}/repos/{target}"
    app.call("PUT", team_path, {"permission": "push"})
    granted = app.get(team_path, accept="application/vnd.github.v3.repository+json")
    require(granted["id"] == repository_id and granted["role_name"] == "write",
            "Owning team's repository role is not Write.")
    body = (f"Provisioned [{target}]({url}) (repository ID `{repository_id}`).\n\n"
            f"Internal visibility; `{values['team']}` has Write access.\n\n"
            f"Template commit: `{config['template_commit']}`.\n"
            f"Reviewed request body SHA-256: `{values['body_hash']}`.\n\n"
            "Verify the first application PR against the inherited review and CI rules.")
    intake.call("POST", issue_path + "/comments", {"body": body})
    unchanged(intake.get(issue_path), issue)
    intake.call("PATCH", issue_path, {"state": "closed", "state_reason": "completed"})
    summary(f"Fulfilled: {url}. Owning team has Write; review and CI rules apply.")
    return repository_id


def main():
    config = json.loads(Path("automation/config.json").read_text())
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    require(os.environ.get("GITHUB_EVENT_NAME") == "issues", "Only issue events are supported.")
    require(os.environ.get("GITHUB_REPOSITORY") == config["intake_repository"], "Wrong workflow repository.")
    values = request_values(event, config)
    if sys.argv[1:] == ["--preview"]:
        details = json.dumps({**values, "template_commit": config["template_commit"],
                              "requester": event["issue"]["user"]["login"]}, indent=2)
        summary("Review this exact request before approving repository-provisioning:\n<pre>"
                + html.escape(details) + "</pre>")
        return
    require(not sys.argv[1:], "Unknown arguments.")
    run_id = os.environ["GITHUB_RUN_ID"]
    require(run_id.isdigit(), "Invalid workflow run ID.")
    provision(event, config, Api(os.environ.get("APP_TOKEN")),
              Api(os.environ.get("INTAKE_TOKEN")), run_id)


if __name__ == "__main__":
    try:
        main()
    except (IntakeError, KeyError, ValueError, OSError) as error:
        print(f"Repository intake failed: {error}", file=sys.stderr)
        sys.exit(1)
