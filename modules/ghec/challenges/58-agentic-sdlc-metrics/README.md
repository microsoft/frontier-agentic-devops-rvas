# Ch58: Agentic SDLC metrics

**Session outcome:** The owner has a short table of agent pull request numbers from real history and makes one decision: widen, keep, or narrow auto-merge. The numbers come from `gh`, so anyone can rerun them.

Don't build a dashboard. A query you can rerun beats a chart nobody trusts.

## Measures

| Measure | Why it matters | Source |
|---|---|---|
| Share of pull requests by tier | Shows how much merges without a human | `risk:*` labels |
| Time to merge by tier | Shows if low-risk is faster | `createdAt`, `mergedAt` |
| Agent pull request merge rate | Low rate means bad tasks or instructions | author, `state` |
| Revert rate by tier | Shows if a tier is too loose | pull requests titled `Revert` |
| Review wait time | The bottleneck auto-merge should shrink | first review time |
| Cost per merged agent pull request | Keeps spend honest | Copilot usage reporting |

## Tasks

1. Pull 60 to 90 days of pull requests:

   ```bash
   gh pr list --state all --limit 500 \
     --json number,author,createdAt,mergedAt,closedAt,labels,title,state \
     > prs.json
   ```

2. Compute the first four measures with `jq` or a short script. Split agent authors (such as `Copilot` and `dependabot[bot]`) from humans.
3. For reverts, list pull requests whose title starts with `Revert`, and trace each to the original tier.
4. Get usage and spend from Copilot usage reporting for the same window. Divide by merged agent pull requests.
5. Put the results in one table in the adoption issue.

### Decide

6. Apply the rule with the owner:
   - **Widen** `low` if its revert rate is near zero and review wait is the bottleneck.
   - **Narrow** it after any incident, or if reverts exceed the owner's threshold.
   - **Stop** an agent task type if most of its pull requests close unmerged.
7. Make the change in `risk-tiers.json`, through a pull request. Record the next review date.

## Hints

- With few pull requests, say so. Small samples don't justify widening anything.
- Compare tiers to each other, not to an industry number.
- DORA metrics (lead time, deployment frequency, change failure rate, recovery time) belong beside these. Don't replace them.

## Common failures

| Symptom | Likely cause |
|---|---|
| Tier counts are zero | Pull requests predate ch53. Narrow the window. |
| Agent pull requests aren't separate | Author login differs. Check `author.login` in `prs.json`. |
| `gh` returns too few rows | `--limit` is too low. |
