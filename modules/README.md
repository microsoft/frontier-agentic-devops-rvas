# Modules

This directory contains the **source content** for each hackathon module. The build script (`docs/build.js`) reads from here — never from `docs/` directly.

## Layout

```
modules/
├── _TEMPLATE/           ← copy this when authoring a new challenge
│   └── challenge/
│       ├── meta.yml     ← all fields with comments
│       ├── README.md    ← student guide template
│       └── COACH.md     ← coach guide template
│
├── ghec/                ← GitHub Enterprise Cloud (20 challenges)
│   ├── ATTRIBUTION.md
│   └── challenges/
│       └── <slug>/      ← one directory per challenge
│           ├── meta.yml
│           ├── README.md
│           └── COACH.md
│
├── ghas/                ← GitHub Advanced Security (6 challenges: S00–S05)
│   ├── ATTRIBUTION.md
│   ├── setup.md         ← how to run Juice Shop
│   └── challenges/
│
├── ghaw/                ← GitHub Agentic Workflows (24 challenges)
│   ├── ATTRIBUTION.md
│   └── challenges/
│
└── sre-agent/           ← SRE Agent (6 challenges)
    ├── ATTRIBUTION.md
    ├── resources/       ← vendored assets (212 KB)
    └── challenges/
```

## Challenge Directory Naming

Use a short, descriptive, kebab-case slug as the directory name. Examples:
- `ch01-issues-labels-projects`
- `s00-explore-attack-surface`
- `1-01-morning-briefing`
- `00-setup`

The directory name is used only for human navigation. The canonical identifier is `id` in `meta.yml`.

## Adding a Challenge

1. Copy `_TEMPLATE/challenge/` to `modules/<moduleId>/challenges/<your-slug>/`.
2. Fill in `meta.yml` (see [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the full field contract).
3. Write `README.md` (student guide) and `COACH.md` (coach guide).
4. Run `node docs/build.js` to validate.

## Module Attributions

Each module directory contains an `ATTRIBUTION.md` crediting its source repository. All source content is MIT licensed © Microsoft Corporation.
