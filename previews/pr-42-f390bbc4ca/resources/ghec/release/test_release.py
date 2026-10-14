"""Local contract and shell tests; no GitHub calls or application builds."""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import textwrap
import unittest
import uuid


HERE = Path(__file__).resolve().parent
WORKFLOW = (HERE / "release.yml").read_text()


def block(text, header):
    """Extract an indented block from this template, without parsing general YAML."""
    lines = text.splitlines()
    start = lines.index(header) + 1
    indent = len(header) - len(header.lstrip())
    end = start
    while end < len(lines):
        line = lines[end]
        if line.strip() and len(line) - len(line.lstrip()) <= indent:
            break
        end += 1
    return "\n".join(lines[start:end]) + "\n"


def step(job, name):
    job_text = block(WORKFLOW, f"  {job}:")
    step_text = block(job_text, f"      - name: {name}")
    return {"run": textwrap.dedent(block(step_text, "        run: |"))}


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.work = HERE / (".test-work-" + uuid.uuid4().hex)
        self.work.mkdir()
        self.addCleanup(shutil.rmtree, self.work)
        self.env = {
            **os.environ,
            "CANDIDATE": "a" * 40,
            "TAG": "v0.1.0-ch49.1",
            "GITHUB_OUTPUT": str(self.work / "output"),
            "GITHUB_STEP_SUMMARY": str(self.work / "summary"),
        }

    def run_step(self, job, name, cwd=None, success=True):
        result = subprocess.run(
            ["bash", "-c", step(job, name)["run"]],
            cwd=cwd or self.work, env=self.env, capture_output=True, text=True,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def package(self):
        (self.work / "dist").mkdir()
        (self.work / "dist" / "app.txt").write_text("tested output\n")
        (self.work / "release-notes.md").write_text("Approved test notes.\n")
        self.run_step("build", "Package the tested output")
        self.env["MANIFEST_SHA256"] = (self.work / "output").read_text().strip().split("=", 1)[1]
        return self.work / "release-assets"

    def fake_gh(self):
        binary = self.work / "bin"
        binary.mkdir()
        gh = binary / "gh"
        gh.write_text("""#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ["GH_CALLS"], "a") as log:
    log.write(json.dumps(args) + "\\n")
if args[0] == "api":
    if "/git/ref/tags/" in args[1] and os.environ.get("ANNOTATED") == "1":
        print(json.dumps({"object": {"type": "tag", "sha": "b" * 40}}))
    else:
        print(json.dumps({"object": {"type": "commit", "sha": os.environ["TAG_SHA"]}}))
elif args[:2] == ["release", "view"]:
    if "--json" in args:
        print("https://github.com/example/test/releases/tag/" + os.environ["TAG"])
    else:
        sys.exit(0 if os.environ.get("EXISTING") == "1" else 1)
elif args[:2] not in (["release", "create"], ["release", "edit"]):
    sys.exit(2)
""")
        gh.chmod(0o700)
        self.env.update({
            "PATH": str(binary) + os.pathsep + os.environ["PATH"],
            "GH_CALLS": str(self.work / "calls"),
            "TAG_SHA": self.env["CANDIDATE"],
            "GH_REPO": "example/test",
            "GH_TOKEN": "local-test-only",
        })

    def calls(self):
        return [json.loads(line) for line in (self.work / "calls").read_text().splitlines()]

    def test_permissions_gate_and_same_run_artifact(self):
        self.assertEqual(re.findall(r"^  (\w+):", block(WORKFLOW, "on:"), re.M), ["workflow_dispatch"])
        self.assertEqual(block(WORKFLOW, "permissions:").strip(), "contents: read")
        build = block(WORKFLOW, "  build:")
        publish = block(WORKFLOW, "  publish:")
        self.assertIn("    if: github.ref == format('refs/heads/{0}', github.event.repository.default_branch)", build)
        self.assertNotIn("    permissions:", build)
        self.assertNotIn("    environment:", build)
        self.assertNotIn("secrets.", WORKFLOW)
        self.assertEqual(block(publish, "    permissions:").strip(), "contents: write")
        self.assertIn("    needs: build\n", publish)
        self.assertIn("    environment: release\n", publish)
        self.assertIn("          persist-credentials: false\n", build)
        self.assertIn("          artifact-ids: ${{ needs.build.outputs.artifact_id }}\n", publish)
        self.assertNotIn("checkout", publish)
        self.assertNotIn("npm ", publish)
        commands = step("build", "Build and test")["run"]
        self.assertLess(commands.index("npm run build"), commands.index("npm run test:artifact"))

    def test_all_shell_blocks_parse(self):
        checked = 0
        for job in ("build", "publish"):
            for name in re.findall(r"^      - name: (.+)$", block(WORKFLOW, f"  {job}:"), re.M):
                result = subprocess.run(["bash", "-n"], input=step(job, name)["run"], text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                checked += 1
        self.assertEqual(checked, WORKFLOW.count("        run: |"))

    def test_package_verifies_and_detects_changed_asset(self):
        assets = self.package()
        digest = hashlib.sha256((assets / "SHA256SUMS").read_bytes()).hexdigest()
        self.assertEqual(self.env["MANIFEST_SHA256"], digest)
        self.run_step("publish", "Verify the reviewed files", assets)
        (assets / "release.tgz").write_bytes(b"changed after approval")
        self.run_step("publish", "Verify the reviewed files", assets, success=False)

    def test_changed_manifest_is_rejected(self):
        assets = self.package()
        (assets / "SHA256SUMS").write_text("0" * 64 + "  release.tgz\n")
        self.run_step("publish", "Verify the reviewed files", assets, success=False)

    def test_candidate_sha_mismatch_is_rejected(self):
        assets = self.package()
        self.env["CANDIDATE"] = "c" * 40
        self.run_step("publish", "Verify the reviewed files", assets, success=False)

    def test_annotated_tag_publishes_exact_files_as_prerelease(self):
        assets = self.package()
        self.fake_gh()
        self.env["ANNOTATED"] = "1"
        self.run_step("publish", "Verify tag and publish without rebuilding", assets)
        calls = self.calls()
        create = next(call for call in calls if call[:2] == ["release", "create"])
        self.assertEqual(create[3:7], ["release.tgz", "SHA256SUMS", "source-sha.txt", "release-notes.md"])
        self.assertIn("--verify-tag", create)
        self.assertIn("--draft", create)
        edit = next(call for call in calls if call[:2] == ["release", "edit"])
        self.assertIn("--prerelease", edit)
        self.assertIn("--latest=false", edit)

    def test_moved_tag_never_creates_release(self):
        self.fake_gh()
        self.env["TAG_SHA"] = "c" * 40
        self.run_step("publish", "Verify tag and publish without rebuilding", success=False)
        self.assertFalse(any(call[:2] == ["release", "create"] for call in self.calls()))

    def test_existing_draft_or_release_is_never_overwritten(self):
        self.fake_gh()
        self.env["EXISTING"] = "1"
        self.run_step("publish", "Verify tag and publish without rebuilding", success=False)
        self.assertFalse(any(call[:2] in (["release", "create"], ["release", "edit"]) for call in self.calls()))


if __name__ == "__main__":
    unittest.main()
