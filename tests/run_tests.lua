#!/usr/bin/env lua
--[[
  Test Runner for Penny the Pumpkin

  This script runs all test suites and reports results.

  Usage:
    lua tests/run_tests.lua
    or
    chmod +x tests/run_tests.lua && ./tests/run_tests.lua
]]--

-- Add tests directory to package path
package.path = package.path .. ";./?.lua;./?/init.lua"

-- Load test framework
local test = require("tests/test_framework")

-- Load mock PICO-8 environment
require("tests/pico8_mock")

print("\nLoading test suites...")

-- Load all test files
local test_files = {
  "tests/test_utilities",
  "tests/test_physics",
  "tests/test_game_state",
  "tests/test_example"  -- Example tests showing how to write tests
}

for _, test_file in ipairs(test_files) do
  local status, err = pcall(require, test_file)
  if not status then
    print("Error loading " .. test_file .. ": " .. tostring(err))
    os.exit(1)
  end
end

-- Run all tests
test.run()
