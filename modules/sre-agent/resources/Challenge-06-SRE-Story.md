# Challenge 06 SRE Story Companion

This companion note gives coaches and curriculum maintainers the story detail behind Challenge 06. Use it to keep the student guide, incident packet, and facilitator prompts aligned around the same SRE response flow.

## Scenario

The team has just completed a deployment from the GitHub Actions path built in Challenge 4. The release passed the pipeline, but shortly after deployment the service starts returning intermittent errors. A synthetic health check reports elevated failures, and a customer-facing API endpoint shows higher latency than the baseline from the start of the day.

The team must investigate as if this were a real production signal. They can use Azure SRE Agent where available, or a coach-provided evidence packet when live access is not available.

## Participant Mission

Produce a short operational response that explains:

- the signal that started the investigation;
- the evidence reviewed;
- the most likely cause and why the team believes it;
- the remediation path;
- the follow-up issue, pull request, runbook change, or deployment gate the team would create next.

## Evidence Packet

Coaches should prepare enough evidence for teams to reason without guessing:

- alert or incident text;
- recent deployment record;
- GitHub Actions run result;
- recent pull request or commit summary;
- application log excerpt;
- metric or trace snapshot;
- runbook excerpt;
- source-code hint or file path, if source context is part of the exercise.

When Azure SRE Agent source-code connection is available, teams can use the connected repository to ask for likely source areas, file and line references, and a To-Do Plan. When it is not available, coaches can provide those artifacts as part of the packet and ask teams to validate them.

## Suggested Flow

1. Read the production signal and write the first hypothesis.
2. Review deployment and pull request evidence before choosing a cause.
3. Use source context, if available, to connect symptoms to a code path.
4. Draft a To-Do Plan for the investigation steps already taken and the steps still needed.
5. Write a customer-safe incident summary.
6. Create or describe the follow-up engineering work.

## Success Criteria

The team succeeds when its response is specific enough for another engineer to act on:

- evidence is named, not hand-waved;
- uncertainty is called out plainly;
- the suspected cause connects the operational symptom to a change, dependency, or configuration;
- the remediation is testable;
- follow-up work is tracked as an issue, pull request, runbook update, or deployment control.

## Coach Notes

Keep this challenge focused on operational reasoning. Azure SRE Agent is the assistant, not the answer key. If the agent proposes a cause, ask the team what evidence supports it. If the team jumps straight to a fix, ask what signal would prove the fix worked.

Good coach prompts:

- What changed most recently?
- Which signal is user-impacting, and which signal is only supporting evidence?
- What would make your hypothesis wrong?
- Where would you capture the follow-up work?
- Would this incident have been easier to investigate if the deployment had included better validation or observability?

## Source Caveats

Live Azure SRE Agent behavior depends on access, region, tenant policy, repository connection, and run mode. Pull request creation from chat also requires a connected repository and an existing source branch with committed changes. Keep a packet-based fallback ready so the challenge still works without live product access.