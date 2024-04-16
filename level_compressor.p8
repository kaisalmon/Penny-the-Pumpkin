pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include levels.p8

function whoami(val)
    for k,v in pairs(_ENV) do
        if v==val then
            return k
        end
    end
end

function block_to_string(block)
    local str=""
    for k,v in pairs(block) do
        str..=k
        str..=":"
        if type(v) == "function" or type(v) == "table" then
            v = whoami(v)
        end
        if v == true then
            v="true"
        end
        if v == false then
            v="false"
        end
        if v == nil then
            v="nil"
        end
        str..=v
        str..=","
    end
    str = sub(str, 0, #str-1)
    return str
end

function level_to_string(level)
    local str=""
    for block in all(level) do
        str..=block_to_string(block)
        str..="|"
    end
    str = sub(str, 0, #str-1)
    return str
end

printh("", "deleteme.txt", true)
for level in all(levels) do 
    printh(level_to_string(level), "deleteme.txt")
end
-- local x = string_to_block("1:0,2:0,3:0,4:25.5,5:0,6:0,update:level8_adj,draw:level8_light", {})
-- x = block_to_string(x)
-- x = string_to_block(x)
-- x = block_to_string(x)
-- printh(x,"deleteme.txt",false)

-- local x = "1:0,2:0,3:0,4:25.5,5:0,6:0,update:level8_adj,draw:level8_light|1:32,2:12,3:16,4:1,5:0,6:8,colide:false,rx:2,ry:5|1:15,2:9,3:4,4:3,5:15,6:9,colide:false|1:0,2:3,3:32,4:16,5:0,6:0,update:level1_adj|1:27,2:0,3:2,4:2,5:1,6:12,key:level1,on_crash:crash_breakable"
-- x = string_to_level({}, x)
-- x = level_to_string(x)
-- x = string_to_level({}, x)
-- x[1].draw()
-- print(level_to_string(x))
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
