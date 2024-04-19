pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--penny the pumpkin
title_y=8
label=false

max_coins=16
function init()
t=0
t_scale=1
broken_blocks={}
wipe_progress = -1  -- -1: no transition, 0-128: transition in progress
fc=0
dust={}
moved=false
shake=0
player = {
	on_land=on_land,
	x=0,
	y=0,
	dx=0,
	dy=0,
	w=8,
	bounce=0,
	size=14,
	tsize=14,
	speed=.2,
	h={
		x=0,
		y=0,
		dx=0,
		dy=0,
		w=8,
	},
	last_gnded=0,
	was_gnded=false,
}
jump_btn = nil
jump_btn_down = btn(4) or btn(5)
cam_x = player.x-64
cam_y = player.y-64
died_at=nil
revived_at=nil
local level=dget(63)
load_level_instant(
	levels[level] or level1,
	 (dget(63)!=0 and (dget(62)*8+4) or level1.px),
 	(dget(63)!=0 and (dget(61)*8+4) or level1.py),
  dget(60), dget(59)
  )
hud_y=-25
g1=0.1
g2=0.275
air=0.01
max_jump_height=8*4.1
player.jumpf=-3
player.facing=➡️
speedrun_t=0
hold_thought_t=0
heart_thought_t=0
menuitem(5,"fix softlock",function()
		if speedrun then 
			extcmd("reset")
		else
			load_first_level()
		end
end)
end
function reset_pal()
	pal()
	palt(0,false)
	palt(1,true)
	pal(blocks.pal, 1)
end

function draw_player(x,y)
	skw_spr(
			player.x+(x or 0),
			player.y+(y or 0),
			player.h.x+(x or 0),
			player.h.y-4+(y or 0),
			player.w+4,
			player.size,
			0
		)
end
function will_smash(p)
	return p.last_gnded_y=="override" or p.y - p.last_gnded_y > 120 
end
function _draw()
	local stat_1 = stat(1)
	cls(1)
	reset_pal()

	camera(
		cam_x+(rnd(1)-.5)*shake,
		cam_y+(rnd(1)-.5)*shake
	)
	draw_blocks()	
	local flicker = revived_at and 
		revived_at + 2 > time() and 
		time()%.3>.15
		foreach(enemies, function(e)
		skw_spr(
			e.x,
			e.y,
			e.h.x,
			e.h.y-((blocks == level9 or e.pumpkin) and 4 or 0),
			e.w+4,
			e.size,
			blocks == level9 and 12 or e.pumpkin and 0 or 3
		)
	end)
		
	if died_at == nil and not flicker then 
		if heart_thought_t>1 or hold_thought_t > 4 then
			spr(time()%1.5 > .75 and 229 or 231,player.x-5,player.h.y-20,2,2)
			if hold_thought_t > 4 then
				spr(time()%1 > .5 and 233 or 249,player.x-5,player.h.y-17,2,1)
			elseif heart_thought_t>1 then
					spr(time()%1> .5 and 214 or 215,player.x-2,player.h.y-18)
			end
		end
		
		if will_smash(player) then
			pal({[0]=9,9,9,9,9,9,9,9,9,9,9,9})
			draw_player(0,-8)
			draw_player(0,0)
			pal({[0]=7,7,7,7,7,7,7,7,7,7,7,7})
			draw_player(0,-4)
			draw_player(0,0)
			reset_pal()
		end
		draw_player()

		if is_halloween() then
			skw_spr(
				player.x,
				player.y,
				player.h.x,
				player.h.y-4,
				player.w+4,
				player.size,
				44,
				player.facing==⬅️
			)
		end
	end
	
	foreach(coins, function(c)
		local dw = abs(sin(t)*16)
		sspr(24,0,16,16,c.x-dw/2,c.y-16,dw,16)
	end)
	draw_dust()
	
	draw_blocks(true)	
	camera()
	draw_wipe_transition(wipe_progress)
	local draw_cpu_usage = stat(1) - stat_1

	if debug then
		print(flr(player.x)..","..flr(player.y).." "..tostr(debug),1,1,7)
	end
	
	camera(0,hud_y)
	local hud_h=25
	for i = 0,16 do
		spr(32,i*8,128-hud_h)
	end
	rectfill(0,128+8-hud_h,128,128,0)
	sspr(24,0,16,16,3,109,16,16)

	if coins_collected == max_coins and
	not speedrun 
	and fc % 50 < 25 then		
		print("speedrun unlocked in menu!",22,115,fc % 10 < 5 and 6 or 7)
	else
		print(coins_collected.."/"..max_coins,22,115,6)
		if #coins==0 then
			print("area complete",70,115,6)
		end
	end
	if shake==25 then
		rectfill(0,0,128,128,9)
	end
	camera()
	if speedrun then
		rectfill(99,0,128,6,0)
		local m =flr(speedrun_t/60)
		local s = flr(speedrun_t%60)
		local ms = flr(10*(speedrun_t%1))
		if s < 10 then
			s="0"..s
		end
		if m < 10 then
			m="0"..m
		end
		print(m..":"..s.."."..ms,100,1,7)
	end
	
	local x=30
	--values 0x10 and 0x30 to 0x3f change the effect
-- poke(0x5f5f,0x10)
--new colors on the affected line
-- pal(blocks.pal == tunnel and 
-- split("0,0,0,132,0,0,0,0,137,9,0,0,13,0,0")
--  or split("131,130,131,132,133,5,6,136,137,9,11,12,13,-4,15"),2)
--0x5f70 to 0x5f7f are the 16 sections of the screen
--0xff is the bitfield of which of the 16 line of the section are affected
 pal_memset(0x5f70,0,16)
 local z=flr(title_y)%8
 pal_memset(0x5f70+(title_y)/8-1,255<<z,1)
 pal_memset(0x5f70+(title_y)/8,255,5)
 pal_memset(0x5f70+(title_y)/8+5,~(255<<z),1)
	for i,v in ipairs({
		{x-1,title_y},
		{x+1,title_y},
		{x,title_y+1},
		{x,title_y-1},
		{x+1,title_y+1},
		{x+2,title_y+2},
		{x,title_y}
	}) do
		pal(9,i==7 and 9 or 0)
		pal(4,i==7 and 4 or 0)
		pal(10,i==7 and 10 or 0)
		sspr(40,76,87,27, v[1]-10,v[2]+3)
			if is_halloween() then
				print("happy halloween",x,title_y+15,9)
	else
		if time()%1.5 < .75 then
			print("director's cut",v[1]+24,v[2]+32,9)
		else
			print("by kai salmon",v[1]+24,v[2]+32,9)
		end
	end
	end		

end

local min_mem = 0x5f70
local max_mem = 0x5f70 + 18

function pal_memset(addr, val, len)
    if addr >= min_mem and (addr + len - 1) <= max_mem then
        memset(addr, val, len)
    end
end

function draw_wipe_transition(wipe_progress)
    if(wipe_progress <0)return
    local p = (wipe_progress < 1 and wipe_progress or 2 - wipe_progress)
				p=sqrt(p)
    local half_radius = 128 * (1 - p)
			 local cx = player.x-cam_x
    local cy = (player.y+player.h.y)/2-cam_y

				ovalfill(
				cx-half_radius,
				cy-half_radius,
				cx+half_radius,
				cy+half_radius,0| 0x1800)
end

function _update60()
	profile_cpu_usage=0
	profile_calls=0

	local stat_1 = stat(1)
	t+=1/60
	fc+=1
	
	if btn(0) or btn(1) then
		moved=true
	end
	title_center_y=label and 30 or 50
	if title_y < title_center_y-5 then
		title_y = lerp(title_y, title_center_y,0.02)
	elseif moved then
		title_dy = (title_dy or 0) + 0.2
		title_dy *= 0.95
		title_y = title_y + title_dy
	end
	local thud_y = -25
	if coin_at and coin_at+2>time() then
		thud_y = 0
	end
	if coins_collected == max_coins and
	not speedrun then	
		add_speedrun_option()
		thud_y = 0
	end
	if hud_y > thud_y then
		hud_y -= 1
	elseif hud_y < thud_y then
		hud_y += 1
	end

 if wipe_progress >= 0 then
  wipe_progress += 0.03  -- adjust this value to control the speed of the transition
  if wipe_progress > 1 and transition_function then
   -- execute the stored function when the wipe effect reaches the halfway point
   transition_function()
   transition_function = nil  -- clear the function
		elseif wipe_progress > 2 then
   wipe_progress = -1
  end
  if(wipe_progress<1)return
 end
 
 update_camera()
	
 if moved and coins_collected < max_coins then
		speedrun_t+=1/60
	end
	
	if died_at and died_at < time() - 1 then
		load_level(blocks,blocks.px,blocks.py,blocks.pdx,blocks.pdy)
		died_at = nil
		revived_at = time()
		if time() < 1.5 then
			load_first_level()
		end
	end

	if not died_at then
		update_player()
	end
	
	for e in all(enemies) do
		update_enemy(e)
	end
	
	foreach(coins, function(c)
		update_coin(c)
	end)
	
	for b in all(blocks) do
		if(b.update)b.update(b)
	end

	update_dust()
	update_cpu_usage = stat(1) - stat_1
end

function update_coin(c)
	 if player.x+player.w/2>c.x-8
		and player.x-player.w/2<c.x+8
		and player.h.y>c.y-16
		and player.h.y<c.y then
			del(coins,c)
			sfx(7)
			dset(c.id, 1)
			sr_coins[c.id]=true
			coins_collected+=1
			coin_at=time()
			set_checkpoint(blocks,c.x,c.y-5,0,0)

			for i = 0,15 do
				add_dust(c,rnd(),1,true,55,"coin")
			end
		end
end

function update_enemy(e)
  if rnd()<0.01 or not e.dir then
    local r=rnd()
    e.dir=r<0.33 and -1 or r<0.66
     and 1 or (not e.pumpkin and player.x-e.x or 0)
				if e.dir==0 and (e.maxy and e.y>e.maxy) or (e.miny and e.y<e.miny)  then
					e.dir = rnd({1,-1})
				end
  end
  if e.maxx and e.x>e.maxx then e.dir=-1
  elseif e.minx and e.x<e.minx then e.dir=1 end
  local jc=e.pumpkin and 0.005 or 0.02
  if (e.maxy and e.y>e.maxy) jc=1
  if (e.miny and e.y<e.miny) jc=0
  update_character(e,e.dir,rnd()<jc,1)
  if not died_at and not e.pumpkin then
    local th=2+abs(player.dy)+abs(e.dy)
    if do_characters_overlap(e,player) and e.h.y+th>player.y then
      sfx(0)
	  player.jumped_on_blob = true
      player.y=e.h.y-2
      player.dy=-4.5
      player.last_gnded_y=player.y
      player.h.dy=-6.5
      e.h.dy+=2.5
      e.dy+=2
	  e.dy=min(e.dy,3)
	  e.h.dy=min(e.h.dy,3.5)
    elseif do_characters_overlap_forgiving(e,player) then
      die()
    end
  end
end

function update_camera()
	shake*=0.5
	if(manual_cam) return
	cam_x += ( player.x-cam_x-64)
		*0.1
	cam_y += ( player.y-cam_y-64)
	*0.1
	
			
	if cam_x > player.x - 64 + 50 then
		cam_x = player.x - 64 + 50
	end
	if cam_x < player.x - 64 - 50 then
		cam_x = player.x - 64 - 50
	end
	if cam_y > player.y - 64 + 50 then
		cam_y = player.y - 64 + 50
	end
	if cam_y < player.y - 64 - 50 then
		cam_y = player.y - 64 - 50
	end
	
	if cam_x < cam_bounds[1] then
		cam_x = cam_bounds[1]
	end
	if cam_x > cam_bounds[2] then
		cam_x = cam_bounds[2]
	end
	if cam_y < cam_bounds[3] then
		cam_y = cam_bounds[3]
	end
	if cam_y > cam_bounds[4] then
		cam_y = cam_bounds[4]
	end
end

function lerp(a, b, t)
  return a + (b - a) * t
end

function update_character(ch, move_dir, jump, t_stretch, jump_held)
	if (move_dir < 0) ch.dx -= ch.speed*t_scale
	if (move_dir > 0) ch.dx += ch.speed*t_scale
	if (move_dir > 0) ch.facing = ➡️
	if (move_dir < 0) ch.facing = ⬅️


	t_stretch= t_stretch or 1 
	if not ch.gnded and not ch.block then
		t_stretch=1
	end
	
	ch.stretch = ch.stretch and (
		 lerp(ch.stretch, t_stretch, .1)
	) or t_stretch
	
	ch.gnded = not not ch.block
	if ch.gnded then
		ch.last_gnded=time()
		ch.jumped_on_blob = false
		ch.last_gnded_y=ch.y
	else
		local g =(ch.dy < 0 and ch.jumped_on_blob) and g1 
				or (ch.dy < 0 and jump_held)and g1
				 or g2
		ch.dy+=g*t_scale
		ch.h.dy+=g*t_scale
	end

	if jump and 
		ch.dy >= 0 and
		ch.last_gnded != nil and
		time()-ch.last_gnded <= 0.2
	then
		ch.last_gnded=nil
		ch.dy = ch.jumpf or -3.5
		ch.h.dy = ch.jumpf and ch.jumpf*1.2 or -5.5
		for i=0,20 do add_dust(ch, -1,4) end
		if ch.x > cam_x
			and ch.x < cam_x + 128
			and ch.y > cam_y
			and ch.y < cam_y + 128
		then 
			sfx(0)
		end
	end

	ch.dx -= (0.1 * ch.dx) * t_scale
	ch.dy -= (sgn(ch.dy)
	* air
	   * ch.dy 
	   * ch.dy) * t_scale
	ch.h.dx -= 0.04 * ch.h.dx * t_scale
	ch.h.dy -= 0.05 * ch.h.dy * t_scale
	local h = ch.size * ch.stretch
	if(not ch.gnded and not ch.was_gnded) h=ch.size
	local fh=0.015
	if(ch.size < 12)fh*=2 
	
	local fyh = (ch.y - ch.h.y - h) 
		* fh * 3
	local fxh = (ch.x - ch.h.x) 
		* fh
		
	ch.h.dx += fxh * t_scale
	ch.h.dy += fyh * t_scale
	ch.dx -= fxh * t_scale
	
	local min_h =ch.size/4+1
	if ch.h.y + min_h > ch.y then
		if(ch.h.dy>0)ch.h.dy *= -1
		ch.h.y = ch.y-min_h
		eject_particle(ch.h, false, 0.5, 1)
		if (ch.y != ch.h.y+min_h) then
			ch.y = ch.h.y+min_h
			ch.dy *= -1 * ch.bounce
			if is_solid(ch, true) and ch == player then
				die()
			end
		end
	end

	ch.block=nil
	update_particle(ch, ch.dy >= 0)
	update_particle(ch.h, false)
	check_for_squeeze(ch)
	update_character_w(ch)

	local max_h = ch.size*ch.stretch*1.25
	if ch.h.y + max_h < ch.y then
		ch.h.y = ch.y-max_h
		eject_particle(ch.h, false, 0.5, 1)
	end	

	local delta_s = ch.tsize - ch.size
	ch.size += delta_s*0.2* t_scale
	check_for_squeeze(ch)
	ch.was_gnded = ch.gnded
	ch.prev_block = ch.block
	
end

function get_bounding_box_forgiving(p)
		local w=p.w-abs(p.x-p.h.x)
		local x=(p.x+p.h.x-w)/2
		local y=p.y
		local h=p.h.y-p.y
  return {x = x, y = y, w = w , h = h}
end
function get_bounding_box(p)
		local x=min(
			p.x-p.w/2, 
			p.h.x-p.w/2
		)
		local y=p.y
		local h=p.h.y-p.y
		local w = max(
			p.x+p.w/2, 
			p.h.x+p.w/2
		) - x
  return {x = x, y = y, w = w , h = h}
end

function do_characters_overlap_forgiving(p1, p2)
  local bbox1 = get_bounding_box_forgiving(p1)
  local bbox2 = get_bounding_box_forgiving(p2)
  return not (bbox1.x + bbox1.w < bbox2.x or bbox2.x + bbox2.w < bbox1.x or bbox1.y + bbox1.h > bbox2.y or bbox2.y + bbox2.h > bbox1.y)
end

function do_characters_overlap(p1, p2)
  local bbox1 = get_bounding_box(p1)
  local bbox2 = get_bounding_box(p2)
  return not (bbox1.x + bbox1.w < bbox2.x or bbox2.x + bbox2.w < bbox1.x or bbox1.y + bbox1.h > bbox2.y or bbox2.y + bbox2.h > bbox1.y)
end


function update_player()
	if not jump_btn_down and (btn(4) or btn(5)) then
	 jump_btn = time()
	end
	jump_btn_down = btn(4) or btn(5)

	update_character(player, 
		btn(0) and -1 or btn(1) and 1 or 0,
		jump_btn_down and jump_btn and jump_btn >= time() - 0.25,
		(btn(3) and .5 or btn(2) and 1.5 or jump_btn_down and 1.25),
		jump_btn_down
	)

	if player.gnded and abs(player.dx) > 0.4 then
		if(rnd()<.3)add_dust(player)
	end
	
	if player.y > 2000 then
		die()
	end
end

function update_character_w(ch)
	local h = ch.y-ch.h.y
	local s= ch.size
	local tw=(32 - h * (25 / 20))/14*s
	tw=min(tw, 30/16*s)
	tw=max(tw, 4)
	ch.w = lerp(ch.w,tw,1)
	ch.h.w = ch.w
end

function skw_spr(x,y,hx,hy, w, size, u)
	h = y-hy+1
	if (h<0)h=0
	for i=0,h do
		s = i/h*16
		sw= (hx-x)*(h-i)/h
		local  v, dv = s/8, 1/w*2
		tline(x-w/2 + sw,y+i-h,
								x+w/2 + sw,y+i-h,
								u, v,
								dv)
	end

end

function on_land(p)
	if(p.dy > 2) then
		for i=0,20 do add_dust(p,2,2) end
		if will_smash(p) then
			shake=25
			sfx(2)
			if p.block.on_crash then
				p.block:on_crash()
				return true
			end
		else
			sfx(1)
		end
	end
end

function die()
	if died_at then
		return
	end
	sfx(4)
	if (debug) return
	died_at = time()
	for i = 0,15 do
		add_dust(player, player.dx,player.dy,true,55)
	end
end
-->8
--physics
function check_for_squeeze(p)
	if(p != player)return
	
	if(is_solid({
			y=p.y,
			x=p.x,
	})) then 
		return false
	end
	while true do
		local right_col = is_solid({
			y=p.y,
			x=p.x+p.w/2+1,
		}) and is_solid({
			y=p.y,
			x=p.h.x+p.h.w/2+1,
		})
		local left_col = is_solid({
			y=p.y,
			x=p.x-p.w/2-1,
		}) and is_solid({
			y=p.y,
			x=p.h.x-p.h.w/2-1,
		})
		p.w-=1
		p.h.w-=1
		if right_col and left_col then 
			if 	is_solid({
				y=p.h.y-1,
				x=p.h.x,
			}) 	then 
				p.y += 1
				p.h.y += 1
			else
				p.h.y -= 1
			end
		elseif right_col then
			p.x -= 1
			p.h.x -= 1
		elseif left_col then
			p.x += 1
			p.h.x += 1
		else
			break
		end
	end
end

function is_colide(x,y,w,inc_semi, h)
	local xs,ys = {x},{y}
	if w then 
		xs = {}
		for dx=0,w/2,7 do
			add(xs, x+dx)
			add(xs, x-dx)
		end
		add(xs, x+w/2)
		add(xs, x-w/2)
	end
	if(h)add(ys, (y+h.y)/2)
	
	for _,y2 in ipairs(ys) do
		for i,x2 in ipairs(xs) do
			local b,tile = is_solid({
				y=y2,
				x=x2,
			},inc_semi)
			if(b)return b,tile
		end
	end
	return false
end

function eject_particle(p, inc_semi, x, y)
	if not is_colide(p.x, p.y, p.w,inc_semi) then
		return
	end
	local ty1,ty2=p.y,p.y
	local tx1,tx2=p.x,p.x
	local i = 0
	while true do
	 ty1-=y
	 ty2+=y
	 tx1-=x
	 tx2+=x
		i+=1
	 local collide_ty1 = is_colide(p.x, ty1, p.w,inc_semi)
	 if not collide_ty1 then
	  p.y = ty1
	  break
	 end
	 local collide_ty2 = is_colide(p.x, ty2, p.w,inc_semi)
	 if not collide_ty2 then
	  p.y = ty2
	  break
	 end
	 local collide_tx1 = is_colide(tx1, p.y, p.w,inc_semi)
	 if not collide_tx1 then
	  p.x = tx1
	  break
		end
	 local collide_tx2 = is_colide(tx2, p.y, p.w,inc_semi)
	 if not collide_tx2 then
	  p.x = tx2
	  break
	 end

	end
end	

function update_particle(p, inc_semi)
	eject_particle(p, inc_semi, 1, 1)

	x_col = is_colide(p.x+p.dx,p.y,p.w,false)
	if not x_col then
		p.x += p.dx*t_scale
	else
		p.dx *= -1
		p.dx *= p.bounce or 0
	end
	
	p.dy=min(p.dy,4)
	p.dy=max(p.dy,-10)

	y_col,tile = is_colide(p.x,p.y+p.dy,p.w,inc_semi)
	if not y_col  then
		 p.y += p.dy*t_scale
	else
		if p.dy > -.1 then
			p.block = y_col
		end
		if fget(tile, 7) and not fget(tile, 1) then 
			if p==player  then
				die()
			end
		end
		if fget(tile, 7) and fget(tile, 1) then 
			if p==player or p==player.h then
				die()
			end
		end
		local override_bounce = false
		if p.on_land  then
			override_bounce = p.on_land(p)
		end
		if not override_bounce then
			p.dy *= -(p.bounce or 0)
		end
	end
end
-->8
--decomp
function
    px9_decomp(x0,y0,src,vget,vset)

    local function vlist_val(l, val)
        -- find position and move
        -- to head of the list

--[ 2-3x faster than block below
        local v,i=l[1],1
        while v!=val do
            i+=1
            v,l[i]=l[i],v
        end
        l[1]=val
--]]

--[[ 7 tokens smaller than above
        for i,v in ipairs(l) do
            if v==val then
                add(l,deli(l,i),1)
                return
            end
        end
--]]
    end

    -- bit cache is between 8 and
    -- 15 bits long with the next
    -- bits in these positions:
    --   0b0000.12345678...
    -- (1 is the next bit in the
    --   stream, 2 is the next bit
    --   after that, etc.
    --  0 is a literal zero)
    local cache,cache_bits=0,0
    function getval(bits)
        if cache_bits<8 then
            -- cache next 8 bits
            cache_bits+=8
            cache+=@src>>cache_bits
            src+=1
        end

        -- shift requested bits up
        -- into the integer slots
        cache<<=bits
        local val=cache&0xffff
        -- remove the integer bits
        cache^^=val
        cache_bits-=bits
        return val
    end

    -- get number plus n
    function gnp(n)
        local bits=0
        repeat
            bits+=1
            local vv=getval(bits)
            n+=vv
        until vv<(1<<bits)-1
        return n
    end

    -- header

    local
        w,h_1,      -- w,h-1
        eb,el,pr,
        x,y,
        splen,
        predict
        =
        gnp"1",gnp"0",
        gnp"1",{},{},
        0,0,
        0
        --,nil

    for i=1,gnp"1" do
        add(el,getval(eb))
    end
    for y=y0,y0+h_1 do
        for x=x0,x0+w-1 do
            splen-=1

            if(splen<1) then
                splen,predict=gnp"1",not predict
            end

            local a=y>y0 and vget(x,y-1) or 0

            -- create vlist if needed
            local l=pr[a] or {unpack(el)}
            pr[a]=l

            -- grab index from stream
            -- iff predicted, always 1

            local v=l[predict and 1 or gnp"2"]

            -- update predictions
            vlist_val(l, v)
            vlist_val(el, v)

            -- set
            vset(x,y,v)
        end
    end
end

-->8
--dust
function add_dust(ch, dy, dx,fullh, t, type)
	if(ch != player and type!="coin")return
	if stat(7)<60 or #dust > 30 then
		deli(dust, 1)	
		deli(dust, 1)	
	end
	add(dust, {
			x=ch.x
				+(rnd()-.5)*ch.w,
			y=ch.y - (fullh and rnd()*20 or 0) ,
			c=11,
			type=type,
			dx=(dx or 1)*(rnd()-.5)-.1*(ch.dx or 0),
			dy=2*(dy or -.7)*(rnd()*.5+.5),
			t=(t or 30)+flr(30*rnd()),
			bounce=.7,
			g=type!="coin" and .2 or -.1
		})
end

function update_dust()	

	if((time()*60)%2 > 1.5) then
		return
	end
	foreach(dust, function(d)
		update_particle(d, d.dy>0)
		d.t -= 2
		d.dy += d.g
		if d.t < 0 then
			del(dust, d)
		elseif d.t < 15 then
			d.c = 5
		elseif d.t < 30 then
			d.c = 3
		end
	end)
end

function draw_dust()
	foreach(dust, function(d)
		if d.t > 80 then
			spr(33, d.x-4,d.y-4) 
		elseif d.t > 75 then
			spr(34, d.x-4,d.y-4) 
		elseif d.t > 60 then
			spr(49, d.x-4,d.y-4)
		elseif d.t > 45 then
			spr(50, d.x-4,d.y-4)
		else
			pset(d.x,d.y,d.c)
		end
	end)
end
-->8
--levels
#include levels.p8
-->8
--level loading

function is_solid(p,inc_semi)
	for b in all(blocks) do
		if b.colide != false then
			local x,w,h=p.x,
								b[3]*(b.rx or 1),
								b[4]*(b.ry or 1)
								
			if x/8 > b[5]
			and x/8 < b[5]+w
			then
				local y=p.y
				if y/8 > b[6]
				and y/8 < b[6]+h
				then
					if b.rx then
						x-=b[5]*8
						x%=b[3]*8
						x+=b[5]*8
					end
					if b.ry then
						y-=b[6]*8
						y%=b[4]*8
						y+=b[6]*8
					end
					local tile = is_solid_in_block(b,{
						x=x,
						y=y
					},inc_semi)
					if tile then
						return b, tile
					end
				end
			end
		end
	end
	return false
end

function is_solid_in_block(b, e,inc_semi)
	local x = e.x/8 + b[1] - b[5]
	local y = e.y/8 + b[2] - b[6]
	local tile = mget(x,y)
	if b.tile then
		local x,y=b[1]+1,b[2]+1
		if e.x/8-b[5] < 1 then
			x-=1
		elseif e.x/8-b[5] > b[3]-1 then
			x+=1
		end
		if e.y/8-b[6] < 1 then
			y-=1
		elseif e.y/8-b[6] > b[4]-1 then
			y+=1
		end
		tile = mget(x,y)
	end
	if fget(tile, 2) then
		if(not inc_semi) return false
		if(e.y % 8 > 4) return false
		return tile
	end
	if fget(tile, 0) then
		if(e.y % 8 < 5) return false
		return tile	
	end
	if fget(tile, 3) then
		return tile
	end
	
	return false
end

function draw_blocks(front)
	for b in all(blocks) do
	if(b.front == front) then
	for ox=0,(b.rx or 1)-1 do --horizontal repeats 		
		for oy=0,(b.ry or 1)-1 do --vertical repeats
			if b.draw then
				b.draw()
			elseif b.fill then
				rectfill(
					b[5]*8,
					b[6]*8,
					b[5]*8+b[3]*8-1,
					b[6]*8+b[4]*8-1,
					b.fill
				)
			elseif b.tile then

				local i_min = max(0, ceil((cam_x - b[5]*8)/8)-1)
				local j_min = max(0, ceil((cam_y - b[6]*8)/8)-1)
				for i=i_min, min(b[3]-1, flr((cam_x+128-b[5]*8)/8)) do
    for j=j_min, min(b[4]-1, flr((cam_y+128-b[6]*8)/8)) do
						local sx,sy = 
							b[1]+(i==0 and 0 or 1)+(i==(b[3]-1) and 1 or 0),
							b[2]+(j==0 and 0 or 1)+(j==(b[4]-1) and 1 or 0)
						local n = 1
						local s=mget(sx,sy)
						if s!=0 then
							spr(s,
								(b[5]+i)*8,
								(b[6]+j)*8
							)
						end
					end
				end
									
				else
				map(b[1],--src x
				 b[2], --src y
				 b[5]*8+ox*b[3]*8, --screen x
				 b[6]*8+oy*b[4]*8, --screen y
				 b[3], --width
				 b[4] --height
				)
			end
		end
	end
	end
	end
end

function calc_cam_bounds()
	cam_bounds = {1000,-1000,1000,-1000}
	for b in all(blocks) do
		if b.update != drop and b.colide!=false then
			if cam_bounds[1] > b[5]*8 then
				cam_bounds[1] = b[5]*8
			end
			if cam_bounds[2] < (b[5]+b[3]*(b.rx or 1))*8 -128 then
				cam_bounds[2] = (b[5]+b[3]*(b.rx or 1))*8 -128
			end
			if cam_bounds[3] > b[6]*8 then
				cam_bounds[3] = b[6]*8
			end
			if cam_bounds[4] < (b[6]+b[4]*(b.ry or 1))*8-128 then
				cam_bounds[4] = (b[6]+b[4]*(b.ry or 1))*8-128 
			end
		end
	end 
end
transition_function = nil

function set_checkpoint(level, x,y,dx,dy)
		if x != nil then
		level.px = x
	end
	if y != nil then
		level.py = y
	end
	level.pdx = dx or 0
	level.pdy = dy or 0
	
	
	for i, v in ipairs(levels) do
		 if v == level and not speedrun then
		 	dset(63, i)
		 	dset(62, flr(level.px/8))
		 	dset(61, flr(level.py/8))
		 	dset(60, flr(level.pdx))
		 	dset(59, flr(level.pdy))
		 	break
		 end
	end
end
function transition(func)
    transition_function = func
    wipe_progress = 0  -- start wipe effect
end

function load_level_instant(level,x,y,dx,dy)
	reload(
		0x1000,
		0x1000,
		128*64
	)

	
	if level.chunk then
		local _addr = level.chunk<32 and 0x2000+128*level.chunk or 0x1000+128*(level.chunk-32)
		local working_ram_addr = 0x8000
		memcpy(
			working_ram_addr,
			_addr, --The address of where the compressed data for the level is
			128*chunk_size -- how many rows to copy
		)
		px9_decomp(0,3,working_ram_addr,mget,mset)
	end
	set_checkpoint(level, x,y,dx,dy)
	
	blocks=level
	for b in all(blocks) do
		if broken_blocks[key] then 
			del(blocks,b)
		end
	end
	calc_cam_bounds()
	manual_cam=false
	
	player.x = level.px or player.x
	player.y = level.py or player.y
	if player.last_gnded_y != "override" then 
		player.last_gnded_y = player.y
	end
	player.h.x = player.x
	player.h.y = player.y-player.size
	player.dx = level.pdx
	player.dy = level.pdy
	player.h.dx = level.pdx
	player.h.dy = level.pdy
	
	enemies={}
	coins={}
	for e in all(level.e or {}) do
		spawn_enemy(e)
	end
	for c in all(level.c or {}) do
		if speedrun then
			if	not sr_coins[c.id]  then
				spawn_coin(c)
			end
		else
			if	dget(c.id) == 0  then
				spawn_coin(c)
			end
		end
	end
	
	cam_x = player.x - 64
	cam_y = player.y - 100
	
	check_for_squeeze(player)	
	
	if #coins == 0 then
		coin_at=time()
	end
end


function set_checkpoint(level, x,y,dx,dy)
	if x != nil then
		level.px = x
	end
	if y != nil then
		level.py = y
	end
	level.pdx = dx or 0
	level.pdy = dy or 0
	
	
	for i, v in ipairs(levels) do
		 if v == level then
		 	dset(63, i)
		 	dset(62, flr(level.px/8))
		 	dset(61, flr(level.py/8))
		 	dset(60, flr(level.pdx))
		 	dset(59, flr(level.pdy))
		 	break
		 end
	end
end

function load_level(level, x, y, dx, dy)
	if blocks == level then
		load_level_instant(level, x, y, dx, dy)
	else
		transition(function()
			 load_level_instant(level, x, y, dx, dy)
		end)
	end
end
function spawn_coin(c)
	add(coins, {
		x=c.x*8,
		y=c.y*8,
		h={x=c.x*8,y=c.y*8},
		w=16,
		dx=0,
		id=c.id
	})
end

function spawn_enemy(e)
	add(enemies, {
		x=e.x*8,
		y=e.y*8-2,
		pumpkin=e.pumpkin,
		maxx=e.maxx,
		minx=e.minx,
		maxy=e.maxy,
		miny=e.miny,
		dx=0,
		dy=0,
		w=8,
		bounce=0,
		size=e.size or 12,
		tsize=e.size or 12,
		speed=0.07,
		jumpf=-4.5,
		h={
			x=e.x*8,
			y=e.y*8-14,
			dx=0,
			dy=0,
			w=12,
		},
		last_gnded=0,
		was_gnded=false,
	})
end	



-->8
--init
function _init()
	if(label)poke(0x5f2c,3)
	poke(0x5f34,0x2)
	cartdata("kai-pumpkin-2-v1-0")
	coins_collected=0
	init()
	for i = 0,30 do
		if dget(i)==1 then
			coins_collected+=1	
			coin_at=time()		
		end
	end
	speedrun=coins_collected>=max_coins
	init()
	if(speedrun)speedrun_init()
end

function add_speedrun_option()
	menuitem(5,"start speedrun",function()
		extcmd("reset")
	end)
end

sr_coins={}
function speedrun_init()
	add_speedrun_option()
	coins_collected=0
	load_first_level()
end

function load_first_level()
	level1.px=20
	level1.py=100
	load_level_instant(level1,level1.px,level1.py)
end

function is_halloween()
    local month = stat(91)
    local day = stat(92)
    return (month == 10 and day >= 25) or
           (month == 11 and day <= 7)
end
__gfx__
000000001111000000001111111110000001111144499444005555605000000000000000000000051111111001111111111111115353333333333b3b00000000
0000000011503bbbbbb305111110099997700111444049440d6656010b33b33b3b33b33b3b33b33011111106d0111111b311b3b135313333331333b300000000
0070070015bbbb67bbbbb35111099aaa77a970114407049410d6501100030330000303300003033011111106601111113b3b3b3b533333333333333b00000000
0007700010bbb7776bbbb3011099a449944777014406029910d67011222020042220200222202000111110056001111133333333333333333333333300000000
0007700003bbb6777bbbbb30109a997799797901905670291105011142224229944242299442444f111004449f90011133333133333333333333333300000000
007007000bbbbb76bbbbbb3004a9977997774a9090dd6024110601114424444499444444994444ff110f4ff4f9f9901133333333333333333333333300000000
000000000bb76bbbbbbbbb3004a9779977794a9005dd6702111011112444444449944444499444ff10f4ff4fff9fff0131333333333333333333333300000000
000000000bb67bbbbbbbbb3004a7799777994a9005ddd602111111112249444444994444449944ff104ff4f44ffff90133333333333333333333333300000000
111111110bbbbbbbbbbbbb300977997779994a9044499444444994442229944444499444444994ff102f44fffff9f40111111111111111119911111100000000
111111110bbbbbbbbbbbb3300999977799a94a9044449944444499442224994444449944444499ff1102f4fffff94401b1111111111111351144119900000000
111111110bbbbbbbbbbbb330049977799a994a90444449a4444449942224499444444994444449af110ff444ff4ff4f03b311111111113534449a11100000000
1111111103bbbbbbbbbb333010977799a999a901444444aa224444992224449944444499444444aa1024f4fff44ff420b3b1111111113535144a911100000000
11111111033bbbbbbbb3333010977999999a9901944444fa422444494224444994444449944444fa024ff4ffff4f4f013b3b311111115153114a791100000000
11111111053333333333335011094aaaaaa99011994444ff442444444424444499444444994444ff05444f4ff4f4ff2033b3b31111353533494aea1100000000
1111111110553333333355011110044444400111499444ff244444442444444449944444499444ff105454444445ff01313b3b31115353331111144100000000
1111111111000000000000111111100000011111449944ff224944442249444444994444449944ff11000000000000113333b3b1153533311441119400000000
1110111011000011111111110000000011153311444994f0004994442249944444499444444994ff111111100111111100000000000000004411111100000000
010101011049aa511110011100000000153333514444990b330499442244994444449944444499ff11111103b011111100000000000000001144114900000000
101010100499779011099411000000005333ab31444444033b3049942224299224422992244229af111111033011111100000000000000004994a11100000000
01010101049997901049790100000000333bba3144444420030444992222124412221244122212aa1111100530011111000000000000000014449a1100000000
0000000054999990154499010000000033b3bb3194444449402444491241124112411221124112f11110044449a001110000000000000000114a791100000000
000000005449994011544011000000005333bb339944444494444444121112111211121112111211110949949a9aa0110000000000000000444aea1100000000
00000000154444011115011100000000333b3b3349944444499444441111111111111111111111111094994999a9aa0100000000000000001111144100000000
000000001155001111111111000000005333b33344994444449944441111111111111111111111110949949999999aa000000000000000001491114900000000
0000000011111111111111110000000033333b331111111105ddd60110010010010010010010010009499499999a949000000000000000004411111100000000
00000000111111111111111100000000533333331110111105dd670104904904904904904904904909499499999a949000000000000000001199119400000000
00000000111041111111111100000000333333331107011110dd6011044044044044044044044044044994999949949000000000000000004444a11100000000
0000000011097411111141110000000015355351110601111056701110010010010010010010010004449499994994900000000000000000199a9a1100000000
0000000011549011111594110000000011549511105670111106011111111111111111111111111104449499994949900000000000000000114a7a1100000000
000000001115011111115111000000001154951110dd601111070111111111111111111111111111054449499494999000000000000000004449ea1100000000
000000001111111111111111000000001154951105dd670111101111111111111111111111111111105454444445990100000000000000001111199100000000
000000001111111111111111000000001549995105ddd60111111111111111111111111111111111110000000000001100000000000000001941114400000000
50000000000000000000000550000005555555555555555550000000000000000000000599949499111111111111116666111111111111115555555544499444
07767776677767766777677007766670555555555555555504999994999999949999997049999949111111111111116666111111111111115445544544499444
0d65666556665665566657700d655670555655555555555505444444444444444444449095555594111111111166661661666611111111114444444444444444
0d65555555555555555555600d655560555555665665565590000000000000000000000445555594111111111666666666666661111111114554455499999999
0055655d555655655555577000555670555555665665555594944444444444444444444545555594111111116666666666666666111111115555555599999999
0d65555555555555556557700d655670555665555555555599445454545454545454545445555594111111116666666666666666111111115445544544444444
0d65565556555555555557700d6556705556655ddd56655595454545454545454545454545555595111111116666666666666666111111114444454444994444
0055555555555555d555556000555560555555600d56655594555555555555555555555554444455111111166666666666666666611111114544444444994444
00555555555555555555556000555560555665600d55555599999999999999999999954599999999111116616666666650000005166111111114111144499444
0d665d5555555555555556700d665670555665566556655599494949494949494949495549494949111166666666666604444440666611111111411144499444
0d66556555555555556556700d6656705555555555566555949494949494949494949545949494941116666666666666059f9940666661111114111144994444
0d66555555555555555555600d665560555556656655555599444444444444444444445544444444111666666666666604944f40666661111111411149944499
00555555555555555555667000556670556556656655555594944444444444444444454544499944166166666666666605944940666616611114111199444999
0d655655d5555555565d66700d65667055555555555565559944545454545454545454554455559466666666666666660499f940666666661111411194449944
0d65555555555555555566700d656670555555555555555595454545454545454545454545555559666666666666666605454540666666661114111144499444
005555555555d5555555556000555560555555555555555594555555555555555555555545555559666666666666666650000005666666661111411144994444
00555655555555655565667000556670500000000000000555555555545445444494494945555559333333333333333333333333333333333333433355555555
0d65555555555555555566700d656670077767766777677054455445545445444494494945555559333333333333333333333333333343333333333355555555
0d65555555655555555555600d65556000665665566656604444444454544544449449494555555933333333b3333333333333b3343435343434393955555555
005555655555565556d5567000555670005555555555556045544554545445444494494945555559333333333333333333333333535343434393434355555555
0d66555555555555555556700d6656700d6566555565557055555555545445444494494945555559333333333313333333333331343435343434393955555555
0d66566556656665566655600d6655600d656655555565705445544554544544449449494555555933333333133333333333b331545445444494494355555555
00000dd00dd0ddd00ddd0060000000600055555ddd55566044444444545445444494494945555559333333331133333b33333331345435444394434955555555
50000000000000000000000550000005005555600d55566045544554545445444494494945555559333333331131333333331311543445434493494955555555
50000000000000000000000511111111005555600d55557050000000000000000000000511111111333333331113333313313111111111111111111155555555
077677766777677667776600111111110d656656655555700db3bb3b333b33b33b333b30141514153b3333331111113333111111111111111111111165566665
0d6566655666566556665600111111110d656655556655700035335535535555553535504141414133333b311111111111111111111111111111111155566665
0d6555555555555555555500111111110d655555556656600d5555555555555555555560151415143313333311111111111111111111113311111111555dddd5
0d66555555555555555556705000000500555555555556600055655d555655655555567055555555113331331111111111111111111113331131113155555555
0d66566556656665566655600776667000566655665665700d655555555555555565567054455445111133111111111111111111331113311131113156655655
00000dd00dd0ddd50ddd00600d655670000ddd00dd0d0d700d65565556555555555556704444444411111111111111111111111133313331113131315dd55555
5000000000000000000000050d65556050000000000000050055555555555555d555556045544554111111111111111111111111133133113131333355555555
ffff8ff73dfbff7e9a0003228a2a031b308273aa021ac0c83048408b53b2b2ca334b637bb315cee3cefbf3ffb0fe6353cbbbcbd377e3d33bd67a92b9c9c93232
4af64a0aa27fa9eeeee005051d7085859db056bd17fcc5ab6e5ffde997e99c7f1e87cff7f2fc4fdf756ffd5af9fb8ee761e7f93cfa7eafeffe9fefbcf7fecf31
b8ff78ff715e7ef78fff2ff4cffacf2df75ee78694ff395fbbfff3f1af83cdff3ef8cff78f2ef4cfd71fffb9fff2eff5df42ff7cff78d96c9df1bcfbcff3affb
0fffbeff5cffb8ff4629ed763fcf7cefedfaeff2dffdbf3affa1f7fe19f71ff53fffa4fecffb9f971bdfbf37ff710579ff73ef731e1272ff30ff98ffacf5ef67
8fffccfd7ceff27eef39efff9e731eff3cfff0767c5ff6ef95f74ff34a0fe9f054c185c81732cdd971f8effbcfb442cff7b07699ffad77ffbdff2bf33ffff99f
27f70ef98ff77f3ff99ff3bf7df5eff3cfff8fff5fff7eff4d3e8878d514c4b8ff8e9465f7ceff5c8ff5bfef0969b5f2fff7dff1495e72ef36f18f6e07ff3cff
58d2ffdcff59cc87d1ffbfff9fff3fff7efffcfff9ff3215dc109dff79ff75effbcffaac2da0f71ef75e84ff3d30ff2437b33eff773fcfffdfffdc1ae0a4d0f3
f7ef3cffe4f37ffb9a3c2f01b8ccc1ff6effdfff9bffcf50a3179c70f4dff3bff36fe7e0c5f43cafffeff0ff0f98ff24a2bf7a9e224fcfa3cff7f16c1f93ff2d
f74ef6cff78fff0f427e88e8f3ff68fd9fc58b2ee48f4429fccffdaf4af72f391fcff30fecbcffa9e778ef4b2fe7489e7cf78ff32fff1e27ff6ca516f2ef87ff
ecf78e7afe4b0816ff2c07e4e1b9f9fdf76eff7cbc797a1ef55879fe5e7099ba98ffcfb1f0cf535c2efddfc911a3eb71f9cfc572356fd3b944efc1e1f0cf9e4c
fffcf4cff9b8ff8fc9f48077f3ffa85fdcf99ffeb9ff75eff8dfc1ef97e371ff96ac7ae473f3fecf7a1ef73ff7ff918f5cb4b476c0e7c5f36fef78ef86f25f5c
c2a4e0d2f73ef3b1f3fff8e39effbcf7ff32ff9ff3ffac8def168fe5bbee7aef2394cfefea46f2f0ff5e3f9ff57beffcff6ef7ff73ff9fcd154ecba42e3cff0c
00000000000000000000000000000000000000001111111999991111111111111111111111111111111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000011111199999aa911111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000001111199991199991111999911111111111111111111111111111111111111111119111111111111111111111
00000000000000000000000000000000000000001111199911119991199449a91111999999111119999991119911111199111119119111191111111111111111
1111111111155111111111110000000000000000111119991111999199911199911999449a9111999449a9199a911119a9111119119991919111111111111111
1111111111945511111111113bbbbbbb000000001111199999999941999111999199941199a9199941199a9499a1111999111199919191999111111111111111
11111111194945511111111133b3b3b3000000001111199994444419999999991199911149991999111499914999119999111119119191911111111111111111
1111111114944451111111115333b333000000001111199991111114999411111199911119991999111199911499919994111119911111199111111111111111
11111111944444551111111153333535000000001111199991111111999111111199911119991999111199911149999941111111111111111111111111111111
11111114454545455111111155353535000000001111199991111111499999999199411119941994111199411114999911111111111111111111111111111111
11111144545454545511111155553555000000001111199991111111144999944144111114411441111144111111999411111111113111111111111111111111
11111145555555555511111155555555000000001111149991111111111444411111111111111111111111111119999111111111494911111111111111111111
11111999999999444551111100000000000000001111114991111111111111111111111111111111111111111999941111111114999491111111111111111111
11119494949494944455111100000000000000001111111449999111111111111111111111111111111111114994411199911114999491111111111111111111
1119494949494949444551110000000000000000111111199999aa9111111111111111111111111111111111144111119a911111494911111111111111111111
11194444444444444444511100000000000000001111119999119999111111111111111111111111111111111111111999411111111111111111111111111111
11944444444444444444551100000000000000001111119991111999199911111991111111111111111111999999111999111991111111111111111111111111
1944454545454545454544510000000000000000111111999111199999a911119a911199991111999111199999aa911999119a91999911199999911111111111
944454545454545454545455000000000000000011111199999999949999111199a919aa99111999a9119994114999199919991199a911999999a91111111111
455555555555555555555555000000000000000011111199994444419999111199991999499199499911999111199919999991119999199994499a9111111111
51111111111111111111111551111111111111151111119999111111499911119991199919999419991999911119991999999111999919999114999111111111
15511111111111111111155115511111111115511111119999111111199991199991999414999119991999911119941999199991999499994111999111111111
19a555111111111111555a9119a5551111555a911111114999111111149999999941999111499119991999999999911994114999999199991111999111111111
19991955555555555591999119991155551199911111111444111111114499944411499111141114991999944444411441111444444149911111994111111111
144419a9119aa9119a9144411444119aa91144411111111111111111111144411111144111111111441999911111111111111111111114411111441111111111
11111999119999119991111111111199991111111111111111111111111111111111111111111111111499911111111111111111111111111111111111111111
11111444114444114441111111111144441111111111111111111111111111111111111111111111111199411111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111144111111111111111111111111111111111111111111
449994111111111111111111111111111111111111111111111111111111111111111111111d6611000000001111999991111111000001119999999999999999
9911194111111111111111111111111111111111111111111ee1ee111111111111d66611111d6611000000001111194949111111999970114949494949494949
991119911111111111111199941194111194111111111111eeeeeee11ee1ee111d6666611d666666000000001111149494491111444490119499949499949494
991119919411191999994199119199119111199991111111eeeeeee11eeeee111d6666611d666666000000001144444444111111000001114445594455994444
aa111aa1aa111a1aa1a1a1aa11a1aa1a11aa1aa11a111111eeeeeee11eeeee111d666661111d6611000000001115444444445111441111114455559455559944
aaaaaa11aa111a1aa111a1aaaa11aaa111aa1aa11a1111111eeeee1111eee1111d666661111d6611000000001111445454511111454111114555555995555594
aa111111aa111a1aa111a1aa1111aa1a119919911a11111111eee111111e11111d666661111d6611000000001115454541111111545451114555555955555559
441111119999941991119199111199119144144119111111111e1111111111111d666661111d6611000000001111155555551111555111114555555945555559
00000000544999111155499915449911111911111111111711111111111177177777111111111111111111111111111111111111111111114555555945555559
00000000444476911567444915474911115691111177717771777111111777677777711115115111115111511111111111111111111111114555555945555559
00000000467777695677777415474911156769111777767776777711111777777777677115115111115111511116111111111111111111114555555944555559
00000000444476411467444415474454157779111777777777777671176777777777777115115155515115511167611111111111111111114555555944555555
00000000555555111155555515777511144744111777777777777771777777777777776715555151515151511116111111111111111111114444444445555555
00000000111511111111511115676511154744547777777777777771777777777777777715115155515155511111111111111111111111115454545455555555
00000000111411111111411111465111154644117777777777777767167777777777777711111111111111111111111111111111111111114545454555555555
00000000111411111111411111151111155444111677777777777777177777777777777711111111111111111111111111111111111111115555555555555559
00000000000000000000000011994451111191111777777777777777777777777777777711111111111111110000000011111100111100111115151100000000
00000000000000000000000011947451111965111777777777777671776777777777677115551111111115510000000011111108011080111115551100000000
00000000000000000000000011947451119676511177677767777711117777777777711111511111111115510000000011111100011000111111511100000000
00000000000000000000000045447451119777511111777771777711117776767767711111515151555515510000000011111111111111111115551100000000
00000000000000000000000011577751114474411111777771111111111771771177177111515151515515110000000011111101010101111115151100000000
00000000000000000000000011567651454474511111177111111771111111111111177115515551511515110000000011111110101011111115551100000000
00000000000000000000000011156411114464511111111111111771111111111111111111111111111111110000000011111111111111111111511100000000
00000000000000000000000011115111114445511111111111171111111111111111711111111111111111110000000011111111111111111115551100000000
__label__
ggggggggggggggggggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggdmdgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggmggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggm
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggmgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmgggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmgggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmgggggggmggggggmgggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmgggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmgggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmgggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgmmmmmmmmmgggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggmgggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmgggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmgggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggmgggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmgggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmgggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggmgggggggggggggggggggggggggggggggggggggmmmmmmmmmmgggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmgggggggggggggggggggmggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmgggggggggggggggggggmggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmgggggggggggggggggmgggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmgggggggggggggggmmgggggg
ggggggggggggggggggggggggggggggggmgggggggggmggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmgggggggggggggmmmgggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmgggggggggggmmmggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmgggggggggggggggggggmmmmmmmmmmmmmmmgggggggmmmmmggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmmmgggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmmmggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmmmgggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmmmggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggmgggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmmmmmgggggggggggg
ggggggggggggggggggggggggggg00000gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmmmmmmmgggggggggggggg
gggggggggggggggggggggggggg0ppppp00ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggmmmmmmmggggggggggggggggg
ggggggggggggggggggggggggg0ppppp99p0gggg0000ggggggggggggggggggggggggggggggggggggggggggg0ggggggggmgggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0pppp00pppp0g00pppp0gggg000000ggggg000000ggg00gggggg00ggggg0g0p0ggg0gggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0ppp0000ppp00ppkkp9p0gg0pppppp0ggg0pppppp0g0pp0gggg0pp0ggg0p00p00m0p0ggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0ppp0000ppp0ppp000ppp00pppkkp9p0g0pppkkp9p0pp9p0gg0p9p0ggg0p00ppp0p0p0gggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0pppppppppk0ppp000ppp0pppk00pp9p0pppk00pp9pkpp90gg0ppp00g0ppp0p0p0ppp0gggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0ppppkkkkk0ppppppppp00ppp000kppp0ppp000kppp0kppp00pppp00gg0p00p0p0p0000ggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0pppp000000kpppk000000ppp0000ppp0ppp0000ppp00kppp0pppk00gg0pp000000pp00ggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0pppp0000000ppp0000000ppp00g0ppp0ppp00g0ppp000kpppppk000ggg000gg0g0000gggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0pppp00gggg0kpppppppp0ppk00g0ppk0ppk00g0ppk00g0kpppp0000ggggg00gggggg00ggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg0pppp00ggggg0kkppppkk0kk000g0kk00kk000g0kk000gg0pppk000ggggg00j0ggggggggggggggggggggggggmggggggggggggggg
gggggggggggggggggggggggg0kppp00gggggg00kkkk00000000gg000000000gg0000000pppp000gmggg0kpkp0gggggggggggggggmggggggggggggggggggggggg
ggggggggggggggggggggggggg0kpp0000gggggg00000000g00ggggg00gg00ggggm000ppppk00000ggg0kpppkp0gggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggg0kkpppp00gggggg0000gggggggggggggggggggggg0kppkk000ppp0gg0kpppkp0gggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggg0ppppp99p0gggggggggggggggggggggggggggggggg0kk00000p9p0ggg0kpkp000ggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggg0pppp00pppp0000ggggg00ggggggggggggggggggg000000000pppk0000g0000000ggggggggggggggggggggggggggggggmgggggg
ggggggggggggggggggggggggg0ppp0000ppp0ppp0ggg0pp0gg0000gggg000gggg0pppppp0g0ppp000pp0000000g000000ggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggg0ppp0000ppppp9p0gg0p9p0g0pppp0gg0ppp0gg0ppppp99p00ppp00p9p0pppp0g0pppppp0gggggggggggggggggggggggggggggg
ggggggggggggggggggggggggg0pppppppppkpppp00g0pp9p0p99pp0g0ppp9p00pppk00kppp0ppp0ppp00pp9p00pppppp9p0ggggggggggggggggggggggggggggg
ggggggggggggggggggggggggg0ppppkkkkk0pppp00g0pppp0pppkpp0ppkppp00ppp0000ppp0pppppp000pppp0ppppkkpp9p0gggggggggggggggggggggggggggg
ggggggggggggggggggggggggg0pppp000000kppp00g0ppp00ppp0ppppk0ppp0pppp0000ppp0pppppp000pppp0pppp00kppp0gggggggggggggggggggggggggggg
ggggggggggggggggggggggggg0pppp0000000pppp00pppp0pppk0kppp00ppp0pppp0000ppk0ppp0pppp0pppkppppk000ppp00ggggggggggggggggggggggggggg
ggggggggggggggggggggggggg0kppp00gggg0kppppppppk0ppp000kpp00ppp0pppppppppp00ppk00kpppppp0pppp0000ppp00ggggggggggggggggggggggggggg
gggggggggggggggggggggggggg0kkk00ggggg0kkpppkkk00kpp0000k000kpp0ppppkkkkkk00kk0000kkkkkk0kpp00000ppk00ggggggggggggggggggggggggggg
ggggggggggggggggggggggggggg00000gggggg00kkk000000kk00gg00000kk0pppp0000000000000g00000000kk000g0kk000ggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggg000gggggggg00000000g0000gggg0gg000kppp00000000gg00gggg0000000000ggg00000ggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggg000gggggg00ggggggggg00ppk00gggggggggggggggggggggg00ggggg00gggggggggggggggggggggggggggg
ggggggmggggggggggggggggggggggggggggggggggggggggggggggggggggggggg00000ggggggggggggggggggggggggggggggggdgggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggg00gg000g000g000gg00g000gg00g000gg0ggg00gggggg00m0g0g000ggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggg0pp00ppp0ppp0ppp00pp0ppp00pp0ppp00p0g0pp0gggg0pp0p0p0ppp0gggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggg0p0p00p00p0p0p000p0000p00p0p0p0p0p000p000ggg0p000p0p00p00gggggggggggggggggg
gggggggggggggggggggggggmggggggggggggggggggggggggggggg0p0p00p00pp00pp00p0g00p00p0p0pp0000g0ppp00gg0p0g0p0p00p000ggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggg0p0p00p00p0p0p000p00g0p00p0p0p0p00g0g00p0ggg0p000p0p00p00gggggggggggggggggg
gggggggggggggggggggggggggggggggggggmggggggggggggggggg0ppp0ppp0p0p0ppp00pp00p00pp00p0p0ggg0pp000ggg0pp00pp00p00gggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggg0000000000000000g000g000000g00000ggg000g0gggg000g0000000gggggggggggggggggg
ggg00ggggggggggggggggggggggggggggggggggggggggggggggggggg000g000g0g0g000gg00gg0gg00gg0g0ggggg00ggggggg00gg00gg0gggggggggggggggggg
ggg00ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
g00j300ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
g00jj00ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
000lj000gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
kkkkkpp9000ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
pppkp99p9990gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
pkkpppp9p9990ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
kpppppppppp9900ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
kppppppp9ppkp00ggggggggggggd55gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
kppppppp9ppkp00l3jgg3j3g3ggd55ggggggggggggggggggggggggjl3jgg3j3g3gggggggggggggggggggggggggggggjl3jgg3j3g3ggggggggggggggggggggggg
kppppppkpppkp00jj3j3j3j3jd555555gggggggggggggggggggggjljj3j3j3j3j3jggggggggggggggggggggggggggjljj3j3j3j3j3jggggggggggggggggggggg
kppppppkpppkp00ljjjjjjjj3d555555ggggggjjggggggggggggjljljjjjjjjj3j3gggggggggggggggggggggggggjljljjjjjjjj3j3ggggggggggggggggggggg
kppppppkpkkpp00jjjjjjgjjj3jd55gggggggjjjgggggggggggglgljjjjjjgjjj3j3jggggggggggggggggggggggglgljjjjjjgjjj3j3jggggggggggggggggggg
pkkppkkpkpppp00jjjjjjjjjjj3d55ggjjgggjjgggggggggggjljljjjjjjjjjjjj3j3jggggggggggggggggggggjljljjjjjjjjjjjj3j3jgggggggggggggggggg
kkkkkkkklppp055jjgjjjjjjjgjd55jgjjjgjjjgggggggggggljljjjjgjjjjjjjgj3j3jgggggggggggggggggggljljjjjgjjjjjjjgj3j3jggggggggggggggggg
000000000000555gjjjjjjjjjjjd553ggjjgjjgggggggggggljljjjgjjjjjjjjjjjj3j3ggggggggggggggggggljljjjgjjjjjjjjjjjj3j3ggggggggggggggggg
000000000000000000000000000000000000000lggggggggljljjjjjjjjjjjjjjjjjj3j3ggggggggggggggggljljjjjjjjjjjjjjjjjjj3j3gggggggggggggggg
jjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jj3jjj3j0ggggggjljljgjjjjjjjjjjjjjjgjjj3j3gggggggggggggjljljgjjjjjjjjjjjjjjgjjj3j3gggggggggggggjl
jlljlllljlljlllljlljlllljlljlllllljljll0gggggjljljjjjjjjjjjjjjjjjjjjjjj3j3jggggggggggjljljjjjjjjjjjjjjjjjjjjjjj3j3jggggggggggjlj
llllllllllllllllllllllllllllllllllllll50ggggjljljjjjjjjjjjjjjjjjjjjjjjjj3j3gggggggggjljljjjjjjjjjjjjjjjjjjjjjjjj3j3gggggggggjljl
lll5ll5llll5ll5llll5ll5llll5ll5llllll5m0gggglgljjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggggglgljjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggggglglj
llllllllllllllllllllllllllllllllll5ll5m0ggjljljjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggjljljjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggjljljj
l5lllllll5lllllll5lllllll5lllllllllll5m0ggljljjjjjjjjjjjjjjjjjjjjjjjjjjjjgj3j3jgggljljjjjjjjjjjjjjjjjjjjjjjjjjjjjgj3j3jgggljljjj
lllllllllllllllllllllllllllllllldlllll50gljljjjgjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ggljljjjgjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ggljljjjg
llllllllllllllllllllllllllllllllllllll50ljljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ljljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ljljjjjj
lllllllllllllllllllllllllllllllllllll5m0jljgjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjgjjj3jjljgjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjgjjj3jjljgjjjj
llllllllllllllllllllllllllllllllll5ll5m0ljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3ljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3ljjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll55m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
dllllllldllllllldllllllldllllllll5ld55m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll55m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
lllldllllllldllllllldllllllldlllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
lllllllllllllllllllllllllllllllllllll5m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllll5ll5m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll55m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
dllllllldllllllldllllllldllllllll5ld55m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll55m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
lllldllllllldllllllldllllllldlllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
lllllllllllllllllllllllllllllllllllll5m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllll5ll5m0jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj

__gff__
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000000000000001010000818a0606060000000000000a050a0a0a0a060606000000000002020a0a0a0a0a0a0000000000000a0000020a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a0200000000000a
00000000020200000000000000000000000000000202020200000000000000000000000a0002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2a2b000102007677787777780a0b107677787979795200500708094042002c2d373839104a4b4c4d10070809ecec7dd87ed97d001d0c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b001112005051525151521a1b1050515266666652005017181960620000007071724a4b5b5b4c4d174f19fcfd00000000001d0d6a0e1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738397072005551545151521010106061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829e1e2e3e40000000d6a6a6a0ec0c1c1c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe129003528be880b8c0cbb51bbb8b0a81a8384f1a222b129a02abf028333300436b7319b9c1ca733b43c722a363d35943e3daf70a17121bfbca09b12930ffc69f99f9db626e2486e7aef2f9efde4fc3f13893e713f2fc784fc38fcedd7ff1bf3ffc8b6fe9fafe87e2e3f6fd7f5fd4bf7bfba7f073f9cb7f9e7
87f5c4feffce4fc161fa4ff5b7e88ffd8e8ff93c9c8ebce7f5ffc1495f5e5fb27fe149c71fbdffc5dbf39fbffe34fe6ce2ffe3bff4eaffe4ffcb3ff007fe3afd373bff1ffe3affcdd5ffc3fd7fe0d7ff3ffe8ffd274e3ff571f85727e53ff0bf29fb7fc7e9dcfc1c4ffd7ffb3bb245fdfff6cfce7fe17f2e3b8ffd4dffbb7eee
8fc8fce039dd7dfb389fe7f9f859ffbf4bfcf1a5fea71b7fefffdbff80138733a7b3c70b31fcbf8dbff41ff8abff87ff193ff95d2d92dda7e3ff9fff9c7fe21c1edea708a3815e4ef87fe2b27ed0fd01f8cffe925ffea25be4fe627ff65311f8fa54e48e87282aa59df1fa7ff79117fa392953f1503c2a71c71ff8fa4e61f6e3
ffc09ffe58ee7ec5ed3f79fbf6772c9c495fc83f0257fe40e24bc5fcbffc3d7c9f7327ffa9fd9af5dce7afbefc7f1fd7f5fd7a73c497f12bd1f93ff0707527f3dcfc7f149ff8d3f38bd7e0a7133f2df83ff27fe6e5ffc53ffd97ffe7ffcfff9d3ffe54e9fcd3abffcfff4fff3fca3ffc1fd4dc5e4ae6413927e8e67fbff9a4fd
ce7f0fcbf281a4df8f270fa4fe7fd1c3ffe1cc7ecdf8c8c59ffeac82fe33ffea7ff975474fc4fdaee3f37fe1237fe3fdbff1d769cff6ff1a16162c271fb7edfca680b1b128f5ffec9d6d3d4907e2c93aa53ddf97ebcce1fff8ffcff871fffc0fcbff27fff05c9a4b67e7f9f2913b420849772717f3fd3f5b7fdffd5ff593f173
ffaa7f4bdc894f6bfff82eae7e287877c697575fbfeefe7f4ffd4e50fdecd13fdfffbca087fb09c1aa3ce0f10e39bf8ff3674ffdbffa3ff4ffeafefdfc640824726a768179c2fffd1399c5ed2a767a74096d7fe999f47feefc803b3d3a04b6bff4ccfa3ff7fe4000000000000000000000000000000000000000000000000000
fffff87fd3bffd6a400c0c28aa2a0de4688c4bcfe6e70723c7ce6a6a883c480aac6c8e4e0845c0c6a866cb8fafc2495b71c71273d5d7bbc74e35f3d9fb4f9307d38e36e3df6e9f83f19ef52756a7e6bccfc3973f8fe5f9f7f9f80f0d27e0b3df74e38fd9f8fedd731d3cfca3c5dc61e4da3cb568fd04fd1cd95fa3affd13f576
de70fa6773f057e3a47f53f657efc6e1559522713ff96693d54f215bf01d613f59fc7f3276bbf2f3cf2464945123ffa51f855b626dec95485fcecfd28e4f61fbcfe9e97378fc41f8899ecfeffcfea271fbffb666b2ac9047e7d7fdff81ff87affc5784a1fd7e6ff7f2e12f2f27e9533f5d274eca009617e9f34ff536ffa3a58f
e6493e7df9afd7fe931f9d9567fe3750ff841a755c4faed5269527293f149524491102449c0fcd387ed7ff27fe4ffc9f94b167309cc8fcab989c35fdb9e66e4efff4f1cba9cf09fe7925fc3f0fc272391f94ffcae3bf387480e0b117d8d3c7fe221fcc99377a7f57a6fd67fe6bc2339e10b274e6bc7fbff9e7e3f8f97c93f224
f6fe49d4ea631f9c9c21649c4f927c93a7cfdb99ea1e4aa7fe3bffa38e891c92b914fce1bc72e1bcf62fcffd2359ffaa789c3c93c49f24f95df93b927fe84848484876f65910c7e90c90061ecdf97934962fe30f2447fe1ff1bc2a7e723f491a05ed2c11bff0baff4fc0fcc0bc7fbffef93b9fffca241fffcba9fd139fffe67f
e7ff7fdffcc5ff7ff57fd2fff07e09ff8b893e6896c923ff0aa35ffc5ff8bfff9abff8fff037cfc3f0fc3f0ffe3fffcefe3c93913fff9fc92c739fffd0b3ffe18fdbfffa34fe84cea0b27bf8ef44cfffe17effffc25a99fffd2cfffe9faf13a75213f57d3fffa9fffd58fffe79f777f5ff6fee00000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe40028a90c0cbebf0bab2cabac2833b42230b1038404a323a434f122b324bb2ae060e13bd1bc130a940b12e1e23fb03c9493a525a72daa212d2fa7b970a0831c1ca01afff53db2e6e38e493a389d77e7bf75cf367964b78e3f0bf8fe53f697f289ffe8ef8fcff4fd7bf5cfedfbff0fe7fa93fb39fe3fcfe3f8
7e7f9bf64fe3f8b1fd49fddf93f29febff84913feabff7fe0fced9227edff85c3f7fdff8e9c79ef1a621c4ffc5ff8ef5ff93ff2ffe6fe0ff8be9e5ffcfffa1c4ffd353ef93ebfe4b52d8ffd125fee4fc09fad67edfbffea68bfe2449ffafff638ffdb7ff77f4e77fe3ffcfffa11fcee3ff6dffdcff36fc1fe3f434ffc7ffb97f
f27fefffe0259df7a777f8e7f2fcbf2febff8c127ff2c124e1ffcd3fc38fa7febffe9fd38ffebffb7f04e932b7e5ffa3ff3ffe75ffcfff9fff3a7fe7ffcf67fe9e393f14393a91ff889110d3bed3bb25b25b916fff6ffeebf898a72bcceff09bff17ff1e967f1ffe29dc93ff31ca7b3df72682fbefa26ffedff7ff90e273f84b
ffa8bc5ffc519b5ffe9b89fafea7ea7fe8874831d4ffcffb59ffa28fc2fffafff6d51c1db7422241fff2d4bc24dffebff5a55fca486c720fc67ffd1fffbf57fe5fe06febbefb5416c1373dcb2cffdcffc155c1f973ffd7ffafffe7fed7e7adfffe024ecfaee927f68902700ee7fff04593f21ffa004fcd2fbe709e50e3f6fde7
fe72525fc39384e4eb82f2fc62f66052dadaa33c5b7f08bd24ab3f07fe43f73737ff1fe2f1fffc2e27ffc9fe4249754d27139b3a8e09d3f3878a4e92c8b5dffeaaffd12ffeafcdf5ffc7effff0fbddeffebffd64cabf8dc713bed3badff87ff0ff6709fffc4fffe2f1c253f3926bea7643d7ff1f44fffe1fde237407e3cffff1
affff0fff9048e34f20e1c7fc72770ff62e7fff1e179edff5fffbbd4b67f717f5fd2b9e7ba11f88bc7fe2ffc7feff0256fdb05be1ff9e4baff1ff87f8acaffdce4e13cbfffc2fffd1399c5ed2a767a74096d7fe999f47feefc803b3d3a04b6bff4ccfa3ff7fe4000000000000000000000000000000000000000000000000000
fffff87fd3bfffef51bbbc003b28a9332837a20322bfa73070bef13f31038404f8130c2f8a948ba78cff13940b30b536b733b4363d35a323a43e3daf2b2ba4ac1b9c1cacb4b8208e860e2e0687082525a626f99aef2a2dbcaaa1a0772d2eba38aa5fffe2cd533b71c4e7a4efce1dffe4bef1f7fff1b86fc2711d49f8ba9d7e4b
f9f3cffe9bc733f3dfa3f55dfb21c7efa57fe6e7bfc78924b0e6f7fc752fb27fe84fcf5fe7fafe9d7f7fe71fa7f5f9fee9cf2dcb9e3ff3f9ca71c670e2f1fc77b2733ffb74ff7feffc1ff87ff172eff3b25ffc689ff93ff2ffea70927487fe6e627ff7e7ff3ffe8ffd3fccd7935ee2febfbfedffb7bffd5658b51fb72ee2ffe6
7febfc67feca7ef1394d27f3ff8a7fedbdbff5cdffab99484edbff43d97f3fc25b248ffdde83ff43ff7f9a421f213ff3dffe1ffc7ff9492126926fa1f8cffe7ffd24ffeb7f4efc926db1a593ff94df93f2747fe8cffed3ffbff8f3b9ffe0e0fff3ffebffd9fff3ff2f67ffdfffdfffc0fffdfffa74bff9a7f4ffc97efa1fb6bf
b7fff07f63f6ffcafd09f43ff33f2e6f2ea1aed2d927eb3fff85fbfff6bfffc3fffe2479f87d24924feaf7fc45ffd1fa467fe620e787fff17fff8dfffc7becea733fff91fffc83fff907fff207e653c750fc5ffaa6fe7fbfdbf9b3fb7f3bf5bfbffe5438af311cf7fffc9ffeffffcaea24ed2dfbf177f4927fff2ffff99fffcd
fffe77fff3f39db6dc713df669fca4d6efd93fffa1ba9fffd14a8483fffa553fa273fffd3ffd1ff7fdffa0bff7febffc6cffe4fc93ff27127e2d12d9247fe6546bff93ff27fff517ff2ffe26edf97e5f97e5ffcffffabfcb49e4c27fff5b94fc39ea7fff5fd97fffb1fffd631fc7fff669fd099d4164f7f1de899fffc8fdffff
90b533fffb59fffdbf5ea74ea427eaf67fff73fffbb37fafbf1eefe6bfb8d13fdfffbca087fb09c1aa3ce0f10e39bf8ff3674ffdbffa3ff4ffeafefdfc640824726a768179c2fffd1399c5ed2a767a74096d7fe999f47feefc803b3d3a04b6bff4ccfa3ff7fe4000000000000000000000000000000000000000000000000000
__sfx__
000100001505016050180501a0501c0501e0502205027050261501600016000160001600017000330000000035000380003900000000000000000013000000000000000000000000000000000000000000000000
0001000023160211501c15016140121300d1300c11013000130001b60013000130000000013000130001300013000000000000000000000000000000000000000000000000000000000000000000000000000000
30020e001d6701517013160101500d1500a1400914007130061200511005100130000000013000130001300013000000000000000000000000000000000000000000000000000000000000000000000000000000
000308000e65011640146401763019620146100d6100b600096000960000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020700323502c350293502735025350213503030034550365503855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a000e2755027550275501d550275502755027550275501c5502755027550275502755027550216500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00081300026350000002b3501a350000001935000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006080000000270502a0502c0503005032050370503b0503f0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 06074344

