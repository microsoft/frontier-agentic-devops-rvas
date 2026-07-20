# Activity 3-03: Engine Swap

**Track:** Continuous Intelligence (Advanced)  
**Difficulty:** 🔴 Advanced  
**Estimated time:** 30 minutes  
**Prerequisites:** Track 2, completed ≥3 activities

---

## Background

**Different AI engines produce different results** on the same workflow — different reasoning quality, speed, cost, and failure modes.

Take the same workflow, run it with Copilot vs Claude vs Codex. You'll get:
- Different quality of reasoning
- Different speeds
- Different costs
- Different failure rates

**Engine Swap** is about **prompt portability**. You'll take ONE workflow design and rewrite it for three different engines, then compare results side-by-side.

The takeaway is not a fixed ranking. It's the habit: test your specific prompt against the engines available to your team, measure on the task you actually need, and make the choice deliberately.

**Why this matters:** Teams that ship production automation test their prompts across engines before committing to one. This activity builds that testing habit — run the same task on multiple engines, observe the actual output differences, and make a documented choice based on evidence from your own workflow.

---

## Goals

By the end of this activity, your squad will:

1. ✅ Take a working workflow and adapt it for multiple engines
2. ✅ Understand how engine choice affects prompt writing
3. ✅ Compare outputs side-by-side and make tradeoff decisions
4. ✅ Recognize which engines are best for which tasks

---

> [!IMPORTANT]
> **Bring your own repo (do this first)**
>
> This activity is most valuable when engine tradeoffs are measured against automation your team might actually keep. Pick a real issue, PR, or code-review task from a repository in an org you control and adapt the three engine versions around that same input.
>
> - **Have a candidate repo?** Use it everywhere this guide references the sample repo, and run Copilot, Claude, and Codex against the same real issue, PR, or code snippet so your comparison reflects production work.
> - **No suitable repo yet?** Use the provided sample repo from setup as the safe practice target.
>
> Tell your coach which path you took — bringing your own is the goal; the sample repo is the fallback.

## Activity

Pick one task. Build three versions of the same workflow, one for each engine.

### The Task (Pick One)

**Option A: "Issue Categorizer"**
- Trigger: `on: issues: types: [opened]`
- Job: Read a new issue, assign it a category (bug/feature/question/docs) and add a label
- Output: `safe-outputs: add-labels`

**Option B: "PR Size Classifier"**
- Trigger: `on: pull_request: types: [opened]`
- Job: Read PR diff, classify size (XS/S/M/L/XL) based on files changed + lines added
- Output: `safe-outputs: add-labels`

**Option C: "Code Review Comment Generator"**
- Trigger: Manual via `workflow_dispatch`
- Job: Given a code snippet (from a file in the repo), write a detailed review comment with 3 specific suggestions
- Output: `safe-outputs: create-issue` (log results)

### Create Three Versions

1. **`task-name-copilot.md`** — Engine: `copilot`
   - Prompt should be direct, concise, step-by-step
   - Copilot works well with structured instructions

2. **`task-name-claude.md`** — Engine: `claude`
   - Prompt can include more reasoning, nuance, edge cases
   - Claude excels at nuanced decision-making

3. **`task-name-codex.md`** — Engine: `codex`
   - Prompt should be code-focused or example-driven
   - Codex works best when you show examples or provide code context

### Compare

Run all three workflows (manually or schedule them). Collect results:
- Which engine was fastest?
- Which gave the most accurate results?
- Which cost more tokens?
- Which failed or hallucinated?

Summarize your findings in a markdown file: `RESULTS.md`

---

## Success Criteria

- [ ] Three versions of the workflow exist (one per engine)
- [ ] All three compile without errors (`gh aw compile` succeeds)
- [ ] All three run at least once (visible in Actions)
- [ ] At least one produces output on a real issue/PR/task
- [ ] You've tested all three and collected observations
- [ ] `RESULTS.md` documents: speed, quality, cost, and your recommendation
- [ ] Each engine's prompt is **adapted** to that engine (not copy-paste)
- [ ] Coach conversation — for one automation you actually care about, how would you decide which AI engine to trust once you have weighed its quality, speed, and cost tradeoffs side by side? Talk it through with your coach and connect it to a real project, task, or workflow you own.

---

## Tips & Hints

- Don't overthink the adaptation. Copilot likes bulleted lists. Claude likes reasoning chains. Codex likes code examples. Start there.
- Run all three on the *same input* (same issue, same PR) so you can compare fairly.
- Check the workflow logs and the GitHub API responses for differences. `gh run view <run-id> --log` is your friend.
- Token usage and time are visible in the workflow logs. Note them.
- Quality comparison is subjective—if one labels an issue "question" and another labels it "documentation", which was right? Decide as a squad.
- If you're not sure which engine is which, ask your coach—they'll clarify the differences.

---

## References

- **Supported Engines:** https://github.github.com/gh-aw/reference/engines/
- **Model aliases:** https://github.github.com/gh-aw/reference/model-tables/
- **Authentication for engines:** https://github.github.com/gh-aw/reference/auth/
- **Workflow frontmatter:** https://github.github.com/gh-aw/reference/frontmatter/

---

## Help

Stuck? Here's how to escalate:

- **"What's the difference between engines?"** → Start simple: Copilot = fast + practical, Claude = reasoning + nuance, Codex = code-focused. Your coach can go deeper.
- **"How do I adapt the prompt?"** → Read the engine-specific guides above. For Copilot, add numbered steps. For Claude, add context about why each decision matters. For Codex, add code examples.
- **"One engine keeps failing?"** → Check the logs. Add a fallback or adjust the prompt. It's OK if one engine isn't great for your task—that's valuable data!
- **"How do I run all three fairly?"** → Same input, same trigger time. Run them one after another on the same issue/PR.

Still stuck after 20 minutes? Raise your hand for your coach.
