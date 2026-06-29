# Resources

This folder contains reusable reference material for coaches and participants. Some resources are templates for live delivery; others describe fallback packets coaches should prepare when preview access, tenant policy, or time prevents hands-on execution.

## Resource Index

| Resource | Purpose |
| --- | --- |
| [Reference Architecture](Reference-Architecture.md) | Describes the end-to-end learning architecture and evidence flow. |
| [Incident Packet Template](Incident-Packet.md) | Provides a template for the Challenge 06 incident simulation. |
| [Agent-Ready Issue Template](Agent-Ready-Issue-Template.md) | Helps teams write issues suitable for cloud coding agent review. |
| [Agentic SDLC Starter Kit](Agentic-SDLC-Starter-Kit.md) | Provides starter context artifacts, PROSE checklist, load lifecycle debugging, ADAPT loop, and anti-pattern recovery. |
| [Agentic SDLC Practices](Agentic-SDLC-Practices.md) | Integrates The Agentic SDLC Handbook into the workshop operating model. |
| [GitHub Agentic Workflows Starter](GitHub-Agentic-Workflows-Starter.md) | Provides safe markdown workflow templates for issue triage, CI Doctor, and plan command challenges. |
| [Build Agentic Workflows](agentic-workflows/README.md) | Provides Peli's Factory / GitHub Agentic Workflows-inspired templates for issue triage, CI diagnosis, and `/plan` coordination. |
| [Pages Publishing](Pages-Publishing.md) | Provides GitHub Pages publishing guidance for this curriculum. |
| [Azure SRE Agent Reference](SRE-Agent-Reference.md) | Captures source-backed Azure SRE Agent behavior and caveats. |
| [Challenge 06 SRE Story Companion](Challenge-06-SRE-Story.md) | Companion SRE story notes for coaches and curriculum maintainers. |
| [Research Links](Research-Links.md) | Curated source links for GitHub, Azure, What The Hack, and SRE topics. |
| [Sample App Assets](sample-app/README.md) | Local Node.js service used for development, CI, deployment discussion, and incident simulation. |
| [Runbooks](runbooks/README.md) | Challenge 06 incident packet, triage template, and generated local evidence. |
| [Scripts](scripts/README.md) | Local scripts for simulating checkout incidents and validating agentic workflow specs. |
| [Infrastructure](infra/README.md) | Safe-by-default Bicep starting point for Azure deployment planning. |

## Delivery Assets Coaches Should Add

Before a live customer delivery, coaches should validate or add environment-specific assets such as:

- Preflight script or setup checklist.
- Baseline branch names.
- Azure deployment target details.
- Simulated deployment logs.
- Simulated cloud coding agent pull request.
- Starter repo instrumentation examples for instructions, persona, prompt or skill, and memory or decision note.
- GitHub Agentic Workflows style workflow specs, or `gh-aw` compiled lock files if the toolchain is available and approved.
- Simulated Azure SRE Agent investigation packet.
- Final demo rubric or scoring sheet.

Do not commit secrets, customer data, private tenant details, or live incident data to this folder.

## Navigation

- [Student challenges](../challenges/00-setup/README.md)
- [Agentic SDLC practices](Agentic-SDLC-Practices.md)
- [Agentic SDLC starter kit](Agentic-SDLC-Starter-Kit.md)
- [GitHub Agentic Workflows starter](GitHub-Agentic-Workflows-Starter.md)
- [Build Agentic Workflows](agentic-workflows/README.md)