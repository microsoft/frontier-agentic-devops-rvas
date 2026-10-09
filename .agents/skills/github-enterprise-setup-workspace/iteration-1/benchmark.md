# Skill Benchmark: github-enterprise-setup

**Model**: <model-name>
**Date**: 2026-10-09T15:36:30Z
**Evals**: 1, 2, 3 (1 run each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 94% ± 10% | 67% ± 17% | +0.28 |
| Time | 101.0s ± 22.7s | 90.3s ± 9.1s | +10.7s |
| Tokens | 19345 ± 21301 | 10504 ± 6571 | +8841 |

## Analyst observations

- The skill improved the mean pass rate by 27.8 percentage points and added 10.7 seconds on average.
- The Copilot scenario showed the clearest gain: 6/6 checks with the skill versus 3/6 without it.
- The access-repair skill failed one assertion because discovery was blocked, even though it correctly failed closed. The next eval should score blocked-path safety separately from successful inventory.
- Several safety checks passed in both configurations, so they confirm minimum behavior more than skill-specific value.
- The next Copilot eval should verify time-sensitive API, preview, permission, and billing claims against dated official sources.
- Token values are output-character proxies, not billed model-token counts.
- This iteration used one run for each eval and configuration. The standard deviation reflects differences between scenarios, not repeated-run variance.