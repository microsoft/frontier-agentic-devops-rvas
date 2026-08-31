# Repository instructions

## Writing

Before creating or editing prose, invoke `/humanize-writing`.
Use the `clear-thinker` voice unless the user requests another voice.

### Default writing style

Write like a senior engineer explaining something to another competent engineer.

Prefer:
- short, direct sentences;
- concrete verbs over abstract nouns;
- active voice when the actor matters;
- ordinary words over formal or bureaucratic alternatives;
- one main idea per sentence;
- explicit subjects: say who does what;
- the shortest wording that preserves the technical meaning.

Write technical content clearly. Complexity should come from the subject, not from the prose.

Bad:
"If the earlier controls were implemented outside this series, confirm the required state in the table below."

Better:
"If you already implemented these controls elsewhere, check that they match the requirements below."

Bad:
"Completion of the configuration enables the establishment of the required governance posture."

Better:
"Complete this configuration to apply the required governance controls."

Bad:
"This section provides guidance for the implementation of controls that enable organizations to..."

Better:
"This section shows how to implement controls for..."

### Avoid bureaucratic prose

Do not turn verbs into abstract nouns when a verb works:
- "perform validation of" -> "validate"
- "make a determination" -> "decide"
- "provide configuration of" -> "configure"
- "enable the establishment of" -> "establish"
- "conduct an assessment of" -> "assess"

Avoid vague institutional phrases such as:
- "required state"
- "desired state"
- "in the context of"
- "with respect to"
- "in order to"
- "as part of this exercise"
- "the implementation of"
- "the configuration of"
- "it is important to note"
- "this enables organizations to"
- "the following section provides"
- "where applicable"
- "as appropriate"

Use them only when they carry necessary technical meaning.

### Do not over-explain

State the point, explain why it matters when necessary, and move on.

Do not add:
- introductory sentences that merely announce the next paragraph;
- conclusions that repeat the preceding paragraph;
- obvious explanations for expert readers;
- generic benefits;
- artificial transitions between every section;
- exhaustive qualification of straightforward statements.

Do not make a sentence more formal simply because it is documentation.

Optimize for sufficient completeness, not maximal completeness. Stop adding detail when the next addition would not materially change the reader's understanding,
decision, or ability to act, and stop when additional work has low marginal value.

Add some strategic bold text.

### Final prose pass

After drafting, read every sentence as if you had to say it aloud to a colleague.

For each sentence ask:
1. Could this be shorter without losing meaning?
2. Is there a simpler verb?
3. Is the subject clear?
4. Is an abstract noun hiding a simple action?
5. Would an experienced engineer actually say this?
6. Does the sentence contain information worth keeping?

Rewrite or delete sentences that fail this test.

Then apply the `/humanize-writing` AI-pattern dictionary.

Preserve technical facts, Microsoft product names, dates, citations, and governance terminology exactly.

## Visual identity

- Reuse the supplied RVAP logos and official Microsoft product icons. Do not redraw, recolor, crop, rotate, or distort them.
