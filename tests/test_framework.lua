--[[
  Simple Test Framework for Penny the Pumpkin

  This framework provides basic unit testing functionality
  for testing PICO-8 Lua code outside of the PICO-8 runtime.
]]--

local TestFramework = {}
TestFramework.tests = {}
TestFramework.current_suite = nil
TestFramework.stats = {
  passed = 0,
  failed = 0,
  total = 0,
  suites = 0
}

-- Colors for terminal output
local colors = {
  reset = "\27[0m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  cyan = "\27[36m"
}

-- Test suite creation
function TestFramework.describe(name, fn)
  TestFramework.current_suite = {
    name = name,
    tests = {},
    before_each = nil,
    after_each = nil
  }

  fn()

  table.insert(TestFramework.tests, TestFramework.current_suite)
  TestFramework.current_suite = nil
  TestFramework.stats.suites = TestFramework.stats.suites + 1
end

-- Individual test
function TestFramework.it(description, fn)
  if not TestFramework.current_suite then
    error("Test must be inside a describe block")
  end

  table.insert(TestFramework.current_suite.tests, {
    description = description,
    fn = fn
  })
end

-- Setup function to run before each test
function TestFramework.before_each(fn)
  if TestFramework.current_suite then
    TestFramework.current_suite.before_each = fn
  end
end

-- Teardown function to run after each test
function TestFramework.after_each(fn)
  if TestFramework.current_suite then
    TestFramework.current_suite.after_each = fn
  end
end

-- Assertion functions
local Assert = {}

function Assert.equal(actual, expected, message)
  if actual ~= expected then
    error(string.format(
      "%s\n  Expected: %s\n  Actual:   %s",
      message or "Values are not equal",
      tostring(expected),
      tostring(actual)
    ))
  end
end

function Assert.not_equal(actual, expected, message)
  if actual == expected then
    error(string.format(
      "%s\n  Both values are: %s",
      message or "Values should not be equal",
      tostring(actual)
    ))
  end
end

function Assert.is_true(value, message)
  if value ~= true then
    error(message or "Expected true, got " .. tostring(value))
  end
end

function Assert.is_false(value, message)
  if value ~= false then
    error(message or "Expected false, got " .. tostring(value))
  end
end

function Assert.is_nil(value, message)
  if value ~= nil then
    error(message or "Expected nil, got " .. tostring(value))
  end
end

function Assert.is_not_nil(value, message)
  if value == nil then
    error(message or "Expected non-nil value")
  end
end

function Assert.greater_than(actual, expected, message)
  if actual <= expected then
    error(string.format(
      "%s\n  Expected %s > %s",
      message or "Value is not greater",
      tostring(actual),
      tostring(expected)
    ))
  end
end

function Assert.less_than(actual, expected, message)
  if actual >= expected then
    error(string.format(
      "%s\n  Expected %s < %s",
      message or "Value is not less than",
      tostring(actual),
      tostring(expected)
    ))
  end
end

function Assert.approximately(actual, expected, delta, message)
  delta = delta or 0.001
  if math.abs(actual - expected) > delta then
    error(string.format(
      "%s\n  Expected: %s (±%s)\n  Actual:   %s",
      message or "Values are not approximately equal",
      tostring(expected),
      tostring(delta),
      tostring(actual)
    ))
  end
end

function Assert.table_equal(actual, expected, message)
  local function tables_equal(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
      return t1 == t2
    end

    for k, v in pairs(t1) do
      if not tables_equal(v, t2[k]) then
        return false
      end
    end

    for k, v in pairs(t2) do
      if not tables_equal(v, t1[k]) then
        return false
      end
    end

    return true
  end

  if not tables_equal(actual, expected) then
    error(message or "Tables are not equal")
  end
end

function Assert.throws(fn, expected_error, message)
  local success, err = pcall(fn)
  if success then
    error(message or "Expected function to throw an error")
  end
  if expected_error and not string.find(tostring(err), expected_error) then
    error(string.format(
      "%s\n  Expected error containing: %s\n  Actual error: %s",
      message or "Wrong error thrown",
      expected_error,
      tostring(err)
    ))
  end
end

TestFramework.assert = Assert

-- Run all tests
function TestFramework.run()
  print("\n" .. colors.cyan .. "================================" .. colors.reset)
  print(colors.cyan .. "  Running Penny the Pumpkin Tests" .. colors.reset)
  print(colors.cyan .. "================================" .. colors.reset .. "\n")

  for _, suite in ipairs(TestFramework.tests) do
    print(colors.blue .. "Suite: " .. suite.name .. colors.reset)

    for _, test in ipairs(suite.tests) do
      TestFramework.stats.total = TestFramework.stats.total + 1

      -- Run before_each hook
      if suite.before_each then
        suite.before_each()
      end

      -- Run the test
      local success, err = pcall(test.fn)

      -- Run after_each hook
      if suite.after_each then
        suite.after_each()
      end

      -- Report results
      if success then
        TestFramework.stats.passed = TestFramework.stats.passed + 1
        print("  " .. colors.green .. "✓" .. colors.reset .. " " .. test.description)
      else
        TestFramework.stats.failed = TestFramework.stats.failed + 1
        print("  " .. colors.red .. "✗" .. colors.reset .. " " .. test.description)
        print("    " .. colors.red .. tostring(err) .. colors.reset)
      end
    end

    print("")
  end

  -- Print summary
  print(colors.cyan .. "================================" .. colors.reset)
  print(colors.cyan .. "  Test Summary" .. colors.reset)
  print(colors.cyan .. "================================" .. colors.reset)
  print(string.format("Total tests: %d", TestFramework.stats.total))
  print(colors.green .. string.format("Passed: %d", TestFramework.stats.passed) .. colors.reset)

  if TestFramework.stats.failed > 0 then
    print(colors.red .. string.format("Failed: %d", TestFramework.stats.failed) .. colors.reset)
  else
    print(colors.green .. "Failed: 0" .. colors.reset)
  end

  print(colors.cyan .. "================================" .. colors.reset .. "\n")

  -- Exit with appropriate code
  if TestFramework.stats.failed > 0 then
    os.exit(1)
  else
    os.exit(0)
  end
end

return TestFramework
