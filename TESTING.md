# Testing Guide for Penny the Pumpkin

This document provides a comprehensive guide to the unit testing system for Penny the Pumpkin.

## Quick Start

```bash
# Install Lua (if not already installed)
make install-lua  # Ubuntu/Debian
# or: brew install lua  # macOS

# Run all tests
make test

# Or run directly
lua tests/run_tests.lua
```

## What Gets Tested

The test suite provides comprehensive coverage of:

### 1. **Utility Functions** (`tests/test_utilities.lua`)
   - Linear interpolation (lerp)
   - Bounding box calculations for collision detection
   - Character overlap detection (strict and forgiving)
   - PICO-8 math functions
   - Table manipulation utilities

### 2. **Physics System** (`tests/test_physics.lua`)
   - Gravity and air resistance
   - Jump mechanics with coyote time
   - Spring-based character deformation
   - Collision detection and response
   - Bounce physics
   - Terminal velocity
   - Smash detection for fall damage

### 3. **Game State** (`tests/test_game_state.lua`)
   - Checkpoint system
   - Coin collection and persistence
   - Speedrun timer and formatting
   - Death and respawn mechanics
   - Save/load system via cartridge data
   - Progress tracking and completion detection

## Test Architecture

### Framework Components

```
tests/
├── test_framework.lua     # Testing framework (describe, it, assertions)
├── pico8_mock.lua        # PICO-8 API mocks
├── run_tests.lua         # Test runner script
├── test_*.lua            # Individual test suites
└── README.md             # Detailed documentation
```

### Key Features

1. **Isolated Testing**: Each test runs in isolation with `before_each` setup
2. **Mock PICO-8 API**: Tests run without PICO-8 runtime
3. **Rich Assertions**: 11+ assertion types for comprehensive validation
4. **Fast Execution**: All tests complete in < 1 second
5. **CI/CD Ready**: GitHub Actions workflow included

## Writing Tests

### Basic Test Structure

```lua
local test = require("tests/test_framework")
local mock = require("tests/pico8_mock")

test.describe("Feature Name", function()
  -- Runs before each test
  test.before_each(function()
    mock.reset()
  end)

  -- Individual test
  test.it("should do something specific", function()
    local result = my_function(input)
    test.assert.equal(result, expected)
  end)

  -- Runs after each test
  test.after_each(function()
    -- cleanup
  end)
end)
```

### Available Assertions

```lua
-- Equality
test.assert.equal(actual, expected)
test.assert.not_equal(actual, expected)
test.assert.table_equal(table1, table2)

-- Truthiness
test.assert.is_true(value)
test.assert.is_false(value)
test.assert.is_nil(value)
test.assert.is_not_nil(value)

-- Comparison
test.assert.greater_than(actual, expected)
test.assert.less_than(actual, expected)
test.assert.approximately(actual, expected, delta)

-- Errors
test.assert.throws(function, expected_message)
```

### Using Mocks

```lua
-- Time control
mock.set_time(5.0)
mock.advance_time(1.0)
local current = time()  -- Returns 6.0

-- Button input
mock.set_button(4, true)  -- Press jump
local jumping = btn(4)    -- Returns true

-- Map manipulation
mock.set_tile(10, 10, 62)
local tile = mget(10, 10)  -- Returns 62

-- Cartridge data
dset(63, 5)              -- Save level
local level = dget(63)   -- Returns 5

-- Full reset
mock.reset()  -- Clears all state
```

## Test Examples

### Testing Physics

```lua
test.describe("Gravity", function()
  local character

  test.before_each(function()
    character = {dy = 0, h = {dy = 0}}
  end)

  test.it("should apply gravity when airborne", function()
    local g = 0.275
    character.dy = character.dy + g
    test.assert.equal(character.dy, 0.275)
  end)
end)
```

### Testing Game Logic

```lua
test.describe("Coin Collection", function()
  test.it("should increment coin count", function()
    local coins = 5
    coins = collect_coin(10, coins)
    test.assert.equal(coins, 6)
  end)
end)
```

### Testing with Time

```lua
test.describe("Respawn System", function()
  test.it("should respawn after 1 second", function()
    mock.set_time(5.0)
    local death = {died_at = 5.0}
    mock.set_time(6.5)
    local can_respawn = time() > death.died_at + 1
    test.assert.is_true(can_respawn)
  end)
end)
```

## Running Specific Tests

```bash
# All tests
lua tests/run_tests.lua

# Single test file
lua -e "require('tests/pico8_mock'); \
        require('tests/test_physics'); \
        require('tests/test_framework').run()"

# With Makefile
make test
```

## Continuous Integration

The project includes a GitHub Actions workflow (`.github/workflows/test.yml`) that:

1. Installs Lua on Ubuntu
2. Runs all tests
3. Reports results
4. Fails the build if tests fail

Tests run automatically on:
- Push to main or claude/* branches
- Pull requests to main

## Test Coverage Goals

- **Minimum**: 70% code coverage of core logic
- **Target**: 85% code coverage
- **Focus Areas**:
  - All physics calculations
  - All collision detection
  - State management and persistence
  - Game mechanics (jumps, coins, etc.)

## Debugging Failed Tests

When a test fails, you'll see:

```
Suite: Physics System
  ✓ should apply gravity
  ✗ should handle collision
    Expected: 10
    Actual:   5
```

To debug:

1. **Read the error message** - Shows expected vs actual values
2. **Check the test** - Review test logic in `tests/test_*.lua`
3. **Add print statements** - Temporarily add debug output
4. **Run single test** - Isolate the failing test
5. **Check mocks** - Ensure mock state is correct

## Best Practices

### DO:
- ✅ Write tests for all new features
- ✅ Test edge cases and boundary conditions
- ✅ Use descriptive test names
- ✅ Keep tests independent
- ✅ Reset mock state with `mock.reset()`
- ✅ Test both success and failure cases

### DON'T:
- ❌ Test PICO-8 rendering (use mocks)
- ❌ Test audio playback (use mocks)
- ❌ Make tests depend on each other
- ❌ Leave debug prints in committed tests
- ❌ Skip edge case testing
- ❌ Test implementation details

## Performance Testing

For performance-critical code:

```lua
test.it("should execute quickly", function()
  local start_time = os.clock()

  -- Run function many times
  for i = 1, 1000 do
    my_expensive_function()
  end

  local elapsed = os.clock() - start_time
  test.assert.less_than(elapsed, 1.0, "Should complete in < 1s")
end)
```

## Integration with Development

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
echo "Running tests..."
lua tests/run_tests.lua
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Editor Integration

**VS Code** - Add to `.vscode/tasks.json`:
```json
{
  "label": "Run Tests",
  "type": "shell",
  "command": "lua tests/run_tests.lua",
  "problemMatcher": []
}
```

## Troubleshooting

### Common Issues

**"module not found"**
- Run from project root: `cd /path/to/Penny-the-Pumpkin`

**"lua: command not found"**
- Install Lua: `make install-lua` or `brew install lua`

**Tests pass locally but fail in CI**
- Check Lua version consistency
- Verify all files are committed
- Check for platform-specific issues

**Random test failures**
- Ensure `mock.reset()` in `before_each`
- Check for shared state between tests
- Use fixed random seeds if needed

## Further Resources

- See `tests/README.md` for detailed framework documentation
- See `tests/test_example.lua` for comprehensive examples
- PICO-8 Manual: https://www.lexaloffle.com/dl/docs/pico-8_manual.html
- Lua Testing Best Practices: https://www.lua.org/manual/5.4/

## Contributing Tests

When contributing:

1. Add tests for new features
2. Ensure all tests pass
3. Maintain or improve coverage
4. Follow existing test patterns
5. Document complex test logic
6. Update this guide if needed

## License

Tests follow the same CC4-BY-NC-SA license as the main project.
