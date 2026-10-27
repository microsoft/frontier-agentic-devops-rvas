import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


RESOURCES = Path(__file__).resolve().parent.parent


def script(relative_path, step):
    lines = (RESOURCES / relative_path).read_text().splitlines()
    start = next(i for i, line in enumerate(lines) if line.strip() == f"- name: {step}")
    for i in range(start + 1, len(lines)):
        line = lines[i]
        if line.lstrip().startswith("run: "):
            value = line.strip()[5:]
            if value != "|":
                return value
            indent = len(line) - len(line.lstrip()) + 2
            result = []
            for body in lines[i + 1:]:
                if body.strip() and len(body) - len(body.lstrip()) < indent:
                    break
                result.append(body[indent:])
            return "\n".join(result)
    raise AssertionError(f"Missing run step: {step}")


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.env = dict(os.environ, GITHUB_OUTPUT=str(self.directory / "output"),
                        GITHUB_STEP_SUMMARY=str(self.directory / "summary"),
                        RUNNER_TEMP=str(self.directory),
                        DOCKER_CONFIG=str(self.directory / "docker-config"),
                        npm_config_cache=str(self.directory / "npm-cache"),
                        npm_config_audit="false")

    def run_step(self, path, step, **env):
        return subprocess.run(
            ["bash", "-e", "-o", "pipefail", "-c", script(path, step)],
            cwd=self.directory, env={**self.env, **env},
            capture_output=True, text=True,
        )

    def git(self, *args):
        return subprocess.check_output(
            ["git", "-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null",
             "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", *args],
            cwd=self.directory, text=True,
        ).strip()

    def prepare_repository(self):
        self.git("init", "-q")
        for name in ("packages/web/app.js", "packages/api/app.js", "shared/common.js"):
            target = self.directory / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("initial\n")
        self.git("add", ".")
        self.git("commit", "-qm", "Initial")
        return self.git("rev-parse", "HEAD")

    def selection(self, base):
        self.git("add", ".")
        self.git("commit", "-qm", "Change", "--allow-empty")
        result = self.run_step("ci/monorepo.yml", "Select affected packages",
                               BASE_SHA=base, HEAD_SHA=self.git("rev-parse", "HEAD"))
        self.assertEqual(result.returncode, 0, result.stderr)
        return dict(line.split("=") for line in (self.directory / "output").read_text().splitlines())

    def test_web_only(self):
        base = self.prepare_repository()
        (self.directory / "packages/web/app.js").write_text("changed\n")
        self.assertEqual(self.selection(base), {"web": "true", "api": "false"})

    def test_api_only(self):
        base = self.prepare_repository()
        (self.directory / "packages/api/app.js").write_text("changed\n")
        self.assertEqual(self.selection(base), {"web": "false", "api": "true"})

    def test_shared_change(self):
        base = self.prepare_repository()
        (self.directory / "shared/common.js").write_text("changed\n")
        self.assertEqual(self.selection(base), {"web": "true", "api": "true"})

    def test_root_change(self):
        base = self.prepare_repository()
        (self.directory / "package-lock.json").write_text("{}")
        self.assertEqual(self.selection(base), {"web": "true", "api": "true"})

    def test_deleted_package_file(self):
        base = self.prepare_repository()
        (self.directory / "packages/web/app.js").unlink()
        self.assertEqual(self.selection(base), {"web": "true", "api": "false"})

    def test_cross_package_rename(self):
        base = self.prepare_repository()
        (self.directory / "packages/web/app.js").rename(self.directory / "packages/api/moved.js")
        self.assertEqual(self.selection(base), {"web": "true", "api": "true"})

    def test_empty_diff_checks_both(self):
        base = self.prepare_repository()
        self.assertEqual(self.selection(base), {"web": "true", "api": "true"})

    def test_selection_rejects_missing_and_unavailable_evidence(self):
        for base in ("", "not-a-sha", "a" * 40):
            with self.subTest(base=base):
                result = self.run_step("ci/monorepo.yml", "Select affected packages",
                                       BASE_SHA=base, HEAD_SHA="b" * 40)
                self.assertNotEqual(result.returncode, 0)

    def test_aggregate_results(self):
        for selection, web, api, selected_web, selected_api, expected in (
            ("success", "success", "skipped", "true", "false", 0),
            ("success", "success", "success", "true", "true", 0),
            ("success", "failure", "success", "true", "true", 1),
            ("success", "skipped", "success", "true", "true", 1),
            ("success", "cancelled", "success", "true", "true", 1),
            ("failure", "skipped", "skipped", "true", "true", 1),
            ("skipped", "skipped", "skipped", "false", "false", 1),
            ("success", "success", "success", "", "true", 1),
        ):
            with self.subTest(selection=selection, web=web, api=api, selected_web=selected_web):
                needs = {"select": {"result": selection, "outputs": {
                    "web": selected_web, "api": selected_api}},
                    "web": {"result": web}, "api": {"result": api}}
                result = self.run_step("ci/monorepo.yml", "Require every selected test",
                                       NEEDS_JSON=json.dumps(needs))
                self.assertEqual(result.returncode, expected, result.stderr)

    def prepare_application(self):
        package = {"name": "fixture", "version": "1.0.0", "private": True,
                   "scripts": {"test": "node --test app.test.cjs", "build": "node build.cjs"}}
        (self.directory / "package.json").write_text(json.dumps(package))
        lock = {"name": "fixture", "version": "1.0.0", "lockfileVersion": 3,
                "requires": True, "packages": {"": {"name": "fixture", "version": "1.0.0"}}}
        (self.directory / "package-lock.json").write_text(json.dumps(lock))
        (self.directory / "app.cjs").write_text("module.exports = 42\n")
        (self.directory / "app.test.cjs").write_text(
            "require('node:assert/strict').equal(require('./app.cjs'), 42)\n")
        (self.directory / "build.cjs").write_text(
            "const fs = require('node:fs'); fs.mkdirSync('dist'); "
            "fs.writeFileSync('dist/app.txt', String(require('./app.cjs')))\n")

    def test_baseline_runs_real_tests_and_build(self):
        self.prepare_application()
        result = self.run_step("ci/baseline.yml", "Build and test the consumer")
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertEqual((self.directory / "dist/app.txt").read_text(), "42")

    def test_baseline_does_not_build_after_test_failure(self):
        self.prepare_application()
        (self.directory / "app.cjs").write_text("module.exports = 41\n")
        result = self.run_step("ci/baseline.yml", "Build and test the consumer")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.directory / "dist").exists())

    def prepare_docker(self):
        binary = self.directory / "bin"
        binary.mkdir()
        docker = binary / "docker"
        docker.write_text("""#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
config = pathlib.Path(os.environ["DOCKER_CONFIG"])
if args[0] == "login":
    assert "--password-stdin" in args
    assert sys.stdin.read() == "test-credential"
    config.mkdir(exist_ok=True)
    (config / "authenticated").write_text("yes")
elif args[0] == "pull":
    if os.environ.get("MOCK_DENIAL") == "network":
        sys.exit("network unavailable")
    if not (config / "authenticated").exists() and os.environ.get("MOCK_DENIAL") != "public":
        sys.exit("unauthorized: authentication required")
elif args[:2] == ["image", "inspect"]:
    if os.environ.get("MOCK_INSPECT_FAILURE"):
        sys.exit("inspect unavailable")
    ref = os.environ["MOCK_PUBLISHED"]
    print(json.dumps([ref]) if "json .RepoDigests" in args[-1] else ref)
elif args[0] not in ("build", "push"):
    sys.exit("unexpected docker operation")
""")
        docker.chmod(0o700)
        self.env["PATH"] = str(binary) + os.pathsep + self.env["PATH"]
        self.env["MOCK_PUBLISHED"] = "ghcr.io/example/service@sha256:" + "a" * 64

    def test_publisher_normalizes_name_and_uniquely_tags_attempt(self):
        result = self.run_step("packages/publish.yml", "Select the repository's image",
                               GITHUB_REPOSITORY="Example/Service",
                               GITHUB_RUN_ID="123", GITHUB_RUN_ATTEMPT="2")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.directory / "output").read_text(),
                         "name=ghcr.io/example/service\ntag=ghcr.io/example/service:run-123-2\n")

    def publish(self, **env):
        return self.run_step("packages/publish.yml", "Build, push, and report digest",
                             IMAGE_NAME="ghcr.io/example/service",
                             IMAGE_TAG="ghcr.io/example/service:run-123-2",
                             GITHUB_SERVER_URL="https://github.com",
                             GITHUB_REPOSITORY="Example/Service", **env)

    def test_publisher_reports_verified_digest(self):
        self.prepare_docker()
        result = self.publish()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(self.env["MOCK_PUBLISHED"], (self.directory / "summary").read_text())

    def test_publisher_rejects_missing_or_wrong_digest(self):
        self.prepare_docker()
        for ref in ("", "sha256:" + "a" * 64,
                    "ghcr.io/other/service@sha256:" + "a" * 64,
                    "ghcr.io/example/service@sha256:short"):
            with self.subTest(ref=ref):
                self.assertNotEqual(self.publish(MOCK_PUBLISHED=ref).returncode, 0)
        self.assertNotEqual(self.publish(MOCK_INSPECT_FAILURE="1").returncode, 0)
        self.assertFalse((self.directory / "summary").exists())

    def consume_check(self, **env):
        return self.run_step("packages/consume.yml", "Check reference and reject unauthenticated pull",
                             IMAGE_DIGEST=self.env["MOCK_PUBLISHED"], **env)

    def test_consumer_proves_denial_then_pulls_same_digest(self):
        self.prepare_docker()
        self.assertEqual(self.consume_check().returncode, 0)
        login = self.run_step("packages/consume.yml", "Authenticate read-only consumer",
                              GHCR_TOKEN="test-credential", GITHUB_ACTOR="fixture")
        self.assertEqual(login.returncode, 0, login.stderr)
        result = self.run_step("packages/consume.yml", "Pull and verify the approved digest",
                               IMAGE_DIGEST=self.env["MOCK_PUBLISHED"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(self.env["MOCK_PUBLISHED"], (self.directory / "summary").read_text())

    def test_consumer_does_not_treat_network_failure_as_denial(self):
        self.prepare_docker()
        self.assertNotEqual(self.consume_check(MOCK_DENIAL="network").returncode, 0)

    def test_consumer_rejects_anonymously_accessible_package(self):
        self.prepare_docker()
        self.assertNotEqual(self.consume_check(MOCK_DENIAL="public").returncode, 0)

    def test_consumer_rejects_invalid_reference_and_digest_mismatch(self):
        self.prepare_docker()
        for ref in ("ghcr.io/example/service:latest", "$(echo injected)", ""):
            result = self.run_step("packages/consume.yml", "Check reference and reject unauthenticated pull",
                                   IMAGE_DIGEST=ref)
            self.assertNotEqual(result.returncode, 0)
        (self.directory / "docker-config").mkdir()
        (self.directory / "docker-config/authenticated").write_text("yes")
        result = self.run_step("packages/consume.yml", "Pull and verify the approved digest",
                               IMAGE_DIGEST="ghcr.io/example/service@sha256:" + "b" * 64)
        self.assertNotEqual(result.returncode, 0)

    def test_workflow_wiring(self):
        baseline = (RESOURCES / "ci/baseline.yml").read_text()
        self.assertIn("  workflow_call:", baseline)
        for filename in ("baseline.yml", "monorepo.yml"):
            text = (RESOURCES / "ci" / filename).read_text()
            self.assertIn("  pull_request:", text)
            self.assertIn("  merge_group:", text)
            self.assertNotIn("paths:", text)
            self.assertNotIn("secrets: inherit", text)
        monorepo = (RESOURCES / "ci/monorepo.yml").read_text()
        self.assertIn("needs: [select, web, api]\n    if: always()", monorepo)
        for filename in ("publish.yml", "consume.yml"):
            text = (RESOURCES / "packages" / filename).read_text()
            self.assertIn("github.event.repository.default_branch", text)
            steps = (["Select the repository's image", "Build, push, and report digest"]
                     if filename == "publish.yml" else
                     ["Check reference and reject unauthenticated pull", "Pull and verify the approved digest"])
            rendered = "\n".join(script(f"packages/{filename}", step) for step in steps)
            self.assertNotIn("${{ inputs.", rendered)
        self.assertNotIn("packages: write", (RESOURCES / "packages/consume.yml").read_text())


if __name__ == "__main__":
    unittest.main()
