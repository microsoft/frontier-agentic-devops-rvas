#!/usr/bin/env python3
"""Compare one repository ruleset with its reviewed baseline, without writing."""

import argparse
import json
import os
import re
import subprocess


POLICY_FIELDS = ("enforcement", "target", "conditions", "rules")


def canonical(value):
    if isinstance(value, dict):
        return {key: canonical(item) for key, item in sorted(value.items())}
    if isinstance(value, list):
        # Ruleset arrays describe sets of rules, patterns, and allowed values.
        items = [canonical(item) for item in value]
        return sorted(items, key=lambda item: json.dumps(item, sort_keys=True))
    return value


def policy_from(payload):
    if not isinstance(payload, dict):
        raise ValueError("Ruleset API must return an object")
    if payload.get("enforcement") not in ("active", "evaluate", "disabled"):
        raise ValueError("Ruleset enforcement is unavailable")
    if payload.get("target") not in ("branch", "tag", "push", "repository"):
        raise ValueError("Ruleset target is unavailable")
    if not isinstance(payload.get("conditions"), dict):
        raise ValueError("Ruleset conditions are unavailable")
    if payload["target"] == "branch":
        refs = payload["conditions"].get("ref_name")
        if not isinstance(refs, dict) or any(
            not isinstance(refs.get(key), list)
            or any(not isinstance(item, str) for item in refs[key])
            for key in ("include", "exclude")
        ):
            raise ValueError("Branch ruleset ref conditions are unavailable")
    rules = payload.get("rules")
    if not isinstance(rules, list) or any(
        not isinstance(rule, dict) or not isinstance(rule.get("type"), str)
        or ("parameters" in rule and not isinstance(rule["parameters"], dict))
        for rule in rules
    ):
        raise ValueError("Ruleset rules are unavailable or malformed")
    return canonical({field: payload[field] for field in POLICY_FIELDS})


def validate_baseline(baseline, repository, hostname):
    if not isinstance(baseline, dict) or type(baseline.get("schema_version")) is not int \
            or baseline["schema_version"] != 1:
        raise ValueError("Expected baseline schema_version 1")
    if set(baseline) != {"schema_version", "repository", "hostname", "ruleset_id", "policy"}:
        raise ValueError("Baseline contains missing or unsupported fields")
    if not isinstance(baseline.get("repository"), str) \
            or baseline["repository"].lower() != repository.lower():
        raise ValueError("Baseline repository does not match the selected repository")
    if baseline.get("hostname") != hostname:
        raise ValueError("Baseline hostname does not match GH_HOST")
    ruleset_id = baseline.get("ruleset_id")
    if type(ruleset_id) is not int or ruleset_id <= 0:
        raise ValueError("Baseline ruleset_id must be a positive integer")
    if not isinstance(baseline.get("policy"), dict) or set(baseline["policy"]) != set(POLICY_FIELDS):
        raise ValueError("Baseline policy must contain only the supported policy fields")
    policy = policy_from(baseline["policy"])
    if policy["target"] != "branch" or policy["enforcement"] != "active" or not policy["rules"]:
        raise ValueError("Baseline must describe an active, nonempty branch ruleset")
    if not policy["conditions"]["ref_name"]["include"]:
        raise ValueError("Baseline must include at least one branch condition")
    return policy


def read_ruleset(repository, ruleset_id, hostname):
    result = subprocess.run(
        ["gh", "api", f"repos/{repository}/rulesets/{ruleset_id}?includes_parents=true",
         "--hostname", hostname, "-H", "X-GitHub-Api-Version: 2022-11-28"],
        capture_output=True, text=True, timeout=30, check=True,
    )
    payload = json.loads(result.stdout)
    if not isinstance(payload, dict) or type(payload.get("id")) is not int \
            or payload["id"] != ruleset_id:
        raise ValueError("Ruleset API returned an unexpected ruleset ID")
    return policy_from(payload)


def assess(actual, expected):
    checks = []
    for field in POLICY_FIELDS:
        matches = json.dumps(canonical(actual[field]), sort_keys=True) == \
            json.dumps(canonical(expected[field]), sort_keys=True)
        checks.append({
            "field": field, "expected": expected[field], "actual": actual[field],
            "result": "pass" if matches else "fail",
        })
    return checks, 0 if all(check["result"] == "pass" for check in checks) else 1


def inspect(repository, baseline, hostname):
    try:
        expected = validate_baseline(baseline, repository, hostname)
    except ValueError as error:
        return {"repository": repository, "result": "unavailable", "reason": str(error)}, 2
    try:
        actual = read_ruleset(repository, baseline["ruleset_id"], hostname)
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        reason = str(error) if isinstance(error, ValueError) else \
            "Ruleset API could not be read; check the host, ruleset ID, access, and connectivity."
        return {"repository": repository, "result": "unavailable", "reason": reason}, 2
    checks, code = assess(actual, expected)
    return {"repository": repository, "ruleset_id": baseline["ruleset_id"], "checks": checks}, code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repository", help="OWNER/REPO on GH_HOST (default: github.com)")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--capture", type=int, metavar="RULESET_ID")
    mode.add_argument("--baseline", metavar="JSON_FILE")
    args = parser.parse_args()
    if args.capture is not None and args.capture <= 0:
        parser.error("ruleset ID must be a positive integer")
    hostname = os.environ.get("GH_HOST", "github.com").lower()
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", args.repository):
        parser.error("repository must be OWNER/REPO")
    if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?", hostname):
        parser.error("GH_HOST must be a hostname, without a scheme or path")
    try:
        if args.capture is not None:
            report = {
                "schema_version": 1, "repository": args.repository, "hostname": hostname,
                "ruleset_id": args.capture,
                "policy": read_ruleset(args.repository, args.capture, hostname),
            }
            validate_baseline(report, args.repository, hostname)
            code = 0
        else:
            with open(args.baseline, encoding="utf-8") as source:
                baseline = json.load(source)
            report, code = inspect(args.repository, baseline, hostname)
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        reason = str(error) if isinstance(error, ValueError) else \
            "Baseline or ruleset could not be read; check paths, access, and connectivity."
        report, code = {"repository": args.repository, "result": "unavailable", "reason": reason}, 2
    print(json.dumps(report, sort_keys=True, indent=2))
    return code


if __name__ == "__main__":
    raise SystemExit(main())
