# Azure SRE Agent resources

Use one approved customer service throughout the Azure SRE Agent track. For sample
practice, use the official Microsoft Grubify starter lab:

```text
https://github.com/microsoft/sre-agent/tree/main/labs/starter-lab
```

Skip sample deployment for an existing monitored service. Use the local templates
for practice when live work is unavailable. Practice does not prove customer adoption.

## Resource index

| Resource | Purpose |
| --- | --- |
| [Azure SRE Agent Reference](SRE-Agent-Reference.md) | Product and starter lab capabilities, with source links. |
| [Reference Architecture](Reference-Architecture.md) | How the lab connects Azure evidence to investigation, remediation, and recovery. |
| [Incident Packet Template](Incident-Packet.md) | Fallback packet template when live Azure SRE Agent access is unavailable. |
| [Runbooks](runbooks/README.md) | Fallback incident packet and triage template aligned to Grubify/Azure SRE Agent. |
| [Research Links](Research-Links.md) | Curated Azure SRE Agent, Azure Monitor, GitHub connector, and operational excellence references. |

## Prepare for delivery

- Use an approved monitored customer service, or prepare Grubify for practice.
- Azure SRE Agent portal access or screenshots for Full setup cards.
- Save a passing endpoint check for Grubify or the selected customer service.
- Collect incident evidence from that service. Use `scripts/break-app.sh` only for approved sample practice.
- Azure Monitor alert, Log Analytics query, Application Insights exception/trace, and SRE Agent transcript.
- For the customer handoff, link GitHub source evidence to a real incident issue.
- Use a simulated issue or pull request only for practice when live work is unavailable.

**Do not commit secrets, customer data, private tenant details, or live incident data to this folder.**

## Navigation

- [Connect a service to Azure SRE Agent](../challenges/01-deploy-grubify-sre-agent/README.md)
- [Azure SRE Agent reference](SRE-Agent-Reference.md)
- [Fallback incident packet](Incident-Packet.md)
- [Runbooks](runbooks/README.md)
