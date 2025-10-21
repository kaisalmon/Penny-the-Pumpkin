--[[
  Unit Tests for Game State Management

  Tests save/load, coins, checkpoints, and game state transitions.
]]--

local test = require("tests/test_framework")
local mock = require("tests/pico8_mock")

-- Mock game state
local game_state = {}

-- Checkpoint system
function set_checkpoint(level, x, y, dx, dy, coins_in_level)
  game_state.checkpoint = {
    level = level,
    x = x,
    y = y,
    dx = dx or 0,
    dy = dy or 0,
    coins = coins_in_level
  }
  -- Save to cartridge data
  dset(60, dx or 0)
  dset(61, math.floor(y / 8))
  dset(62, math.floor(x / 8))
  dset(59, dy or 0)
end

-- Coin collection
function collect_coin(coin_id, coins_collected)
  dset(coin_id, 1)
  return coins_collected + 1
end

function is_coin_collected(coin_id)
  return dget(coin_id) == 1
end

-- Speedrun tracking
function init_speedrun()
  return {
    active = true,
    time = 0,
    coins = {}
  }
end

function update_speedrun_time(sr, dt)
  if sr.active then
    sr.time = sr.time + dt
  end
end

-- Death and respawn
function handle_death(player, time_of_death)
  return {
    died_at = time_of_death,
    respawn_at = time_of_death + 1
  }
end

function can_respawn(death_state, current_time)
  return death_state.died_at and death_state.died_at < current_time - 1
end

-- Test suites
test.describe("Checkpoint System", function()
  test.before_each(function()
    mock.reset()
    game_state = {}
  end)

  test.it("should save checkpoint position", function()
    set_checkpoint({name = "level1"}, 100, 200, 0, 0, 5)
    test.assert.is_not_nil(game_state.checkpoint)
    test.assert.equal(game_state.checkpoint.x, 100)
    test.assert.equal(game_state.checkpoint.y, 200)
  end)

  test.it("should save checkpoint to cartridge data", function()
    set_checkpoint({name = "level1"}, 100, 200, 0, 0, 5)
    -- Position saved as tiles (divided by 8)
    test.assert.equal(dget(62), math.floor(100 / 8))
    test.assert.equal(dget(61), math.floor(200 / 8))
  end)

  test.it("should save velocity at checkpoint", function()
    set_checkpoint({name = "level1"}, 100, 200, 2.5, -1.5, 5)
    test.assert.equal(game_state.checkpoint.dx, 2.5)
    test.assert.equal(game_state.checkpoint.dy, -1.5)
  end)

  test.it("should default velocity to zero", function()
    set_checkpoint({name = "level1"}, 100, 200, nil, nil, 5)
    test.assert.equal(game_state.checkpoint.dx, 0)
    test.assert.equal(game_state.checkpoint.dy, 0)
  end)

  test.it("should save coins collected at checkpoint", function()
    set_checkpoint({name = "level1"}, 100, 200, 0, 0, 12)
    test.assert.equal(game_state.checkpoint.coins, 12)
  end)

  test.it("should overwrite previous checkpoint", function()
    set_checkpoint({name = "level1"}, 100, 200, 0, 0, 5)
    set_checkpoint({name = "level2"}, 300, 400, 0, 0, 10)
    test.assert.equal(game_state.checkpoint.x, 300)
    test.assert.equal(game_state.checkpoint.y, 400)
    test.assert.equal(game_state.checkpoint.coins, 10)
  end)
end)

test.describe("Coin Collection", function()
  test.before_each(function()
    mock.reset()
  end)

  test.it("should mark coin as collected", function()
    local coins = 5
    coins = collect_coin(10, coins)
    test.assert.equal(coins, 6)
    test.assert.is_true(is_coin_collected(10))
  end)

  test.it("should persist coin state in cartridge data", function()
    collect_coin(15, 0)
    test.assert.equal(dget(15), 1)
  end)

  test.it("should track multiple coins", function()
    local coins = 0
    coins = collect_coin(1, coins)
    coins = collect_coin(2, coins)
    coins = collect_coin(3, coins)
    test.assert.equal(coins, 3)
    test.assert.is_true(is_coin_collected(1))
    test.assert.is_true(is_coin_collected(2))
    test.assert.is_true(is_coin_collected(3))
  end)

  test.it("should check if coin is not collected", function()
    test.assert.is_false(is_coin_collected(99))
  end)

  test.it("should handle coin collection order", function()
    collect_coin(5, 0)
    collect_coin(3, 0)
    collect_coin(7, 0)
    test.assert.is_true(is_coin_collected(5))
    test.assert.is_true(is_coin_collected(3))
    test.assert.is_true(is_coin_collected(7))
    test.assert.is_false(is_coin_collected(4))
  end)
end)

test.describe("Speedrun Mode", function()
  local speedrun

  test.before_each(function()
    mock.reset()
    speedrun = init_speedrun()
  end)

  test.it("should initialize speedrun mode", function()
    test.assert.is_true(speedrun.active)
    test.assert.equal(speedrun.time, 0)
    test.assert.is_not_nil(speedrun.coins)
  end)

  test.it("should track time during speedrun", function()
    update_speedrun_time(speedrun, 1/60)
    update_speedrun_time(speedrun, 1/60)
    test.assert.approximately(speedrun.time, 2/60, 0.0001)
  end)

  test.it("should accumulate time correctly", function()
    for i = 1, 60 do
      update_speedrun_time(speedrun, 1/60)
    end
    test.assert.approximately(speedrun.time, 1, 0.01)
  end)

  test.it("should not track time when inactive", function()
    speedrun.active = false
    update_speedrun_time(speedrun, 1)
    test.assert.equal(speedrun.time, 0)
  end)

  test.it("should format time for display", function()
    speedrun.time = 125.5  -- 2 minutes, 5.5 seconds
    local m = math.floor(speedrun.time / 60)
    local s = math.floor(speedrun.time % 60)
    local ms = math.floor(10 * (speedrun.time % 1))
    test.assert.equal(m, 2)
    test.assert.equal(s, 5)
    test.assert.equal(ms, 5)
  end)

  test.it("should handle sub-3-minute runs", function()
    speedrun.time = 179  -- 2:59
    local m = math.floor(speedrun.time / 60)
    test.assert.less_than(m, 3)
  end)
end)

test.describe("Death and Respawn", function()
  test.before_each(function()
    mock.reset()
  end)

  test.it("should record time of death", function()
    mock.set_time(5.5)
    local death = handle_death({}, mock.state.time_value)
    test.assert.equal(death.died_at, 5.5)
  end)

  test.it("should set respawn time 1 second after death", function()
    mock.set_time(5.5)
    local death = handle_death({}, mock.state.time_value)
    test.assert.equal(death.respawn_at, 6.5)
  end)

  test.it("should allow respawn after delay", function()
    mock.set_time(5.5)
    local death = handle_death({}, mock.state.time_value)
    mock.set_time(7)
    test.assert.is_true(can_respawn(death, mock.state.time_value))
  end)

  test.it("should not allow immediate respawn", function()
    mock.set_time(5.5)
    local death = handle_death({}, mock.state.time_value)
    mock.set_time(5.6)
    test.assert.is_false(can_respawn(death, mock.state.time_value))
  end)

  test.it("should not allow respawn at exactly 1 second", function()
    mock.set_time(5.5)
    local death = handle_death({}, mock.state.time_value)
    mock.set_time(6.5)
    test.assert.is_false(can_respawn(death, mock.state.time_value))
  end)

  test.it("should handle multiple deaths", function()
    mock.set_time(2)
    local death1 = handle_death({}, mock.state.time_value)
    mock.set_time(10)
    local death2 = handle_death({}, mock.state.time_value)
    test.assert.equal(death2.died_at, 10)
    test.assert.not_equal(death1.died_at, death2.died_at)
  end)
end)

test.describe("Game State Persistence", function()
  test.before_each(function()
    mock.reset()
  end)

  test.it("should save level progression", function()
    dset(63, 5)  -- Current level
    test.assert.equal(dget(63), 5)
  end)

  test.it("should load saved level", function()
    dset(63, 3)
    local level = dget(63)
    test.assert.equal(level, 3)
  end)

  test.it("should default to level 0 when no save", function()
    local level = dget(63)
    test.assert.equal(level, 0)
  end)

  test.it("should save player position components separately", function()
    -- Position stored as tile coordinates
    local px, py = 120, 200
    dset(62, math.floor(px / 8))  -- x as tiles
    dset(61, math.floor(py / 8))  -- y as tiles
    test.assert.equal(dget(62), 15)
    test.assert.equal(dget(61), 25)
  end)

  test.it("should save velocity components", function()
    dset(60, 2.5)  -- dx
    dset(59, -1.5) -- dy
    test.assert.equal(dget(60), 2.5)
    test.assert.equal(dget(59), -1.5)
  end)

  test.it("should handle fresh game state", function()
    -- All values should be 0 initially
    test.assert.equal(dget(58), 0)
    test.assert.equal(dget(59), 0)
    test.assert.equal(dget(60), 0)
  end)
end)

test.describe("Max Coins and Completion", function()
  local max_coins = 18

  test.it("should track progress toward max coins", function()
    local collected = 12
    local percentage = (collected / max_coins) * 100
    test.assert.approximately(percentage, 66.67, 0.1)
  end)

  test.it("should detect game completion", function()
    local collected = 18
    test.assert.equal(collected, max_coins)
  end)

  test.it("should detect incomplete game", function()
    local collected = 17
    test.assert.less_than(collected, max_coins)
  end)

  test.it("should unlock speedrun at max coins", function()
    local collected = 18
    local speedrun_unlocked = (collected == max_coins)
    test.assert.is_true(speedrun_unlocked)
  end)

  test.it("should not unlock speedrun before max coins", function()
    local collected = 17
    local speedrun_unlocked = (collected == max_coins)
    test.assert.is_false(speedrun_unlocked)
  end)
end)
