---
name: ai-slop-detector
description: "User-invocable audit skill for detecting and surfacing AI-slop in documents and code: content that sounds AI-generated, is useless, generic, overconfident, fake, verbose, mechanically structured, or exists because of common LLM failure modes. Use only when the user explicitly asks to run the ai-slop-detector skill, asks for an AI-slop audit, or asks to list AI-generated slop in documents/code. Do not auto-trigger for normal writing edits, humanizing text, code review, linting, or implementation requests."
---

# AI-Slop Detector

Detect and surface AI-slop in documents and code. AI-slop is content that may look polished or complete at a glance but is low-value, generic, misleading, unactionable, performative, or mechanically produced by common LLM habits.

This skill audits and reports. It does **not** rewrite prose, refactor code, or fix findings unless the user explicitly asks in a follow-up.

## Operating principle

Treat AI-slop as an evidence problem, not a vibes problem. A phrase can feel AI-ish without being harmful; a code block can look tidy while being useless. Report only items where you can point to a concrete excerpt and explain why it is low-value or AI-shaped.

Avoid accusing a human author. Say "AI-slop pattern" or "LLM-shaped failure mode," not "AI wrote this."

## Inputs to inspect

Inspect the exact scope the user provides:

- Markdown, text, docs, specs, PRDs, READMEs, slide scripts, web copy, reports, prompts, or comments.
- Source code, tests, configuration, infrastructure-as-code, generated-looking helper scripts, examples, notebooks, and inline code comments.
- Mixed repositories where documents and code reinforce each other.

If the user provides binary documents such as PDF, DOCX, PPTX, or XLSX and the relevant extraction skill/tool is available, extract the text first, then apply this audit to the extracted content. Preserve page/section/sheet context where possible.

## AI-slop taxonomy

Use this taxonomy to classify findings. A single finding may match more than one category; choose the dominant one and mention secondary patterns in the detail.

### A. Prose and document slop

1. **Vacuous significance inflation**
   - Claims that something is "crucial," "transformative," "pivotal," "innovative," "robust," "seamless," or "game-changing" without explaining what changed, for whom, or how it is measured.
   - Boilerplate "underscores the importance of," "plays a key role in," "sets the stage for," "in today's rapidly evolving landscape."

2. **Generic filler and corporate fog**
   - Sentences that could appear in any document with the nouns swapped.
   - Strategy-sounding words with no owner, decision, tradeoff, date, metric, or dependency.
   - Phrases like "drive value," "enhance efficiency," "unlock insights," "foster collaboration," "ensure alignment," when not tied to a concrete mechanism.

3. **Mechanical structure**
   - Repetitive three-part lists, symmetrical paragraphs, overuse of headings, bullet waterfalls, "not only X but also Y," or repeated "by doing X, teams can Y" patterns.
   - A polished outline that hides the absence of substance.

4. **Fake specificity**
   - Precise-sounding numbers, examples, named risks, personas, or timelines with no source or derivation.
   - Invented citations, invented customer quotes, or fabricated authority signals.

5. **Tautologies and non-decisions**
   - Statements that restate the obvious: "Testing ensures quality," "Security is important," "The platform should be scalable."
   - Requirements that cannot be accepted or rejected because they lack thresholds.

6. **Hedged overconfidence**
   - Phrases that combine certainty with vagueness: "typically," "generally," "can help," "may significantly improve," "is designed to ensure."
   - Sweeping claims without evidence, especially about safety, compliance, productivity, or user behavior.

7. **Placeholder masquerading as content**
   - TODO-like text dressed up as a finished section.
   - Sections that say what will be discussed instead of actually discussing it.
   - "Overview," "Key considerations," or "Best practices" content that never makes a concrete recommendation.

8. **Prompt-shaped prose**
   - Text that exposes the model's generation pattern: "Certainly," "Here is a comprehensive...", "Let's dive into...", "In conclusion," "It is worth noting."
   - Meta-commentary that belongs in a chat response, not the target document.

9. **Audience mismatch**
   - Explanations that are too generic for the stated audience, or assume away domain-specific constraints.
   - Content that sounds plausible to outsiders but would not help the actual reader act.

### B. Code and engineering slop

1. **Useless abstraction**
   - Wrappers, factories, managers, interfaces, adapters, or utility modules that add names but no behavior, policy, or reuse.
   - Over-generalized code for only one call site.

2. **Comment noise**
   - Comments that restate syntax or obvious intent: "Initialize variable," "Loop through items," "Return response."
   - Docstrings that promise robustness, security, or validation the code does not implement.

3. **Fake completeness**
   - TODOs, placeholders, pass-through methods, hardcoded sample data, simulated delays, demo branches, or random outputs on paths presented as real.
   - UI wired to static arrays while the surrounding text claims live integration.

4. **Defensive-looking but ineffective code**
   - Broad catches that return success-shaped defaults.
   - Validation that checks types but not business constraints.
   - Retries, logging, or error handling that cannot change the outcome.

5. **Test slop**
   - Tests that assert mocks, snapshots, or implementation details without verifying behavior.
   - Tests that pass even if the real integration is broken.
   - "Comprehensive" test names covering only happy paths.

6. **Type-safety theater**
   - `any`, double casts, overly broad interfaces, optional fields everywhere, stringly typed dispatch, or schemas that accept anything.
   - Types that document wishful thinking rather than enforce constraints.

7. **Config and IaC boilerplate slop**
   - Repeated blocks with no meaningful variation.
   - Parameters exposed "for flexibility" but never changed.
   - Security, observability, or scaling settings declared in names/comments but not actually enforced.

8. **Hallucination residue**
   - Imports, APIs, CLI flags, environment variables, config keys, or SDK methods that look plausible but are unsupported.
   - Dead code paths caused by made-up integration assumptions.

9. **Generated-code smell**
   - Overly uniform naming, unnecessary helper splitting, excessive indirection, repeated error messages, or large patches that optimize for apparent completeness over maintainability.

### C. Cross-cutting AI failure modes

- **Plausibility over truth:** sounds right but has no evidence.
- **Completion bias:** fills every heading even when there is nothing useful to say.
- **Symmetry bias:** forces balanced pros/cons, three bullets, or mirrored sections where the content is uneven.
- **Safety blanket language:** adds compliance/security/accessibility claims without implementation.
- **Local coherence, global incoherence:** each paragraph/function makes sense alone, but the whole document/system has contradictions or no through-line.
- **Authority laundering:** makes weak claims look stronger through confident tone, citations, named frameworks, or invented best practices.

## Audit method

1. **Map the target.** Identify which files or excerpts are documents, code, tests, config, or mixed content. If the user did not define a scope, inspect the likely user-facing docs and recently changed code first.
2. **Scan for surface tells.** Search for generic AI phrases, repetitive structures, placeholder markers, broad claims, broad catches, hardcoded sample data, excessive comments, and fake-complete tests.
3. **Check usefulness.** For each candidate, ask: "Would a capable human reader or maintainer know what to do differently after reading this?" If no, it is likely slop.
4. **Check evidence.** For claims, look for a source, measurement, implementation, acceptance criterion, or linked code path. Missing evidence is not always slop, but confident unsupported claims are.
5. **Separate harmless style from harmful slop.** Do not report an em dash, a common phrase, or a neat list by itself. Report it when the wording hides vagueness, false authority, or missing implementation.
6. **Prefer fewer, stronger findings.** Do not pad. Merge repeated instances of the same pattern when one root cause explains them.

## Severity

Use severity to show why the slop matters:

- **High:** Misleads readers about shipped behavior, safety, compliance, integration status, or test coverage; could cause bad decisions.
- **Medium:** Wastes reviewer/user time, obscures requirements, bloats code, or makes maintenance harder.
- **Low:** Mostly stylistic AI residue that weakens credibility but is unlikely to change decisions.

## Output format

### 1. AI-slop summary

Give a short verdict:

- **Overall slop level:** Low / Medium / High
- **Most common pattern:** the dominant taxonomy category
- **Highest-risk area:** file/section with the most misleading or decision-affecting slop

### 2. Findings table

| # | Severity | Type | Location | AI-slop pattern | Why it matters |
|---|----------|------|----------|-----------------|----------------|

Type ∈ { Document/prose · Code · Test · Config/IaC · Cross-cutting }

### 3. Finding details

For each finding:

**[#N] {Severity} — {short title}**
- **Location:** `path:line` or document section/page
- **Excerpt:** quote the exact sentence, paragraph, code block, or comment
- **Pattern:** taxonomy category
- **Why this is AI-slop:** explain the LLM-shaped failure mode and why it is useless, misleading, or low-value
- **What a useful version would contain:** describe the missing evidence, decision, metric, behavior, implementation, or constraint; do not rewrite unless asked

### 4. Repeated slop clusters

List recurring phrases, structures, helper patterns, or code smells that appear across multiple places. Include locations and the likely root habit, such as "completion bias created empty best-practice sections" or "generated-code smell created one-method wrapper classes."

### 5. Not slop / intentionally acceptable

Briefly mention any suspicious-looking patterns you deliberately did **not** flag because they are justified by the context. This keeps the audit fair and prevents style policing.

## Guardrails

- Do not claim content was AI-generated. Identify AI-slop patterns.
- Do not rewrite or fix content unless asked.
- Do not flag every polished sentence; focus on uselessness, misleading completeness, and model-shaped failure modes.
- Do not treat domain jargon as slop when it is precise and useful to the intended audience.
- Do not report security-sensitive code snippets beyond what is necessary to cite evidence.
