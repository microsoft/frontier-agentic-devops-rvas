---
safe-outputs:
  jobs:
    publish-report:
      description: Publish one report to the destination fixed by the triggering event or configuration.
      runs-on: ubuntu-latest
      needs: agent
      if: needs.agent.result == 'success'
      permissions:
        contents: read
        issues: write
        pull-requests: read
        actions: read
      inputs:
        body:
          description: Markdown report, at most 12000 characters
          required: true
          type: string
        source_hash:
          description: Exact source_hash from the collected context
          required: true
          type: string
      steps:
        - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
          with:
            ref: ${{ github.event.pull_request.base.sha || github.sha }}
            persist-credentials: false
        - name: Recheck the source and publish
          env:
            GH_TOKEN: ${{ github.token }}
          run: node .github/workflows/report-pilot.cjs publish
---

Call publish-report once with your report body and the supplied source_hash.
The writer selects the destination, rechecks current source state, and writes
the publication marker with the report. Do not choose a destination yourself.
