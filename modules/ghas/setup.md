# GHAS Module Setup

The GHAS challenges use [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/), an intentionally vulnerable Node.js application used for hands-on web security training. You run Juice Shop locally or in a cloud dev environment for manual testing, while GitHub Advanced Security alerts come from the shared org repository maintained for the hackathon.

## Option A: GitHub Codespaces (preferred)

The source repository, [`microsoft/frontier-ghas-hackathon`](https://github.com/microsoft/frontier-ghas-hackathon), includes a devcontainer setup that is the fastest path for most students.

1. Open the source repo on GitHub.
2. Create a new Codespace from the repository.
3. Wait for the devcontainer to finish provisioning.
4. Start Juice Shop if it is not already running in the workspace.
5. Open the forwarded port for port 3000 and use that URL for browser testing.

## Option B: Local Docker

If you want a quick local runtime without cloning the full app, run Juice Shop directly with Docker:

```bash
docker run -p 3000:3000 bkimminich/juice-shop
```

## Option C: Organizer-hosted

A coach or organizer can provision a shared Juice Shop instance on a cloud VM and hand out the URL to participants. This is useful when students do not have Docker locally or when a workshop wants a prewarmed environment for everyone.

## Verification

Open [http://localhost:3000](http://localhost:3000) if you are running locally, or open the forwarded/hosted URL if you are using Codespaces or an organizer-hosted instance. The setup is ready when the Juice Shop UI loads in the browser.

## Important note about GHAS alerts

CodeQL, Dependabot, and secret scanning are configured on the **shared org repo** used for the hackathon, not on your local Juice Shop runtime. Your local or hosted Juice Shop instance is only for manual testing and exploit verification. The alerts, PR checks, and Security tab workflows referenced in the challenges come from the shared repository.

## Reference

- Source hackathon repo: https://github.com/microsoft/frontier-ghas-hackathon
