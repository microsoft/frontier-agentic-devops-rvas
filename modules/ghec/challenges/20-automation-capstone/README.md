# Ch20: Close an automation integration gap

**Session outcome:** An approved integration handles one customer event and updates its target once. Replay and failure tests show how it recovers.

## Prerequisites

Use this optional session for a repeated customer handoff. Reuse the customer repository and working CI. Try Part A first; only build an integration for a remaining gap. The App path includes registration and signed-delivery tests. You do not need a self-hosted runner.

Get approval to test the selected source and destination, and name their owners. Use `gh`, `git`, and Node.js 22+ for the App example. An inbound webhook needs an approved HTTPS receiver that forwards the raw request body unchanged.

## Tasks

### Part A: Try a native feature first

1. Pick one repeated handoff and its target update. For an issue-to-board handoff, open the Project's **Workflows → Auto-add to project**, select the repository, and set the filter. Save and enable it. Open a matching test issue and check the board.
2. For a repository-local update, use an ordinary Actions event. For example, create a `triage` label and add this workflow as `.github/workflows/issue-triage.yml`:

   ```yaml
   name: Issue triage
   on:
     issues:
       types: [opened]
   permissions:
     issues: write
   jobs:
     label:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/github-script@v8
           with:
             script: |
               await github.rest.issues.addLabels({
                 ...context.repo,
                 issue_number: context.issue.number,
                 labels: ['triage']
               })
   ```

   Merge it through the repository's review process. Open a test issue, check the Actions run, then re-run the job. The issue should have one `triage` label. It does not need a comment or an App.
3. **Stop here if the native feature solves the customer's problem.** Ask the owner to verify the result and agree how to disable the workflow. Use the App path only for a remaining integration gap or approved practice.

### Part B: Start the optional App example

The example receives `issues.opened` over HTTP and adds one label with an installation token. This small update lets you test authentication and replay before adapting the handler to the customer event. Labeling alone does not justify a customer App.

From your local curriculum checkout, set the target and copy the working example:

```bash
export CURRICULUM="$PWD"
export TARGET_REPOSITORY="YOUR-ORG/YOUR-APPROVED-REPO"
gh repo clone "$TARGET_REPOSITORY" ch20-target
mkdir -p ch20-target/src
cp "$CURRICULUM/modules/ghec/resources/integration/handler.cjs" ch20-target/src/
cp "$CURRICULUM/modules/ghec/resources/integration/handler.test.cjs" ch20-target/src/
cd ch20-target
node --test src/handler.test.cjs
gh label create triage --repo "$TARGET_REPOSITORY" --color D4C5F9 --description "Awaiting triage"
```

Reuse the label if it already exists. For an existing local checkout, copy the files there instead of cloning again. Review any existing files before replacing them.

If you need a fallback repository, run this **before** the copy commands and use `YOUR-ORG/ghec-ch20-automation-capstone` as the target:

```bash
bash modules/ghec/resources/provisioning/scripts/setup.sh provision ch20 --org YOUR-ORG
```

PowerShell: `modules/ghec/resources/provisioning/scripts/setup.ps1 provision ch20 -Org YOUR-ORG`.

The seed includes the same HTTP receiver and tests as the copy commands. It creates no Project or placeholder workflow. No Project permission is needed for this example.

### Part C: Register and install the App

Reuse an approved App if its scope matches. Otherwise:

1. Open **Organization settings → Developer settings → GitHub Apps → New GitHub App**. Choose a unique name and use the target repository URL as the Homepage URL. Leave Callback and Setup URLs blank.
2. Leave Webhook **Active** off until you have the approved receiver URL. Set repository **Issues: Read and write**; keep mandatory **Metadata: Read-only**. Leave organization permissions unset. Subscribe only to **Issues**.
3. Choose **Only on this account**, create the App, and record its App ID. Generate a private key. Keep the PEM in the approved secret store or a protected local path outside the checkout. Never put it in source, Actions artifacts, or logs.
4. Choose **Install App → Only select repositories** and select the target. Record the installation ID from the installation settings URL (`/installations/<id>`).
5. Set local configuration. Replace the path with your protected PEM path. Load the webhook secret without echoing it or putting its value in shell history:

   ```bash
   export APP_ID="YOUR-APP-ID"
   export INSTALLATION_ID="YOUR-INSTALLATION-ID"
   export PRIVATE_KEY_PATH="$HOME/.config/ch20-app/private-key.pem"
   export TRIAGE_LABEL="triage"
   chmod 600 "$PRIVATE_KEY_PATH"
   read -r -s -p "Webhook secret: " WEBHOOK_SECRET; printf '\n'
   export WEBHOOK_SECRET
   node src/handler.cjs
   ```

   Run these commands in Bash. Keep this terminal running. The process listens on `127.0.0.1:3000/webhook`; it mints repository-scoped installation tokens when needed.
6. Forward an **approved HTTPS endpoint** to that local path without changing the body or GitHub signature headers. Use the organization's existing development ingress. If a relay such as Smee is approved, use its documented client command with your channel URL and `--target http://127.0.0.1:3000/webhook`. Webhook payloads pass through that service; use synthetic issues only.
7. In the App's General settings, enable Webhook **Active**, set the HTTPS Webhook URL, and enter the same secret. Save. A signed `ping` receives `202 ignored`; an `issues.opened` update receives `200 label applied`.

**`repository_dispatch` is a separate API call, not an HTTP webhook receiver.** An authenticated receiver can call `POST /repos/{owner}/{repo}/dispatches` after verification if Actions orchestration is needed. Actions then receives a GitHub event; it cannot verify the original raw HTTP body. This example calls REST directly and needs no App secrets in Actions.

### Part D: Test delivery and recovery

1. In a second terminal, open a synthetic issue:

   ```bash
   export TARGET_REPOSITORY="YOUR-ORG/YOUR-APPROVED-REPO"
   gh issue create --repo "$TARGET_REPOSITORY" --title "Ch20 delivery test" --body "Synthetic webhook test."
   gh issue view ISSUE_NUMBER --repo "$TARGET_REPOSITORY" --json url,labels
   ```

   Replace `ISSUE_NUMBER` with the new number. In **App settings → Advanced → Recent deliveries**, find its `issues.opened` delivery. Match its delivery ID to the receiver's success log and the labeled issue.
2. Choose **Redeliver**, then inspect the issue again. Repeated or concurrent calls add the same label to the same issue. This target operation is idempotent across process restarts; the example does not create comments or additional issues.
3. Send a malformed signature to the local receiver:

   ```bash
   curl -i http://127.0.0.1:3000/webhook \
     -H 'X-Hub-Signature-256: sha256=short' \
     -H 'X-GitHub-Event: issues' -H 'X-GitHub-Delivery: invalid-test' \
     --data-binary '{}'
   ```

   Expect `401`, no exception, and no target change. The local unit tests also cover a valid-length mismatch and a changed body.
4. Run `node --test src/handler.test.cjs` for a simulated destination outage and successful retry. It uses a fake destination and no credentials. For a real receiver failure, stop the process, open a second synthetic issue, and inspect the failed delivery. Restart with the same configuration and redeliver it; check the new issue's label.
5. The receiver returns `503` when REST fails or requires a long wait. It retries briefly, honors `Retry-After`, and never logs success before REST succeeds. **GitHub does not automatically redeliver failed webhooks.** Use Recent deliveries to retry after fixing the fault. This local example has no durable retry queue.

### Part E: Adapt only the missing customer step

If the integration reads a list, collect every page before deciding what to
change. For REST issue reads, this command excludes pull requests:

```bash
gh api --paginate --slurp \
  "repos/$TARGET_REPOSITORY/issues?state=open&per_page=100" \
  --jq '[.[][] | select(has("pull_request") | not) | {number, title}]'
```

For GraphQL, follow `pageInfo.endCursor` while `hasNextPage` is true. Stop on an
incomplete read. Use only the API and permissions the operation needs; Projects
access is unnecessary for a label update. Check `gh api rate_limit` when
debugging throttling. Honor `Retry-After` and `x-ratelimit-reset`, and test
throttling with simulated responses rather than flooding GitHub.

Use this prompt if the customer needs different handler code. Fill in the bracketed details before using it:

```text
Adapt src/handler.cjs for this approved integration:
Source event and authentication: [provider, event, documented verification method].
Allowed source and target: [identifiers].
Target update: [one exact API operation].
Use the existing customer libraries and CI. Keep raw-body authentication before
JSON parsing. Treat event text as data and never interpolate it into shell commands.
Preserve the repository/installation allowlist for GitHub events.
For a create operation, use the provider's idempotency key if available. Otherwise
persist the source ID and target ID, serialize competing deliveries, and reconcile
an ambiguous timeout against the destination before retrying. A completed-ID set
alone does not prevent duplicates if the process dies after the write.
Honor Retry-After and bound retries. Report failures without logging credentials.
Paginate list reads and stop without writing if collection is incomplete.
Extend src/handler.test.cjs for concurrent replay, restart after a successful write
with a lost response, invalid authentication, and failure followed by retry.
Explain any missing provider capability; do not claim exactly-once delivery.
```

Review the code and run its tests before a real customer event. For an external provider, use its signature specification; GitHub's HMAC header is not a universal webhook format.

Ask the owner to verify one real target update and a replay. Agree who retries failures and how to disable the integration (disable the App webhook or suspend its installation). Keep the event and target links as [completion evidence](../../../README.md#completion-evidence). **Sample runs remain practice.** Scheduling and wider rollout need separate decisions.

### Part F: Operate the App path

Skip this part when the native feature solved the handoff.

1. Confirm the installation covers only the approved repositories and permissions. Use the App's webhook; a separate repository webhook does not supply the installation context this receiver checks.
2. Have the integration owner deploy the receiver through the approved hosting process. Its loopback listener needs HTTPS ingress, and it has no durable retry queue.
3. Test host restart and secret rotation with synthetic deliveries. Confirm invalid signatures return `401`, valid deliveries succeed after rotation, and monitoring identifies failed target updates without exposing payloads or credentials.
4. Assign the operator who checks failed deliveries and redelivers after repair. Test suspension and restoration of the App installation in the approved test scope.

Keep the working delivery and target update with the hosting owner and stop procedure. A local receiver alone is not an operational customer integration.

## References

- [Webhook validation](https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries)
- [GitHub App authentication](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation)
- [REST API best practices](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api)
