# Scripts

The rebuilt Azure SRE Agent track uses the official Microsoft starter lab as the live source. The setup command fetches the lab at a fixed revision only when it is needed:

```text
https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab
```

## Doctor

Run the local preflight before Activity 00 or Activity 01:

```bash
npm run setup:sre-agent
```

The doctor checks for Git, Azure CLI, Azure Developer CLI, Python, Azure login state, and `Microsoft.App` provider registration. It does not deploy resources.

## Official Live Lab Commands

Use these commands to fetch the official lab and enter it:

```bash
npm run setup:sre-agent-lab
cd external/sre-agent/labs/starter-lab
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
