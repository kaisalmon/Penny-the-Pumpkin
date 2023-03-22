pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--penny the pumpkin
title_y=8

max_coins=13
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
speedrun_t=0
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
		skw_spr(
			player.x,
			player.y,
			player.h.x,
			player.h.y-4,
			player.w+4,
			player.size
		)
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
	
	local x=50
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
	if time()%1 < .5 then
		print("by kai salmon",x+24,title_y+15,13)
	else
		print("by kaimonkey",x+24,title_y+15,13)
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
	
	if title_y < 45 then
		title_y = lerp(title_y, 50,0.02)
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
	 if player.x+player.w>c.x-8
		and player.x-player.w<c.x+8
		and player.h.y>c.y-16
		and player.h.y<c.y then
			del(coins,c)
			sfx(7)
			dset(c.id, 1)
			sr_coins[c.id]=true
			coins_collected+=1
			coin_at=time()
			set_checkpoint(blocks,player.x,player.y-5,0,0)

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
		and ch.h.y + 1.5*max_h < ch.y then
			die()
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
						1,7,15}
forest_pal={138,2,3,4,
						147,6,7,8,
						9,10,11,12,
						13,-4,15}
day={-4,2,3,4,5,6,7,8,9,10,11,12,13,14,15}

level1={
	px=20,
	py=100,
	pal=forest_pal,
	--chunk=19,
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
					if player.x/8 > b[3]+b[5] then
						load_level(level2, 5, 30)
					end
			end
	}
}

level2={
	pal=forest_pal,
	--chunk=19,
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
			"32,14,6,4,29,12"
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
		"41,0,3,3,15,5"
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
		if player.y > 100 then
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
	cartdata("kai-pumkinv1")
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
ffff8ff73dfaff04822da0265ba91f3a8c23e568e1c34b8d9871031720b78fdea8ea90235acbb7e6408155d272c255a446dacd828b7dff9acd49ed777cd3777e
fbc73e0f0f5ab4466bf45ccf7c3e31ff1dedcffbf33dfaf25eafef25e7fd741e9ffbf0ffcefcfd3ff62eeff99c7e39afeffceefdfebfff4090ff89deef5ff39e
ffe8e7f128e761f30f94fb0fdc3f2ffbf4dc3d3f4e39ff70cff9fe13ffb82fc9ecf4d0f3f14ecf4a7ef97a732fe4f5307f79ffe1ff3c315f6df7f7def70b727e
42af720e7872a1f74e0228d1bc466b76ef948f7aeff5cf4d5c3dfff3ef98df5293989de43d0fe7ddfbf6763f4a2d1d0c1efbf9df124cff5dffcaff9deffc7f0d
994c831143ff5cd2affbb1ff7bff366ff383f1bfca69bef74fe7b49ff7ceb6c6f16bfffb1fa972ef78f3dbc13c98ffc9b9e942f9afe2efc5725ef77fff0f72ff
f1eff5e97bdfb42c72bf42dfa9008547173261ba3b9e7db4f32f15c0e7c7f7cb17effe2cc278ef766f6b17e1462efb959d76ebf99fb45eff3c72904cff2ccff8
12221fb3ce3e4cfa2f22ff3ff9dfc1ff5fffdef3f5efe6f041fbe5f382e73489fde8ff7ccf57a7dc7d1d6df50def88dbe4f7bfbf0269eefb0fb4bfec0639ef69
ccf58c72aee7c3b6ffbb9bf0fcf78fbefaffe0b3febd11b63c871073f178effddf477873987d9ec0ff3f9021b66e875980d8319ceff798ef35bfe84383077085
100dfffc427d8fefffb88bcf568e1eb308ff6c3f0e94b7ff5de0a472f64c12121212121212121212121212121212121212121212121212121212121212121212
12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
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
44999411111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
99111941111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
99111991111111111111119994119411119411111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
99111991941119199999419911919911911119999111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
aa111aa1aa111a1aa1a1a1aa11a1aa1a11aa1aa11a11111100000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaa11aa111a1aa111a1aaaa11aaa111aa1aa11a11111100000000000000000000000000000000000000000000000000000000000000000000000000000000
aa111111aa111a1aa111a1aa1111aa1a119919911a11111100000000000000000000000000000000000000000000000000000000000000000000000000000000
44111111999994199111919911119911914414411911111100000000000000000000000000000000000000000000000000000000000000000000000000000000
11111661544999111155499915449911111911110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111161444465911556444915464911115491110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16611611466666495466666415464911155659110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11611661444465411456444415464454156669110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16111111555555111155555515666511144644110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16611111111511111111511115565511154644540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111411111111411111445111154644110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111411111111411111151111155444110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
jjjjjj60333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjj670333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jj6jj670333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjjj60333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjj6670333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
j6jd6670333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjj6670333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjjj60333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjjj60333333333333333333334333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjj670333333333333433333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jj6jj6703333333334343j3434343939333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjjj6033333333j3j3434343934343333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjj66703333333334343j3434343939333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
j6jd667033333333j4j44j4444944943333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjj66703333333334j43j4443944349333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjjj6033333333j4344j4344934949333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
jjjjjj6033333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333333333333333343333333333333333333
jjjjj67033333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333333334333333333333333333333333333
jj6jj67033333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333334343j34343439393333333333333333
jjjjjj6033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j3j34343439343433333333333333333
jjjj667033333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333334343j34343439393333333333333333
j6jd667033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449433333333333333333
jjjj667033333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333334j43j44439443493333333333333333
jjjjjj6033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4344j43449349493333333333333333
jjjjjj6033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jjjjj67033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jj6jj67033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jjjjjj6033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jjjj667033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
j6jd667033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jjjj667033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jjjjjj6033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jjjjjj6033333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449493333333333333333
jjjjj6703b333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333b333333j4j44j44449449493333333333333333
jj6jj67033333b3qj4j44j4444944949b33333333333333333333333333333333333333333333333333333b333333b3qj4j44j4444944949b333333333333333
jjjjjj6033q33333j4j44j44449449493333333333333333333333333333333333333333333333333333333333q33333j4j44j44449449493333333333333333
jjjj6670qq333q33j4j44j444494494933q3333333333333333333333333333333333333333333333333333qqq333q33j4j44j444494494933q3333333333333
l5ld5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjbjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjbjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjbjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
lllll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjbjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjbjjjjjj
ll5ll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjbjjjjjjjjj000j000j00jj00jj0j0jbjjj000b0j0j000jjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjbjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0ppp0ppp0pp00pp00p0p0jjj0ppp0p0p0ppp0jjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0p0p0p000p0p0p0p0p0p0jjjj0p00p0p0p00jjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
l5ld5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0ppp0pp00p0p0p0p0ppp0jjjj0p00ppp0pp0jjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjbj0p000p000p0p0p0p000p0jjjj0p00p0p0p00jjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0p000ppp0p0p0p0p0ppp0jjjj0p00p0p0ppp0jjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0kkpppk0j0j0j0j0j000jjjjjj0jj0j0j000jjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
lllll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0pp000pk0jjjjjjjjjjjjjj0000jj00jjjj00jjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
ll5ll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0pp0b0pp000jbj0j0000000pppk00pk0j00pk00000jjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0pp0j0pp0pk0j0p0pppppk0pp00p0pp00p0000pppp0jjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj099000990990j0909909090990090990900990990090jjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
l5ld5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj099999900990j09099000909999009990j0990990090jjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0990000j09900090990j0909900j0990900pp0pp0090jjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjj0kk0jjjj0pppppk0pp0j0p0pp0jj0pp00p0kk0kk00p0jjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjj00jjjjjj000000j00jjj0j00jjjj00jj0j00j00jj0jjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
lllll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
ll5ll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjdddjdjdjjjjjdjdjdddjdddkdddlkddkddkpdpdjdddjdjdjjjjjjj
l5ld5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjdjdjdjdjjjjjdjdjdjdjjdlkdddldkdkdkdpdpdjdjjjdjdjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjddjjdddjjjjjddjjdddjjdlkdkdldkdkdkdpddjjddjjdddjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjdjdjjjdjjjjjdjdjdjdjjdlkdkdldkdkdkdpdpdjdjjjjjdjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjdddjdddjjjjjdjdjdjdjdddkdkdlddkkdkdpdpdjdddjdddjjjjjjj
lllll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
ll5ll560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llllll50jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
llll5560jjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjlklkklkkkkpkkpkpjjjjjjjjjjjjjjjj
j6jd6670qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq
jjjj6670qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq
jjjjjj60qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq
jjjjjj60qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq
jjjjj670qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq
jj6jj670qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq
jjjjjj60qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqq33
jjjj6670qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqq333
j6jd6670qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq33qqq33q
jjjj6670qqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq333q333q
jjjjjj60qqqqqqqqj4j0004444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqq33q33qq
jjjjjj60qqqqqqqqj4j0004444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqj0000000
jjjjj670qqqqqqqqj403bb0444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0db3bb3b
jj6jj670qqqqqqqqj403330444944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq003j33jj
jjjjjj60qqqqqqqqj00j330044944949qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0djjjjjj
jjjj6670qqqqqq000444449a00044949qqqqqqqqqq3qqq3qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq00jj6jjd
j6jd6670qqqqq094499499a9aaa04949qqqqqqqqqq3qqq3qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0d6jjjjj
jjjj6670qqqq09499949999a9aaa0949qqqqqqqqqq3q3q3qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0d6jj6jj
jjjjjj60qq00949994999999999aa049qqqqqqqq3q3q3333qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq00jjjjjj
jjjjjj60qq00949994999999a9949049qqqqqqqqj00000000000000jqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq00jjjjjj
jjjjj670qq00949994999999a9949049qqqqqqqq0db3bb3b3b333b30qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0d66jdjj
jj6jj670qq0044999499999499949049qqqqqqqq003j33jjjj3j3jj0qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0d66jj6j
jjjjjj60qq0044499499999499949049qqqqqqqq0djjjjjjjjjjjj60qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0d66jjjj
jjjj6670qq0044499499999494499039qqqqqqqq00jj6jjdjjjjj670qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq00jjjjjj
j6jd66703300j4444949994949999039qqqqqqqq0d6jjjjjjj6jj670qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0d6jj6jj
jjjj6670333q0j4jj4444444j9990939qqqqqqqq0d6jj6jjjjjjj670qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0d6jjjjj
jjjjjj60q33q30000000000000003333qqqqqqqq00jjjjjjdjjjjj60qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq00jjjjjj
jjj66j60000000000000000000000000000000000djjjjjjjjjjjj60qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq00jjjjjj
jjj66jj6333b33b3333b33b3333b33b3333b33b36jj66jjjjjjjj670q4qjq4qjq4qjq4qjq4qjq4qjq4qjq4qjq4qjq4qjj4jj444j449j444jq4qjq4qj0d66jdjj
jjjjjjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjjjjj66jjjjj6jj6704q4q4q4q4q4q4q4q4q4q4q4q4q4q4q4q4q4q4q4q44444j44444449494q4q4q4q0d66jj6j
jjjjj66jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj66jjjjjjjjjjjj60qjq4qjq4qjq4qjq4qjq4qjq4qjq4qjq4qjq4qjq4jjj44j444j944j44qjq4qjq40d66jjjj
jj6jj66jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6j66jjjjjjjjjj6670jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj00jjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj6jjjj6jd6670j44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44j0d6jj6jj
jjjjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjjjjjjjjjjjjj667044444444444444444444444444444444444444444444444444444444444444440d6jjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj604jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj400jjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj60jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj00jjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj670j44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44j0d66jdjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj6jj67044444444444444444444444444444444444444444444444444444444444444440d66jj6j
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj604jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj40d66jjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj6670jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj00jjjjjj
djjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjj6jd6670j44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44j0d6jj6jj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj667044444444444444444444444444444444444444444444444444444444444444440d6jjjjj
jjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjjj604jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj44jj400jjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj66j6000000000000000000000000000000000000000000000000000000000000000000djjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj66jj6333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b36jj66jjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjjjjj66jjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj66jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj66jjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj6jj66jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6j66jjjjjj
djjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj6jjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjjjjjjjjj
jjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
djjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjj

__gff__
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000060600000001010000818a0606060000000000000a0a0a0a0a0a060606000000000002020a0a0a0a0a0a0000000000000a0000020a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a0200000000000a
0000000002020000000000000000000000000000020202020000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000000000000000000000000000
__map__
2a2b000102007677785210101010507677787979795200500708090000002c2d373839104a4b4c4d10070809000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b0011120050515252101010105050515266666652005017181900000000007071724a4b5b5b4c4d171819000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738390000005551545477787677556061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d272829000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52000000000000000000000000000000000000000000000000000000000000006a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a00000000000000000000000000000000515200007d1010100010101718181819404141414141414141414141716161000000520000000000005051515151515100000000000000000000000000007677
52000000000000000000000000000000000000000000000000000000000000006a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a0000000000000000000000000000000051520000070910101010101718181819505144444544446145514462000000000000530000000000405551515151515100000000000000000000000000765551
52000000000000000000000000000000007e00000000007d007e0000000000006a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a0000000000000000000000000000000051523535050535101010101718181819506152065062060050515200000000000000530066000000505151515151515100000000000000000000000000606161
52000000000000000000000000000000373800000000070808090000000000006a6a6d6e6a6a6a6a6a6a6a6a6a6a6a6a00000000000000000000000000000000515208080808091010101007080809195300060053000000065306000000003738395366664e0040555151515151515100000000000000000000000000000066
5200000000000000000000000000000000000000000017181819007d000000006a6a67686a6a6a6a6a6a6a6a6d6e6a6a7778000000000000000000000000000051520518181819101010101718181919060000000600000000060000000000000000534e4e004055515151515151515100000000000000000000000000000066
52000000000000000000000000000000000000000000171818070809000000006a6a67686a6a6a6a6a6a6a6a67686a6a51547777777778000000000000000000515478051818191000101017181819197d0000000000000000000000660000000000530000006061455151515151515100000000000000000000000000007677
52000000000000000000000000000000000000000000171818171819000000766c7a67686b6a6a6a6a6a6c7a67686b6a5151515144616200000000000000000051515478181819100010101718070808090066660000000000006666664e00000000530000000000606145515151515100000000000000000000000000005051
52000000000000000000000000000000000000000000171818171819000000507c0067687b6b6a6a6c7a7c0067687b7a515151446200000000373800000000005151515218181910001010171817181819004e4e00000000004e4e4e000000000000530000666600000060616145515100000000000000000000000000005051
5200000000000000000000000000000000000000007e1718181718190000005000006768007b7a7a7c00000067680000515144620000000000000000000000005151515205051910001007080917181819000000437e0000000000000000000000005042004e4e4e000000000050515100000000000037383937380000005051
5200000000000000000000000000007d0000000000070808080809190000005000006768000000000000000067680000514462000000000000000000000000005151515477781910001027161917181819000000504200000000000000000000007d505442000043000000000050515100000000000000000000000000005051
52000000007e0000000000000000007677783738391718181818191900000050000000000000000000000000000000005152000000007e00000000000000000051515151515205100010101719171818190000005052000000000000000007080808605162000050420000000050515100000000000000000000000000005051
527d007e00767800000000000000005051527979791718181818191979797950003535353535000000000000000000005152000000373800000000000000000051515151515442353535350708091818197d00005052007e00007d00000017181818186300006660623937383950515100003738393738000000000000005051
5477777777555279797979797979795051526666070809181818191966666650004041414142000000000000000000005152000000003738000000000035353510101010615162070808080808080808080808096062080808080808080809181818181900004e00000066664e50515100000000000000000000000000355051
5151515151515266666666666666665051526666171819181818070809666650355051515152000000000000000000005152000000000000000000007e07080910101010366336171818181818181818181818250808261807080808080808091818181900000000006666660050515100000000000000000000004041415551
5151515151515477777777777777775551547777777777777777777777777755405500000052000000000000000000005152000000000000000000070826181910101010100000171818181818181818181818181818181817181818181818191818187678007677777777777755515100000000000037383940415551515151
5151515151515151515151515151515151515151515151515151515151515151000000000000000000000000000000005152000000000000000000171818181910101010777777777777783738397677777777777777777777777777777777777777775552005051515151515151515100000000000000000050515151515151
fffff87fd3afff74806aa3f48173066041e386876ee1c4c48b8a9d5fcd4286cd81bb811b77399d9f478a9b3d6bf9ee1c24e5bce36c9530ffc69f99f9db626e2484e7a97bf3df67df81dc9eb89f8fe1c27e3bf2fcf89ff8df9ffe4716fe9fafe87e327e9fa4dfa7e1e7ec9fb9cfe72dfe3f0847f3c4f7fae4fc38d69f9cfedb7e
68ffd8ff0ff53fc77d79d77ff5fdd32570fdd3ff02b8fdeffe1edfa5ffc5ff8d78fe3ff27fe4ffa757ff2ffe69ff803aaeb4bff90c64ff9a7fdfcf16ffe4ffce72e3ff471f85727e53ff03f99fbffa7ea9f389ffa7ff577648bf97feb9f9cffc0fc1c7eb1ffa1a6fe9d1f91fd446e3dfd9c4feffbfc67fecd669e6ffd9ffaffe
04ce5fed3a9d3bdff85fc3f8df97fe63ff157fedffdd27fefba5b25bb75e7fe57a7b39ffc950702bb9df0ffc364fda7d3fb29a7ff092fff112df27f135fbe988fc3f24e563a1cb0aa967e6bfd3f2e4a54fc57f12a71c6ffc9538bffca4fb71ffcc4e18ef9ebafca4bfbcfc9affe0689fd1f912bff2849ffd3ffaa2713f3ffe7f
09f87327ff29fd9a74efbeff0fc3aebb3871c497f134e5f93fed3c76fe7b9f9fe493ff0a7e724f14fdfaf5c3fdf1edffedffdbffb74ffed63f5c7e57ecfc73ff9d92c9a573209c92399fe7ff793f339fb9fc206736d92f79dfe3ff88879e47e2dfd5316cffc3ff9a3ff9fe79f56791fb57127dc4dff97f6ffc91d9f87fe27f6f
fcbcc2cfdec1caefe52d576bd43e451757ab2490fe78f8e16fff8bffe3f0ebffcfe5ff97ffd3f8bac892047b81eefdbfdd3a937e17cfbf0b7fdffd1fed707522787afd17ffd5bc6fb9cfcd3de3f1fce7eff8f69c73f97e3f9f9e4ffd37cbc475f1f8a69df2839ffd7ff93ff2ffe8fd38fcd388727c9c807e1003ddfcffe2d253
fffff87fd3affd148060c3168a3a11315e6ee1c9e0cfb9e3a906055c9cb842874d7356d73efe124adb8e3993aeaeb6ee9b5efc9fb4f5307d38e36e3cf38fdaef3c93adfbaf33de5befc3f1e8c0e4e64ab3ae9c571afecfc3f6bcc49dfe305ea51e4d93bf2c4fdc4fc9ca64fc48fccfcfff1cfd1dcaef8599dccb3f07f659faab
f6e38e2f24211c7ff3e164be32750b68e4fe27effc49c375f9fe9fabaeab4e138b1bff9d1f853ab565de71c725fe1d44e961c567fe42e6edf883feafe7fafe640f50830b0fcbafeffc9fefbff5e129fabf6fcac9c0f27e2ff0e79ffc1dfbff4d523d4a1dcfd5a7fe14d3fde9d3be649eb8fcd7ebc1fd4d64ffc4afc2cbcc863f
56486ebace53977c4893949fb24a922488812383fc38dcf52412967109ccaf4b059cb5dfb7eb27eb87fe99ba493ff159637ebf8ce0147e53ff1b8e778e090d0b1dafb67fe83fedf8b77089c9facff39e119c645b274e4f9fbffe49f8fe9e5fca49249e5fc93abec7fcc32713f249f924e9f4fc3713e43c954ffc77ff2f1d126e
7f33ff277e89efd2bff30e27fe77e6ee4f127c93e575ddebf5b2121212121dbd87fe548924df84df976bc1fe5e0ffc0d13ff49fa1da731bf13d7dfffc021212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
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

