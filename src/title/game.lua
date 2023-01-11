---@diagnostic disable: global-in-nil-env, lowercase-global

require("lib/attack_ion")
require("lib/bubble")
require("lib/particle")

title_logo_bounce_speed, title_logo_bounce_screen_dy = 0, 0

-- タイトルロゴを跳ねさせる
local function bounce_title_logo()
  title_logo_bounce_screen_dy, title_logo_bounce_speed = 0, -5
end

function update_title_logo_bounce()
  if title_logo_bounce_speed ~= 0 then
    title_logo_bounce_speed = title_logo_bounce_speed + 0.9
    title_logo_bounce_screen_dy = title_logo_bounce_screen_dy + title_logo_bounce_speed

    if title_logo_bounce_screen_dy > 0 then
      title_logo_bounce_screen_dy, title_logo_bounce_speed = 0, -title_logo_bounce_speed
    end
  end
end

local attack_cube_callback = function(target_x, target_y)
  bounce_title_logo()
  sfx(19)
  particle:create_chunk(target_x, target_y,
    "5,5,9,7,random,random,-0.03,-0.03,20|5,5,9,7,random,random,-0.03,-0.03,20|4,4,9,7,random,random,-0.03,-0.03,20|4,4,2,5,random,random,-0.03,-0.03,20|4,4,6,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|0,0,2,5,random,random,-0.03,-0.03,20")
end

function game()
  return setmetatable({
    reduce_callback = function(_score, _x, _y, _player)
      -- NOP
    end,

    combo_callback = function(_combo_count, x, y, _player, board, _other_board)
      attack_ion:create(
        board:screen_x(x),
        board:screen_y(y),
        attack_cube_callback,
        12,
        64,
        36
      )
    end,

    block_offset_callback = function(_chain_id, chain_count, _x, _y, _player, _board, _other_board)
      return chain_count
    end,

    chain_callback = function(_chain_id, _chain_count, x, y, _player, board, _other_board)
      attack_ion:create(
        board:screen_x(x),
        board:screen_y(y),
        attack_cube_callback,
        12,
        64,
        36
      )
    end,

    init = function(_ENV)
      all_players_info = {}
    end,

    add_player = function(_ENV, player, board)
      add(all_players_info, {
        player = player,
        board = board,
        tick = 0
      })
    end,

    update = function(_ENV)
      for _, each in pairs(all_players_info) do
        local player, board, cursor = each.player, each.board, each.board.cursor

        player:update(board)

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
        if player.o then
          _raise(_ENV, each)
        end

        board:update(_ENV, player)
        cursor:update()
      end

      particle:update_all()
      bubble:update_all()
      attack_ion:update_all()
    end,

    render = function(_ENV)
      for _, each in pairs(all_players_info) do
        each.board:render()
      end

      particle:render_all()
      bubble:render_all()
      attack_ion:render_all()
    end,

    -- ブロックをせりあげる
    _raise = function(_ENV, player_info)
      local board = player_info.board

      board.raised_dots = board.raised_dots + 1

      if board.raised_dots == 8 then
        board.raised_dots = 0
        board:insert_blocks_at_bottom()
        board.cursor:move_up(board.rows)
      end
    end
  }, { __index = _ENV })
end
