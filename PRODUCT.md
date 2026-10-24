# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Customer delivery teams use the portal to choose and run hands-on activities
with customer engineers. Enterprise administrators also use the GitHub Enterprise
setup guide.

## Product Purpose

Help teams **understand where to start**, choose the right sessions or setup path,
adopt the GitHub platform, and start with Agentic DevSecOps.

Success means users can choose a relevant path and apply the work to their own
repositories or services.

## Positioning

The portal offers two routes: **learn by doing** through outcome-based sessions,
or **set up GitHub** with a guided Copilot CLI skill. Sessions use the team's own
environment so the work remains useful after delivery.

## Operating Context

- Delivery teams choose activities, build and share ordered session sets, and
  follow the delivery guides with customer engineers.
- Teams reuse one approved repository or service across selected activities.
  Sample applications are available when teams lack a suitable application.
- Enterprise administrators use the setup skill to assess an existing GitHub
  Enterprise Cloud account, review a saved plan, and approve each write batch.
  High-impact changes require separate confirmation.

## Capabilities and Constraints

- Preserve both entry routes, the activity catalog, outcome paths, session
  builder, and shared sets. Keep chapter order and prerequisites intact.
- The curriculum covers GitHub Enterprise Cloud, GitHub Advanced Security,
  GitHub Agentic Workflows, and SRE Agent.
- Serve the static site from `docs/` through GitHub Pages. Preserve the existing
  Node.js build, which requires no npm install.
- Activity metadata lives in `meta.yml`; the build generates site data.
  Do not maintain a second copy by hand.
- The setup skill does not run curriculum lab provisioners. Live end-to-end
  setup validation is still pending.

## Brand Commitments

Preserve the RVAS/RVAP identity and existing assets. Keep Microsoft product names
and technical terminology accurate.

Use a **clear-thinker voice**: short, direct sentences, concrete verbs, and plain
technical explanations. Remove repetition and low-value detail.

## Evidence on Hand

- `modules/`: activity metadata, delivery guides, and supporting resources.
- `outcomes.json`: outcome journeys used by the catalog.
- `docs/`: the existing portal, setup guides, and shared navigation.
- `docs/assets/img/`: existing brand assets.
- `plugins/github-enterprise-setup/`: setup plugin and its documentation.

These materials support descriptions of the available activities and setup
workflow. Do not invent customer results, testimonials, or validation claims.

## Product Principles

- Make the starting point and path choices clear.
- Help teams choose work that fits their goal, rather than complete every activity.
- Prefer the team's own repositories, services, and data.
- Keep setup changes reviewable and explicitly approved.
- Add detail only when it helps users decide or act.
