local flow = require("engine/application/flow")
local ui = require("engine/ui/ui")

require("engine/application/constants")
require("engine/core/class")
require("engine/render/color")

local gamestate = require("engine/application/gamestate")
local solo = derived_class(gamestate)

local player_class = require("player")
local player = player_class()

local player_cursor_class = require("player_cursor")
local player_cursor = player_cursor_class()

local board_class = require("board")
local board = board_class()

local gate = require("gate")

local puff_particle = require("puff_particle")

solo.type = ':solo'

local buttons = {
  left = 0,
  right = 1,
  up = 2,
  down = 3,
  x = 4,
  o = 5,
}

function solo:on_enter()
  board:initialize_with_random_gates()
  player:init()
  self.tick = 0
end

function solo:update()
  if board:is_game_over() then
    if btnp(buttons.o) then
      flow:query_gamestate_type(':title')
    end
  else
    if btnp(buttons.left) then
      player_cursor:sfx_move()
      player_cursor:move_left()
    end
    if btnp(buttons.right) then
      player_cursor:sfx_move()
      player_cursor:move_right()
    end
    if btnp(buttons.up) then
      player_cursor:sfx_move()
      player_cursor:move_up()
    end
    if btnp(buttons.down) then
      player_cursor:sfx_move()
      player_cursor:move_down()
    end
    if btnp(buttons.x) then
      if board:swap(player_cursor.x, player_cursor.x + 1, player_cursor.y) then
        player_cursor:sfx_swap()
      end
    end

    player.score = player.score + board:update()
    player_cursor:update()
    puff_particle:update()

    if self:_maybe_raise_gates() and rnd(1) < 0.05 then
      board:drop_garbage()
    end

    self.tick = self.tick + 1
  end
end

function solo:_maybe_raise_gates()
  if (self.tick < 30) then -- TODO: 30 をどこか定数化
    return false
  end

  self.tick = 0

  if (board:is_busy()) then
    return false
  end

  board.raised_dots = board.raised_dots + 1

  if board.raised_dots == tile_size then
    board.raised_dots = 0
    board:insert_gates_at_bottom(player.steps)
    player_cursor:move_up()
    player.steps = player.steps + 1
  end

  return true
end

function solo:render() -- override
  cls()
  board:render()
  player_cursor:render(board)
  self:render_score()
  puff_particle:render()

  if board:is_game_over() then
    ui.draw_rounded_box(10, 47, 117, 70, colors.dark_gray, colors.white)
    ui.print_centered("game over", 64, 55, colors.red)
    ui.print_centered("push x to replay", 64, 63, colors.black)
  end

  color(colors.white)
  cursor(1, 1)
  print(stat(1))
  cursor(1, 8)
  print(stat(7))
end

function solo:render_score()
  color(colors.white)

  cursor(board.offset_x * 2 + board.width, board.offset_y)
  print(player.steps .. " steps")

  -- skip 2 lines and draw score
  cursor(board.offset_x * 2 + board.width, board.offset_y + 2 * character_height)
  print("score " .. player.score .. (player.score == 0 and "" or "00"))
end

return solo
