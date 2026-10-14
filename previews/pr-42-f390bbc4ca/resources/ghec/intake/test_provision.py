import copy
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import provision


SHA = "a" * 40
TREE = "b" * 40
CONFIG = {
    "organization": "example", "intake_repository": "example/intake",
    "template_repository": "example/starter", "template_commit": SHA,
    "approved_teams": ["grubify"], "approver_team": "platform-admins",
    "required_checks": ["application-ci"],
}
ISSUE = {
    "id": 101, "number": 1, "state": "open", "title": "Repository request: orders",
    "body": "### Service name\n\norders\n\n### Owning team\n\ngrubify\n\n### Purpose\n\nRun customer orders.",
    "updated_at": "2026-01-01T10:00:00Z", "user": {"id": 10, "login": "requester"},
}
EVENT = {"repository": {"full_name": "example/intake"}, "issue": ISSUE}
RULES = [
    {"type": "pull_request", "parameters": {"required_approving_review_count": 1}},
    {"type": "required_status_checks",
     "parameters": {"required_status_checks": [{"context": "application-ci"}]}},
]


class FakeApi:
    def __init__(self):
        self.writes = []
        self.reads = []
        self.accept_headers = {}
        self.existing = False
        self.source_reads = 0
        self.issue_reads = 0
        self.fail_write = None
        self.mutate_issue_at = None
        self.change_template_during_clone = False
        self.responses = {
            "/repos/example/intake/issues/1": copy.deepcopy(ISSUE),
            "/repos/example/intake/environments/repository-provisioning": {"id": 80},
            "/repos/example/intake/actions/runs/12/approvals": [
                {"state": "approved", "environments": [{"id": 80}],
                 "user": {"id": 20, "login": "approver"}},
            ],
            "/orgs/example/memberships/requester": {"state": "active", "user": {"id": 10}},
            "/orgs/example/teams/grubify/memberships/requester": {"state": "active"},
            "/orgs/example/memberships/approver": {"state": "active", "user": {"id": 20}},
            "/orgs/example/teams/platform-admins/memberships/approver": {"state": "active"},
            "/repos/example/intake/collaborators/approver/permission":
                {"user": {"id": 20}, "role_name": "maintain"},
            "/repos/example/starter": {
                "is_template": True, "default_branch": "main", "node_id": "template-id",
                "owner": {"node_id": "organization-id"},
            },
            "/repos/example/starter/commits/main": {"sha": SHA, "commit": {"tree": {"sha": TREE}}},
            "/repos/example/starter/rules/branches/main": copy.deepcopy(RULES),
            "/repos/example/grubify-orders":
                {"id": 500, "visibility": "internal", "default_branch": "main"},
            "/repos/example/grubify-orders/commits/main": {"commit": {"tree": {"sha": TREE}}},
            "/repos/example/grubify-orders/rules/branches/main": copy.deepcopy(RULES),
            "/orgs/example/teams/grubify/repos/example/grubify-orders": {"id": 500, "role_name": "write"},
            "/graphql": {"data": {"cloneTemplateRepository": {"repository": {
                "id": "new-node-id", "databaseId": 500, "name": "grubify-orders",
                "owner": {"login": "example"}, "visibility": "INTERNAL",
            }}}},
        }

    def get(self, path, accept=None):
        self.reads.append(path)
        self.accept_headers[path] = accept
        if path == "/repos/example/grubify-orders" and not self.existing:
            raise provision.ApiError("GET", path, 404)
        if path == "/repos/example/starter/commits/main":
            self.source_reads += 1
            if self.source_reads > 1 and self.change_template_during_clone:
                return {"sha": "c" * 40}
        if path == "/repos/example/intake/issues/1":
            self.issue_reads += 1
            if self.mutate_issue_at == self.issue_reads:
                self.responses[path]["body"] += "\nEdited purpose."
        response = self.responses[path]
        if isinstance(response, Exception):
            raise response
        return copy.deepcopy(response)

    def call(self, method, path, data):
        self.writes.append((method, path, copy.deepcopy(data)))
        if path == self.fail_write:
            raise provision.ApiError(method, path, 503)
        if path == "/graphql":
            self.existing = True
            return copy.deepcopy(self.responses[path])
        if path.endswith("/comments"):
            self.responses["/repos/example/intake/issues/1"]["updated_at"] = "2026-01-01T10:10:00Z"
        if method == "PATCH":
            self.responses[path].update(data)
        return None


class ProvisionTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeApi()
        self.output = patch("provision.summary")
        self.output.start()
        self.addCleanup(self.output.stop)

    def run_provision(self):
        return provision.provision(copy.deepcopy(EVENT), copy.deepcopy(CONFIG), self.api, self.api, "12")

    def reject_before_creation(self):
        with self.assertRaises(provision.IntakeError):
            self.run_provision()
        self.assertEqual(self.api.writes, [])

    def test_creates_internal_from_fixed_template_and_grants_write(self):
        self.assertEqual(self.run_provision(), 500)
        create, grant, comment, close = self.api.writes
        self.assertEqual(create[:2], ("POST", "/graphql"))
        self.assertEqual(create[2]["variables"]["input"], {
            "ownerId": "organization-id", "repositoryId": "template-id", "name": "grubify-orders",
            "visibility": "INTERNAL", "includeAllBranches": False,
            "description": "Provisioned through example/intake#1",
        })
        self.assertEqual(grant, ("PUT", "/orgs/example/teams/grubify/repos/example/grubify-orders",
                                 {"permission": "push"}))
        self.assertEqual(self.api.accept_headers[grant[1]], "application/vnd.github.v3.repository+json")
        self.assertIn("repository ID `500`", comment[2]["body"])
        self.assertEqual(close, ("PATCH", "/repos/example/intake/issues/1",
                                 {"state": "closed", "state_reason": "completed"}))
        self.assertNotIn("updated_at", close[2])

    def test_missing_rejected_wrong_environment_and_duplicate_approvals(self):
        path = "/repos/example/intake/actions/runs/12/approvals"
        review = copy.deepcopy(self.api.responses[path][0])
        for reviews in ([], [{**review, "state": "rejected"}],
                        [{**review, "environments": [{"id": 81}]}], [review, review]):
            with self.subTest(reviews=reviews):
                self.api.responses[path] = reviews
                self.reject_before_creation()

    def test_self_approval(self):
        self.api.responses["/repos/example/intake/actions/runs/12/approvals"][0]["user"] = ISSUE["user"]
        self.reject_before_creation()

    def test_inactive_requester_and_foreign_team_and_unauthorized_approver(self):
        paths = (
            "/orgs/example/memberships/requester",
            "/orgs/example/teams/grubify/memberships/requester",
            "/orgs/example/memberships/approver",
            "/orgs/example/teams/platform-admins/memberships/approver",
        )
        for path in paths:
            with self.subTest(path=path):
                self.api = FakeApi()
                self.api.responses[path]["state"] = "pending"
                self.reject_before_creation()
        self.api = FakeApi()
        self.api.responses["/repos/example/intake/collaborators/approver/permission"]["role_name"] = "write"
        self.reject_before_creation()

    def test_membership_lookup_failure_is_not_a_default_allow(self):
        self.api.responses["/orgs/example/teams/grubify/memberships/requester"] = provision.ApiError("GET", "membership", 404)
        self.reject_before_creation()

    def test_identity_change(self):
        self.api.responses["/orgs/example/memberships/requester"]["user"]["id"] = 999
        self.reject_before_creation()

    def test_request_edits_before_and_during_preflight(self):
        for read in (1, 2):
            with self.subTest(read=read):
                self.api = FakeApi()
                self.api.mutate_issue_at = read
                self.reject_before_creation()

    def test_edit_after_creation_does_not_grant_access(self):
        self.api.mutate_issue_at = 3
        with self.assertRaisesRegex(provision.IntakeError, "Request changed"):
            self.run_provision()
        self.assertEqual([write[1] for write in self.api.writes], ["/graphql"])

    def test_comments_do_not_invalidate_content_approval_or_prevent_closure(self):
        self.api.responses["/repos/example/intake/issues/1"]["updated_at"] = "2026-01-01T10:02:00Z"
        self.assertEqual(self.run_provision(), 500)
        self.assertEqual(self.api.writes[-1][0], "PATCH")

    def test_existing_repository_and_replayed_request_never_change_access(self):
        self.api.existing = True
        self.reject_before_creation()
        self.api = FakeApi()
        self.run_provision()
        self.api.writes.clear()
        self.reject_before_creation()

    def test_lost_creation_response_does_not_retry_or_grant(self):
        self.api.fail_write = "/graphql"
        with self.assertRaisesRegex(provision.IntakeError, "may have succeeded"):
            self.run_provision()
        self.assertEqual(len(self.api.writes), 1)

    def test_graphql_error_or_incomplete_response_cannot_report_success(self):
        for response in (None, {"errors": [{"message": "Denied"}]}, {"data": {}},
                         {"data": {"cloneTemplateRepository": {"repository": None}}}):
            with self.subTest(response=response):
                self.api = FakeApi()
                self.api.responses["/graphql"] = response
                with self.assertRaisesRegex(provision.IntakeError, "may have succeeded"):
                    self.run_provision()
                self.assertEqual(len(self.api.writes), 1)

    def test_template_must_be_reviewed_and_still_marked_as_template(self):
        self.api.responses["/repos/example/starter/commits/main"]["sha"] = "c" * 40
        self.reject_before_creation()
        self.api = FakeApi()
        self.api.responses["/repos/example/starter"]["is_template"] = False
        self.reject_before_creation()

    def test_template_move_during_creation_stops_before_team_access(self):
        self.api.change_template_during_clone = True
        with self.assertRaisesRegex(provision.IntakeError, "Template changed"):
            self.run_provision()
        self.assertEqual(len(self.api.writes), 1)

    def test_wrong_identity_visibility_or_tree_never_grants_access(self):
        for field, value in (("id", 999), ("visibility", "public")):
            with self.subTest(field=field):
                self.api = FakeApi()
                self.api.responses["/repos/example/grubify-orders"][field] = value
                with self.assertRaises(provision.IntakeError):
                    self.run_provision()
                self.assertEqual(len(self.api.writes), 1)
        self.api = FakeApi()
        self.api.responses["/repos/example/grubify-orders/commits/main"]["commit"]["tree"]["sha"] = "c" * 40
        with self.assertRaises(provision.IntakeError):
            self.run_provision()
        self.assertEqual(len(self.api.writes), 1)

    def test_baseline_required_on_template_before_creation_and_destination_before_grant(self):
        for repo, expected_writes in (("starter", 0), ("grubify-orders", 1)):
            for rules in ([], [RULES[0]], [RULES[1]],
                          [{**RULES[0], "parameters": {"required_approving_review_count": 0}}, RULES[1]]):
                with self.subTest(repo=repo, rules=rules):
                    self.api = FakeApi()
                    self.api.responses[f"/repos/example/{repo}/rules/branches/main"] = rules
                    with self.assertRaises(provision.IntakeError):
                        self.run_provision()
                    self.assertEqual(len(self.api.writes), expected_writes)

    def test_grant_failure_keeps_request_open_and_does_not_report_fulfillment(self):
        self.api.fail_write = "/orgs/example/teams/grubify/repos/example/grubify-orders"
        with self.assertRaises(provision.IntakeError):
            self.run_provision()
        self.assertEqual(len(self.api.writes), 2)
        self.assertFalse(any(write[0] == "PATCH" for write in self.api.writes))
        self.assertFalse(any("Fulfilled" in str(call) for call in provision.summary.call_args_list))

    def test_incorrect_team_role_or_identity_keeps_request_open(self):
        for field, value in (("id", 999), ("role_name", "admin")):
            with self.subTest(field=field):
                self.api = FakeApi()
                self.api.responses["/orgs/example/teams/grubify/repos/example/grubify-orders"][field] = value
                with self.assertRaises(provision.IntakeError):
                    self.run_provision()
                self.assertEqual(len(self.api.writes), 2)

    def test_membership_revoked_during_creation_prevents_team_grant(self):
        original_call = self.api.call

        def revoke(method, path, data):
            result = original_call(method, path, data)
            if path == "/graphql":
                self.api.responses["/orgs/example/teams/grubify/memberships/requester"]["state"] = "pending"
            return result

        self.api.call = revoke
        with self.assertRaises(provision.IntakeError):
            self.run_provision()
        self.assertEqual(len(self.api.writes), 1)

    def test_new_repository_reads_retry_not_ready_without_repeating_creation(self):
        original_get = self.api.get
        count = 0

        def eventually_ready(path, accept=None):
            nonlocal count
            if path == "/repos/example/grubify-orders/commits/main":
                count += 1
                if count < 3:
                    raise provision.ApiError("GET", path, 409)
            return original_get(path, accept)

        self.api.get = eventually_ready
        with patch("provision.time.sleep") as sleep:
            self.assertEqual(self.run_provision(), 500)
        self.assertEqual([call.args[0] for call in sleep.call_args_list], [1, 2])
        self.assertEqual(sum(write[1] == "/graphql" for write in self.api.writes), 1)

    def test_read_retry_is_bounded_and_does_not_retry_permission_failures(self):
        for status, expected_sleeps in ((409, 4), (403, 0)):
            with self.subTest(status=status):
                self.api = FakeApi()
                path = "/repos/example/grubify-orders/commits/main"
                self.api.responses[path] = provision.ApiError("GET", path, status)
                with patch("provision.time.sleep") as sleep, self.assertRaises(provision.ApiError):
                    self.run_provision()
                self.assertEqual(sleep.call_count, expected_sleeps)
                self.assertEqual(len(self.api.writes), 1)


class InputTests(unittest.TestCase):
    def test_windows_line_endings(self):
        event = copy.deepcopy(EVENT)
        event["issue"]["body"] = ISSUE["body"].replace("\n", "\r\n")
        self.assertEqual(provision.request_values(event, CONFIG)["name"], "grubify-orders")

    def test_invalid_names_teams_and_duplicate_fields(self):
        for service in ("Orders", "orders; echo bad", "../orders", "orders--api", "1orders", "a" * 51):
            with self.subTest(service=service):
                event = copy.deepcopy(EVENT)
                event["issue"]["body"] = ISSUE["body"].replace("\norders\n", "\n" + service + "\n")
                with self.assertRaises(provision.IntakeError):
                    provision.request_values(event, CONFIG)
        for body in (ISSUE["body"].replace("\ngrubify\n", "\nunknown\n"),
                     ISSUE["body"] + "\n### Owning team\n\nother",
                     "Forged instructions\n" + ISSUE["body"]):
            event = copy.deepcopy(EVENT)
            event["issue"]["body"] = body
            with self.assertRaises(provision.IntakeError):
                provision.request_values(event, CONFIG)

    def test_cross_organization_configuration_and_unconfigured_commit(self):
        for key, value in (("template_repository", "other/starter"), ("template_commit", "REPLACE_ME"),
                           ("required_checks", []), ("intake_repository", "other/intake")):
            with self.subTest(key=key):
                config = {**CONFIG, key: value}
                with self.assertRaises(provision.IntakeError):
                    provision.request_values(EVENT, config)

    def test_preview_escapes_untrusted_text_and_has_no_tokens(self):
        event = copy.deepcopy(EVENT)
        event["issue"]["body"] += "\n<script>alert(1)</script>"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "automation").mkdir()
            (root / "automation/config.json").write_text(json.dumps(CONFIG))
            (root / "event.json").write_text(json.dumps(event))
            with patch("provision.Path", side_effect=lambda name: root / name), \
                    patch.dict("os.environ", {
                        "GITHUB_EVENT_PATH": "event.json", "GITHUB_EVENT_NAME": "issues",
                        "GITHUB_REPOSITORY": "example/intake",
                    }, clear=True), \
                    patch("sys.argv", ["provision.py", "--preview"]), \
                    patch("provision.summary") as output:
                provision.main()
                preview = output.call_args[0][0]
                self.assertIn("&lt;script&gt;", preview)
                self.assertNotIn("<script>", preview)
                self.assertIn(SHA, preview)

    def test_http_request_uses_json_and_does_not_execute_issue_text(self):
        data = {"purpose": "$(touch /not-a-command)", "visibility": "INTERNAL"}
        with patch("provision.urlopen", return_value=io.BytesIO(b'{"ok":true}')) as send:
            self.assertEqual(provision.Api("test-token").call("POST", "/graphql", data), {"ok": True})
        request = send.call_args[0][0]
        self.assertEqual(request.full_url, "https://api.github.com/graphql")
        self.assertEqual(json.loads(request.data), data)
        self.assertEqual(request.get_header("Authorization"), "Bearer test-token")
        self.assertEqual(send.call_args.kwargs["timeout"], 30)

    def test_team_verification_requests_the_repository_response_not_empty_204(self):
        with patch("provision.urlopen", return_value=io.BytesIO(b'{"id":500,"role_name":"write"}')) as send:
            response = provision.Api("test-token").get(
                "/orgs/example/teams/grubify/repos/example/grubify-orders",
                accept="application/vnd.github.v3.repository+json")
        self.assertEqual(response["role_name"], "write")
        self.assertEqual(send.call_args[0][0].get_header("Accept"), "application/vnd.github.v3.repository+json")

    def test_invalid_api_json_is_an_explicit_failure(self):
        with patch("provision.urlopen", return_value=io.BytesIO(b"not-json")):
            with self.assertRaisesRegex(provision.IntakeError, "invalid JSON"):
                provision.Api("test-token").call("POST", "/graphql", {})

    def test_workflow_has_approval_gate_fixed_checkout_and_no_pull_request_trigger(self):
        workflow = Path(__file__).with_name("repository-intake.yml").read_text()
        self.assertIn("environment: repository-provisioning", workflow)
        self.assertIn("needs: review", workflow)
        self.assertEqual(workflow.count("ref: ${{ github.sha }}"), 2)
        self.assertNotIn("pull_request", workflow)
        self.assertNotIn("${{ github.event.issue.body }}", workflow)
        self.assertNotIn("APP_TOKEN", workflow.split("  provision:")[0])
        self.assertIn("group: repository-intake-${{ github.event.issue.number }}", workflow)


if __name__ == "__main__":
    unittest.main()
