--[[
  Example Test File

  This file demonstrates how to write tests for Penny the Pumpkin.
  Use this as a template for creating new test files.
]]--

local test = require("tests/test_framework")
local mock = require("tests/pico8_mock")

-- Example game function to test
local function calculate_damage(fall_distance)
  if fall_distance > 120 then
    return 100  -- Fatal
  elseif fall_distance > 60 then
    return 50   -- Heavy damage
  elseif fall_distance > 30 then
    return 25   -- Light damage
  else
    return 0    -- No damage
  end
end

-- Example player state function
local function create_player(x, y)
  return {
    x = x,
    y = y,
    dx = 0,
    dy = 0,
    w = 8,
    h = {
      x = x,
      y = y - 14,
      dx = 0,
      dy = 0,
      w = 8
    },
    gnded = false,
    last_gnded = nil
  }
end

-- Test suite
test.describe("Example: Damage Calculation", function()
  test.it("should deal no damage for short falls", function()
    local damage = calculate_damage(20)
    test.assert.equal(damage, 0, "Short falls should not cause damage")
  end)

  test.it("should deal light damage for medium falls", function()
    local damage = calculate_damage(45)
    test.assert.equal(damage, 25, "Medium falls should cause light damage")
  end)

  test.it("should deal heavy damage for long falls", function()
    local damage = calculate_damage(80)
    test.assert.equal(damage, 50, "Long falls should cause heavy damage")
  end)

  test.it("should deal fatal damage for very long falls", function()
    local damage = calculate_damage(150)
    test.assert.equal(damage, 100, "Very long falls should be fatal")
  end)

  test.it("should handle boundary conditions", function()
    test.assert.equal(calculate_damage(30), 0, "Exactly 30 should be no damage")
    test.assert.equal(calculate_damage(31), 25, "Just over 30 should be light damage")
    test.assert.equal(calculate_damage(60), 25, "Exactly 60 should be light damage")
    test.assert.equal(calculate_damage(61), 50, "Just over 60 should be heavy damage")
    test.assert.equal(calculate_damage(120), 50, "Exactly 120 should be heavy damage")
    test.assert.equal(calculate_damage(121), 100, "Just over 120 should be fatal")
  end)
end)

test.describe("Example: Player Creation", function()
  local player

  test.before_each(function()
    mock.reset()
    player = create_player(100, 200)
  end)

  test.it("should create player at specified position", function()
    test.assert.equal(player.x, 100)
    test.assert.equal(player.y, 200)
  end)

  test.it("should create head above body", function()
    test.assert.equal(player.h.x, 100)
    test.assert.equal(player.h.y, 186)  -- 200 - 14
  end)

  test.it("should initialize with zero velocity", function()
    test.assert.equal(player.dx, 0)
    test.assert.equal(player.dy, 0)
    test.assert.equal(player.h.dx, 0)
    test.assert.equal(player.h.dy, 0)
  end)

  test.it("should initialize as not grounded", function()
    test.assert.is_false(player.gnded)
  end)

  test.it("should have matching width for body and head", function()
    test.assert.equal(player.w, player.h.w)
  end)

  test.after_each(function()
    player = nil
  end)
end)

test.describe("Example: Mock Usage", function()
  test.before_each(function()
    mock.reset()
  end)

  test.it("should simulate time progression", function()
    test.assert.equal(time(), 0)
    mock.set_time(5.5)
    test.assert.equal(time(), 5.5)
    mock.advance_time(2)
    test.assert.equal(time(), 7.5)
  end)

  test.it("should simulate button presses", function()
    test.assert.is_false(btn(4))  -- Jump button not pressed
    mock.set_button(4, true)
    test.assert.is_true(btn(4))   -- Jump button pressed
    mock.reset_buttons()
    test.assert.is_false(btn(4))  -- Jump button released
  end)

  test.it("should simulate map tiles", function()
    test.assert.equal(mget(5, 5), 0)  -- Empty tile
    mock.set_tile(5, 5, 62)
    test.assert.equal(mget(5, 5), 62) -- Tile placed
  end)

  test.it("should simulate cartridge data", function()
    test.assert.equal(dget(10), 0)    -- No data
    dset(10, 42)
    test.assert.equal(dget(10), 42)   -- Data saved
    mock.clear_cartdata()
    test.assert.equal(dget(10), 0)    -- Data cleared
  end)
end)

test.describe("Example: Advanced Assertions", function()
  test.it("should use approximately for floating point", function()
    local result = 1.0 / 3.0
    test.assert.approximately(result, 0.333, 0.001)
  end)

  test.it("should compare tables", function()
    local table1 = {a = 1, b = 2, c = 3}
    local table2 = {a = 1, b = 2, c = 3}
    test.assert.table_equal(table1, table2)
  end)

  test.it("should test for errors", function()
    local function divide_by_zero()
      return 10 / 0
    end
    -- Note: Lua allows division by zero (returns inf), so this is just an example
    -- For actual error testing, use a function that calls error()
    local function throw_error()
      error("Something went wrong!")
    end
    test.assert.throws(throw_error, "went wrong")
  end)

  test.it("should test nil values", function()
    local value = nil
    test.assert.is_nil(value)

    value = 42
    test.assert.is_not_nil(value)
  end)

  test.it("should compare magnitudes", function()
    local score = 100
    test.assert.greater_than(score, 50)
    test.assert.less_than(score, 200)
  end)
end)
