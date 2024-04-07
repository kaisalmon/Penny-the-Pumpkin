pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--penny the pumpkin
title_y=8
label=false

max_coins=15
function init()
t=0
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
	local draw_cpu_usage = stat(1) - stat_1

	if debug then
		print(player.x..","..player.y.." "..debug,1,1,7)
		print(player.block)
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
	if (move_dir < 0) ch.dx -= ch.speed
	if (move_dir > 0) ch.dx += ch.speed
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
		p.x += p.dx
	else
		p.dx *= -1
		p.dx *= p.bounce or 0
	end
	
	p.dy=min(p.dy,4)
	p.dy=max(p.dy,-10)

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
local chunk_size=6
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

tunnel=split("0,-16,-4,1,0,5,6,8,-3,-1,12,12,	1,14,15")
spooky_tunnel= split("0,130,131,132,0,5,13,136,137,9,3,12,13,8,4")
forest_pal=split("138,2,3,4,147,6,7,8,9,10,11,12,13,-4,15")
spooky_pal = split("128,130,131,132,133,5,134,136,137,9,3,12,13,8,4")
day=split("-4,2,3,4,5,6,7,8,9,10,11,12,13,14,15")

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
		"32,1,3,1,66,3",
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
		{x=15,y=11, miny=20, maxy=100, minx=80, maxx=290},
		{x=24,y=9, miny=20,  maxy=100, minx=80, maxx=290},
		{x=33,y=11, miny=20,  maxy=100, minx=80, maxx=290}
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
ffff8ff73dfbff7e920003228a2a031b308273aa021ac0c83048408b53b2b2ca334b637bb3b3cee3cefbf3ffb0fe6353cbcbd377e3d33bd67a92b9c9c932324a
f64a0aa27fa9eeeee005051d7085859db056bd17fcc5ab6e5ffde997e99c7f1e87cff7f2fc4fdf756ffd5af9fb8ee761e7f93cfa7eafeffe9fefbcf7fecf31b8
ff78ff715e7ef78fff2ff4cffacf2df75ee78694ff395fbbfff3f1af83cdff3ef8cff78f2ef4cfd71fffb9fff2eff5df42ff7cff78d96c9df1bcfbcff3affb0f
ffbeff5cffb8ff4629ed763fcef7deaeff2eff5cecf9bf4af5cf75bfff0dbbfff2efe5c6f7e5cdff3c4d52ffdcff988f8494ffcbff0ef71f79ff59ebf33f73fe
ff788fff4afffb9fdc8ff75ecf52f763ff4e79ff349ff4900e4f155c887c21d39c1d87ff9eff0c2bf47c5e946ef75fd9ff5fffaef8cfff7eefc5f98f72eff1df
cd7eeff4ef5d7dfff7fff1dfffcfff8fff3f832e127d053522ff9f2155f9bff31fe771efff7a61b5f2fff6dff1c85e72ef36f18f6e07ff3cafe95afb9ffb2f93
f830fbfff5efffdfffbfff7ffffeffcda69348d1f99ff74fffaeff8ccfda027acff19f25f34f0cffecc9ec8fffddcffff3fff33f86340d96bfff5ff1afbaff37
afc9f31280cb1cfceff6fffbbff9ff499e7c42d1f34fffceff9d8f9317f3f07eff8ff1ff1c72df80baeef94ab83d0fbe1fcff7b14c7eff94ff19fb1fff3eff0c
39e92283ffef31f75e273e485e21b4f33ff79e19ffacf43c0fff3ca3def73ff40dff4de9f40dd983feff70eff4cfe2f58fb8c452fffcf19ffcdf41df6f09c0f3
8fe4903c3d37bffecffb8f9f274fcfb20f2bdfcf8c7f5317f3ff1816ff688bcbb5fffa2872752c3fffb848aee77c3b86f93c381cffd983f99f9eff391ff7fff0
989de07eff1fe19b3bffd33ff79eff1dff3af9fc722cffde93459e6c7edfff49cff2eff6ff2efb819a96c61ef8bc78effc0dffdc503eaa8549c1a5ff6cf71e3b
ff8f3deef9cf77ff1fffff19ffcfd9f88ecff2d57f35ff53c9f374237178ff2f9bcffabdfff5ff2fffff99ffcfedb2793937b2b9f0ff00000000000000000000
00000000000000000000000000000000000000001111111999991111111111111111111111111111111111111111111111111111111111111111111111111111
000000000000000000000000000000000000000011111199999aa911111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000001111199991199991111999911111111111111111111111111111111111111111119111111111111111111111
00000000000000000000000000000000000000001111199911119991199449a91111999999111119999991119911111199111119119111191111111111111111
1111111111155111111111110000000000000000111119991111999199911199911999449a9111999449a9199a911119a9111119119991919111111111111111
11111111119455111111111100000000000000001111199999999941999111999199941199a9199941199a9499a1111999111199919191999111111111111111
11111111194945511111111100000000000000001111199994444419999999991199911149991999111499914999119999111119119191911111111111111111
11111111149444511111111100000000000000001111199991111114999411111199911119991999111199911499919994111119911111199111111111111111
11111111944444551111111100000000000000001111199991111111999111111199911119991999111199911149999941111111111111111111111111111111
11111114454545455111111100000000000000001111199991111111499999999199411119941994111199411114999911111111111111111111111111111111
11111144545454545511111100000000000000001111199991111111144999944144111114411441111144111111999411111111113111111111111111111111
11111145555555555511111100000000000000001111149991111111111444411111111111111111111111111119999111111111494911111111111111111111
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
11111661544999111155499915449911111911111111111711111111111177177777111111111111111111111111111111111111111111114555555945555559
11111161444476911567444915474911115691111177717771777111111777677777711115115111115111511111111111111111111111114555555945555559
1661161146777769567777741547491115676911177776777677771111177777777767711511511111511151111d111111111111111111114555555944555559
116116614444764114674444154744541577791117777777777776711767777777777771151151555151155111d7d11111111111111111114555555944555555
1611111155555511115555551577751114474411177777777777777177777777777777671555515151515151111d111111111111111111114444444445555555
16611111111511111111511115676511154744547777777777777771777777777777777715115155515155511111111111111111111111115454545455555555
11111111111411111111411111465111154644117777777777777767167777777777777711111111111111111111111111111111111111114545454555555555
11111111111411111111411111151111155444111677777777777777177777777777777711111111111111111111111111111111111111115555555555555559
00000000005353535353000011111111111111111777777777777777777777777777777711111111111111111311111111111100111100111115151100000000
00000000000000000000000011188811111111111777777777777671776777777777677115551111111115519a91111111111108011080111115551100000000
00000000000414141424000011811181ddd11111117767776777771111777777777771111151111111111551a9a1111111111100011000111111511100000000
0000000000000000000000001818111811d111111111777771777711117776767767711111515151555515511111111111111111111111111115551100000000
0000000053051515152500001811811811d111111111777771111111111771771177177111515151515515111111111111111101010101111115151100000000
0000000000000000000000001811181811d111111111177111111771111111111111177115515551511515111111111111111110101011111115551100000000
002e000004550000002500001181118111dddd111111111111111771111111111111111111111111111111111111111111111111111111111111511100000000
00000000000000000000000011188811111111111111111111171111111111111111711111111111111111111111111111111111111111111115551100000000
__label__
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg00000000000000000000000000000
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg06660666000006660606000006660
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg06060606006006060606000006000
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg06060606000006060666000006660
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6gggggggggggggggggggggggg06060606006006060006000000060
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg06660666000006660006006006660
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg00000000000000000000000000000
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggg6gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6gggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666ggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666666gggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666666666gggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666ggggggg6ggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6gggggggggggggggggggggggggg6666666666ggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666gggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666ggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666gggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg666666666ggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666ggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg666666666gggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg666666666gggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666gggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666gggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666gggggggggggggggggggggggggg
gggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666gggggggggggggggggggggggggg
gggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666gggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666ggggggggggggggggggg6ggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666ggggggggggggggggggg6ggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666ggggggggggggggggg6gggggg
ggggggggggggggggggggggggggggg6gggggggggggggggggggggggggggggggggdggggggggggggggggggggggggggggg666666666666ggggggggggggggg66gggggg
gggggggggggggggggggggggggggggggggggggdggggggggggggggggggggggggd6dgggggggggggggggggggggggggggg6666666666666ggggggggggggg666gggggg
ggggggggggggggggggggggggggggggggggggd6dggggggggggggggggggggggggdgggggggggggggggggggggggggggggg6666666666666ggggggggggg666ggggggg
gggggggggggggggggggggggggggggggggggggdgggggggggggggggggggggggggggggggggggggggggggggggggggggggg666666666666666ggggggg66666ggggggg
ggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666666666666666666gggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666666666666666ggggggggg
gggggggggg6gggggggggggggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggg666666666666666666666gggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666666666666666ggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg66666666666666666gggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggg6666666666666gggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6666666ggggggggggggggggg
ggggggggggggggggggggggggggggggg6gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6gggggggggg
ggggggggggggggggggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggd
gggggggggggggggggggggggggggggggggggggd6dgggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggg6ggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggg6gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggd6dgggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggg6gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggd6dgggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggdgggggggggggggggggggggggggggggggggggggdggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggd6dggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg6gggggggggggggggggg
ggggggggggggggggggggggggggggggggggggggggggdg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggg00gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggg00gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggggggg00j300gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggg6gggggggggggggggg00jj00gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggggggg000lj000ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggggg000kkkkkpp9000gggggggggggggggggggggggggggg6ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggggggggggg0ppkpppkp99p9990ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggggg0pkkppkkpppp9p9990gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggg00pkpppkpppppppppp9900gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
gggggggggggggggg00pkpppkpppd55p9ppkp00gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
ggggggggggd555jl00pkpppkpppd55p9ppkp00ggggggggggggggggjl3jgg3j3g3gggggggggggggggggggggggggggggjl3jgg3j3g3ggggggggggggggggggggggg
gggggggggd55555j00kkpppkpd555555ppkp00gggggggggggggggjljj3j3j3j3j3jggggggggggggggggggggggggggjljj3j3j3j3j3jggggggggggggggggggggg
ggggggjjgd55555l00kkkkpkpd555555ppkp00jjggggggggggggjljljjjjjjjj3j3gggggggggggggggggggggggggjljljjjjjjjj3j3ggggggggggggggggggggg
gggggjjjgd55555j00jkkkjkpppd55kpkkpp0jjjgggggggggggglgljjjjjjgjjj3j3jggggggggggggggggggggggglgljjjjjjgjjj3j3jggggggggggggggggggg
jjgggjjggd55555j00jkkkjpkkpd55pkjjpp0jjgggggggggggjljljjjjjjjjjjjj3j3jggggggggggggggggggggjljljjjjjjjjjjjj3j3jgggggggggggggggggg
jjjgjjjggd55555jjgjljkjkkkkd55kljjj0jjjgggggggggggljljjjjgjjjjjjjgj3j3jgggggggggggggggggggljljjjjgjjjjjjjgj3j3jggggggggggggggggg
gjjgjjgggd55555gjjj0jjjj000d55000jjgjjgggggggggggljljjjgjjjjjjjjjjjj3j3ggggggggggggggggggljljjjgjjjjjjjjjjjj3j3ggggggggggggggggg
000000000000000000000000000000000000000lggggggggljljjjjjjjjjjjjjjjjjj3j3ggggggggggggggggljljjjjjjjjjjjjjjjjjj3j3gggggggggggggggg
jjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jj3jjj3j0ggggggjljljgjjjjjjjjjjjjjjgjjj3j3gggggggggggggjljljgjjjjjjjjjjjjjjgjjj3j3gggggggggggggjl
jlljlllljlljlllljlljlllljlljlllllljljll0gggggjljljjjjjjjjjjjjjjjjjjjjjj3j3jggggggggggjljljjjjjjjjjjjjjjjjjjjjjj3j3jggggggggggjlj
llllllllllllllllllllllllllllllllllllll50ggggjljljjjjjjjjjjjjjjjjjjjjjjjj3j3gggggggggjljljjjjjjjjjjjjjjjjjjjjjjjj3j3gggggggggjljl
lll5ll5llll5ll5llll5ll5llll5ll5llllll560gggglgljjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggggglgljjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggggglglj
llllllllllllllllllllllllllllllllll5ll560ggjljljjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggjljljjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3jggggjljljj
l5lllllll5lllllll5lllllll5lllllllllll560ggljljjjjjjjjjjjjjjjjjjjjjjjjjjjjgj3j3jgggljljjjjjjjjjjjjjjjjjjjjjjjjjjjjgj3j3jgggljljjj
lllllllllllllllllllllllllllllllldlllll50gljljjjgjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ggljljjjgjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ggljljjjg
llllllllllllllllllllllllllllllllllllll50ljljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ljljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3j3ljljjjjj
lllllllllllllllllllllllllllllllllllll560jljgjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjgjjj3jjljgjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjgjjj3jjljgjjjj
llllllllllllllllllllllllllllllllll5ll560ljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3ljjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3ljjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll5560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
dllllllldllllllldllllllldllllllll5ld5560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll5560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
lllldllllllldllllllldllllllldlllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
lllllllllllllllllllllllllllllllllllll560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllll5ll560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllllll50jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll5560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
dllllllldllllllldllllllldllllllll5ld5560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
llllllllllllllllllllllllllllllllllll5560jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj

__gff__
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000060600000001010000818a0606060000000000000a0a0a0a0a0a060606000000000002020a0a0a0a0a0a0000000000000a0000020a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a0200000000000a
0000000002020000000000000000000000000000020202020000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000
__map__
2a2b000102007677787777780a0b107677787979795200500708094042002c2d373839104a4b4c4d10070809ecec7dd87ed97d001d0c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b001112005051525151521a1b1050515266666652005017181960620000007071724a4b5b5b4c4d174f19fcfd00000000001d0d6a0e1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738397072005551545151521010106061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829e1e2e3e40000000d6a6a6a0ec0c1c1c20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe0a9003528be880b8c0cbb3bb8b0a80384f1a222b129a02abf1a828333300436b7319b9c1ca733b43c722a363d35943e3daf70a1a1713fbc9b1293208ffc69f99f9db626e2486e7aef279efb3efc0d27ae27e3f8709f8eebae27fe37e3ff91c5bf97e7f91f38fd3f3fcff32fe3efea9fb1cfe92dfdf9e1fc71
3f9feb93f0e37f50fce7f6dbf247fec7f87fa9fe4e475e75fb7fd495f5e5fba7fe049c71fbdffc3dbf39fb7fe24fe2ce2ffe2bff82757ff1ffe49ff803aaeb73bff17fe2affcbd5ffc1fc7fdaffe6ffcfffa0e9c7fe9e3f1ae4fca7fe07e53f7ff8fd7b9f8389ffabff5f7648bf9ffec9f9cffc2fe5c771ffa5bff6efd9d1f91
f9c073bafbf4713fcff3f19ffbb59acbf9cdb7feeffd9ff0270e672f676e166ffc2fddfc6dffa0ffc55ffbfff849ffc6e96c96ed37fe7ffe58e0f6f538451c0aee77c3ff0d93f6927e80fc67ff392fff412df27ef13ffaa988fc7d2a724743941552cef8fcfffb488bfd1c94a9f8a81e1538e38ffc5d2717ffbc9f6e3ffc09ff
e58ee7ec5f13f79faf6772c9c495fc83f0257fe40e24bc4fcbffc7cf93de24ff27f66bcf739ebeebf1fc7f5fd7f5e9cf125fc4af47e4ffb83b7f1dcfc3f049ff893f2927e0a7133f2df83fcffcfcbff8a7ffa2fffbfff7ffefa7ffba9fbdffe5ffa3ff97e51ffe0fea6e2f2571209c12399feffe593f639f7f0fc2065fc1f872
9c3d93f28387ffb398fd9bf1918b3ffd590fca8e9f81fa5dc7e6ffc046ffc5fb7fe2a1cf1fd3fa6e6162c271fb7edfca5842c7f7880f5ffe89d6d3d4907e43d3ddf97bcce1fff0ffcdf875fff7f2ffc7fff9fc5d64492d9fbfe7ca13b9ff7fff0082125dc9c5fbf0fc6dff7ff57fd64fc57ff4c7c7977ffebd5cfc50f16a7bd7
e5fb3f7fcfff5b993f6d356feffff80f32087fb090fedb99ecbd3ff67fe7ffd1ffa7f6eff36a21ed3be13900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bffd6a400c0c28aa2a0de4688c4bcfe6e70723c7ce6a6a883c480aac6c8e4e0845c0c6a866cb8fafc2495b71c71273d5d7bbc74e35f3d9fb4f9307d38e36e3df6e9f83f19ef52756a7e6bccfc3973f8fe5f9f7f9f80f0d27e0b3df74e38fd9f8fedd731d3cfca3c5dc61e4da3cb568fd04fd1ca7ecebff44fd5db7
9c3e99dcfc15f8e91fd4fd95fba54dc2ab2a44e27ff2cd27aa9e42b7e03ac27eb3f8fe64ed77e7e7e7dc8c920a247ff4a3f0ab6c4dbdf255217f3b3f4a3f587ef3fa7a5cde3f107e2267b3fbff3fa89c75fed990fa2c9047e7d7fdff81ff87affc5784a1fd7e6ff7f2e12f2f27e952bf5d274ec8402585fa78d3fd4dbfe8e963
f8924f9f7e6bf5ffa4c7e76559ff8dcc3f9381069d5713ebb549a549ca4fc52549124440912703f34e1fb5ffc9ff93ff27579e66962ce613999f95731235fd79e66e4efff4f15d4e784ff24fe9bf0fc2720a3f29ff95c77e72e101a1622fb1a76ffc443f99326eb52f2dfacffcd784673c2259397276ff7ff3cfc7f1eefe327e
249edfc93a9d4c63f39381a1c4f927c93a7cfdb99ea1e4aa7fe3bffa38e891c92b914fce1bc72e1bcf657fe91afe1ffaa78bc3c93c49f24f95df93b927fe84848484876f65910c7e90c9006f44df97934962fe30f2447fe1ff1bc2a7e723f491a05ed2c11bff0baff4fc0fcc277438fdbf79fd1292ffe1d5f938393ae0bc3f18
bd9814b6b6a8cffc0b6fe11ef296a4fc1ff90fdcffd5cdffc7ffa9e271389fe4245d5349c4e6cea38274fd0f149d25b3ff1497ffcf5ffaabff447e63ebfd73fffc1ef77bff97ff1932afe371c4efb4eeb7fe7ffcfff84e13fff85fffc3e384a7e7235ed3b3e43ffefa27fff07ef11ba03f1e75fff7ffb82471a77070e3fe393b
87fb133fff890bcf6feafffddea5912cfd2b9e7ba11c8bc7fe0ffc3feff0256fdb05be1ff9e4baff1ff87f8acaffe0e4e13cbffe7ffd44e6717b4a9d9e9d025b5ffa657d1ffb3f20d9f900657d1ffb3f200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffff87fd3bfffe28028a90c0cbe8bab2cabac2833b42230b13f2323a434f122b3038404a4bb2ae060e13bbc0a940b61e2303c9493a525a72da020a12a2d2fa7bfb970831c1c9afff53db2e369c7269d75df9ef5cf367764b78e3ebf87e33f697f189ffe8ea7e5f9afe9dfae7f07eafdbf793f839fdff9fdff77e5f9bf54fdff
7b1fbc9fc5f93f29fd3ff8491bfbbfdff87e6effdffbfeffbff03f9ffc2ae3fe3fe73ff7fcffbff049221c4ffc5ff8ef9ff93ff2ffe6fecffc3fd5f4f1ff9fa9ffa227bea7b7fc96a5b1ff9e4bfd4df3f4b289bfe5fe0967fe9ffd49ffaef93ff17fe7cfcb71ffaeffeb7f106f9f8bf434ff3ff5affbffb3ff689677de9ddfe3
7e3f8fe3f9812ffeea90e1ffbd3f85bffa7ff87f0bffc7ff5cf13237e5ff9fff3ffe75ffcfff9fff3a7fe7ffcf67fe8e393f14393a91ff8844434efb4eec96c96e45bffcbff9d31eaf33bfc26ffe5ffbf959ff83ffa53b927fe58729ecf7dc9a0befbe89bff97fdffd4389ffdbffb9ffe06e2ffe48cdff86fff0dc4fcff33f33
ff443a418e6bff4feb67feaa3f0bffe7ffc3547076bd088907ffab26bb6fff3f9b7e7ffe132fe52437c227e13ffd8fff9fab9fe06febbefb5416c1373d3f4ffd13ffebf8e7ff97ff5fff8ffd8fcf5bfff92767d6f493fb4481380773fff8048b22c512ffe5e3277438fdbf79fd1292ffe1d5f938393ae0bc3f18bd9814b6b6a8
cffc0b6fe11ef296a4fc1ff90fdcffd5cdffc7ffa9e271389fe4245d5349c4e6cea38274fd0f149d25b3ff1497ffcf5ffaabff447e63ebffb39fffe0f7bbdffcbff8c9957f1b8e277da775bff3ffe7ffc2709fffc2fffe1f1c253f391af69d9f21fff7d13fff83f788dd01f8f3afffbffda1238d3b83871ff1c9dc3fd899fffc
485e7b7f57ffe6f52c8967e95cf3dd08e45e3ff07fe1ff7f812b7ed82df0ffcf25d7f8ffc3fc5657fed72709e5fff3ffea27338bda54ecf4e812daffd32be8ffd9f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

