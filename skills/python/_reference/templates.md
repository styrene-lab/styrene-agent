# Python Project Templates

Copy-paste templates for new projects. Replace `<package>` with your package name.

## pyproject.toml — Library (hatchling)

Used by: cleave, styrene-tui

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "package-name"
version = "0.1.0"
description = "One-line description"
readme = "README.md"
license = "MIT"
requires-python = ">=3.11"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov",
    "pytest-asyncio",
    "ruff>=0.4",
    "mypy>=1.10",
]

[tool.hatch.build.targets.wheel]
packages = ["src/<package>"]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "RUF"]
ignore = ["E501"]

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]

[tool.ruff.lint.isort]
known-first-party = ["<package>"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --strict-markers"
asyncio_mode = "auto"
markers = [
    "slow: marks tests as slow",
    "smoke: quick validation tests",
    "integration: requires external services",
]
```

## pyproject.toml — Application (setuptools)

Used by: styrened

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "app-name"
description = "One-line description"
readme = "README.md"
license = "MIT"
dynamic = ["version"]
requires-python = ">=3.11"
dependencies = []

[project.scripts]
app-name = "<package>.cli:main"

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov",
    "pytest-asyncio",
    "pytest-xdist",
    "ruff>=0.4",
    "mypy>=1.10",
]

[tool.setuptools]
package-dir = {"" = "src"}

[tool.setuptools.dynamic]
version = {attr = "<package>.__version__"}

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP", "N"]
ignore = ["E501"]

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]

[tool.ruff.lint.isort]
known-first-party = ["<package>"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = false
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
addopts = "-v --strict-markers"
asyncio_mode = "auto"
markers = [
    "slow: marks tests as slow",
    "smoke: quick validation tests",
    "integration: requires external services",
    "comprehensive: thorough test suite",
]
```

## Makefile

```makefile
VENV := .venv
PIP := $(VENV)/bin/pip
PYTHON := $(VENV)/bin/python

$(VENV)/bin/activate:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip

.PHONY: install
install: $(VENV)/bin/activate
	$(PIP) install -e ".[dev]"

.PHONY: test
test:
	$(PYTHON) -m pytest

.PHONY: test-cov
test-cov:
	$(PYTHON) -m pytest --cov=src --cov-report=term-missing

.PHONY: lint
lint:
	$(PYTHON) -m ruff check .
	$(PYTHON) -m ruff format --check .

.PHONY: format
format:
	$(PYTHON) -m ruff check --fix .
	$(PYTHON) -m ruff format .

.PHONY: typecheck
typecheck:
	$(PYTHON) -m mypy src/

.PHONY: validate
validate: lint typecheck test

.PHONY: clean
clean:
	rm -rf $(VENV) dist/ build/ *.egg-info src/*.egg-info .pytest_cache .mypy_cache .ruff_cache
```

## CI Workflow — Library

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.11", "3.12"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -e ".[dev]"
      - run: ruff check .
      - run: ruff format --check .
      - run: mypy src/
      - run: pytest --cov
```

## CI Workflow — Release to PyPI

```yaml
name: Release
on:
  push:
    tags: ["v*"]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install -e ".[dev]"
      - run: pytest

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: pip install build
      - run: python -m build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  publish:
    needs: build
    runs-on: ubuntu-latest
    environment: pypi
    permissions:
      id-token: write
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist/
      - uses: pypa/gh-action-pypi-publish@release/v1
        with:
          packages-dir: dist/

  github-release:
    needs: publish
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: dist
          path: dist/
      - uses: softprops/action-gh-release@v2
        with:
          files: dist/*
          generate_release_notes: true
```
