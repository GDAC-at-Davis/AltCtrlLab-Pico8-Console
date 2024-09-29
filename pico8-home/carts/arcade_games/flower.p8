pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
g_coroutines = {}
g_floor = true
g_idle = true
g_menu = false
g_on = false
g_x = 24
g_y = 40
g_i = 0
g_c = 0
g_jump = -2
g_gr = 0.12
g_fr = 0.85
g_ac = 0.2

g_p = {
  o = 0,
  s = 64,
  x = 280,
  y = -14,
  dx = 0,
  dy = 0,
  fl = false,
  alive = true,
}

g_g = {
  s = 9,
  x = 180,
  y = 81,
  fl = true,
  alive = true,
}

g_particles = {}
g_rain = {}

g_inside = true
g_pause = false
g_lock = false

g_flowers = {}
g_level = 2
g_shift = 0

g_typer = {
  w = -1,
  c = -1,
  o_c = -1,
  s = "",
  l = {""},
  a = {0},
  y = 0,
  t = 0,
}

g_d = {
  o_g = 704,
  o_y = 8,
}

g_final = 0

function drip()
  local delay = 14
  while true do
		  g_d.x = g_d.o_g
		  g_d.y = g_d.o_y
		  for i = 1,4 do
		    wait(delay)
		    g_d.y += 1
		  end
		  g_d.x += 1
		  for i = 1,6 do
		    wait(delay)
		    g_d.y += 1
		  end
		  g_d.x += 1
		  for i = 1,3 do
		    wait(delay)
		    g_d.y += 1
		  end
		  wait(delay)
		  g_d.y += 1
		  g_d.x += 1
		  wait(delay)
		  local o = 0
		  while true do
		    local temp = g_d.y+1+o
		    if temp > 119 then
		      g_d.y = 119
		      for i = 1,3 do
		        pop(g_d.x, g_d.y, true)
		      end
		      break
		    end
		    g_d.y = temp
		    o+= 0.06
		    wait(1)
		  end
		  wait(2)
		  g_d.y += 100
		  wait(100)
  end
end

function upper()
  wait(10)
  for i = 1,6 do
    g_typer.y += 1
    wait(1)
  end
end

function typer()
  g_typer.y = 0
  g_typer.w = 6
  g_typer.c = 7
  g_typer.o_c = 7
  g_typer.l = {""}
  g_typer.a = {0}
  local old = g_shift
  local skip = false
  local tilda = false
  local string = g_typer.s
  local list = split(string, "")
  for i = 1,#list do
    if old != g_shift then
      return
    end
    local char = list[i]
    if char == "\n" then
      add(g_typer.l, "")
      add(g_typer.a, 0)
      animate(upper)
      skip = true
    elseif char == "%" then
      skip = true
      wait(10)
    elseif char == "~" then
      tilda = true
      skip = true
    elseif tilda then
      local value = tonum(char)
      if char == "w" then
        g_typer.c = 7
      elseif char == "r" then
        g_typer.c = 8
      elseif char == "p" then
        g_typer.c = "d"
      elseif value then
        g_typer.w = value*3
      end
      tilda = false
      skip = true
    end
    if not skip then
      local j = #g_typer.l
      if not (i == 1 or char == " "
      or char == "%" or char == "\n"
      or (list[1] == "~" and i == 3)) then
        wait(g_typer.w)
      end
      local convert = ""
      if g_typer.o_c != g_typer.c then
        convert = "\f"..tostr(g_typer.c)
        g_typer.o_c = g_typer.c
      end
      local top = 3
      local r = rnd(top)\1+1
--      if g_level != 3 then
--        sfx(50, 1, r-1, 1)
--      end
      -- extra backup
      if old != g_shift then
        return
      end
      if g_menu then
        while true do
          wait(1)
        end
      end
      g_typer.l[j] = g_typer.l[j]..convert..char
      g_typer.a[j] += 1
    end
    skip = false
  end
  if g_typer.s == "" then
    return
  end
  wait(140)
  -- extra backup
  if old != g_shift then
    return
  end
  if g_level <= 1 then
    if g_shift == 1 then
      if g_typer.t == 1 then
        g_typer.s = "~4i thought you\nmade it past the\n~rred ~wrain~9... ~4but\nno matter~9... ~4i am\nhappy for the\ncompany."
        animate(typer)
      else
        g_typer.s = ""
        animate(typer)
      end
      g_typer.t += 1
    elseif g_typer.t >= 4 then
      if g_typer.t == 4 then
        g_typer.s = "~4i wish i could\n~ppause ~wthis one\nperfect moment\nforever."
      elseif g_typer.t == 5 then
        g_typer.s = "~4could you watch\nthe rain with me\nfor a little bit\nlonger?"
      elseif g_typer.t == 6 then
        g_typer.s = ""
      end
      animate(typer)
      g_typer.t += 1
    end
  end
end

function plant(x , y)
  local flower = {
    s = 41,
    x = x,
    o = x,
    y = y,
    i = 1,
    fl = false,
  }
  add(g_flowers, flower)
end

function sway()
  while true do
    wait(30)
    local list = {41, 42, 43, 42}
    for flower in all(g_flowers) do
      local x = g_x+peek2(0x5f28)
      local fx = flower.x
      local fy = flower.y
      if not (g_menu
      and fx > x-5
      and fx < x+77
      and fy > g_y-6
      and fy < g_y+47) then
		      flower.s = list[flower.i]
		      if flower.i == 1 then
		        flower.fl = not flower.fl
		      end
		      if flower.fl then
		        flower.x = flower.o-1
		      else
		        flower.x = flower.o
		      end
		      if flower.i != 4 then
		        flower.i += 1
		      else
		        flower.i = 1
		      end
      end
    end
  end
end

function plants()
  animate(sway)
  plant(496, 89)
  plant(304, 89)
  plant(352, 105)
  plant(548, 81)
  wait(75)
  plant(584, 113)
  plant(608, 113)
  plant(672, 113)
  plant(728, 113)
  wait(50)
  plant(616, 113)
  plant(656, 113)
  plant(680, 113)
  plant(720, 113)
  plant(736, 113)
end

function _init()
  menuitem(1, "debug", menu)
  animate(sprinkle)
  animate(plants)
  animate(idle)
  camera(256)
end

function menu()
  g_menu = true
  g_on = true
  main()
end

function touch(obj, dir)
  local x = obj.x
  local y = obj.y
  local x1 = 1
  local x2 = 1
  local y1 = 0
  local y2 = 12
  if dir == "right" then
    x1 = 14
    x2 = 14
  elseif dir == "bottom" then
    x1 = 5
    x2 = 10
    y1 = 14
    y2 = 14
  end
  return fget(mget((x+x1)/8, (y+y1)/8), 0)
      or fget(mget((x+x2)/8, (y+y2)/8), 0)
end

function collide(dir)
  local wall = nil
  local button = nil
  local moving = g_p.dy > 0
  if dir == "left" then
    button = 0
    wall = touch(g_p, dir)
  elseif dir == "right" then
    button = 1
    wall = touch(g_p, dir)
  elseif dir == "bottom" then
    wall = touch(g_p, dir)
    if wall and moving then
      g_p.dy = 0
    end
  end
  local n_b = dir != "bottom"
  if n_b and btn(button) and wall then
    g_p.dx = 0
  end
  local c = 0
  local temp = {
    x = g_p.x,
    y = g_p.y
  }
  temp.x += g_p.dx
  temp.y += g_p.dy
  local o = 1
  if dir != "left" then
    o = -1
  end
  while touch(temp, dir) do
    if n_b then temp.x += o*1
    else temp.y += o*1 end
    c += 1
  end
  if c > 1 then
    local v = o*(c-1)
    if n_b then g_p.x += v
    else g_p.y += v end
  end
end

function death()
  local delay = 100
  g_p.x = 704
  for i = 1,4 do
    g_p.x -= 0.5
    wait(1)
  end
  g_p.s = 144
  wait(50)
  g_p.s = 146
  wait(delay)
  g_p.s = 148
  wait(delay)
  g_p.s = 150
  g_p.x -= 4
  wait(delay)
  plant(g_p.x+6, g_p.y+7)
  g_p.y += 100
end

function controller_1()
  g_p.dx *= g_fr
  g_p.dy += g_gr
  if btn(0) and not btn(1) then
    g_p.dx -= g_ac
    g_p.fl = true
  elseif btn(1) and not btn(0) then
    g_p.dx += g_ac
    g_p.fl = false
  end
  if abs(g_p.dx) < g_ac then
    g_p.dx = 0
  end
  g_p.dx = mid(-1.3, g_p.dx, 1.3)
  collide("bottom")
  collide("right")
  collide("left")
  -- jump
  if g_p.dy == 0 then
    g_c = 0
    if btn(4) then
      g_p.dy = g_jump
    end
  else
    -- coyote time
    g_c += 1
    if g_c <= 6 and g_p.dy > 0
    and btn(4) then
      g_p.dy = g_jump
      g_c = 100
    end
  end
  g_p.x += g_p.dx
  g_p.y += g_p.dy
end

function idle()
  g_i += 1
  g_p.s = 64+g_p.o
  local o = 1
  local old = g_i
  while g_i == old and g_floor
  and g_p.alive do
    if not g_inside then
      g_p.s += o*2
      o *= -1
      wait(20)
    else
      wait(1)
    end
  end
end

function bob()
  g_i += 1
  g_p.s = 68+g_p.o
  local o = 1
  local old = g_i
  while g_i == old and g_floor
  and g_p.alive do
    if not g_inside then
      g_p.s += o*2
      o *= -1
      wait(4)
    else
      wait(1)
    end
  end
end

function air()
  while not g_floor do
    if g_p.o != 40 then
      local o = g_p.o/2
      if g_p.dy <= 0 then
        g_p.s = 96+o
      else
        g_p.s = 98+o
      end
    end
    wait(1)
  end
end

function player()
  if touch(g_p, "bottom") then
    if abs(g_p.dx) > g_ac then
      if g_idle then
        g_idle = false
        animate(bob)
      end
    else
      if not g_idle then
        g_idle = true
        animate(idle)
      end
    end
    if not g_floor then
      g_floor = true
      animate(idle)
      g_idle = true
    end
  else
    if g_floor then
      g_floor = false
      animate(air)
    end
  end
  -- death
  if g_level == 0
  and g_p.y > 230 then
    animate(shift, "right")
    g_p.x = 232
    g_p.y = 82
  elseif g_level == 1
  and g_p.y > 160 then
    g_p.x = 232
    g_p.y = 82
  elseif g_level == 3
  and g_p.y > 160 then
    g_p.x = 408
    g_p.y = 98
  end
end

function controller_2()
  if btn(0) and not btn(1) then
    g_x -= 1
  elseif btn(1) and not btn(0) then
    g_x += 1
  end
  if btn(2) and not btn(3) then
    g_y -= 1
  elseif btn(3) and not btn(2) then
    g_y += 1
  end
end

function shift(dir)
  local old = peek2(0x5f28)
  local c = 18
  local o = 1
  if dir == "left" then
    o *= -1
  else
    if g_level == 3 then
      -- dumb trick
      g_floor = false
      g_jump = -1.45
      g_ac = 0.12
      g_p.o = 8
    elseif g_level == 4 then
      g_floor = false
      g_jump = 0
      g_ac = 0.065
      g_p.o = 40
    end
  end
  -- goto
  g_menu = false
  g_lock = true
  g_on = false
  g_x = 24
  g_y = 40
  local last = g_level
  while true do
    local x = peek2(0x5f28)
    local move = x+(1+c\2)*o
    if not (abs(move-old) >= 128) then
      camera(move)
    else
      break
    end
    if c > 2 then
      c -= 0.75
    else
      c = 0
    end
    wait(1)
  end
  wait(1)
  camera(peek2(0x5f28)+o)
  g_lock = false
  if g_level == 1
  or (g_level == 2
  and last == 1)
  and last != 0 then
    if g_shift == 0 then
      animate(gus)
    elseif g_shift == 3 then
      g_g.alive = false
      plant(g_g.x+6, g_g.y+8)
    end
    g_shift += 1
  end
  if g_level == 4 and g_final == 0 then
    animate(drip)
    g_final = 1
  end
end

function tick()
  if g_pause then
    wait(2)
    g_pause = false
  end
end

function _update60()
  if not g_menu then
    animate(tick)
    if btn(6) then
      g_pause = true
    end
  end
  events()
  main()
  local c_x = peek2(0x5f28)
  local diff = g_p.x-c_x
  if not g_lock then
    if diff >= 120
    and g_p.dx > 0 then
      animate(shift, "right")
    elseif diff <= -7
    and g_p.dx < 0 then
      animate(shift, "left")
    end
  end
end

function events()
  local c_x = peek2(0x5f28)
  g_level = c_x/128\1
  if g_p.x < 204 then
    if g_typer.t == 0 then
      g_typer.s = "~6ah~9... ~4welcome\nback old friend.%%%%\n~4i am suprised to\nsee you again."
      animate(typer)
      g_typer.t += 1
    elseif g_typer.t <= 3
    and g_shift == 3 then
      g_typer.s = "~4i fear that my\ntime has nearly\nreached its end."
      animate(typer)
      g_typer.t = 4
    end
  elseif g_level > 1 then
    g_typer.s = ""
    g_typer.l = {""}
    g_typer.a = {0}
  end
  -- death scene
  if g_p.x > 705 and g_final == 1 then
    g_final = 2
  elseif g_p.x < 704 and g_final == 2 then
    g_p.alive = false
    animate(death)
    g_final = 3
  end
end

function main()
  -- pause player
  local xi = g_x+peek2(0x5f28)
  g_inside = false
  local x = g_p.x
  local y = g_p.y
  if g_menu
  and x > xi-9
  and x < xi+73
  and y > g_y-12
  and y < g_y+45 then
    g_inside = true
  end
  local bool = not g_pause
  if not g_on then
    if not g_inside and bool
    and g_p.alive then
      controller_1()
    end
    updater()
    if bool then
      player()
    end
  else
    controller_2()
  end
  -- draw
  cls()
  pal()
  if g_on then
    pal(8, 5)
    pal(7, 5)
    pal(6, 5)
    pal(2, 5)
  end
  draw()
  -- menu
  if g_menu then
    if btnp() == 64 then
      g_on = not g_on
      poke(0x5f30, 1)
    end
    square()
  end
  if not g_on then
    rainer()
  end
end

-- goto
function spawn(n, x)
		for i = 0,n do
				local blood = {
				  s = 128+rnd(4)\1,
				  x = x+i*8,
				  y = 2*-rnd(10)-10,
				  dy = 0,
				  depth = (rnd(14)\1)*2
				}
				add(g_rain, blood)
				if #g_rain > 200 then
				  deli(g_rain, #g_rain\2)
				end
		end
end

function sprinkle()
		while true do
		  if g_level <= 2 then
		    spawn(19, 0)
		  end
		  if g_level >= 2
		  and g_level <= 4 then
		    spawn(6, 433)
		  end
				wait(10)
		end
end

function either()
  local value = rnd(2)+1
  value *= rnd(2)\1*2-1
  return value
end

function pop(x, y, blue)
  local dx = either()
  local dy = either()
  local blood = {
    x = x,
    y = y,
    dx = dx,
    dy = dy,
    l = rnd(20)\1,
    c = rnd(2)\1*6+2
  }
  if blue then
    blood.l = 24
    blood.c = 12
  end
  add(g_particles, blood)
end

function gus()
  local o = 1
  while g_g.alive do
    local x = g_x+peek2(0x5f28)
    local gx = g_g.x
    local gy = g_g.y
    if not (g_menu
    and gx > x-11
    and gx < x+77-4
    and gy > g_y-12
    and gy < g_y+45) then
      g_g.s += o*2
      o *= -1
    end
    wait(60)
  end
end

-- drawing
error = ""
debug = false
function draw()
  map()
  for flower in all(g_flowers) do
    spr(flower.s, flower.x, flower.y, 1, 1, flower.fl)
  end
  palt(0, false)
  palt(1, true)
  if g_g.alive then
    spr(g_g.s, g_g.x, g_g.y, 2, 2, g_g.fl)
  end
  spr(g_p.s, g_p.x, g_p.y, 2, 2, g_p.fl)
  if debug then
    local x = g_p.x
    local y = g_p.y
    -- left
    pset(x+1, y, 8)
    pset(x+1, y+12, 8)
    -- right
    pset(x+14, y, 8)
    pset(x+14, y+12, 8)
    -- bottom
    pset(x+5, y+14, 8)
    pset(x+10, y+14, 8)
    -- print
    error = stat(1)
    local c_x = peek2(0x5f28)
    --error = g_p.x
    print(error, c_x+8, 10, 8)
  end
  palt()
  -- falling blood drops
  for blood in all(g_rain) do
    spr(blood.s, blood.x, blood.y)
  end
  -- blood splash
  for blood in all(g_particles) do
    pset(blood.x, blood.y, blood.c)
  end
  -- water drip
  pset(g_d.x, g_d.y, 12)
  -- camden
  for i = 1,#g_typer.l do
    local string = g_typer.l[i]
    local o = g_typer.a[i]*2
    local y = g_typer.y
    local m_x = 188-o
    local m_y = 74-y
    m_y += (i-1)*6
    print(string, m_x, m_y, 7)
  end
end

function square()
  clip(g_x-1, g_y-1, 82, 50)
  pal(8, 1)
  pal(7, 1)
  pal(6, 1)
  pal(5, 1)
  pal(2, 1)
  draw()
  pal()
  if not g_on then
    pal(7, 5)
  end
  local x = peek2(0x5f28)+g_x
  rect(x, g_y, x+79, g_y+47, 7)
  print("menu location", x+10, g_y+6, 7)
  print("x: "..g_x, x+10, g_y+14, 7)
  print("y: "..g_y, x+10, g_y+22, 7)
end

function dist(obj)
  local x0 = g_p.x+8
  local x1 = obj.x+3
  local y0 = g_p.y+7
  local y1 = obj.y+4
  local dx = (x0-x1)/64
  local dy = (y0-y1)/64
  local d = dx^2+dy^2
  if d < 0 then return 32767 end
  return sqrt(d)*64
end

function rainer()
  -- falling blood drops
  for blood in all(g_rain) do
    if  blood.x > g_p.x-20
    and blood.x < g_p.x+20
    and dist(blood) <= 5 then
      -- death
      if g_p.x < 150 then
        g_p.x = 232
        g_p.y = 82
      elseif g_p.x > 420
      and g_p.x < 450 then
        g_p.x = 408
        g_p.y = 98
      elseif g_p.x >= 450
      and g_p.x < 480 then
        g_p.x = 496
        g_p.y = 82
      end
    end
    blood.dy += 0.1
    if blood.dy > 3 then
      blood.dy = 3
    end
    -- goto
    local x = g_x+peek2(0x5f28)
    if not (g_menu
    and blood.x > x-4
    and blood.x < x+79
    and blood.y > g_y+2+blood.depth
    and blood.y < g_y+44) then
      if not g_pause then
        blood.y += blood.dy
      end
    end
    local hit = mget((blood.x+2)/8, (blood.y+7)/8)
    if hit != 0 or blood.y > 130 then
      if hit != 0 then
        for i = 0,7 do
          pop(blood.x+3, blood.y+6)
        end
      end
      del(g_rain, blood)
    end
  end
  -- blood splash
  for blood in all(g_particles) do
    blood.x += blood.dx/4
    blood.y += blood.dy/4
    blood.l += 1
    if blood.l > 30 then
      del(g_particles, blood)
    end
  end
end

-- animate
function wait(dur)
  for i = 1,dur do
    yield()
  end
end

function animate(call, args)
  local co = cocreate(function() call(args) end)
  add(g_coroutines, co)
end

function updater()
  for co in all(g_coroutines) do
    if costatus(co) == "dead" then
      del(g_coroutines, co)
    else
      coresume(co)
    end
  end
end
__gfx__
00000000777777777777777777777777777777776000007088888888111111117777777611111167771111111111111111111111055500000000005550000000
00000000700000000000000000000000000000076000007088888888111111117666667611166666666661111111116777111111055500000000005550000000
00000000706770000677007006700700067700076000007088888888111111117777777611111677777111111116666666666111055505550055005550005555
00000000706770000677000006700000067700076000007088888888111111117666767611111600700111111111167777711111000005550055000000005555
00000000706770000677000000006770067700076700007088888888111111117777777611111677706111111111160070011111000005550000000000005555
00000000700000000000067000006770000000070600076088888888111111110007600011111676006111111111167770611111555000000000055555005555
00000000700000700000067000006770000007070600070088888888111111110007600711111666666111111111167600611111555055005550055555000000
00000000700000000000000000000000000000070600070088888888111111110607606011111660006111111111166666611111555055005550055555000000
00000000700000000000000770000000000000070600070000000000000000000000000011111167771111111111166000611111000055505550055555000000
00000000706700700067700000677000067007070600070000000000000000000000000011116671111111111111116777111111000055500000055555055500
00000000706700000067700000677000067000070670070000000000000000000000000011166777177111111111667111161111555055500000000000055500
00000000700000000067700000677000000000070060760000000000000000000000000011166777177111111116677711771111555000000005550000055500
00000000700067700000000000000000000677070060700000000000000000000000000011776677116111111116677711771111555000000005550000000000
00000000700067700700067007000670000677070060700000000000000000000000000011776716716111111177667771161111000005550005550055000000
00000000700067700000067000000670000677070006000000000000000000000000000011116716716111111177671671161111005505550000000055000000
00000000700000000000000000000000000000070000000000000000000000000000000011111111111111111111111111111111005505550000000000000000
00000000700000000000000000000000000000070000000000000000000000000000000000070000000000000000000000000000000000000000000000000000
00000000700000000000677000000000000000070000000000000000000000000000000000607000000070000000000000000000000000000000000000000000
00000000706770070070677006700000677007070000000000000000000000000000000000060000000607000000700000000000000000000000000000000000
00000000706770000000677006700000677000070000000000000000000000000000000000070000000060000006070000000000000000000000000000000000
00000000706770000000000000006770677000070000000000000000000000000000000000070000000070000000600000000000000000000000000000000000
00000000700000670067007000006770000067070000000000000000000000000000000060070060600700606007006000000000000000000000000000000000
00000000700000670067000000706770000067070000000000000000000000000000000007060700070607000706070000000000000000000000000000000000
00000000700000000000000770000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000706770000677007006700700067700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000706770000677000006700000067700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000706770000677000000006770067700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000067000006770000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000700000067000006770000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111677777111111111111111111111111116777771111111111111111111111111116777771111111111111111111111111167777711111111111111111111
11111677777111111111167777711111111116777771111111111677777111111111116777771111111111677777111111111167777711111111116777771111
11111660706111111111167777711111111116660701111111111677777111111111116007001111111111677777111111111166007011111111116777771111
11111666666111111111166060611111111116666661111111111666060111111111116666661111111111600600111111111166666611111111116600601111
11111660006111111111166666611111111116600001111111111666666111111111116600061111111111666666111111111166000011111111116666661111
11111666666111111111166000611111111116666661111111111660000111111111116666661111111111660006111111111166666611111111116600001111
11111116711111111111166666611111111111167111111111111666666111111111111671111111111111666666111111111116711111111111116666661111
11111666666111111111111671111111111116666661111111111116711111111111166666611111111111167111111111111666666111111111111671111111
11111667777111111111166666611111111116677771771111771666666111111111166777711111111116666661111111111667777177111177166666611111
11771667777177111111166777711111117716677771771111771667777177111177166777717711111116677771111111771667777177111177166777717711
11771667777177111111166777711111117716677771111111111667777177111177166777717711111116677771111111771667777111111111166777717711
11111667777111111177166777717711111116677777711111111667777111111111166777711111117716677771771111111667777771111111166777711111
11111671167111111177166777717711111116711111111111167767777111111111167116711111117716677771771111111671111111111116776777711111
11111671167111111111167116711111111116711111111111111111167111111111167116711111111116711671111111111671111111111111111116711111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111116777771111111111111111111111111167777711111111111111111111
11111677777111111111167777711111111111677777111111111167777711111111116777771111111111677777111111111167777711111111116777771111
11111670607111111111167777711111111111600600111111111167777711111111116007001111111111677777111111111166007011111111116777771111
11111666666111111111166666611111111111666666111111111166666611111111116666661111111111600600111111111166666611111111116600601111
11111660006111111111166060611111111111660006111111111160060011111111116600061111111111666666111111111166000011111111116666661111
11111660006111111111166666611111111111660006111111111166666611111111116666661111111111660006111111111166666611111111116600001111
11111666666111111111166007611111111111666666111111111166007611111111111671111111111111666666111111111116711111111111116666661111
11111116711111111111111671111111111111167111111111111116771111111111166666611111111111167111111111111666666177111111111671111111
11111666666111111177166666617711111116666661111111771666666177111177166777711111111116666661771111111667777177111177166666611111
11111667777111111177166777717711111116677771111111771667777177111177166777717711111116677771771111771667777116111177166777717711
11771667777177111111166777711111117716677771771111111667777111111111166777717711117716677771161111771667777116111111166777717711
11771667777177111111166777711111117716677771771111111667777111111111166677711611117716677771161111111667777716111111166777711611
11111676666111111167776777777711111116766661111111677767777777111111116711671611111116667777161111111167116711111116776777711611
11116711116711111111111111111111111167111167111111111111111111111111116711671611111111671167111111111167116711111111111116711611
11116711116711111111111111111111111167111167111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000000000820008200000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000200220002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200000000000000002000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02880000002000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02880000028800000020000002880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22888000228880000888000002880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22282000222820002288800002820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02220000022200000222000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111167777711111111111677777111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111167777711111111111677777111111111677777111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111160060011111111111600600111111111677777111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111166666611111111111666666111111111006006111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111166000611111111111660000111111111666666111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111166666611111111111666666111111111000006111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111116711111111111111167111111111111666666111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111666666177111111116666611111111111116711111111111771111111110000000000000000000000000000000000000000000000000000000000000000
11111667777177111111166677711771111111666661771111111771160677710000000000000000000000000000000000000000000000000000000000000000
11771667777116111111166777711771111116667771771111766666160607710000000000000000000000000000000000000000000000000000000000000000
11771667777116111177166777711161111116666661161117677776760607710000000000000000000000000000000000000000000000000000000000000000
11111666777716111177166677771161117716677777161111177776666667710000000000000000000000000000000000000000000000000000000000000000
11111167116711111111116711671161117711671167161111766666166666610000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111117666776166666610000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111771111111110000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010101000000000000000000000000010101010000000000000000000000000101010100000000000000000000000001010101000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000210000000000000000000000000014000021000000000022333233323332333233340000000000000031323332333233230000000000002233333323000000000000223233323332333233320000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000313233322300000000000000000024000011000000223334001500000500150000150000000000000000050000000000313233230000223415050031333233323332340005001500150000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000015050031333233323332333233340000313233323400000000000015000000000000000000000000001500000d0000000500313233340000150000150000001500000015000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000001500000015001505000000150000000000051500000000000000000000000d00000000000000000000000000000000150000150500000000000000000000000000000000001d000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000001500000000000000000015000000000e0f00000000000000000000000000000000000000000000000000000015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e1f00000d00000000000000000000000000000000000000000000000000000000000e0f00000000000d000000000000000008000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e0f0000000000001d0000001e1f000104000000000000000000000103020000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e1f000000000000000000000000001114000000000000000000003123000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000001d0000000000000e0f00000000000000000000001d0000000000000000000000000000000103021324000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000e0f0000000000000000000000000000001e1f00000000000000000000000000000000000000000d00000000080011000000140000000000000e0f00000021000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001e1f000000000000000000000000000000000000000000000000000000000000000000000000000000000001020313000022340000000000001e1f00000011000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000000000010400000000003133323333323400000000000000000000000021000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000001030203020302030203020302030203020302040000000000000000001d00000000000000000000010302030203131202040000000000000000000000000d00000000000000000011000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001130000000000000000000000000000000000001400000000000000000000000000000000000000011200000000000000002400001d0000000d000000000000000000000000001d0021000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000001100000000000000000000000000000000000000120203020302030203020302030204000001020313000000000000000000140000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000002100000000000000000000000000000000000000000000000000000000000000000014000011000000000000000000000000120203020302030203020302030203020302030203020313000000000000000000000000000000000000000000000000000000000000000000