# Scripts

The rebuilt Azure SRE Agent track uses the official Microsoft starter lab as the live source:

```text
https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab
```

## Doctor

Run the local preflight before Challenge 00 or Challenge 01:

```bash
npm run setup:sre-agent
```

The doctor checks for Git, Azure CLI, Azure Developer CLI, Python, Azure login state, and `Microsoft.App` provider registration. It does not deploy resources.

## Official Live Lab Commands

Use these commands from a separate clone of the Microsoft lab:

```bash
LAB_DIR="$(bash modules/sre-agent/resources/scripts/ensure-starter-lab.sh)"
cd "$LAB_DIR"
bash scripts/setup.sh
```

For the controlled incident:

```bash
bash scripts/break-app.sh
```

For optional GitHub/source-code connection:

```bash
bash scripts/setup-github.sh
```

## Legacy Local Utilities

Some local scripts remain in this repository as fallback utilities for coaches, but they are no longer the primary SRE Agent track path. Prefer the official Microsoft lab for live delivery and use fallback packets when Azure access is unavailable.
