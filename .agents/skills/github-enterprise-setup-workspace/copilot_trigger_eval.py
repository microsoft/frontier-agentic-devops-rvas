#!/usr/bin/env python3

import argparse
import concurrent.futures
import json
import subprocess
import time
from pathlib import Path


def run_query(query, model, skill_name, timeout):
    started = time.time()
    command = [
        "copilot",
        "-p",
        query,
        "-s",
        "--model",
        model,
        "--output-format",
        "json",
        "--available-tools",
        "skill",
        "--disable-builtin-mcps",
        "--log-level",
        "none",
    ]
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {
            "triggered": False,
            "timed_out": True,
            "exit_code": None,
            "duration_seconds": round(time.time() - started, 3),
        }

    triggered = False
    for line in result.stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("type") != "assistant.message":
            continue
        for request in event.get("data", {}).get("toolRequests", []):
            if request.get("name") != "skill":
                continue
            if request.get("arguments", {}).get("skill") == skill_name:
                triggered = True
                break
        if triggered:
            break

    return {
        "triggered": triggered,
        "timed_out": False,
        "exit_code": result.returncode,
        "duration_seconds": round(time.time() - started, 3),
        "stderr": result.stderr[-1000:] if result.returncode else "",
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--eval-set", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--skill-name", required=True)
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--workers", type=int, default=6)
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    jobs = []
    for index, item in enumerate(eval_set):
        for run_number in range(1, args.runs + 1):
            jobs.append((index, run_number, item))

    raw_results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        future_map = {
            pool.submit(
                run_query,
                item["query"],
                args.model,
                args.skill_name,
                args.timeout,
            ): (index, run_number, item)
            for index, run_number, item in jobs
        }
        for future in concurrent.futures.as_completed(future_map):
            index, run_number, item = future_map[future]
            result = future.result()
            raw_results.append(
                {
                    "index": index,
                    "run": run_number,
                    "query": item["query"],
                    "should_trigger": item["should_trigger"],
                    **result,
                }
            )

    results = []
    for index, item in enumerate(eval_set):
        runs = sorted(
            [result for result in raw_results if result["index"] == index],
            key=lambda result: result["run"],
        )
        trigger_count = sum(1 for result in runs if result["triggered"])
        expected = item["should_trigger"]
        passed = trigger_count >= 2 if expected else trigger_count <= 1
        results.append(
            {
                "query": item["query"],
                "should_trigger": expected,
                "triggers": trigger_count,
                "runs": len(runs),
                "pass": passed,
                "details": runs,
            }
        )

    passed = sum(1 for result in results if result["pass"])
    output = {
        "skill_name": args.skill_name,
        "model": args.model,
        "runs_per_query": args.runs,
        "summary": {
            "passed": passed,
            "failed": len(results) - passed,
            "total": len(results),
        },
        "results": results,
    }
    Path(args.output).write_text(json.dumps(output, indent=2))
    print(json.dumps(output["summary"]))
    for result in results:
        status = "PASS" if result["pass"] else "FAIL"
        print(
            f"{status} {result['triggers']}/{result['runs']} "
            f"expected={result['should_trigger']}: {result['query'][:90]}"
        )


if __name__ == "__main__":
    main()
