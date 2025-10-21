--[[
  PICO-8 API Mock Functions

  This file provides mock implementations of PICO-8 functions
  to allow testing game logic outside of the PICO-8 runtime.
]]--

local Mock = {}

-- Save original Lua functions that we'll override
local _lua_print = print

-- Global state for mocking
Mock.state = {
  time_value = 0,
  button_states = {},
  map_data = {},
  sprite_flags = {},
  cartdata = {},
  rng_seed = 12345
}

-- Math utilities
function sgn(x)
  return x < 0 and -1 or (x > 0 and 1 or 0)
end

function mid(x, y, z)
  return math.max(x, math.min(y, z))
end

function flr(x)
  return math.floor(x)
end

function ceil(x)
  return math.ceil(x)
end

function cos(x)
  return math.cos((x or 0) * math.pi * 2)
end

function sin(x)
  return -math.sin((x or 0) * math.pi * 2)
end

function atan2(dx, dy)
  return (0.5 + math.atan2(dy, dx) / (math.pi * 2)) % 1.0
end

function abs(x)
  return math.abs(x)
end

function sqrt(x)
  return math.sqrt(x)
end

function min(a, b)
  return math.min(a, b)
end

function max(a, b)
  return math.max(a, b)
end

-- Random number generation
function srand(seed)
  Mock.state.rng_seed = seed or 0
  math.randomseed(seed)
end

function rnd(max)
  max = max or 1
  return math.random() * max
end

-- Time
function time()
  return Mock.state.time_value
end

function Mock.set_time(t)
  Mock.state.time_value = t
end

function Mock.advance_time(dt)
  Mock.state.time_value = Mock.state.time_value + dt
end

-- Button input
function btn(button_id)
  return Mock.state.button_states[button_id] or false
end

function btnp(button_id)
  -- Simplified: returns same as btn for testing
  return btn(button_id)
end

function Mock.set_button(button_id, state)
  Mock.state.button_states[button_id] = state
end

function Mock.reset_buttons()
  Mock.state.button_states = {}
end

-- Table utilities
function add(tbl, item, index)
  if index then
    table.insert(tbl, index, item)
  else
    table.insert(tbl, item)
  end
  return item
end

function del(tbl, item)
  for i, v in ipairs(tbl) do
    if v == item then
      table.remove(tbl, i)
      return item
    end
  end
  return nil
end

function deli(tbl, index)
  return table.remove(tbl, index)
end

function count(tbl)
  return #tbl
end

function all(tbl)
  local i = 0
  local n = #tbl
  return function()
    i = i + 1
    if i <= n then
      return tbl[i]
    end
  end
end

function foreach(tbl, fn)
  for i, v in ipairs(tbl) do
    fn(v)
  end
end

-- Map functions
function mget(x, y)
  local key = x .. "," .. y
  return Mock.state.map_data[key] or 0
end

function mset(x, y, tile)
  local key = x .. "," .. y
  Mock.state.map_data[key] = tile
end

function Mock.set_tile(x, y, tile)
  mset(x, y, tile)
end

function Mock.clear_map()
  Mock.state.map_data = {}
end

-- Sprite flags
function fget(sprite, flag)
  local flags = Mock.state.sprite_flags[sprite] or 0
  if flag ~= nil then
    return ((flags >> flag) & 1) == 1
  end
  return flags
end

function fset(sprite, flag, value)
  local flags = Mock.state.sprite_flags[sprite] or 0
  if value == nil then
    Mock.state.sprite_flags[sprite] = flag
  else
    if value then
      flags = flags | (1 << flag)
    else
      flags = flags & ~(1 << flag)
    end
    Mock.state.sprite_flags[sprite] = flags
  end
end

function Mock.set_sprite_flag(sprite, flag, value)
  fset(sprite, flag, value)
end

-- Cartridge data (persistent storage)
function dget(index)
  return Mock.state.cartdata[index] or 0
end

function dset(index, value)
  Mock.state.cartdata[index] = value
end

function Mock.set_cartdata(index, value)
  dset(index, value)
end

function Mock.clear_cartdata()
  Mock.state.cartdata = {}
end

-- Graphics stubs (don't actually draw, but track calls)
Mock.draw_calls = {}

function camera(x, y)
  table.insert(Mock.draw_calls, {type = "camera", x = x, y = y})
end

function clip(x, y, w, h)
  table.insert(Mock.draw_calls, {type = "clip", x = x, y = y, w = w, h = h})
end

function rectfill(x0, y0, x1, y1, col)
  table.insert(Mock.draw_calls, {type = "rectfill", x0 = x0, y0 = y0, x1 = x1, y1 = y1, col = col})
end

function circfill(x, y, r, col)
  table.insert(Mock.draw_calls, {type = "circfill", x = x, y = y, r = r, col = col})
end

function ovalfill(x0, y0, x1, y1, col)
  table.insert(Mock.draw_calls, {type = "ovalfill", x0 = x0, y0 = y0, x1 = x1, y1 = y1, col = col})
end

function spr(n, x, y, w, h, flip_x, flip_y)
  table.insert(Mock.draw_calls, {type = "spr", n = n, x = x, y = y, w = w, h = h, flip_x = flip_x, flip_y = flip_y})
end

function sspr(sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y)
  table.insert(Mock.draw_calls, {type = "sspr", sx = sx, sy = sy, sw = sw, sh = sh, dx = dx, dy = dy, dw = dw, dh = dh, flip_x = flip_x, flip_y = flip_y})
end

-- Note: We use a local reference instead of overriding global print()
-- to avoid breaking Lua's require() mechanism
function _pico8_print(text, x, y, col)
  table.insert(Mock.draw_calls, {type = "print", text = text, x = x, y = y, col = col})
end

-- Provide pico8 print as a mock function, not as global override
Mock.pico8_print = _pico8_print

function pset(x, y, col)
  table.insert(Mock.draw_calls, {type = "pset", x = x, y = y, col = col})
end

function cls(col)
  table.insert(Mock.draw_calls, {type = "cls", col = col})
end

function pal(c0, c1, p)
  table.insert(Mock.draw_calls, {type = "pal", c0 = c0, c1 = c1, p = p})
end

function palt(c, t)
  table.insert(Mock.draw_calls, {type = "palt", c = c, t = t})
end

function fillp(pattern)
  table.insert(Mock.draw_calls, {type = "fillp", pattern = pattern})
end

function Mock.clear_draw_calls()
  Mock.draw_calls = {}
end

function Mock.get_draw_calls()
  return Mock.draw_calls
end

-- Audio stubs
Mock.audio_calls = {}

function sfx(n, channel, offset, length)
  table.insert(Mock.audio_calls, {type = "sfx", n = n, channel = channel, offset = offset, length = length})
end

function music(pattern, fade_len, channel_mask)
  table.insert(Mock.audio_calls, {type = "music", pattern = pattern, fade_len = fade_len, channel_mask = channel_mask})
end

function Mock.clear_audio_calls()
  Mock.audio_calls = {}
end

function Mock.get_audio_calls()
  return Mock.audio_calls
end

-- System stats
function stat(id)
  if id == 1 then
    -- CPU usage (mock)
    return 0.5
  elseif id == 7 then
    -- FPS (mock)
    return 60
  end
  return 0
end

-- Misc
function cartdata(id)
  -- Mock cart data loading
  return true
end

-- Reset all mock state
function Mock.reset()
  Mock.state = {
    time_value = 0,
    button_states = {},
    map_data = {},
    sprite_flags = {},
    cartdata = {},
    rng_seed = 12345
  }
  Mock.draw_calls = {}
  Mock.audio_calls = {}
  srand(12345)
end

return Mock
