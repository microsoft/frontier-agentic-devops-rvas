# Modules

This directory holds the source files for each delivery session module. The build script (`docs/build.js`) reads from here, not `docs/`.

## Layout

```
modules/
├── _TEMPLATE/           ← copy this to create an activity
│   └── challenge/
│       ├── meta.yml     ← field template with comments
│       └── README.md    ← delivery team guide template
│
├── ghec/                ← GitHub Enterprise Cloud (41 active activities)
│   ├── resources/       ← provisioning scripts and governance templates
│   └── challenges/
│       └── <slug>/      ← one directory per activity
│           ├── meta.yml
│           └── README.md
│
├── ghas/                ← GitHub Advanced Security (9 active activities)
│   ├── setup.md         ← how to run Juice Shop
│   └── challenges/
│
├── ghaw/                ← GitHub Agentic Workflows (7 active activities)
│   ├── setup.md         ← dev container and `gh aw` setup
│   └── challenges/
│
└── sre-agent/           ← Azure SRE Agent (4 activities)
    ├── resources/       ← vendored assets and fallback runbooks
    └── challenges/
```

## Activity directory naming

Use a short, descriptive kebab-case slug for each activity directory. Examples:

- `01-issues-labels-projects`
- `02-fix-injection`
- `17-issue-triage-agent`
- `00-setup`

The directory name is for browsing. The `id` field in `meta.yml` is the canonical identifier.

Activity IDs are stable identifiers and need not be consecutive.

## Completion evidence

**Leave the team with something it can use.** Each session should configure a
needed capability or complete useful work through GitHub. Teach the mechanism
while the participant uses it, and verify the result before expanding it.

Use one customer repository or service throughout the selected activities. Create a practice
environment only when you need one. Check existing settings before changing them or
adding tools.

Record the result in the team's existing issue or change record. Link to the relevant
pull request or alert instead of copying its state into another register.

| Result | What counts |
|---|---|
| **Implemented** | The team uses the feature in its approved environment. Tests confirm that permissions or review requirements work as intended. |
| **Sample practice** | The exercise works in a sample or uses a prepared packet. It does not prove customer rollout. |
| **Assessment accepted** | The accountable owner accepts a decision or risk. This supports implementation, but does not complete a session that promises a working capability. |
| **Blocked / not tested** | Record the missing access or feature and who will resolve it. Drafts and simulations do not count as implemented controls. |

For code changes, use one real work item and a reviewed pull request with required
checks. Verify release or recovery when the selected activities include it.

Run agent pilots manually first. Review the output and test a case that should produce
no action before enabling a schedule. Use ordinary Actions for tasks with fixed rules.

## Add an activity

1. Copy `_TEMPLATE/challenge/` to `modules/<moduleId>/challenges/<your-slug>/`.
2. Complete `meta.yml`. See [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the field contract.
3. Write `README.md` for the delivery team.
4. Run `node docs/build.js` to validate.

## Module attributions

See [`docs/EXTERNAL-REPOS.md`](../docs/EXTERNAL-REPOS.md) for how the project manages and pins Juice Shop, source delivery session repositories, sample apps, and other external dependencies.
