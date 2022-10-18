require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")

local gate_class = require("gate")
local reduction_rules = require("reduction_rules")
local chain_popup = require("chain_popup")

local board = new_class()

board.cols = 6 -- board の列数
board.rows = 12 -- board の行数
board.row_next_gates = board.rows + 1

function board:_init()
  self._gates = {}
  self.width = board.cols * tile_size
  self.height = board.rows * tile_size
  self.offset_x = 10
  self.offset_y = screen_height - self.height
  self.tick_chainable = 0
  self.chain_count = 0
  self:init()
end

function board:init()
  self.raised_dots = 0

  -- fill the board with I gates
  for x = 1, board.cols do
    self._gates[x] = {}
    for y = 1, board.row_next_gates do
      self:put(x, y, i_gate())
    end
  end
end

function board:initialize_with_random_gates()
  self:init()

  for y = board.row_next_gates, 6, -1 do
    for x = 1, board.cols do
      if y >= board.rows - 2 or
          (y < board.rows - 2 and rnd(1) > (y - 11) * -0.1 and (not self:is_empty(x, y + 1))) then
        repeat
          self:put(x, y, self:_random_single_gate())
        until #self:reduce(x, y, true).to == 0
      end
    end
  end
end

function board:_random_single_gate()
  local single_gate_types = { h_gate, x_gate, y_gate, z_gate, s_gate, t_gate }
  local gate_type = single_gate_types[flr(rnd(#single_gate_types)) + 1]

  return gate_type()
end

function board:is_busy()
  for x = 1, self.cols do
    for y = 1, self.row_next_gates do
      if not self._gates[x][y]:is_idle() then
        return true
      end
    end
  end

  return false
end

function board:insert_gates_at_bottom(steps)
  -- 各ゲートを 1 つ上にずらす
  for y = 1, self.row_next_gates - 1 do
    for x = 1, self.cols do
      self:put(x, y, self._gates[x][y + 1])
      self:remove_gate(x, y + 1)
    end
  end

  local min_cnot_probability = 0.3
  local max_cnot_probability = 0.7
  local p = min_cnot_probability + flr(steps / 5) * 0.1
  p = p > max_cnot_probability and max_cnot_probability or p

  if rnd(1) < p then
    local control_x
    local cnot_x_x
    repeat
      control_x = flr(rnd(board.cols)) + 1
      cnot_x_x = flr(rnd(board.cols)) + 1
    until control_x ~= cnot_x_x

    self:put(control_x, self.row_next_gates, control_gate(cnot_x_x))
    self:put(cnot_x_x, self.row_next_gates, cnot_x_gate(control_x))
  end

  -- 最下段の空いている部分に新しいゲートを置く
  for x = 1, self.cols do
    if self:is_empty(x, self.row_next_gates) then
      repeat
        self:put(x, self.row_next_gates, self:_random_single_gate())
      until #self:reduce(x, self.rows, true).to == 0
    end
  end
end

function board:update()
  local score = 0

  score = score + self:reduce_gates()
  self:drop_gates()
  self:_update_gates()

  if self.tick_chainable > 0 then
    self.tick_chainable = self.tick_chainable - 1
  end

  return score
end

function board:reduce_gates()
  local score = 0

  for y = 1, board.rows do
    for x = 1, board.cols do
      local reduction = self:reduce(x, y)
      score = score + (#reduction.to == 0 and 0 or reduction.score)

      -- チェイン (連鎖) の処理
      if #reduction.to > 0 then
        if self.tick_chainable == 0 then
          self.chain_count = 1
          self.tick_chainable = gate_class.match_animation_frame_count + reduction.gate_count * gate_class.match_delay_per_gate + 10
          self.last_tick_chain = self.tick_chainable

          -- すべてのブロックを dirty = false にする
          -- 連鎖中に一度でも入れ換えを行ったブロックは dirty になる
          -- dirty なブロックが消えた場合はチェインを継続しない
          for _x = 1, board.cols do
            for _y = 1, board.rows do
              self._gates[_x][_y].dirty = false
            end
          end
        else
          if not reduction.dirty and self.last_tick_chain ~= self.tick_chainable then -- 同時消しの場合は chain_count を増やさない
            local chainable_frames = gate_class.match_animation_frame_count + reduction.gate_count * gate_class.match_delay_per_gate + 10
            if self.tick_chainable < chainable_frames then
              self.tick_chainable = chainable_frames
            end
            self.last_tick_chain = self.tick_chainable

            self.chain_count = self.chain_count + 1

            if self.chain_count > 1 then
              chain_popup(self.chain_count, self:screen_x(x), self:screen_y(y))
            end
          end
        end
      end

      for index, r in pairs(reduction.to) do
        local dx = r.dx and reduction.dx or 0
        local dy = r.dy or 0
        local gate = gate_class(r.gate_type)

        if gate.type == "swap" or gate.type == "cnot_x" or gate.type == "control" then
          if r.dx then
            gate.other_x = x
          else
            gate.other_x = x + reduction.dx
          end
        end

        self._gates[x + dx][y + dy]:replace_with(gate, index)
      end
    end
  end

  -- おじゃまゲートのマッチ
  for y = board.rows, 1, -1 do
    for x = 1, board.cols do
      local gate = self._gates[x][y]
      local span = gate.span

      if gate:is_garbage() then
        local adjacent_gates = {}
        local match = false

        if x > 1 then
          add(adjacent_gates, self:gate_at(x - 1, y))
        end

        if x + span <= board.cols then
          add(adjacent_gates, self:gate_at(x + span, y))
        end

        for gx = x, x + span - 1 do
          if y > 1 then
            add(adjacent_gates, self:gate_at(gx, y - 1))
          end
          if y < board.rows then
            add(adjacent_gates, self:gate_at(gx, y + 1))
          end
        end

        for _, each in pairs(adjacent_gates) do
          if (each:is_match() and each.type ~= "!") then
            match = true
          end
        end

        if match then
          for dx = 0, span - 1 do
            self:put(x + dx, y, garbage_match_gate())
            self:gate_at(x + dx, y):replace_with(self:_random_single_gate(), dx, span)
          end
        end
      end
    end
  end

  return score
end

function board:drop_gates()
  for y = board.rows - 1, 1, -1 do
    for x = 1, board.cols do
      local gate = self._gates[x][y]

      if gate:is_droppable() and self:is_gate_droppable(x, y) then
        if gate.other_x then
          if x < gate.other_x and self:gate_at(gate.other_x, y):is_droppable() then
            gate:drop()
            self:gate_at(gate.other_x, y):drop()
          end
        else
          gate:drop()
        end
      end
    end
  end
end

-- 指定したゲートが行 y に落とせるかどうかを返す。
-- y を省略した場合、すぐ下の行 y + 1 に落とせるかどうかを返す。
function board:is_gate_droppable(gate_x, gate_y, y)
  --#if assert
  assert(1 <= gate_x and gate_x <= board.cols)
  assert(1 <= gate_y and gate_y <= board.row_next_gates)
  --#endif

  if gate_y == board.row_next_gates or y == board.row_next_gates then
    return false
  end

  local gate = self:gate_at(gate_x, gate_y)
  local start_x, end_x

  if gate.other_x then
    start_x, end_x = min(gate_x, gate.other_x), max(gate_x, gate.other_x)
  else
    start_x, end_x = gate_x, gate_x + gate.span - 1
  end

  for x = start_x, end_x do
    if not self:is_empty(x, y or gate_y + 1) then
      return false
    end
  end

  return true
end

function board:_update_gates()
  -- swap などのペアとなるゲートを正しく落とすために、
  -- 一番下の行から上に向かって順番に update していく
  for y = board.row_next_gates, 1, -1 do
    for x = 1, board.cols do
      self._gates[x][y]:update(self, x, y)
    end
  end
end

function board:render()
  -- 連鎖ゲージを描画
  local max_tick_chainable = gate_class.match_animation_frame_count + 6 * gate_class.match_delay_per_gate + 10
  local length = self.tick_chainable / max_tick_chainable
  local gauge_height = length * self.height
  rectfill(2, self.offset_y + (self.height - gauge_height),
    3, self.offset_y + self.height,
    colors.green)

  for x = 1, board.cols do
    -- draw wires
    local line_x = self:screen_x(x) + 3
    line(line_x, self.offset_y,
      line_x, self.offset_y + self.height,
      colors.dark_gray)
  end

  -- draw idle gates
  for x = 1, board.cols do
    for y = 1, board.row_next_gates do
      local gate = self._gates[x][y]
      local screen_x = self:screen_x(x)
      local screen_y = self:screen_y(y) + self:dy()

      if gate.other_x and x < gate.other_x then
        local connection_y = self:screen_y(y) + 3
        line(self:screen_x(x) + 3, connection_y,
          self:screen_x(gate.other_x) + 3, connection_y,
          colors.yellow)
      end

      gate:render(screen_x, screen_y)

      -- マスクを描画
      if y == board.row_next_gates then
        -- TODO: 102 を定数にする
        spr(102, screen_x, screen_y)
      end
    end
  end
end

-- (x_left, y) と (x_right, y) のゲートを入れ替える
-- 入れ替えできた場合は true を、そうでない場合は false を返す
--
-- TODO: 引数の x_right をなくして x_left + 1 を使う
function board:swap(x_left, x_right, y)
  --#if assert
  assert(x_right == x_left + 1)
  assert(1 <= x_left and x_left <= board.cols - 1)
  assert(2 <= x_right and x_right <= board.cols)
  assert(1 <= y and y <= board.rows)
  --#endif

  if self:is_garbage(x_left, y) or self:is_garbage(x_right, y) then
    return false
  end

  local left_gate = self:gate_at(x_left, y)
  local right_gate = self:gate_at(x_right, y)

  if not (left_gate:is_idle() and right_gate:is_idle()) then
    return false
  end

  -- 回路が A--[AB]--B のようになっている場合
  -- [AB] は入れ替えできない
  if left_gate.other_x and right_gate.other_x then
    if left_gate.other_x ~= x_right then
      return false
    end
  end

  -- 回路が A--[A?] のようになっている場合
  -- [A?] は入れ替えできない。
  if left_gate.other_x and left_gate.other_x < x_left and not right_gate:is_i() then
    return false
  end

  -- 回路が [?A]--A のようになっている場合も、
  -- [?A] は入れ替えできない。
  if not left_gate:is_i() and right_gate.other_x and x_right < right_gate.other_x then
    return false
  end

  left_gate:swap_with_right(x_right)
  right_gate:swap_with_left(x_left)

  return true
end

function board:dy()
  return 0
end

function board:screen_x(x)
  return self.offset_x + (x - 1) * tile_size
end

-- ボード上の Y 座標を画面上の Y 座標に変換
function board:screen_y(y)
  return self.offset_y + (y - 1) * tile_size - self.raised_dots
end

function board:y(screen_y)
  return ceil((screen_y - self.offset_y) / tile_size + 1)
end

function board:gate_at(x, y)
  --#if assert
  assert(1 <= x and x <= board.cols, "x = " .. x)
  assert(1 <= y and y <= board.row_next_gates, "y = " .. y)
  --#endif

  local gate = self._gates[x][y]

  --#if assert
  assert(gate)
  --#endif

  return gate
end

-- x, y が空かどうかを返す
-- おじゃまユニタリと SWAP, CNOT ゲートも考慮する
function board:is_empty(x, y)
  for tmp_x = 1, x - 1 do
    -- local gate = self._gates[tmp_x][y]
    local gate = self:gate_at(tmp_x, y)

    if gate:is_garbage() and (not gate:is_empty()) and x <= tmp_x + gate.span - 1 then
      return false
    end
    if gate.other_x and (not gate:is_empty()) and x < gate.other_x then
      return false
    end
  end

  return self._gates[x][y]:is_empty()
end

function board:is_garbage(x, y)
  for tmp_x = 1, x - 1 do
    local gate = self:gate_at(tmp_x, y)

    if gate:is_garbage() and x <= tmp_x + gate.span - 1 then
      return true
    end
  end

  return self:gate_at(x, y):is_garbage()
end

function board:reducible_gate_at(x, y)
  local gate = self._gates[x][y]

  return gate:is_reducible() and gate or i_gate()
end

function board:put(x, y, gate)
  --#if assert
  assert(1 <= x and x <= board.cols, x)
  assert(1 <= y and y <= board.row_next_gates, y)
  --#endif

  self._gates[x][y] = gate
end

function board:put_random_gate(x, y)
  repeat
    self:put(x, y, self:_random_single_gate())
  until #self:reduce(x, y, true).to == 0
end

function board:remove_gate(x, y)
  self:put(x, y, i_gate())
end

function board:drop_garbage()
  local span = flr(rnd(4)) + 3
  local x = flr(rnd(board.cols - span + 1)) + 1

  for i = x, x + span - 1 do
    if not self:is_empty(x, 1) then
      return
    end
  end

  local garbage = garbage_gate(span)
  self:put(x, 1, garbage)
  garbage:drop()
end

-------------------------------------------------------------------------------
-- gate reduction
-------------------------------------------------------------------------------

function board:reduce(x, y, include_next_gates)
  local reduction = { to = {}, score = 0 }
  local gate = self._gates[x][y]
  local dirty = false

  if not gate:is_reducible() then return reduction end

  local rules = reduction_rules[gate.type]
  if not rules then return reduction end

  for _, rule in pairs(rules) do
    -- other_x と dx を決める
    local gate_pattern_rows = rule[1]
    local other_x
    local dx

    if (include_next_gates and y + #gate_pattern_rows - 1 > self.row_next_gates) or
        (not include_next_gates and y + #gate_pattern_rows - 1 > self.rows) then
      goto next_rule
    end

    for i, gates in pairs(gate_pattern_rows) do
      if gates[2] then
        local current_gate = self:reducible_gate_at(x, y + i - 1)

        if current_gate.other_x then
          if current_gate.type == gates[1] then
            other_x = current_gate.other_x
            dx = other_x - x
            goto check_match
          else
            goto next_rule
          end
        end
      end
    end

    ::check_match::
    -- マッチするかチェック
    for i, gates in pairs(gate_pattern_rows) do
      local current_y = y + i - 1

      if gates[1] ~= "?" then
        if self:reducible_gate_at(x, current_y).type ~= gates[1] then
          goto next_rule
        else
          dirty = dirty or self:reducible_gate_at(x, current_y).dirty
        end
      end

      if gates[2] and other_x then
        if self:reducible_gate_at(other_x, current_y).type ~= gates[2] then
          goto next_rule
        else
          dirty = dirty or self:reducible_gate_at(other_x, current_y).dirty
        end
      end
    end

    reduction = { to = rule[2], dx = dx, gate_count = rule[3], score = rule[4] or 1, dirty = dirty }
    goto matched

    ::next_rule::
  end

  ::matched::
  return reduction
end

function board:is_game_over()
  if self.raised_dots ~= tile_size - 1 then
    return false
  end

  for x = 1, self.cols do
    if not self:is_empty(x, 1) then
      return true
    end
  end

  return false
end

-------------------------------------------------------------------------------
-- debug
-------------------------------------------------------------------------------

--#if debug
function board:_tostring()
  local str = ''

  for y = 1, board.row_next_gates do
    for x = 1, board.cols do
      str = str .. self:gate_at(x, y):_tostring() .. " "
    end
    str = str .. "\n"
  end

  return str
end

--#endif

return board
