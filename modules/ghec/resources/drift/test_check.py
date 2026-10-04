import contextlib
import copy
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from check import assess, inspect, main, policy_from, validate_baseline


class DriftTests(unittest.TestCase):
    def setUp(self):
        self.payload = {
            "id": 42, "enforcement": "active", "target": "branch",
            "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
            "rules": [
                {"type": "pull_request", "parameters": {"required_approving_review_count": 1}},
                {"type": "required_status_checks", "parameters": {
                    "required_status_checks": [{"context": "test", "integration_id": 12}],
                    "strict_required_status_checks_policy": True,
                }},
            ],
        }
        self.baseline = {
            "schema_version": 1, "repository": "example/service", "hostname": "github.com",
            "ruleset_id": 42, "policy": policy_from(self.payload),
        }

    def test_pass_drift_repair(self):
        expected = self.baseline["policy"]
        actual = copy.deepcopy(expected)
        self.assertEqual(assess(actual, expected)[1], 0)
        actual["enforcement"] = "disabled"
        self.assertEqual(assess(actual, expected)[1], 1)
        actual["enforcement"] = "active"
        self.assertEqual(assess(actual, expected)[1], 0)

    def test_review_check_and_target_changes_fail(self):
        for mutation in (
            lambda p: p["rules"][0]["parameters"].update(required_approving_review_count=0),
            lambda p: p["rules"][1]["parameters"].update(required_status_checks=[]),
            lambda p: p["conditions"]["ref_name"]["exclude"].append("refs/heads/main"),
            lambda p: p.update(target="tag"),
        ):
            payload = copy.deepcopy(self.payload)
            mutation(payload)
            self.assertEqual(assess(policy_from(payload), self.baseline["policy"])[1], 1)

    def test_order_and_unmonitored_fields_do_not_create_false_alerts(self):
        payload = copy.deepcopy(self.payload)
        payload["rules"].reverse()
        payload.update(updated_at="later", name="Renamed", bypass_actors=[])
        self.assertEqual(assess(policy_from(payload), self.baseline["policy"])[1], 0)

    def test_boolean_is_not_an_integer(self):
        payload = copy.deepcopy(self.payload)
        payload["rules"][0]["parameters"]["required_approving_review_count"] = True
        self.assertEqual(assess(policy_from(payload), self.baseline["policy"])[1], 1)

    def test_malformed_policy_is_unavailable(self):
        for field, value in (
            ("enforcement", None), ("target", "unknown"), ("conditions", []),
            ("conditions", {}), ("conditions", {"ref_name": {"include": "main", "exclude": []}}),
            ("rules", None), ("rules", [{}]), ("rules", [{"type": "pull_request", "parameters": []}]),
        ):
            payload = {**self.payload, field: value}
            with self.assertRaises(ValueError):
                policy_from(payload)

    def test_invalid_baseline_does_not_query_github(self):
        for baseline in (
            None, {**self.baseline, "schema_version": True},
            {**self.baseline, "repository": "other/repo"},
            {**self.baseline, "repository": None}, {**self.baseline, "repository": 7},
            {**self.baseline, "extra": "unsupported"},
            {**self.baseline, "hostname": "other.ghe.com"},
            {**self.baseline, "ruleset_id": True},
            {**self.baseline, "ruleset_id": 0},
            {**self.baseline, "policy": {**self.baseline["policy"], "enforcement": "evaluate"}},
            {**self.baseline, "policy": {**self.baseline["policy"], "rules": []}},
            {**self.baseline, "policy": {**self.baseline["policy"], "bypass_actors": []}},
        ):
            with patch("check.subprocess.run") as run:
                self.assertEqual(inspect("example/service", baseline, "github.com")[1], 2)
                run.assert_not_called()

    @patch("check.subprocess.run")
    def test_api_success_and_host_binding(self, run):
        run.return_value.stdout = json.dumps(self.payload)
        report, code = inspect("example/service", self.baseline, "github.com")
        self.assertEqual(code, 0)
        self.assertEqual(report["ruleset_id"], 42)
        self.assertIn("repos/example/service/rulesets/42?includes_parents=true", run.call_args.args[0])
        self.assertIn("--hostname", run.call_args.args[0])
        baseline = {**self.baseline, "hostname": "customer.ghe.com"}
        self.assertEqual(inspect("example/service", baseline, "customer.ghe.com")[1], 0)
        self.assertIn("customer.ghe.com", run.call_args.args[0])

    @patch("check.subprocess.run")
    def test_unreadable_evidence(self, run):
        for error in (
            FileNotFoundError(), subprocess.TimeoutExpired("gh", 30),
            subprocess.CalledProcessError(1, "gh", stderr="private details"),
        ):
            run.side_effect = error
            report, code = inspect("example/service", self.baseline, "github.com")
            self.assertEqual(code, 2)
            self.assertEqual(report["result"], "unavailable")
            self.assertNotIn("private details", str(report))

    @patch("check.subprocess.run")
    def test_invalid_api_payload_and_wrong_id(self, run):
        for payload in ("not json", "[]", "null", json.dumps({**self.payload, "id": 99})):
            run.return_value.stdout = payload
            self.assertEqual(inspect("example/service", self.baseline, "github.com")[1], 2)

    @patch.dict(os.environ, {"GH_HOST": "github.com"})
    @patch("check.subprocess.run")
    def test_capture_emits_a_usable_baseline(self, run):
        run.return_value.stdout = json.dumps(self.payload)
        output = io.StringIO()
        with patch.object(sys, "argv", ["check.py", "example/service", "--capture", "42"]), \
                contextlib.redirect_stdout(output):
            self.assertEqual(main(), 0)
        self.assertEqual(validate_baseline(json.loads(output.getvalue()), "example/service", "github.com"),
                         self.baseline["policy"])

    @patch.dict(os.environ, {"GH_HOST": "github.com"})
    @patch("check.subprocess.run")
    def test_cli_reads_baseline_and_returns_drift(self, run):
        run.return_value.stdout = json.dumps({**self.payload, "enforcement": "disabled"})
        with tempfile.TemporaryDirectory() as directory:
            file = os.path.join(directory, "baseline.json")
            with open(file, "w", encoding="utf-8") as target:
                json.dump(self.baseline, target)
            with patch.object(sys, "argv", ["check.py", "example/service", "--baseline", file]), \
                    contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(main(), 1)

    def test_workflow_steps_report_pass_drift_and_unavailable(self):
        here = Path(__file__).resolve().parent
        workflow = (here / "ruleset-drift.yml").read_text()
        steps = [
            "\n".join(line[10:] for line in match.splitlines()) + "\n"
            for match in re.findall(r"        run: \|\n((?:          .*\n|[ \t]*\n)+)", workflow)
        ]
        self.assertEqual(len(steps), 2)
        for payload, expected in (
            (self.payload, 0), ({**self.payload, "enforcement": "disabled"}, 1), (None, 2),
        ):
            with self.subTest(expected=expected), tempfile.TemporaryDirectory() as directory:
                work = Path(directory)
                scripts = work / ".github/scripts"
                scripts.mkdir(parents=True)
                shutil.copyfile(here / "check.py", scripts / "check.py")
                (work / ".github/ruleset-baseline.json").write_text(json.dumps(self.baseline))
                binary = work / "bin"
                binary.mkdir()
                gh = binary / "gh"
                gh.write_text(
                    "#!/usr/bin/env python3\nimport os, sys\n"
                    "if os.environ['EVIDENCE'] == 'null':\n"
                    "    print('API denied', file=sys.stderr)\n    sys.exit(1)\n"
                    "print(os.environ['EVIDENCE'])\n"
                )
                gh.chmod(0o700)
                env = {
                    **os.environ, "PATH": f"{binary}{os.pathsep}{os.environ['PATH']}",
                    "GH_HOST": "https://github.com", "GITHUB_REPOSITORY": "example/service",
                    "GITHUB_STEP_SUMMARY": str(work / "summary"), "EVIDENCE": json.dumps(payload),
                }
                result = subprocess.run(["bash", "-e", "-c", steps[0]], cwd=work, env=env,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, expected, result.stderr)
                report = json.loads((work / "ruleset-drift.json").read_text())
                summary = subprocess.run(["bash", "-e", "-c", steps[1]], cwd=work, env=env,
                                         capture_output=True, text=True)
                self.assertEqual(summary.returncode, 0, summary.stderr)
                self.assertIn("Ruleset drift", (work / "summary").read_text())
                if expected == 2:
                    self.assertEqual(report["result"], "unavailable")


if __name__ == "__main__":
    unittest.main()
