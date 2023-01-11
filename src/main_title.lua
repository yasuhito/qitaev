---@diagnostic disable: lowercase-global

require("lib/helpers")

require("lib/cursor")
require("lib/qpu")
require("title/game")
require("title/plasma")
require("lib/board")

demo_game = game()

local menu_class = require("title/menu")

local main_menu = menu_class(
  "quantattack_tutorial,,32,48,16,16,,tutorial,learn how to play|quantattack_endless,,64,48,16,16,,endless,play as long as you can, 1|quantattack_rush,,48,48,16,16,,rush,play for 2 minutes,0|,:level_menu,80,48,16,16,,vs qpu,defeat the qpu|quantattack_qpu_vs_qpu,,96,48,16,16,,qpu vs qpu,watch qpu vs qpu"
  ,
  ":demo"
)
local level_menu = menu_class(
  "quantattack_vs_qpu,,48,80,19,7,3|quantattack_vs_qpu,,72,80,27,7,2|quantattack_vs_qpu,,104,80,19,7,1",
  ":main_menu"
)

-- :logo_slidein QuantumAttack のロゴ slide-in アニメーション
-- :board_fadein ボードの fade-in アニメーション
-- :demo デモプレイ
-- :main_menu メニューを表示した状態
-- :level_menu QPU のレベル選択
local title_state = ":logo_slidein"
local tick = 0

function _init()
  local qpu_cursor = cursor_class()
  local qpu_board = board_class(qpu_cursor, 0, 16)
  local qpu = create_qpu(qpu_board, 1)

  qpu:init()
  qpu_board:put_random_blocks()

  qpu_board.show_wires = false
  qpu_board.show_top_line = false

  demo_game:init()
  demo_game:add_player(qpu, qpu_board)
end

function _update60()
  if title_state == ":logo_slidein" then
    -- NOP
  elseif title_state == ":board_fadein" then
    demo_game:update()
  elseif title_state == ":demo" then
    demo_game:update()
    update_title_logo_bounce()

    if btnp(5) then -- x でタイトルへ進む
      sfx(15)
      title_state = ":main_menu"
    end
  elseif title_state == ":main_menu" then
    if main_menu._active_item_index == 4 then
      level_menu.stale = true
    end

    main_menu.stale = false
    title_state = main_menu:update() or title_state
  elseif title_state == ":level_menu" then
    level_menu.stale = false
    title_state = level_menu:update() or title_state
  end

  tick = tick + 1
end

function _draw()
  cls()

  if title_state == ":logo_slidein" then
    sspr(unpack_split("0,64,128,16,0," .. tick))

    if tick > 24 then
      title_state = ":board_fadein"
    end
  elseif title_state == ":board_fadein" then
    sspr(unpack_split("0,64,128,16,0,24"))

    if tick <= 90 then
      fadein((tick - 26) / 3)
    end
    demo_game:render()
    pal()

    if tick > 90 then
      title_state = ":demo"
    end
  else
    sspr(0, 64, 128, 16, 0, 24 + title_logo_bounce_screen_dy)

    demo_game:render()

    if title_state == ":demo" then
      -- X start を表示
      if tick % 60 < 30 then
        print_outlined("x start", 50, 50, 1)
      end
    else -- ":main_menu" or ":level_menu"
      -- メニューのウィンドウを表示
      draw_rounded_box(unpack_split("7,46,118,108,0,0")) -- ふちどり
      draw_rounded_box(unpack_split("8,47,117,107,12,12")) -- 枠線
      draw_rounded_box(unpack_split("10,49,115,105,1,1")) -- 本体

      -- メニューを表示
      main_menu:draw(15, 72)

      -- レベル選択メニューを表示
      if main_menu._active_item_index == 4 or title_state == ":level_menu" then
        level_menu:draw(27, 93)
      end
    end
  end

  render_plasma()
end

function fadein(i)
  local index = flr(15 - i)

  for c = 0, 15 do
    if index < 1 then
      pal(c, c)
    else
      pal(c,
        split(split("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0|1,1,129,129,129,129,129,129,129,129,0,0,0,0,0|2,2,2,130,130,130,130,130,128,128,128,128,128,0,0|3,3,3,131,131,131,131,129,129,129,129,129,0,0,0|4,4,132,132,132,132,132,132,130,128,128,128,128,0,0|5,5,133,133,133,133,130,130,128,128,128,128,128,0,0|6,6,134,13,13,13,141,5,5,5,133,130,128,128,0|7,6,6,6,134,134,134,134,5,5,5,133,130,128,0|8,8,136,136,136,136,132,132,132,130,128,128,128,128,0|9,9,9,4,4,4,4,132,132,132,128,128,128,128,0|10,10,138,138,138,4,4,4,132,132,133,128,128,128,0|11,139,139,139,139,3,3,3,3,129,129,129,0,0,0|12,12,12,140,140,140,140,131,131,131,1,129,129,129,0|13,13,141,141,5,5,5,133,133,130,129,129,128,128,0|14,14,14,134,134,141,141,2,2,133,130,130,128,128,0|15,143,143,134,134,134,134,5,5,5,133,133,128,128,0"
          , "|")[c + 1])[index])
    end
  end
end
