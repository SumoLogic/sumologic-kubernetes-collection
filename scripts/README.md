# Fix for Helm Template Tests Without Dependencies

## Problem

When updating the OpenTelemetry operator chart version (e.g., from 0.86.4 to 0.93.0), the Helm template tests fail because they require chart dependencies to be present in the `deploy/helm/sumologic/charts/` directory. In environments without internet access or when external chart repositories are unavailable, `helm dependency build` fails, preventing the tests from running.

## Root Cause

The tests in `tests/helm/remotewrite_validation_test.go` are designed to validate that certain configurations trigger proper error messages from the chart's validation logic (in `deploy/helm/sumologic/templates/checks.txt`). However, these tests fail before reaching the validation logic because Helm requires all chart dependencies to be present, even when using `skipDependencies: true`.

## Solution

Create minimal stub charts that satisfy Helm's dependency requirements without requiring external repositories. This allows the tests to reach the validation logic and behave as expected.

## Usage

Run the following script to create minimal chart dependencies for testing:

```bash
./scripts/create-test-charts.sh
```

After running this script, the Helm template tests should pass:

```bash
cd tests/helm
go test -run "TestValidationOfRemoteWriteConfig" -v
```

## What the Script Does

1. Creates minimal `Chart.yaml` files for all dependencies listed in `deploy/helm/sumologic/Chart.yaml`
2. Adds necessary template helpers (specifically for `kube-prometheus-stack`)
3. Places these in the `deploy/helm/sumologic/charts/` directory

## Important Notes

- The `charts/` directory is already in `.gitignore`, so these test stubs won't be committed
- These are minimal stubs for testing only - they don't contain actual functionality
- In CI environments, this script should be run before executing `make test-templates`
- The actual fix for the OpenTelemetry operator chart update is simply ensuring the dependencies can be resolved

## Validation Logic

The tests validate that:
1. Remote write configurations fail with proper error message when Prometheus is disabled
2. Remote write configurations work when Prometheus is enabled  
3. Metrics disabled scenarios work correctly

The validation happens in `deploy/helm/sumologic/templates/checks.txt` lines 28-35.