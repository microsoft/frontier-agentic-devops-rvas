# Modules

This directory contains the source content for each delivery session module. The build script (`docs/build.js`) reads from here — never from `docs/` directly.

## Layout

```
modules/
├── _TEMPLATE/           ← copy this when authoring a new challenge
│   └── challenge/
│       ├── meta.yml     ← all fields with comments
│       ├── README.md    ← customer delivery team guide template
│       └── COACH.md     ← coach guide template
│
├── ghec/                ← GitHub Enterprise Cloud (28 challenges)
│   └── challenges/
│       └── <slug>/      ← one directory per challenge
│           ├── meta.yml
│           ├── README.md
│           └── COACH.md
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

Use a short, descriptive, kebab-case slug as the directory name. Examples:
- `ch01-issues-labels-projects`
- `01-explore-attack-surface`
- `01-morning-briefing`
- `00-setup`

The directory name is used only for human navigation. The canonical identifier is `id` in `meta.yml`.

The curated GHAW catalog intentionally has gaps at `ghaw-04`, `ghaw-05`, `ghaw-13`, and `ghaw-15`; IDs remain stable when activities are removed.

## Adding a Activity

1. Copy `_TEMPLATE/challenge/` to `modules/<moduleId>/challenges/<your-slug>/`.
2. Fill in `meta.yml` (see [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the full field contract).
3. Write `README.md` (customer delivery team guide) and `COACH.md` (coach guide).
4. Run `node docs/build.js` to validate.

## Module Attributions

For information on how external dependencies (Juice Shop, source delivery session repos, sample apps) are managed and pinned, see [`docs/EXTERNAL-REPOS.md`](../docs/EXTERNAL-REPOS.md).
