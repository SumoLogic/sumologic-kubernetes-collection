# Releasing guide

Perform the following steps in order to release new verions of helm chart.

1. Prepare and merge PR with the following changes:

   - update [changelog][changelog]
   - update [chart][chart]
   - update [README.md][documentation]
     - add link to minor version, if created
     - set "supported until" date for previous minor version to 6 months after today
   - update [deploy/README.md][deploy_matrix] (support matrix)

1. Create and push new tag:

   ```bash
   export TAG=x.y.z
   git tag -sm "v${TAG}" "v${TAG}"
   git push origin "v${TAG}"
   ```

1. Prepare release branch:

   - branch out:

     ```bash
     git checkout main
     git pull
     git checkout -b `release-v${TAG%.*}`
     ```

   - update [deploy/README.md][deploy_title] (`for unreleased version` in title)
   - push branch:

   ```bash
   git push origin `release-v${TAG%.*}`
   ```

1. Update description for [new release][releases]

[deploy_title]: ../README.md#deployment-guide-for-unreleased-version
[deploy_matrix]: ../README.md#support-matrix
[changelog]: ../../CHANGELOG.md#unreleased
[chart]: ../helm/sumologic/Chart.yaml
[releases]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases
[documentation]: ../../README.md#documentation
