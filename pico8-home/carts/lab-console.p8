pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- Game Loop
#include ../../lib/utils.lua
#include ../../lib/topdown_engine.lua

#include ../../lib/input_util.lua

#include ../../lib/open_lab_remote.lua
#include ../../lib/arcade_games_config.lua

game_states = {
  sleeping = 1,
  main_lab = 2,
  idling = 3,
  arcade_menu = 4
}
current_game_state = game_states.sleeping

dget_indexes = {
  p_x = 0,
  p_y = 1,
  arcade_selected_game = 2,
  arcade_menu_open = 3
}

debug = false
frame_count = 0

function _init()
  cartdata("alt-ctrl-lab")
  load_player_pos()
  init_input()
  init_arcade_selection()

  if dget(dget_indexes.arcade_menu_open) == 1 then
    switch_to_arcade_menu_state()
  else
    switch_to_lab_main_state()
  end

  if debug then
    poke(0x5F2D, 1)
  end
end

function _update()
  frame_count += 1
  handle_input()

  if current_game_state == game_states.sleeping then
    update_sleep_screen()
  elseif current_game_state == game_states.idling then
    update_idle_screen()
  elseif current_game_state == game_states.main_lab then
    update_lab_open()
  elseif current_game_state == game_states.arcade_menu then
    update_arcade_menu()
  end

  if debug then
    debug_draw_mouse(main_cam)
  end
end

-->8
-- Input handling

button_states = nil

function init_input()
  button_states = create_button_states()
end

function handle_input()
  update_button_states(button_states)
end

-->8
-- lab open game state

main_cam = create_camera(6 * 8, 2 * 8)

function switch_to_lab_main_state()
  open_lab_remote()
  init_lab_open()
  current_game_state = game_states.main_lab

  -- reset arcade menu state
  dset(dget_indexes.arcade_menu_open, 0)
  dset(dget_indexes.arcade_selected_game, 1)
end

function init_lab_open()
  clear_interactables()
  init_lever()
  init_arcade_interactable()
  init_bench()
end

function update_lab_open()
  cls(0)

  draw_map(main_cam, 0, 0, vector(), 25, 25)

  update_player()

  update_interactables(p.body, button_states[btn_ids.primary].pressed)

  if debug then
    debug_draw_interactables(main_cam)
  end
end

-->8
-- player controller

p_walk_anim = create_anim({ 0, 2 }, 4)

p = {
  body = topdown_body(vector(), vector(1, 1)),
  spr_offset = vector(-4, -8),
  speed = 1,
  vel = vector(0, 0),
  flip_x = false
}

camera_offset = vector(64, 48)

function load_player_pos()
  local spawn_pos = vector(dget(dget_indexes.p_x), dget(dget_indexes.p_y))
  if spawn_pos.x == 0 and spawn_pos.y == 0 then
    spawn_pos = vector(13, 8)
  end

  set_body_pos(p.body, spawn_pos)
end

function update_player()
  local input_v = vector()

  if button_states[btn_ids.left].pressed then input_v.x -= 1 end
  if button_states[btn_ids.right].pressed then input_v.x += 1 end
  if button_states[btn_ids.up].pressed then input_v.y -= 1 end
  if button_states[btn_ids.down].pressed then input_v.y += 1 end

  local moved = simple_move(p.body, input_v, 0)

  -- main_cam.pos = v_sub(p.body.visual_pos, camera_offset)

  if p.body.facing.x != 0 then
    p.flip_x = p.body.facing.x < 0
  end

  local p_sprite = 0

  if p.body.facing.x != 0 then
    p_sprite = 0
  elseif p.body.facing.y > 0 then
    p_sprite = 4
  elseif p.body.facing.y < 0 then
    p_sprite = 2
  end

  draw_sprite(main_cam, p_sprite, v_add(p.body.visual_pos, p.spr_offset), 2, 2, p.flip_x)
end

-->8
-- go to sleep interactable
lever = nil

function init_lever()
  lever = create_interactable(vector(18, 6), vector(2, 2), switch_to_sleep_screen, while_lever_in_range)
  register_interactable(lever)
end

function while_lever_in_range()
  btn_prompt_centered("🅾️", "close lab", 64, 108, 8, 7)
end

function save_player_pos()
  local x = p.body.pos.x
  local y = p.body.pos.y
  dset(dget_indexes.p_x, x)
  dset(dget_indexes.p_y, y)
end

-->8
-- lab asleep game state

function update_sleep_screen()
  if button_states[btn_ids.primary].pressed then
    switch_to_lab_main_state()
  end

  if button_states[btn_ids.secondary].pressed then
    switch_to_lab_main_state()
  end
end

function switch_to_sleep_screen()
  cls(0)

  -- spr(32, 55, 54, 2, 2)
  print_centered("alt-ctrl lab is closed", 64, 40, 1)
  btn_prompt_centered("🅾️", "open lab", 64, 84, 1, 1)
  -- rect(0, 0, 127, 127, 7)

  close_lab_remote()
  current_game_state = game_states.sleeping
end

-->8
-- idle awake interactable
bench = nil

function init_bench()
  bench = create_interactable(vector(13, 11), vector(2, 1), switch_to_idle_screen, while_bench_in_range)
  register_interactable(bench)
end

function while_bench_in_range()
  btn_prompt_centered("🅾️", "idle", 64, 108, 8, 7)
end

-->8
-- idle awake game state

function update_idle_screen()
  if button_states[btn_ids.primary].pressed then
    switch_to_lab_main_state()
  end

  if button_states[btn_ids.secondary].pressed then
    switch_to_lab_main_state()
  end
end

function switch_to_idle_screen()
  cls(0)

  -- map(40, 0, 0, 0, 16, 16)

  print_centered("idling... lab is still open", 64, 40, 1)
  btn_prompt_centered("🅾️", "return", 64, 84, 1, 1)

  current_game_state = game_states.idling
end

-->8
-- arcade game selection window

arcade_interactable = nil
selected_game_index = 1
entries_per_page = 4

function init_arcade_interactable()
  arcade_interactable = create_interactable(vector(8, 7), vector(2, 1), switch_to_arcade_menu_state, while_arcade_in_range)
  register_interactable(arcade_interactable)
end

function init_arcade_selection()
  selected_game_index = dget(dget_indexes.arcade_selected_game)
  if selected_game_index == 0 or selected_game_index > #arcade_games_list then
    selected_game_index = 1
  end
end

function while_arcade_in_range()
  btn_prompt_centered("🅾️", "arcade", 64, 108, 8, 7)
end

function switch_to_arcade_menu_state()
  current_game_state = game_states.arcade_menu
  dset(dget_indexes.arcade_menu_open, 1)
  redraw_arcade_menu()
end

function update_arcade_menu()
  local did_change = arcade_menu_input()

  if did_change then
    redraw_arcade_menu()
  end
end

function arcade_menu_input()
  if button_states[btn_ids.up].pressed then
    selected_game_index = selected_game_index - 1
    if selected_game_index < 1 then
      selected_game_index = 1
    end
    return true
  end

  if button_states[btn_ids.down].pressed then
    selected_game_index = selected_game_index + 1
    if selected_game_index > #arcade_games_list then
      selected_game_index = #arcade_games_list
    end
    return true
  end

  if button_states[btn_ids.left].pressed then
    current_page = flr((selected_game_index - 1) / entries_per_page)
    new_page = current_page - 1
    if new_page < 0 then
      return false
    end
    selected_game_index = new_page * entries_per_page + 1
    return true
  end

  if button_states[btn_ids.right].pressed then
    current_page = flr((selected_game_index - 1) / entries_per_page)
    new_page = current_page + 1
    total_pages = flr((#arcade_games_list - 1) / entries_per_page)
    if new_page > total_pages then
      return false
    end
    selected_game_index = new_page * entries_per_page + 1
    return true
  end

  if button_states[btn_ids.secondary].pressed then
    switch_to_lab_main_state()
  end

  if button_states[btn_ids.primary].pressed then
    save_player_pos()
    dset(dget_indexes.arcade_selected_game, selected_game_index)
    load_arcade_game(selected_game_index)
  end

  return false
end

function redraw_arcade_menu()
  cls()

  local selected_game = arcade_games_list[selected_game_index]

  -- title
  print_centered(selected_game.name, 71, 6, 10)
  rect(15, 1, 127, 15, 6)

  -- credits
  local credits = wrap_text(selected_game.credits, 120, ",")
  local height = print_height(credits)
  local credits_bot_y = 15 + height + 5
  print(credits, 4, 18, 6)
  rect(0, 15, 127, credits_bot_y, 8)

  -- desc
  print(wrap_text(selected_game.desc, 120," "), 4, credits_bot_y + 3, 7)

  -- game list
  local space_per_entry = 7
  local list_section_y = 98

  -- frame
  rect(0, 0, 15, 15, 8)
  rect(0, 15, 127, 127, 8)

  -- 0 indexed
  local page = flr((selected_game_index - 1) / entries_per_page)
  local total_pages = flr((#arcade_games_list - 1) / entries_per_page)

  for i = 1, entries_per_page do
    local game_index = page * entries_per_page + i
    if game_index > #arcade_games_list then
      break
    end

    local game = arcade_games_list[game_index]
    local y = list_section_y + (i - 1) * space_per_entry
    local clr = 7
    if game_index == selected_game_index then
      clr = 8
    end

    print(game_index .. ".", 5, y, clr)
    print(game.name, 15, y, 7)
  end

  rect(0, list_section_y - 4, 127, 127, 13)

  -- page display
  print("page " .. page + 1 .. "/" .. total_pages + 1, 5, list_section_y - 11, 7)
  rect(0, list_section_y - 14, 45, list_section_y - 4, 13)

  -- input prompt
  btn_prompt("🅾️", "play", 57, list_section_y - 11, 8, 7)
  btn_prompt("❎", "exit", 90, list_section_y - 11, 11, 7)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000a00a00000000000a00a00000000000000a00a00000000000a00a0000000000000000000000000000000000000000000000000000000000000000000000
000000a00a000000000000a00a000000000000a00a000000000000a00a0000000000000000000000000000000000000000000000000000000000000000000000
00009999444400000000999944440000000099994444000000009999444400000000000000000000000000000000000000000000000000000000000000000000
00009cccccc4000000009cc7c7c4000000009cccccc4000000009cccccc400000000000000000000000000000000000000000000000000000000000000000000
00009cccccc4000000009cc7c7c4000000009cccccc4000000009cccccc400000000000000000000000000000000000000000000000000000000000000000000
00009cc7c7c4000000009cccccc4000000009cccccc4000000009cccccc400000000000000000000000000000000000000000000000000000000000000000000
00009cc7c7c4000000009cccccc4000000009cc7c7c4000000009cc7c7c400000000000000000000000000000000000000000000000000000000000000000000
00004cccccc9000000004cccccc9000000004cc7c7c9000000004cc7c7c900000000000000000000000000000000000000000000000000000000000000000000
00004499999900000000449999990000000044999999000000004499999900000000000000000000000000000000000000000000000000000000000000000000
00000044900000000000004490000000000000449000000000000044900000000000000000000000000000000000000000000000000000000000000000000000
00000449990000000000044999000000000004499900000000000449990000000000000000000000000000000000000000000000000000000000000000000000
00001099901000000000109990100000000010999010000000001099901000000000000000000000000000000000000000000000000000000000000000000000
00000010100000000000001010000000000000101000000000000010100000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000a00a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a00a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999944440006700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009cccccc40067760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009cccccc90066660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004c77c7790666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004cccccc96660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044999400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00109191010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000bbbbbbbbbbbbbbbb0000000000000000cccccccc
000000000000000000000000000000000000000000000000bbbb3bbbbbbbbbbbbbbbbbbb0000000000000000bbbbbbbbbbbbbbbb0000000000000000cccccccc
000000000000000000000000000000000000000000000000bbbb3bbbbbb3bbbbbb5566bb0000000000000000bbbbbbbbbbbbbbbb0000000000000000cccccccc
000000000000000000000000000000000000000000000000bbbb3b3bbbb3bbbbb551566b0000000000000000bb5565665bbbbbbb0000000000000000cccccccc
000000000000000000000000000000000000000000000000bb3bbb3bbbb3bbbbb51bb55b0000000000000000b555656665bbbbbb0000000000000000cccccccc
000000000000000000000000000000000000000000000000bb3bbbbbbbb3b3bbb55bb56b0000000000000000b555bbb665bbbbbb0000000000000000cccccccc
000000000000000000000000000000000000000000000000bbbbbbbbbbbbb3bbb553355b0000000000000000b55bbbbb55bbbbbb0000000000000000cccccccc
000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbb333333b0000000000000000b553333355bbbbbb0000000000000000cccccccc
0000000000000000ccbbbbbbbbbbbbbbbbbbbbcc00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333bbbbbb000000000000000000000000
0000000000000000cbbbbbbbbbbbbbbbbbbbbbbc00000000bbbb8bbbbbbbbbbbbbbb666bbbbbbbbb33bbbbbbbbbbbbbbb555bbbb000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bb8b8abbbb666bbbb66bd666bbbbbb3311bbbbbbbbbbbbbb55555bbb000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000ba8b38bbb66666bbb666b666bbbb331111bbbbbbbbbbbbbb55b55bbb000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000b8b3bbbbbd66ddbbbd66b66dbb33111111bbbbbbbbbbbbbb55355bbb000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbb3bbbbbbddbbbbbbddbddbbb2211111133bbbbbbbbbbbb33333bbb000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbbbb22211188aa33bbbbbbbbbbbbbbbbbb000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbbbbbbbbbb00000000bbbbbbbbbbbbbbbbbbbbbbbbbb22228888aaaabbbbbbbbbbbbbbbbbb000000000000000000000000
00000000000000003bbbbbbbbbbbbbbbbbbbbbb300000000bbbbbbbbbbbbbbbb00000000bb22228888aaaabb0000000000000000000000000000000000000000
000000000000000033bbbbbbbbbbbbbbbbbbbb3300000000bbbbbbbbbbbbbbbb00000000bb22228888aaaabb0000000000000000000000000000000000000000
000000000000000023333333333333333333333200000000333333bbbb33333300000000bbbb2288999aaabb0000000000000000000000000000000000000000
0000000000000000223333333333333333333322000000003333333bb333333300000000bbbbbb999999aabb0000000000000000000000000000000000000000
000000000000000024222233332222333322224200000000332222333322223300000000bbbbbb999999bbbb0000000000000000000000000000000000000000
000000000000000044444422224444222244444400000000224444233244442200000000bbbbbb9999bbbbbb0000000000000000000000000000000000000000
000000000000000044444444444444444444444400000000444444422444444400000000bbbbbb99bbbbbbbb0000000000000000000000000000000000000000
000000000000000024444444444444444444444200000000444444422444444400000000bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
000000000000000024444444444444444444444200000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
000000000000000044224444224224444444224400000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
000000000000000024422422444224222242244200000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
000000000000000064444444444444444444444600000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
0000000000000000c7444444444444444444447c00000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
0000000000000000cc77777777777777777777cc00000000cccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccccccccccccccccccccc00000000bccccccccccccccb0000000000000000000000000000000000000000000000000000000000000000
0000000000000000cccccccccccccccccccccccc00000000bbccccccccccccbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbabbbabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2226262288bbbb288bbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2222622228bbbb228bbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2221212228bbbb1221bbbbbbbbbbbbffffffffffffffb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb5212221222bbbbbb11dbbbbbbbbbbb44444444444444b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb5522288888bbbbbbb11dbbbbbbbbbb22444444222222b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb5cccccc778bbbbb1111dd6771111bb44444444444444b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2ccccccc78bbbb1122d6666672211bbb22bbbbbb22bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2cccccccc8bbbb1a26611111662aab44444444444444b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2cccccccc8bbbbaa26111111162aab44444444444444b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2dccccccc8bbbbaa22222222222a1b22224422222424b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2ddcccccc8bbbb9111aaa111aaa10b44444444444444b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2222228888bbbb300999000999003b22222222222222b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2111111118bbbbb3333333333333bbdddd3333335dddb00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2181167718bbbbbbb333bbbbbbbbbb53d3333333353db00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2171166718bbbbbbb33bbbbbbbbbbb55333333333355b00000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2111111118bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2228888888bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2222222222bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2111111112bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb2111111112bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb3211111123bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb3333333333bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb333333bbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000010101000101000000000000000000000101010001010000000000000000
0101010101010000000000000000000001010101010100000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f525353544f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f478081534f4f4f4f4f4f525353544f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f525353534f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f53909153764f4f4f4f77538283564f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f535353534f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f53a0a146535353535353539293534f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f525353535353544f4f4f4f6263636363634f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f535753535353595a5346535358534f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f535353535353534f4f4f4f7273737373734f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f626366535653696a5353536763644f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f626363636363644f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f72737353534784855357537373744f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f727373737373744f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f53535394955353534f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f62665353535367644f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f72736263636473744f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f727373744f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f4f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
