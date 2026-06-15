# Coach Guide: Challenge 3-03 — Engine Swap

---

## Coaching Philosophy for This Challenge

This is the **engine selection and prompt portability challenge**. Squads have built workflows—now teach them to think **like engineers choosing a tool**.

Your job: Help them see that engine choice is not "pick the best one globally"—it's "pick the best for *this task*." Different engines, different tradeoffs.

**Key rule:** There's no "right" answer. Copilot might be faster but less accurate. Claude might be slower but smarter. That's the point—they should make the tradeoff consciously.

---

## Expected Outcomes

A finished solution has:

**Three workflows (e.g., Issue Categorizer):**

1. **`issue-categorizer-copilot.md`** (~25 lines)
   ```markdown
   engines:
     - copilot
   
   ---
   
   # Issue Categorizer (Copilot)
   
   Steps to categorize the issue:
   1. Read the issue title and body
   2. Determine the category: bug, feature, question, or docs
   3. Apply the label
   
   Use this logic:
   - "error", "crash", "broken" → bug
   - "add", "new", "implement" → feature
   - "?", "how", "why" → question
   - "docs", "readme", "guide" → docs
   ```

2. **`issue-categorizer-claude.md`** (~30 lines)
   ```markdown
   engines:
     - claude
   
   ---
   
   # Issue Categorizer (Claude)
   
   Analyze this GitHub issue carefully. Consider:
   
   - **Context:** What problem is the author describing?
   - **Intent:** Are they reporting a problem, requesting a feature, seeking help, or suggesting documentation?
   - **Evidence:** Look for keywords, tone, and specificity.
   
   Based on this analysis, categorize as:
   - bug: problem with current behavior
   - feature: request for new capability
   - question: asking for help/info
   - docs: documentation improvement
   
   Apply the appropriate label.
   ```

3. **`issue-categorizer-codex.md`** (~25 lines)
   ```markdown
   engines:
     - codex
   
   ---
   
   # Issue Categorizer (Codex)
   
   Given an issue, categorize it. Here's a code example:
   
   ```
   // Example 1
   Issue: "When I call foo, it crashes"
   Category: bug (code is broken)
   
   // Example 2
   Issue: "Can we add async/await support?"
   Category: feature (new capability)
   ```
   
   Now categorize the current issue using the same pattern.
   ```

**`RESULTS.md` Summary:**
```
# Engine Comparison Results

## Issue Categorizer Test

| Metric | Copilot | Claude | Codex |
|--------|---------|--------|-------|
| Accuracy | 4/5 | 5/5 | 3/5 |
| Speed | 2s | 8s | 4s |
| Tokens | ~500 | ~1200 | ~700 |
| Cost | Low | Medium | Medium |
| Failures | None | None | 1 hallucination |

## Recommendation

**Use Claude** for production: Most accurate on edge cases, worth the extra latency.

**Use Copilot** for real-time: Fast enough, good accuracy, lower cost.

**Avoid Codex** for this task: More expensive than Copilot, less accurate than Claude.
```

---

## Common Approaches

Squads will vary:

### Approach 1: "Copy-Paste Variants" (common first attempt)
All three workflows have identical prompts, just different engine declarations.

**Cons:** Misses the point. Engines work differently; prompts should adapt.

**Coach response:** "Here's the key insight: each engine has different strengths. Copilot likes step-by-step. Claude likes reasoning. Codex likes examples. Let's rewrite each one."

### Approach 2: "Full Adaptation"
Each prompt is rewritten for that engine's strengths.

**Pros:** Demonstrates true engine understanding, fair comparison
**Cons:** More work, but worth it

### Approach 3: "Two Engines" (time pressure)
Only tests 2 of 3 engines (e.g., Copilot + Claude, skip Codex).

**Cons:** Incomplete, but acceptable if time is tight.

**Coach guidance:** Prefer Approach 2. If squad runs out of time, push for at least Copilot + Claude.

---

## Common Pitfalls & Socratic Responses

### Pitfall 1: All three workflows have identical prompts
**Symptom:** Workflows compile, but the prompts look cut-and-pasted.

**Root cause:** Squad didn't adapt for each engine's strengths.

**Coach response:**
- "You're testing three engines, but the prompts are identical. How do they know they're different?"
- "Each engine has strengths. Copilot: structured tasks. Claude: nuanced reasoning. Codex: code examples. How would you rewrite each one?"
- Have them pick ONE difference per engine (e.g., add numbered steps for Copilot, add reasoning context for Claude).

### Pitfall 2: Unfair comparison (different inputs)
**Symptom:** Copilot tested on issue #100, Claude tested on issue #200. Results are different but not comparable.

**Root cause:** Didn't control for input.

**Coach response:**
- "How do you know the difference is the engine and not the input?"
- "Run all three on the same issue. Same issue, same trigger time, compare results."
- This is a critical scientific thinking moment.

### Pitfall 3: No metrics collected
**Symptom:** Squad runs the workflows but doesn't document speed, tokens, or quality.

**Root cause:** No plan for comparison.

**Coach response:**
- "What did you measure? Speed? Accuracy? Cost?"
- Have them collect at least 3 metrics (time, tokens, quality assessment).
- Direct them to workflow logs: `gh run view <run-id>` shows timing and token count.

### Pitfall 4: One engine fails or times out
**Symptom:** Claude times out, Codex hallucinations kick in, only Copilot works.

**Root cause:** Engine limitation or prompt too complex for that engine.

**Coach response:**
- "That's actually valuable data! Document it: 'Claude timed out on this task—maybe the prompt was too verbose for the API limit.'"
- "See if you can simplify the prompt or adjust the task. Or: accept that this engine isn't suitable for this task."
- Failure is data.

### Pitfall 5: RESULTS.md is vague
**Symptom:** "Claude was better" with no supporting data.

**Root cause:** Didn't document specifics.

**Coach response:**
- "What makes Claude 'better'? Faster? More accurate? Cheaper?"
- Have them fill in a comparison table with numbers and observations.
- "Put yourself in a product manager's shoes: based on your data, which engine would you recommend?"

### Pitfall 6: Engines not configured correctly
**Symptom:** Workflow compiles, but logs show "Engine not found" or "Copilot API error".

**Root cause:** Engine name typo or API credentials missing.

**Coach response:**
- "What does your `engines:` section say? Should be `copilot`, `claude`, or `codex` exactly."
- Check: do they have API access for all three engines? (Copilot is built-in; Claude and Codex may need setup)

---

## Coaching Questions

1. **"How is your Copilot prompt different from Claude?"** → Should be different; probe for understanding
2. **"What's Copilot's strength? Claude's?"** → Test conceptual understanding
3. **"Did you use the same input for all three?"** → Fair comparison check
4. **"What metrics did you collect?"** → Verification of effort
5. **"Which engine would you use in production and why?"** → Synthesis + decision-making
6. **"If one engine failed, what do you think caused it?"** → Problem-solving thinking

---

## Sample Solution

Share **only if stuck >20 minutes**. Have them type it.

**`issue-categorizer-copilot.md`:**

```markdown
---
on:
  issues:
    types: [opened]

permissions:
  contents: read
  issues: read

safe-outputs:
  add-labels:
    allowlist: [bug, feature, question, docs]

engines:
  - copilot

checkout: false
---

# Issue Categorizer (Copilot)

Categorize the GitHub issue into one of four categories using these steps:

1. Read the issue title and body
2. Identify the category by looking for keywords:
   - **bug**: "error", "crash", "broken", "not working", "issue"
   - **feature**: "add", "new", "implement", "request"
   - **question**: "how", "why", "can I", "?", "help"
   - **docs**: "documentation", "readme", "guide", "tutorial"
3. Select the single best category
4. Apply the label and call the safe-output

Always choose exactly one category. If ambiguous, prefer the most specific keyword match.
```

**`issue-categorizer-claude.md`:**

```markdown
---
on:
  issues:
    types: [opened]

permissions:
  contents: read
  issues: read

safe-outputs:
  add-labels:
    allowlist: [bug, feature, question, docs]

engines:
  - claude

checkout: false
---

# Issue Categorizer (Claude)

Analyze this GitHub issue and categorize it thoughtfully.

**Context:** Issues can be one of four types, each with different intent.

**Analysis steps:**
1. What is the author's intent? Are they reporting a problem, requesting a capability, seeking help, or suggesting documentation?
2. What keywords or tone signals this intent?
3. Is there any ambiguity? If so, why?

**Categories:**
- **bug**: The author is reporting a problem or broken behavior
- **feature**: The author is requesting new functionality
- **question**: The author is asking for help or information
- **docs**: The author is suggesting documentation improvements

Choose one category based on your analysis. Apply the corresponding label.
```

**`issue-categorizer-codex.md`:**

```markdown
---
on:
  issues:
    types: [opened]

permissions:
  contents: read
  issues: read

safe-outputs:
  add-labels:
    allowlist: [bug, feature, question, docs]

engines:
  - codex

checkout: false
---

# Issue Categorizer (Codex)

Categorize the GitHub issue. Here are examples:

```
Example 1: "When I run deploy.sh, it crashes with ENOENT"
→ bug (broken behavior, specific error)

Example 2: "Can we add support for async/await?"
→ feature (request for new capability)

Example 3: "How do I configure the database?"
→ question (asking for help)

Example 4: "The README doesn't explain the API"
→ docs (documentation gap)
```

Now categorize the current issue and apply the matching label.
```

**`RESULTS.md`:**

```markdown
# Engine Swap Results: Issue Categorizer

## Test Inputs
- Issue #123: "App crashes on startup" (expect: bug)
- Issue #124: "Add dark mode" (expect: feature)
- Issue #125: "How do I deploy?" (expect: question)
- Issue #126: "Update README" (expect: docs)

## Results

| Issue | Expected | Copilot | Claude | Codex |
|-------|----------|---------|--------|-------|
| #123 | bug | ✅ bug | ✅ bug | ✅ bug |
| #124 | feature | ✅ feature | ✅ feature | ✅ feature |
| #125 | question | ✅ question | ✅ question | ❌ feature |
| #126 | docs | ✅ docs | ✅ docs | ✅ docs |

**Accuracy:** Copilot 4/4, Claude 4/4, Codex 3/4

## Performance

| Metric | Copilot | Claude | Codex |
|--------|---------|--------|-------|
| Avg time | 1.2s | 4.5s | 2.1s |
| Tokens/run | ~400 | ~800 | ~600 |
| Cost/run (est) | $0.02 | $0.04 | $0.03 |
| Failures | 0 | 0 | 1 (hallucinated) |

## Recommendation

**Production choice: Copilot**
- Perfect accuracy on this task
- Fastest (1.2s vs 4.5s)
- Cheapest (1/2 cost of Claude)
- Structured prompts work great for classification

**Runner-up: Claude**
- Also perfect accuracy
- Slower, but gives more detailed reasoning
- Useful if edge cases become important

**Not recommended: Codex**
- Lower accuracy (1 error out of 4)
- Slower than Copilot, more expensive
- Doesn't add value for this classification task

## Lessons Learned

- Copilot excels at classification with step-by-step prompts
- Claude is more thoughtful but overkill for simple categories
- Codex struggled with this non-code task
```

---

## Why This Works

- **Three adaptations:** Shows understanding that engines differ
- **Fair testing:** Same input across all engines
- **Metrics collected:** Speed, accuracy, cost
- **Decision-making:** Recommendation based on tradeoffs, not gut feel
- **Learning moment:** Squad internalizes engine selection as a conscious choice

---

## Time Management

| Phase | Time | What to Do |
|-------|------|-----------|
| Orient | 3 min | Understand three engines, pick a task |
| Write v1 (Copilot) | 8 min | Build and test |
| Adapt v2 (Claude) | 6 min | Rewrite for reasoning |
| Adapt v3 (Codex) | 6 min | Rewrite for code/examples |
| Test all three | 5 min | Run on same input, collect metrics |
| Document RESULTS.md | 2 min | Fill in comparison table |

**Total: ~30 minutes.**

---

## Extension Ideas

1. **A/B test prompt variants:** Run Claude with two different prompt styles and see which is better.
2. **Cost optimization:** Optimize each engine's prompt to use fewer tokens while maintaining quality.
3. **Hybrid approach:** Use Copilot for fast triage, Claude for edge cases (two-stage pipeline).
4. **Sentiment analysis:** Add a second challenge (sentiment classification) and compare how engines perform.

---

## Debugging Checklist

- [ ] All three workflows compile?
- [ ] Engine names correct? (copilot, claude, codex)
- [ ] All three triggered on the same issue/PR?
- [ ] Workflows produced output? (check logs and results)
- [ ] Metrics collected? (time, tokens, accuracy)
- [ ] RESULTS.md written and filled out?
- [ ] Recommendation stated?

---

## Key Takeaways

- **Engine choice is a tradeoff:** Speed vs accuracy, cost vs quality. No single "best" engine.
- **Prompt adaptation matters:** Each engine responds to different instruction styles.
- **Data-driven decisions:** Use metrics, not hunches.
- **Production thinking:** Real teams test across engines. You now do too.
