# Start a remediation PR

Use this checklist at the start of the selected fix. Keep the same repository and finding through review and the default-branch rescan.

1. Confirm repository access, working tests, and scanning through [Prepare the remediation repository](../../challenge.html?id=ghas-00), or use the setup you already verified.
2. Open the relevant Security alert. Check its description against the affected code and the application's actual behavior. For a dependency, read the advisory and production dependency path.
3. Record priority and the fix owner on the alert's existing issue or PR. Create an issue only when the work needs one. Real credential exposure takes priority: involve the credential owner immediately.
4. Choose the case that matches the finding:

| Finding | Continue with |
|---|---|
| Query, command, or template injection | [Injection fix](../../challenge.html?id=ghas-02) |
| Unsafe HTML or script output | [XSS fix](../../challenge.html?id=ghas-03) |
| Missing ownership or role checks | [Authorization fix](../../challenge.html?id=ghas-04) |
| Exposed credential | [Credential response](../../challenge.html?id=ghas-admin-02#customer-path-respond-to-an-exposed-credential) |
| Vulnerable dependency | [Tested dependency update](../../challenge.html?id=ghas-admin-05#5-merge-a-security-update-pull-request) |

For code findings, open the affected file and use this prompt if Copilot is approved:

```text
Explain this alert against the current code. Identify the untrusted input and
the operation or permission check that makes it unsafe. Describe the affected
behavior and a test that would distinguish a real fix from a hidden finding.
Use the application's existing libraries. Do not change code yet.
```

Verify the explanation yourself. Set the regression test before implementing the fix. You only need the case your repository requires.
