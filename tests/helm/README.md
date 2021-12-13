# Helm template tests

To add test for new template file, please create new directory with given structure:

```text
example_test/  # Test set name
├── config.sh  # Configuration file
└── static  # Test cases
    ├── test_name.input.yaml  # Input configuration for test_name
    └── test_name.output.yaml  # Output configuration for test_name
```

## Configuration file

`config.sh` should export `TEST_TEMPLATE` env variable, which should point to the helm template
file name, e.g. for `deploy/helm/sumologic/templates/configmap.yaml` it will be `templates/configmap.yaml`:

```bash
TEST_TEMPLATE="templates/configmap.yaml"
```

There's also a shared config file: `shared_config.sh` which will be sourced for
all tests with particular tests `config.sh`s taking precedence (as they will be
sourced later).

## Input file

Input file e.g. `test_name.input.yaml` should be compatible with `values.yaml`

## Output file

Output file is the yaml template which is expected to be output of the following command:

```bash
helm template deploy/helm/sumologic/ \
  --namespace sumologic \
  --set sumologic.accessId='accessId' \
  --set sumologic.accessKey='accessKey' \
  -f test_name.input.yaml \
  -s values.yaml
```
