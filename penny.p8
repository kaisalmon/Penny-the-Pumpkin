pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--penny the pumpkin
title_y=8
label=false

max_coins=13
function init()
t=0
broken_blocks={}
wipe_progress = -1  -- -1: no transition, 0-128: transition in progress
fc=0
dust={}
moved=false
shake=0
trail={}
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
fire_at=nil
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
cave_thought_t=0
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
	pal(blocks.pal or {1,2,3,4,
						5,6,7,8,
						9,10,11,12,
						13,14,15,16}, 1)
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
			e.h.y-(e.pumpkin and 4 or 0),
			e.w+4,
			e.size,
			e.pumpkin and 0 or 3
		)
	end)
		
	if died_at == nil and not flicker then 
		if heart_thought_t>1 or cave_thought_t > 10 or hold_thought_t > 4 then
			spr(time()%1.5 > .75 and 229 or 231,player.x-5,player.h.y-20,2,2)
			if hold_thought_t > 4 then
				spr(time()%1 > .5 and 233 or 249,player.x-5,player.h.y-17,2,1)
			elseif cave_thought_t > 10 then
				local thought_rem=time()%2
				if thought_rem < 1 then
					spr(244,player.x-1,player.h.y-17)
					local tt=mid(thought_rem,.25,.5)
					spr(251,
					player.x+8*(.9-tt*2),
					player.h.y-14+350*(tt-.55)*(tt-.25)
					)
				else
					spr(243,player.x-2,player.h.y-18)
				end	
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
	if(blocks==level3)	draw_wipe_transition(.35)
	local draw_cpu_usage = stat(1) - stat_1

	if debug then
		cursor(1,1)
		print(tostr(player.x)..", "..tostr(player.y),7)
		print(stat(7).."fps",7)
		print(flr((stat(0)/20)).."% mem",7)
		print(flr(update_cpu_usage*100).."% cpu (update)")
		print(flr((draw_cpu_usage)*100).."% cpu (draw)",7)
		if(profile_cpu_usage !=0)		print((flr(profile_cpu_usage*1000)/10).."% cpu (profile)",7)
	
		print(flr((stat(1))*100).."% cpu (total)",7)
		print(debug)
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
	
	local x=label and 10 or 50
	--values 0x10 and 0x30 to 0x3f change the effect
 poke(0x5f5f,0x10)
--new colors on the affected line
 pal(blocks.pal == night and {
 0,0,0,132,
						0,0,0,0,
						137,9,0,0,
						13,0,0
 } or {131,130,131,132,
						133,5,6,136,
						137,9,11,12,
						13,-4,15},2)
--0x5f70 to 0x5f7f are the 16 sections of the screen
--0xff is the bitfield of which of the 16 line of the section are affected
 pal_memset(0x5f70,0,16)
 local z=flr(title_y)%8
 pal_memset(0x5f70+(title_y)/8-1,255<<z,1)
 pal_memset(0x5f70+(title_y)/8,255,3)
 pal_memset(0x5f70+(title_y)/8+3,~(255<<z),1)
	for i,v in ipairs({
		{x-1,title_y},
		{x+1,title_y},
		{x,title_y+1},
		{x,title_y-1},
		{x,title_y}
	}) do
		pal(9,i==5 and 9 or 0)
		pal(4,i==5 and 4 or 0)
		pal(10,i==5 and 10 or 0)
		sspr(0,104,48,8, v[1],v[2]+3)
		print("penny the",v[1],v[2]-2,9)
	end		
	if is_halloween() then
				print("happy halloween",x,title_y+15,13)
	else
		if time()%1 < .5 then
			print("by kai salmon",x+24,title_y+15,13)
		else
			print("by kaimonkey",x+24,title_y+15,13)
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

	update_camera()
	
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
 
 if moved and coins_collected < max_coins then
		speedrun_t+=1/60
	end
	
	if died_at and died_at < time() - 1 then
		load_level(blocks,blocks.px,blocks.py,blocks.dpx,blocks.pdy)
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
      player.y=e.h.y-2
      player.dy=-4.5
      player.last_gnded_y=player.y
      player.h.dy=-6.5
      e.h.dy+=2
      e.dy+=2
    elseif do_characters_overlap_forgiving(e,player) then
      die()
    end
  end
end

function update_camera()
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
	shake*=0.5
end

function lerp(a, b, t)
  return a + (b - a) * t
end

function update_character(ch, move_dir, jump, t_stretch, jump_held)
	if (move_dir < 0) ch.dx -= ch.speed or .2
	if (move_dir > 0) ch.dx += ch.speed or .2
	if (move_dir > 0) ch.facing = ➡️
	if (move_dir < 0) ch.facing = ⬅️


	ch.tile = t1 or t0 or t2
	
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
		ch.last_gnded_y=ch.y
	else
		local g = (ch.dy < 0 
			and jump_held)	
			and g1
			 or g2
		ch.dy+=g
		ch.h.dy+=g
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

	ch.dx *= 0.9
	ch.dy -= sgn(ch.dy)
		 * air
			* ch.dy 
			* ch.dy
	ch.h.dx *= 0.96
	ch.h.dy *= 0.95

	local h = ch.size * ch.stretch
	if(not ch.gnded and not ch.was_gnded) h=ch.size
	local fh=0.015
	if(ch.size < 12)fh*=2 
	
	local fyh = (ch.y - ch.h.y - h) 
		* fh * 3
	local fxh = (ch.x - ch.h.x) 
		* fh
		
	ch.h.dx += fxh
	ch.h.dy += fyh
	ch.dx -= fxh
	
	local min_h =ch.size/4+1
	if ch.h.y + min_h > ch.y then
		if(ch.h.dy>0)ch.h.dy *= -1
		ch.h.y = ch.y-min_h
		eject_particle(ch.h, false, 0.5, 1)
		if (ch.y != ch.h.y+min_h) then
			ch.y = ch.h.y+min_h
			ch.dy *= -1 * ch.bounce
			if is_solid(ch, true) then
				--todo be better
				if(ch == player) die()
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
	ch.size += delta_s*0.2
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
		(btn(3) and .5 or btn(2) and 1.5 or 1),
		jump_btn_down
	)

	if fget(player.tile, 7) then
		die()
	end

	if player.tile == 35 then
		fire()
	end

	 
	if player.gnded and abs(player.dx) > 0.4 then
		if(rnd()<.3)add_dust(player)
	end

	
	if player.y > 2000 then
		die()
	end
end

-- function add_dust(ch, dy, dx,fullh, t)
-- 	if(#dust > 100 or stat(7)<60) then
-- 		deli(dust, 1)
-- 	end
-- 	add(dust, {
-- 			x=ch.x
-- 				+(rnd()-.5)*ch.w,
-- 			y=ch.y - (fullh and rnd()*20 or 0) ,
-- 			c=11,
-- 			dx=(dx or 1)*(rnd()-.5)-.1*ch.dx,
-- 			dy=2*(dy or -.7)*(rnd()*.5+.5),
-- 			t=(t or 30)+flr(30*rnd()),
-- 			bounce=.7
-- 		})
-- end

function update_character_w(ch)
	local h = ch.y-ch.h.y
	local s= ch.size
	local tw=(32 - h * (25 / 20))/14*s
	tw=min(tw, 30/16*s)
	tw=max(tw, 4)
	ch.w = lerp(ch.w,tw,1)
	ch.h.w = ch.w
end

function skw_spr(x,y,hx,hy, w, size, u, fx)

	h = y-hy+1
	if (h<0)h=0
	
	for i=0,h do
		s = i/h*16
		sw= (hx-x)*(h-i)/h
		local  v, dv = s/8, 1/w*2
		if fx then
			tline(x+w/2 + sw,y+i-h,
								x-w/2 + sw,y+i-h,
								u, v,
							 dv)
		else
			tline(x-w/2 + sw,y+i-h,
									x+w/2 + sw,y+i-h,
									u, v,
								 dv)
		end
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
	if (debug) return
	if died_at then
		return
	end
	sfx(4)
	died_at = time()
	for i = 0,15 do
		add_dust(player, player.dx,player.dy,true,55)
	end
end

function fire()
	sfx(3)
	
	if fire_at and fire_at > time()-1 then
		die()
	else
		player.dy -= 5
		player.h.dy -= 8
		fire_at=time()
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
		p.x += p.dx
	else
		p.dx *= -1
		p.dx *= p.bounce or 0
	end
	
	y_col,tile = is_colide(p.x,p.y+p.dy,p.w,inc_semi)
	if not y_col  then
		 p.y += p.dy
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
	if(ch != player and rnd() < .25)return
	if stat(7)<60 or #dust > 30 then
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
alternate = function(b)
	if t%2 > 1 then
		b[3]=0
	else
		b[3]=2
	end
end
local crash_breakable =  function(b)
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

night={0,-16,-4,1,
						0,5,6,8,
						-3,-1,12,12,
						1,14,15}
forest_pal={138,2,3,4,
						147,6,7,8,
						9,10,11,12,
						13,-4,15}
spooky_pal = {128,130,131,132,
133,5,6,136,
137,9,3,12,
13,8,15}
day={-4,2,3,4,5,6,7,8,9,10,11,12,13,14,15}

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
			update=function(b)
					if player.x < -30 then
						load_level(level8, 5, 30)
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
	pal=night,	
	chunk=3+chunk_size,
	c={
		{x=2.5,y=4,id=4},
		{x=45.5,y=10,id=5},
		{x=76.5,y=13,id=6}
	},
	e={
		{x=86.5,y=11, minx=670, maxx=770},
		{x=86.5,y=11, minx=670, maxx=770}
	},
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
			if player.x > 30
			and player.x < 85 then
				cave_thought_t+=1/60
				if player.y >88 then
					player.y=88
					player.h.y=88+player.size
				end
			else
				cave_thought_t=0
			end
		
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
		"32,1,3,1,66,3",
		update=drop
	},
		"27,13,16,6,58,5",
	"58,3,58,16,74,0"	
}

level4={
	chunk=3+chunk_size*2,
	pal=day,
	c={
		{x=4, y=23, id=7},
		{x=352/8, y=120/8, id=8},
		{x=23, y=3.5, id=9},
		{x=39, y=27, id=13},
	},
	e={
		{x=352/8, y=120/8, 
		pumpkin=true, 
		minx=317,maxx=370,
		miny=125, maxy=175},
		{x=91/8, y=61/8, 
		pumpkin=true, 
		minx=91,maxx=365,
		miny=61, maxy=90},
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
	"0,3,48,16,0,0",
	"48,3,48,16,0,16",
	{
		"30,0,2,1,12,21",
		update=alternate
	},
	{
		"30,0,2,1,17,23",
		update=alternate
	},
	{
		"40,6,4,7,42,12",
		front=true
	},
	{"27,0,2,2,38,25",on_crash=crash_breakable,front=true, key="level4"},
}

level5={
	chunk=3+chunk_size*2,
	pal=day,
	e={
		{x=15,y=11, miny=20, maxy=100, minx=55, maxx=290},
		{x=24,y=9, miny=20,  maxy=100, minx=55, maxx=290},
		{x=33,y=11, miny=20,  maxy=100, minx=55, maxx=290}
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
		if player.x < 0 then
			load_level(
				level4,
				385,
				player.y > 30 and 70 or 0
			)
		end
	end},
	"118,2,4,17,44,-1"
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
	"48,16,16,3,0,-6",
	"16,15,14,4,1,-2",
	{
		"16,15,14,4,1,2",
		colide=false,
		fill=3
	},
	"37,12,4,7,6,-8",
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
				load_level(level2, 170, -30)
				player.last_gnded_y="override"
		elseif player.x > 300 then
			load_level(level6, 5, -15)
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
level8={
	px=17,
	py=17,
	pal=spooky_pal,
	chunk=32+chunk_size*0,
	{"1,10,22,1,1,8", ry=7},
	"0,3,128,16,0,0",
	"0,2,3,1,6,4",
	"0,2,3,1,6,1",
	{"27,0,2,2,2,13",on_crash=function(s)
		s[3]=0
	end},
	{"27,0,2,2,31,12",on_crash=function(s)
		s[3]=0
	end},
}
local stars = {}
for i=0,30 do
	add(stars,{rnd(256)-30,-50-rnd(85)})
end
level1_variant={
	px=20,
	py=100,
	pal=spooky_pal,
	chunk=3+chunk_size*0,
	c={
		{x=17,y=2.75,id=1}
	},
	{"41,0,3,3,10,-30",  draw=function()

		-- Draw stars
		for i=1,#stars do
			pset(stars[i][1],stars[i][2],7)
		end
		ovalfill(60,-100,90,-70,7)
		ovalfill(70,-100,100,-70,1)
	end},
	{"51,0,5,3,-4,-7", colide=false, rx=9},
	{"51,0,36,4,-4,-4", colide=false,fill=3},
	"0,3,1,3,0,-3",
	{"9,0,5,19,-5,-3", colide=false,fill=5},
	{"9,0,5,3,-4,-6", tile=true},
	{"46,0,5,1,-4,-7", colide=false, front=true},
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
	level1_variant,
}
-->8
--level loading
function preload(t)
	if type(t) == "table" then
		new = {}
		for i, v in pairs(t) do new[i] = v end
		split_str = split(t[1])
		for i, v in pairs(split_str) do new[i] = v end
		return new
	end
	return split(t)
end

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
				if b[7] then
					y -= b[7](p.x,t,b)
				end
				
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
		return tile	end
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
			if b[7] then
				for i=0,b[3]*8-1 do
					local x=b[5]*8+i
					y1=b[6]*8+b[7](x,t,b)
					y2=(b[6]+b[4])*8+b[7](x,t,b)-1
					tline(x,y1,x,y2,
						b[1]+i/8,b[2],
						0,1/8)
				end
			elseif b.draw then
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

	for i,v in ipairs(level)do
		level[i]=preload(v)
	end
	
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
		for key in all(broken_blocks) do
			if b.key == key then
				del(blocks,b)
			end
		end
	end
	calc_cam_bounds()

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
	set_halloween_map()
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
	cartdata("kai-pumkinv1-1")
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
	load_level_instant(level1_variant,-10,-40)
end

function is_halloween()
    local month = stat(91)
    local day = stat(92)
    return (month == 10 and day >= 25) or
           (month == 11 and day <= 7)
end

function set_halloween_map()

end
__gfx__
000000001111000000001111111110000001111144499444005555605000000000000000000000051113333333333311111111115353333333333b3b00000000
0000000011503bbbbbb305111110099997700111444049440d6656010b33b33b3b33b33b3b33b3301333333b33333331b311b3b135313333331333b300000000
0070070015bbbb67bbbbb35111099aaa77a970114407049410d650110003033000030330000303303333abbbb3bbab313b3b3b3b533333333333333b00000000
0007700010bbb7776bbbb3011099a449944777014406029910d67011222020042220200222202000333bb3bbbbbbba3133333333333333333333333300000000
0007700003bbb6777bbbbb30109a997799797901905670291105011142224229944242299442444f33b3b3bbbbbbbb3133333133333333333333333300000000
007007000bbbbb76bbbbbb3004a9977997774a9090dd6024110601114424444499444444994444ff3333bbbbbbbbbb3333333333333333333333333300000000
000000000bb76bbbbbbbbb3004a9779977794a9005dd6702111011112444444449944444499444ff333b3b3bbb3b3b3331333333333333333333333300000000
000000000bb67bbbbbbbbb3004a7799777994a9005ddd602111111112249444444994444449944ff3333b3b3b3b3b33333333333333333333333333300000000
111111110bbbbbbbbbbbbb300977997779994a9044499444444494442229944444499444444994ff333b3b3b3b3b3b3311111111111111119911111100000000
111111110bbbbbbbbbbbb3300999977799a94a9044449944444499442224994444449944444499ff3333333333333333b1111111111111351144119900000000
111111110bbbbbbbbbbbb330049977799a994a90444449a4442449942224499444444994444449af33333333333333333b311111111113534449a11100000000
1111111103bbbbbbbbbb333010977799a999a901444444aa422444992224449944444499444444aa1333333333333331b3b1111111113535144a911100000000
11111111033bbbbbbbb3333010977999999a9901944444fa922444494224444994444449944444fa11115449945111113b3b311111115153114a791100000000
11111111053333333333335011094aaaaaa99011994444ff942444444424444499444444994444ff111154499451111133b3b31111353533494aea1100000000
1111111110553333333355011110044444400111499444ff144444442444444449944444499444ff1111544999511111313b3b31115353331111144100000000
1111111111000000000000111111100000011111449944ff124944442249444444994444449944ff11154499994511113333b3b1153533311441119400000000
1110111011000011111111110000000011153311444994f0004994442249944444499444444994ff111111100111111140000000000000044411111100000000
010101011049aa511110011100000000153333514444990b330499442244994444449944444499ff11111103b011111102444994444449901144114900000000
101010100499779011099411000000005333ab31444444033b3049942224299224422992244229af111111033011111102222244222222404994a11100000000
01010101049997901049790100000000333bba3144444420030444992222124412221244122212aa1111100530011111200000000000000414449a1100000000
0000000054999990154499010000000033b3bb3194444449402444491241124112411221124112f11110044449a001119222222442222229114a791100000000
000000005449994011544011000000005333bb339944444494444444121112111211121112111211110949949a9aa0119944444499444444444aea1100000000
00000000154444011115011100000000333b3b3349944444499444441111111111111111111111111094994999a9aa0149944444499444441111144100000000
000000001155001111111111000000005333b33344994444449944441111111111111111111111110949949999999aa044994444449944441491114900000000
0000000011111111111111110000000033333b331111111105ddd60110010010010010010010010009499499999a949042244222222442244411111100000000
00000000111111111111111100000000533333331110111105dd670104904904904904904904904909499499999a949024449944444499421199119400000000
00000000111041111111111100000000333333331107011110dd6011044044044044044044044044044994999949949024444994444449924444a11100000000
0000000011097411111141110000000015355351110601111056701110010010010010010010010004449499994994904222224422222229199a9a1100000000
0000000011549011111594110000000011549511105670111106011111111111111111111111111104449499994949909444444994444449114a7a1100000000
000000001115011111115111000000001154951110dd601111070111111111111111111111111111054449499494999099444444994444444449ea1100000000
000000001111111111111111000000001154951105dd670111101111111111111111111111111111105454444445990149944444499444441111199100000000
000000001111111111111111000000001549995105ddd60111111111111111111111111111111111110000000000001144994444449944441941114400000000
50000000000000000000000550000005555555555555555550000000000000000000000599949499111111111111116666111111111111115555555544499444
07767776677767766777677007766670555555555555555504999994999999949999997049999949111111111111116666111111111111115445544544499444
0d65666556665665566657700d655670555655555555555505444444444444444444449095555594111111111166661661666611111111114444444444444444
0d65555555555555555555600d655560555555665665565590000000000000000000000445555594111111111666666666666661111111114554455499999999
0055655d555655655555577000555670555555665665555594944444444444444444444545555594111111116666666666666666111111115555555599999999
0d65555555555555556557700d655670555665555555555599445454545454545454545445555594111111116666666666666666111111115445544544444444
0d65565556555555555557700d6556705556655ddd56655595454545454545454545454545555595111111116666666666666666111111114444454444994444
0055555555555555d555556000555560555555600d56655594555555555555555555555554444455111111166666666666666666611111114544444444994444
00555555555555555555556000555560555665600d55555599999999999999999999954599999999111116616666666650000005166111111117111144499444
0d665d5555555555555556700d665670555665566556655599494949494949494949495549494949111166666666666604444440666611111111711144499444
0d66556555555555556556700d6656705555555555566555949494949494949494949545949494941116666666666666059f9940666661111117111144994444
0d66555555555555555555600d665560555556656655555599444444444444444444445544444444111666666666666604944f40666661111111711149944499
00555555555555555555667000556670556556656655555594944444444444444444454544499944166166666666666605944940666616611117111199444999
0d655655d5555555565d66700d65667055555555555565559944545454545454545454554455559466666666666666660499f940666666661111711194449944
0d65555555555555555566700d656670555555555555555595454545454545454545454545555559666666666666666605454540666666661117111144499444
005555555555d5555555556000555560555555555555555594555555555555555555555545555559666666666666666650000005666666661111711144994444
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
ffff8ff73dfbefa0d404d0da8c9cd0f8d4c6dea0bcf0f8667eb1b1021e10e2e0e234223ee0fcf0e2bec8c0c4cca2a8a2609a3caff4ff6f9cf3ffefa5ddf3b27c
33ffdf3572d3775e7ffeece7f1f8ff9ff6c3ac3bebf7727eebaf369c7ffdff3ee8467435e8725e3e17c99ccecffff2ff4f72734fdf76ffffcc3cffcf2bee7ece
df1effeffd7c7feff3f9aefff77ebfd67bffffb3fcc3fffb87f7ff2b5fff38ffc0f3b1ffb8fff1ef7431fff2ef95ffb96dffef4b9f4de77898be0ffb9fff4ff7
9ef8df15fbff1cf75fff3e5e9bffdc6db36eb8a307cffbff1df36f5772effddf78ef5eff5c7d75f75e3effa176efe5c23eb9fd17c36bb5ffdfbe3dff972ea3f4
f7e1e52fc9d9c39affdf0ac9ece1ecd9fecff21ecff6fcff93ffa8fb7ff7fe39ff582d9dd2bdfaf33fd3d3cbec157420bbd90fff3c46df7a3dbf927aff91f2ff
12d22ff731f5eb89f83c2fe465a3c10baa69e7b6dff3e3a445cf751fa2176cff9cac17f79f9c6f3eff0ac913fdd3579f94f7973ff5cfd031aff32275ef052e72
311fff9e0fe93f72ff93dfa95fff6d57fcf7795efde7473e98f22e963d2ff7cdd1fbe77ebe9f42ff4cf9c8395df3e7e707fff7e8f9dfdafffefffdfffbf4ef5f
f3b8eee713ff0def663d51cc2827846ef7fb9f4edfe4e77e0f18c9bd46db7ef779ef22e197f1b8f72513358ffcba7878dec584ff9c73eff47dff5267e7f13cbf
f75e6e61c2c1eaef255d67efa7788c2aae5ff0bfd79f1f83fbeff2fff83cfafff379eff5fff4edbe229444e781e1fe7eff70ef964db90febd78fb5eff78effa6
e77879f7afdb66fa697acbe7f33bafcfbbe4a3cffff23deb3dff34f8cf92cc3f49c1ffceff9cff79fff49e7c6ec9346fe4040000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
449994111111111111111111111111111111111111111111111111111111111111111111111d6611000000000000000000000000000000000000000000000000
9911194111111111111111111111111111111111111111111ee1ee111111111111d66611111d6611000000000000000000000000000000000000000000000000
991119911111111111111199941194111194111111111111eeeeeee11ee1ee111d6666611d666666000000000000000000000000000000000000000000000000
991119919411191999994199119199119111199991111111eeeeeee11eeeee111d6666611d666666000000000000000000000000000000000000000000000000
aa111aa1aa111a1aa1a1a1aa11a1aa1a11aa1aa11a111111eeeeeee11eeeee111d666661111d6611000000000000000000000000000000000000000000000000
aaaaaa11aa111a1aa111a1aaaa11aaa111aa1aa11a1111111eeeee1111eee1111d666661111d6611000000000000000000000000000000000000000000000000
aa111111aa111a1aa111a1aa1111aa1a119919911a11111111eee111111e11111d666661111d6611000000000000000000000000000000000000000000000000
441111119999941991119199111199119144144119111111111e1111111111111d666661111d6611000000000000000000000000000000000000000000000000
11111661544999111155499915449911111911111111111711111111111177177777111111111111111111110000000011111111111111110000000000000000
11111161444465911556444915464911115491111177717771777111111777677777711115115111115111510000000011111111111111110000000000000000
16611611466666495466666415464911155659111777767776777711111777777777677115115111115111510000000011111111111111110000000000000000
11611661444465411456444415464454156669111777777777777671176777777777777115115155515115510000000011111111111111110000000000000000
16111111555555111155555515666511144644111777777777777771777777777777776715555151515151510000000011111111111111110000000000000000
16611111111511111111511115565511154644547777777777777771777777777777777715115155515155510000000011111111111111110000000000000000
11111111111411111111411111445111154644117777777777777767167777777777777711111111111111110000000011111111111111110000000000000000
11111111111411111111411111151111155444111677777777777777177777777777777711111111111111110000000011111111111111110000000000000000
00000000005353535353000011111111111111111777777777777777777777777777777711111111111111111311111111111100111100110000000000000000
00000000000000000000000011188811111111111777777777777671776777777777677115551111111115519a91111111111108011080110000000000000000
00000000000414141424000011811181ddd11111117767776777771111777777777771111151111111111551a9a1111111111100011000110000000000000000
0000000000000000000000001818111811d111111111777771777711117776767767711111515151555515511111111111111111111111110000000000000000
0000000053051515152500001811811811d111111111777771111111111771771177177111515151515515111111111111111101010101110000000000000000
0000000000000000000000001811181811d111111111177111111771111111111111177115515551511515111111111111111110101011110000000000000000
002e000004550000002500001181118111dddd111111111111111771111111111111111111111111111111111111111111111111111111110000000000000000
00000000000000000000000011188811111111111111111111171111111111111111711111111111111111111111111111111111111111110000000000000000
__label__
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjj000000jj000000jj0000jjjj0000jjjj00jj00jjjjjjjjjj000000jj00jj00jj000000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjj000000jj000000jj0000jjjj0000jjjj00jj00jjjjjjjjjj000000jj00jj00jj000000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppppp00pppppp00pppp0000pppp0000pp00pp00jjjjjj00pppppp00pp00pp00pppppp00jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppppp00pppppp00pppp0000pppp0000pp00pp00jjjjjj00pppppp00pp00pp00pppppp00jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pp00pp00pp000000pp00pp00pp00pp00pp00pp00jjjjjjjj00pp0000pp00pp00pp0000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pp00pp00pp000000pp00pp00pp00pp00pp00pp00jjjjjjjj00pp0000pp00pp00pp0000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppppp00pppp0000pp00pp00pp00pp00pppppp00jjjjjjjj00pp0000pppppp00pppp00jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppppp00pppp0000pp00pp00pp00pp00pppppp00jjjjjjjj00pp0000pppppp00pppp00jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pp000000pp000000pp00pp00pp00pp000000pp00jjjjjjjj00pp0000pp00pp00pp0000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pp000000pp000000pp00pp00pp00pp000000pp00jjjjjjjj00pp0000pp00pp00pp0000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pp000000pppppp00pp00pp00pp00pp00pppppp00jjjjjjjj00pp0000pp00pp00pppppp00jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pp000000pppppp00pp00pp00pp00pp00pppppp00jjjjjjjj00pp0000pp00pp00pppppp00jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00kkkkppppppkk00jj00jj00jj00jj00jj000000jjjjjjjjjjjj00jjjj00jj00jj000000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00kkkkppppppkk00jj00jj00jj00jj00jj000000jjjjjjjjjjjj00jjjj00jj00jj000000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppp000000ppkk00jjjjjjjjjjjjjjjjjjjjjjjjjjjj00000000jjjj0000jjjjjjjj0000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppp000000ppkk00jjjjjjjjjjjjjjjjjjjjjjjjjjjj00000000jjjj0000jjjjjjjj0000jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppp00jj00pppp000000jjjjjj00jj00000000000000ppppppkk0000ppkk00jj0000ppkk0000000000jjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppp00jj00pppp000000jjjjjj00jj00000000000000ppppppkk0000ppkk00jj0000ppkk0000000000jjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppp00jj00pppp00ppkk00jj00pp00ppppppppppkk00pppp0000pp00pppp0000pp00000000pppppppp00jjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00pppp00jj00pppp00ppkk00jj00pp00ppppppppppkk00pppp0000pp00pppp0000pp00000000pppppppp00jjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj009999000000999900999900jj00990099990099009900999900009900999900990000999900999900009900jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj009999000000999900999900jj00990099990099009900999900009900999900990000999900999900009900jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj009999999999990000999900jj0099009999000000990099999999000099999900jj00999900999900009900jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj009999999999990000999900jj0099009999000000990099999999000099999900jj00999900999900009900jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00999900000000jj0099990000009900999900jj00990099990000jj00999900990000pppp00pppp00009900jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00999900000000jj0099990000009900999900jj00990099990000jj00999900990000pppp00pppp00009900jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00kkkk00jjjjjjll00ppppppppppkk00pppp00kk00pp00pppp00jjjj00pppp0000pp00kkkk00kkkk0000pp00jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjj00kkkk00jjjjjjll00ppppppppppkk00pppp00kk00pp00pppp00jjjj00pppp0000pp00kkkk00kkkk0000pp00jjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjj0000jjjjjjjjjjkk000000000000jj0000kkjjpp00pp0000jjjjjjjj0000jjjj00jj0000jj0000jjjj00jjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjj0000jjjjjjjjjjkk000000000000jj0000kkjjpp00pp0000jjjjjjjj0000jjjj00jj0000jj0000jjjj00jjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjkkllkkjjllkkkkkkjjppkkkkjjkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjkkllkkjjllkkkkkkjjppkkkkjjkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjj000000jjjjjjjjjjjjjjjjjjjjllkkjjkkkkllkkjjkkkkppjjkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjj000000jjjjjjjjjjjjjjjjjjjjllkkjjkkkkllkkjjkkkkppjjkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjj000000jjjjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddddddjjddjjddjjjjjjjjjjddjjddjjddddddjjddddddjjjjjjjjjjjjdd
jjjjjj000000jjjjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddddddjjddjjddjjjjjjjjjjddjjddjjddddddjjddddddjjjjjjjjjjjjdd
jjjj00jjbbbb00jjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddjjddjjddjjddjjjjjjjjjjddjjddjjddjjddjjjjddjjjjjjjjjjjjddjj
jjjj00jjbbbb00jjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddjjddjjddjjddjjjjjjjjjjddjjddjjddjjddjjjjddjjjjjjjjjjjjddjj
jjjj00jjjjjj00jjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddddjjjjddddddjjjjjjjjjjddddjjjjddddddjjjjddjjjjjjjjjjjjdddd
jjjj00jjjjjj00jjjjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddddjjjjddddddjjjjjjjjjjddddjjjjddddddjjjjddjjjjjjjjjjjjdddd
jj0000lljjjj0000jjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddjjddjjjjjjddjjjjjjjjjjddjjddjjddjjddjjjjddjjjjjjjjjjjjjjjj
jj0000lljjjj0000jjjjjjjjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddjjddjjjjjjddjjjjjjjjjjddjjddjjddjjddjjjjddjjjjjjjjjjjjjjjj
00kkkkkkkkkkpp99000000jjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddddddjjddddddjjjjjjjjjjddjjddjjddjjddjjddddddjjjjjjjjjjdddd
00kkkkkkkkkkpp99000000jjjjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjddddddjjddddddjjjjjjjjjjddjjddjjddjjddjjddddddjjjjjjjjjjdddd
kkppppkkpppp99pp99999900jjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
kkppppkkpppp99pp99999900jjjjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
ppppkkpppppppp99pp99999900jjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
ppppkkpppppppp99pp99999900jjjjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
ppkkpppppppppppppppppp999900jjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
ppkkpppppppppppppppppp999900jjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
ppkkpppppppppppp99ppppkkpp00jjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
ppkkpppppppppppp99ppppkkpp00jjjjllkkllkkkkllkkkkkkkkppkkkkppkkppjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
9944999999999999aa99994499003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
9944999999999999aa99994499003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
99449999999999449999994499003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
99449999999999449999994499003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
99449999999999449999994499003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
99449999999999449999994499003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
99449999999999449944449999003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
99449999999999449944449999003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
44994499999944994499999999003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
44994499999944994499999999003333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
jj44444444444444jj99999900333333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
jj44444444444444jj99999900333333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
00000000000000000000000033333333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
00000000000000000000000033333333jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
000000000000000000000000000000jjjj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
000000000000000000000000000000jjjj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
333333bb3333bb3333bb333333bb3300jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
333333bb3333bb3333bb333333bb3300jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
33jjjj33jjjjjjjjjjjj33jj33jjjj00jj44jj4444jj44444444994444994499bb33333333333333333333333333333333333333333333333333333333333333
33jjjj33jjjjjjjjjjjj33jj33jjjj00jj44jj4444jj44444444994444994499bb33333333333333333333333333333333333333333333333333333333333333
jjjjjjjjjjjjjjjjjjjjjjjjjjjj6600jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
jjjjjjjjjjjjjjjjjjjjjjjjjjjj6600jj44jj4444jj444444449944449944993333333333333333333333333333333333333333333333333333333333333333
jjjjjj66jjjj66jjjjjjjjjjjj667700jj44jj4444jj444444449944449944993333qq3333333333333333333333333333333333333333333333333333333333
jjjjjj66jjjj66jjjjjjjjjjjj667700jj44jj4444jj444444449944449944993333qq3333333333333333333333333333333333333333333333333333333333
jjjjjjjjjjjjjjjjjjjj66jjjj667700jj44jj4444jj44444444994444994499qq33333333333333333333333333333333333333333333333333333333333333
jjjjjjjjjjjjjjjjjjjj66jjjj667700jj44jj4444jj44444444994444994499qq33333333333333333333333333333333333333333333333333333333333333
jj66jjjjjjjjjjjjjjjjjjjjjj667700jj44jj4444jj44444444994444994499qqqq3333333333bb333333333333333333333333333333333333333333333333
jj66jjjjjjjjjjjjjjjjjjjjjj667700jj44jj4444jj44444444994444994499qqqq3333333333bb333333333333333333333333333333333333333333333333
jjjjjjjjjjjjjjjjddjjjjjjjjjj6600jj44jj4444jj44444444994444994499qqqq33qq33333333333333333333333333333333333333333333333333333333
jjjjjjjjjjjjjjjjddjjjjjjjjjj6600jj44jj4444jj44444444994444994499qqqq33qq33333333333333333333333333333333333333333333333333333333

__gff__
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000060600000001010000818a0606060000000000000a0a0a0a0a0a060606000000000002020a0a0a0a0a0a0000000000000a0000020a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a0200000000000a
0000000002020000000000000000000000000000020202020000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000
__map__
2a2b000102007677787777781010107677787979795200500708094042002c2d373839104a4b4c4d10070809ecec7dd87ed97d001d0c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b0011120050515251515210101050515266666652005017181960620000007071724a4b5b5b4c4d174f19fcfd00000000001d0d6a0e1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738397072005551545151521010106061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829e1e2e3e40000000d6a6a6a0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe029003528be880b8c0cbb3bb8b0a80384f1a222b129a02abf1a828333300436b7319b9c1ca733b43c2a363d35943e3daf70a1a1723fbc9b1293208ffc69f99f9db626e2486e7aef279efb3efc0d27ae27e3f8709f8eebae27fe37e3ff91c5bf97e7f91f38fd3f3fcff32fe3efea9fb1cfe92dfdf9e1fc713f
9feb93f0e37f50fce7f6dbf247fec7f87fa9fe4e475e75fb7fd495f5e5fba7fe049c71fbdffc3dbf39fb7fe24fe2ce2ffe2bff82757ff1ffe49ff803aaeb73bff17fe2affcbd5ffc1fc7fdaffe6ffcfffa0e9c7fe9e3f1ae4fca7fe07e53f7ff8fd7b9f8389ffabff5f7648bf9ffec9f9cffc2fe5c771ffa5a6fd9d1f91f9c07
3bafbf4713fbfeff19ffb759acbf9cdb7fedffd9ff0270e672f676ef7fe17eefe36ffd07fe2affddffbe4ffe174b64b769bff37ff1c707b7a9c228e05773be1ff86c9fb493f407e33ff9497ff9896f93f789ffd14c47e3e953923a1ca0aa9677c7e7ffd6445fe8e4a54fc540f0a9c71c7fe2e938bffda4fb71ffdc4e58ee7ea5
ed3f79faf6772c9c495fc83f0257fe40e24bc4fcbffbfcf53de24ffed3fb35e7b9cf5ef5f87e1fa7e9fa74e7892fe257a3f27fdc1dbf8ee7e1f824ffc49f9493f053899f96fc1fe7fe6e5ffe13ffc97ffd7ffafff5d3ffd54fdefff1ffd1ffc7f28ffee7f3371792b8904e091ccff7ff2c9fb1cfbf87e1032fe0fc394e1ec9f9
41d398fd9bf1918b3ffcd90fca8e9f81fa5dc7e6ffc046ffc5fb7fe2a1cf1fcbfa6e6162c271fb7edfca5842c7f5880f5ffe49d6d3d4907e43d3ddf97bcce1ffecffcdf875fff3f2ffc7fff5fc5d6449288fcb909dcffbfff10424bb938bf7e1f8dbfeffeaffac9f82ffe98f8f2efffb7ab9f8a1e2d4f78fcbf57edf90e64fd7
4d5bfbfffcf32087fb090fedb99ecbd3ff67fe7ffd1ffa7f6eff36a21ede9df09c80c27209c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3affd548060c3168a3a1be262bdfdbb87279f73a7520c0ab8f272e1097066b0db5cfbf8492b6e38e64ebbbadbba77af9ecfda7c983e9c71b71efb74fc1f8cf7d93ab5dfe6dccfc3a73f8fe5f9f7f9f80e4d27e0b3bef4e27ecfcbf6eb98edefe71eaee30f26d1edab47e827e8e53f675ffa27eaedbce1f84cee7e2a
fcb48fea7ecafdf8dc2ab2a44e27ff2cd27aa9e42b7e23ac27eb3f8fe64ed77e5fafedfbc8c928a247ff4a3f0ab6c4dbd92a90bf9d9fa51d2f90ffc85cbe3f107e226795fd7f7fd44e3aff24fc90fa249047e7d7fbff4ffc1d7fe1bc253f57f9f970979793f3a95fae93a7c402585fa7cd3fc4dbfd8e979927af7f35faffd263
f3b2acffc4e61fc9c0834eab95d6bbe2449c24fc5254912444091c3f24e1fb5ffc7ff8fff1f578e26962ce613995f972e648d6f3cce39731ffa2392729fe753f97df4e4147e53ff238ebce5c221a1622fd1ffacfe62a5e751cb7eb3ff2de119cf08964e1c9d3fcffcd3f1fc7abf8c92493dbf92753a98c7e727034389ea4f527
4f9fb733d43c954ffc77ff3f1d1239257229f9c378e5c379ecaffd0389ffa5e2f0f24ed27a93d575ddebff3d9090909090ede4b2218fd219200df84df8f934962fe30eedffc0ffc0de153f391fa48d0f52c11bfc71ff88fc0fccfff1ffd1ffc7f28ffee7f3371792b8904e091ccff7ff2c9fb1cfbf87e1032fe0fc394e1ec9f9
41d398fd9bf1918b3ffcd90fca8e9f81fa5dc7e6ffc046ffc5fb7fe2a1cf1fcbfa6e6162c271fb7edfca5842c7f5880f5ffe49d6d3d4907e43d3ddf97bcce1ffecffcdf875fff3f2ffc7fff5fc5d6449288fcb909dcffbfff10424bb938bf7e1f8dbfeffeaffac9f82ffe98f8f2efffb7ab9f8a1e2d4f78fcbf57edf90e64fd7
4d5bfbfffcf32087fb090fedb99ecbd3ff67fe7ffd1ffa7f6eff36a21ede9df09c80c27209c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe18028a9028c2b2caba323a40c8ba830b8b934ac7170a222b3038404bbbc3b312ab03ca4a5259e1ea72da020a12a2d2fa7bf938b0a94f19312942e1b9c1afff53b929bcef8e7aefcf7ef9c7e1e14b25a96c9f8bf98fc627ffa3bdf97e7fa75e5fcbf5fca71fb7dfbff1f9709e3f2ffd723ff84fe7f36feafe9
fd9ef93fcff4ff6bfd3fe10ff21e1dbff070ffc09ff867fe39f87e09f858ffc526ffc737cfcafd3f474fd3924ffc5ff813ff0731ff93f29cce4f0d3f1fe8fca4e79fa737f24e5f03f797ff2effc70f0eb49ff7fd67fe0ffcd53f39263989f821c9c69ff9c8208773693599ff9e7e69ffa3ff4d3174ffd5ffae727e6ffd94e627
6589d27e0fdfb7efecfef49a5a381c37f5ffb4389ffbbff79ffc3fd97fd8750e0434ffc7ff92cffcb7f2bffc7ff83f63f381ffcac96eb7ff4fe4bf97ff06b6cfc271c1ff8ff089f94ffe63ffa7eae7f7a398713ff59373c493a5fe0ea7ff5709f973ffdbffbfff47ff8fff3f9eb7ff0a5e113ff0493f6680161d127e848c58be
1f8e7fe3ffca93c707e7c7fe3bffe3ff16fc22c87f87047fad6723cc9c57eefc27fe7f4ffce5b3bc7e5ea713ff1bfc848bcbbf92bfe4fff517ffdcfff83d3c527d78fca53993927d7ff27f1d77b5febfe93a55fc670ffd139fffbec9096de7ff04bfd4ee08ffc5c843ffafa13f0b043f1e75ffe3ffc10df9efffdfffc0fffe0f
ffe71df7ed922c786f0026e7f0ffe3ffbe887fb0cfffe142f3ecfe6fffddea54b1f43c9fe7f89fe54ff3f038821c30f300391ff9e49aff1fe7f1591ffe694e13b87fe57d4e8123dffd50e4a27e2fc4c944fc5f8827e2fc40f10424bb938bf7e1f8dbfeffeaffac9f82ffe98f8f2efffb7ab9f8a1e2d4f78fcbf57edf90e64fd7
4d5bfbfffcf32087fb090fedb99ecbd3ff67fe7ffd1ffa7f6eff36a21ede9df09c80c27209c8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe43c003b292870bef13f038404f83b930c2f8a94b022bfa8b78ba78c93940b3536b7363d35b3b42323a4313e3daf2b2ba4ac272cb48e860e2e0687082525a626adad2e8fc647fffd57f26ffffb27e49370e5774871de95ffff3d7cf7d75f7e1c79f8fe3f8a73cb72e78ffff974fcbf3fd3f5fdba77fbff1fcf
f5fdff889feffdffff3e7ff07fe1ffc5face2f3fa7e9fa7e9dc5f3f2fc7fffc8ffc7f929e4397e9a4fd7fffc8f25ffc9ff965b24fcd3fffd5d7fe6ffcfffa3ff4ffea9092c93f173f8cffd7ffb24ffdb7fffadcffeeffdf3ff87e1f878fdff04ee7ff1383ff97ff3ffe87ff5fffebcffece5f860ffedfadffd1ffa61f6bf7ff7
f8fbfffaeef4ffcde85ffce6b6cb649facfff1f87fff6b9dfa7e83988eaf1cfff9fff5ffeefb2ee67ffcfff87ffc3ffe0fffeaf5ffc67e2ffd3fd7f567f5ffa79e77ffdffddfffac4992dfbf17edf9c927fff03fff83fffc2fffe1ffff1339db6dc7fff24c4248ced3f5b274d12d9247fca935fd7f5fffe2afedf9b72efbefbd
fffc5123a7e529d7e3ba133ffe7bfff0bcbfff8d9fffc7fffe8072f97ff1c9c2713ff1bf23c848bc4eba38f12bfe4ffef17ffc4fff2e7ffd7ffbe7f6fff0e0f14bf5e3f287e4398df8effc7fc75bace3afa3ccbf8ce83fa22f539fff9ec825bbaffc12ff339824ffc32d98bf904fc2d21f8f1afff1ffdc87e7bffef5d7ffd71d
f7e588b5e1bc009b8fc3ff7ffeda439bc4ebf4867ffe84ededfdf7ffccf12a111f43c9fe7f89fe53fd8e20870c075801d0ffcf24d7f8ff7f8ae11ffdba384ee1ff95e7c091d7fea872513f17e2f9fc7b4e3afcbf1fcfcf13ff438ffc69a77ca0e7ff5ffe4ffcbffa3f4e3f34e21fb27200000000000000000000000000000000
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

