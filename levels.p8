pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--levels
local chunk_size=6
crash_breakable =  function(b)
	b[3]=0
	if b.key then
		add(broken_blocks, b.key)
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
	{
			rx=2,
			colide=false,
			"32,5,16,9,0,0",
	},
	{
			rx=2,ry=5,
			colide=false,
			"32,12,16,1,0,8"
	},
	{
		colide=false,
		"15,9,4,3,15,9"
	},
	{
			"0,3,32,16,0,0",
			update=level1_adj
	},
	{"27,0,2,2,1,12",on_crash=crash_breakable, key="level1"},
}

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
	{
			fill=3,
			colide=false,
			"6,5,48,3,0,-3",
			update=function()
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
	},
	{"115,18,6,1,35,16",colide=false},
	{
			rx=4,
			colide=false,
			"32,5,16,9,-0.5,0"
	},
	{
			rx=4,ry=9,
			colide=false,
			"32,12,16,1,-0.5,8"
	},
	{
		tile=true,
		colide=false,
		"18,0,48,3,0,16"
	},
	{
		fill=4,
		colide=false,
		"18,0,48,13,0,19"
	},
		"48,3,16,16,0,0",
		"32,14,5,4,6,6",
		"64,3,48,16,0,16",
		"112,3,16,16,32,0",
	{
			front=true,
			"0,60,10,4,25,12"
	},
	{
			front=true,
			colide=false,
			"1,63,1,1,16.5,15"
	},
	{
			front=true,
			colide=false,
			"106,3,4,4,0,28"
	},
	{
			colide=false,
			rx=3,ry=3,
			front=true,
			"31,18,1,1,31,14"
	},
	"25,8,3,5,21,11",
	"21,11,1,2,20,14",
	{27,0,2,2,7,28,on_crash=crash_breakable, key="level2"},
}

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
	{"0,0,0,0,0,0", draw=function ()
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
	end},
	{
		"32,1,3,1,30,10",
		update=drop
	},
	{
		"32,1,3,1,36,8",
		update=drop
	},
	{
		"0,3,58,16,0,0",
		update=function()		
			if fc%10==0 then
				for x=0,128 do
					for y=3,19 do
						if(mget(x,y)==62)then mset(x,y,30)
						elseif(mget(x,y)==46)then mset(x,y,62)
						elseif(mget(x,y)==30)then mset(x,y,46)
						end
					end
				end
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
	},
	{
		"32,1,3,1,60,5",
		update=drop
	},
	{
		"32,1,3,1,67.5,3",
		update=drop
	},
		"27,13,16,6,58,5",
	"58,3,50,16,74,0",
	{"0,0,0,0,0,0", front=true, draw=function()
		draw_dark_halo(max(50, lerp(50, 100, (player.x-750)/250)))
	end}
}

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
	{
		"35,0,6,3,4,5",
		rx=7,
		colide=false,
		update=function()
			if player.y>264 then
				load_level(level3, 971, 0, 0, 0)
			elseif player.x < -3 then
				load_level(level6,120,player.y-25)
			elseif player.x > 388 then
				load_level(level5, 0, player.y < 30 and 0 or 64)		
			end
		end
	},
	{
		"35,0,44,14,4,8",
		colide=false,
		fill=6
	},
	{"85,7,3,6,25,20",rx=2},
	"0,3,48,16,0,0",
	"48,3,48,16,0,16",
	{
		"40,6,4,7,41,12",
		front=true
	},
	{
		"56,2,4,1,37,16",
		front=true
	},
	{"27,0,2,2,38,25",on_crash=crash_breakable,front=true, key="level4"},
}

level5={
	chunk=3+chunk_size*2,
	pal=day,
	e={
		{x=15,y=11,miny=20, maxy=100, minx=80, maxx=290},
		{x=24,y=9,miny=20,  maxy=100, minx=80, maxx=290},
		{x=33,y=11,miny=20,  maxy=100, minx=80, maxx=290}
	},
	c={
		{x=40,y=13,id=10},
	},
	{
		"35,0,6,3,4,5",
		rx=7,
		colide=false,
	},
	{
		"35,0,48,8,0,8",
		fill=6,
		colide=false,
	},
	{
		update=drop,
		"111,9,6,5,11,11"
	},	
	{
		update=drop,
		"111,14,7,5,20,7"
	},	
	{
		update=drop,
		"41,0,3,3,16,5"
	},
	"96,3,15,16,0,0",
	{"100,16,11,3,15,13",rx=3},
	{"6,0,3,3,38,13", update=function()
		cam_x=max(0,cam_x-1)
		if player.x < 0 then
			load_level(
				level4,
				385,
				player.y > 35 and 70 or 0
			)
		end
	end},
	"118,3,4,16,44,0"
}

level6 = {
	pal=forest_pal,
	chunk=3+chunk_size*3,
	e={
		{x=62/8,y=87/8, maxy=0,minx=55, maxx=65}
	},
	c={
		{x=62/8,y=5, id=11}
	},
	{
		"16,16,16,16,0,-8",
		fill=14,
		colide=false,
	},
	{
		"16,15,16,5,0,-3",
		colide=false,
		fill=6
	},
	"48,16,16,3,0,-6",
	"16,15,14,4,1,-2",
	{
		"16,15,14,4,1,2",
		colide=false,
		fill=3
	},
	"37,12,4,7,6,-8",
	{
		"0,3,16,16,0,0",
		update=function()
			if player.x < -2 then 
				if player.y<15 then
					load_level(level7, 295, 5)
				else
					load_level(level2, 380, 32)
				end
			elseif player.x > 130 then
				load_level(level4, 16, player.y+15)	
			end	
		end
	},
}

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
	{
		"16,15,37,5,0,-3",
		colide=false,
		fill=6,
		update=function()
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
	},
	{
		"16,15,37,4,0,2",
		colide=false,
		fill=3
	},
	{"48,16,16,3,-11,-6", rx=3},
	{"16,15,21,4,-26,-2", rx=3},
	{"16,13,21,2,-26,4", rx=3},
	"41,11,7,8,3,-2",
	{"37,12,4,7,15,-4",update=function(b)
		b[6]=sin(time()/2)-4
	end},
	"29,5,6,5,14,-6",
	{"37,12,4,7,25,-5",update=function(b)
		b[6]=sin(time()/3)-5
	end},
	"16,5,6,5,24,-7",
	"24,5,5,6,32,0",
}
function draw_light(x,y,c,r)
	ovalfill(x-r,y-r,x+r,y+r,c)
	fillp(▒)
	r+=15
	ovalfill(x-r,y-r,x+r,y+r,c)
	fillp(0)
end
function draw_dark_halo(half_radius)
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
level8={
	px=17,
	py=17,
	pal=spooky_pal,
	c={
		{x=16,y=2.5,id=14},
	},
	chunk=32+chunk_size*0,
	{"0,0,0,25.5,0,0", draw=function ()
		rectfill(0,0,256,256,0)
		rectfill(0,192,256,256,5)
		rectfill(0,128,16,160,5)
		rectfill(216,0,240,128,5)
		draw_light(128,0,1,30)
		draw_light(24,0,1,30)
	end, update=function()
		if player.x > 245 then
			load_level(level3,35,87)
		elseif player.y < -4 and player.x < 100 then
			load_level(level9,138,230,-2,-7)
		end
		
		if player.x < 16 then
			player.x=16
		end
	end},
	"0,3,28,16,0,0",
	"28,3,27,8,2,16",
	{"27,0,2,2,20,20",on_crash=crash_breakable, key="level8"},
	{"0,0,0,0,0,0", draw=function()
		draw_dark_halo(lerp(100,25,player.y/250))
	end}
}
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
	{"0,0,0,0,0,0",draw=function()
		rectfill(0,-40,159,0,3)
		rectfill(0,112,184,224,4)
	end},
	{"55,3,11,16,0,0", update=function()
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
		-- cam_x+=1
		-- cam_x=min(cam_bounds[2], cam_x)
		cam_y-=3.5
		cam_y=max(cam_bounds[3], cam_y)
	end},
	"66,3,12,16,11,-2",
	"55,3,1,4,0,-4",
	"44,15,3,4,9,5",
	"31,17,3,2,20,-4",
	"62,3,2,4,7,-4",
	"31,11,5,1,16,9",
	"31,12,5,1,11.5,10",
	"31,13,5,1,6.5,8",
	"31,14,5,1,1,11",
	"43,11,12,2,11,14",
	"78,3,23,14,0,14",
	"47,17,3,2,3,-2",
}
local stars = {}
for i=0,45 do
	add(stars,{rnd(150)-30,-50-rnd(105),0})
end
level1_variant={
	px=20,
	py=100,
	pal=spooky_pal,
	chunk=3+chunk_size*0,
	c={
		{x=17,y=2.75,id=1}
	},
	{"41,0,3,3,10,-18",  draw=function()
		-- Draw stars
		for i=1,#stars do
			pset(stars[i][1],stars[i][2],7)
			if stars[i][3]>0 then spr(235,stars[i][1]-3,stars[i][2]-3); stars[i][3]-=1 end
			if rnd() < 0.005 then stars[i][3]=20 end
		end
		ovalfill(60,-130,90,-100,7)
		ovalfill(70,-127,90,-107,1)
	end,
	update=function()
		if player.y < -15 then 
			cam_y-=4
		end
	end
	},
	{"51,0,5,3,-4,-7", colide=false, rx=9},
	{"51,0,36,4,-4,-4", colide=false,fill=3},
	"0,3,1,3,0,-3",
	{"9,0,5,19,-5,-3", colide=false,fill=5},
	{"9,0,5,3,-4,-6", tile=true},
	{"46,0,5,1,-4,-7", colide=false},
}
for b in all(level1) do
	add(level1_variant, b)
end

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
function preload(t)
	local new={}
	if type(t) == "table" then
		for i, v in pairs(t) do new[i] = v end
		split_str = split(t[1])
		for i, v in pairs(split_str) do new[i] = v end
	else
		new= split(t)
	end

	return new
end
