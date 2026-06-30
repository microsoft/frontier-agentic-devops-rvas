# Azure SRE Agent Reference Architecture

## Learning Architecture

The SRE Agent track follows an Azure-first evidence chain:

```text
Azure SRE Agent lab prerequisites
  -> Grubify sample app and Azure SRE Agent deployment
  -> connected Azure resources, incidents, knowledge, and runbooks
  -> controlled Grubify failure
  -> Azure Monitor alert
  -> Azure SRE Agent investigation
  -> Log Analytics / Application Insights / resource evidence
  -> source-code context when available
  -> GitHub issue or reviewed pull request
  -> recovery evidence
  -> post-incident improvement
```

## Core Systems

| System | Role in the track |
| --- | --- |
| Azure SRE Agent | Investigates incidents, uses connected context, proposes mitigation and remediation. |
| Grubify starter lab | Microsoft-provided sample app used for break-fix scenarios. |
| Azure Monitor | Produces alerts and incident signals. |
| Log Analytics | Provides queryable logs for evidence. |
| Application Insights | Provides request, exception, and trace context. |
| Knowledge files and runbooks | Give the agent service-specific operating instructions. |
| Source-code connector | Adds repository context for file/line leads and remediation work. |
| GitHub | Tracks issues or pull requests after Azure evidence supports engineering follow-up. |

## Human, Agent, and Platform Layers

| Layer | Responsibility |
| --- | --- |
| Human | Owns incident declaration, customer communication, approval gates, and production-risk decisions. |
| Azure SRE Agent | Investigates, summarizes evidence, suggests mitigation, correlates symptoms to code, and drafts follow-up. |
| Platform | Supplies inspectable evidence: alerts, logs, traces, metrics, source diffs, issues, pull requests, and recovery checks. |

Agent output is useful evidence, not proof by itself. Teams should validate it against Azure telemetry, runbooks, source references, or recovery checks.

## Fallback Model

When live Azure access is blocked, coaches should preserve the same shape:

| Live artifact | Fallback artifact |
| --- | --- |
| Azure Monitor alert | Alert screenshot or text |
| Log Analytics query | Sanitized log excerpt |
| Application Insights trace | Sanitized trace/exception excerpt |
| SRE Agent transcript | Prepared transcript with evidence |
| Source connector | File/line source packet |
| GitHub issue/PR | Simulated issue or reviewed PR packet |

The fallback should still require evidence, uncertainty, human review, recovery proof, and one improvement.
