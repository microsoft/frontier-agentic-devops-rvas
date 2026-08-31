# Azure SRE Agent Resources

The Azure SRE Agent track uses the official Microsoft repository for the live lab:

```text
https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab
```

Use the Microsoft Grubify starter lab when live Azure access is available. The local files support the course and provide fallback templates; they are not the live lab.

## Resource Index

| Resource | Purpose |
| --- | --- |
| [Azure SRE Agent Reference](SRE-Agent-Reference.md) | Source-backed baseline for what Azure SRE Agent, the starter lab, source-code context, plugins, and recipes provide. |
| [Reference Architecture](Reference-Architecture.md) | Azure-first learning architecture for signal, investigation, source context, remediation, and recovery. |
| [Incident Packet Template](Incident-Packet.md) | Fallback packet template when live Azure SRE Agent access is unavailable. |
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

**Do not commit secrets, customer data, private tenant details, or live incident data to this folder.**

## Navigation

- [Delivery team member activities](../challenges/00-setup/README.md)
- [Azure SRE Agent reference](SRE-Agent-Reference.md)
- [Fallback incident packet](Incident-Packet.md)
- [Runbooks](runbooks/README.md)
