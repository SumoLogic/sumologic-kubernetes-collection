# Releasing guide

**Note** To do a v3.x release, go to [v3 releasing guide][release_v3].

**Note** To do a v2.x release, go to [v2 releasing guide][release_v2].

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

1. Create [new release][releases]. Copy generated changelog to release notes.

## Patch releases (vx.y.z)

- For patch releases on an already released minor version `vx.y`, re-use the existing `release-vx.y`
branch and use the above same steps. Merge your changes in existing release branch and create a tag `vx.y.z` from the existing release branch instead of creating a new release branch.
- For example, to do a minor patch release of `v4.21.2`, re-use the release branch `release-v4.21` and create the tag `v4.21.2` from it.

[deploy_title]: /docs/README.md#deployment-guide-for-unreleased-version
[changelog]: /CHANGELOG.md#unreleased
[chart]: /deploy/helm/sumologic/Chart.yaml
[releases]: https://github.com/SumoLogic/sumologic-kubernetes-collection/releases
[documentation]: /README.md#documentation
[release_v2]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2/deploy/docs/release.md
[release_v3]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v3/docs/release.md
