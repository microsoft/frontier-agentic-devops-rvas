# Secure Secrets & Dependencies — Coach Guide

> Audience: facilitators and coaches. Pair with the student `README.md`.

## Facilitation objectives
- Reinforce that secrets belong in runtime configuration, not source control.
- Help students connect secret scanning and Dependabot as two complementary supply-chain/security hygiene workflows.
- Keep validation grounded in branch checks, push protection behavior, and application startup testing.

## Common student blockers
- Students may remove a hardcoded value without wiring a replacement environment variable; remind them to preserve app functionality.
- Some treat Dependabot alerts as just version bumps; ask them to read the advisory and explain the actual risk.
- Push protection behavior can surprise students; frame a block as useful feedback, not a failure.

## Facilitation hints
- Ask students to inventory where the secret is consumed before changing the code.
- Encourage documenting required environment variables in the PR or challenge notes.
- Have them review at least two high/critical advisories deeply enough to explain exploit impact.
- After the changes, make sure they can still start the app and exercise an auth-related path.

## Validation checklist
Verify each success criterion from the student guide:
- [ ] No hardcoded secrets, passwords, or credentials remain in source code files
- [ ] Secrets replaced with environment variable references (process.env.VARIABLE_NAME)
- [ ] At least 2 high or critical Dependabot alerts reviewed and understood
- [ ] Pull request checks and security annotations reviewed for branch changes
- [ ] Secret scanning alerts relevant to changes addressed or explained
- [ ] Application still starts and authenticates correctly after secrets migration

## Source
Derived from [microsoft/frontier-ghas-hackathon](https://github.com/microsoft/frontier-ghas-hackathon), MIT license.
