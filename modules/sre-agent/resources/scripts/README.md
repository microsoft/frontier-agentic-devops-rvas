# Scripts

The Azure SRE Agent track uses the official Microsoft starter lab. The setup command fetches a fixed revision:

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

## Local Fallback Utilities

Use these only when Azure access is unavailable:

| Script | Purpose |
| --- | --- |
| `simulate-checkout-incident.sh` | Runs the local `sample-app` in a failure mode and writes evidence to `runbooks/generated/`. |
| `capture-deployment-evidence.sh` | Writes a deployment evidence note to `runbooks/generated/`. |

## Automation Helper

`ensure-starter-lab.sh` is a thin wrapper around `scripts/provision-app.sh`. It is not invoked by `npm run setup:sre-agent-lab`; automation that needs the lab path calls it directly. It prepares the pinned Grubify starter lab and prints its absolute path.
