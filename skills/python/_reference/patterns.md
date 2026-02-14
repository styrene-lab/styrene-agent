# Python Code Patterns

Detailed examples for testing, async, and common patterns used in styrene-lab.

## Fixtures

### Basic Fixture

```python
import pytest

@pytest.fixture
def config(tmp_path):
    """Temporary config file."""
    cfg = tmp_path / "config.yaml"
    cfg.write_text("key: value\n")
    return cfg
```

### Async Fixture with Cleanup

```python
@pytest.fixture
async def client():
    """Async client with teardown."""
    c = await Client.connect()
    yield c
    await c.close()
```

### Factory Fixture

```python
@pytest.fixture
def make_node():
    """Factory for test nodes with defaults."""
    def _make(name="test-node", online=True, **kwargs):
        return Node(name=name, online=online, **kwargs)
    return _make

def test_offline_node(make_node):
    node = make_node(online=False)
    assert not node.is_reachable
```

### Shared Fixtures in conftest.py

```python
# tests/conftest.py
import pytest

@pytest.fixture(scope="session")
def test_config():
    """Config shared across all tests in session."""
    return {"timeout": 5, "retries": 3}

@pytest.fixture(autouse=True)
def reset_state():
    """Auto-reset before each test."""
    yield
    State.reset()
```

## Mocking

### MagicMock for Sync Code

```python
from unittest.mock import MagicMock, patch

def test_handler_calls_service():
    mock_service = MagicMock()
    mock_service.get_status.return_value = {"online": True}
    handler = Handler(service=mock_service)
    result = handler.process()
    mock_service.get_status.assert_called_once()
    assert result["online"]
```

### AsyncMock for Async Code

```python
from unittest.mock import AsyncMock

async def test_async_send():
    mock_client = AsyncMock()
    mock_client.send.return_value = {"ok": True}
    result = await mock_client.send("hello")
    assert result["ok"]
    mock_client.send.assert_awaited_once_with("hello")
```

### Patching Modules

```python
from unittest.mock import patch

def test_patch_external():
    with patch("package.module.external_call") as mock_call:
        mock_call.return_value = 42
        assert do_something() == 42
        mock_call.assert_called_once()

# Decorator form
@patch("package.module.get_time", return_value=1000)
def test_with_decorator(mock_time):
    assert get_elapsed() == 1000
```

### Patching with pytest-monkeypatch

```python
def test_env_var(monkeypatch):
    monkeypatch.setenv("STYRENE_CONFIG", "/tmp/test.yaml")
    config = load_config()
    assert config.path == "/tmp/test.yaml"

def test_override_attribute(monkeypatch):
    monkeypatch.setattr("package.module.DEFAULT_TIMEOUT", 1)
    assert get_timeout() == 1
```

## Async Patterns

### Gathering Concurrent Results

```python
import asyncio

async def gather_status(nodes: list[str]) -> list[dict]:
    tasks = [get_status(node) for node in nodes]
    return await asyncio.gather(*tasks, return_exceptions=True)
```

### Timeouts

```python
async def with_timeout(coro, seconds: float = 10.0):
    try:
        return await asyncio.wait_for(coro, timeout=seconds)
    except asyncio.TimeoutError:
        logger.warning("Operation timed out after %s seconds", seconds)
        raise
```

### Task Groups (Python 3.11+)

```python
async def fetch_all(urls: list[str]) -> list[bytes]:
    results = []
    async with asyncio.TaskGroup() as tg:
        for url in urls:
            tg.create_task(fetch(url))
    return results
```

### Async Context Managers

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def managed_connection(host: str):
    conn = await connect(host)
    try:
        yield conn
    finally:
        await conn.close()

async def test_connection():
    async with managed_connection("localhost") as conn:
        assert conn.is_connected
```

## Data Models

### Dataclasses

```python
from dataclasses import dataclass, field

@dataclass
class NodeStatus:
    identity_hash: str
    online: bool
    uptime_seconds: int
    capabilities: list[str] = field(default_factory=list)

@dataclass(frozen=True)
class Config:
    """Immutable config."""
    host: str
    port: int = 4242
```

### Enums

```python
from enum import Enum, auto

class DeviceType(Enum):
    FULL_NODE = auto()
    EDGE_NODE = auto()
    TRANSPORT = auto()
```

## Path Handling

```python
from pathlib import Path

# Construction
config_dir = Path.home() / ".config" / "styrene"
config_dir.mkdir(parents=True, exist_ok=True)
config_file = config_dir / "config.yaml"

# Reading/writing
data = config_file.read_text()
config_file.write_text("key: value\n")

# Globbing
for py_file in Path("src").rglob("*.py"):
    print(py_file)

# Temporary paths in tests
def test_with_tmp(tmp_path):
    f = tmp_path / "test.txt"
    f.write_text("hello")
    assert f.read_text() == "hello"
```

## Logging

```python
import logging

logger = logging.getLogger(__name__)

# Basic usage
logger.debug("Processing node %s", node_hash)
logger.info("Device discovered", extra={"hash": dest_hash, "type": device_type})
logger.warning("Connection timeout after %d seconds", timeout)
logger.error("Failed to send message: %s", exc, exc_info=True)

# Configuration (usually in entry point)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
)
```

## Entry Points

```python
# src/package/cli.py
import argparse
import sys

def main() -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Tool description")
    parser.add_argument("--verbose", "-v", action="store_true")
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)

    # ... application logic
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

Registered in pyproject.toml:
```toml
[project.scripts]
command-name = "package.cli:main"
```

## Coverage

```bash
# Terminal report with missing lines
pytest --cov=src --cov-report=term-missing

# HTML report (opens in browser)
pytest --cov=src --cov-report=html
open htmlcov/index.html

# Fail if coverage drops below threshold
pytest --cov=src --cov-fail-under=80
```
