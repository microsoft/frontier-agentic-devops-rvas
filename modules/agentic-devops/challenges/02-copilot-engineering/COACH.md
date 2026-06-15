# Coach Guide: Challenge 02 — Build with GitHub Copilot

### Expected Outcome

Teams use Copilot for comprehension, implementation help, test ideas, or review preparation, then validate the output themselves. They practice PROSE and write down one convention Copilot needed but the repo did not state.

### Strong Evidence

- Prompt includes relevant context and constraints.
- Prompt shows progressive disclosure, reduced scope, clear hierarchy, safety boundaries, and staged composition.
- Team rejects or edits part of the AI suggestion.
- Tests or manual checks align to acceptance criteria.
- Pull request states what AI helped with and what humans verified.

### Common Gaps

- Participants paste generated code without understanding it.
- Copilot suggests broader refactoring than the issue requires.
- Tests cover only happy paths.
- Pull request hides AI assistance rather than documenting validation.
- A useful convention is discovered but left only in the chat thread.

### Coach Hint

Ask Copilot for failure modes, then ask the team which failure modes matter for this service.
If the same correction appears twice, have the team externalize it into the starter context note or pull request template.
