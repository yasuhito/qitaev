require("engine/core/class")
require("engine/core/fun_helper")
require("engine/core/helper")
require("engine/core/string")
require("engine/render/color")

local gamestate = require("engine/application/gamestate")
local ui = require("engine/ui/ui")
local menu_item = require("menu_item")
local text_menu = require("text_menu")

-- main menu: gamestate for player navigating in main menu
local title = derived_class(gamestate)

title.type = ':title'

-- sequence of menu items to display, with their target states
title._items = transform({
  { "1 player", ':solo' },
}, unpacking(menu_item))

-- text_menu: text_menu    component handling menu display and selection
function title:_init()
  self.text_menu = text_menu(title._items)
end

function title:update()
  self.text_menu:update()
end

function title:render()
  cls()

  local title_y = 48
  ui.print_centered("qitaev", 64, title_y, colors.white)

  -- skip 4 lines and draw menu content
  self.text_menu:draw(title_y + 4 * character_height)

  -- skip 4 lines and draw how to start
  ui.print_centered("push z to start", 64, title_y + 8 * character_height, colors.white)
end

return title