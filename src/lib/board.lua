---@diagnostic disable: global-in-nil-env, lowercase-global, unbalanced-assignments

require("lib/block")
require("lib/cursor")
require("lib/garbage_block")
require("lib/particle")
require("lib/pending_garbage_blocks")

local reduction_rules = require("lib/reduction_rules")

board_class = new_class()

function board_class._init(_ENV, _cursor, __offset_x, _cols)
  cursor = _cursor or cursor_class()
  _offset_x = __offset_x
  show_wires = true
  show_top_line = true
  init(_ENV, _cols)
end

function board_class.init(_ENV, _cols)
  -- サイズ関係
  cols, rows = _cols or 6, 17

  -- 画面上のサイズと位置
  width, height, offset_x, offset_y, raised_dots =
  cols * tile_size, (rows - 1) * tile_size, _offset_x or 11, 0, 0

  -- board の状態
  state, win, lose, timeup, top_block_y, _changed, show_gameover_menu =
  "play", false, false, false, 0, false, false

  -- 各種キャッシュ
  _reduce_cache, _is_block_fallable_cache = {}, {}

  -- ブロックが hover 状態かどうかをチェックするためのフラグを格納
  _check_hover_flag = {}

  -- ゲームオーバーの線
  top_line_start_x = 0

  _chain_count, _topped_out_frame_count, _topped_out_delay_frame_count, _bounce_speed,
      _bounce_screen_dy =
  {}, 0, 600, 0, 0

  pending_garbage_blocks = create_pending_garbage_blocks()

  -- 各種ブロックの取得
  blocks, reducible_blocks, _garbage_blocks, contains_garbage_match_block = {}, {}, {}, false

  tick, steps = 0, 0

  for y = 0, rows do
    blocks[y], reducible_blocks[y], _check_hover_flag[y] = {}, {}, {}
    for x = 1, cols do
      put(_ENV, x, y, block_class("i"))
    end
  end

  cursor:init()
end

function board_class.block_at(_ENV, x, y)
  return blocks[y][x]
end

function board_class.put_random_blocks(_ENV)
  for y = 0, 8 do
    for x = 1, cols do
      -- y = 0 (次のブロック) と、y = 1 .. 4 (下から 4 行) はブロックで埋める
      -- y >= 5 の行は確率的にブロックを置く
      if y < 5 or
          (rnd(1) > 0.2 and (not is_block_empty(_ENV, x, y - 1))) then
        repeat
          put(_ENV, x, y, _random_single_block(_ENV))
        until #reduce(_ENV, x, y, true).to == 0
      end
    end
  end
end

function board_class.reduce_blocks(_ENV, game, player, other_board)
  local chain_id_callbacked, combo_count = {}

  for y, row in pairs(blocks) do
    for x, _ in pairs(row) do
      local reduction = reduce(_ENV, x, y)

      -- コンボ (同時消し) とチェイン (連鎖) の処理
      if #reduction.to > 0 then
        --   local chain_id = reduction.chain_id

        --   if _chain_count[chain_id] == nil then
        --     _chain_count[chain_id] = 0
        --   end

        if combo_count and game.combo_callback then
          -- 同時消し
          combo_count = combo_count + #reduction.to
          game.combo_callback(combo_count, x, y, player, _ENV, other_board)
        else
          combo_count = #reduction.to
        end

        --   -- 同じフレームで同じ chain_id を持つ連鎖が発生した場合、
        --   -- 連鎖数をインクリメントしない
        --   if not chain_id_callbacked[chain_id] then
        --     _chain_count[chain_id] = _chain_count[chain_id] + 1
        --   end

        --   -- 連鎖
        --   if not chain_id_callbacked[chain_id] and _chain_count[chain_id] > 1 and game and game.chain_callback then
        --     if #pending_garbage_blocks.all > 1 then
        --       local offset_height_left = game.block_offset_callback(chain_id, _chain_count[chain_id], x, y, player, _ENV
        --         , other_board)

        --       -- 相殺しても残っていれば、相手に攻撃
        --       if offset_height_left > 0 then
        --         game.chain_callback(chain_id, _chain_count[chain_id], x, y, player, _ENV, other_board)
        --       end
        --     else
        --       game.chain_callback(chain_id, _chain_count[chain_id], x, y, player, _ENV, other_board)
        --     end
        --     chain_id_callbacked[chain_id] = true
        --   end

        for index, r in pairs(reduction.to) do
          local dx, dy, new_block = r.dx and reduction.dx or 0, r.dy or 0, block_class(r.block_type)

          if new_block.type == "swap" or new_block.type == "cnot_x" or new_block.type == "control" then
            new_block.other_x = x + (r.dx and 0 or reduction.dx)
          end

          -- printh("replace_with: x + dx, y + dy = " .. x + dx .. ", " .. y + dy)
          -- printh("new_block.type = " .. new_block.type)

          blocks[y + dy][x + dx]:replace_with(new_block, index, chain_id)

          -- ブロックが消える、または変化するとき、その上にあるブロックすべてに chain_id をセット
          -- for chainable_y = y + dy - 1, 1, -1 do
          --   local block_to_fall = blocks[x + dx][chainable_y]
          --   if block_to_fall.type ~= "i" then
          --     if block_to_fall:is_match() then
          --       goto next_reduction
          --     end
          --     block_to_fall.chain_id = chain_id
          --   end
          -- end

          ::next_reduction::
        end

        --   if player then
        --     game.reduce_callback(reduction.score, x, y, player, reduction.pattern, reduction.dx)
        --   end
      end
    end
  end

  -- -- おじゃまブロックのマッチ
  -- repeat
  --   local matched_garbage_block_count = 0

  --   for _, each in pairs(_garbage_blocks) do
  --     if each:is_idle() then
  --       local x, y, garbage_span, garbage_height = each.x, each.y, each.span, each.height
  --       local is_matching = function(adjacent_block)
  --         if not adjacent_block:is_match() then
  --           return false
  --         end

  --         if adjacent_block.type == "?" then
  --           if each.body_color == adjacent_block.body_color then
  --             each.chain_id = adjacent_block.chain_id
  --             return true
  --           end
  --         else
  --           each.chain_id = adjacent_block.chain_id
  --           return true
  --         end

  --         return false
  --       end

  --       -- あるおじゃまブロックの上下左右にマッチ中のブロック、
  --       -- または同じ色の ? ブロックがあれば、おじゃまブロックに chain_id をセットして
  --       -- ? ブロックに分解 & 一列ちぢめる。

  --       -- 下と上
  --       for gx = x, x + garbage_span - 1 do
  --         if (y < rows and is_matching(blocks[gx][y + 1])) or
  --             (y - garbage_height > 1 and is_matching(blocks[gx][y - garbage_height])) then
  --           matched_garbage_block_count = matched_garbage_block_count + 1
  --           goto matched
  --         end
  --       end

  --       -- 左と右
  --       for i = 0, garbage_height - 1 do
  --         if (x > 1 and y - i > 0 and is_matching(blocks[x - 1][y - i])) or
  --             (x + garbage_span <= cols and y - i > 0 and is_matching(blocks[x + garbage_span][y - i])) then
  --           matched_garbage_block_count = matched_garbage_block_count + 1
  --           goto matched
  --         end
  --       end

  --       goto next_garbage_block

  --       ::matched::
  --       for i = 0, garbage_span - 1 do
  --         for j = 0, garbage_height - 1 do
  --           garbage_match_block = block_class("?")
  --           garbage_match_block.body_color = each.body_color
  --           put(_ENV, x + i, y - j, garbage_match_block)

  --           local new_block
  --           if j == 0 then
  --             -- 一行目にはランダムなブロックを入れる
  --             new_block = _random_single_block(_ENV)
  --           elseif j == 1 and i == 0 then
  --             -- 二行目の先頭にはおじゃまブロック
  --             new_block = garbage_block(garbage_span, garbage_height - 1, each.body_color)
  --           else
  --             new_block = block_class("i")
  --           end

  --           blocks[x + i][y - j]:replace_with(
  --             new_block,
  --             i + j * garbage_span,
  --             j == 0 and each.chain_id or nil,
  --             garbage_span,
  --             garbage_height
  --           )
  --         end
  --       end
  --     end

  --     ::next_garbage_block::
  --   end
  -- until matched_garbage_block_count == 0
end

-- function board_class.reduce(_ENV, x, y, include_next_blocks)
--   if include_next_blocks then
--     return _reduce_nocache(_ENV, x, y, true)
--   else
--     return _memoize(_ENV, _reduce_nocache, _reduce_cache, x, y)
--   end
-- end

-- function board_class._reduce_nocache(_ENV, x, y, include_next_blocks)
function board_class.reduce(_ENV, x, y, include_next_blocks)
  local reduction, block = { to = {}, score = 0 }, blocks[y][x]
  local rules = reduction_rules[block.type]

  if not rules then return reduction end

  for _, rule in pairs(rules) do
    -- other_x と dx を決める
    local block_pattern_rows, other_x, dx = rule[1]

    if (include_next_blocks and y - #block_pattern_rows < -1) or
        (not include_next_blocks and y - #block_pattern_rows < 0) then
      return reduction
    end

    for i, block_types in pairs(block_pattern_rows) do
      if y - i + 1 < 0 then
        goto next_rule
      end

      -- other_x と dx を決める際に、パターンにマッチしないブロックがあれば
      -- 先にここではじいておく
      if block_types[1] ~= "?" then
        -- printh("x, y, i = " .. x .. ", " .. y .. ", " .. i)
        if reducible_block_at(_ENV, x, y - i + 1).type ~= block_types[1] then
          goto next_rule
        end
      end

      if block_types[2] then
        local current_block = reducible_block_at(_ENV, x, y - i + 1)

        if current_block.other_x then
          if current_block.type == block_types[1] then
            other_x = current_block.other_x
            dx = other_x - x
            goto check_match
          else
            goto next_rule
          end
        end
      end
    end

    ::check_match::
    -- chainable フラグがついたブロックがマッチしたブロックの中に 1 個でも含まれていたら連鎖
    local chain_id = x .. "," .. y

    -- マッチするかチェック
    for i, block_types in pairs(block_pattern_rows) do
      local current_y = y - i + 1

      if current_y < 0 then
        goto next_rule
      end

      if block_types[1] ~= "?" then
        local block1 = reducible_block_at(_ENV, x, current_y)
        if block1.type ~= block_types[1] or
            (block1.other_x and block1.other_x ~= other_x) then
          goto next_rule
        end

        if block1.chain_id then
          chain_id = block1.chain_id
        end
      end

      if block_types[2] then
        local block2 = reducible_block_at(_ENV, other_x, current_y)
        if block2.type ~= block_types[2] or
            (block2.other_x and block2.other_x ~= x) then
          goto next_rule
        end

        if block2.chain_id then
          chain_id = block2.chain_id
        end
      end
    end

    reduction = {
      to = rule[2],
      dx = dx,
      block_count = rule[3],
      score = rule[4] or 1,
      chain_id = chain_id,
      pattern = rule[5]
    }
    goto matched

    ::next_rule::
  end

  ::matched::
  return reduction
end

-- ボード上の X 座標を画面上の X 座標に変換
function board_class.screen_x(_ENV, x)
  return offset_x + (x - 1) * 8
end

-- ボード上の Y 座標を画面上の Y 座標に変換
-- 一行目は表示しないことに注意
function board_class.screen_y(_ENV, y)
  return offset_y + 128 - y * 8 - raised_dots
  -- return offset_y + (rows - y) * 8 -- raised_dots + _bounce_screen_dy
  -- return offset_y + (y - 2) * 8 - raised_dots + _bounce_screen_dy
end

function board_class._random_single_block(_ENV)
  local single_block_types = split('h,x,y,z,s,t')
  local block_type = single_block_types[ceil_rnd(#single_block_types)]

  return block_class(block_type)
end

-------------------------------------------------------------------------------
-- board の状態
-------------------------------------------------------------------------------

function board_class.is_busy(_ENV)
  for x = 1, cols do
    for y = 1, rows do
      local block = blocks[y][x]
      if not (block:is_idle() or block:is_swapping()) then
        return true
      end
    end
  end

  return false
end

function board_class.is_game_over(_ENV)
  return state == "over"
end

-------------------------------------------------------------------------------
-- board の操作
-------------------------------------------------------------------------------

function board_class.reducible_block_at(_ENV, x, y)
  --#if assert
  assert(1 <= x and x <= cols, "x = " .. x)
  assert(0 <= y and y <= rows, "y = " .. y)
  --#endif

  return reducible_blocks[y][x] or block_class("i")
end

function board_class.put(_ENV, x, y, block)
  --#if assert
  assert(1 <= x and x <= cols, "x = " .. x)
  assert(0 <= y, "y = " .. y)
  assert(block ~= nil, "block is nil")
  --#endif

  block.x, block.y = x, y

  -- おじゃまブロックを分解する時 (= garbage_match ブロックと置き換える時)、
  -- おじゃまブロックキャッシュから消す
  if blocks[y][x] and blocks[y][x].type == "g" then
    del(_garbage_blocks, blocks[y][x])
  end

  -- 新たにおじゃまブロックを置く場合
  -- おじゃまブロックキャッシュに追加する
  if block.type == "g" then
    add(_garbage_blocks, block)
  end

  blocks[y][x] = block
  block:attach(_ENV)
  observable_update(_ENV, block)
  _check_hover_flag[y][x] = true
end

function board_class.remove_block(_ENV, x, y)
  put(_ENV, x, y, block_class("i"))
end

function board_class.send_garbage(_ENV, chain_id, span, _height)
  pending_garbage_blocks:add_garbage(span, _height, chain_id)
end

function board_class.insert_blocks_at_bottom(_ENV)
  shift_all_blocks_up(_ENV)

  -- local min_cnot_probability = 0.3
  -- local max_cnot_probability = 0.7
  local p = 0.3 + flr(steps / 5) * 0.1
  p = p > 0.7 and 0.7 or p

  if rnd(1) < p then
    local control_x, cnot_x_x

    repeat
      control_x, cnot_x_x = ceil_rnd(cols), ceil_rnd(cols)
    until control_x ~= cnot_x_x

    local control_block = block_class("control")
    control_block.other_x = cnot_x_x

    local cnot_x_block = block_class("cnot_x")
    cnot_x_block.other_x = control_x

    put(_ENV, control_x, 0, control_block)
    put(_ENV, cnot_x_x, 0, cnot_x_block)
  end

  -- 最下段の空いている部分に新しいブロックを置く
  for x = 1, cols do
    if is_block_empty(_ENV, x, 0) then
      repeat
        put(_ENV, x, 0, _random_single_block(_ENV))
      until #reduce(_ENV, x, 1, true).to == 0
    end
  end

  steps = steps + 1
end

function board_class.shift_all_blocks_up(_ENV)
  for y = #blocks, 0, -1 do
    for x = 1, cols do
      if not is_block_empty(_ENV, x, y) then
        put(_ENV, x, y + 1, blocks[y][x])
        remove_block(_ENV, x, y)
      end
    end
  end
end

-------------------------------------------------------------------------------
-- プレイヤーによるブロック操作
-------------------------------------------------------------------------------

-- (x_left, y) と (x_left + 1, y) のブロックを入れ替える
-- 入れ替えできる場合は true を、そうでない場合は false を返す
function board_class.swap(_ENV, x_left, y)
  local x_right = x_left + 1
  local left_block, right_block = blocks[y][x_left], blocks[y][x_right]
  -- local left_block, right_block = blocks[x_left][y], blocks[x_right][y]

  -- 入れ替えできない場合
  --  1. 左または右の状態が idle や falling でない
  --  2. 左または右が # ブロック
  --  3. 左または右がおじゃまブロックの一部
  --  4. CNOT または SWAP の一部と単一ブロックを入れ替えようとしている場合
  if not (left_block:is_swappable_state() and right_block:is_swappable_state()) or
      (left_block.type == "#" or right_block.type == "#") or
      (_is_part_of_garbage(_ENV, x_left, y) or _is_part_of_garbage(_ENV, x_right, y)) or
      (left_block.other_x and left_block.other_x < x_left and not is_block_empty(_ENV, x_right, y)) or
      (not is_block_empty(_ENV, x_left, y) and right_block.other_x and x_right < right_block.other_x) then
    return false
  end

  left_block:swap_with("right")
  right_block:swap_with("left")
  return true
end

-------------------------------------------------------------------------------
-- update, render
-------------------------------------------------------------------------------

function board_class.update(_ENV, game, player, other_board)
  pending_garbage_blocks:update(_ENV)
  _update_bounce(_ENV)
  top_line_start_x = (top_line_start_x + 4) % 96

  if state == "play" then
    if win or lose then
      state, tick_over = "over", 0
      sfx(17)
    elseif timeup then
      state, tick_over = "over", 0
    else
      _update_game(_ENV, game, player, other_board)
    end
  elseif state == "over" then
    if lose then
      if tick_over == 20 and not done_over_fx then
        sfx(18)
      end

      for x = 1, cols do
        for y = 0, #blocks do
          if tick_over == 0 then
            blocks[y][x]._state = "over"
          elseif tick_over == 20 and not done_over_fx then
            blocks[y][x] = block_class("i")
            particle:create_chunk(screen_x(_ENV, x), screen_y(_ENV, y),
              "5,5,9,7,random,random,-0.03,-0.03,40|5,5,9,7,random,random,-0.03,-0.03,40|4,4,9,7,random,random,-0.03,-0.03,40|4,4,2,5,random,random,-0.03,-0.03,40|4,4,6,7,random,random,-0.03,-0.03,40|2,2,9,7,random,random,-0.03,-0.03,40|2,2,9,7,random,random,-0.03,-0.03,40|2,2,6,5,random,random,-0.03,-0.03,40|2,2,6,5,random,random,-0.03,-0.03,40|0,0,2,5,random,random,-0.03,-0.03,40")
          end
        end
      end
    end

    tick_over = tick_over + 1

    if tick_over > 20 then
      done_over_fx = true
    end
  end

  tick = tick + 1
end

function board_class.render(_ENV)
  -- ワイヤの描画
  -- show_wires == true の場合のみ、ワイヤを描画する
  if show_wires then
    for x = 1, cols do
      local line_x = screen_x(_ENV, x) + 3
      line(
        line_x, offset_y,
        line_x, offset_y + height,
        5
      )
    end
  end

  -- ブロックの描画
  for y = 0, rows do
    for x = 1, cols do
      local block, scr_x, scr_y = blocks[y][x], screen_x(_ENV, x), screen_y(_ENV, y)

      -- CNOT や SWAP の接続を描画
      -- TODO: block 側で描画する。
      if block.other_x and x < block.other_x then
        local connection_y = scr_y + 3
        line(
          scr_x + 3,
          connection_y,
          screen_x(_ENV, block.other_x) + 3,
          connection_y,
          block:is_match() and 13 or (lose and 5 or 10)
        )
      end

      block:render(scr_x, scr_y)

      -- 一番下のマスクを描画
      if y == 0 and not is_game_over(_ENV) then
        spr(97, scr_x, scr_y)
      end
    end
  end

  -- -- 残り時間ゲージの描画
  -- if is_topped_out(_ENV) then
  --   local time_left_height = (_topped_out_delay_frame_count - _topped_out_frame_count) /
  --       _topped_out_delay_frame_count * 128
  --   local gauge_x = offset_x < 64 and offset_x + 50 or offset_x - 4

  --   if time_left_height > 0 then
  --     rectfill(gauge_x, 128 - time_left_height, gauge_x + 1, 127, 8)
  --   end

  --   for y = 1, row_next_blocks do
  --     for x = 1, cols do
  --       local block = blocks[x][y]
  --       if time_left_height < 128 / 3 then
  --         block.pinch = true
  --         block.tick_pinch = tick
  --       else
  --         block.pinch = false
  --       end
  --     end
  --   end
  -- end

  -- ゲームオーバーの線
  if show_top_line and not is_game_over(_ENV) then
    if top_line_start_x < 73 then
      line(max(offset_x - 1, offset_x + top_line_start_x - 25), 40,
        min(offset_x + 48, offset_x + top_line_start_x + 5), 40,
        is_topped_out(_ENV) and 8 or 1)
    end

    -- if offset_x - 1 + (top_line_start_x - 24) < offset_x + 48 then
    --   line(max(offset_x - 1, offset_x - 1 + top_line_start_x - 24), 40,
    --     min(offset_x + 48, offset_x - 1 + top_line_start_x - 24 + 30), 40,
    --     is_topped_out(_ENV) and 8 or 1)
    -- end
  end

  -- -- 待機中のおじゃまブロック
  -- pending_garbage_blocks:render(_ENV)

  -- カーソル
  if not is_game_over(_ENV) then
    cursor:render(screen_x(_ENV, cursor.x), screen_y(_ENV, cursor.y))
  end

  -- -- WIN! または LOSE を描画
  -- if is_game_over(_ENV) and (win or lose) and tick_over > 20 and #particle.all == 0 then
  --   sspr(
  --     win and 0 or 48,
  --     96,
  --     48,
  --     24,
  --     win and offset_x or offset_x + 3 * sin(tick % 60 / 60),
  --     win and offset_y + 40 + 3 * sin(tick % 60 / 60) or offset_y + 43
  --   )
  -- end

  -- if show_gameover_menu then
  --   draw_rounded_box(offset_x - 1, offset_y + 96, offset_x + 7, offset_y + 105, 0, 0)
  --   spr(99, offset_x, offset_y + 97)
  --   print_outlined("try again", offset_x + 11, offset_y + 98, 1, 7)

  --   draw_rounded_box(offset_x - 1, offset_y + 109, offset_x + 7, offset_y + 118, 0, 0)
  --   spr(112, offset_x, offset_y + 110)
  --   print_outlined("title", offset_x + 11, offset_y + 111, 1, 7)
  -- end
end

function board_class.is_topped_out(_ENV)
  return screen_y(_ENV, top_block_y) - _bounce_screen_dy <= 40
end

function board_class._update_game(_ENV, game, player, other_board)
  -- FIXME: swap のテストのために、一時的に無効
  --
  -- if is_topped_out(_ENV) then
  --   if not is_busy(_ENV) then
  --     _topped_out_frame_count = _topped_out_frame_count + 1

  --     if _topped_out_frame_count >= _topped_out_delay_frame_count then
  --       lose = true
  --     end
  --   end
  -- else
  --   _topped_out_frame_count = 0
  -- end

  if _changed then
    reduce_blocks(_ENV, game, player, other_board)
    _changed = false
  end

  -- 落下と更新処理をすべてのブロックに対して行う。
  -- あわせて top_block_y も更新
  --
  -- swap などのペアとなるブロックを正しく落とすために、
  -- 一番下の行から上に向かって順に処理
  top_block_y = 0
  contains_garbage_match_block = false

  for y = 1, rows do
    for x = 1, cols do
      local block = blocks[y][x]

      block:update()

      if block.type ~= "i" then
        if block.type == "?" then
          contains_garbage_match_block = true
        end

        -- 落下できるブロックをホバー状態にする
        if not block:is_falling() and
            not block:is_hover() and
            is_block_fallable(_ENV, x, y) then
          if not block.other_x then -- 単体ブロックとおじゃまゲート
            block:hover()
            if y > 1 and blocks[y - 1][x]:is_hover() then
              block.timer = blocks[y - 1][x].timer
            end
          else -- CNOT または SWAP
            if x < block.other_x and is_block_fallable(_ENV, block.other_x, y) then
              block:hover()
              blocks[y][block.other_x]:hover(block.timer + 1)
            end
          end
        end

        -- ホバー中のブロックに乗ったブロックをホバー状態にする
        if _check_hover_flag[y][x] then
          _check_hover_flag[y][x] = false

          if not block:is_hover() then
            local hover_timer = propagatable_hover_timer(_ENV, x, y)
            if hover_timer then
              if not block.other_x then
                -- 単体ブロックとおじゃまゲート
                block:hover(hover_timer)
              elseif x < block.other_x then
                -- CNOT または SWAP
                block:hover(hover_timer)
                blocks[y][block.other_x]:hover(hover_timer + 1)
              end
            end
          end
        end

        -- top_block_y を更新
        if block.type == "g" then
          if not block.first_drop and top_block_y > y - block.height + 1 then
            top_block_y = y - block.height + 1
          end
        elseif top_block_y < y then
          top_block_y = y
        end

        if block:is_idle() and block.chain_id and blocks[y + 1][x].chain_id == nil then
          block.chain_id = nil
        end

        if block:is_falling() then
          if not is_block_fallable(_ENV, x, y) then
            if block.type == "g" then
              bounce(_ENV)
              sfx(9)
              block.first_drop = false
            else
              sfx(12)
            end

            block._tick_landed = 1
            block:change_state("idle")

            if block.other_x and x < block.other_x then
              local other_block = blocks[y][block.other_x]
              other_block._tick_landed = 1
              other_block:change_state("idle")
            end
          else
            if is_block_empty(_ENV, x, y - 1) then
              -- 落下中のブロックをひとつ下に移動
              if not block.other_x then
                remove_block(_ENV, x, y)
                put(_ENV, x, y - 1, block)
              elseif x < block.other_x then
                remove_block(_ENV, x, y)
                put(_ENV, x, y - 1, block)

                local other_block = blocks[y][block.other_x]
                other_block._state = "falling"
                remove_block(_ENV, block.other_x, y)
                put(_ENV, block.other_x, y - 1, other_block)
              end
            end
          end
        end
      end
    end
  end

  for chain_id, _ in pairs(_chain_count) do
    -- 連鎖可能フラグ (chain_id) の立ったブロックが 1 つもなかった場合、
    -- _chain_count をリセット
    for x = 1, cols do
      for y = 1, rows do
        if blocks[x][y].chain_id == chain_id then
          goto next_chain_id
        end
      end
    end
    _chain_count[chain_id] = nil

    ::next_chain_id::
  end
end

-------------------------------------------------------------------------------
-- おじゃまユニタリが接地したときの bounce エフェクト
-------------------------------------------------------------------------------

-- bounce エフェクトを開始
function board_class.bounce(_ENV)
  _bounce_screen_dy, _bounce_speed = 0, -4
end

function board_class._update_bounce(_ENV)
  if _bounce_speed ~= 0 then
    _bounce_speed = _bounce_speed + 0.9
    _bounce_screen_dy = _bounce_screen_dy + _bounce_speed

    if _bounce_screen_dy > 0 then
      _bounce_screen_dy, _bounce_speed = 0, -_bounce_speed
    end
  end
end

-------------------------------------------------------------------------------
-- ブロックの種類判定
-------------------------------------------------------------------------------

-- x, y が空かどうかを返す
-- おじゃまユニタリと SWAP, CNOT ブロックも考慮する
function board_class.is_block_empty(_ENV, x, y)
  --#if assert
  assert(0 < x and x <= cols, "x = " .. x)
  assert(0 <= y and y <= rows, "y = " .. y)
  --#endif

  return blocks[y][x]:is_empty() and
      not (_is_part_of_garbage(_ENV, x, y) or
          _is_part_of_cnot(_ENV, x, y) or
          _is_part_of_swap(_ENV, x, y))
end

-- x, y がおじゃまブロックの一部であるかどうかを返す
function board_class._is_part_of_garbage(_ENV, x, y)
  return _garbage_head_block(_ENV, x, y) ~= nil
end

function board_class._block_or_its_head_block(_ENV, x, y)
  return _garbage_head_block(_ENV, x, y) or
      _cnot_head_block(_ENV, x, y) or
      _swap_head_block(_ENV, x, y) or
      blocks[y][x]
end

-- x, y がおじゃまブロックの一部であった場合、
-- おじゃまブロック先頭のブロックを返す
-- 一部でない場合は nil を返す
function board_class._garbage_head_block(_ENV, x, y)
  for _, each in pairs(_garbage_blocks) do
    local garbage_x, garbage_y = each.x, each.y
    if garbage_x <= x and x <= garbage_x + each.span - 1 and -- 幅に x が含まれる
        y <= garbage_y and y >= garbage_y - each.height + 1 then -- 高さに y が含まれる
      return each
    end
  end

  return nil
end

-- x, y が CNOT の一部であるかどうかを返す
function board_class._is_part_of_cnot(_ENV, x, y)
  return _cnot_head_block(_ENV, x, y) ~= nil
end

-- x, y が CNOT の一部であった場合、
-- CNOT 左端のブロック (control または cnot_x) を返す
-- 一部でない場合は nil を返す
function board_class._cnot_head_block(_ENV, x, y)
  for tmp_x = 1, x - 1 do
    local block = blocks[y][tmp_x]

    if (block.type == "cnot_x" or block.type == "control") and x < block.other_x then
      return block
    end
  end

  local block = blocks[y][x]
  return (block.type == "cnot_x" or block.type == "control") and block or nil
end

-- x, y が SWAP ペアの一部であるかどうかを返す
function board_class._is_part_of_swap(_ENV, x, y)
  return _swap_head_block(_ENV, x, y) ~= nil
end

-- x, y が SWAP ペアの一部であった場合、
-- SWAP ペア左端のブロックを返す
-- 一部でない場合は nil を返す
function board_class._swap_head_block(_ENV, x, y)
  for tmp_x = 1, x - 1 do
    local block = blocks[y][tmp_x]

    if block.type == "swap" and x < block.other_x then
      return block
    end
  end

  local block = blocks[y][x]
  return block.type == "swap" and block or nil
end

-------------------------------------------------------------------------------
-- ブロックの状態
-------------------------------------------------------------------------------

-- ブロック x, y の直下のブロックでホバー状態にあるもののうち、
-- timer の最大値を取得する。
-- 直下のブロックが一つもなかった場合は nil を返す。
--
-- x, y で指定するブロックは X などの単一ブロックだけでなく、
-- CNOT, SWAP, おじゃまゲートもある。
-- このため、直下のブロックは複数の場合もある。
function board_class.propagatable_hover_timer(_ENV, x, y)
  local block = blocks[y][x]
  local hover_timer = 0

  -- y が最下段、または next block の場合、
  -- またはブロックが落下可能でない状態の場合、
  -- nil を返す
  if y < 2 or not block:is_fallable() then
    return nil
  end

  for_all_nonempty_blocks_below(_ENV, x, y, function(each)
    if each:is_hover() and hover_timer < each.timer then
      hover_timer = each.timer
    end
  end)

  return hover_timer > 0 and hover_timer or nil
end

-- ブロック x, y が x, y - 1 に落とせるかどうかを返す
function board_class.is_block_fallable(_ENV, x, y)
  return _memoize(_ENV, _is_block_fallable_nocache, _is_block_fallable_cache, x, y)
end

function board_class._is_block_fallable_nocache(_ENV, x, y)
  local block = blocks[y][x]
  local fallable = true

  if y < 2 or not block:is_fallable() then
    return false
  end

  for_all_nonempty_blocks_below(_ENV, x, y, function(each)
    if not each:is_falling() then
      fallable = false
    end
  end)

  return fallable
end

-- x, y で指定するブロックの下にあるすべてのブロックに対して、f を適用する
function board_class.for_all_nonempty_blocks_below(_ENV, x, y, f)
  local block = blocks[y][x]

  -- ブロックの幅 (x 座標の start と end) を得る
  local start_x, end_x = x, x + block.span - 1
  if block.other_x then
    start_x, end_x = min(x, block.other_x), max(x, block.other_x)
  end

  for i = start_x, end_x do
    if is_block_empty(_ENV, i, y - 1) then
      goto next_block
    end

    f(_block_or_its_head_block(_ENV, i, y - 1))

    ::next_block::
  end
end

-- ボード内にあるいずれかのブロックが更新された場合に呼ばれる。
-- _changed フラグを立て各種キャッシュも更新・クリアする。
function board_class.observable_update(_ENV, block, old_state)
  local x, y = block.x, block.y

  if old_state == "swapping_with_right" and block:is_idle() then
    local new_x = x + 1
    local right_block = blocks[y][new_x]

    --#if assert
    assert(right_block:_is_swapping_with_left(), right_block._state)
    --#endif

    if right_block.type ~= "i" then
      particle:create_chunk(screen_x(_ENV, x) - 2, screen_y(_ENV, y) + 3,
        "1,1,10,10,-1,-0.8,0.05,0.05,3|1,1,10,10,-1,0,0.05,0,5|1,1,10,10,-1,0.8,0.05,-0.05,3")
    end
    if block.type ~= "i" then
      particle:create_chunk(screen_x(_ENV, new_x) + 10, screen_y(_ENV, y) + 3,
        "1,1,10,10,1,-0.8,-0.05,0.05,3|1,1,10,10,1,0,-0.05,0,5|1,1,10,10,1,0.8,-0.05,-0.05,3")
    end

    local right_block_other_x = right_block.other_x

    if block.other_x then
      blocks[y][block.other_x].other_x = new_x
    end

    if right_block_other_x then
      blocks[y][right_block_other_x].other_x = x
    end

    put(_ENV, new_x, y, block)
    put(_ENV, x, y, right_block)

    right_block:change_state("idle")

    return
  end

  -- hover が完了して下のブロックが空または falling の場合、
  -- パネルの状態を ":falling" にする
  if old_state == "hover" and is_block_fallable(_ENV, x, y) then
    block:fall()
  end

  if old_state == "match" and block:is_idle() then
    sfx(11, -1, (block._match_index % 6 - 1) * 4, 4)
    put(_ENV, x, y, block.new_block)
    particle:create_chunk(screen_x(_ENV, x) + 3, screen_y(_ENV, y) + 3,
      "2,1,7,7,-1,-1,0.05,0.05,16|2,1,7,7,1,-1,-0.05,0.05,16|2,1,7,7,-1,1,0.05,-0.05,16|2,1,7,7,1,1,-0.05,-0.05,16")
    return
  end

  if block:is_hover() then
    for each_y = y + 1, #blocks do
      for each_x = 1, cols do
        _check_hover_flag[each_y][each_x] = true
      end
    end
  end

  if block:is_reducible() then
    reducible_blocks[y][x] = block
  else
    reducible_blocks[y][x] = nil
  end

  _changed = true

  -- if block:is_reducible() then
  --   _reduce_cache = {}
  -- end

  if not (block:is_swapping() or block:is_match()) then
    for i = y, #blocks do
      _is_block_fallable_cache[i] = {}
    end
  end
end

-------------------------------------------------------------------------------
-- memoization
-------------------------------------------------------------------------------

-- 引数 x, y を取る関数 func をメモ化した関数を返す
function board_class._memoize(_ENV, f, cache, x, y)
  if cache[y] == nil then
    cache[y] = {}
  end

  local result = cache[y][x]

  if result == nil then
    result = f(_ENV, x, y)
    cache[y][x] = result
  end

  return result
end

-------------------------------------------------------------------------------
-- debug
-------------------------------------------------------------------------------

--#if debug
function board_class._tostring(_ENV)
  local str = ''

  for y = rows, 1, -1 do
    for x = 1, cols do
      local block = blocks[y][x]

      if block.type == "i" then
        if _is_part_of_garbage(_ENV, x, y) then
          str = str .. "g " .. " "
        else
          str = str .. blocks[y][x]:_tostring() .. " "
        end
      else
        str = str .. blocks[y][x]:_tostring() .. " "
      end
    end
    str = str .. "\n"
  end

  return str
end

--#endif
