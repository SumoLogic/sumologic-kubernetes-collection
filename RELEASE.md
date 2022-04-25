# How to release

Perform the following steps in order to release new verions of helm chart.

1. Prepare and merge PR with the following changes:

   - update [changelog][changelog]
   - update [chart][chart]
   - update [deploy/README.md][deploy] (support matrix)

1. Branch out `release-v${TAG}` and add the following changes:

   - update [deploy/README.md][deploy] (title)

1. Create and push new tag:

   ```bash
   export TAG=x.y.z
   git tag -sm "v${TAG}" "v${TAG}"
   git push origin "v${TAG}"
   ```

1. Update description for [new release][releases]

[deploy]: ../../deploy/README.md
[changelog]: ../../CHANGELOG.md#unreleased
[chart]: ../../deploy/helm/sumologic/Chart.yaml
[releases]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases
