pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main
function init()
t=0
fc=0
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
load_level(
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
		local dw = abs(sin(t)*16)
		sspr(24,0,16,16,c.x-dw/2,c.y-16,dw,16)
	end)
	draw_dust()
	
	draw_blocks(true)	
	camera()
	
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

function _update60()
	profile_cpu_usage=0
	profile_calls=0
	local stat_1 = stat(1)
	t+=1/60
	fc+=1
	
	local thud_y = -25
	if coin_at and coin_at+2>time() then
		thud_y = 0
	end
	if hud_y > thud_y then
		hud_y -= 1
	elseif hud_y < thud_y then
		hud_y += 1
	end
	
	if died_at and died_at < time() - 1 then
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

	update_camera()
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
	if not jump_btn_down and btn(4) then
	 jump_btn = time()
	end
	jump_btn_down = btn(4)

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

	
	if player.y-128 > 16*cam_bounds[4] then
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
	chunk=19,
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
					elseif player.x > 260 then
							load_level(level4, 16, -4)
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
			front=true,
			colide=false,
			106,3,--src
			4,4,--size
			0,28,--dst
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
		{x=2.5,y=4,id=4},
		{x=45.5,y=10,id=5},
		{x=76.5,y=13,id=6}
	},
	e={
		{x=86.5,y=11, minx=670, maxx=770},
		{x=86.5,y=11, minx=670, maxx=770}
	},
	{
		32,1,
		3,1,
		30,10,
		update=drop
	},
	{
		32,1,
		3,1,
		36,8,
		update=drop
	},
	{
		0,3,--src,
		58,16,
		0,0,
		update=function()
			if btn(5) then
				player.x=620
				player.h.x=620
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
		32,1,
		3,1,
		60,5,
		update=drop
	},
	{
		32,1,
		3,1,
		66,3,
		update=drop
	},
	{
		27,13,
		16,6,
		58,5
	},
	{
		58,3,--src,
		58,16,
		74,0,
	}	
}

level4={
	pal=day,
	c={
		{x=43/8, y=191/8, id=7},
		{x=352/8, y=120/8, id=8},
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
		35,0,
		6,3,
		4,5,
		rx=7,
		colide=false,
		update=function()
			if player.y>264 then
				load_level(level3, 971, 0, 0, 0)
			end
		end
	},
	{
		35,0,
		44,14,
		4,8,
		colide=false,
		fill=6
	},
	{
		0,3,
		48,16,
		0,0
	},
	{
		48,3,
		48,16,
		0,16
	},
	--{
--		96,3,
--		32,16,
--		0,32
--	},
--	{
--		fill=5,
--		96,3,
--		16,16,
--		32,32
--	},
	{
		30,0,
		2,1,
		12,21,
		update=alternate
	},
	{
		30,0,
		2,1,
		17,23,
		update=alternate
	},
	{
		40,6,
		4,7,
		42,12,
		front=true
	}
}

levels={
	level1, level2, level3, level4
}
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
		maxy=e.maxy,
		miny=e.miny,
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
	cartdata("kai-pumkin-x")
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
50000000000000000000000550000005555555555555555550000000000000000000000599949499111111111111116666111111111111115555555500000000
0776777667776776677767700776667055555555555555550499999499999994999999704999994911111111111111666611111111111111544554450e000e00
0d65666556665665566657700d65567055565555555555550544444444444444444444909555559411111111116666166166661111111111444444440e000e00
0d65555555555555555555600d65556055555566566556559000000000000000000000044555559411111111166666666666666111111111455445540e000e00
0055655d55565565555557700055567055555566566555559494444444444444444444454555559411111111666666666666666611111111555555550e0e0e00
0d65555555555555556557700d655670555665555555555599445454545454545454545445555594111111116666666666666666111111115445544500e0e000
0d65565556555555555557700d6556705556655ddd56655595454545454545454545454545555595111111116666666666666666111111114444454400000000
0055555555555555d555556000555560555555600d56655594555555555555555555555554444455111111166666666666666666611111114544444400000000
00555555555555555555556000555560555665600d55555599999999999999999999954599999999111116616666666650000005166111110006000000000000
0d665d5555555555555556700d665670555665566556655599494949494949494949495549494949111166666666666604444440666611110000600000eee000
0d66556555555555556556700d6656705555555555566555949494949494949494949545949494941116666666666666059f99406666611100060000000e0000
0d66555555555555555555600d665560555556656655555599444444444444444444445544444444111666666666666604944f406666611100006000000e0000
005555555555555555556670005566705565566566555555949444444444444444444545444999441661666666666666059449406666166100060000000e0000
0d655655d5555555565d66700d65667055555555555565559944545454545454545454554455559466666666666666660499f9406666666600006000000e0000
0d65555555555555555566700d656670555555555555555595454545454545454545454545555559666666666666666605454540666666660006000000eee000
005555555555d5555555556000555560555555555555555594555555555555555555555545555559666666666666666650000005666666660000600000000000
00555655555555655565667000556670500000000000000555555555545445444494494945555559333333333333333333333333333333333333433300000000
0d65555555555555555566700d656670077767766777677054455445545445444494494945555559333333333333333333333333333343333333333300eee000
0d65555555655555555555600d65556000665665566656604444444454544544449449494555555933333333b3333333333333b3343435343434393900e00e00
005555655555565556d5567000555670005555555555556045544554545445444494494945555559333333333333333333333333535343434393434300e00e00
0d66555555555555555556700d6656700d6566555565557055555555545445444494494945555559333333333313333333333331343435343434393900eee000
0d66566556656665566655600d6655600d656655555565705445544554544544449449494555555933333333133333333333b331545445444494494300e00000
00000dd00dd0ddd00ddd0060000000600055555ddd55566044444444545445444494494945555559333333331133333b33333331345435444394434900e00000
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
0000010602818a060606000000000000000101020a0202020202000000000000000101000002020000000000060600000001010000818a0606060000000000000a0a0a0a0a0a0606060000000000020a0a0a0a0a0a0a0000000000000a00000a0a0a0a0a0a0a0200000000000000000a0a0a0a010a0a0a0a0a02000000000000
0000000002020000000000000000000000000000020202020000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2a2b000102007677785210101010507677787979795200500708090000002c2d373839104a4b4c4d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a3b0011120050515252101010105050515266666652005017181900000000007071724a4b5b5b4c4d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738390000005551545477787677556061624e4e4e547755171819a0a10000000000005a5b5b5b5b5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505151515151515151515305051818181818181818181856595746474819000017181718191900001718181819000000505251515151510000000000000000000000000000000000000000000000000050
5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505151515151515144616171721818181818181818181856695757575819000017181718191900001718181819000000505251515151510000000000000000000000000000000000000000000000004055
6f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000505251515151446162666617171818181818181818180708080808080808080917181718191900001718181819000000505251515151000000000000000000000000000000000000000000000000005051
7777777777777777780000000000000000000000000000000000000000000000000000000000000046474748000000505251515144626666666617171818181818181818181718181818181818181917181718191900001707080808080808505251515151000000000000000000000000000000000000000000000000405551
5151515151446161620000464747474747474747474747474800000000000000000000000000000056575758000000505251514462666666666617171818181818181818181718181818181818070808080808080900001717181818181818505251515151000000000000000000000000000000000000000000000000505151
5151515144620000000000565749575749575749575749575800000000000000464747474800000056495758004a4b505251515266666666666617173c3d181818181818181718181818181818171818181818181900001717181818181876555251515100000000000000000000000000000000000000000000000000505151
51515151520000000000005657495757495757495757495746474747480000005649574958000000565757584a4b5b605251515266666666404142171818181818181818181718181818181818171818181818180708080809181818181850515251515100000000000000000000000000000000000000000000000040555151
51515151544200000000005657575757575757575757575756575757580000005657575758000000564957585a5b5b4f52515152666666405551544218181818183c3d18181718181818181818171818181818181718181819181818187655515251515100000000000000000000000000000000000000000000004055515151
51515151515200000000005657575757575757575757575756495749580000005649574958000000565957580000005f5251515441414155515151521818181818181818181718181818181818171818181818181718181819181818765551515251510000000000000000000000000000000000000000000000405551515151
51515151446172000000070808080957575759575757575756575759580000005657595758000000566957580000006f5251515151515151515144621818181818181818181718181818181818171818181818181718181819187677555151515251510000000000000000000000000000000000000000000000604551515151
5144616162666600000017181818195757576957575757575657576958000000565769575800000007080808080808085251515151515151515152171818181818181818181718181876777778171818181818181718181876775551515151515251510000000000000000000000000000000000000000000000006045515151
6162666666666600000017070808080808080808080808080808080809000007082618250937380708261818181818185251515151515151515152171818181818181818181718187655515152171818181818181776777755515151515151515251510000000000000000000000000000000000000000000000000050515151
6666666666666600000017171818181818181818181818181818181819000017181818181900001718181818181529405251515151515151514462171818181876780505050576775551515154777777781818187655515151515151515151515251510000000000000000000000000000000000000000000000000060455151
666666666640414142001717181818181818181818181818181818185c37385c180708091900001718181818152900505251515151515151446266171818187651544141414155515151515151515151517777775551515151515151515151515251000000000000000000000000000000000000000000004379797979505151
6666666640555151544217171818181818181818181846474748181819000017181718191900001718181815290000505251515151515144626666171818765551515151515151515151515151515151515151515151515151515151515151515251000000000000000000000000000000000000000000405542666666604551
4141414155515151515217171818181818181818181856575758181819000017181718191900001718181819000000505251515151515152666666177677555151515151515151515151515151515151515151515151515151515151515151515441414141414141414141414141414141414141414141555154426666666051
fffff87fd3afff74806aa3f48173066041e386876ee1c4c48b8a9d5fcd4286cd81bb811b77399d9f478a9b3d6bf9ee1c24e5bce36c9530ffc69f99f9db626e2484e7a97bf3df67df81dc9eb89f8fe1c27e3bf2fcf89ff8df9ffe4716fe9fafe87e327e9fa4dfa7e1e7ec9fb9cfe72dfe3f0847f3c4f7fae4fc38d69f9cfedb7e
68ffd8ff0ff53fc77d79d77ff5fdd32570fdd3ff02b8fdeffe1edfa5ffc5ff8d78fe3ff27fe4ffa757ff2ffe69ff803aaeb4bff90c64ff9a7fdfcf16ffe4ffce72e3ff471f85727e53ff03f99fbffa7ea9f389ffa7ff577648bf97feb9f9cffc0fc1c7eb1ffa1a6fe9d1f91fd446e3dfd9c4feffbfc67fecd669e6ffd9ffaffe
04ce5fed3a9d3bdff85fc3f8df97fe63ff157fedffdd27fefba5b25bb75e7fe57a7b39ffc950702bb9df0ffc364fda7d3fb29a7ff092fff112df27f135fbe988fc3f24e563a1cb0aa967e6bfd3f2e4a54fc57f12a71c6ffc9538bffca4fb71ffcc4e18ef9ebafca4bfbcfc9affe0689fd1f912bff2849ffd3ffaa2713f3ffe7f
09f87327ff29fd9a74efbeff0fc3aebb3871c497f134e5f93fed3c76fe7b9f9fe493ff0a7e724f14fdfaf5c3fdf1edffedffdbffb74ffed63f5c7e57ecfc73ff9d92c9a573209c92399fe7ff793f339fb9fc206736d92f79dfe3ff88879e47e2dfd5316cffc3ff9a3ff9fe79f56791fb57127dc4dff97f6ffc91d9f87fe27f6f
fcbcc2cfdec1caefe52d576bd43e451757ab2490fe78f8e16fff8bffe3f0ebffcfe5ff97ffd3f8bac892047b81eefdbfdd3a937e17cfbf0b7fdffd1fed707522787afd17ffd5bc6fb9cfcd3de3f1fce7eff8f69c73f97e3f9f9e4ffd37cbc475f1f8a69df2839ffd7ff93ff2ffe8fd38fcd388727c9c809c8021212121212121
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

