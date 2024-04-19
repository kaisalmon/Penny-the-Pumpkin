pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--levels
local chunk_size=6
crash_breakable =  function(b)
	b[3]=0
	if b.key then
		broken_blocks[b.key] = true
	end
	for i = 0,15 do
		add_dust({x=player.x,y=player.y-16,w=player.w},0,0,true,55,"coin")
	end
	local x = -5
	player.dy=x
	player.h.dy=x
	sfx(7)
end
drop = function(b)
	b.oy=b.oy or b[6]
	b.ow=b.ow or b[3]
 b.t=b.t or 0
	
	b[3] = b.t < 0 and time() % 0.3 > 0.15 and 0 or b.ow
	b.colide = not (b.t < 0)
	
	if player.block == b or b.t > 0 then
		b.t+=1
		b[5]+=sin(t*10)*.2
	elseif b.t <0 then
		b.t+=1
	end	
	
	if b.t >= 42 then
				b.dy = (b.dy or 0) + 0.02
				b[6] += b.dy
	end
	
	if b[6] - b.oy > 100 then
    b.t, b[6], b.dy = -60, b.oy, 0
	end
end

tunnel=split("0,-16,-4,1,0,5,6,8,-3,-10,12,12,	1,14,15")
spooky_tunnel= split("0,130,131,132,0,5,13,136,137,9,3,12,13,8,4")
forest_pal=split("138,2,3,4,147,6,7,8,9,10,11,12,13,-4,15")
spooky_pal = split("128,130,131,132,133,5,134,136,137,9,3,12,13,8,4")
day=split("-4,2,3,4,5,6,7,8,9,10,11,12,13,14,15")
sea_pal=split("-4,2,3,4,5,6,7,8,9,10,11,12,13,-4,15")

level1_adj = function(b)
    if player.x < -30 then
        load_level(level9, 170, -17)
    end
    if player.y > 135 then
        load_level(level8,128, 0, 0, 3)
    end
    if player.x > 60
    and player.x < 125 then
        hold_thought_t+=1/60
    else
        hold_thought_t=0
    end
    if player.x/8 > b[3]+b[5] then
        load_level(level2, 5, 30)
    end
end
level1={
	px=20,
	py=100,
	pal=forest_pal,
	chunk=3+chunk_size*0,
	c={
		{x=17,y=2.75,id=1}
	},
    blocks="1:32,2:5,3:16,4:9,5:0,6:0,rx:2,colide:false|1:32,2:12,3:16,4:1,5:0,6:8,ry:5,rx:2,colide:false|1:15,2:9,3:4,4:3,5:15,6:9,colide:false|1:0,2:3,3:32,4:16,5:0,6:0,update:level1_adj|1:27,2:0,3:2,4:2,5:1,6:12,on_crash:crash_breakable,key:level1_breakable",
}
level2_adj=function()
    if player.x < 0 and player.y < 100 then
        load_level(level1,31.5*8,6*8)
    elseif player.y > 34*8 then
        if player.x>250 then
            load_level(level3, 156,20)
            player.last_gnded_y="override"
        else
            load_level(level3, 30, -15)
        end
    elseif player.x > 384 then
        load_level(level6, 5, 90)		
    end
end
level2={
	pal=forest_pal,
	chunk=3+chunk_size*0,
	e={
		{x=30,y=25, minx=175, maxx=270},
		{x=22,y=15, minx=133, maxx=222}
	},
	c={
		{x=33,y=17,id=2},
		{x=22.5,y=11,id=3}
	},
	blocks="1:6,2:5,3:48,4:3,5:0,6:-3,update:level2_adj,fill:3,colide:false|1:115,2:18,3:6,4:1,5:35,6:16,colide:false|1:32,2:5,3:16,4:9,5:-0.5,6:0,colide:false,rx:4|1:32,2:12,3:16,4:1,5:-0.5,6:8,rx:4,ry:9,colide:false|1:18,2:0,3:48,4:3,5:0,6:16,colide:false,tile:true|1:18,2:0,3:48,4:13,5:0,6:19,colide:false,fill:4|1:48,2:3,3:16,4:16,5:0,6:0|1:32,2:14,3:5,4:4,5:6,6:6|1:64,2:3,3:48,4:16,5:0,6:16|1:112,2:3,3:16,4:16,5:32,6:0|1:0,2:60,3:10,4:4,5:25,6:12,front:true|1:1,2:63,3:1,4:1,5:16.5,6:15,colide:false,front:true|1:106,2:3,3:4,4:4,5:0,6:28,colide:false,front:true|1:31,2:18,3:1,4:1,5:31,6:14,front:true,rx:3,ry:3,colide:false|1:25,2:8,3:3,4:5,5:21,6:11|1:21,2:11,3:1,4:2,5:20,6:14|1:27,2:0,3:2,4:2,5:7,6:28,on_crash:crash_breakable,key:level2_breakable|1:37,2:14,3:7,4:4,5:28,6:12"
}

level3_draw = function ()
    draw_light(975,-5,4, 45)
    draw_light(975,-5,9, 20)
    rectfill(80,0,104,18,4)
    fillp(▒)
    rectfill(80,0,104,24,4)
    fillp(0)
    rectfill(80,0,104,10,9)
    fillp(▒)
    rectfill(80,0,104,14,9)
    fillp(0)
end
level3_adj = function()		
    if player.x < 850 and player.x > 250 then
        player.y = max(2,player.y)
    end
    if player.x < -10 then
        load_level(level8, 196,183)
    end
    if player.y<0 then
        if player.x < 70 then
            player.x = 16
        elseif player.x < 200 then
            load_level(level2, 100, 260, 0, -3)
        elseif player.x > 900 then
            load_level(level4,90,250, 1, -4)
        end
    end
end
level3_halo = function()
    draw_dark_halo(max(50, lerp(50, 100, (player.x-750)/250)))
end
level3={
	px=16,
	py=-16,
	pal=tunnel,	
	chunk=3+chunk_size,
	c={
		{x=2.5,y=4,id=4},
		{x=45.5,y=10,id=5},
		{x=76.5,y=13,id=6}
	},
	e={
		{x=86.5,y=11, minx=675, maxx=760, maxy=103},
	},
	blocks="1:0,2:0,3:0,4:0,5:0,6:0,draw:level3_draw|1:32,2:1,3:3,4:1,5:30,6:10,update:drop|1:32,2:1,3:3,4:1,5:36,6:8,update:drop|1:0,2:3,3:58,4:16,5:0,6:0,update:level3_adj|1:32,2:1,3:3,4:1,5:60,6:5,update:drop|1:32,2:1,3:3,4:1,5:67.5,6:3,update:drop|1:27,2:13,3:16,4:6,5:58,6:5|1:58,2:3,3:50,4:16,5:74,6:0|1:0,2:0,3:0,4:0,5:0,6:0,draw:level3_halo,front:true"
}

level4_adj = function()
    if player.y>264 then
        load_level(level3, 971, 0, 0, 0)
    elseif player.x < -3 then
        if player.y < 150 then
            load_level(level6,240,player.y-25)
        else
            load_level(level6,195,215)
        end
    elseif player.x > 388 then
        load_level(level5, 0, player.y < 30 and 0 or 64)		
    end
end

level4={
	chunk=3+chunk_size*2,
	pal=day,
	c={
		{x=4, y=23, id=7},
		{x=352/8, y=120/8, id=8},
		{x=27, y=3.5, id=9},
		{x=39, y=27, id=13},
	},
	e={
		{x=352/8, y=120/8, 
		pumpkin=true, 
		minx=317,maxx=370,
		miny=125, maxy=175},
		{x=91/8, y=61/8, 
		pumpkin=true, 
		minx=70,maxx=295,
		miny=60, maxy=110},
		{x=165/8, y=175/8, 
		pumpkin=true, 
		minx=126,maxx=295,
		miny=128, maxy=210}
	},
	blocks="1:35,2:0,3:6,4:3,5:4,6:5,update:level4_adj,rx:7,colide:false|1:35,2:0,3:44,4:14,5:4,6:8,colide:false,fill:6|1:85,2:7,3:3,4:6,5:25,6:20,rx:2|1:0,2:3,3:48,4:16,5:0,6:0|1:48,2:3,3:48,4:16,5:0,6:16|1:40,2:6,3:4,4:7,5:41,6:12,front:true|1:56,2:2,3:4,4:1,5:37,6:16,front:true|1:27,2:0,3:2,4:2,5:38,6:25,on_crash:crash_breakable,key:level4_breakable,front:true|1:48,2:13,3:1,4:3,5:0,6:23,front:true,colide:false"
}

level5_adj = function()
    cam_x=max(0,cam_x-1)
    cam_bounds[2] = 224
    if player.x < 0 then
        load_level(
            level4,
            385,
            player.y > 35 and 70 or 0
        )
    end
end
level5={
	chunk=3+chunk_size*2,
	pal=sea_pal,
	e={
		{x=15,y=11,miny=20, maxy=100, minx=80, maxx=290},
		{x=24,y=9,miny=20,  maxy=100, minx=80, maxx=290},
		{x=33,y=11,miny=20,  maxy=100, minx=80, maxx=290}
	},
	c={
		{x=40,y=13,id=10},
	},
	blocks="1:35,2:0,3:6,4:3,5:4,6:5,colide:false,rx:7|1:35,2:0,3:48,4:8,5:0,6:8,colide:false,fill:6|1:111,2:9,3:6,4:5,5:11,6:11,update:drop|1:111,2:14,3:7,4:5,5:20,6:7,update:drop|1:41,2:0,3:3,4:3,5:16,6:5,update:drop|1:96,2:3,3:15,4:4,5:0,6:0|1:96,2:7,3:15,4:12,5:0,6:4,front:true|1:100,2:16,3:11,4:3,5:15,6:13,rx:3,front:true|1:6,2:0,3:3,4:3,5:38,6:13,update:level5_adj|1:118,2:3,3:4,4:16,5:44,6:0"
}
level6_adj=function()
    if player.x < -2 then 
        if player.y<15 then
            load_level(level7, 295, 5)
        else
            load_level(level2, 380, 32)
        end
    elseif player.x > 258 then
        load_level(level4, 16, player.y+15)	
    end
    if player.y > 125 then
        manual_cam = true
        if(not broken_blocks.level6_breakable)level6.pal=tunnel
        cam_x = lerp(cam_x,73,0.2)
        cam_y = lerp(cam_y,128,0.08)
        if player.x > 205 then
            load_level(level4,8,199)
        elseif player.y > 280 then
            load_level(level3,681,0)
        end
     else
        manual_cam = false
        level6.pal=forest_pal
        cam_bounds[4]=0
     end
end
level6_halo=function()
    if not broken_blocks.level6_breakable and player.y > 125 then
       draw_dark_halo(40)
    end
end
level6_bg=function()
   if broken_blocks.level6_breakable then
       clip(0,128-cam_y,128,128)
       rectfill(0,128,256,256,0)
       draw_light(136,142,5,70)
       draw_light(136,142,4,40)
       clip()
   end
end
level6 = {
	pal=forest_pal,
	chunk=3+chunk_size*3,
	e={
		{x=62/8,y=87/8, maxy=0,minx=55, maxx=65}
	},
	c={
		{x=62/8,y=5, id=11},
		{x=104/8,y=190/8, id=16}
	},
	blocks="1:0,2:0,3:0,4:0,5:0,6:0,draw:level6_bg|1:16,2:16,3:32,4:16,5:0,6:-8,colide:false,fill:14|1:16,2:15,3:32,4:5,5:0,6:-3,colide:false,fill:6|1:48,2:16,3:16,4:3,5:0,6:-6,rx:2|1:16,2:15,3:19,4:4,5:1,6:-2|1:16,2:15,3:32,4:4,5:1,6:2,colide:false,fill:3|1:37,2:12,3:4,4:7,5:9,6:-8|1:80,2:3,3:16,4:16,5:9,6:16|1:64,2:3,3:16,4:16,5:16,6:0|1:96,2:14,3:12,4:5,5:20,6:-5|1:27,2:0,3:2,4:2,5:16,6:14,key:level6_breakable,on_crash:crash_breakable|1:0,2:3,3:16,4:16,5:0,6:0,update:level6_adj|1:0,2:0,3:0,4:0,5:0,6:0,draw:level6_halo,front:true"
}
level7_adj = function()
    if(cam_x < 0)cam_x=0
    if player.x < 75 then
        heart_thought_t+=1/60
    else
        heart_thought_t=0
    end
    if player.y > 100 then
            heart_thought_t=0
            load_level(level2, player.x/255*218, -30)
            player.last_gnded_y="override"
    elseif player.x > 300 then
        load_level(level6, 5, -15)
    elseif player.x < -10 then
        heart_thought_t=0
        load_level(level1, 256, -50, -5, -5)
        player.last_gnded_y="override"
    end
end
level7_sin1 =function(b)
    b[6]=sin(time()/2)-4
end
level7_sin2=function(b)
    b[6]=sin(time()/3)-5
end
level7 = {
	pal=day,
	chunk=3+chunk_size*3,
	e={
		{x=55/8,y=2,size=6, miny=100,minx=35, maxx=60, pumpkin=true},
		{x=65/8,y=2,size=6, miny=100,minx=35, maxx=60, pumpkin=true},		
		{x=45/8,y=2, miny=100,minx=35, maxx=60, pumpkin=true}
	},
	c={
		{x=55/8,y=-3, id=12},
	},
	blocks="1:16,2:15,3:37,4:5,5:0,6:-3,update:level7_adj,fill:6,colide:false|1:16,2:15,3:37,4:4,5:0,6:2,colide:false,fill:3|1:48,2:16,3:16,4:3,5:-11,6:-6,rx:3|1:16,2:15,3:21,4:4,5:-26,6:-2,rx:3|1:16,2:13,3:21,4:2,5:-26,6:4,rx:3|1:41,2:11,3:7,4:8,5:3,6:-2|1:37,2:12,3:4,4:7,5:15,6:-4,update:level7_sin1|1:29,2:5,3:6,4:5,5:14,6:-6|1:37,2:12,3:4,4:7,5:25,6:-5,update:level7_sin2|1:16,2:5,3:6,4:5,5:24,6:-7|1:24,2:5,3:5,4:6,5:32,6:0",
}
function draw_light(x,y,c,r)
	ovalfill(x-r,y-r,x+r,y+r,c)
	fillp(▒)
	r+=15
	ovalfill(x-r,y-r,x+r,y+r,c)
	fillp(0)
end
function draw_dark_halo(half_radius)
    half_radius+=sin(time()/2)*3
	ovalfill(
		player.x-half_radius,
		player.y-half_radius,
		player.x+half_radius,
		player.y+half_radius,0| 0x1800)
	half_radius-=10
	fillp(▒)	
	ovalfill(
		player.x-half_radius,
		player.y-half_radius,
		player.x+half_radius,
		player.y+half_radius,0| 0x1800)
	fillp(0)
end
level8_light = function ()
    rectfill(0,0,256,256,0)
    rectfill(0,192,256,256,5)
    rectfill(0,128,16,160,5)
    rectfill(216,0,240,128,5)
    if(broken_blocks.level1_breakable)draw_light(128,0,1,30)
    draw_light(24,0,1,30)
end
level8_adj = function()
    if player.x > 245 then
        load_level(level3,35,87)
    elseif player.y < -4 and player.x < 100 then
        load_level(level9,138,230,-2,-7)
    end
    
    if player.x < 16 then
        player.x=16
    end
end
level8_halo = function()
    draw_dark_halo(lerp(100,25,player.y/250))
end
level8={
	px=17,
	py=17,
	pal=spooky_pal,
	c={
		{x=16,y=2.5,id=14},
	},
	chunk=32+chunk_size*0,
	blocks="1:0,2:0,3:0,4:25.5,5:0,6:0,update:level8_adj,draw:level8_light|1:0,2:3,3:28,4:16,5:0,6:0|1:28,2:3,3:27,4:8,5:2,6:16|1:27,2:0,3:2,4:2,5:20,6:20,key:level8_breakable,on_crash:crash_breakable|1:0,2:0,3:0,4:0,5:0,6:0,draw:level8_halo,front:true"
}
level9_draw =function()
    rectfill(0,-40,159,0,3)
    rectfill(0,112,184,224,4)
end
level9_adj = function()
    if player.x > 180 then
        load_level(level1_variant,-25,-49)
    elseif player.x < 16 then
        player.x=16
    elseif player.y > 240 then
        load_level(level8,16,-2)
    end
    enemies[1].speed=0.05
    enemies[1].size=14
    enemies[1].minx=player.x-5
    enemies[1].maxx=player.x+5
    enemies[1].miny=player.y-5
    enemies[1].maxy=player.y+5
    cam_y-=3.5
    cam_y=max(cam_bounds[3], cam_y)
end
level9={
	px=17,
	py=17,
	pal=spooky_pal,
	c={
		{x=4.5,y=-2.5,id=15},
	},
	e={
		{x=16,y=16},
	},
	chunk=32+chunk_size*0,
	blocks="1:0,2:0,3:0,4:0,5:0,6:0,draw:level9_draw|1:55,2:3,3:11,4:16,5:0,6:0,update:level9_adj|1:66,2:3,3:12,4:16,5:11,6:-2|1:55,2:3,3:1,4:4,5:0,6:-4|1:44,2:15,3:3,4:4,5:9,6:5|1:31,2:17,3:3,4:2,5:20,6:-4|1:62,2:3,3:2,4:4,5:7,6:-4|1:31,2:11,3:5,4:1,5:16,6:9|1:31,2:12,3:5,4:1,5:11.5,6:10|1:31,2:13,3:5,4:1,5:6.5,6:8|1:31,2:14,3:5,4:1,5:1,6:11|1:43,2:11,3:12,4:2,5:11,6:14|1:78,2:3,3:23,4:14,5:0,6:14|1:47,2:17,3:3,4:2,5:3,6:-2"
}
local stars = {}
for i=0,45 do
	add(stars,{rnd(150)-30,-50-rnd(105),0})
end
level1_v_draw = function()
    -- Draw stars
    for i=1,#stars do
        pset(stars[i][1],stars[i][2],7)
        if stars[i][3]>0 then spr(235,stars[i][1]-3,stars[i][2]-3); stars[i][3]-=1 end
        if rnd() < 0.005 then stars[i][3]=20 end
    end
    ovalfill(60,-130,90,-100,7)
    ovalfill(70,-127,90,-107,1)
end
level1_v_cam = function()
    if player.y < -15 then 
        cam_y-=4
    end
end
level1_variant={
	px=20,
	py=100,
	pal=spooky_pal,
	chunk=3+chunk_size*0,
	c={
		{x=17,y=2.75,id=1}
	},
	blocks="1:41,2:0,3:3,4:3,5:10,6:-18,update:level1_v_cam,draw:level1_v_draw|1:51,2:0,3:5,4:3,5:-4,6:-7,colide:false,rx:9|1:51,2:0,3:36,4:4,5:-4,6:-4,colide:false,fill:3|1:0,2:3,3:1,4:3,5:0,6:-3|1:9,2:0,3:5,4:19,5:-5,6:-3,colide:false,fill:5|1:9,2:0,3:5,4:3,5:-4,6:-6,tile:true|1:46,2:0,3:5,4:1,5:-4,6:-7,colide:false|1:32,2:5,3:16,4:9,5:0,6:0,colide:false,rx:2|1:32,2:12,3:16,4:1,5:0,6:8,rx:2,ry:5,colide:false|1:15,2:9,3:4,4:3,5:15,6:9,colide:false|1:0,2:3,3:32,4:16,5:0,6:0,update:level1_adj|1:27,2:0,3:2,4:2,5:1,6:12,key:level1_breakable,on_crash:crash_breakable"
}

levels={
	level1,
 level2,
 level3,
 level4,
	level5,
	level6,
	level7,
	level8,
	level9,
	level1_variant,
}


function string_to_block(str) 
    local tbl = {}
    local pairs = split(str,",")
    for pair in all(pairs) do
        local kv = split(pair,":")
        local k,v = kv[1], kv[2]
        local lookup = _ENV[v]
        if v == "true" then
            v=true
        elseif v == "false" then
            v=false
        elseif lookup then
            v=lookup
        end
        tbl[k] =v
    end
    return tbl
end
function string_to_level(tbl, str)
    local blocks = split(str, "|")
    for block_str in all(blocks) do
        local block = string_to_block(block_str)
        add(tbl, block)
    end
    return tbl
end

for level in all(levels) do 
    if(level.blocks)string_to_level(level, level.blocks)

end