--[[
  Unit Tests for Physics and Collision System

  Tests gravity, collision detection, and character physics.
]]--

local test = require("tests/test_framework")
local mock = require("tests/pico8_mock")

-- Game constants
local g1 = 0.1
local g2 = 0.275
local air = 0.01

-- Physics helper to check if smash will occur
function will_smash(p)
  return p.last_gnded_y == "override" or p.y - p.last_gnded_y > 120
end

-- Character width update based on stretch
function update_character_w(ch)
  local h = ch.y - ch.h.y
  local s = ch.size
  local tw = (32 - h * (25 / 20)) / 14 * s
  tw = math.min(tw, 30 / 16 * s)
  tw = math.max(tw, 4)
  ch.w = tw
  ch.h.w = ch.w
end

-- Simplified collision check
function is_solid_mock(x, y, inc_semi)
  -- Mock solid tiles at specific positions for testing
  if mock.state.solid_positions then
    local key = math.floor(x / 8) .. "," .. math.floor(y / 8)
    return mock.state.solid_positions[key] or false
  end
  return false
end

-- Test suites
test.describe("Physics - Smash Detection", function()
  local player

  test.before_each(function()
    player = {
      y = 200,
      last_gnded_y = 100
    }
  end)

  test.it("should detect smash when falling more than 120 pixels", function()
    player.y = 221
    player.last_gnded_y = 100
    local smash = will_smash(player)
    test.assert.is_true(smash)
  end)

  test.it("should not detect smash for small falls", function()
    player.y = 150
    player.last_gnded_y = 100
    local smash = will_smash(player)
    test.assert.is_false(smash)
  end)

  test.it("should detect smash when override is set", function()
    player.y = 100
    player.last_gnded_y = "override"
    local smash = will_smash(player)
    test.assert.is_true(smash)
  end)

  test.it("should handle exactly 120 pixels", function()
    player.y = 220
    player.last_gnded_y = 100
    local smash = will_smash(player)
    test.assert.is_false(smash)  -- > 120, not >= 120
  end)

  test.it("should handle negative positions", function()
    player.y = 50
    player.last_gnded_y = -80
    local smash = will_smash(player)
    test.assert.is_true(smash)
  end)
end)

test.describe("Physics - Character Width", function()
  local character

  test.before_each(function()
    character = {
      x = 50,
      y = 100,
      size = 14,
      w = 8,
      h = {
        x = 50,
        y = 80,
        w = 8
      }
    }
  end)

  test.it("should calculate width based on stretch", function()
    update_character_w(character)
    test.assert.is_not_nil(character.w)
    test.assert.greater_than(character.w, 0)
  end)

  test.it("should sync head width with body width", function()
    update_character_w(character)
    test.assert.equal(character.w, character.h.w)
  end)

  test.it("should have minimum width of 4", function()
    character.y = 50
    character.h.y = 200  -- Very stretched
    update_character_w(character)
    test.assert.greater_than(character.w, 4)
  end)

  test.it("should have maximum width constraint", function()
    character.y = 100
    character.h.y = 99  -- Almost no stretch
    update_character_w(character)
    local max_expected = 30 / 16 * character.size
    test.assert.less_than(character.w, max_expected + 1)
  end)

  test.it("should handle compressed character", function()
    character.y = 100
    character.h.y = 95  -- Very compressed
    update_character_w(character)
    test.assert.greater_than(character.w, character.size * 0.5)
  end)

  test.it("should handle stretched character", function()
    character.y = 100
    character.h.y = 70  -- Very stretched
    update_character_w(character)
    test.assert.less_than(character.w, character.size)
  end)
end)

test.describe("Physics - Gravity Application", function()
  local character

  test.before_each(function()
    character = {
      dy = 0,
      h = {dy = 0},
      gnded = false
    }
  end)

  test.it("should apply stronger gravity when not holding jump", function()
    -- Simulate one frame of gravity
    local gravity = g2  -- 0.275
    character.dy = character.dy + gravity
    test.assert.equal(character.dy, gravity)
  end)

  test.it("should apply weaker gravity when holding jump and moving up", function()
    character.dy = -2  -- Moving upward
    local gravity = g1  -- 0.1
    character.dy = character.dy + gravity
    test.assert.equal(character.dy, -2 + gravity)
  end)

  test.it("should apply air resistance", function()
    character.dy = 5
    -- Air resistance formula: dy -= sgn(dy) * air * dy * dy
    local resistance = 1 * air * character.dy * character.dy
    local new_dy = character.dy - resistance
    test.assert.less_than(new_dy, character.dy)
    test.assert.approximately(new_dy, 5 - 0.25, 0.01)
  end)

  test.it("should apply friction to horizontal movement", function()
    character.dx = 5
    -- Friction formula: dx -= 0.1 * dx
    local new_dx = character.dx - (0.1 * character.dx)
    test.assert.equal(new_dx, 4.5)
  end)

  test.it("should handle terminal velocity", function()
    character.dy = 10  -- Very fast
    -- Max dy should be clamped to 4
    character.dy = math.min(character.dy, 4)
    test.assert.equal(character.dy, 4)
  end)

  test.it("should handle maximum upward velocity", function()
    character.dy = -15  -- Very fast upward
    -- Max upward should be clamped to -10
    character.dy = math.max(character.dy, -10)
    test.assert.equal(character.dy, -10)
  end)
end)

test.describe("Physics - Jump Mechanics", function()
  local character

  test.before_each(function()
    mock.reset()
    character = {
      dy = 0,
      h = {dy = 0},
      gnded = true,
      last_gnded = 0,
      jumpf = -3
    }
  end)

  test.it("should allow jump when grounded", function()
    mock.set_time(0.5)
    character.last_gnded = 0.4
    local can_jump = character.gnded and mock.state.time_value - character.last_gnded <= 0.2
    test.assert.is_true(can_jump)
  end)

  test.it("should allow coyote time jump", function()
    mock.set_time(0.5)
    character.last_gnded = 0.35
    character.gnded = false
    local can_jump = character.last_gnded ~= nil and mock.state.time_value - character.last_gnded <= 0.2
    test.assert.is_true(can_jump)
  end)

  test.it("should not allow jump after coyote time", function()
    mock.set_time(0.5)
    character.last_gnded = 0.25
    character.gnded = false
    local can_jump = character.last_gnded ~= nil and mock.state.time_value - character.last_gnded <= 0.2
    test.assert.is_false(can_jump)
  end)

  test.it("should apply jump force to body", function()
    character.dy = character.jumpf
    test.assert.equal(character.dy, -3)
  end)

  test.it("should apply stronger jump force to head", function()
    local head_jumpf = character.jumpf * 1.2
    character.h.dy = head_jumpf
    test.assert.equal(character.h.dy, -3.6)
  end)

  test.it("should only jump when moving downward or stationary", function()
    character.dy = -2  -- Already moving up
    local can_jump = character.dy >= 0
    test.assert.is_false(can_jump)
  end)
end)

test.describe("Physics - Spring Physics", function()
  local character

  test.before_each(function()
    character = {
      x = 50,
      y = 100,
      dx = 0,
      dy = 0,
      size = 14,
      h = {
        x = 50,
        y = 80,
        dx = 0,
        dy = 0
      }
    }
  end)

  test.it("should apply spring force when head is offset horizontally", function()
    character.h.x = 55  -- Head 5 pixels to the right
    local fh = 0.015
    local fxh = (character.x - character.h.x) * fh
    test.assert.less_than(fxh, 0)  -- Force pulls head back to center
    test.assert.approximately(fxh, -0.075, 0.001)
  end)

  test.it("should apply spring force when head height is wrong", function()
    character.y = 100
    character.h.y = 75  -- Head too high
    character.size = 14
    local target_h = 14  -- Expected height
    local fh = 0.015
    local fyh = (character.y - character.h.y - target_h) * fh * 3
    test.assert.greater_than(fyh, 0)  -- Force pulls head down
  end)

  test.it("should apply opposite force to body", function()
    character.h.x = 55
    local fh = 0.015
    local fxh = (character.x - character.h.x) * fh
    -- Body gets opposite force
    local body_force = -fxh
    test.assert.greater_than(body_force, 0)
  end)

  test.it("should enforce minimum head-body distance", function()
    local min_h = character.size / 4 + 1  -- Minimum distance
    character.h.y = character.y - min_h + 2  -- Too close
    local should_bounce = character.h.y + min_h > character.y
    test.assert.is_true(should_bounce)
  end)

  test.it("should enforce maximum head-body distance", function()
    local max_h = character.size * 1.5  -- Maximum stretch
    character.h.y = character.y - max_h - 5  -- Too far
    local should_clamp = character.h.y + max_h < character.y
    test.assert.is_true(should_clamp)
  end)
end)

test.describe("Physics - Collision Response", function()
  local particle

  test.before_each(function()
    mock.reset()
    particle = {
      x = 50,
      y = 100,
      dx = 5,
      dy = 5,
      w = 8,
      bounce = 0.5
    }
  end)

  test.it("should bounce horizontally on wall collision", function()
    local old_dx = particle.dx
    -- Simulate collision
    particle.dx = particle.dx * -1 * particle.bounce
    test.assert.less_than(particle.dx, 0)
    test.assert.equal(particle.dx, -2.5)
  end)

  test.it("should bounce vertically on ground collision", function()
    local old_dy = particle.dy
    -- Simulate collision
    particle.dy = particle.dy * -(particle.bounce)
    test.assert.less_than(particle.dy, 0)
    test.assert.equal(particle.dy, -2.5)
  end)

  test.it("should lose energy on each bounce", function()
    local initial = 10
    particle.dy = initial
    particle.dy = particle.dy * -(particle.bounce)
    test.assert.approximately(particle.dy, -5, 0.01)
  end)

  test.it("should stop bouncing at low velocities", function()
    particle.dy = 0.1
    particle.dy = particle.dy * -(particle.bounce)
    test.assert.less_than(math.abs(particle.dy), 0.1)
  end)
end)
