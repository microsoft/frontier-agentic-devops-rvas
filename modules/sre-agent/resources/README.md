# Azure SRE Agent Resources

This folder contains reference material for the Azure SRE Agent track. The primary lab source is the official Microsoft repository:

```text
https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab
```

The course should use the Microsoft-provided Grubify starter lab whenever live Azure access is available. Local files in this folder are supporting curriculum assets and fallback templates, not the canonical application.

## Resource Index

| Resource | Purpose |
| --- | --- |
| [Azure SRE Agent Reference](SRE-Agent-Reference.md) | Source-backed baseline for what Azure SRE Agent, the starter lab, source-code context, plugins, and recipes provide. |
| [Reference Architecture](Reference-Architecture.md) | Azure-first learning architecture for signal, investigation, source context, remediation, and recovery. |
| [Incident Packet Template](Incident-Packet.md) | Fallback packet template when live Azure SRE Agent access is unavailable. |
| [Challenge 06 SRE Story Companion](Challenge-06-SRE-Story.md) | Game-day story notes for coaches and maintainers. |
| [Runbooks](runbooks/README.md) | Fallback incident packet and triage template aligned to Grubify/Azure SRE Agent. |
| [Research Links](Research-Links.md) | Curated Azure SRE Agent, Azure Monitor, GitHub connector, and operational excellence references. |

## Delivery Assets Coaches Should Prepare

- Live `microsoft/sre-agent/labs/starter-lab` deployment, or a shared pre-provisioned Grubify environment.
- Azure SRE Agent portal access or screenshots for Full setup cards.
- Healthy Grubify endpoint evidence.
- Controlled incident evidence from `scripts/break-app.sh`.
- Azure Monitor alert, Log Analytics query, Application Insights exception/trace, and SRE Agent transcript.
- Optional GitHub connector/source-code evidence.
- Simulated issue or pull request when live GitHub remediation is unavailable.

Do not commit secrets, customer data, private tenant details, or live incident data to this folder.

## Navigation

- [Student challenges](../challenges/00-setup/README.md)
- [Azure SRE Agent reference](SRE-Agent-Reference.md)
- [Fallback incident packet](Incident-Packet.md)
- [Runbooks](runbooks/README.md)
