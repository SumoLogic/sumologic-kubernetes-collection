# AGENTS.md

## Commands

- Build: `make`
- Test (template): `make test`
- Test (integration): `make test-integration` (uses kind by default; can reuse an existing cluster via `USE_KUBECONFIG`/`KUBECONFIG`)
- Lint: `make lint`
- Format: `make format`
- Regenerate golden files: `make regenerate-goldenfiles`

## Tooling

- Build system: Make
- Helm chart linting: `helm lint` with dummy accessId/accessKey values
- Formatting: prettier (yaml, markdown)
- Go linting: golangci-lint

## Boundaries

- Never: commit secrets or credentials

## Testing

- Framework: Go `testing` package with golden file comparison (`tests/helm/`)
- Integration tests: Go tests against Kind clusters (`tests/integration/`)
- After changing helm templates, run `make regenerate-goldenfiles` or template tests will fail

## Git workflow

- Branch naming: Jira ticket prefix (e.g., SUMO-XXXXX/description)
- Commit prefixes: `fix:` for bug fixes, `chore:` for maintenance, `feat:` for features
- Always ask the user whether a changelog fragment file needs to be added

## Gotchas / context

- After modifying helm templates, golden files must be regenerated: `make regenerate-goldenfiles`
- Run `prettier -w "**/*.yaml" "**/*.yml"` or `make format` after editing yaml/md files to pass lint
- Helm dependency update is needed before running tests: `make helm-dependency-update`

<!-- See README for project overview — not duplicated here. -->
