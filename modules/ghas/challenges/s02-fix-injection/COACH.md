# Fix Injection Vulnerabilities — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Facilitation objectives
- Reinforce why parameterized queries and ORM-safe patterns are the real fix for injection flaws.
- Help students distinguish between attacker-controlled input, query construction, and execution sinks.
- Keep attention on verifying branch-level CodeQL results after the code change, not just editing until the app runs.

## Common student blockers
- Students may try input sanitization or regex filtering first; redirect them toward prepared statements or framework-supported parameter binding.
- Some students fix one file but miss a parallel vulnerable path; ask them to search for the same unsafe query pattern elsewhere.
- Autofix suggestions may be helpful but incomplete; coach them to review the patch, not accept it blindly.

## Facilitation hints
- Ask students to point to the exact line where user input crosses into query construction.
- Encourage a small PR per fix if they are getting lost in multiple vulnerability paths.
- Have them explain how the chosen API keeps data separate from code at execution time.
- Remind them to inspect PR annotations after the scan completes, even if the local change looks correct.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] At least 2 injection vulnerabilities fixed in the code
- [ ] Fixes use parameterized queries or equivalent safe patterns — not input sanitization alone
- [ ] Pull requests to main opened with clear descriptions of the vulnerability and remediation
- [ ] Copilot Autofix tried on at least one alert (click "Generate fix" in the Security tab)
- [ ] PR CodeQL/code scanning checks reviewed, with no remaining annotations for the fixed patterns

## Source
Derived from [microsoft/frontier-ghas-hackathon](https://github.com/microsoft/frontier-ghas-hackathon), MIT license.
