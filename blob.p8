pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main
function init()
t=0
wipe_progress = -1  -- -1: no transition, 0-128: transition in progress
dust={}
coins_collected=0
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
jump_btn_down = btn(4)
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
coin_at=nil
g1=0.1
g2=0.275
air=0.01
max_jump_height=8*4.1
player.jumpf=-3
debug="test"
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
		local dw = sin(t)*16
		sspr(24,0,16,16,c.x-dw/2,c.y-16,dw,16)
	end)
	draw_dust()
	
	draw_blocks(true)	
	camera()
	draw_wipe_transition()
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

	print(coins_collected.."/4",22,115,7)
end

function draw_wipe_transition()
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
	
	local thud_y = -25
	if coin_at and coin_at+2>time() then
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
	
	if died_at and died_at < time() - 2 then
		load_level(blocks,blocks.px,blocks.py,blocks.dpx,blocks.pdy)
		died_at = nil
		revived_at = time()
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
	if player.x>c.x-8
		and player.x<c.x+8
		and player.h.y>c.y-16
		and player.h.y<c.y then
			del(coins,c)
			sfx(7)
			dset(c.id, 1)
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
    e.dir=r<0.33 and -1 or r<0.66 and 1 or player.x-e.x
  end
  if e.maxx and e.x>e.maxx then e.dir=-1
  elseif e.minx and e.x<e.minx then e.dir=1 end
  local jc=e.pumpkin and 0.005 or 0.02
  update_character(e,e.dir,rnd()<jc,1)
  if not died_at and not e.pumpkin then
    local th=2+abs(player.dy)+abs(e.dy)
    if do_characters_overlap(e,player) and e.h.y+th>player.y then
      sfx(0)
      player.y=e.h.y-2
      player.dy-=3.5
      player.h.dy-=5.5
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

function update_character(ch, move_dir, jump, squeeze, jump_held)
	if (move_dir < 0) ch.dx -= ch.speed or .2
	if (move_dir > 0) ch.dx += ch.speed or .2

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

	local h = ch.size * (squeeze or 1)
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

	local max_h = ch.size*1.5
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
	if not jump_btn_down and btn(4) then
	 jump_btn = time()
	end
	jump_btn_down = btn(4)

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

	
	if player.y > 8*cam_bounds[4]+32 then
		--die()
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
	local max_w = 25/16*ch.size
	if (ch.w>max_w) ch.w=max_w
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

function is_colide(x,y,w,inc_semi)
	local xs =  {x}
	if w then 
		xs = {}
		for dx=-w/2,w/2,7 do
			add(xs, x+dx)
		end
		add(xs, x+w/2)
	end
	
	for i,x2 in ipairs(xs) do
		local b,tile = is_solid({
			y=y,
			x=x2,
		},inc_semi)
		if(b)return b,tile
	
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

	x_col = is_colide(p.x+p.dx,p.y,p.w)

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
	if(#dust > 30 or stat(7)<60) then
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
													local s1=stat(1)

	if((time()*60)%2 > 1.5) then

							profile_cpu_usage+=stat(1)-s1

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
	
							profile_cpu_usage+=stat(1)-s1

end

function draw_dust()
			local s1=stat(1)

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
		profile_cpu_usage+=stat(1)-s1

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
	
	if player.block == b then
		b.t+=1/30
		b[5]+=sin(t*10)*.2
	elseif b.t <=0 then
		b.t+=1/30
	end	
	
	if b.t >= .7 then
				b.dy = (b.dy or 0) + 0.02
				b[6] += b.dy
	end
	
	if b[6] - b.oy > 100 then
    b.t, b[6], b.dy = -1, b.oy, 0
	end
end

night={0,-16,-4,1,
						0,5,6,8,
						-3,-1,12,12,
						1,14,15}
forest_pal={138,2,3,4,
						147,6,7,8,
						9,10,11,12,
						13,14,15}
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
			32,5,--src
			16,9,--size
			0,0,--dst
	},
	{
			rx=2,ry=5,
			colide=false,
			32,12,--src
			16,1,--size
			0,8,--dst
	},
	{
			0,3,--src
			32,16,--size
			0,0,--dst,
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
		{x=22,y=7,id=3}
	},
	{
			fill=3,
			colide=false,
			6,5,--src
			48,3,--size
			0,-3,--dst
			update=function(b)
					if player.x < 0 then
						load_level(level1,31.5*8,6*8)
					elseif player.y > 34*8 then
						if player.x>250 then
							load_level(level3, 156,20)
						else
							load_level(level3, 30, -15)
						end
					end
			end
	},
	{
			rx=3,
			colide=false,
			32,5,--src
			16,9,--size
			0,0,--dst
	},
	{
			rx=3,ry=9,
			colide=false,
			32,12,--src
			16,1,--size
			0,8,--dst
	},
	{
			tile=true,
			colide=false,
			18,0,--src
			48,3,--size
			0,16,--dst
	},
		{
			fill=4,
			colide=false,
			18,0,--src
			48,13,--size
			0,19,--dst
	},
	{
			48,3,--src
			16,16,--size
			0,0,--dst
	},
	{
			64,3,--src
			48,16,--size
			0,16,--dst
	},
	{
			112,3,--src
			16,16,--size
			32,0,--dst
	},
	{
			front=true,
			32,14,--src
			6,4,--size
			29,12,--dst
	},
	{
			colide=false,
			rx=3,ry=3,
			front=true,
			31,18,--src
			1,1,--size
			31,14,--dst
	},
	{
			25,8,--src
			3,5,--size
			21,11,--dst
	},
	{
			114,14,--src
			5,1,--size
			20,14,--dst
	},
	{
			21,11,--src
			1,2,--size
			20,14,--dst
	},
}

level3={
	px=16,
	py=-16,
	pal=night,	
	chunk=24,
	c={
		{x=2.5,y=4,id=4}
	},
	{
		0,3,--src,
		32,16,
		0,0,
		update=function()
			if player.y<0 then
				if player.x < 70 then
					player.x = 16
				else
					load_level(level2, 100, 260, 0, -3)
				end
			end
		end
	}
}

levels={level1, level2, level3}
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
transition_function = nil

function transition(func)
    transition_function = func
    wipe_progress = 0  -- start wipe effect
end

function load_level_instant(level,x,y,dx,dy)
		if level.chunk then
		reload(
			0x2000+128*level.chunk,
			0x2000+128*level.chunk,
			128*3
		)

		px9_decomp(0,3,0x2000+128*level.chunk,mget,mset)
	else
		reload(0x2000,0x2000,128*19)
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
		if 	dget(c.id) == 0 then
			spawn_coin(c)
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
		y=c.y*8-2,
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
		dx=0,
		dy=0,
		w=8,
		bounce=0,
		size=12,
		tsize=12,
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


function _init()
	cartdata("d5d")
	init()
	for i = 0,30 do
		if dget(i)==1 then
			coins_collected+=1	
			coin_at=time()		
		end
	end
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
111111110bbbbbbbbbbbbb300977997779994a9044499444444494442229944444499444444994ff333b3b3b3b3b3b3311111111111111110000000000000000
111111110bbbbbbbbbbbb3300999977799a94a9044449944444499442224994444449944444499ff3333333333333333b1111111111111350000000000000000
111111110bbbbbbbbbbbb330049977799a994a90444449a4442449942224499444444994444449af33333333333333333b311111111113530000000000000000
1111111103bbbbbbbbbb333010977799a999a901444444aa422444992224449944444499444444aa1333333333333331b3b11111111135350000000000000000
11111111033bbbbbbbb3333010977999999a9901944444fa922444494224444994444449944444fa11115449945111113b3b3111111151530000000000000000
11111111053333333333335011094aaaaaa99011994444ff942444444424444499444444994444ff111154499451111133b3b311113535330000000000000000
1111111110553333333355011110044444400111499444ff144444442444444449944444499444ff1111544999511111313b3b31115353330000000000000000
1111111111000000000000111111100000011111449944ff124944442249444444994444449944ff11154499994511113333b3b1153533310000000000000000
111011101100001111111111aaaaaaaa11153311444994f0004994442249944444499444444994ff111111100111111140000000000000040000000000000000
010101011049aa511110011199aaa99a153333514444990b330499442244994444449944444499ff11111103b011111102444994444449900000000000000000
101010100499779011099411999999995333ab31444444033b3049942224299224422992244229af111111033011111102222244222222400000000000000000
01010101049997901049790188999889333bba3144444420030444992222124412221244122212aa111110053001111120000000000000040000000000000000
0000000054999990154499018888888833b3bb3194444449402444491241124112411221124112f11110044449a0011192222224422222290000000000000000
000000005449994011544011888888885333bb339944444494444444121112111211121112111211110949949a9aa01199444444994444440000000000000000
00000000154444011115011188888888333b3b3349944444499444441111111111111111111111111094994999a9aa0149944444499444440000000000000000
000000001155001111111111888888885333b33344994444449944441111111111111111111111110949949999999aa044994444449944440000000000000000
0000000011111111111111118888888833333b331111111105ddd60110010010010010010010010009499499999a949042244222222442240000000000000000
00000000111111111111111188888888533333331110111105dd670104904904904904904904904909499499999a949024449944444499420000000000000000
00000000111041111111111188888888333333331107011110dd6011044044044044044044044044044994999949949024444994444449920000000000000000
00000000110974111111411188888888153553511106011110567011100100100100100100100100044494999949949042222244222222290000000000000000
00000000115490111115941188888888115495111056701111060111111111111111111111111111044494999949499094444449944444490000000000000000
000000001115011111115111888888881154951110dd601111070111111111111111111111111111054449499494999099444444994444440000000000000000
000000001111111111111111888888881154951105dd670111101111111111111111111111111111105454444445990149944444499444440000000000000000
000000001111111111111111888888881549995105ddd60111111111111111111111111111111111110000000000001144994444449944440000000000000000
50000000000000000000000550000005555555555555555510000000000000000000000199949499111111111111116666111111111111115555555500000000
07767776677767766777677007766670555555555555555504999994999999949999997049999949111111111111116666111111111111115445544500000000
0d65666556665665566657700d655670555655555555555505444444444444444444449095555594111111111166661661666611111111114444444400000000
0d65555555555555555555600d655560555555665665565590000000000000000000000445555594111111111666666666666661111111114554455400000000
0055655d555655655555577000555670555555665665555594944444444444444444444545555594111111116666666666666666111111115555555500000000
0d65555555555555556557700d655670555665555555555599445454545454545454545445555594111111116666666666666666111111115445544500000000
0d65565556555555555557700d6556705556655ddd56655595454545454545454545454545555595111111116666666666666666111111114444454400000000
0055555555555555d555556000555560555555600d56655594555555555555555555555554444455111111166666666666666666611111114544444400000000
00555555555555555555556000555560555665600d55555599999999999999999999954599999999111116616666666650000005166111110000000000000000
0d665d5555555555555556700d665670555665566556655599494949494949494949495549494949111166666666666604444440666611110000000000000000
0d66556555555555556556700d6656705555555555566555949494949494949494949545949494941116666666666666059f9940666661110000000000000000
0d66555555555555555555600d665560555556656655555599444444444444444444445544444444111666666666666604944f40666661110000000000000000
00555555555555555555667000556670556556656655555594944444444444444444454544499944166166666666666605944940666616610000000000000000
0d655655d5555555565d66700d65667055555555555565559944545454545454545454554455559466666666666666660499f940666666660000000000000000
0d65555555555555555566700d656670555555555555555595454545454545454545454545555559666666666666666605454540666666660000000000000000
005555555555d5555555556000555560555555555555555594555555555555555555555545555559666666666666666650000005666666660000000000000000
00555655555555655565667000556670500000000000000555555555545445444494494945555559333333333333333333333333333333333333433300000000
0d65555555555555555566700d656670077767766777677054455445545445444494494945555559333333333333333333333333333343333333333300000000
0d65555555655555555555600d65556000665665566656604444444454544544449449494555555933333333b3333333333333b3343435343434393900000000
005555655555565556d5567000555670005555555555556045544554545445444494494945555559333333333333333333333333535343434393434300000000
0d66555555555555555556700d6656700d6566555565557055555555545445444494494945555559333333333313333333333331343435343434393900000000
0d66566556656665566655600d6655600d656655555565705445544554544544449449494555555933333333133333333333b331545445444494494300000000
00000dd00dd0ddd00ddd0060000000600055555ddd55566044444444545445444494494945555559333333331133333b33333331345435444394434900000000
50000000000000000000000550000005005555600d55566045544554545445444494494945555559333333331131333333331311543445434493494900000000
50000000000000000000000511111111005555600d55557050000000000000000000000511111111333333331113333313313111111111111111111100000000
077677766777677667776600111111110d656656655555700db3bb3b333b33b33b333b30141514153b3333331111113333111111111111111111111100000000
0d6566655666566556665600111111110d656655556655700035335535535555553535504141414133333b311111111111111111111111111111111100000000
0d6555555555555555555500111111110d655555556656600d555555555555555555556015141514331333331111111111111111111111331111111100000000
0d66555555555555555556705000000500555555555556600055655d555655655555567055555555113331331111111111111111111113331131113100000000
0d66566556656665566655600776667000566655665665700d655555555555555565567054455445111133111111111111111111331113311131113100000000
00000dd00dd0ddd50ddd00600d655670000ddd00dd0d0d700d655655565555555555567044444444111111111111111111111111333133311131313100000000
5000000000000000000000050d65556050000000000000050055555555555555d555556045544554111111111111111111111111133133113131333300000000
00000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b33b33b3b33b33b3b33b33000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02232332222323322223233000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02224249444242494442424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224444994444449944444f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0424444499444444994444f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0444444449944444499444f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0249444444994444449944f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0229944444499444444994f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224994444449944444499f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224499444444994444449a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224449944444499444444a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0224444994444449944444f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0424444499444444994444f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0444444449944444499444f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0249444444994444449944f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
83838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383
83838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383838383
53535353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53535353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53535353000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333334333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333433333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333334343j3434343939333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333j3j3434343934343333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333334343j3434343939333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333j4j44j4444944943333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333334j43j4443944349333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333j4344j4344934949333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333333333333333343333333333333333333
3333333333333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333333334333333333333333333333333333
3333333333333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333334343j34343439393333333333333333
3333333333333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j3j34343439343433333333333333333
3333333333333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333334343j34343439393333333333333333
3333333333333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4j44j44449449433333333333333333
3333333333333333j4j44j4444944949333333333333333333333333333333333333333333333333333333333333333334j43j44439443493333333333333333
3333333333333333j4j44j44449449493333333333333333333333333333333333333333333333333333333333333333j4344j43449349493333333333333333
3003003003003003j4j44j44449449493333333333333333j000000000000000000000000000000j3333333333333333j4j44j44449449493333333333333333
0490490490490490j4j44j444494494933333333333333330b33b33b3b33b33b3b33b33b3b33b3303333333333333333j4j44j44449449493333333333333333
0440440440440440j4j44j44449449493333333333333333000303300003033000030330000303303333333333333333j4j44j44449449493333333333333333
3003003003003003j4j44j44449449493333333333333333222020042220200422202004444040003333333333333333j4j44j44449449493333333333333333
3333333333333333j4j44j44449449493333333333333333422242299442422994424229944444ff3333333333333333j4j44j44449449493333333333333333
3333333333333333j4j44j44449449493333333333333333442444449944444499444444994444ff3333333333333333j4j44j44449449493333333333333333
3333333333333333j4j44j44449449493333333333333333244444444994444449944444499444ff3333333333333333j4j44j44449449493333333333333333
3333333333333333j4j44j44449449493333333333333333224944444499444444994444449944ff3333333333333333j4j44j44449449493333333333333333
3333333333333333j4j44j44449449493333333333333333222994444449944444499444444994ff3333333333333333j4j44j44449449493333333333333333
333333333b333333j4j44j44449449493333333333333333222499444444994444449944444499ff333333333b333333j4j44j44449449493333333333333333
333333b333333b3qj4j44j4444944949b333333333333333222449944444499444444994444449af333333b333333b3qj4j44j4444944949b333333333333333
3333333333q33333j4j44j44449449493333333333333333222444994444449944444499444444aa3333333333q33333j4j44j44449449493333333333333333
3333333qqq333q33j4j44j444494494933q3333333333333422444499444444994444449944444fa3333333qqq333333j4j44j444494494933q3333333333333
3333b33qqqqq33qqj4j44j4444944949q333333333333333442444449944444499444444994444ff3333b33q33qq333qj4j44j4444944949q333333333333333
3333333qqqqqqqqqj4j44j4444944949qq33333b33333333244444444994444449944444499444ff3333333q333q333qj4j44j4444944949qq33333b33333333
3333q3qqqqqqqqqqj4j44j4444944949qq3q333333333333224944444499444444994444449944ff3333q3qqq33q33qqj4j44j4444944949qq3q333333333333
q33q3qqqqqqqqqqqj4j44j4444944949qqq3333333333333222994444449944444499444j0000000000000000000000jj4j44j4444944949qqq3333333333333
33qqqqqqqqqqqqqqj4j44j4444944949qqqqqq33333333332224994444449944444499440b33b33b3b33b33b3b33b330j4j44j4444944949qqqqqq333b333333
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqb3333333222449944444499444444994000303300003033000030330j4j44j4444944949qqqqqqqq33333b3q
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq33333333222444994444449944444499222020042220200444404000j4j44j4444944949qqqqqqqq33q33333
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq33q333334224444994444449944444494222422994424229944444ffj4j44j4444944949qqqqqqqqqq333q33
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqq33333334424444499444444994444444424444499444444994444ffj4j44j4444944949qqqqqqqqqqqq33qq
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqq33333b2444444449944444499444442444444449944444499444ffj4j44j4444944949qqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqq3q33332249444444994444449944442249444444994444449944ffj4j44j4444944949qqqqqqqqqqqqqqqq
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqq333332229944444499444444994442229944444499444444994ffj4j44j4444944949qqqqqqqqj0000000
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqq332224994444449944444499442224994444449944444499ffj4j44j4444944949qqqqqqqq0db3bb3b
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224499444444994444449942224499444444994444449afj4j44j4444944949qqqqqqqq003j33jj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224449944444499444444992224449944444499444444aaj4j44j4444944949qqqqqqqq0djjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq4224444994444449944444494224444994444449944444faj4j44j4444944949qqqqqqqq00jj6jjd
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq4424444499444444994444444424444499444444994444ffj4j44j4444944949qqqqqqqq0d6jjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2444444449944444499444442444444449944444499444ffj4j44j4444944949qqqqqqqq0d6jj6jj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2249444444994444449944442249444444994444449944ffj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2229944444499444444994442229944444499444444994ffj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224994444449944444499442224994444449944444499ffj4j44j4444944949qqqqqqqq0d66jdjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224499444444994444449942224499444444994444449afj4j44j4444944949qqqqqqqq0d66jj6j
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224449944444499444444992224449944444499444444aaj4j44j4444944949qqqqqqqq0d66jjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq4224444994444449944444494224444994444449944444faj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq4424444499444444994444444424444499444444994444ffj4j44j4444944949qqqqqqqq0d6jj6jj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2444444449944444499444442444444449944444499444ffj4j44j4444944949qqqqqqqq0d6jjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2249444444994444449944442249444444994444449944ffj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2229944444499444444994442229944444499444444994ffj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224994444449944444499442224994444449944444499ffj4j44j4444944949qqqqqqqq0d66jdjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224499444444994444449942224499444444994444449afj4j44j4444944949qqqqqqqq0d66jj6j
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqqqqqqqq2224449944444499444444992224449944444499444444aaj4j44j4444944949qqqqqqqq0d66jjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqq3qqq3q4224444994444449944444494224444994444449944444faj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqq3qqq3q4424444499444444994444444424444499444444994444ffj4j44j4444944949qqqqqqqq0d6jj6jj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqqq3q3q3q2444444449944444499444442444444449944444499444ffj4j44j4444944949qqqqqqqq0d6jjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq3q3q33332249444444994444449944442249444444994444449944ffj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqqj0000000000000000000000000000000000000000000000j444994ffj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq0b33b33b3b33b33b3b33b33b3b33b33b3b33b33b3b33b330444499ffj4j44j4444944949qqqqqqqq0d66jdjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq000303300003033000030330000303300003033000030330444449afj4j44j4444944949qqqqqqqq0d66jj6j
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq222020042220200422202004222020042220200444404000444444aaj4j44j4444944949qqqqqqqq0d66jjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq4222422994424229944242299442422994424229944444ff944444faj4j44j4444944949qqqqqqqq00jjjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq4424444499444444994444449944444499444444994444ff994444ffj4j44j4444944949qqqqqqqq0d6jj6jj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq2444444449944444499444444994444449944444499444ff499444ffj4j44j4444944949qqqqqqqq0d6jjjjj
qqqqqqqqqqqqqqqqj4j44j4444944949qqqqqqqq2249444444994444449944444499444444994444449944ff449944ffj4j44j4444944949qqqqqqqq00jjjjjj
000000000000000jj00400400400400900q00q002229944444499444444994444449944444499444444994ff444994ffj4j44j4444944949qqqqqqqq00jjjjjj
333b33b33b333b300490490490490490490490492224994444449944444499444444994444449944444499ff444499ffj4j44j4444944949qqqqqqqq0d66jdjj
3jj3jjjjjj3j3jj00440440440440440440440442224499444444994444449944444499444444994444449af444449afj4j44j4444944949qqqqqqqq0d66jj6j
jjjjjjjjjjjjjj60j00400400400400900q00q002224449944444499444444994444449944444499444444aa444444aaj4j44j4444944949qqqqqqqq0d66jjjj
jjj6jj6jjjjjj670j4j44j4444944949qqqqqqqq4224444994444449944444499444444994444449944444fa944444faj4j44j4444944949qqqqqqqq00jjjjjj
jjjjjjjjjj6jj670j4j44j4444944949qqqqqqqq4424444499444444994444449944444499444444994444ff994444ffj4j44j4444944949qqqqqqqq0d6jj6jj
j6jjjjjjjjjjj670j4j44j4444944949qqqqqqqq2444444449944444499444444994444449944444499444ff499444ffj4j44j4444944949qqqqqqqq0d6jjjjj
jjjjjjjjdjjjjj60j4j44j4444944949qqqqqqqq2249444444994444449944444499444444994444449944ff449944ffj4j44j4444944949qqqqqqqq00jjjjjj
jjjjjjjjjjjjjj60j4j44j4444944949qqqqqqqq2229944444499444444994444449944444499444444994ff444994ffj4j44j4444944949qqqqqqqq00jjjjjj
jjjjjjjjjjjjj670jjj44j444j944j44qjq4qjq42224994444449944444499444444994444449944444499ff444499ffjjj44j444j944j44qjq4qjq40d66jdjj
jjjjjjjjjj6jj670j4j4jjj4j4j4j9j9jqjqjqjq2224499444444994444449944444499444444994444449af444449afj4j4jjj4j4j4j9j9jqjqjqjq0d66jj6j
jjjjjjjjjjjjjj60j4jj444j449j444jq4qjq4qj2224449944444499444444994444449944444499444444aa444444aaj4jj444j449j444jq4qjq4qj0d66jjjj
jjjjjjjjjjjj66704444444444444444444444444224444994444449944444499444440094444449944444fa944444fa44444444444444444444444400jjjjjj
djjjjjjjj6jd66704jj44jj44jj44jj44jj44jj44424444499444444994444449944440099444444994444ff994444ff4jj44jj44jj44jj44jj44jj40d6jj6jj
jjjjjjjjjjjj6670jjjjjjjjjjjjjjjjjjjjjjjj2444444449944444499444444994403b09944444499444ff499444ffjjjjjjjjjjjjjjjjjjjjjjjj0d6jjjjj
jjjjdjjjjjjjjj60j44jj44jj44jj44jj44jj44j2249444444994444449944444499403304994444449944ff449944ffj44jj44jj44jj44jj44jj44j00jjjjjj
jjjjjjjjjjjjjj604444444444444444j0000000000000000000000j44499444444900j300499444444994ff444994ff44444444444444444444444400jjjjjj
jjjjjjjjjjjjj6704jj44jj44jj44jj40b33b33b3b33b33b3b33b33044449944440044449a009944444499ff444499ff4jj44jj44jj44jj44jj44jj40d66jdjj
jjjjjjjjjj6jj670jjjjjjjjjjjjjjjj0003033000030330000303304444499440949949a9aa0994444449af444449afjjjjjjjjjjjjjjjjjjjjjjjj0d66jj6j
jjjjjjjjjjjjjj60j44jj44jj44jj44j2220200422202004444040004444449940949949a9aa0499444444aa444444aaj44jj44jj44jj44jj44jj44j0d66jjjj
jjjjjjjjjjjj667044444444444444444222422994424229944444ff94444449094994999a9aa049944444fa944444fa44444444444444444444444400jjjjjj
djjjjjjjj6jd66704jj44jj44jj44jj44424444499444444994444ff99444440949949999499aa04994444ff994444ff4jj44jj44jj44jj44jj44jj40d6jj6jj
jjjjjjjjjjjj6670jjjjjjjjjjjjjjjj2444444449944444499444ff499444409499499999a94904499444ff499444ffjjjjjjjjjjjjjjjjjjjjjjjj0d6jjjjj
jjjjdjjjjjjjjj60j44jj44jj44jj44j2249444444994444449944ff449944409499499999a94904449944ff449944ffj44jj44jj44jj44jj44jj44j00jjjjjj
jjjjjjjjjjjjjj6044444444444444442229944444499444444994ff444994404499499994994904j0000000000000000000000j444444444444444400jjjjjj
jjjjjjjjjjjjj6704jj44jj44jj44jj42224994444449944444499ff4444994044994999949949040b33b33b3b33b33b3b33b3304jj44jj44jj44jj40d66jdjj
jjjjjjjjjj6jj670jjjjjjjjjjjjjjjj2224499444444994444449af444449904449499994994904000303300003033000030330jjjjjjjjjjjjjjjj0d66jj6j
jjjjjjjjjjjjjj60j44jj44jj44jj44j2224449944444499444444aa444444904449499994949909222020042220200444404000j44jj44jj44jj44j0d66jjjj
jjjjjjjjjjjj667044444444444444444224444994444449944444fa94444440j4449499494999094222422994424229944444ff444444444444444400jjjjjj
djjjjjjjj6jd66704jj44jj44jj44jj44424444499444444994444ff994444440j4j444444j990444424444499444444994444ff4jj44jj44jj44jj40d6jj6jj
jjjjjjjjjjjj6670jjjjjjjjjjjjjjjj2444444449944444499444ff4994444440000000000004442444444449944444499444ffjjjjjjjjjjjjjjjj0d6jjjjj
jjjjdjjjjjjjjj60j44jj44jj44jj44j2249444444994444449944ff4499444440000000000004442249444444994444449944ffj44jj44jj44jj44j00jjjjjj
jjjjjjjjjjj66j60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000djjjjjj
jjjjjjjjjjj66jj6333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b3333b33b36jj66jjj
jjjjjjjjjjjjjjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjj3jj3jjjjjjj66jjj
jjjjjjjjjjjjj66jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj66jjjjjj
jjjjjjjjjj6jj66jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6jjjj6jj6j66jjjjjj
djjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj6jjj
jjjjjjjjjjjjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjj6jjjjjjjjjjjjjj
jjjjdjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
djjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjj
jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
jjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjjjjjjdjjj

__gff__
0000010602818a060606000000000000000101020a02020202020000000000000001010a0002020000000000000000000001010000818a0606060000000000000a0a0a0a0a0a060606000000000002000a0a0a0a0a0a0000000000000a0000000a0a0a0a0a0a020000000000000000000a0a0a010a0a0a0a0a02000000000000
0000000002020000000000000000000000000000020202020000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2a2b000102007677785210101010507677787979795200500708090000002c2d373839104a4b4c4d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b0011120050515252101010105050515266666652005017181900000000000000004a4b5b5b4c4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738390000005551545477787677556061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
52000000000000000000000000000000000000000000000000000000000000006a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a00000000000000000000000000000000515200007d1010100010101718181819404141414141414141414141716161000000520000000000005051515151515100000000000000000000000000007677
52000000000000000000000000000000000000000000000000000000000000006a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a0000000000000000000000000000000051520000070910101010101718181819505144444544446145514462000000000000530000000000405551515151515100000000000000000000000000765551
52000000000000000000000000000000007e00000000007d007e0000000000006a6a6a6a6a6a6a6a6a6a6a6a6a6a6a6a0000000000000000000000000000000051523535050535101010101718181819506152065062060050515200000000000000530066000000505151515151515100000000000000000000000000606161
52000000000000000000000000000000373800000000070808090000000000006a6a6d6e6a6a6a6a6a6a6a6a6a6a6a6a00000000000000000000000000000000515208080808091010101007080809195300060053000000065306000000003738395366664e0040555151515151515100000000000000000000000000000066
5200000000000000000000000000000000000000000017181819007d000000006a6a67686a6a6a6a6a6a6a6a6d6e6a6a7778000000000000000000000000000051520518181819101010101718181919060000000600000000060000000000000000534e4e004055515151515151515100000000000000000000000000000066
52000000000000000000000000000000000000000000171818070809000000006a6a67686a6a6a6a6a6a6a6a67686a6a51547777777778000000000000000000515478051818191000101017181819197d0000000000000000000000660000000000530000006045515151515151515100000000000000000000000000007677
52000000000000000000000000000000000000000000171818171819000000766c7a67686b6a6a6a6a6a6c7a67686b6a5151515144616200000000000000000051515478181819100010101718070808090066660000000000006666664e00000000530000000060455151515151515100000000000000000000000000005051
52000000000000000000000000000000000000000000171818171819000000507c0067687b6b6a6a6c7a7c0067687b7a515151446200000000373800000000005151515218181910001010171817181819004e4e00000000004e4e4e000000000000530000666600606161616145515100000000000000000000000000005051
5200000000000000000000000000000000000000007e1718181718190000005000006768007b7a7a7c00000067680000515144620000000000000000000000005151515205051910001007080917181819000000437e0000000000000000000000005042004e4e4e000000000050515100000000000037383937380000005051
5200000000000000000000000000007d0000000000070808080809190000005000006768000000000000000067680000514462000000000000000000000000005151515477781910001027161917181819000000504200000000000000000000007d505442000000000000000050515100000000000000000000000000005051
52000000007e0000000000000000007677783738391718181818191900000050000000000000000000000000000000005152000000007e00000000000000000051515151515205100010101719171818190000005052000000000000000007080808605162000043000000000050515100000000000000000000000000005051
527d007e00767800000000000000005051527979791718181818191979797950003535353535000000000000000000005152000000373800000000000000000044616145515442353535350708091818197d00005052007e00007d00000017181818186300006674723937383950515100003738393738000000000000005051
5477777777555279797979797979795051526666070809181818191966666650004041414142000000000000000000005152000000003738000000000035353552101060615162070808080808080808080808096062080808080808080809181818181900004e00000066664e50515100000000000000000000000000355051
5151515151515266666666666666665051526666171819181818070809666650355051515152000000000000000000005152000000000000000000007e07080952101010366336171818181818181818181818250808261807080808080808091818181900000000006666660050515100000000000000000000004041415551
5151515151515477777777777777775551547777777777777777777777777755405500000052000000000000000000005152000000000000000000070826181952101010100000171818181818181818181818181818181817181818181818191818187678007677777777777755515100000000000037383940415551515151
5151515151515151515151515151515151515151515151515151515151515151000000000000000000000000000000005152000000000000000000171818181952101010767777777777783738397677777777777777777777777777777777777777775552005051515151515151515100000000000000000050515151515151
fffff87fd3afff54806a6ee1cd1205cc1981078e1a1dbb8713122e2a757f7d6a14366c0236eecfa3c54d9eb5fcf70e179c7d39364a987fe34fccf7bbb8939e788ea413bf25f7efc3d9f8fe477278e27e7f709f8efd3f5e27fe37ebff91c5bfb7effa1f949fa7e937e9f879fc27f273f9cb7fafc2247f7c4fbfce4fc38e2d3f39
feb6ff91ff92fedfb4e1ff80ffc29ff81df5e75dffe2bfca64ae1fca7fe3571fbdffc9dbf4bbf55e3dffcbff97fe9d5ffcdff9e7fe00eabad2ffe53193ff134ffc5fdf16f3fd1ccdbeae4fca7fe37f33f9ff0fdd3d713ff47fe9eec917f1ffd53f39ff3f071fa9371bfc747e47f511b8f3ff0b89fd7f5f8cffd7acd3cdffafff
57fe204cfda72e093ff27f9fd6fc7ff29ff8abff67fed93ff75d2d92ddbaf3ff22f1efbec90e174e7ff2affae47010777ff27f4fe27d3fb29a7fef92fff012df2ff51e91f87f2441c95acb07e2bfd3f2e4a54fc579e78e39928a9ce54e27ff17e1b8ffe41d7043ff1cfc9affe0ffcba27f47e44affcaea2717f1afc2f843fb34
eddf3fefe1f879e7bd38e24bf89fc3ff17076fdfb9f9fe51ff913f089f831fbf5f3d7f9e3dbffcfff9fff3e9ffcec7eb8fcafdf4ee2b9b5ffca5964d214fc27f7ffd275f97ff5ffedf8f3cc071f9e7fe2fcbff090efc8fc5bf8a62d9ff87ff347ff2fcf3f5cceebe4593ee26ffcbfa7fe588fc5bf47faea167ef5072ffc9ff93
ff21f92f50fc68babc592487e7178a701bf3ffef3ffbfe1d7ff8fcbff37ff97ed759112249e801ebf84e27525fc2f9f7e16ffdff9bff070e643c3de3f4e3ffcdbc6fc3acfcd3de3f1fc6fedf769db9afbff3df723af8fc534f220e7ff57f3fcff5fa71f9a710e4fd802121212121212121212121212121212121212121212121
fffff87fd3afee900c1862d1a0ddc3931cf1d4830e055a713136842495b71c71272ba23fffe09cce7871d77e757ffffe093f19ea43fffd93e57e1d9c3848ffff54fc7f29386eb9e79e7efb802c754ffffbafffffc810ffffa73f9f3cfe9faea710ffffabf6933c9c07fffcb4f2cdcfeffc27687fffc0b37ed27bd9eaf9ce7071
3b87fffb64eed87b3f928fffff82220ffffa64fea7c7fffe2713b91fffffdc21212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
2121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
2121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121
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

