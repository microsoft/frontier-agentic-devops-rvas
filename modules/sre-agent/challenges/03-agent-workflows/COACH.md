# Coach Guide: Challenge 03 — Coordinate Agent Workflows

### Expected Outcome

Teams decompose work, preserve context in GitHub artifacts, make agent-assisted summaries or plans reviewable, and create a starter instrumentation set.

## Grounding conversation (you will be called)

Students are **expected to call you** to talk through this challenge's real-world impact before they consider it done. This is a required completion step, not optional — it is how we keep the learning grounded in their actual day-to-day work.

**Their question:** Coach conversation — looking at your team's current backlog, which coordination task (triage, planning, or review summarization) would you trust a workflow agent to attempt first, and what human checkpoint would you need before any output could affect code or infrastructure? Talk it through with your coach and connect it to a real project, task, or workflow you own.

Use these follow-ups to steer the conversation:
- Ask them to name a specific backlog item or recurring coordination task their team handles today — something they own, not a hypothetical.
- Ask what would go wrong if the agent got it 80% right: who would catch it, where, and how quickly — surfacing the real cost of a missed handoff.
- Ask them to define the one human checkpoint they would add to make this safe enough to run next week without babysitting it.

### Strong Evidence

- Work is split into small issues or checklist items.
- Instructions, agent persona, reusable prompt or skill, and memory/decision note exist as durable artifacts.
- Owners and validation expectations are visible.
- Agent-generated summary or plan is attached to the workflow.
- Review feedback changes the work or creates a follow-up.

### Common Gaps

- Agent output exists only in chat.
- No human owns the merge decision.
- Work decomposition is too broad to review.
- Handoff note omits risks and deployment readiness.
- Teams create a large prompt instead of small primitives.
- Teams cannot explain whether a primitive resolved, materialized, bound, or activated.

### Coach Hint

Ask: What did the agent decide, and what did the human decide? If the answer is unclear, ownership is unclear.
Then ask where the agent would find that rule next time.
