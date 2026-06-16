# GitHub Pages Publishing

This repository can be published with GitHub Pages so participants have a simple front door during the event.

## Recommended Pages Entry Points

- [ATTRIBUTION.md](../ATTRIBUTION.md) as the module provenance page.
- [challenges/00-setup/README.md](../challenges/00-setup/README.md) as the first participant action.
- [Resources/README.md](README.md) for templates and fallback packets.

## Publishing Checklist

1. Confirm the repository is safe to publish to the intended audience.
2. Remove secrets, private tenant details, internal-only links, and customer data.
3. Confirm preview and fallback language is accurate for the delivery date.
4. Enable GitHub Pages using the approved branch and folder for the customer environment.
5. Test links from the landing page on desktop and projected display.
6. Provide coaches with a direct link to Challenge 00 before kickoff.

## Content Freshness

Agentic DevOps capabilities change quickly. Before each delivery, review these areas for accuracy:

- GitHub Copilot and coding agent availability.
- GitHub Actions and environment protection behavior.
- Azure deployment target setup.
- Azure SRE Agent source-code connection and PR creation behavior.
- Azure/sre-agent-plugins marketplace structure.

## Accessibility and Delivery Notes

- Keep the README as the main navigation surface.
- Avoid burying the first challenge behind multiple clicks.
- Use descriptive link text.
- Keep coach-only materials clearly separated from student challenges.
- If publishing publicly, verify that simulation packets contain no real customer data.
