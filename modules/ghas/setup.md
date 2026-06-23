# GHAS Module Setup

The GHAS challenges use [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/), an intentionally vulnerable Node.js application used for hands-on web security training. The module has two environments:

1. **Local Juice Shop runtime** — where you perform manual exploit testing.
2. **Shared org repository** — where GitHub Advanced Security (CodeQL, Dependabot, secret scanning) runs and produces alerts.

These are **separate**. You run Juice Shop locally for testing; the org repository is where GHAS features operate.

## Local Juice Shop Runtime

### Option A: GitHub Codespaces (preferred)

Open **this repository** (`microsoft/frontier-agenticdevops-hackathon`) in a Codespace — the devcontainer is already configured with Node.js and the required toolchain.

1. Open this repo on GitHub and click **Code → Codespaces → Create codespace on main**.
2. Wait for the devcontainer to finish provisioning.
3. Fetch and start Juice Shop:
   ```bash
   npm run setup:juice-shop
   cd app && npm install && npm start
   ```
4. Open the forwarded port 3000 in your browser for exploit testing.

### Option B: Local Docker

If you want a quick local runtime without cloning the full app, run Juice Shop directly with Docker:

```bash
docker run -p 3000:3000 bkimminich/juice-shop
```

### Option C: Organizer-hosted

A coach or organizer can provision a shared Juice Shop instance on a cloud VM and hand out the URL to participants. This is useful when students do not have Docker locally or when a workshop wants a prewarmed environment for everyone.

## Verification

Open [http://localhost:3000](http://localhost:3000) if you are running locally, or open the forwarded/hosted URL if you are using Codespaces or an organizer-hosted instance. The setup is ready when the Juice Shop UI loads in the browser.

## Important: GHAS Alerts Run on the Shared Org Repository

CodeQL, Dependabot, and secret scanning are configured on the **shared org repo** used for the hackathon, **not** on your local Juice Shop runtime. Your local or hosted Juice Shop instance is **only for manual testing** and exploit verification. 

The **alerts**, **PR checks**, and **Security tab workflows** referenced in the challenges come from the **shared organization repository** that your event organizer maintains. All GHAS features (code scanning, dependency analysis, secret detection) operate there, not on your local instance.

**Summary:**
- **Local Juice Shop (port 3000)** → manual exploit testing, learning the app
- **Shared org repository** → GHAS alerts, security dashboards, PR checks

See [`docs/EXTERNAL-REPOS.md`](../../docs/EXTERNAL-REPOS.md) for how Juice Shop and other external dependencies are managed and pinned.
