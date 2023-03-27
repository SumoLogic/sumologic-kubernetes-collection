# Releasing guide

> **Note** For release v2 see [v2 releasing guide][release_v2]

Perform the following steps in order to release new verions of helm chart.

1. Prepare and merge PR with the following changes:

   - update [changelog][changelog] by running `make update-changelog VERSION=x.y.z` where `x.y.z` is the new version number.
   - update [chart][chart]
   - update [README.md][documentation]
     - add link to minor version, if created
     - set "supported until" date for previous minor version to 6 months after today

1. Create and push new tag:

   ```bash
   export TAG=x.y.z
   git checkout main
   git pull
   git tag -sm "v${TAG}" "v${TAG}"
   git push origin "v${TAG}"
   ```

1. Prepare release branch:

   - branch out:

     ```bash
     git checkout -b "release-v${TAG%.*}"
     ```

   - update [docs/README.md][deploy_title] (`for unreleased version` in title)
   - push branch:

     ```bash
     git push -u origin "release-v${TAG%.*}"
     ```

1. Create [new release][releases]

[deploy_title]: /docs/README.md#deployment-guide-for-unreleased-version
[changelog]: /CHANGELOG.md#unreleased
[chart]: /deploy/helm/sumologic/Chart.yaml
[releases]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases
[documentation]: /README.md#documentation
[release_v2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/release.md
