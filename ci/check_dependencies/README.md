# dependency-checker

Dependency checker uses web scraping to get information about:

- platforms suppported by [Sumologic Kubernetes Helm Chart][helm-chart]
- subcharts which are use in [Sumologic Kubernetes Helm Chart][helm-chart]

## Usage

### Prepare a virtualenv and activate it

```bash
python -m venv .venv
source .venv/bin/activate
```

### Install dependencies

```bash
pip install -r requirements.txt
```

### Run the script

```bash
python main.py
```

Web pages used to get information are saved in `cache` directory to clean it please run:

```bash
rm -r ./cache
```

[helm-chart]: https://github.com/SumoLogic/sumologic-kubernetes-collection
