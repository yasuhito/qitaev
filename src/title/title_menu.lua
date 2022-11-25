require("board")
require("plasma")

local gamestate = require("gamestate")
local menu_item = require("menu_item")
local text_menu_class = require("text_menu")

-- main menu: gamestate for player navigating in main menu
local title_menu = derived_class(gamestate)
title_menu.type = ':title_menu'

-- sequence of menu items to display, with their target states
title_menu._items = {
  menu_item("solo", 'qitaev_solo'),
  menu_item("vs qpu", 'qitaev_vs_qpu'),
  menu_item("qpu vs qpu", 'qitaev_qpu_vs_qpu')
}

local text_menu = text_menu_class(title_menu._items)

function title_menu:on_enter()
  -- NOP
end

function title_menu:update()
  text_menu:update()
end

function title_menu:render()
  render_plasma()

  demo_game:render()

  -- ロゴを表示
  sspr(0, 64, 128, 16, 0, 24)

  -- メニューのウィンドウを表示
  draw_rounded_box(31, 65, 96, 99, 0, 0) -- ふちどり
  draw_rounded_box(32, 66, 95, 98, 12, 12) -- 枠線
  draw_rounded_box(34, 68, 93, 96, 1, 1) -- 本体

  -- メニューを表示
  text_menu:draw(40, 72) -- 40 + 4 * character_height (= 6)
end

return title_menu