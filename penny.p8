pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--penny the pumpkin
title_y=8
label=false

max_coins=18
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
	important=true,
	x=0,
	y=0,
	dx=0,
	dy=0,
	w=8,
	bounce=0,
	size=14,
	speed=.2,
	pumpkin=true,
	h={
		x=0,
		y=0,
		important=true,
		head=true,
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
  dget(60), dget(59), dget(58)
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

end
function reset_pal()
	pal()
	palt(0,false)
	palt(1,true)
	pal(blocks.pal, 1)
end

function draw_entity(e,pal_overide,x,y)
	for d in all({
		{-1,0,true},
		{1,0,true},
		{0,1,true},
		{0,-1,true},
		{0,0,false}
	}) do
		if pal_overide or d[3] then 
			pal(pal_overide or {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
		else
			reset_pal()
		end
		skw_spr(
			e.x+(x or 0)+d[1],
			e.y+(y or 0)+d[2],
			e.h.x+(x or 0)+d[1],
			e.h.y-((blocks == level9 or e.pumpkin) and 4 or 0)+(y or 0)+d[2],
			e.w+4,
			e.pumpkin and 80 or blocks == level9 and 80 or  8,
			e.pumpkin and 16 or blocks == level9 and 0 or 0
	
		)
	end
end

function draw_player(pal_overide,x,y)
	draw_entity(player,pal_overide,x,y)
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
		foreach(enemies, draw_entity)
			
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
			draw_player({[0]=9,9,9,9,9,9,9,9,9,9,9,9},0,-8)
			draw_player({[0]=7,7,7,7,7,7,7,7,7,7,7,7},0,-4)
		end
		draw_player()

		if is_halloween() then
			skw_spr(
				player.x,
				player.y,
				player.h.x,
				player.h.y-4,
				player.w+4,
				96,
				112,
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
	
	if hud_y<=-24 then
		hud_pos=nil
	elseif hud_pos == nil then 
		if player.y - cam_y > 80 then
			hud_pos=⬆️
		else 
			hud_pos=⬇️
		end
	end
	local hud_h=25
	if hud_pos==⬇️ then
		camera(0,hud_y)
	else
		camera(0,128-24-hud_y)
	end
    fillp(▒)
	rectfill(0,128-hud_h, 128, 128,0)
    fillp(0)
	if hud_pos==⬇️ then
		rectfill(0,128-hud_h+4, 128, 128,0)
	else
		rectfill(0,128-hud_h, 128, 124,0)
	end
	sspr(24,0,16,16,3,108,16,16)

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
	
	draw_logo()
end

function draw_logo()
	if title_y > 128 then
		return
	end
	local x=30
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
			print("happy halloween",v[1]+24,v[2]+32,9)
		else
			if time()%3 < 1 then
				print("director's cut",v[1]+24,v[2]+32,9)
			elseif time()%3 < 2 then
				print("music by packbat",v[1]+18,v[2]+32,9)
			else
				print("game by kai salmon",v[1]+12,v[2]+32,9)
			end
		end
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
		load_level_instant(blocks,blocks.px,blocks.py,blocks.pdx,blocks.pdy)
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
		for i=1,#animated_tiles do
			local x, y = animated_tiles[i].x, animated_tiles[i].y
			local tile_id = mget(x, y)
				
			if fc%10 == 0 then
				if tile_id == 62 then mset(x, y, 30)
				elseif tile_id == 46 then mset(x, y, 62)
				elseif tile_id == 30 then mset(x, y, 46)
				end
			end
			if fc%10 == 0 and tile_id >= 208 and tile_id <= 211then
	  	mset(x, y, (tile_id+1)%4+208)
			end
			if (fc+x*123+y)%40 == 0 then
				if tile_id == 60 then mset(x, y, 126)
				elseif tile_id == 126 then mset(x, y, 60)
				elseif tile_id == 61 then mset(x, y, 125)
				elseif tile_id == 125 then mset(x, y, 61)
				end
			end
		end
	update_dust()
	update_cpu_usage = stat(1) - stat_1
	local height =player.y-player.h.y
	if player.gnded or player.prev_block then
		if btnp(⬇️) and height>8 then
			sfx(57,3)
		elseif btnp(⬆️) and height<14 then
			sfx(58,3)
		end
	end
	if player.last_gnded_y != "override" and will_smash(player) then
		sfx(59,3)
	else
		sfx(59,-2)
	end
end

function update_coin(c)
	 if player.x+player.w/2>c.x-8
		and player.x-player.w/2<c.x+8
		and player.h.y>c.y-16
		and player.h.y<c.y then
			del(coins,c)
			sfx(56)
			dset(c.id, 1)
			sr_coins[c.id]=true
			coins_collected+=1
			coin_at=time()
			set_checkpoint(blocks,c.x,c.y-5,0,0,16)

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
      sfx(63)
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
			sfx(63)
		end
	end

	ch.dx -= (0.1 * ch.dx) * t_scale
	ch.dy -= (sgn(ch.dy)
	* air
	   * ch.dy 
	   * ch.dy) * t_scale
	ch.h.dx -= 0.04 * ch.h.dx * t_scale
	ch.h.dy -= 0.05 * ch.h.dy * t_scale
	local h = ch.size * ch.stretch * (ch.pumpkin and 1 or 1.1)
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
		eject_particle(ch.h,false, 0.5, 1)
		if (ch.y != ch.h.y+min_h) then
			ch.y = ch.h.y+min_h
			ch.dy *= -1 * ch.bounce
		end
	end

	ch.block=nil
	update_particle(ch, ch.dy >= 0)
	update_particle(ch.h, false)
	update_character_w(ch)
	check_for_squeeze(ch)

	local max_h = ch.size*ch.stretch*1.5
	if ch.h.y + max_h < ch.y then
		ch.h.y = ch.y-max_h
		eject_particle(ch.h, false, 0.5, 1)
	end	

	ch.was_gnded = ch.gnded
	ch.prev_block = ch.block
	ch.prev_h = ch.y-ch.h.y
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
	ch.w = tw
	ch.h.w = ch.w
end

function skw_spr(x,y,hx,hy, w, sx, sy, flip)
	local h = y-hy+1
	if (h<0)h=0
	for i=1,h do
		local s = i/h*16
		local skew_x=lerp(x,hx,i/h)
		sspr(sx,sy+16-s,16,1,skew_x-w/2,y-i+1,w,1, flip)
	end
end

function on_land(p)
	if(p.dy > 2) then
		for i=0,20 do add_dust(p,2,2) end
		
		if will_smash(p) then
			shake=25
			sfx(62)
			if p.block.on_crash then
				p.block:on_crash()
				return true
			end
		else
			sfx(61)
		end
	end
end

function die()
	if died_at then
		return
	end
	if (debug) return
	sfx(60)
	died_at = time()
	for i = 0,15 do
		add_dust(player, player.dx,player.dy,true,55)
	end
end
-->8
--physics
function check_for_squeeze(p)
	if is_solid(p.x,p.y) then 
		return false
	end
	while true do
		local right_col = is_solid(p.x+p.w/2+1, p.y) or is_solid(p.h.x+p.h.w/2+1, p.h.y)
		local left_col = is_solid(p.x-p.w/2-1, p.y) or is_solid(p.h.x-p.h.w/2-1, p.h.y)
		p.w-=1
		p.h.w-=1
		if right_col and left_col then 
			if 	is_solid(p.h.x, p.h.y-1) then 
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

-- function get_solid()
-- 	for x=cam_x,cam_x+128 do
-- 		for y=cam_y,cam_y+128 do
-- 			pset(x-cam_x,y-cam_y,is_solid(x,y) and 8 or is_solid(x,y, true) and 12 or 3)
-- 		end
-- 	end
-- end

function is_colide(x,y,w, inc_semi)
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
	
	for _,y2 in ipairs(ys) do
		for i,x2 in ipairs(xs) do
			local b,tile = is_solid(x2,y2,inc_semi)
			if(b)return b,tile
		end
	end
	return false
end

function eject_particle(p,inc_semi, x, y)
	if(not p.important) return
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
	eject_particle(p,p.dy>=0 and not p.head, 1, 1)

	x_col = is_colide(p.x+p.dx*t_scale,p.y,p.w,false)
	if not x_col then
		p.x += p.dx*t_scale
	else
		p.dx *= -1
		p.dx *= p.bounce or 0
	end
	
	p.dy=min(p.dy,4)
	p.dy=max(p.dy,-10)

	y_col,tile = is_colide(p.x,p.y+p.dy*t_scale,p.w,inc_semi)
	if not y_col  then
		 p.y += p.dy*t_scale
	else
		local override_bounce = false
		if p.important then
			if p.dy > -.1 then
				p.block = y_col
			end
			if p==player or p==player.h then
				if fget(tile, 7) and not fget(tile, 1) then 
					die()
				end
				if fget(tile, 7) and fget(tile, 1) then 
					die()
				end
			end
			if p.on_land  then
				override_bounce = p.on_land(p)
			end
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
	if stat(7)<60 then
		deli(dust, 1)	
	end
	if #dust > 30 then
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
local chunk_size=6
crash_breakable =  function(b)
	b[3]=0
	if b.key then
		broken_blocks[b.key] = true
	end
	for i = 0,35 do
		add_dust({x=b[5]*8+8,y=b[6]*8+8,w=16},0,0,true,55,"coin")
	end
	local x = -5
	player.dy=x
	player.h.dy=x
	sfx(56)
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

function drop_island(b)
	drop(b)
	if b.t < 42 then
		local dy = sin(t/2+b[5]*5.314)/50
		b[6]+=dy
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
forest_instrument=0xe58
level1={
	px=20,
	py=100,
	instrument=forest_instrument,
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
        load_level(level6, 5, 100)		
    end
end
level2={
	pal=forest_pal,
	instrument=forest_instrument,
	chunk=3+chunk_size*0,
	e={
		{x=30,y=25, minx=175, maxx=270},
		{x=22,y=15, minx=133, maxx=222}
	},
	c={
		{x=33,y=17,id=2},
		{x=22.5,y=10.5,id=3}
	},
	blocks="1:6,2:5,3:48,4:3,5:0,6:-3,update:level2_adj,fill:3,colide:false|1:115,2:18,3:6,4:1,5:35,6:16,colide:false|1:32,2:5,3:16,4:9,5:-0.5,6:0,colide:false,rx:4|1:32,2:12,3:16,4:1,5:-0.5,6:8,rx:4,ry:9,colide:false|1:82,2:8,3:2,4:3,5:2,6:16,colide:false,rx:20|1:18,2:0,3:48,4:13,5:0,6:19,colide:false,fill:4|1:48,2:3,3:16,4:16,5:0,6:0|1:32,2:14,3:5,4:4,5:6,6:6|1:64,2:3,3:48,4:16,5:0,6:16|1:112,2:3,3:16,4:16,5:32,6:0|1:103,2:11,3:1,4:1,5:16.5,6:15,colide:false,front:true|1:106,2:3,3:4,4:4,5:0,6:28,colide:false,front:true|1:31,2:18,3:1,4:1,5:31,6:14,front:true,rx:3,ry:3,colide:false|1:25,2:8,3:3,4:5,5:21,6:11|1:21,2:11,3:1,4:2,5:20,6:14|1:27,2:0,3:2,4:2,5:7,6:28,on_crash:crash_breakable,key:level2_breakable|1:37,2:14,3:7,4:4,5:28,6:12"
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

local tunnel_instrument = 0x5d7
level3={
	px=16,
	py=-16,
	pal=tunnel,	
	instrument=tunnel_instrument,
	chunk=3+chunk_size,
	c={
		{x=2.5,y=4,id=4},
		{x=45.5,y=10,id=5},
		{x=76.5,y=13,id=6},
		{x=13.5,y=12.75,id=18}
	},
	e={
		{x=86.5,y=11, minx=675, maxx=760, maxy=103},
	},
	blocks="1:0,2:0,3:0,4:0,5:0,6:0,draw:level3_draw|1:32,2:1,3:3,4:1,5:30,6:10,update:drop|1:32,2:1,3:3,4:1,5:36,6:8,update:drop|1:0,2:3,3:58,4:16,5:0,6:0,update:level3_adj|1:32,2:1,3:3,4:1,5:60,6:5,update:drop|1:32,2:1,3:3,4:1,5:67.5,6:3,update:drop|1:27,2:13,3:16,4:6,5:58,6:5|1:58,2:3,3:50,4:16,5:74,6:0|1:0,2:0,3:0,4:0,5:0,6:0,draw:level3_halo,front:true"
}

town_instrument = 0xf58

level4_adj = function()
    if player.y>264 then
        load_level(level3, 971, 0, 0, 0)
    elseif player.x < -3 then
        if player.y < 150 then
            load_level(level6,240,player.y-25)
        else
            load_level(level6,195,215,0,0,2)
        end
    elseif player.x > 388 then
        load_level(level5, 0, player.y < 30 and 23 or 79)		
    end
end

level4={
	chunk=3+chunk_size*2,
	pal=day,
	instrument=town_instrument,
	c={
		{x=4, y=23, id=7},
		{x=44, y=15, id=8},
		{x=27, y=3.5, id=9},
		{x=39, y=27, id=13},
	},
	e={
		{x=44, y=15, 
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
    cam_x=max(0,cam_x-1.75)
	cam_bounds[3] = -50
   	cam_bounds[2] = 254
    if player.x < 0 then
        load_level(
            level4,
            378,
            player.y
        )
    end
end
level5={
	chunk=3+chunk_size*2,
	pal=sea_pal,
	instrument=town_instrument,
	e={
		{x=15,y=11,miny=20, maxy=100, minx=80, maxx=220},
		{x=24,y=9,miny=20,  maxy=100, minx=180, maxx=250},
		{x=33,y=11,miny=20,  maxy=100, minx=250, maxx=330}
	},
	c={
		{x=45.5,y=10.5,id=10},
		{x=4,y=-4,id=17},
	},
	blocks="1:35,2:0,3:6,4:3,5:4,6:5,colide:false,rx:9|1:35,2:0,3:48,4:8,5:0,6:8,colide:false,fill:6|1:111,2:9,3:6,4:5,5:19,6:2,update:drop_island|1:41,2:0,3:3,4:3,5:13,6:-1.5,update:drop_island|1:111,2:9,3:6,4:5,5:11,6:11,update:drop_island|1:111,2:14,3:7,4:5,5:17,6:7,update:drop_island|1:41,2:0,3:3,4:3,5:12,6:5,update:drop_island|1:96,2:3,3:15,4:11,5:0,6:0|1:96,2:14,3:15,4:5,5:0,6:11,front:true|1:100,2:16,3:11,4:3,5:15,6:13,rx:4,front:true|1:6,2:0,3:3,4:3,5:44,6:12,update:level5_adj|1:11,2:6,3:4,4:6,5:2,6:-3|1:118,2:3,3:4,4:16,5:50,6:0"
}
level6_adj=function()
    if player.x < -2 then 
        if player.y<15 then
            load_level(level7, 295, 5)
        else
            load_level(level2, 375, 39)
        end
    elseif player.x > 258 then
        load_level(level4, 16, player.y+15)	
    end
    if player.y > 125 then
        manual_cam = true
        if(not broken_blocks.level6_breakable) then 
			level6.pal=tunnel
			update_note(1,0,tunnel_instrument)
		end
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
		{x=10,y=87/8, maxy=0,minx=75, maxx=85}
	},
	c={
		{x=10,y=5, id=11},
		{x=104/8,y=190/8, id=16}
	},
	blocks="1:0,2:0,3:0,4:0,5:0,6:0,draw:level6_bg|1:16,2:16,3:32,4:16,5:0,6:-8,colide:false,fill:14|1:16,2:15,3:32,4:5,5:0,6:-3,colide:false,fill:6|1:48,2:16,3:16,4:3,5:0,6:-6,rx:2|1:16,2:15,3:19,4:4,5:1,6:-2|1:16,2:15,3:32,4:4,5:1,6:2,colide:false,fill:3|1:37,2:12,3:4,4:7,5:9,6:-8|1:80,2:3,3:16,4:16,5:9,6:16|1:64,2:3,3:16,4:16,5:16,6:0|1:96,2:14,3:12,4:5,5:19,6:-5|1:27,2:0,3:2,4:2,5:16,6:14,key:level6_breakable,on_crash:crash_breakable|1:0,2:3,3:16,4:16,5:0,6:0,update:level6_adj|1:0,2:0,3:0,4:0,5:0,6:0,draw:level6_halo,front:true"
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
level7_island=function(b)
	local dy = sin(t/2+b[5]*5.314)/50
	b[6]+=dy
end
level7 = {
	pal=day,
	instrument=town_instrument,
	chunk=3+chunk_size*3,
	e={
		{x=55/8,y=2,size=5, miny=100,minx=35, maxx=60, pumpkin=true},
		{x=65/8,y=2,size=5, miny=100,minx=35, maxx=60, pumpkin=true},		
		{x=45/8,y=2, miny=100,minx=35, maxx=60, pumpkin=true}
	},
	c={
		{x=55/8,y=-3, id=12},
	},
	blocks="1:16,2:15,3:37,4:5,5:0,6:-3,update:level7_adj,fill:6,colide:false|1:16,2:15,3:37,4:4,5:0,6:2,colide:false,fill:3|1:48,2:16,3:16,4:3,5:-11,6:-6,rx:3|1:16,2:15,3:21,4:4,5:-26,6:-2,rx:3|1:16,2:13,3:21,4:2,5:-26,6:4,rx:3|1:41,2:11,3:7,4:8,5:3,6:-2|1:37,2:12,3:4,4:7,5:15,6:-4,update:level7_sin1|1:29,2:5,3:6,4:5,5:14,6:-6,update:level7_island|1:37,2:12,3:4,4:7,5:25,6:-5,update:level7_sin2|1:16,2:5,3:6,4:5,5:24,6:-7,update:level7_island|1:24,2:5,3:5,4:6,5:32,6:0",
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
	fillp(-23130.5)	
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
local spooky_instrument=9304
level8={
	px=17,
	py=17,
	pal=spooky_pal,
	instrument=spooky_instrument,
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
		manual_cam=true
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
	instrument=spooky_instrument,
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
for i=0,15 do
	add(stars,{rnd(150)-50,-50-rnd(32),0})
	add(stars,{rnd(150)-50,-82-rnd(32),0})
	add(stars,{rnd(150)-50,-114-rnd(32),0})
	add(stars,{rnd(150)-50,-146-rnd(32),0})
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
	cam_bounds[3]=-200
	local t=(time()-last_level_load_at)/5
	if player.y < -15 then 
		manual_cam=true
		cam_x=-30
		if t < 1 and been_level1_v_down != true and (not speedrun or speedrun_t > 45) then
			cam_y=lerp(-190,-150,-6*(t*t*t/3-t*t/2))
		else
			cam_y=-150
		end
	else
		been_level1_v_down = true
		manual_cam=false
    end
end
level1_variant={
	px=20,
	py=100,
	pal=spooky_pal,
	instrument=spooky_instrument,
	chunk=3+chunk_size*0,
	c={
		{x=17,y=2.75,id=1}
	},
	blocks="1:41,2:0,3:3,4:3,5:10,6:-18,update:level1_v_cam,draw:level1_v_draw|1:51,2:0,3:5,4:3,5:-4,6:-7,colide:false,rx:9|1:51,2:0,3:36,4:4,5:-4,6:-4,colide:false,fill:3|1:0,2:3,3:1,4:3,5:0,6:-3|1:9,2:0,3:5,4:19,5:-5,6:-3,colide:false,fill:5|1:9,2:0,3:2,4:3,5:-4,6:-6|1:9,2:0,3:3,4:3,5:-2,6:-6|1:46,2:0,3:5,4:1,5:-4,6:-7,colide:false|1:32,2:5,3:16,4:9,5:0,6:0,colide:false,rx:2|1:32,2:12,3:16,4:1,5:0,6:8,rx:2,ry:5,colide:false|1:15,2:9,3:4,4:3,5:15,6:9,colide:false|1:0,2:3,3:32,4:16,5:0,6:0,update:level1_adj|1:27,2:0,3:2,4:2,5:1,6:12,key:level1_breakable,on_crash:crash_breakable"
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
-->8
--level loading

function is_solid(x, y,inc_semi)
	for b in all(blocks) do
		if b.colide != false then
			local w,h=b[3]*(b.rx or 1), b[4]*(b.ry or 1)				
			if x/8 > b[5]
			and x/8 < b[5]+w
			then
				if y/8 > b[6]
				and y/8 < b[6]+h
				then
					local tile = is_solid_in_block(b,x,y,inc_semi)
					if tile then
						return b, tile
					end
				end
			end
		end
	end
	return false
end

function is_solid_in_block(b, e_x, e_y, inc_semi)
	if b.rx then
		e_x-=b[5]*8
		e_x%=b[3]*8
		e_x+=b[5]*8
	end
	if b.ry then
		e_y-=b[6]*8
		e_y%=b[4]*8
		e_y+=b[6]*8
	end
	local x = e_x/8 + b[1] - b[5]
	local y = e_y/8 + b[2] - b[6]
	local tile = mget(x,y)
	if fget(tile, 2) then
		if(not inc_semi) return false
		if(y % 1 > 1/2) return false
		return tile
	end
	if fget(tile, 0) then
		if(y % 1 < 1/2)return false
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
		if b.update != drop and b.update != drop_island and b.colide!=false then
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

function set_checkpoint(level, x,y,dx,dy,h)
	if x != nil then
		level.px = x
	end
	if y != nil then
		level.py = y
	end
	
	level.pdx = dx or 0
	level.pdy = dy or 0
	level.ph = h or 16
	
	for i, v in ipairs(levels) do
		 if v == level and not speedrun then
		 	dset(63, i)
		 	dset(62, flr(level.px/8))
		 	dset(61, flr(level.py/8))
		 	dset(60, flr(level.pdx))
		 	dset(59, flr(level.pdy))
		 	dset(58, flr(level.ph))
		 	break
		 end
	end
end
function transition(func)
    transition_function = func
    wipe_progress = 0  -- start wipe effect
end

function load_level_instant(level,x,y,dx,dy,h)
	dx=dx or 0
	dy=dy or 0
	last_level_load_at=time()
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
	set_checkpoint(level, x,y,dx,dy,player.y-player.h.y)

	blocks=level
	for b in all(blocks) do
		if broken_blocks[b.key] then 
			del(blocks,b)
		end
	end
	calc_cam_bounds()
	
	player.x = level.px or player.x
	player.y = level.py or player.y
	if player.last_gnded_y != "override" then 
		player.last_gnded_y = player.y
	end
	player.h.x = player.x
	player.h.y = player.y-4
	player.dx = dx
	player.dy = dy
	player.h.dx = dx
	player.h.dy = dy
	
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
	
	if not manual_cam then
		cam_x = player.x - 64
		cam_y = player.y - 64
	end
	manual_cam=false
	check_for_squeeze(player)
	--eject_particle(player,false, 1, 1)	
	
	if #coins == 0 and blocks!=level1_variant then
		coin_at=time()
	end

	animated_tiles = {}
	for x=0,128 do
		for y=3,19 do
			local tile_id = mget(x, y)
			if tile_id == 62 or tile_id == 46 or tile_id == 30 or
				tile_id == 208 or  tile_id == 60 or tile_id == 126 or tile_id == 61 or tile_id == 125 then
				add(animated_tiles, {x=x, y=y})
			end
		end
	end
	if level.instrument then
		update_note(1,0,level.instrument)
	end
	
	if(dget(57) == 1) then
		mute()
	else
		unmute()
	end
	update_camera()
end

function load_level(level, x, y, dx, dy, h)
	if blocks == level then
		load_level_instant(level, x, y, dx, dy, h)
	else
		transition(function()
			 load_level_instant(level, x, y, dx, dy, h)
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
		important=true,
		pumpkin=e.pumpkin,
		maxx=e.maxx,
		minx=e.minx,
		maxy=e.maxy,
		miny=e.miny,
		dx=0,
		dy=0,
		w=8,
		bounce=0,
		size=e.size or e.pumpkin and 12 or 14,
		speed=0.07,
		jumpf=-4.5,
		h={
			x=e.x*8,
			y=e.y*8-14,
			head=true,
			important=true,
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
	cartdata("kai-pumpkin-2-v1-1")
	music(0,500)
 	poke(0x5f5c, 255)
	if(label)poke(0x5f2c,3)
	poke(0x5f34,0x2)
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
	level1.px=25
	level1.py=90
	load_level_instant(level1,level1.px,level1.py)
end

function is_halloween()
    local month = stat(91)
    local day = stat(92)
    return (month == 10 and day >= 25) or
           (month == 11 and day <= 7)
end
function num2hex(number)
    local base = 16
    local result = {}
    local resultstr = ""

    local digits = "0123456789abcdef"
    local quotient = flr(number / base)
    local remainder = number % base

    add(result, sub(digits, remainder + 1, remainder + 1))

  while (quotient > 0) do
    local old = quotient
    quotient /= base
    quotient = flr(quotient)
    remainder = old % base

         add(result, sub(digits, remainder + 1, remainder + 1))
  end

  for i = #result, 1, -1 do
    resultstr = resultstr..result[i]
  end

  return resultstr
end

function update_note(sfx_id, note_i, new_note)
	local sfx_addr = 0x3200 + sfx_id * 68
	local note_addr = sfx_addr + note_i * 2
	local note = peek2(note_addr)
	poke2(note_addr, new_note)
end

function toggle_mute()
	if muted then
		unmute()
	else
		mute()
	end
end

function mute()
	muted=true
	dset(57, 1)
	update_note(1,0,0)
	update_note(0,0,0)
	menuitem(1,"unmute music", toggle_mute)
end
function unmute()
	muted=false
	dset(57, 0)
	update_note(1,0,blocks.instrument or forest_instrument)
	update_note(0,0,3608)
	menuitem(1,"mute music", toggle_mute)
end

__gfx__
000000001111111111111111111110000001111144499444005555605000000000000000000000051111111111111111111111115353333333333b3b00000000
0000000011113bbbbbb311111110099997700111444049440d6656010b33b33b3b33b33b3b33b33011111116d1111111b311b3b135313333331333b300000000
00700700113bbbbb76bbbb1111099aaa77a970114407049410d6501100030330000303300003033011111116611111113b3b3b3b533333333333333b00000000
00077000113bbbb6777bbb111099a449944777014406029910d67011222020042220200222202000111111156111111133333333333333333333333300000000
0007700013bbbbb7776bbb31109a997799797901905670291105011142224229944242299442444f111114449f91111133333133333333333333333300000000
0070070013bbbbbb67bbbbb104a9977997774a9090dd6024110601114424444499444444994444ff111f4ff4f9f9911133333333333333333333333300000000
0000000013bbbbbbbbb67bb104a9779977794a9005dd6702111011112444444449944444499444ff11f4ff4fff9fff1131333333333333333333333300000000
0000000013bbbbbbbbb76bb104a7799777994a9005ddd602111111112249444444994444449944ff114ff4f44ffff91133333333333333333333333300000000
1111111113bbbbbbbbbbbbb10977997779994a9044499444444994442229944444499444444994ff112f44fffff9f41111111111111111119911111100000000
11111111133bbbbbbbbbbbb10999977799a94a9044449944444499442224994444449944444499ff1112f4fffff94411b1111111111111351144119900000000
11111111133bbbbbbbbbbbb1049977799a994a90444449a4444449942224499444444994444449af111ff444ff4ff4f13b311111111113534449a11100000000
111111111333bbbbbbbbbb3110977799a999a901444444aa224444992224449944444499444444aa1124f4fff44ff421b3b1111111113535144a911100000000
1111111113333bbbbbbbb33110977999999a9901944444fa422444494224444994444449944444fa124ff4ffff4f4f113b3b311111115153114a791100000000
11111111153333333333335111094aaaaaa99011994444ff442444444424444499444444994444ff15444f4ff4f4ff2133b3b31111353533494aea1100000000
1111111111553333333355111110044444400111499444ff244444442444444449944444499444ff115454444445ff11313b3b31115353331111144100000000
1111111111111111111111111111100000011111449944ff224944442249444444994444449944ff11111111111111113333b3b1153533311441119400000000
1110111011000011111111110000000000000000444994f0004994442249944444499444444994ff111111111111111100000000000000004411111100000000
010101011049aa511110011100000000000000004444990b330499442244994444449944444499ff11111113b111111100000000000000001144114900000000
1010101004997790110994110000000000000000444444033b3049942224299224422992244229af111111133111111100000000000000004994a11100000000
010101010499979010497901000000000000000044444420030444992222124412221244122212aa1111111531111111000000000000000014449a1100000000
000000005499999015449901000000000000000094444449402444491241124112411221124112f11111144449a111110000000000000000114a791100000000
00000000544999401154401100000000000000009944444494444444121112111211121112111211111949949a9aa1110000000000000000444aea1100000000
000000001544440111150111000000000000000049944444499444441111111111111111111111111194994999a9aa1100000000000000001111144100000000
000000001155001111111111000000000000000044994444449944441111111111111111111111111949949999999aa100000000000000001491114900000000
00000000111111111111111100000000000000001111111105ddd60110010010010010010010010019499499999a949111111111111111114411111100000000
00000000111111111111111100000000000000001110111105dd670104904904904904904904904919499499999a949111111111111111111199119400000000
00000000111041111111111100000000000000001107011110dd6011044044044044044044044044144994999949949111111111111111114444a11100000000
0000000011097411111141110000000000000000110601111056701110010010010010010010010014449499994994911111113311111111199a9a1100000000
0000000011549011111594110000000000000000105670111106011111111111111111111111111114449499994949911131133311311131114a7a1100000000
000000001115011111115111000000000000000010dd601111070111111111111111111111111111154449499494999113311331113111314449ea1100000000
000000001111111111111111000000000000000005dd670111101111111111111111111111111111115454444445991113313331113131311111199100000000
000000001111111111111111000000000000000005ddd60111111111111111111111111111111111111111111111111113313311313133331941114400000000
50000000000000000000000550000005555555555555555550000000000000000000000599494999111111111111116666111111111111115555555544499444
07767776677767766777677007766670555555555555555507999999499999994999994094999994111111111111116666111111111111115445544544499444
0d65666556665665566657700d655670555655555555555509444444444444444444445049555559111111111166661661666611111111114444444444444444
0d65555555555555555555600d655560555555665665565540000000000000000000000949555554111111111666666666666661111111114554455499999999
0055655d555655655555577000555670555555665665555554444444444444444444494949555554111111116666666666666666111111115555555599999999
0d65555555555555556557700d655670555665555555555545454545454545454545449949555554111111116666666666666666111111115445544544444444
0d65565556555555555557700d6556705556655ddd56655554545454545454545454545959555554111111116666666666666666111111114444454444994444
0055555555555555d555556000555560555555600d56655555555555555555555555554955444445111111166666666666666666611111114544444444994444
00555555555555555555556000555560555665600d55555554599999999999999999999999999999111116616666666650000005166111111114111144499444
0d665d5555555555555556700d665670555665566556655555949494949494949494949994949494111166666666666604444440666611111111411144499444
0d66556555555555556556700d6656705555555555566555545949494949494949494949494949491116666666666666059f9940666661111114111144994444
0d66555555555555555555600d665560555556656655555555444444444444444444449944444444111666666666666604944f40666661111111411149944499
00555555555555555555667000556670556556656655555554544444444444444444494944999444166166666666666605944940666616611114111199444999
0d655655d5555555565d66700d65667055555555555565555545454545454545454544994955554466666666666666660499f940666666661111411194449944
0d65555555555555555566700d656670555555555555555554545454545454545454545995555554666666666666666605454540666666661114111144499444
005555555555d5555555556000555560555555555555555555555555555555555555554995555554666666666666666650000005666666661111411144994444
00555655555555655565667000556670500000000000000555555555545445444494494995555554333333333333333333333333333333333333433355555555
0d65555555555555555566700d656670077767766777677054455445545445444494494995555554333333333333333333333333333343333333333355555555
0d65555555655555555555600d65556000665665566656604444444454544544449449499555555433333333b3333333333333b3343435343434393955555555
005555655555565556d5567000555670005555555555556045544554545445444494494995555554333333333333333333333333535343434393434355555555
0d66555555555555555556700d6656700d6566555565556055555555545445444494494995555554333333333313333333333331343435343434393955555555
0d66566556656665566655600d6655600d656655555565605445544554544544449449499555555433333333133333333333b331545445444494494355555555
00000dd00dd0ddd00ddd0060000000600055555ddd55567044444444545445444494494995555554333333331133333b33333331345435444394434955555555
50000000000000000000000550000005005555600d55567045544554545445444494494995555554333333331131333333331311543445434493494955555555
50000000000000000000000511111111005555600d55556050000000000000000000000511111111333333331113333313313111111111111111111155555555
077677766777677667776600111111110d656656655555600db3bb3b333b33b33b333b30141514153b3333331111113333111111111111111111111165566665
0d6566655666566556665600111111110d656655556655600035335535535555553535504141414133333b311111111111111111111111111111111155566665
0d6555555555555555555500111111110d655555556656700d5555555555555555555560151415143313333311111111111111111111111111111331555dddd5
0d66555555555555555556705000000500555555555556700055655d555655655555567055555555113331331111111111111111131113111111133155555555
0d66566556656665566655600776667000566655665665600d655555555555555565567054455445111133111111111111111111131113113311333156655655
00000dd00dd0ddd50ddd00600d655670000ddd00dd0d0d600d65565556555555555556704444444411111111111111111111111111331131333133115dd55555
5000000000000000000000050d65556050000000000000050055555555555555d555556045544554111111111111111111111111313131331331331155555555
ffff8ff73dfbff7e9a0003228a2a031b308273aa021ac0c83048408b53b2b2ca334b637bb315cee3cefbf3ffb0fe6353cbbbcbd377e3d33bd67a92b9c9c93232
4af64a0aa27fa9eeeee005051d7085859db056bd17fcc5ab6e5ffde997e99c7f1e87cff7f2fc4fdf756ffd5af9fb8ee761e7f93cfa7eafeffe9fefbcf7fecf31
b8ff78ff715e7ef78fff2ff4cffacf2df75ee78694ff395fbbfff3f1af83cdff3ef8cff78f1efff8ecf33ff75effbcff4af98fff0f3f8b6d3a9f77ff78ff75ef
f1dff78ffb1ff7ce29b5cceff38affbd5dff5cffbbff47f73ef4df2ff2efb2eff79ed5ff79fff263f3fb66e771ff73ef731e1272ff30ff98ffacf5ef679ffcef
f6cff57ceff27eef39efff9e731eff3cfff0767c5ff6ef95f74ff34a0fe9f05461f948f82747e5f3afff1fc2391fcfd277f9df7af7dffbbf32fff39fff7972ef
90ff78fff793ff39ffdb57ff3efffcfff8fff5eff7dfe443e10f3522ffaf47a83bfff5eff22cfffd4f8469b5f2fff7cfff495e72ef36f18f6e07ff1cff58ddfb
9ffb2fab87d1ffbfff9fff3fff7efffcfff9ff32154d303bfff2effadff79ff5594a41ff2cffac19ff994267f78ee476c7f7eeeff7f9fffb9f4b129c147afeff
8df79e7cef7f5f83e724119738f9cffdfffb7ff3ff087ae493029eff7afff5effb1cbc988ff7f7ff1cffef11f38e54f547df52e5f978f5f83e8fed72f3aff4cf
d8fff8fff1ef40c91f117cff0fbdffb279c194fd802995ffb9ff45f8ef25e7f378ef919df73ff40dff6de9f40dd983feff70eff5cfe2f58fbcc452fffcf19ffc
df41df5f09c0f38fe4903c3d37bffecffd8f9f270fafeb3bd7cf0a3f5317f3ff3816ff688bcbb5ff3b2872752c3fffb848aee77c3b86f93c381cffd983f99f9e
ff391ff7ff31981ee07eff1fe59b3bffd33ff7aeff1dff3af9fc722cffde93459e6c7edfff49cff2eff6ff3ef3819a96c61ef8bc78effd0dffdc50ef8b5a9814
5cfacf763e76ff1f7eddf39ff6ff4ef7ff72ff9fb5f1ccf3b0fcd745ff6c94f3f95dcc581effcfebf7b26fff9dffcffcff6effffb3a8c37998c585f78f000000
00000000000000000000000000000000000000001111111999991111111111111111111111111111111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000011111199999aa911111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000001111199991199991111999911111111111111111111111111111111111111111119111111111111111111111
00000000000000000000000000000000000000001111199911119991199449a91111999999111119999991119911111199111119119111191111111111111111
1111111111155111111111110000000001001001111119991111999199911199911999449a9111999449a9199a911119a9111119119991919111111111111111
1111111111554911111111113bbbbbbb904904901111199999999941999111999199941199a9199941199a9499a1111999111199919191999111111111111111
11111111155494911111111133b3b3b3404404401111199994444419999999991199911149991999111499914999119999111119119191911111111111111111
1111111115444941111111115333b333035035031111199991111114999411111199911119991999111199911499919994111119911111199111111111111111
11111111554444491111111153333535131313531111199991111111999111111199911119991999111199911149999941111111111111111111111111111111
11111115545454544111111155353535111313131111199991111111499999999199411119941994111199411114999911111111111111111111111111111111
11111155454545454411111155553555111113111111199991111111144999944144111114411441111144111111999411111111113111111111111111111111
11111155555555555411111155555555111111111111149991111111111444411111111111111111111111111119999111111111494911111111111111111111
11111554449999999991111111111111eeeeeeee1111114991111111111111111111111111111111111111111999941111111114999491111111111111111111
11115544494949494949111111111111eeeeeeee1111111449999111111111111111111111111111111111114994411199911114999491111111111111111111
11155444949494949494911111111111eeeeeeee111111199999aa9111111111111111111111111111111111144111119a911111494911111111111111111111
11154444444444444444911111111111eeeeeeee1111119999119999111111111111111111111111111111111111111999411111111111111111111111111111
11554444444444444444491111111111eeeeeeee1111119991111999199911111991111111111111111111999999111999111991111111111111111111111111
15445454545454545454449111111111eeeeeeee111111999111199999a911119a911199991111999111199999aa911999119a91999911199999911111111111
55454545454545454545444911111111eeeeeeee11111199999999949999111199a919aa99111999a9119994114999199919991199a911999999a91111111111
55555555555555555555555411111111eeeeeeee11111199994444419999111199991999499199499911999111199919999991119999199994499a9111111111
51111111111111111111111551111111111111151111119999111111499911119991199919999419991999911119991999999111999919999114999111111111
15511111111111111111155115511111111115511111119999111111199991199991999414999119991999911119941999199991999499994111999111111111
19a555111111111111555a9119a5551111555a911111114999111111149999999941999111499119991999999999911994114999999199991111999111111111
19991955555555555591999119991155551199911111111444111111114499944411499111141114991999944444411441111444444149911111994111111111
144419a9119aa9119a9144411444119aa91144411111111111111111111144411111144111111111441999911111111111111111111114411111441111111111
11111999119999119991111111111199991111111111111111111111111111111111111111111111111499911111111111111111111111111111111111111111
11111444114444114441111111111144441111111111111111111111111111111111111111111111111199411111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111144111111111111111111111111111111111111111111
111011111111011111111011111101110000000000000000111111111111111111111111111d6611000000001111999991111111000005119999999999999999
110c01111110c01111110c011110c01100000000000000001ee1ee111111111111d66611111d6611000000001111194949111111999940119494949494949494
10c7c001110c7c000110c7c0110c7c000000000000000000eeeeeee11ee1ee111d6666611d666666000000001111149494491111444450114949994949494999
0cec7cc000cec7ccc00cec7c00cec7cc0000000000000000eeeeeee11eeeee111d6666611d666666000000001144444444111111000001114495544444449955
ceccc77ccceccc777cceccc7cceccc770000000000000000eeeeeee11eeeee111d666661111d6611000000001115444444445111441111114955554444995555
cccccccccccccccccccccccccccccccc00000000000000001eeeee1111eee1111d666661111d6611000000001111445454511111454111119555555449555559
cccccecccccceccccccecccccccceccc000000000000000011eee111111e11111d666661111d6611000000001115454541111111545451119555555495555555
ccceeeeccceeeeccceeeeccccceeeecc0000000000000000111e1111111111111d666661111d6611000000001111155555551111555111119555555495555554
00000000544999111155499915449911111911111111111711111111111177177777111111111111111111111111111111111111111111119555555495555554
00000000444476911567444915474911115691111177717771777111111777677777711115115111115111511111111111111111111111119555555495555554
00000000467777695677777415474911156769111777767776777711111777777777677115115111115111511116111111111111111111119555555495555544
00000000444476411467444415474454157779111777777777777671176777777777777115115155515115511167611111111111111111119555555455555544
00000000555555111155555515777511144744111777777777777771777777777777776715555151515151511116111111111111111111114444444455555554
00000000111511111111511115676511154744547777777777777771777777777777777715115155515155511111111111111111111111114545454555555555
00000000111411111111411111465111154644117777777777777767167777777777777711111111111111111111111111111111111111115454545455555555
00000000111411111111411111151111155444111677777777777777177777777777777711111111111111111111111111111111111111115555555595555555
00000000111111110000000011994451111191111777777777777777777777777777777711111111111111110000000011111100111100111115151100000000
00000000111111110000000011947451111965111777777777777671776777777777677115551111111115510000000011111108011080111115551100000000
00000000116611110000000011947451119676511177677767777711117777777777711111511111111115510000000011111100011000111111511100000000
000000001d6761110000000045447451119777511111777771777711117776767767711111515151555515510000000011111111111111111115551100000000
000000001dd676110000000011577751114474411111777771111111111771771177177111515151515515110000000011111101010101111115151100000000
000000001dd666110000000011567651454474511111177111111771111111111111177115515551511515110000000011111110101011111115551100000000
000000001ddd66610000000011156411114464511111111111111771111111111111111111111111111111110000000011111111111111111111511100000000
000000001ddddd660000000011115111114445511111111111171111111111111111711111111111111111110000000011111111111111111115551100000000
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
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000000000000001010000818a0606060000000000000a0a0a0a0a0a060606000000000002020a0a0a0a0a0a0000000000000a0000020a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a0200000000000a
00000000020200000000000000000000000000000202020200000000000000000000000a060202020000000000000000000000008a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2a2b0001020076a3787777780a0b107677787979795200500708094042002c2d373839104a4b4c4d10070809ecec7dd87ed97d001d0c1c00000000000046474748000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b001112005051525151521a1b1050515266666652005017181960620000007071724a4b5b5b4c4d174f19fcfd00000000001d0d6a0e1c000000000056575958000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738397072005051525151521010106061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829e1e2e3e40000000d6a6a6a0ec0c1c1c20056576958000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe1a9003528be880b8c0cbb3bd1b8b0a81a8384f1a222b129bca02abf028333300436b7319b9c1ca733b43c722a363d35943e3daf70a17120a1bfd21b12930ffc69f99f9db626e2486e7aef279ee9f34fc3f13893e713f2fc784fc38fcedd7ff1bf3ffc8b6fe9fafe87e2e3f6fd7f5fd4bf7bfba7f073f9cb7f
9e787f49fda4ff3fde4fc161fa4ff9b7ea8ffd8ecffc09e4e475ef3fb7fe1a4afaf37f7e3ff104e79fdeffe3f1f9cfdfff227f36717ff25ffc13abff97ff34ffc01ff92bf5dceffc9ff92bff3f57ff17f5ff875ffd1ffa7ff55e3ff5dfab93f29ff89f94fdfff01faf73e713ff67fedeec917f6ffdd3f39ff89fcb893e68ffd6
dffbf8fe1d1f91f9c073baf7f6713fdff7f0b3ff8712ff1ce97f99c6dffc3ff77fe104e1cdedd8e0032cc7f2fe36ffd27fe2affe3ffca4ffe774b64b769f9ffe8ffe91ff8c707b7a9c0e9651cf4fedff8ec98fc61fa03f19ffd64bffd84b7c9fcc4ffee90c47e3e953c75d9c2a59df1f9fff89117fa392953f1503c2a71c71ff
93a4e61f6e3ffc89ffe98ee7ea5e93f79fbf6772c9c495fc83f0247ffb4ffdce24a2dfc7ffcbd7a9fca3ffe7f86bd7739ebdfbf0fc3f4fd3f4e9cf125fc4af07fe14f27e1f824ffc8e79e79eff2e69c4e9f96fc1ff97ff3f2ffe49fff6a8e9fa54e9fbd3abffd3ff57ffefd5fc4dc5e4ae669c93f473f87fdffa0fd9f9f9f7d1
164df87268f64fdffe1c21cedff48c59ffeac82fe13ffda7ffa769dbf03f5ad1ff888dff93f6ffc95da73fcbfd685858b09c7edfb7f29a02c6c4a3d7ffd275b4f5241f8324ee429eefc7f4e670fffe013f0e3fff83f9ffe5fffe1393496cfcbff672913b420849772717f3fd3f5b7feffd7ff82c9f8b9ffd73fa5ea44a7b5fff
c27573f143c3be34babafdff77f3fa7feb7287ef6689ff7ffbe507fe185cd51e7078871cdfc7f9b3a7feeffd3ffabff5ff7efe32041239353b40bc80d4ed02f2fe4e240824726a768179ffff0627338bda54ecfd812daffd4fffe4fd1ffbff203fff95f47ff0fc801f9000000000000000000000000000000000000000000000
fffff87fd3bffd6a400c0c28aa2a0de4688c4bcfe6e70723c7ce6a6a883c480aac6c8e4e0845c0c6a866cb8fafc2495b71c71273d5d7bbc74e35f3d9fb4f9307d38e36e3df6e9f83f19ef52756a7e6bccfc3973f8fe5f9f7f9f80f0d27e0b3df74e38fd9f8fedd731d3cfca3c5dc61e4da3cb568fd04fd1cd95fa3affd13f576
de70fa6773f057e3a47f53f657efc6e1559522713ff96693d54f215bf01d613f59fc7f3276bbf2f3cf2464945123ffa51f855b626dec95485fcecfd28e4f61fbcfe9e97378fc41f8899ecfeffcfea271fbffb666b2ac9047e7d7fdff81ff87affc5784a1fd7e6ff7f2e12f2f27e9533f5d274eca009617e9f34ff536ffa3a58f
e6493e7df9afd7fe931f9d9567fe3750ff841a755c4faed5269527293f149524491102449c0fcd387ed7ff27fe4ffc9f94b167309cc8fcab989c35fdb9e66e4efff4f1cba9cf09fe7925fc3f0fc272391f94ffcae3bf387480e0b117d8d3c7fe221fcc99377a7f57a6fd67fe6bc2339e10b274e6bc7fbff9e7e3f8f97c93f224
f6fe49d4ea631f9c9c21649c4f927c93a7cfdb99ea1e4aa7fe3bffa38e891c92b914fce1bc72e1bcf62fcffd2359ffaa789c3c93c49f24f95df93b927fe84848484876f65910c7e90c90061ecdf97934962fe30f2447fe1ff1bc2a7e723f491a05ed2c11bff0baff4fc0fcc0bc7fbffef93b9fffca241fffcba9fd139fffe67f
e7ff7fdffcc5ff7ff57fd2fff07e09ff8b893e6896c923ff0aa35ffc5ff8bfff9abff8fff037cfc3f0fc3f0ffe3fffcefe3c93913fff9fc92c739fffd0b3ffe18fdbfffa34fe84cea0b27bf8ef44cfffe17effffc25a99fffd2cfffe9faf13a75213f57d3fffa9fffd58fffe79f777f5ff6fee00000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe38028a90c0cbebf0bab2cabac282230b1038404a323a434f122b324bb2abbd1bc130a940b12e1e26060e13fb03c9493a525a72daa212d2fa7b970a083521ca0685a7ff53db2e6e38e493a389d77e7bf75cf367964b789f85fe63f089ffe8ef8fc7f2fcf9edcfe9fafecfdff893f939fdbfafdbf67e3f9bf6f
ed3f29fdbff84913fcabfe7fbedb244fc7fe70fcbf5fdba71e7b74c438e3ff07fe1fc6cfdcf2ffe2ffc6e27fe4a9d7f89fedff25a96c7fe392ff327e04fceb3f4fd7ff2b45ffc09127fe6ffcee3ff45ffd3fc39dff87ff17fe347f2bff89cd9ccff0d3fdffccdff7feaffd7f9db3bef4eeff1cffecffdbffbbfaffdf049ffc30
4938dffc5ff93ff0b8fa7fe6ffe5fd38ffe7ffa3f04e932f53fedf91f8a1c9d57fc20869d749d592d92dc2effe9ffd57f1314e5799dfe137fdffb3a59fb7ff6a7713f74fc4e53d9e7993417cf3c137ff4ffbffb87139fc25ffca5b7f915b5ffe5b89fcff27f27fe88740fc27fe5fdaeffcd4fc2fff8fff2d51c1daf422241ffe
ad4bdefff1ff992afe53fc86b0ecfc67ffb1fff25e7ff83f07fe6fe06fdfbefb5416c1373dcb2cffdd3ff056707e5cfff3ffe9fff1ffb9647bb5fffa93b3eb7a49fc22409c03b9fff8593f21ff9004f52fbe709e50e3fafea7fe52525fb9384e0ef82f2e1d73538ecc0a5b5b54676b6fe117a49567e1c7fe17f3ff8b7ecfffe0
713f1bfe4249354d269cdbdc704edf9c3c527459ff856bbffcb5ff8dbf2ffe07d7ff1fbfffc1ef79bff87ff093587e571c4efb4eeb7fdff7f2709fffc2fffe1f1c253f3926bea7643d7feff44fffe0fde23743f3e7fff893fff83ffcc2471a79070e3f63a393b87fb17ee7b7fe0bffe37a96cfea2fedd573cf7423f1178ffc1f
f87fbfdc4adfb60b7c3ff3c9fffc5f595ffbdc4384f2ffff03ffe44e6717b4a9d9fb025b5ffa9fffc6fa3ff4fe407fe9ffd5ffaffbf7f1902091c9a9da05e491eb2bff7b88709e5fffe1ffff0627338bda54ecfd812daffd4fffe4fd1ffbff203fff95f47ff0fc801f9000000000000000000000000000000000000000000000
fffff87fd3bfffef51bbbc002828aa293337a20322bfa73070bef13f31038404f83b7f130c2f8a948ba78cb093940b3536b733b4363d35a323a41c9bd21c3e3daf2b2ba4ac2cb4b8208e860e2e0687082525a626f99a9e2dbcaaa1a02d2eba38aa5fffe2cdc69cf1c2713aed38f3875ff92fbc7dfffc6ce3f0e6b993f11df13a
fc97f3e79ffd378e67e7bf47eabbf6438fdf4affcdcbf1e24928e6f5fc752fb27fe84fcf5fe7fafe9d7f7fe71feff5f9fee9cf2dcb9e3ff3f9c26fc7387178fe3fed9399ffdba7fe0ffc3ff8bff1ffe4e5dfdf8c9cffe544ffcdff9fff538493993ff4279fc7113ffbf3ffa7ff57febfea6bc9c5ee2fedfc7efffb7a59629df6
e62ffe67fecfc67feda7ef139349fd7fe29ffbaf73ff67fec6ffd1cc913c6ffd0f65fcff092c92bff7fa0ffd0ffe1e59144f47c3213ff3dffe3ffcbff9cb2492449be87e33ffa7ff593ffb5fd3bf249b6c6964ffe73affefffe3ffcbffc7ffa98ffd19ffee7ffcff17b9fff4e0fffdfffc0fffe09fffc2ffcb4bf837fe69fd3f
f25fbe87e7afe7fffc3fccfcfff2bf4fc61ff99f972f6d7ab7696c93f59fffc4fd3ffb5fffe2ffff1a7fe5bcff12f49ffa7ff67e9fe039e1fffc7fffe47fff26fb3a9ccfffe57fff28fffe51fffca1f9a53c750fc5ff97ff2efd6fefff9651a7748e7afffe5fff8fffe673127496fdf8bbfca493fff9bfffcefffe7ffff43fff
a39cedb6e389efb34fd926b77f09fffd2dd4fffe9a729ff9a7fff51ff849d79ffabff6ffe5ffc1ffafff0c7fe067ff27e89ff8b893f36896c9238546bff87ff0ffff557ff17fcddbf3fcff3fcfff9ffff5bfd693cb84fffebf29f873d4fffec7d3cfffecffff5dffbffefcafe2ff44ddf50593f1fc77e2267fff2bf8fffe52d4
cfffed67fff6fd7a9faba909fabd9fffdcfffeec9fea0f3bf7f89fb1dcfdc0a9d9fb025b5ffa9fffc6fa3ff4fe407fe9ffd5ffaffbf7f1902091c9a9da05e491eb2bff7b88709e5fffe1ffff0627338bda54ecfd812daffd4fffe4fd1ffbff203fff95f47ff0fc801f9000000000000000000000000000000000000000000000
__sfx__
ad0100011807000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
310100011812200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
310000011817000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000008551a3001a3001a300000001a3000085500000008550000018300183000083500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01280000159251c925219251f9251c9251e9251f9251c925199251a9251c925199251f92521925239251f925159251c925219251f9251c9251e9251f9251c925259252392521925209251c9251e9252092520925
01280000159551c945219451f9351c9451e9451f9451c935199551a9451c945199351f94521945239351f925159551c945219451f9351c9551e9451f945219352595526945289452594523955219452095520915
01280000239552594526945239452595523945219451e9452395525945269452394525955269452895523935239552594526945239452595523945219451e9451a9551c9451a9451994517945159451495514915
012800000984009811098300e830108300e8300b8300b8110d84010830138301583017830158301383013811108400e8300d8300b8300e8300d8300b83009830088500b8300e83010830128300e8300b8300b811
012800000984009811098300e830108300e8300b8300b8110d84010830138301583017830158301383013811108401383015830178301583013830108300e830108500e8300d8300b83008830088300882108811
012800000984009831098210981109810098150080000800008000080000800008000080000800048300482109840098310982109811098100981500800008000080000800008000080000800008000080000800
012800000b8400b8310b8210b8110b8100b815008000080000800008000080000800008000080004830048210b8400b8310b8210b8110b8100b81500800008000080000800008000080000800008001083010811
01280000259552694528945259352694528945269452593523955259452694523935259452694525945239352595526945289452a9352b9552a945289452b9352f9552d9452c9452a945289552a9452c9552c915
012800000e8400e8110e83010830128301383012830128110d8400d8110d8300e830108301283010830108110b8400b8110b8300d8300e8300d8300b8300d8301085010831108211081114840148311482114811
012800002d955289552695525955239552391500900009002d955289552695525955239552391500900009002d955289552695525955269552595523955219552395525955289552a95528955289252891500900
012800001585015811158150080000800098500b85010850158501581115815008000080009850108501285010850108110b8400d8400e850108400e8400d8400e8501084010811108150e8500e8110e8100e815
012800002d955289552695525955239552391500900009002d955289552695525955239552391500900009002d955289552695525955269552a9552f9552d9552c9552a955289552a9552c9552c9252c91500900
012800001585015811158150080000800098500b850108501585015811158150080000800098500b850108500e8500e8410e8310e8300e8210e8200e8110e8150d8500d8410d8310d8210d8110d8150d8000d800
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006080000000270502a0502c0503005032050370503b0503f0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
580108003351032510325102e5102b51027510215101e5101f5100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8801080019520195101c5102151024510285103051036510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030b0e0065004650086500d65010650186501d65021650296502f6503d6503b650366503d650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020700323502c350293502735025350213503030034550365503855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000023160211501c15016140121300d1300c11013000130001b60013000130000000013000130001300013000000000000000000000000000000000000000000000000000000000000000000000000000000
30020e001d6701517013160101500d1500a1400914007130061200511005100130000000013000130001300013000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001505016050180501a0501c0501e0502205027050261501600016000160001600017000330000000035000380003900000000000000000013000000000000000000000000000000000000000000000000
__music__
01 08424344
00 09424344
00 080d4344
00 0a0e4344
00 080b4344
00 090c4344
00 080b4344
00 0f104344
00 11124344
00 13124344
00 11124344
02 13144344
00 7d424344
03 0c424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344
00 7d424344

