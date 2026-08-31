# Ch40: Actions OIDC with Azure Delivery Assurance

Apply the [Delivery Assurance Standard](../../../DELIVERY_ASSURANCE.md); `README.md` is canonical for tasks, evidence, commands, and Definition of Done.

## Assurance record

- **Authorized scope:** record GitHub repository, Azure tenant/subscription/resource group, identity, and approving owners.
- **Evidence:** link subject-claim design, Azure federated credential screenshot/API output, workflow URL, and denied negative test.
- **Open risk:** record old secrets, overbroad Azure roles, weak subject claims, or `none`.
- **Next decision:** record next workflow migration or old credential retirement.

## Reviewer focus

- Confirm setup did not create Azure resources or accept cloud credentials.
- Verify the subject claim is constrained to the intended repository and branch, tag, or environment.
- Ask why each job with `id-token: write` needs it.
- Confirm old client secrets are removed or have an owner-approved retirement date.
