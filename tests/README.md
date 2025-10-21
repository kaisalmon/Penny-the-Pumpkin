# Penny the Pumpkin - Unit Tests

Comprehensive unit test suite for the Penny the Pumpkin PICO-8 game.

## Overview

This test suite provides comprehensive coverage of the game's core systems:

- **Utility Functions**: Mathematical helpers, interpolation, and table operations
- **Physics System**: Gravity, collision detection, spring mechanics, and bounce physics
- **Game State Management**: Checkpoints, coin collection, save/load, and speedrun tracking

## Test Framework

The test suite uses a custom lightweight testing framework specifically designed for Lua/PICO-8 code. The framework provides:

- **Test Suites**: Group related tests using `describe()`
- **Test Cases**: Individual tests using `it()`
- **Setup/Teardown**: `before_each()` and `after_each()` hooks
- **Rich Assertions**: Multiple assertion types for comprehensive testing
- **Mock PICO-8 API**: Simulates PICO-8 functions for testing outside the runtime

## Requirements

- **Lua 5.3 or higher** (Lua 5.4 recommended)
- No external dependencies - all testing tools are included

## Installation

1. Ensure Lua is installed on your system:
   ```bash
   lua -v
   ```

2. If Lua is not installed:
   - **Ubuntu/Debian**: `sudo apt-get install lua5.4`
   - **macOS**: `brew install lua`
   - **Windows**: Download from https://www.lua.org/download.html

## Running Tests

### Run All Tests

```bash
lua tests/run_tests.lua
```

### Make Test Runner Executable (Unix/Linux/macOS)

```bash
chmod +x tests/run_tests.lua
./tests/run_tests.lua
```

### Run Individual Test Files

```bash
# Utility tests only
lua -e "require('tests/pico8_mock'); require('tests/test_utilities'); require('tests/test_framework').run()"

# Physics tests only
lua -e "require('tests/pico8_mock'); require('tests/test_physics'); require('tests/test_framework').run()"

# Game state tests only
lua -e "require('tests/pico8_mock'); require('tests/test_game_state'); require('tests/test_framework').run()"
```

## Test Structure

```
tests/
├── README.md              # This file
├── run_tests.lua          # Main test runner
├── test_framework.lua     # Testing framework
├── pico8_mock.lua         # PICO-8 API mocks
├── test_utilities.lua     # Utility function tests
├── test_physics.lua       # Physics system tests
└── test_game_state.lua    # Game state tests
```

## Test Coverage

### Utility Functions (test_utilities.lua)

- ✓ Linear interpolation (lerp)
- ✓ Bounding box calculations
- ✓ Character overlap detection
- ✓ PICO-8 math functions (sgn, flr, abs, min, max, sqrt)
- ✓ Table utilities (add, del, deli, count, foreach)

### Physics System (test_physics.lua)

- ✓ Smash detection for falling damage
- ✓ Character width calculation based on stretch
- ✓ Gravity application (normal and jump-held)
- ✓ Air resistance and friction
- ✓ Terminal velocity clamping
- ✓ Jump mechanics and coyote time
- ✓ Spring physics for head-body connection
- ✓ Collision response and bounce physics

### Game State Management (test_game_state.lua)

- ✓ Checkpoint system (position, velocity, coins)
- ✓ Coin collection and persistence
- ✓ Speedrun mode tracking
- ✓ Death and respawn mechanics
- ✓ Cartridge data persistence
- ✓ Game completion detection

## Available Assertions

The test framework provides the following assertions:

```lua
Assert.equal(actual, expected, message)
Assert.not_equal(actual, expected, message)
Assert.is_true(value, message)
Assert.is_false(value, message)
Assert.is_nil(value, message)
Assert.is_not_nil(value, message)
Assert.greater_than(actual, expected, message)
Assert.less_than(actual, expected, message)
Assert.approximately(actual, expected, delta, message)
Assert.table_equal(actual, expected, message)
Assert.throws(function, expected_error, message)
```

## Writing New Tests

To add new tests, create a new file in the `tests/` directory:

```lua
local test = require("tests/test_framework")
local mock = require("tests/pico8_mock")

test.describe("My Feature", function()
  test.before_each(function()
    -- Setup code runs before each test
    mock.reset()
  end)

  test.it("should do something", function()
    -- Test code
    local result = my_function(5)
    test.assert.equal(result, 10)
  end)

  test.after_each(function()
    -- Teardown code runs after each test
  end)
end)
```

Then add your test file to `run_tests.lua`:

```lua
local test_files = {
  -- ... existing files ...
  "tests/test_my_feature"
}
```

## Mock PICO-8 API

The mock provides simulated versions of PICO-8 functions:

### Math Functions
- `sgn()`, `flr()`, `ceil()`, `abs()`, `min()`, `max()`, `sqrt()`
- `sin()`, `cos()`, `atan2()`
- `rnd()`, `srand()`

### Table Functions
- `add()`, `del()`, `deli()`, `count()`, `all()`, `foreach()`

### Game Functions
- `time()`, `btn()`, `btnp()`
- `mget()`, `mset()`, `fget()`, `fset()`
- `dget()`, `dset()`

### Graphics Functions (tracked but not rendered)
- `camera()`, `clip()`, `rectfill()`, `circfill()`
- `spr()`, `sspr()`, `print()`, `pset()`
- `pal()`, `palt()`, `fillp()`

### Audio Functions (tracked but not played)
- `sfx()`, `music()`

## Mock State Control

```lua
-- Time control
mock.set_time(5.5)
mock.advance_time(1.0)

-- Button input
mock.set_button(4, true)  -- Press jump button
mock.reset_buttons()

-- Map tiles
mock.set_tile(10, 10, 62)
mock.clear_map()

-- Sprite flags
mock.set_sprite_flag(32, 7, true)

-- Cartridge data
mock.set_cartdata(63, 5)
mock.clear_cartdata()

-- Reset everything
mock.reset()
```

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Lua
        run: sudo apt-get install -y lua5.4
      - name: Run Tests
        run: lua tests/run_tests.lua
```

## Troubleshooting

### "module not found" errors

Ensure you're running tests from the project root directory:
```bash
cd /path/to/Penny-the-Pumpkin
lua tests/run_tests.lua
```

### Tests fail with "attempt to call nil value"

This usually means a PICO-8 function is used but not mocked. Check `pico8_mock.lua` and add the missing function.

### Permission denied on Unix systems

Make the test runner executable:
```bash
chmod +x tests/run_tests.lua
```

## Contributing

When adding new game features:

1. Write tests for the new functionality
2. Ensure all tests pass before committing
3. Update this README if adding new test categories
4. Maintain test coverage above 80%

## Testing Philosophy

These tests focus on:

- **Unit Testing**: Testing individual functions in isolation
- **Pure Logic**: Testing game logic without PICO-8 runtime dependencies
- **Edge Cases**: Testing boundary conditions and error cases
- **Determinism**: Using fixed random seeds for reproducible tests

## Performance

The test suite is designed to run quickly:
- All tests typically complete in under 1 second
- No external network calls or file I/O (except test loading)
- Minimal memory footprint

## License

Same license as the main project (CC4-BY-NC-SA)

## Further Reading

- [PICO-8 Manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html)
- [Lua Testing Best Practices](https://www.lua.org/manual/5.4/)
- [Test-Driven Development in Games](https://gameprogrammingpatterns.com/contents.html)
