pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--penny the pumpkin
title_y=8
label=false

max_coins=12
function init()
t=0
wipe_progress = -1  -- -1: no transition, 0-128: transition in progress
fc=0
dust={}
moved=false
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

function _draw()
	local stat_1 = stat(1)
	cls(1)
	pal()
	palt(0,false)
	palt(1,true)
	
	pal(blocks.pal or {1,2,3,4,
						5,6,7,8,
						9,10,11,12,
						13,14,15,16}, 1)
	--if(stat(7) != 60) pal(1,8,1)

	camera(cam_x,cam_y)
	draw_blocks()	
	flicker = revived_at and 
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
		if heart_thought_t>1 or cave_thought_t > 6 or hold_thought_t > 4 then
			spr(time()%1.5 > .75 and 229 or 231,player.x-5,player.h.y-20,2,2)
			if hold_thought_t > 4 then
				spr(time()%1 > .5 and 233 or 249,player.x-5,player.h.y-17,2,1)
			elseif cave_thought_t > 6 then
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
		skw_spr(
			player.x,
			player.y,
			player.h.x,
			player.h.y-4,
			player.w+4,
			player.size,
			0
		)
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
    -- calculate the circle's radius based on the progress
    local radius = 140 * (1 - p)

    -- calculate the circle's center coordinates
    local cx = player.x
    local cy = (player.y + player.h.y) / 2

    -- draw the circular mask
       for x = -128, 128, 1 do
        local dx = x + cx - cam_x
        local dy = sqrt(radius * radius - x * x)
        local y1 = cy - dy - cam_y
        local y2 = cy + dy - cam_y

        line(dx, 0, dx, y1, 0)  -- draw a line from the top to the top of the circle
        line(dx, y2, dx, 128, 0)  -- draw a line from the bottom of the circle to the bottom
    end
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
end

function lerp(a, b, t)
  return a + (b - a) * t
end

function update_character(ch, move_dir, jump, t_stretch, jump_held)
	if (move_dir < 0) ch.dx -= ch.speed or .2
	if (move_dir > 0) ch.dx += ch.speed or .2
	if (move_dir > 0) ch.facing = ➡️
	if (move_dir < 0) ch.facing = ⬅️
	t_stretch= t_stretch or 1
	ch.stretch = ch.stretch and (
		 lerp(ch.stretch, t_stretch, .1)
	) or t_stretch

	ch.tile = t1 or t0 or t2
	
	ch.gnded = not not ch.block
	if ch.gnded then
		ch.last_gnded=time()
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

	update_character_w(ch)
	check_for_squeeze(ch)
	ch.block=nil
	update_particle(ch, ch.dy >= 0)
	update_particle(ch.h, false)
	check_for_squeeze(ch)

	local max_h = ch.size*ch.stretch*1.25
	if ch.h.y + max_h < ch.y then
		ch.h.y = ch.y-max_h
		eject_particle(ch.h, false, 0.5, 1)
		--todo make better
		if ch == player 
		and ch.h.y + 1.5*max(ch.size,ch.size*ch.stretch) < ch.y then
			--die()
		end
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
		(btn(3) and .3 or btn(2) and 1.6 or 1),
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

function add_dust(ch, dy, dx,fullh, t)
	if(#dust > 100 or stat(7)<60) then
		deli(dust, 1)
	end
	add(dust, {
			x=ch.x
				+(rnd()-.5)*ch.w,
			y=ch.y - (fullh and rnd()*20 or 0) ,
			c=11,
			dx=(dx or 1)*(rnd()-.5)-.1*ch.dx,
			dy=2*(dy or -.7)*(rnd()*.5+.5),
			t=(t or 30)+flr(30*rnd()),
			bounce=.7
		})
end

function update_character_w(ch)
	h = ch.y-ch.h.y
	s= ch.size
	ch.w = s*s/h - 2
	ch.w=min(ch.w, 30/16*ch.size)
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
			sfx(1)
			for i=0,20 do add_dust(p,2,2) end
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
	while (is_solid({
			y=p.y,
			x=p.x+p.w/2+2,
		}) and is_solid({
			y=p.y,
			x=p.x-p.w/2-1,
		})) or (
		is_solid({
			y=p.h.y,
			x=p.h.x+p.w/2+2,
		}) and is_solid({
			y=p.h.y,
			x=p.h.x-p.w/2-1,
		})
		) do
			if 	is_solid({
				y=p.h.y-1,
				x=p.h.x,
			}) 	then 
				p.y += 1
				p.h.y += 1
			else
				p.h.y -= 1
			end
			update_character_w(p) --set p.w based on p.y and p.h.y
		end
		
end

function is_colide(x,y,w,inc_semi, h)
	local xs,ys = {x},{y}
	if w then 
		xs = {}
		for dx=-w/2,w/2,7 do
			add(xs, x+dx)
		end
		add(xs, x+w/2)
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
		if p.on_land  then
			p.on_land(p)
		end
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
		p.dy *= -1
		p.dy *= p.bounce or 0
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
	if(stat(7)<60)return 
	if(#dust > 30) then
		deli(dust, 1)	
		deli(dust, 1)

	end
	add(dust, {
			x=ch.x
				+(rnd()-.5)*ch.w,
			y=ch.y - (fullh and rnd()*20 or 0) ,
			c=11,
			type=type,
			dx=(dx or 1)*(rnd()-.5)-.1*ch.dx,
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
alternate = function(b)
	if t%2 > 1 then
		b[3]=0
	else
		b[3]=2
	end
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
day={-4,2,3,4,5,6,7,8,9,10,11,12,13,14,15}

level1={
	px=20,
	py=100,
	pal=forest_pal,
	chunk=19,
	c={
		{x=17,y=3,id=1}
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
			"0,3,32,16,0,0",
			update=function(b)
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
	}
}

level2={
	pal=forest_pal,
	chunk=19,
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
			update=function(b)
					if player.x < 0 and player.y < 100 then
						load_level(level1,31.5*8,6*8)
					elseif player.y > 34*8 then
						if player.x>250 then
							load_level(level3, 156,20)
						else
							load_level(level3, 30, -15)
						end
					elseif player.x > 384 then
						load_level(level6, 5, 90)		
					end
			end
	},
	{
			rx=3,
			colide=false,
			"32,5,16,9,0,0"
	},
	{
			rx=3,ry=9,
			colide=false,
			"32,12,16,1,0,8"
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
	"114,14,5,1,20,14",
	"21,11,1,2,20,14",
	"126,9,2,4,46,-3",
}

level3={
	px=16,
	py=-16,
	pal=night,	
	chunk=24,
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
	chunk=32,
	pal=day,
	c={
		{x=4, y=23, id=7},
		{x=352/8, y=120/8, id=8},
		{x=23, y=3.5, id=9},
	},
	e={
		{x=352/8, y=120/8, 
		pumpkin=true, 
		minx=240,maxx=365,
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
	}
}

level5={
	chunk=32,
	pal=day,
	e={
		{x=15,y=11, miny=20, maxy=100, minx=55, maxx=290},
		{x=18,y=9, miny=20,  maxy=100, minx=55, maxx=290},
		{x=18,y=11, miny=20,  maxy=100, minx=55, maxx=290}
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
	"118,2,4,16,44,0"
}

level6 = {
	pal=forest_pal,
	chunk=42,
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
	chunk=42,
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
				load_level(level2, 160, -30)
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


levels={
	level1,
 level2,
 level3,
 level4,
	level5,
	level6,
	level7
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
						local n = 1//2
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
		if b.update != drop then
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
		_addr = level.chunk<32 and 
										0x2000+128*level.chunk
										or 0x1000+128*(level.chunk-32)
		px9_decomp(0,3,_addr,mget,mset)
	end
	
	set_checkpoint(level, x,y,dx,dy)
	
	blocks=level
	calc_cam_bounds()

	player.x = level.px or player.x
	player.y = level.py or player.y
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
	load_level_instant(level1,
	 level1.px,
  level1.py)
end
-->8
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
ffff8ff73dfbff0e00829a20c8b2c2ba3a324ac0b88a038b9b43ca17072a223b304840bbcbb313a20b425a52e9e1da0a021aa2d2f27a39b8a0491f3921b9c941
e2a1ff5fb329b9ec8f7eeacf7ffec9e7e1419ac6699c8ffb89cf26f7afb3fd797eaf575ecffbf5ac17bfd7bffff179903e2fff7d32ff48eff763effa9edfe99f
f3fc4fffb6dff31ef02fe1d1fb0f07ff0cf98f76ef938fe7908f85ff5c62ff7c73fcacdff374f43d29f4cff58f35ff7013ff392fc9ecf4d0f3f18ecf4a7ef97a
732fe4f5307f79ffe2ff7c315f6df7fb8fb2ff40909f9ce3988f129c6cf99f880278279dd299ffa9e796fff9ff541347ff3dffaaf794e42667354bcff1fbf6bd
9ddf9e434b0783f67eff8517f36ff7def37ff73bff70ef03994c831143ff7cd2ff9cf5d8fffdff9bbff1c9f0ef61b457fbaff352cffb7f536bf0bdf7fd9fd431
2ff9cf74fff25dfcfe74032ef79e627e9872efb8fb79909f37fffcff7aff72fff5effde97bff20e511f30f94f3660861d121e746c885ebf1e49795ff6988363f
3eff50ffbefff62cc268f33728f36d3b196ee4b25f6795fe7aef279ff71f9c2c17f31ffb328c84cbe4ab831fb2eff4ef1ff7cff4ffe2f7dff7bf7e6fff0f0e1f
b45f3e2f784e93d88ffecff77cb5ca3efa3accfbc88ef32af235f9ffe98c52bbfacf21ff338942ff3cd289fb09f42c2df1f8a1ff1fffcd787efbef5f7dff7dd1
7f5e885b1ecb00b9f83cfff7efad34b94cbe4f68f7ef48dededf7fffcc1fa211f1349ceff798ef35dfe80278c07085100dfffc427d8ffff7a81ef1dfab83e41e
ff597e0c197def8a2715f3712e121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
ffff8ff73dfaff370c053a8492a86db66cf8029cb78f872f3d2650d51f226ee002f4f781bb0639a2b57c6b0e2c9a962365eea09a9bf08cff5e52eee6e0c7feea
cf7ffe3c1fcfc1e7e5419ac669bc8feff1e8f52ffddcffacb4eddff3f5bdfcf29ebfef29f7f1c8e7f53af8cfb59feffb7bff22fc3f5ff66f5ffff17839ff70ef
31ffd0fb8ff70fff2e01725c37efb6f31fff3e6ef74ef98f7e5e9f725e86c9f75e39b04fcfd9f3f272eff6cf98fff88807f7e6aff9f84ff919833e9e5ccf3909
f14cfb9f8fffbc315f6df71eff7cf58f5ee73189f99f0d8e3ef4df4001349bc669ccff1df354ff3dff9ac0d5f35fffcef92d355dffe472eaf9fa3bdf2d96860e
07fd7cef0d2ef7f5bff8dfffceff7c8ee4e1727fa3c9fdeff1bf7ecee707f38fbcff9ae67b3fcf7d3fffed6d8df3d6ff78ff93ff19c3c9fba6937831ff157353
21f4df71f7e43daf12ec7bef29ff7e44ff7c42efa100854707c961f23f831ef59fde1979dff99fef2e03f19ff98f65ec32bc3188dfcbc2fe3bff14c7fb9f3a3b
afed23841983c92ff621fb1f44f5ef35ffb9f9eff9df769eff9c1c2fdf83df3e1accf61cf73c2ff32af275ff7bfff7cfeba4d2cb77ffa8f52e5740f98f5e3b71
4eff1c56374cf9cfb709cf7fffe883ff0f3efcd31b61fef70f96ad25e6f3f1eff1bf9ae0f631fadcfb99ff7eff4df7af402b94c5904efffb4eff9adf7cc1f2e0
a647097032ffed7fe7edc49a9df00dcfc5350a847effd3f7eebeafaae50012121212121212121212121212121212121212121212121212121212121212121212
12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
ffff8ff73dfbff4ec300b3928207eb1ff33048408fb339c0f2a8490b22fb8a7bb87ac83949b053637b63d3533b4b32324a13e3d3fab2b24aca72c24be868e0e2
60788052526a62dadae2f86c74ffdf752ff6ffbf724e39075e778417ed59ffffd3c77f7df5e7c1978feff3a837bc277ef8ff9f47cffbf33d5fdfab77bffff1fc
5fdfff88f9fedfffffe3f70ff71eff5cafecf2f37a9eafe7d95c3f2fcff7ff8cff7c9f924e93e7a9f47dffcff852ff9cff69b542cf3dffdfd5f76efffcff3aff
f4ef9a90c2391f378ffcdff7bf42ffbdf7ffdafceffedf3fff781e8f87dfff40eef71f83f39ff73fff8ef75fffefcbffce5e8f06ffdeaffddff1af166ffbf77f
8fbfffafee4fffdc8ef5cf6e6bbc46f9caff1f8ff7ffb6d9afe73889e8fac1ff9fff5fffeebfe26ef7cfff8ff7cff3eff0ffae5fff6ce7f2dff37d5f765fff7a
e977fffddffdffca9429fdfb71de9f9c72ff0ff3ff38ffcff2ff1effff3193bdd67cff2fc42484ec3d5f2b471dd22974cf9a53dff7f5ff2efade9f7be2bffedb
ffcf15327a5e927d3eab31f3efb7ff0fcbfbffd8f9ff7cffef081c2fdf83df3e1accf61cf73c2ff32af275ff7bfff7cfeba4d2cb77ffa8f52e5740f98f5e3b71
4eff1c56374cf9cfb709cf7fffe883ff0f3efcd31b61fef70f96ad25e6f3f1eff1bf9ae0f631fadcfb99ff7eff4df7af402b94c5904efffb4eff9adf7cc1f2e0
a647097032ffed7fe7edc49a9df00dcfc5350a847effd3f7eebeafaae50012121212121212121212121212121212121212121212121212121212121212121212
12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
83838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383
83838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383
53535353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53535353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53535353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44999411111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
9911194111111111111111111111111111111111111111111ee1ee11111111110000000000000000000000000000000000000000000000000000000000000000
991119911111111111111199941194111194111111111111eeeeeee11ee1ee110000000000000000000000000000000000000000000000000000000000000000
991119919411191999994199119199119111199991111111eeeeeee11eeeee110000000000000000000000000000000000000000000000000000000000000000
aa111aa1aa111a1aa1a1a1aa11a1aa1a11aa1aa11a111111eeeeeee11eeeee110000000000000000000000000000000000000000000000000000000000000000
aaaaaa11aa111a1aa111a1aaaa11aaa111aa1aa11a1111111eeeee1111eee1110000000000000000000000000000000000000000000000000000000000000000
aa111111aa111a1aa111a1aa1111aa1a119919911a11111111eee111111e11110000000000000000000000000000000000000000000000000000000000000000
441111119999941991119199111199119144144119111111111e1111111111110000000000000000000000000000000000000000000000000000000000000000
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
2a2b000102007677785210101010507677787979795200500708090000002c2d373839104a4b4c4d10070809ecec00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b0011120050515252101010105050515266666652005017181900000000007071724a4b5b5b4c4d174f19fcfd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738390000005551545477787677556061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829e1e2e3e40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52000000606161455152232323506f6f6f6f522350515151515151515100000000004462000000000000000000000000000000000000005e0000005e005e00000000000000000000000050515151515144614551515151517f515151515151515151515151515152232323505151515100000000000000000000000000000000
52000000000000604552373839506f51516f5200505151516f5151515144616151615200000000000000000000000000000000000000005e0000005e005e0000000000000000000000006045517f51446200606161456f51516f6f6f6f6f6f6f6f6f6f446161616200000050516f6f5100000000000000000000000000000000
52001e00000000006052000000506f51516f5200505151516f5151515152000006000600000000000000000000000000000000000000005e0000005e005e0000003e00000000000000000050515151520000000000606161456f6f6f6f6f6f6f6f6f44620000005e00000050516f6f5100000000000000000000000000000000
52000000730000000063000000506f7f5151520050516f6f6f7f51514452000000000000000000000000000000000000000000000000005e0000005e005e0000000000000000000000000060455144620000000000000000606161456f6f51517f5152000000005e00000050517f6f5100000000000000000000000000000000
544141415200000000003738396061456f6f520050516f6f6f5151446206000000000000000000000000000000000000000000000000005e0000005e005e00000000000000000000000000005051520000000000000000000000006045515151514462000000003738393750516f6f5100000000000000000000000000000000
6f7f515152000000000000001e0000506f6f52005051516f6f5151520000000000000000000000000000000000000000000000000000005e00000037383900000000000000000000000000006051620000000000000000000000000050517f51515200000000000000004055516f6f5100000000000000000000000000000000
6f6f7f515200000000000000000000506f51520050517f6f515144620000000000000000000000000000006472007041420000000000005e00000000000000000000000000000000000000000063000000000000000000000000000060516161516200000000000000005051517f515100000000000000000000000000000000
6f6f51515200000000000043383940556f51520050515151514462000000000000000000001e00000000005300000050544200000000005e0000414141414141414200000000000000000000005e0000000000000000000000000000006300006300000000000000004055515151515100000000000000000000000000000000
6f6f7f5152002e00000000530000505151515200505151515152000000000000000000000000000000000053002e0050515142000000005e00006f6f6f6f6f7f6f5200000000002e0000001e005e003e0000002e0000003e0000002e005e003e5e00002e0000000000506f516f51515100000000000000000000000000000000
6f6f6f6f5200000000404152000050515144620060455151446200000000002e000000000000000000000053000000507f5154420000005e004044616161456f6f5200000000000000000000005e0000000000000000000000000000005e00005e0000000000404141556f516f51515100000000000000000000000000000000
6f6f6f6f5200000040517f52373860616162000000606161620000000000000000000000350000000000005042004055515151520000005e0050520000005061616142000000000000000000005e0000000000000000000000000000005e00005e0000000000506f6f6f6f516f51515100000000000000000000000000000000
6f6f6f6f54414141515151520000000000000000000000000000000000000000000000004335353535353550520060616161616200000037385052002e00633636366337383937383937383937380000000000000000000000000000005e00005e0000000040556f6f6f6f516f51515100000000000000000000000000000000
6f6f6f6f6f6f6f6f7f5151520000001e0000003e0000002e0000000000000000000000005041414141414151620000000000000000000000005052000000000000000000000000000000000000000000000000000000000000000000005c37385c00000040556f6f6f6f7f516f51515100000000000000000000000000000000
6f6f6f6f6f6f7f516f6f51544142000000007d000000000000007e000000000000000000505151515151515200002e0000001e0000003e000050544141414141414141414243000000430000004300000043000000430000004300000000000000000040556f6f7f6f6f6f516f51515100000000000000000000000000000000
6f7f6f6f6f6f6f6f6f6f516f6f544141414141414141414141414142353535353535353550517f6f6f6f515200000000000000000000000000505151515151515151515151533535355335353553353535533535355335353553353535353535353540556f6f6f6f6f6f6f517f51515100000000000000000000000000000000
5151515151515151515151515151515151517f51515151517f5151514141414141414141555151517f515154414141414141414141414141415551515151515151515151514141414141414141414141414141414141414141414141414141414141555151515151515151515151515100000000000000000000000000000000
fffff87fd3bfff6a400d4a2fa202e30328082e2c2a0ecee0e12888ac4a6aafc6a0a0cccc06e7010dadc729cced0f0a8d8f4d6f8f68685c3c8f2c66c4a4c3ff1a7e67e76d89b892139ea5efcf7d9f7e07727ae27e3f8709f8efcbf3e27fe37e7ff91c5bfa7ebfa1f8c9fa7e937e9f879fb27ee73f9cb7f8fc211fcf13dfeb93f0
e35a7e73fb6df9a3ff63fc3fd4ff1df5e75dffd7f74c95c3f74ffc0ae3f7bff87b7e97ff17fe35e3f8ffc9ff93fe9d5ffcbff9a7fe00eabad2ffe43193fe69ff7f3c5bff93ff39cb8ffd1c7e15c9f94ffc0fe67effe9faa7ce27fe9ffd5dd922fe5ffae7e73ff03f071fac7fe869bfa747e47f511b8f7f6713fbfeff19ffb359
a79bff67febff813397fb4ea74ef7fe17f0fe37e5ff98ffc55ffb7ff749ffbee96c96edd79ff95e9ece7ff2541c0aee77c3ff0d93f69f4feca69ffc24bffc44b7c9fc4d7efa623f0fc93958e872c2aa59f9aff4fcb92953f15fc4a9c71bff254e2fff293edc7ff313863be7aebf292fef3f26bff81a27f47e44affca1c44e27e
3ffcfe13de64ffe53fb35ebffa4eb9eff1fc7befce9c7125fc4d3a7e4ffb83b7efdcfd3f349ff853f1927aa7efcfce1feff1d3ffadbffdbffb7ff6e9ffdaa7f17dcfc73ff9dfde6d315cc827248e67f9ffde4fd4e7ee7f0819cdb64bde77f97fe221e791f8b7f523153f8cfab3c8fdab893b937fe4fd7ff25767e1ff91fdbff2
f30b3f4b072bbf94b55daf50f9145d5ea1ff838f88b7ffc5fff1f875ffe7f2ffcbffe9fbdd6449023dc0f77f1ff83ff34ea4df85f3efc2dff3ff3ffb53f43c7e8bffeade37dcd7e69ef1f8feb3f9fc7b4e3afcbf1fcfcf13ff438ffc69a77ca0e7ff5ffe4ffcbffa3f4e3f34e21fb272fcd388727c9c807e1003ddfcffe2d253
fffff87fd3affd548060c3168a3a1be262bdfdbb8727833ee78ea418157272e10a1d35cd5b5cfbf8492b6e38e64ebbbadbba77af9ecfda7c983e9c71b71efb74fc1f8cf7d93ab5dfe6dccfc3a73f8fe5f9f7f9f80e4d27e0b3bedc573cdfd9f97edd731dbdfce3d5dc61e4da3db568fd04fd1ca7ec47ea7ebff8e7ecee677c3f
0bc3b9f8abf2d23f62cfdd5fc71b95570a90e7ff9f0d25f153c856fc47584fd67f3fd49db75fafedfbb4ce251058dffce8fc2b6b176f64aa90bf9d9fad274b0e61ff90b97c7e20fce6795fdff9fd51ea0dc847e7d7fbff4ffc1d7fe1bc253f57f1f97125e5e4fcea67ea841cf1ff8baf3ff0cb348257b3f169ff8d36ffc1cba7
5cc93d77f9afd7263f31324ffc8afcb14c7eac834eab95d6bbe2449c24fc9254912444091c3f24e1fb091c6e3992098b3984e657a5e5a4e5aee388e169ffa231394feeca6fc7c9c828fca7fe571d6e5c04342c45fa3ff410ff66e611393f59ff6e119c708b64e1c9d3f9ffcd3f1fdbabec92493dbf92753b98c7ee591c4f527a
93a7d3f2dc4f50f2553ff1dffcfc744979fd55c0a7f3e38709e7b2bff40e27fe978bc3d93b49ea4f55d777afc6c84848484876f25910c7e90c9054df84df8f92c962fe30eed3ff037854fce47e92343d4b046ff1f8ffe24fc0fcc021212121212121212121212121212121212121212121212121212121212121212121212121
2121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
fff091df3faff9fef7f7fdd38ffff575d3a7ebcbbdff83affc3ff851387fe1a7fff977fe2ff3bff0ffc64eefe0ffc8dfd8c54ffff2befd57acfc7c7fffba3f2e9ff8f5ff3fcff2dff3fcff3fffffa821212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
2121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
__sfx__
000100001505016050180501a0501c0501e0502205027050261501600016000160001600017000330000000035000380003900000000000000000013000000000000000000000000000000000000000000000000
0001000023150211501c15016150121500d1500c15013000130001b60013000130000000013000130001300013000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000d0f3501435017350183501835016350103500d3500a3500a3500c3500e3501135015350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000308000e65011640146401763019620146100d6100b600096000960000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020700323502c350293502735025350213503030034550365503855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a000e2755027550275501d550275502755027550275501c5502755027550275502755027550216500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00081300026350000002b3501a350000001935000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006080000000270502a0502c0503005032050370503b0503f0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 06074344

