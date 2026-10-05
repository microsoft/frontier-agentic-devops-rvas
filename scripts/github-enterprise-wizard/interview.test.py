import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shlex
import signal
import struct
import tempfile
import termios
import time
import unittest


ROOT = Path(__file__).resolve().parent
CONFIG = ROOT / "lib" / "config.sh"
ENTRYPOINT = ROOT.parent / "github-enterprise-wizard.sh"


FAKE_GH = """#!/usr/bin/env python3
import json, os, sys, time
from pathlib import Path
args = sys.argv[1:]
state = json.loads(Path(os.environ["WIZARD_DISCOVERY_FIXTURE"]).read_text())
calls = Path(os.environ["WIZARD_DISCOVERY_CALLS"])
payload = None
if "--input" in args:
    payload = json.loads(Path(args[args.index("--input") + 1]).read_text())
with calls.open("a") as stream:
    stream.write(json.dumps({"args": args, "body": payload, "pid": os.getpid()}) + "\\n")
host = args[args.index("--hostname") + 1]
if args[:2] == ["auth", "status"]:
    time.sleep(state.get("account_delay", 0))
    if state.get("account_failure"):
        sys.exit("Private authentication diagnostic: DO_NOT_DISPLAY")
    rows = state.get("accounts", {}).get(host, [])
    print(json.dumps([{k: r[k] for k in ("login", "active", "state")} for r in rows]))
elif args[0] == "api" and "graphql" in args:
    if not payload["query"].startswith("query("):
        sys.exit("Writes are forbidden in discovery tests")
    if "viewer" in payload["query"]:
        rows = state.get("enterprises", {}).get(host, [])
        data = {"viewer": {"enterprises": {"nodes": [{"slug": x} for x in rows]}}}
    else:
        slug = payload["variables"]["slug"]
        rows = state.get("organizations", {}).get(host + "/" + slug, [])
        data = {"enterprise": {"organizations": {"nodes": [{"login": x} for x in rows]}}}
    print(json.dumps([{"data": data}]))
elif args[0] == "api" and args[args.index("--method") + 1] == "GET":
    endpoint = next(x for x in args if x.startswith("/"))
    org = endpoint.split("/")[2]
    rows = state.get("repositories", {}).get(host + "/" + org, [])
    print(json.dumps([[{"name": x} for x in rows]]))
else:
    sys.exit("Unexpected discovery command")
"""


def terminal_run(command, answers, *, columns=100, rows=30, discovery=None, environment=None, calls_sink=None, resize_to=None):
    fixture = tempfile.TemporaryDirectory(prefix="wizard-discovery-test-")
    fixture_root = Path(fixture.name)
    fake_gh = fixture_root / "gh"
    fake_gh.write_text(FAKE_GH)
    fake_gh.chmod(0o700)
    state_file = fixture_root / "state.json"
    state_file.write_text(json.dumps(discovery or {}))
    calls_file = fixture_root / "calls.jsonl"
    pid, terminal = pty.fork()
    if pid == 0:
        child_environment = dict(os.environ, TERM="xterm-256color", PATH=str(fixture_root) + os.pathsep + os.environ["PATH"],
                                 WIZARD_DISCOVERY_FIXTURE=str(state_file), WIZARD_DISCOVERY_CALLS=str(calls_file))
        for name, value in (environment or {}).items():
            if value is None:
                child_environment.pop(name, None)
            else:
                child_environment[name] = value
        os.execve("/bin/bash", ["/bin/bash", "-c", command], child_environment)
    fcntl.ioctl(terminal, termios.TIOCSWINSZ, struct.pack("HHHH", rows, columns, 0, 0))
    initial = termios.tcgetattr(terminal)
    output = b""
    consumed = 0
    answer_index = 0
    deadline = time.monotonic() + 45
    status = None
    try:
        while time.monotonic() < deadline:
            if answer_index < len(answers):
                prompt, answer = answers[answer_index]
                found = output.find(prompt.encode(), consumed)
                if found != -1:
                    consumed = found + len(prompt.encode())
                    if answer_index == 0 and resize_to is not None:
                        fcntl.ioctl(terminal, termios.TIOCSWINSZ, struct.pack("HHHH", 30, resize_to, 0, 0))
                    os.write(terminal, answer)
                    answer_index += 1
            readable, _, _ = select.select([terminal], [], [], 0.05)
            if readable:
                try:
                    chunk = os.read(terminal, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    chunk = b""
                if chunk:
                    output += chunk
                else:
                    break
        else:
            os.kill(pid, signal.SIGKILL)
            raise AssertionError(f"Interview timed out at answer {answer_index}:\n{output.decode(errors='replace')}")
        _, status = os.waitpid(pid, 0)
        final = termios.tcgetattr(terminal)
        if answer_index != len(answers):
            raise AssertionError(f"Interview exited before answer {answer_index}:\n{output.decode(errors='replace')}")
        return os.waitstatus_to_exitcode(status), output.decode(errors="replace"), initial, final
    finally:
        os.close(terminal)
        if status is None:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            os.waitpid(pid, 0)
        if calls_sink is not None and calls_file.exists():
            calls_sink.extend(json.loads(line) for line in calls_file.read_text().splitlines())
        fixture.cleanup()


class InterviewTests(unittest.TestCase):
    def helper(self, body, answers, *, columns=100):
        command = f"source {shlex.quote(str(CONFIG))}; WIZARD_ORIGINAL_TTY=$(stty -g); {body}"
        return terminal_run(command, answers, columns=columns)

    def assert_restored(self, initial, final):
        self.assertEqual(initial, final, "terminal attributes must be restored exactly")

    def test_arrows_select_an_account_and_restore_terminal(self):
        options = json.dumps([
            {"value": "personal", "label": "Personal accounts", "description": "Personal identity"},
            {"value": "emu", "label": "Managed users", "description": "Company identity"},
        ])
        result, output, initial, final = self.helper(
            f"wizard_choose Account personal 'Choose your identity' {shlex.quote(options)}; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Choice 1/2.", b"\x1b[B\r")],
            columns=40,
        )
        self.assertEqual(result, 0, output)
        self.assertIn("RESULT=emu", output)
        self.assert_restored(initial, final)

    def test_space_toggles_packages_and_dependencies_are_included(self):
        result, output, initial, final = self.helper(
            "wizard_select_packages '[\"workspace\",\"actions\"]'; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Space: toggle a checkbox.", b" \x1b[B\x1b[B\x1b[B\x1b[B \r")],
        )
        self.assertEqual(result, 0, output)
        self.assertIn('RESULT=["actions","security","workspace"]', output)
        self.assertIn("including required packages", output)
        self.assert_restored(initial, final)

    def test_escape_cancels_and_restores_terminal(self):
        result, output, initial, final = self.helper(
            "wizard_prompt_bool 'Save configuration?' true; status=$?; printf '\\nSTATUS=%s\\n' \"$status\"; exit \"$status\"",
            [("Choice 2/2.", b"\x1b")],
        )
        self.assertEqual(result, 1, output)
        self.assertIn("No configuration was saved", output)
        self.assert_restored(initial, final)

    def test_plain_terminal_mode_accepts_defaults_and_yes(self):
        result, output, initial, final = self.helper(
            "WIZARD_PLAIN=true; wizard_prompt_bool 'Add team?' false; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Add team?: [No]", b"yes\r")],
        )
        self.assertEqual(result, 0, output)
        self.assertIn("RESULT=true", output)
        self.assertNotIn("\x1b[?25l", output)
        self.assert_restored(initial, final)

    def test_text_choices_reject_zero_and_accept_the_named_default(self):
        result, output, initial, final = self.helper(
            "WIZARD_PLAIN=true; wizard_prompt_bool 'Save?' false; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Save?: [No]", b"0\r"), ("Select one of the listed values", b"\r")],
        )
        self.assertEqual(result, 0, output)
        self.assertIn("RESULT=false", output)
        self.assert_restored(initial, final)

    def test_invalid_organization_names_retry_the_same_field(self):
        result, output, initial, final = self.helper(
            "wizard_prompt_identifier organization 'Organization login: ' '' 'Copy the organization name from its URL.'; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [
                ("Organization login:", b"https://github.com/acme-org\r"),
                ("Use a valid organization name", b"acme-org\r"),
            ],
        )
        self.assertEqual(result, 0, output)
        self.assertIn("RESULT=acme-org", output)
        self.assert_restored(initial, final)

    def test_invalid_actor_does_not_erase_the_saved_enterprise(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [
                    ("GitHub host:", b"\r"),
                    ("Expected authenticated GitHub login:", b"alice\r"),
                    ("Existing enterprise slug:", b"acme\r"),
                    ("Account identity", b"\x1b[D"),
                    ("Existing enterprise slug: [acme]", b":back\r"),
                    ("Expected authenticated GitHub login: [alice]", b"alice@example.com\r"),
                    ("Use a valid user name", b"alice\r"),
                    ("Existing enterprise slug: [acme]", b"\x1b[C"),
                    ("Account identity", b"\x1b"),
                ],
            )
            self.assertEqual(result, 1, output)
            self.assert_restored(initial, final)

    def test_optional_saved_text_can_be_cleared(self):
        with tempfile.TemporaryDirectory(prefix="wizard-clear-") as directory:
            journal = Path(directory) / "navigation.json"
            entry = {"key": json.dumps({"kind": "text", "title": "Members: ", "options": ""}, separators=(",", ":")),
                     "answer": "alice"}
            journal.write_text(json.dumps({"answers": [entry], "cursor": 0, "replay_until": 0, "back": False}))
            result, output, initial, final = self.helper(
                f"WIZARD_INTERVIEW_DIR={shlex.quote(directory)}; WIZARD_PAGED=true; "
                "wizard_prompt_list users 'Members: ' '' 'Use GitHub usernames.'; printf '\\nRESULT=<%s>\\n' \"$WIZARD_REPLY\"",
                [("Members: [alice]", b":clear\r")],
            )
            self.assertEqual(result, 0, output)
            self.assertIn("RESULT=<>", output)
            self.assertIn("Enter or Right Arrow: continue.", output)
            self.assertIn("Type a command, then press Enter:", output)
            self.assertIn(":clear = empty an optional field", output)
            self.assertIn("\n\n================\n\nUse GitHub usernames.\n", output.replace("\r\n", "\n"))
            self.assertEqual(json.loads(journal.read_text())["answers"][0]["answer"], "")
            self.assert_restored(initial, final)

    def test_empty_pilot_checklist_retries_without_aborting(self):
        result, output, initial, final = self.helper(
            "wizard_select_pilots; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Space: toggle a checkbox.", b" \r"),
             ("Select at least one listed pilot", b"\r")],
        )
        self.assertEqual(result, 0, output)
        self.assertIn('RESULT=["issue-triage"]', output)
        self.assert_restored(initial, final)

    def test_csi_home_end_and_modified_arrow_sequences_are_consumed(self):
        options = json.dumps([{"value": value, "label": value} for value in ("first", "middle", "last")])
        result, output, initial, final = self.helper(
            f"wizard_choose Pick first '' {shlex.quote(options)}; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Choice 1/3.", b"\x1b[4~\x1b[1~\x1b[1;5B\r")],
        )
        self.assertEqual(result, 0, output)
        self.assertIn("RESULT=middle", output)
        self.assert_restored(initial, final)

    def test_narrow_unicode_menu_keeps_complete_characters_and_short_controls(self):
        options = json.dumps([{"value": "first", "label": "報告書" * 10},
                              {"value": "last", "label": "Résumé" * 10}])
        result, output, initial, final = self.helper(
            f"wizard_choose Pick first '' {shlex.quote(options)}; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Enter/Right: next", b"\x1b[B\r")], columns=20,
        )
        self.assertEqual(result, 0, output)
        self.assertIn("RESULT=last", output)
        self.assertNotIn("\ufffd", output, "clipping must not split UTF-8 bytes")
        self.assertIn("Left/B: back", output)
        self.assert_restored(initial, final)

    def test_resizing_a_menu_reclips_rows_and_keeps_the_selection(self):
        options = json.dumps([{"value": "first", "label": "First " * 20},
                              {"value": "last", "label": "Last " * 20}])
        result, output, initial, final = terminal_run(
            f"source {shlex.quote(str(CONFIG))}; WIZARD_ORIGINAL_TTY=$(stty -g); "
            f"wizard_choose Pick first '' {shlex.quote(options)}; printf '\\nRESULT=%s\\n' \"$WIZARD_REPLY\"",
            [("Left/B: back. E: edit. Esc: stop.", b"\x1b[B\r")], resize_to=20,
        )
        self.assertEqual(result, 0, output)
        self.assertIn("RESULT=last", output)
        self.assertIn("\x1b[2J\x1b[H", output)
        resized = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", output.split("\x1b[2J\x1b[H")[-1])
        for line in resized.replace("\r", "").splitlines():
            self.assertLess(len(line), 20, line)
        self.assert_restored(initial, final)

    def test_too_small_terminals_stop_with_plain_mode_guidance(self):
        for rows, columns in ((12, 100), (30, 15)):
            with self.subTest(rows=rows, columns=columns):
                result, output, initial, final = terminal_run(
                    f"source {shlex.quote(str(CONFIG))}; WIZARD_ORIGINAL_TTY=$(stty -g); "
                    "wizard_prompt_bool 'Continue?' true; exit \"$?\"",
                    [], rows=rows, columns=columns,
                )
                self.assertEqual(result, 1, output)
                self.assertIn("16 rows and 20 columns", output)
                self.assertIn("--plain", output)
                self.assert_restored(initial, final)

    def test_invalid_approval_count_preserves_later_choices_when_corrected(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            approval_index = next(i for i, (prompt, _) in enumerate(answers) if prompt.startswith("Required human approvals"))
            answers[-2] = ("Prevent force pushes?", b"\x1b[A\r")
            answers = answers[:-1] + [
                ("Save this configuration?", b"e"),
                ("Edit an earlier answer", b"\x1b[1~" + b"\x1b[B" * approval_index + b"\r"),
                ("Required human approvals (0-6): [1]", b"9\r"),
                ("Invalid value. Enter an integer from 0 to 6", b"1\r"),
                ("Prevent force pushes?", b"\x1b[C"),
                ("Save this configuration?", b"\x1b[C"),
            ]
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            rules = json.loads(output_file.read_text())["organizations"][0]["repositories"][0]["rulesets"][0]["rules"]
            self.assertFalse(any(rule["type"] == "non_fast_forward" for rule in rules))
            self.assertEqual(rules[0]["parameters"]["required_approving_review_count"], 1)
            self.assert_restored(initial, final)

    def test_ctrl_c_does_not_save_and_restores_terminal(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(output_file))}",
                [
                    ("GitHub host: [github.com]", b"\r"),
                    ("Expected authenticated GitHub login:", b"alice\r"),
                    ("Existing enterprise slug:", b"acme\r"),
                    ("Choice 1/2.", b"\x03"),
                ],
            )
            self.assertEqual(result, 130, output)
            self.assertFalse(output_file.exists())
            self.assertEqual(list(Path(directory).iterdir()), [])
            self.assert_restored(initial, final)

    def guided_answers(self):
        return [
                ("GitHub host: [github.com]", b"\r"),
                ("Expected authenticated GitHub login:", b"alice\r"),
                ("Existing enterprise slug:", b"acme\r"),
                ("Choice 1/2.", b"\r"),
                ("Space: toggle a checkbox.", b"\r"),
                ("Enforce the enterprise PAT baseline?", b"\x1b[B\r"),
                ("Enforce the Codespaces baseline?", b"\x1b[B\r"),
                ("Enforce enterprise app approval?", b"\x1b[B\r"),
                ("Remove users when they leave their last organization?", b"\x1b[B\r"),
                ("Require enterprise two-factor authentication?", b"\x1b[B\r"),
                ("Default repository visibility", b"\r"),
                ("Organization setup", b"\r"),
                ("Organization login:", b"acme-org\r"),
                ("Allow the plan to propose updates", b"\x1b[B\r"),
                ("Organization owner logins (comma-separated): [alice]", b"\r"),
                ("Capabilities for this organization", b"\r"),
                ("Add a team?", b"\r"),
                ("Team name: [Developers]", b"\r"),
                ("Team slug: [developers]", b"\r"),
                ("Member logins (comma-separated; blank none):", b"\r"),
                ("Grant this team repository access?", b"\r"),
                ("Repository name within this organization: [service]", b"\r"),
                ("Team repository permission", b"\r"),
                ("Grant this team repository access?", b"\r"),
                ("Add a team?", b"\r"),
                ("Add a repository?", b"\r"),
                ("Explicitly adopt an existing repository?", b"\r"),
                ("Repository name: [service]", b"\r"),
                ("Repository visibility", b"\r"),
                ("Project starter", b"\r"),
                ("Select a workflow for a live CI check", b"\r"),
                ("Add a repository?", b"\r"),
                ("Allowed GitHub Actions", b"\r"),
                ("Additional approved action patterns", b"\r"),
                ("Default workflow token permission", b"\r"),
                ("Require full commit-SHA pins", b"\r"),
                ("CodeQL setup", b"\r"),
                ("Enable Secret Protection and push protection", b"\r"),
                ("Enable Code Quality?", b"\r"),
                ("Add another organization?", b"\r"),
                ("Configure labels, review gates or shared Copilot content?", b"\r"),
                ("Configure labels for acme-org/service?", b"\r"),
                ("Label names", b"\r"),
                ("Configure pull-request review gates", b"\r"),
                ("Required human approvals (0-6): [1]", b"\r"),
                ("Prevent force pushes?", b"\r"),
                ("Save this configuration?", b"\r"),
        ]

    def test_guided_init_defaults_produce_a_usable_reviewed_project(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            config = json.loads(output_file.read_text())
            self.assertEqual(config["defaults"]["packages"], ["actions", "quality", "security", "workspace"])
            policies = config["enterprise"]["policies"]
            self.assertEqual(policies["repository"]["default_branch"], "main")
            self.assertFalse(policies["repository"]["public_repository_creation"])
            self.assertEqual(policies["pat"], {
                "classic_access": "blocked",
                "fine_grained_access": "allowed",
                "approval_required": True,
                "maximum_lifetime_days": 90,
                "enforcement_confirmed": True,
            })
            self.assertEqual(policies["actions"]["fork_approval_policy"], "all_external_contributors")
            self.assertFalse(policies["actions"]["private_fork_workflows"]["send_write_tokens_to_workflows"])
            self.assertTrue(policies["actions"]["disable_repository_runners"])
            self.assertEqual(policies["actions"]["cache_retention_days"], 7)
            self.assertEqual(policies["codespaces"]["machine_types"], [2, 4])
            self.assertEqual(policies["codespaces"]["port_visibility"], "private")
            self.assertTrue(policies["codespaces"]["enforcement_confirmed"])
            self.assertEqual([item["property_name"] for item in policies["custom_properties"]], [
                "data_classification", "service_tier", "lifecycle", "owner",
            ])
            self.assertEqual(policies["rulesets"][0]["enforcement"], "evaluate")
            self.assertTrue(policies["offboarding"]["remove_unaffiliated_users"])
            self.assertTrue(policies["offboarding"]["enforcement_confirmed"])
            self.assertTrue(policies["applications"]["enforcement_confirmed"])
            self.assertTrue(policies["authentication"]["require_two_factor"])
            self.assertTrue(policies["authentication"]["enforcement_confirmed"])
            self.assertNotIn("domains", policies)
            self.assertNotIn("usage", policies["copilot"])
            organization = config["organizations"][0]
            self.assertTrue(organization["adopt"])
            self.assertEqual(config["defaults"]["settings"]["default_repository_permission"], "read")
            self.assertTrue(config["defaults"]["settings"]["members_can_create_repositories"])
            self.assertFalse(config["defaults"]["settings"]["members_can_create_public_repositories"])
            self.assertFalse(config["defaults"]["settings"]["members_can_delete_repositories"])
            self.assertFalse(config["defaults"]["settings"]["members_can_change_repo_visibility"])
            self.assertTrue(config["defaults"]["settings"]["web_commit_signoff_required"])
            self.assertEqual(len(organization["manual_handoffs"]), 1)
            self.assertEqual(organization["teams"][0]["privacy"], "closed")
            self.assertEqual(organization["teams"][0]["repositories"], [{"name": "service", "permission": "push"}])
            self.assertEqual(organization["repositories"][0]["stack"], "node")
            self.assertTrue(organization["repositories"][0]["allow_squash_merge"])
            self.assertFalse(organization["repositories"][0]["allow_merge_commit"])
            self.assertTrue(organization["repositories"][0]["delete_branch_on_merge"])
            self.assertEqual(len(organization["repositories"][0]["labels"]), 4)
            self.assertEqual(organization["repositories"][0]["rulesets"][0]["rules"][0]["parameters"]["required_approving_review_count"], 1)
            self.assertEqual(organization["repositories"][0]["rulesets"][0]["rules"][-1]["type"], "code_scanning")
            self.assertEqual(organization["repositories"][0]["rulesets"][1]["enforcement"], "evaluate")
            self.assertEqual(organization["repositories"][0]["rulesets"][1]["rules"][0], {
                "type": "code_quality", "parameters": {"severity": "errors"},
            })
            self.assertTrue(organization["actions"]["selected_actions"]["github_owned_allowed"])
            self.assertFalse(organization["actions"]["permissions"]["sha_pinning_required"])
            self.assertEqual(organization["actions"]["retention_days"], 90)
            self.assertFalse(organization["actions"]["workflow_permissions"]["can_approve_pull_request_reviews"])
            self.assertEqual(organization["security"]["codeql"], "default")
            self.assertTrue(organization["security"]["purchase"])
            self.assertTrue(organization["security"]["dependency_graph"])
            self.assertTrue(organization["security"]["dependabot_alerts"])
            self.assertTrue(organization["security"]["dependabot_security_updates"])
            self.assertTrue(organization["security"]["dependency_review"])
            self.assertTrue(organization["security"]["triage"])
            self.assertTrue(organization["security"]["secret_scanning"])
            self.assertTrue(organization["security"]["push_protection"])
            self.assertEqual(organization["security"]["configuration_name"], "enterprise-security-baseline")
            self.assertEqual(organization["security"]["settings"]["secret_scanning_validity_checks"], "enabled")
            self.assertEqual(organization["security"]["settings"]["secret_scanning_non_provider_patterns"], "enabled")
            self.assertEqual(organization["security"]["settings"]["secret_scanning_generic_secrets"], "enabled")
            self.assertEqual(organization["security"]["settings"]["private_vulnerability_reporting"], "enabled")
            self.assertEqual(organization["quality"], {
                "enabled": True, "live_analysis": True, "purchase": True, "enforce": False,
            })
            self.assertEqual(output_file.stat().st_mode & 0o777, 0o600)
            self.assertIn("Review your configuration", output)
            self.assertIn("doctor --config", output)
            self.assertIn("plan --config", output)
            self.assert_restored(initial, final)

    def test_new_organization_retries_billing_email_and_never_offers_adoption(self):
        with tempfile.TemporaryDirectory(prefix="wizard-create-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            answers[4] = ("Space: toggle a checkbox.", b"\x1b[B" * 3 + b" \x1b[C")
            setup_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Organization setup")
            answers[setup_index] = ("Organization setup", b"\x1b[B\x1b[C")
            answers = [(prompt, answer) for prompt, answer in answers
                       if prompt not in ("Allow the plan to propose updates", "Explicitly adopt an existing repository?")]
            owners_index = next(i for i, (prompt, _) in enumerate(answers) if prompt.startswith("Organization owner logins"))
            answers[owners_index + 1:owners_index + 1] = [
                ("Organization billing email:", b"not-an-email\r"),
                ("Invalid value. Enter a billing email", b"ops@example.com\r"),
            ]
            settings_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "CodeQL setup")
            answers[settings_index:settings_index] = [
                ("Copilot seat user logins", b"\r"), ("Copilot seat team slugs", b"\r"),
                ("Enable the Kimi model family", b"\r"),
                ("Enable the Claude Fable model family", b"\r"),
            ]
            answers[-1:-1] = [
                ("Write repository Copilot instructions", b"\x1b[C"),
                ("Configure shared Copilot content", b"\x1b[C"),
                ("Write a private member profile?", b"\x1b[C"),
                ("Local Markdown agent file to copy", b"\r"),
            ]
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            organization = json.loads(output_file.read_text())["organizations"][0]
            self.assertTrue(organization["create"])
            self.assertFalse(organization["adopt"])
            self.assertEqual(organization["billing_email"], "ops@example.com")
            self.assertTrue(all(not repo["adopt"] for repo in organization["repositories"]))
            self.assertEqual(organization["repositories"][-1]["name"], ".github-private")
            self.assertEqual(
                [agent["path"] for agent in organization["copilot"]["agents"]],
                [
                    "agents/security-reviewer.md",
                    "agents/ci-investigator.md",
                    "agents/test-author.md",
                    "agents/documentation-maintainer.md",
                ],
            )
            self.assertNotIn("Explicitly adopt an existing", output)
            self.assert_restored(initial, final)

    def test_duplicate_teams_and_repositories_retry_before_advancing(self):
        with tempfile.TemporaryDirectory(prefix="wizard-duplicates-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            name_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Team name: [Developers]")
            answers[name_index] = ("Team name: [Developers]", b"Core Team\r")
            answers[name_index + 1] = ("Team slug: [core-team]", b"\r")
            team_index = [i for i, (prompt, _) in enumerate(answers) if prompt == "Add a team?"][1]
            answers[team_index:team_index + 1] = [
                ("Add a team?", b"\x1b[B\x1b[C"),
                ("Team name: [Developers]", b"Core-Team\r"),
                ("Invalid value. Use a distinct team name", b"Platform\r"),
                ("Team slug: [platform]", b"CORE-TEAM\r"),
                ("Already listed: CORE-TEAM", b"\r"),
                ("Member logins", b"\r"),
                ("Grant this team repository access?", b"\x1b[A\x1b[C"),
                ("Add a team?", b"\x1b[C"),
            ]
            repo_index = [i for i, (prompt, _) in enumerate(answers) if prompt == "Add a repository?"][1]
            answers[repo_index:repo_index + 1] = [
                ("Add a repository?", b"\x1b[B\x1b[C"),
                ("Explicitly adopt an existing repository?", b"\x1b[C"),
                ("Repository name: [service]", b"\r"),
                ("Already listed: service", b"worker\r"),
                ("Repository visibility", b"\x1b[C"),
                ("Project starter", b"\x1b[C"),
                ("Select a workflow for a live CI check", b"\x1b[C"),
                ("Add a repository?", b"\x1b[C"),
            ]
            answers[-1:-1] = [
                ("Configure labels for acme-org/worker?", b"\r"),
                ("Label names", b"\r"),
                ("Configure pull-request review gates for acme-org/worker?", b"\r"),
                ("Required human approvals (0-6): [1]", b"\r"),
                ("Prevent force pushes?", b"\r"),
            ]
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            organization = json.loads(output_file.read_text())["organizations"][0]
            self.assertEqual([team["slug"] for team in organization["teams"]], ["core-team", "platform"])
            self.assertEqual([repo["name"] for repo in organization["repositories"]], ["service", "worker"])
            self.assert_restored(initial, final)

    def test_copilot_purchase_is_offered_only_with_explicit_recipients(self):
        for users, teams in (("", ""), (" , , ", " , "), ("alice", ""), ("", "developers")):
            with self.subTest(users=users, teams=teams), tempfile.TemporaryDirectory(prefix="wizard-copilot-") as directory:
                output_file = Path(directory) / "config.json"
                has_recipients = users == "alice" or teams == "developers"
                answers = self.guided_answers()
                answers[4] = ("Space: toggle a checkbox.", b"\x1b[B" * 3 + b" \x1b[C")
                settings_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "CodeQL setup")
                copilot_answers = [
                    ("Copilot seat user logins", users.encode() + b"\r"),
                    ("Copilot seat team slugs", teams.encode() + b"\r"),
                ]
                if has_recipients:
                    copilot_answers.append(("Enable Copilot seats for the selected users and teams", b"\x1b[B\x1b[C"))
                copilot_answers.extend([
                    ("Enable the Kimi model family", b"\x1b[C"),
                    ("Enable the Claude Fable model family", b"\x1b[C"),
                ])
                answers[settings_index:settings_index] = copilot_answers
                answers[-1:-1] = [
                    ("Write repository Copilot instructions", b"\x1b[C"),
                    ("Configure shared Copilot content", b"\x1b[A\x1b[C"),
                ]
                result, output, initial, final = terminal_run(
                    f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                    answers,
                )
                self.assertEqual(result, 0, output)
                copilot = json.loads(output_file.read_text())["organizations"][0]["copilot"]
                self.assertEqual(copilot["purchase"], has_recipients)
                self.assertEqual(copilot["users"], ["alice"] if users == "alice" else [])
                self.assertEqual(copilot["teams"], ["developers"] if teams == "developers" else [])
                self.assertEqual(copilot["mcp"], {"enabled": True, "approved_servers_only": True})
                self.assertEqual(copilot["models"], {
                    "default_availability": True, "kimi": False, "fable": False,
                })
                self.assertEqual(copilot["features"]["cloud_agent"], "selected")
                self.assertEqual(copilot["features"]["review_effort"], "balanced")
                self.assertFalse(copilot["features"]["copilot_approvals"])
                if not has_recipients:
                    self.assertNotIn("Enable Copilot seats for the selected users and teams", output)
                    self.assertIn("Seat purchase is skipped", output)
                self.assertNotIn("even if cost is unknown", output)
                self.assertNotIn("Resolve configuration error", output)
                self.assert_restored(initial, final)

    def test_security_and_quality_use_feature_choices_without_cost_confirmations(self):
        for codeql, protection, quality in (("none", False, False), ("default", True, True), ("none", True, False)):
            with self.subTest(codeql=codeql, protection=protection, quality=quality), tempfile.TemporaryDirectory(prefix="wizard-features-") as directory:
                output_file = Path(directory) / "config.json"
                answers = self.guided_answers()
                settings_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Add another organization?")
                feature_start = settings_index - 3
                answers[feature_start:settings_index] = [
                    ("CodeQL setup", (b"\x1b[H" if codeql == "none" else b"") + b"\x1b[C"),
                    ("Enable Secret Protection and push protection", (b"" if protection else b"\x1b[A") + b"\x1b[C"),
                    ("Enable Code Quality?", (b"" if quality else b"\x1b[A") + b"\x1b[C"),
                ]
                result, output, initial, final = terminal_run(
                    f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                    answers,
                )
                self.assertEqual(result, 0, output)
                organization = json.loads(output_file.read_text())["organizations"][0]
                self.assertEqual(organization["security"]["codeql"], codeql)
                self.assertEqual(organization["security"]["purchase"], codeql != "none" or protection)
                self.assertEqual(organization["security"].get("secret_scanning", False), protection)
                self.assertTrue(organization["security"]["dependency_graph"])
                self.assertTrue(organization["security"]["dependabot_alerts"])
                self.assertTrue(organization["security"]["dependabot_security_updates"])
                self.assertEqual(organization["security"]["dependency_review"], codeql != "none")
                self.assertEqual(
                    organization["security"]["settings"]["code_scanning_default_setup"],
                    "enabled" if codeql == "default" else "disabled" if codeql == "advanced" else "not_set",
                )
                self.assertEqual(
                    organization["security"]["settings"]["secret_scanning_generic_secrets"],
                    "enabled" if protection else "not_set",
                )
                self.assertEqual(organization["quality"], {
                    "enabled": quality, "live_analysis": quality, "purchase": quality, "enforce": False,
                })
                self.assertNotIn("even if cost is unknown", output)
                self.assertNotIn("Select required", output)
                self.assertNotIn("Select Code Quality live analysis", output)
                self.assert_restored(initial, final)

    def test_apply_uses_one_plan_approval_without_a_cost_confirmation(self):
        with tempfile.TemporaryDirectory(prefix="wizard-approval-") as directory:
            plan = Path(directory) / "plan.json"
            digest = "a" * 64
            plan.write_text(json.dumps({
                "host": "github.com", "actor": "alice", "digest": digest,
                "warnings": ["Selected features may incur charges."],
                "actions": [{"id": "seats", "kind": "purchase", "cost": {"known": False}}],
            }))
            result, output, initial, final = terminal_run(
                f"source {shlex.quote(str(ROOT / 'lib' / 'api.sh'))}; "
                f"source {shlex.quote(str(ROOT / 'lib' / 'execute.sh'))}; "
                f"wizard_approve {shlex.quote(str(plan))} ''",
                [("Type the plan digest to approve:", digest.encode() + b"\r")],
            )
            self.assertEqual(result, 0, output)
            self.assertEqual(output.count("Type the plan digest to approve"), 1)
            self.assertNotIn("including unknown costs", output)
            plain_output = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", output)
            self.assertIn('"known": false', plain_output)
            self.assert_restored(initial, final)

    def test_active_username_is_suggested_and_enterprises_are_read_only(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(output_file))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login: [alice]", b"\r"),
                 ("Existing enterprise slug", b"\r"), ("Account identity", b"\x1b")],
                discovery={"accounts": {"github.com": [{"login": "alice", "active": True, "state": "success"}]},
                           "enterprises": {"github.com": ["acme"]}},
                calls_sink=calls,
            )
            self.assertEqual(result, 1, output)
            self.assertFalse(output_file.exists())
            self.assertEqual(len(calls), 2)
            self.assertEqual(calls[0]["args"][:2], ["auth", "status"])
            self.assertNotIn("--show-token", calls[0]["args"])
            self.assertTrue(calls[1]["body"]["query"].startswith("query("))
            self.assert_restored(initial, final)

    def test_inactive_account_selection_never_switches_or_discovers_under_the_wrong_identity(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("GitHub account", b"\x1b[B\r"),
                 ("Existing enterprise slug:", b"acme\r"), ("Account identity", b"\x1b")],
                discovery={"accounts": {"github.com": [
                    {"login": "alice", "active": True, "state": "success"},
                    {"login": "bob", "active": False, "state": "success"}]}},
                calls_sink=calls,
            )
            self.assertEqual(result, 1, output)
            self.assertIn("gh auth switch --hostname github.com --user bob", output)
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0]["args"][:2], ["auth", "status"])
            self.assert_restored(initial, final)

    def test_back_preserves_answers_and_changed_actor_clears_later_scope(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login: [alice]", b"\r"),
                 ("Existing enterprise slug", b"\r"), ("Account identity", b"b"),
                 ("Existing enterprise slug", b"b"), ("Expected authenticated GitHub login: [alice]", b"bob\r"),
                 ("Existing enterprise slug:", b"beta\r"), ("Account identity", b"\x1b")],
                discovery={"accounts": {"github.com": [{"login": "alice", "active": True, "state": "success"}]},
                           "enterprises": {"github.com": ["acme"]}},
                calls_sink=calls,
            )
            self.assertEqual(result, 1, output)
            self.assertIn("Back: earlier answers are kept", output)
            self.assertEqual(len(calls), 2, "cached read-only lookups must not run again on Back")
            self.assert_restored(initial, final)

    def test_tenant_organization_suggestions_are_scoped_to_selected_enterprise(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"customer.ghe.com\r"),
                 ("Expected authenticated GitHub login: [tenant-admin]", b"\r"),
                 ("Existing enterprise slug", b"\r"), ("Account identity", b"\r"),
                 ("Space: toggle a checkbox", b"\r"),
                 ("Enforce the enterprise PAT baseline?", b"\r"),
                 ("Enforce the Codespaces baseline?", b"\r"),
                 ("Enforce enterprise app approval?", b"\r"),
                 ("Remove users when they leave their last organization?", b"\r"),
                 ("Require enterprise two-factor authentication?", b"\r"),
                 ("Default repository visibility", b"\r"),
                 ("Organization setup", b"\r"), ("Organization login", b"\r"),
                 ("Allow the plan to propose updates", b"\x1b")],
                discovery={"accounts": {"customer.ghe.com": [{"login": "tenant-admin", "active": True, "state": "success"}]},
                           "enterprises": {"customer.ghe.com": ["scope-acme"]},
                           "organizations": {"customer.ghe.com/scope-acme": ["engineering"]}},
                calls_sink=calls,
            )
            self.assertEqual(result, 1, output)
            self.assertEqual(len(calls), 3)
            for call in calls:
                args = call["args"]
                self.assertEqual(args[args.index("--hostname") + 1], "customer.ghe.com")
            self.assertEqual(calls[-1]["body"]["variables"]["slug"], "scope-acme")
            self.assert_restored(initial, final)

    def test_no_discovery_keeps_manual_input_offline(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login:", b"alice\r"),
                 ("Existing enterprise slug:", b"acme\r"), ("Account identity", b"\x1b")],
                calls_sink=calls,
            )
            self.assertEqual(result, 1, output)
            self.assertEqual(calls, [])
            self.assertNotIn("Looking up", output)
            self.assert_restored(initial, final)

    def test_failed_lookup_is_cached_and_keeps_diagnostics_private(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(output_file))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login:", b"alice\r"),
                 ("Existing enterprise slug:", b"acme\r"), ("Account identity", b"b"),
                 ("Existing enterprise slug: [acme]", b":back\r"),
                 ("Expected authenticated GitHub login: [alice]", b"\r"),
                 ("Existing enterprise slug: [acme]", b"\r"), ("Account identity", b"\x1b")],
                discovery={"account_failure": True}, calls_sink=calls,
            )
            self.assertEqual(result, 1, output)
            self.assertIn("unavailable. Check gh authentication", output)
            self.assertNotIn("DO_NOT_DISPLAY", output)
            self.assertEqual(len(calls), 1)
            self.assertFalse(output_file.exists())
            self.assert_restored(initial, final)

    def test_lookup_timeout_stops_the_process_and_allows_manual_input(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login:", b"alice\r"),
                 ("Existing enterprise slug:", b"acme\r"), ("Account identity", b"\x1b")],
                discovery={"account_delay": 15}, calls_sink=calls, environment={"TMPDIR": directory},
            )
            self.assertEqual(result, 1, output)
            self.assertIn("timed out. Enter the value manually", output)
            self.assertEqual(len(calls), 1)
            with self.assertRaises(ProcessLookupError):
                os.kill(calls[0]["pid"], 0)
            self.assertEqual(list(Path(directory).iterdir()), [])
            self.assert_restored(initial, final)

    def test_ctrl_c_stops_inflight_discovery_and_removes_interview_state(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("Looking up accounts", b"\x03")],
                discovery={"account_delay": 15}, calls_sink=calls, environment={"TMPDIR": directory},
            )
            self.assertEqual(result, 130, output)
            self.assertEqual(list(Path(directory).iterdir()), [])
            for call in calls:
                with self.assertRaises(ProcessLookupError):
                    os.kill(call["pid"], 0)
            self.assert_restored(initial, final)

    def test_repository_suggestions_use_the_selected_host_and_organization(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            answers = [(prompt, b"\x1b[B\r" if prompt == "Explicitly adopt an existing repository?" else answer)
                       for prompt, answer in answers if prompt != "Repository name: [service]"]
            adoption_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Explicitly adopt an existing repository?")
            answers.insert(adoption_index + 1, ("Existing repository", b"\r"))
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --output {shlex.quote(str(output_file))}",
                answers,
                discovery={"accounts": {"github.com": [{"login": "alice", "active": True, "state": "success"}]},
                           "repositories": {"github.com/acme-org": ["service"]}},
                calls_sink=calls,
            )
            self.assertEqual(result, 0, output)
            repository = json.loads(output_file.read_text())["organizations"][0]["repositories"][0]
            self.assertTrue(repository["adopt"])
            self.assertEqual(repository["name"], "service")
            self.assertEqual(repository["stack"], "none")
            repository_calls = [call["args"] for call in calls if "--method" in call["args"] and "GET" in call["args"]]
            self.assertEqual(len(repository_calls), 1)
            self.assertIn("/orgs/acme-org/repos?per_page=100", repository_calls[0])
            self.assertEqual(repository_calls[0][repository_calls[0].index("--hostname") + 1], "github.com")
            self.assert_restored(initial, final)

    def test_editing_team_name_rebuilds_the_configuration_with_a_new_slug(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            team_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Team name: [Developers]")
            answers = answers[:-1] + [
                ("Save this configuration?", b"e"),
                ("Edit an earlier answer", b"\x1b[H" + b"\x1b[B" * team_index + b"\r"),
                ("Team name: [Developers]", b"Platform\r"),
            ] + [(prompt.replace("[developers]", "[platform]"), answer)
                 for prompt, answer in self.guided_answers()[team_index + 1:]]
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            team = json.loads(output_file.read_text())["organizations"][0]["teams"][0]
            self.assertEqual(team["name"], "Platform")
            self.assertEqual(team["slug"], "platform")
            self.assert_restored(initial, final)

    def test_validation_error_opens_the_editor_without_losing_earlier_answers(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            team_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Team name: [Developers]")
            answers[team_index] = ("Team name: [Developers]", b"Engineers\r")
            answers[team_index + 1] = ("Team slug: [engineers]", b"not-engineers\r")
            answers = answers[:-1] + [
                ("Resolve configuration error", b"\r"),
                ("Edit an earlier answer", b"\x1b[H" + b"\x1b[B" * team_index + b"\r"),
                ("Team name: [Engineers]", b"Developers\r"),
            ] + self.guided_answers()[team_index + 1:]
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            config = json.loads(output_file.read_text())
            self.assertEqual(config["actor"], "alice")
            self.assertEqual(config["organizations"][0]["teams"][0]["slug"], "developers")
            self.assert_restored(initial, final)

    def test_invalid_review_stays_in_section_six_and_can_cancel_without_restarting(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            team_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Team name: [Developers]")
            answers[team_index] = ("Team name: [Developers]", b"Engineers\r")
            answers[team_index + 1] = ("Team slug: [engineers]", b"not-engineers\r")
            answers = answers[:-1] + [
                ("Resolve configuration error", b"\x1b[C"),
                ("Right/Left: return. Esc: stop.", b"\x1b[C"),
                ("Resolve configuration error", b"\x1b[B\x1b[C"),
            ]
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 1, output)
            self.assertFalse(output_file.exists())
            self.assertIn("slug must match", output)
            self.assertIn("Cancel interview without saving", output)
            self.assertIn("Interview cancelled. No configuration was saved.", output)
            self.assertEqual(output.count("Team name: [Developers]"), 1)
            review_output = output[output.index("Resolve configuration error"):]
            self.assertNotIn("Section 4/6", review_output)
            self.assertNotIn("Section 5/6", review_output)
            self.assert_restored(initial, final)

    def test_right_returns_from_answer_editor_and_final_review_saves_once(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()[:-1] + [
                ("Save this configuration?", b"e"),
                ("Right/Left: return. Esc: stop.", b"\x1b[C"),
                ("Save this configuration?", b"\x1b[C"),
            ]
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            self.assertEqual(json.loads(output_file.read_text())["organizations"][0]["teams"][0]["slug"], "developers")
            self.assertEqual(output.count("GitHub host:"), 1)
            self.assertEqual(output.count("Saved configuration:"), 1)
            self.assertIn("Enter: edit answer.", output)
            self.assert_restored(initial, final)

    def test_right_returns_from_text_field_editor_without_replaying_earlier_questions(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login:", b"alice\r"),
                 ("Existing enterprise slug:", b":edit\r"),
                 ("Right/Left: return. Esc: stop.", b"\x1b[C"),
                 ("Existing enterprise slug:", b"acme\r"), ("Account identity", b"\x1b")],
            )
            self.assertEqual(result, 1, output)
            self.assertEqual(output.count("GitHub host:"), 1)
            self.assertEqual(output.count("Expected authenticated GitHub login:"), 1)
            self.assertEqual(output.count("Existing enterprise slug:"), 2)
            self.assert_restored(initial, final)

    def test_plain_editor_has_an_explicit_return_option(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --plain --no-discovery --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login:", b"alice\r"),
                 ("Existing enterprise slug:", b":edit\r"),
                 ("Edit an earlier answer: [Return without editing]", b"\r"),
                 ("Existing enterprise slug:", b"\x03")],
            )
            self.assertEqual(result, 130, output)
            self.assertEqual(output.count("GitHub host:"), 1)
            self.assertIn("Return without editing", output)
            self.assert_restored(initial, final)

    def test_answer_editor_preserves_text_and_filters_only_control_characters(self):
        with tempfile.TemporaryDirectory(prefix="wizard-editor-") as directory:
            entries = [
                ("text", "GitHub host: ", "", "github.com"),
                ("text", "Expected authenticated GitHub login: ", "", "alice-sandbox_emu"),
                ("multi", "Capabilities", "[]", '["workspace","actions","security"]'),
                ("text", "Notes: ", "", "first\tsecond\nthird\u0000last\u007f"),
            ]
            answers = [{"key": json.dumps({"kind": kind, "title": title, "options": options}), "answer": answer}
                       for kind, title, options, answer in entries]
            journal = Path(directory) / "navigation.json"
            journal.write_text(json.dumps({"answers": answers, "cursor": len(answers), "replay_until": 0, "back": False}))
            result, output, initial, final = terminal_run(
                f"source {shlex.quote(str(CONFIG))}; WIZARD_ORIGINAL_TTY=$(stty -g); "
                f"WIZARD_INTERVIEW_DIR={shlex.quote(directory)}; wizard_edit_answers",
                [("Choice 4/4.", b"\x1b[H\r")],
            )
            self.assertEqual(result, 1, output)
            self.assertIn("GitHub host = github.com", output)
            self.assertIn("Expected authenticated GitHub login = alice-sandbox_emu", output)
            self.assertIn('Capabilities = ["workspace","actions","security"]', output)
            self.assertIn("Notes = first second third last ", output)
            self.assertNotIn("first\tsecond", output)
            self.assertNotIn("\u0000", output)
            self.assertNotIn("\u007f", output)
            saved = json.loads(journal.read_text())
            self.assertEqual(saved["answers"], answers, "display sanitization must not change saved answers")
            self.assertEqual(saved["replay_until"], 0)
            self.assertTrue(saved["back"])
            self.assert_restored(initial, final)

    def test_no_color_disables_styling_without_disabling_keyboard_selection(self):
        result, output, initial, final = terminal_run(
            f"source {shlex.quote(str(CONFIG))}; WIZARD_ORIGINAL_TTY=$(stty -g); wizard_section Heading Explanation; wizard_prompt_bool 'Continue?' true",
            [("Choice 2/2.", b"\r")], environment={"NO_COLOR": ""},
        )
        self.assertEqual(result, 0, output)
        self.assertNotIn("\x1b[1;36m", output)
        self.assertNotIn("\x1b[32m", output)
        self.assertIn("Heading", output)
        self.assert_restored(initial, final)

    def test_page_header_colors_progress_and_estimate_and_honors_no_color(self):
        with tempfile.TemporaryDirectory(prefix="wizard-header-") as directory:
            (Path(directory) / "navigation.json").write_text(json.dumps({"cursor": 40}))
            command = (
                f"source {shlex.quote(str(CONFIG))}; WIZARD_PAGED=true; "
                f"WIZARD_INTERVIEW_DIR={shlex.quote(directory)}; "
                "wizard_section '4. Capability settings' ''; wizard_page Question"
            )
            for no_color in (None, ""):
                with self.subTest(no_color=no_color):
                    result, output, initial, final = terminal_run(
                        command, [], environment={"NO_COLOR": no_color},
                    )
                    self.assertEqual(result, 0, output)
                    if no_color is None:
                        self.assertIn("\x1b[36mSection 4/6: Capability settings", output)
                        self.assertIn("\x1b[32m[===>..]\x1b[0m", output)
                        self.assertIn("\x1b[1;36m Question 41", output)
                        self.assertIn("\x1b[33mEstimate: 5-10 min", output)
                        self.assertIn("\x1b[36mMore packages or organizations take longer.", output)
                    else:
                        self.assertNotRegex(output, r"\x1b\[[0-9;]*m")
                        self.assertIn("[===>..] Question 41", output)
                    self.assert_restored(initial, final)

    def test_clean_pages_restore_nondefault_choices_when_moving_back_and_forward(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            output_file = Path(directory) / "config.json"
            answers = self.guided_answers()
            setup_index = next(i for i, (prompt, _) in enumerate(answers) if prompt == "Organization setup")
            answers[3:setup_index + 1] = [
                ("Account identity", b"\x1b[B\x1b[C"),
                ("Space: toggle a checkbox.", b" \x1b[C"),
                ("Enforce the enterprise PAT baseline?", b"\r"),
                ("Enforce the Codespaces baseline?", b"\r"),
                ("Enforce enterprise app approval?", b"\r"),
                ("Default repository visibility", b"\x1b[D"),
                ("Enforce enterprise app approval?", b"\x1b[D"),
                ("Enforce the Codespaces baseline?", b"\x1b[D"),
                ("Enforce the enterprise PAT baseline?", b"\x1b[D"),
                ("Space: toggle a checkbox.", b"\x1b[D"),
                ("Account identity", b"\x1b[C"),
                ("Space: toggle a checkbox.", b"\x1b[C"),
                ("Enforce the enterprise PAT baseline?", b"\x1b[C"),
                ("Enforce the Codespaces baseline?", b"\x1b[C"),
                ("Enforce enterprise app approval?", b"\x1b[C"),
                ("Default repository visibility", b"\x1b[B\x1b[C"),
                ("Organization setup", b"\x1b[D"),
                ("Default repository visibility", b"\x1b[C"),
                ("Organization setup", b"\x1b[C"),
            ]
            answers[-1] = ("Save this configuration?", b"\x1b[C")
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(output_file))}",
                answers,
            )
            self.assertEqual(result, 0, output)
            config = json.loads(output_file.read_text())
            self.assertEqual(config["enterprise"]["identity"], "emu")
            self.assertEqual(config["defaults"]["repository_visibility"], "internal")
            self.assertEqual(config["defaults"]["packages"], ["actions", "quality", "security", "workspace"])
            frames = [re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", frame).replace("\r", "")
                      for frame in output.split("\x1b[2J\x1b[H")[1:]]
            account_frames = [frame for frame in frames if "\nAccount identity\n" in frame]
            self.assertEqual(len(account_frames), 2, "rebuilding the config must not redisplay earlier pages")
            self.assertIn("> Enterprise Managed Users", account_frames[-1])
            package_frames = [frame for frame in frames if "\nCapabilities\n" in frame]
            self.assertEqual(len(package_frames), 3)
            self.assertIn("[ ] Organizations and workspace", package_frames[-1])
            self.assertIn("[x] Actions and developer experience", package_frames[-1])
            self.assertEqual(sum("GitHub host:" in frame for frame in frames), 1)
            self.assertIn("Section 6/6: Review and save", frames[-1])
            self.assertIn("Review your configuration", frames[-1])
            self.assertIn("Estimate: 5-10 min", frames[0])
            self.assert_restored(initial, final)

    def test_right_arrow_keeps_saved_text_and_replay_stays_hidden(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --no-discovery --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\x1b[C"),
                 ("Expected authenticated GitHub login:", b"alice\r"),
                 ("Existing enterprise slug:", b"acme\r"),
                 ("Account identity", b"\x1b[D"),
                 ("Existing enterprise slug: [acme]", b":back\r"),
                 ("Expected authenticated GitHub login: [alice]", b"\x1b[C"),
                 ("Existing enterprise slug: [acme]", b"\x1b[C"),
                 ("Account identity", b"\x1b")],
            )
            self.assertEqual(result, 1, output)
            self.assertEqual(output.count("GitHub host:"), 1)
            self.assertEqual(output.count("Expected authenticated GitHub login:"), 2)
            self.assertIn("Saved answer shown below", output)
            self.assertNotIn("warning: line editing", output)
            self.assert_restored(initial, final)

    def test_plain_mode_keeps_scrollable_output_without_clear_screen_sequences(self):
        with tempfile.TemporaryDirectory(prefix="wizard-interview-") as directory:
            result, output, initial, final = terminal_run(
                f"/bin/bash {shlex.quote(str(ENTRYPOINT))} init --plain --no-discovery --output {shlex.quote(str(Path(directory) / 'config.json'))}",
                [("GitHub host:", b"\r"), ("Expected authenticated GitHub login:", b"alice\r"),
                 ("Existing enterprise slug:", b"acme\r"),
                 ("Account identity:", b":back\r"),
                 ("Existing enterprise slug: [acme]", b"\x03")],
            )
            self.assertEqual(result, 130, output)
            self.assertNotIn("\x1b[2J", output)
            self.assert_restored(initial, final)


if __name__ == "__main__":
    unittest.main()
