# Modules

This directory holds the source files for each delivery session module. The build script (`docs/build.js`) reads from here, not `docs/`.

## Layout

```
modules/
├── _TEMPLATE/           ← copy this to create a challenge
│   └── challenge/
│       ├── meta.yml     ← field template with comments
│       └── README.md    ← delivery team guide template
│
├── ghec/                ← GitHub Enterprise Cloud (53 activities)
│   └── challenges/
│       └── <slug>/      ← one directory per challenge
│           ├── meta.yml
│           └── README.md
│
├── ghas/                ← GitHub Advanced Security (7 challenges: S00–S06)
│   ├── setup.md         ← how to run Juice Shop
│   └── challenges/
│
├── ghaw/                ← GitHub Agentic Workflows (19 activities)
│   └── challenges/
│
└── sre-agent/           ← SRE Agent (5 challenges)
    ├── resources/       ← vendored assets (212 KB)
    └── challenges/
```

## Activity Directory Naming

Use a short, descriptive kebab-case slug for each activity directory. Examples:

- `01-issues-labels-projects`
- `01-explore-attack-surface`
- `01-morning-briefing`
- `00-setup`

The directory name is for browsing. The `id` field in `meta.yml` is the canonical identifier.

The curated GHAW catalog has intentional gaps at `ghaw-04`, `ghaw-05`, `ghaw-13`, and `ghaw-15`. Removing an activity does not renumber the remaining IDs.

## Add an Activity

1. Copy `_TEMPLATE/challenge/` to `modules/<moduleId>/challenges/<your-slug>/`.
2. Complete `meta.yml`. See [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the field contract.
3. Write `README.md` for the delivery team.
4. Run `node docs/build.js` to validate.

## Module Attributions

See [`docs/EXTERNAL-REPOS.md`](../docs/EXTERNAL-REPOS.md) for how the project manages and pins Juice Shop, source delivery session repositories, sample apps, and other external dependencies.
