---@diagnostic disable: global-in-nil-env, lowercase-global

require("lib/helpers")
require("lib/block")
require("lib/ripple")
require("lib/particle")
require("lib/bubble")

local game = new_class()
local _state

function game._init(_ENV)
  _state = ":initial"
  show_board = false
  move_cursor = false
end

function game.update(_ENV)
  if _state == ":initial" then
    -- NOP
  elseif _state == ":raise_stack" then
    board.raised_dots = board.raised_dots + 1

    if _rows_raised < 8 then
      if board.raised_dots == 8 then
        _rows_raised = _rows_raised + 1
        board.raised_dots = 0
        board:shift_all_blocks_up()

        for x = 1, board.cols do
          local block_type, other_x = unpack(split(_board_data[_rows_raised][x]))
          local new_block = block_class(block_type)
          new_block.other_x = other_x
          board:put(x, board.row_next_blocks, new_block)
        end

        cursor:move_up(board.rows)
      end
    else
      _state = ":idle"
      _raise_stack_callback()
    end
  else
    player:update(board)

    if move_cursor then
      if player.left then
        sfx(8)
        cursor:move_left()
      end
      if player.right then
        sfx(8)
        cursor:move_right(board.cols)
      end
      if player.up then
        sfx(8)
        cursor:move_up(board.rows)
      end
      if player.down then
        sfx(8)
        cursor:move_down()
      end
      if player.x and board:swap(cursor.x, cursor.y) then
        sfx(10)
      end
    end
  end

  -- すべてのモードに共通な update 処理
  board:update(_ENV, player)
  cursor:update()

  ripple:update()
  particle:update_all()
  bubble:update_all()
end

function game.render(_ENV)
  if _state ~= ":initial" then
    board:render()
  end
  particle:render_all()
  bubble:render_all()
end

function game.raise_stack(_ENV, board_data, callback)
  _state = ":raise_stack"
  _rows_raised = 0
  _board_data = board_data
  _raise_stack_callback = callback or function() end

  for x = 1, board.cols do
    for y = 1, board.row_next_blocks do
      board:put(x, y, block_class("i"))
    end
  end
end

return game
