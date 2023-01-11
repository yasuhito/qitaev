require("lib/helpers")
require("lib/attack_ion")
require("lib/ripple")
require("lib/particle")
require("lib/bubble")

local game = new_class()

local all_players_info, countdown

function game.reduce_callback(score, _x, _y, player)
  player.score = player.score + score
end

function game.combo_callback(combo_count, x, y, player, board, other_board)
  local attack_cube_callback = function(target_x, target_y)
    sfx(21)
    particle:create_chunk(target_x, target_y,
      "5,5,9,7,random,random,-0.03,-0.03,20|5,5,9,7,random,random,-0.03,-0.03,20|4,4,9,7,random,random,-0.03,-0.03,20|4,4,2,5,random,random,-0.03,-0.03,20|4,4,6,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|0,0,2,5,random,random,-0.03,-0.03,20")

    player.score = player.score + combo_count

    -- 対戦相手がいる時、おじゃまブロックを送る
    if other_board then
      other_board:send_garbage(nil, combo_count > 6 and 6 or combo_count - 1, 1)
    end
  end

  bubble:create("combo", combo_count, board:screen_x(x), board:screen_y(y))
  attack_ion:create(
    board:screen_x(x),
    board:screen_y(y),
    attack_cube_callback,
    12,
    unpack(board.attack_ion_target)
  )
end

local chain_bonus = { 0, 5, 8, 15, 30, 40, 50, 70, 90, 110, 130, 150, 180 }

function game.block_offset_callback(chain_id, chain_count, x, y, player, board, other_board)
  local offset_height = chain_count

  if offset_height > 2 then
    local attack_cube_callback = function(target_x, target_y)
      sfx(21)
      particle:create_chunk(target_x, target_y,
        "5,5,9,7,random,random,-0.03,-0.03,20|5,5,9,7,random,random,-0.03,-0.03,20|4,4,9,7,random,random,-0.03,-0.03,20|4,4,2,5,random,random,-0.03,-0.03,20|4,4,6,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|0,0,2,5,random,random,-0.03,-0.03,20")

      player.score = player.score + (chain_bonus[chain_count] or 180)

      if other_board then
        offset_height = board.pending_garbage_blocks:offset(offset_height)
      end
    end

    attack_ion:create(
      board:screen_x(x),
      board:screen_y(y),
      attack_cube_callback,
      9,
      unpack(board.block_offset_target)
    )
  end

  return offset_height
end

function game.chain_callback(chain_id, chain_count, x, y, player, board, other_board)
  if chain_count > 2 then
    local attack_cube_callback = function(target_x, target_y)
      sfx(21)
      particle:create_chunk(target_x, target_y,
        "5,5,9,7,random,random,-0.03,-0.03,20|5,5,9,7,random,random,-0.03,-0.03,20|4,4,9,7,random,random,-0.03,-0.03,20|4,4,2,5,random,random,-0.03,-0.03,20|4,4,6,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,9,7,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|2,2,6,5,random,random,-0.03,-0.03,20|0,0,2,5,random,random,-0.03,-0.03,20")

      player.score = player.score + (chain_bonus[chain_count] or 180)

      -- 対戦相手がいる時、おじゃまブロックを送る
      if other_board then
        other_board:send_garbage(chain_id, 6, chain_count - 1 < 6 and chain_count - 1 or 5)
      end
    end

    bubble:create("chain", chain_count, board:screen_x(x), board:screen_y(y))
    attack_ion:create(
      board:screen_x(x),
      board:screen_y(y),
      attack_cube_callback,
      12,
      unpack(board.attack_ion_target)
    )
  else
    player.score = player.score + (chain_bonus[chain_count])
  end
end

function game:is_game_over()
  return self.game_over_time ~= nil
end

function game:_init()
  self.auto_raise_frame_count = 10
end

function game:init()
  attack_ion.slow = false
  particle.slow = false

  all_players_info = {}
  countdown = 240
  self.start_time = t()
  self.game_over_time = nil
  self.time_left = nil
end

function game:add_player(player, board, other_board)
  add(all_players_info, {
    player = player,
    board = board,
    other_board = other_board,
    tick = 0
  })
end

function game:update()
  ripple:update()

  if countdown then
    countdown = countdown - 1
    local countdown_number = flr(countdown / 60 + 1)

    if countdown > 0 then
      self.start_time = t()

      if countdown_number < 4 then
        for _, each in pairs(all_players_info) do
          each.board.countdown = countdown_number
        end
      end

      if countdown % 60 == 0 then
        sfx(13)
      end
    elseif countdown == 0 then
      countdown = nil

      for _, each in pairs(all_players_info) do
        each.board.countdown = nil
      end

      sfx(14)
    end
  end

  -- もしどちらかの board でおじゃまブロックを分解中だった場合 "slow" にする
  ripple.slow = false

  for index, each in pairs(all_players_info) do
    local player = each.player
    local board = each.board
    local cursor = board.cursor
    local other_board = each.other_board

    if self:is_game_over() then
      board:update()
      ripple.slow = false
    else
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
      if player.x and not countdown and board:swap(cursor.x, cursor.y) then
        sfx(10)
      end
      if player.o and not countdown and board.top_block_y > 2 then
        self:_raise(each)
      end

      board:update(self, player, other_board)
      cursor:update()

      if not countdown then
        self:_auto_raise(each)
      end

      if board.contains_garbage_match_block then
        ripple.slow = true
      end
    end
  end

  particle:update_all()
  bubble:update_all()
  attack_ion:update_all()

  if self:is_game_over() then
    particle.slow = true
  else
    -- ゲーム中だけ time_left を更新
    game.time_left = 120 - (t() - self.start_time)

    if all_players_info[1].board:is_game_over() then
      self.game_over_time = t()
    end
  end
end

function game:render() -- override
  ripple:render()

  for _, each in pairs(all_players_info) do
    local board = each.board

    board:render()

    -- カウントダウンの数字はカーソルの上に表示
    if board.countdown then
      local countdown_sprite_x = { 32, 16, 0 }
      sspr(countdown_sprite_x[board.countdown], 80,
        16, 16,
        board.offset_x + 16, board.offset_y + 43)
    end
  end

  particle:render_all()
  bubble:render_all()
  attack_ion:render_all()
end

-- ブロックをせりあげる
function game:_raise(player_info)
  local board = player_info.board

  board.raised_dots = board.raised_dots + 1

  if board.raised_dots == 8 then
    board.raised_dots = 0
    board:insert_blocks_at_bottom()
    board.cursor:move_up(board.rows)
  end
end

-- 可能な場合ブロックを自動的にせりあげる
function game:_auto_raise(player_info)
  if player_info.board:is_busy() then
    return
  end

  player_info.tick = player_info.tick + 1

  if player_info.tick > self.auto_raise_frame_count then
    self:_raise(player_info)
    player_info.tick = 0
  end
end

-- 残り時間を文字列で返す (e.g., "01:23")
function game:time_left_string()
  return length2_number_string_0filled(flr(self.time_left / 60)) ..
      ":" ..
      length2_number_string_0filled(ceil(self.time_left) % 60)
end

function length2_number_string_0filled(num)
  return (num < 10) and "0" .. num or num
end

return game
