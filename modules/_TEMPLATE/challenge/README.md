# Activity Title

> One sentence: what the delivery team can do after finishing this activity.

## Delivery target

- Delivery target: the customer repository, organisation setting, workflow, or operating artefact this activity changes.
- Safety boundary: what needs owner approval, and what to do instead when approval is missing. Name the sample fallback here if there is one.
- Evidence: the artefacts the customer keeps afterwards.
- Owner: who accepts the result and operates it.
- Next decision: what that owner decides next. Drop this bullet when the owner bullet already covers it.

## Prerequisites

- Prior activities: none, or the activity ids listed in `meta.yml`.
- Access, licences, and local tooling the delivery team needs.

## Sample test repository or environment

Skip this if you brought your own target. Otherwise provision the sample, for example:

```bash
bash modules/<module>/resources/provisioning/scripts/setup.sh provision <activity-id> --org <org>
```

Delete this section for activities that create no sample resources.

## Tasks

1. One action per step. Include the GitHub UI path, CLI command, or YAML snippet the step needs.
2. Keep verification in the step that produces the result.
3. Close with the record or hand-off the owner needs.

## Reference links

- [GitHub Docs](https://docs.github.com/)
