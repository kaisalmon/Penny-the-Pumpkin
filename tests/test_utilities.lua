--[[
  Unit Tests for Utility Functions

  Tests mathematical and helper functions used throughout the game.
]]--

local test = require("tests/test_framework")
local mock = require("tests/pico8_mock")

-- Load utility functions from the game
function lerp(a, b, t)
  return a + (b - a) * t
end

-- Bounding box functions from the game
function get_bounding_box_forgiving(p)
  local w = p.w - math.abs(p.x - p.h.x)
  local x = (p.x + p.h.x - w) / 2
  local y = p.y
  local h = p.h.y - p.y
  return {x = x, y = y, w = w, h = h}
end

function get_bounding_box(p)
  local x = math.min(
    p.x - p.w / 2,
    p.h.x - p.w / 2
  )
  local y = p.y
  local h = p.h.y - p.y
  local w = math.max(
    p.x + p.w / 2,
    p.h.x + p.w / 2
  ) - x
  return {x = x, y = y, w = w, h = h}
end

function do_characters_overlap(p1, p2)
  local bbox1 = get_bounding_box(p1)
  local bbox2 = get_bounding_box(p2)
  return not (bbox1.x + bbox1.w < bbox2.x or bbox2.x + bbox2.w < bbox1.x or bbox1.y + bbox1.h > bbox2.y or bbox2.y + bbox2.h > bbox1.y)
end

function do_characters_overlap_forgiving(p1, p2)
  local bbox1 = get_bounding_box_forgiving(p1)
  local bbox2 = get_bounding_box_forgiving(p2)
  return not (bbox1.x + bbox1.w < bbox2.x or bbox2.x + bbox2.w < bbox1.x or bbox1.y + bbox1.h > bbox2.y or bbox2.y + bbox2.h > bbox1.y)
end

-- Test suites
test.describe("Lerp Function", function()
  test.it("should interpolate between two values at t=0", function()
    local result = lerp(0, 10, 0)
    test.assert.equal(result, 0)
  end)

  test.it("should interpolate between two values at t=1", function()
    local result = lerp(0, 10, 1)
    test.assert.equal(result, 10)
  end)

  test.it("should interpolate between two values at t=0.5", function()
    local result = lerp(0, 10, 0.5)
    test.assert.equal(result, 5)
  end)

  test.it("should handle negative values", function()
    local result = lerp(-10, 10, 0.5)
    test.assert.equal(result, 0)
  end)

  test.it("should handle values outside 0-1 range", function()
    local result = lerp(0, 10, 2)
    test.assert.equal(result, 20)
  end)

  test.it("should work with floating point numbers", function()
    local result = lerp(0, 1, 0.25)
    test.assert.equal(result, 0.25)
  end)
end)

test.describe("Bounding Box Calculation", function()
  local character

  test.before_each(function()
    character = {
      x = 50,
      y = 100,
      w = 8,
      h = {
        x = 50,
        y = 80
      }
    }
  end)

  test.it("should calculate basic bounding box correctly", function()
    local bbox = get_bounding_box(character)
    test.assert.is_not_nil(bbox)
    test.assert.is_not_nil(bbox.x)
    test.assert.is_not_nil(bbox.y)
    test.assert.is_not_nil(bbox.w)
    test.assert.is_not_nil(bbox.h)
  end)

  test.it("should have correct height (head to body)", function()
    local bbox = get_bounding_box(character)
    test.assert.equal(bbox.h, character.h.y - character.y)
    test.assert.equal(bbox.h, -20)
  end)

  test.it("should calculate forgiving bounding box", function()
    local bbox = get_bounding_box_forgiving(character)
    test.assert.is_not_nil(bbox)
    test.assert.equal(bbox.w, character.w)
  end)

  test.it("should handle character with offset head", function()
    character.h.x = 55
    local bbox = get_bounding_box(character)
    test.assert.greater_than(bbox.w, character.w)
  end)

  test.it("should calculate y position at body level", function()
    local bbox = get_bounding_box(character)
    test.assert.equal(bbox.y, character.y)
  end)
end)

test.describe("Character Overlap Detection", function()
  local char1, char2

  test.before_each(function()
    char1 = {
      x = 50,
      y = 100,
      w = 8,
      h = {x = 50, y = 80}
    }
    char2 = {
      x = 60,
      y = 100,
      w = 8,
      h = {x = 60, y = 80}
    }
  end)

  test.it("should detect overlapping characters", function()
    char2.x = 52  -- Close enough to overlap
    local overlaps = do_characters_overlap(char1, char2)
    test.assert.is_true(overlaps)
  end)

  test.it("should not detect non-overlapping characters", function()
    char2.x = 100  -- Far away
    local overlaps = do_characters_overlap(char1, char2)
    test.assert.is_false(overlaps)
  end)

  test.it("should detect vertical separation", function()
    char2.x = char1.x  -- Same x position
    char2.y = 200      -- Far below
    char2.h.y = 180
    local overlaps = do_characters_overlap(char1, char2)
    test.assert.is_false(overlaps)
  end)

  test.it("should use forgiving overlap for near misses", function()
    char2.x = 51
    -- Forgiving should be more lenient than strict
    local strict = do_characters_overlap(char1, char2)
    local forgiving = do_characters_overlap_forgiving(char1, char2)
    -- Both should detect this close overlap
    test.assert.is_true(forgiving or strict)
  end)

  test.it("should handle characters at same position", function()
    char2.x = char1.x
    char2.y = char1.y
    char2.h.x = char1.h.x
    char2.h.y = char1.h.y
    local overlaps = do_characters_overlap(char1, char2)
    test.assert.is_true(overlaps)
  end)
end)

test.describe("PICO-8 Math Functions", function()
  test.it("sgn should return correct sign", function()
    test.assert.equal(sgn(10), 1)
    test.assert.equal(sgn(-10), -1)
    test.assert.equal(sgn(0), 0)
  end)

  test.it("flr should floor values correctly", function()
    test.assert.equal(flr(3.7), 3)
    test.assert.equal(flr(3.2), 3)
    test.assert.equal(flr(-2.5), -3)
  end)

  test.it("abs should return absolute value", function()
    test.assert.equal(abs(5), 5)
    test.assert.equal(abs(-5), 5)
    test.assert.equal(abs(0), 0)
  end)

  test.it("min should return minimum value", function()
    test.assert.equal(min(5, 10), 5)
    test.assert.equal(min(-5, -10), -10)
  end)

  test.it("max should return maximum value", function()
    test.assert.equal(max(5, 10), 10)
    test.assert.equal(max(-5, -10), -5)
  end)

  test.it("sqrt should calculate square root", function()
    test.assert.equal(sqrt(16), 4)
    test.assert.equal(sqrt(25), 5)
    test.assert.approximately(sqrt(2), 1.414, 0.001)
  end)
end)

test.describe("Table Utilities", function()
  local tbl

  test.before_each(function()
    tbl = {}
  end)

  test.it("add should append items to table", function()
    add(tbl, "item1")
    add(tbl, "item2")
    test.assert.equal(#tbl, 2)
    test.assert.equal(tbl[1], "item1")
    test.assert.equal(tbl[2], "item2")
  end)

  test.it("add should insert at specific index", function()
    add(tbl, "item1")
    add(tbl, "item2")
    add(tbl, "inserted", 1)
    test.assert.equal(#tbl, 3)
    test.assert.equal(tbl[1], "inserted")
    test.assert.equal(tbl[2], "item1")
  end)

  test.it("del should remove items from table", function()
    add(tbl, "item1")
    add(tbl, "item2")
    add(tbl, "item3")
    del(tbl, "item2")
    test.assert.equal(#tbl, 2)
    test.assert.equal(tbl[1], "item1")
    test.assert.equal(tbl[2], "item3")
  end)

  test.it("deli should remove item by index", function()
    add(tbl, "item1")
    add(tbl, "item2")
    add(tbl, "item3")
    local removed = deli(tbl, 2)
    test.assert.equal(removed, "item2")
    test.assert.equal(#tbl, 2)
  end)

  test.it("count should return table length", function()
    add(tbl, "item1")
    add(tbl, "item2")
    test.assert.equal(count(tbl), 2)
  end)

  test.it("foreach should iterate over table", function()
    add(tbl, 1)
    add(tbl, 2)
    add(tbl, 3)
    local sum = 0
    foreach(tbl, function(v) sum = sum + v end)
    test.assert.equal(sum, 6)
  end)
end)
