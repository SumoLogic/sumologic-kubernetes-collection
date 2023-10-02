# Releasing guide for v2.x

:warning: This guide is for releasing v2.x. Go to [current releasing guide][release_current].

Perform the following steps in order to release new verions of helm chart.

1. Prepare and merge PR (to `release-v2` branch) with the following changes:

   - update [changelog][changelog]
   - update [chart][chart]
   - update [README.md][documentation]
     - add link to minor version, if created
     - set "supported until" date for previous minor version to 6 months after today
   - update [deploy/README.md][deploy_matrix] (support matrix)
   - Follow the below convention for the commit message
      - `chore: prepare release v2.y.z`
      - Please refer to https://www.conventionalcommits.org/en/v1.0.0/ for more on this

1. Prepare PR for the `main` branch with analogical changes

1. Create and push new tag:

   ```bash
   export TAG=2.y.z
   git checkout release-v2
   git pull
   git tag -sm "v${TAG}" "v${TAG}"
   git push origin "v${TAG}"
   ```

1. Prepare release branch:

   - branch out:

     ```bash
     git checkout -b "release-v${TAG%.*}"
     ```

   - update [deploy/README.md][deploy_title] (`for unreleased version` in title)
   - push branch:

   ```bash
   git push -u origin "release-v${TAG%.*}"
   ```

1. Create [new release][releases]

[deploy_title]: ../README.md#deployment-guide-for-unreleased-version
[deploy_matrix]: ../README.md#support-matrix
[changelog]: ../../CHANGELOG.md#unreleased
[chart]: ../helm/sumologic/Chart.yaml
[releases]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases
[documentation]: ../../README.md#documentation
[release_current]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/main/docs/release.md
