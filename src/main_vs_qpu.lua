require("lib/helpers")

require("lib/board")
require("lib/cursor")
require("lib/game")
require("lib/player")
require("lib/qpu")

local game, board, qpu_board =
game_class(), board_class(cursor_class(), 3), board_class(cursor_class(), 78)

board.block_offset_target, qpu_board.block_offset_target = { 27, 9 }, { 102, 9 }
board.attack_ion_target, qpu_board.attack_ion_target = { 102, 9 }, { 27, 9 }

game:add_player(player_class(), board, qpu_board)
game:add_player(create_qpu(qpu_board, stat(6)), qpu_board, board)

function _init()
  game:init()
end

function _update60()
  game:update()

  if game:is_game_over() and t() - game.game_over_time > 2 then
    board.show_gameover_menu = true
    if btnp(5) then -- x でリプレイ
      _init()
    elseif btnp(4) then -- c でタイトルへ戻る
      jump('quantattack_title')
    end
  end
end

function _draw()
  cls()

  game:render()

  print_outlined(unpack_split("time,57,106,7,0"))
  print_outlined(game:elapsed_time_string(), unpack_split("55,114,7,0"))
end
