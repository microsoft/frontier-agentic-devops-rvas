# shellcheck shell=bash
#
# challenges/ch45-packages-container-registry-governance/provision.sh
#
# Seeds a package governance sample repository. Setup does not push packages,
# change package visibility, grant package access, or delete package versions.

CH45_REPO="ghec-${CHID}-container-governance"

_ch45_repo_full() { printf '%s/%s' "$ORG" "$CH45_REPO"; }

_ch45_readme() {
  cat <<'EOF_README'
# Container Registry Governance Sample

Use this repository to publish and govern a sample GHCR package under an approved namespace.

Participant-owned package steps:

1. Build and publish a sample image to `ghcr.io/<org>/ghec-ch45-container-governance:<tag>`.
2. Configure package visibility and repository/team access explicitly.
3. Record digest, tags, metadata, retention, and cleanup decisions.

Setup intentionally pushes no packages and changes no package permissions.
EOF_README
}

_ch45_containerfile() {
  cat <<'EOF_CONTAINER'
FROM alpine:3.20
LABEL org.opencontainers.image.title="ghec-ch45-container-governance"
LABEL org.opencontainers.image.description="Sample image for GHCR governance validation"
LABEL org.opencontainers.image.source="https://github.com/OWNER/REPOSITORY"
CMD ["/bin/sh", "-c", "echo ghec-ch45 sample container"]
EOF_CONTAINER
}

_ch45_workflow() {
  cat <<'EOF_WORKFLOW'
name: Publish sample container

on:
  workflow_dispatch:
    inputs:
      tag:
        description: Image tag to publish
        required: true
        default: lab

permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and publish
        run: |
          IMAGE="ghcr.io/${{ github.repository_owner }}/ghec-ch45-container-governance:${{ inputs.tag }}"
          docker build -f Containerfile -t "$IMAGE" .
          docker push "$IMAGE"
          docker inspect "$IMAGE" --format='{{index .RepoDigests 0}}' || true
EOF_WORKFLOW
}

_ch45_policy() {
  cat <<'EOF_POLICY'
# Package Governance Register

| Package | Source repo | Visibility | Access model | Owner | Retention | Deletion approver | Evidence |
|---|---|---|---|---|---|---|
| ghcr.io/<org>/ghec-ch45-container-governance | ghec-ch45-container-governance | TBD | TBD | TBD | TBD | TBD | TBD |

## Required metadata

- Description
- Source repository link
- OCI labels
- Approved tags and digest
- Retention or cleanup decision
EOF_POLICY
}

_ch45_seed_files() {
  log_step "seeding container governance sample"
  gh_put_file "$ORG" "$CH45_REPO" "README.md" "Add container governance README" "$(_ch45_readme)"
  gh_put_file "$ORG" "$CH45_REPO" "Containerfile" "Add sample Containerfile" "$(_ch45_containerfile)"
  gh_put_file "$ORG" "$CH45_REPO" ".github/workflows/publish-container.yml" "Add package publish workflow scaffold" "$(_ch45_workflow)"
  gh_put_file "$ORG" "$CH45_REPO" "governance/package-register.md" "Add package governance register" "$(_ch45_policy)"
}

_ch45_print_snapshot() {
  log_step "package governance discovery commands"
  log_info "After publishing, inspect package settings in GitHub UI or via GraphQL/package APIs."
  if [[ "$DRY_RUN" == "true" ]]; then
    log_plan "would list workflows for $(_ch45_repo_full)"
    return 0
  fi
  gh workflow list --repo "$(_ch45_repo_full)" || log_warn "could not list workflows"
}

ghec_provision() {
  gh_create_repo "$ORG" "$CH45_REPO" private
  if [[ "$DRY_RUN" != "true" ]] && ! gh_repo_exists "$ORG" "$CH45_REPO"; then
    die "repo $(_ch45_repo_full) missing after create — aborting seed"
  fi
  _ch45_seed_files
  _ch45_print_snapshot
  echo >&2
  log_info "Next steps for the participant:"
  log_info "  - publish a sample image under ghcr.io/$ORG/$CH45_REPO"
  log_info "  - configure package visibility/access explicitly"
  log_info "  - record digest, retention, and cleanup evidence"
}

ghec_teardown() {
  guard_prefix "$CH45_REPO" "$CHID" || return 1
  gh_delete_repo "$ORG" "$CH45_REPO"
  log_warn "teardown does not delete GHCR packages; remove approved sample packages manually"
}

ghec_status() {
  log_step "status — $CHID in '$ORG'"
  if gh_repo_exists "$ORG" "$CH45_REPO"; then
    local workflows
    workflows="$(gh workflow list --repo "$(_ch45_repo_full)" 2>/dev/null | wc -l | tr -d ' ' || echo '?')"
    log_ok "repo $(_ch45_repo_full) present — $workflows workflows"
  else
    log_info "repo $(_ch45_repo_full) not provisioned"
  fi
}
