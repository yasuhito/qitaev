require("lib/helpers")

local sash = require("lib/sash")

-- ハイスコア関係
local high_score_class = require("lib/high_score")
local high_score = high_score_class(0)
local current_high_score

local cursor_class = require("lib/cursor")
local cursor = cursor_class()

local board_class = require("lib/board")
local board = board_class(cursor)
board.attack_cube_target = { 85, 30 }

local player_class = require("lib/player")
local player = player_class()

local game_class = require("rush/game")
local game = game_class()

local gamestate = require("lib/gamestate")
local rush = derived_class(gamestate)

rush.type = ':rush'

local last_steps = -1

function _init()
  current_high_score = high_score:get()

  player:_init()
  board:init()
  board:put_random_blocks()
  cursor:init()

  game:init()
  game:add_player(player, cursor, board)
end

function _update60()
  game:update()

  if player.steps > last_steps then
    -- 5 ステップごとに
    --   * おじゃまゲートを降らせる
    --   * ゲートをせり上げるスピードを上げる
    if player.steps % 5 == 0 then
      if game.auto_raise_frame_count > 10 then
        game.auto_raise_frame_count = game.auto_raise_frame_count - 1
      end
      board:send_garbage(nil, 6, (player.steps + 5) / 5)
    end
    last_steps = player.steps
  end

  if game:is_game_over() then
    if t() - game.game_over_time > 2 then
      board.show_gameover_menu = true
      if btnp(5) then -- x でリプレイ
        _init()
      elseif btnp(4) then -- z でタイトルへ戻る
        jump('quantattack_title')
      end
    end
  else
    if game.time_left <= 0 then
      board.timeup = true
      game.game_over_time = t()
      sfx(16)
      sash:create("time up!", 13, 7, function()
        if high_score:put(player.score) then
          sfx(22)
          sash:create("high score!", 9, 8)
        end
      end)
    end
  end

  sash:update()
end

function _draw()
  cls()

  game:render()

  local base_x = board.offset_x * 2 + board.width

  -- スコア表示
  print_outlined("score " .. score_string(player.score), base_x, 16, 7, 0)
  print_outlined("hi-score " .. score_string(current_high_score), base_x, 24, 7, 0)

  -- 残り時間表示
  print_outlined("time left", base_x, 44, 7, 0)
  print_outlined(game:time_left_string(), base_x, 52, 7, 0)

  if not game:is_game_over() then
    spr(99, base_x, 109)
    print_outlined("swap blocks", 81, 110, 7, 0)
    spr(112, base_x, 119)
    print_outlined("raise blocks", 81, 120, 7, 0)
  end

  sash:render()
end