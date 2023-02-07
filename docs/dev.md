# Development

This document contains information helpful for developers.

## Changelog management

We use [Towncrier](https://towncrier.readthedocs.io) for changelog management. We keep the changelog entries for currently unreleased
changed in the [.changelog] directory. The contents of this directory are consumed when the changelog is updated prior to a release.

### Adding a changelog entry

If you want to add a changelog entry for your PR, run:

```bash
make add-changelog-entry
```

You can also just create the file manually. The filename format is `<PR NUMBER>.<CHANGE TYPE>(.<FRAGMENT NUMBER>).txt`, and the content is
the entry text.

### My change doesn't need a changelog entry

Add a `Skip Changelog` label to your Pull Request.

### How do I update the changelog while releasing?

```bash
make update-changelog VERSION=x.x.x
```

### How do I add multiple entries for the same PR?

Add a counter to your entry file names. For example, if you wanted to have three entries for PR `#123`, which is a fix, you'd create the
following files in [.changelog]:

```text
123.fixed.0.txt
123.fixed.1.txt
123.fixed.2.txt
```

Unfortunately, the `towncrier create` command doesn't have support for this [yet](https://github.com/twisted/towncrier/issues/474), so you
need to create the files manually.

### How do I add an entry with multiple PR links?

Just add an entry with the same text for each PR, they will be grouped together.

## Installation of non-official Helm charts

| DISCLAIMER                                                                                                                                                                 |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| We recommend testing dev releases on non-production clusters. <br/> These releases are generated continuously from contributions to this repo and may not be fully tested. |

Non-official Helm charts are available in [dev] directory on [gh-pages] branch.

[dev]: https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/gh-pages/dev
[gh-pages]: https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/gh-pages

To use non-official Helm charts it is necessary to add repository containing them:

```bash
helm repo add sumologic-dev https://sumologic.github.io/sumologic-kubernetes-collection/dev
helm repo update
```

To install/upgrade Helm chart you can use `helm upgrade` command with following arguments:

```bash
helm upgrade <release> sumologic-dev/sumologic \
        --install \
        --namespace <namespace> \
        --version <version> \
        -f <values>
```

e.g.

```bash
helm upgrade collection sumologic-dev/sumologic \
        --install \
        --namespace sumologic \
        --version 2.0.0-dev.0-83-g7cbe1a27 \
        -f /sumologic/vagrant/values.yaml,/sumologic/vagrant/values.local.yaml
```
