require("engine/core/class")

local garbage_gate = require("garbage_gate")
local i_gate = require("i_gate")
local h_gate = require("h_gate")
local x_gate = require("x_gate")
local y_gate = require("y_gate")
local z_gate = require("z_gate")
local s_gate = require("s_gate")
local t_gate = require("t_gate")
local control_gate = require("control_gate")
local cnot_x_gate = require("cnot_x_gate")
local swap_gate = require("swap_gate")
local quantum_gate = require("quantum_gate")

local board = new_class()

board.cols = 6 -- board の列数
board.rows = 12 -- board の行数
board.row_next_gates = board.rows + 1

function board:_init()
  self.raised_dots = 0
  self._gates = {}
  self._offset_x = 10
  self._offset_y = 10

  -- fill the board with I gates
  for x = 1, board.cols do
    self._gates[x] = {}
    for y = 1, board.row_next_gates do
      self:put(x, y, i_gate())
    end
  end
end

function board:initialize_with_random_gates()
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

  -- ランダムに swap を 1 つ置く
  local swap_x
  local swap_other_x
  local swap_y
  repeat
    swap_x = flr(rnd(board.cols)) + 1
    swap_other_x = flr(rnd(board.cols)) + 1
    swap_y = flr(rnd(board.rows)) + 1
  until not self:is_empty(swap_x, swap_y + 1) and swap_other_x ~= swap_x

  self:put(swap_x, swap_y, swap_gate(swap_other_x))
  self:put(swap_other_x, swap_y, swap_gate(swap_x))

  if swap_x < swap_other_x then
    for x = swap_x + 1, swap_other_x - 1 do
      self:put(x, swap_y, i_gate())
    end
  else
    for x = swap_other_x + 1, swap_x - 1 do
      self:put(x, swap_y, i_gate())
    end
  end
end

function board:_random_single_gate()
  local single_gate_types = { h_gate, x_gate, y_gate, z_gate, s_gate, t_gate }
  local gate_type = single_gate_types[flr(rnd(#single_gate_types)) + 1]

  return gate_type()
end

function board:update()
  self:reduce_gates()
  self:drop_gates()
  self:_update_gates()
end

function board:reduce_gates()
  for x = 1, board.cols do
    for y = 1, board.rows do
      if not self:gate_at(x, y):is_reducible() then
        goto next
      end

      local reduction = self:reduce(x, y, self.raised_dots > 0)

      for _index, r in pairs(reduction.to) do
        local dx = r.dx or 0
        local dy = r.dy or 0
        local gate = r.gate or i_gate()

        self:gate_at(x + dx, y + dy):replace_with(gate)
      end

      ::next::
    end
  end
end

function board:drop_gates()
  local max_y = self.raised_dots > 0 and board.rows or board.rows - 1

  for x = 1, board.cols do
    for y = max_y, 1, -1 do
      local gate = self:gate_at(x, y)

      if gate:is_droppable(x, y) and self:is_gate_droppable(x, y) then
        gate:drop(x, y)

        -- SWAP ゲートの場合、もう一方のゲートも下に落とす
        if gate:is_swap() then
          self:gate_at(gate.other_x, y):drop(gate.other_x, y)
        end
      end
    end
  end
end

-- 指定したゲートが行 y に落とせるかどうかを返す。
-- y を省略した場合、すぐ下の行 y + 1 に落とせるかどうかを返す。
function board:is_gate_droppable(gate_x, gate_y, y)
  --#if assert
  assert(1 <= gate_x)
  assert(gate_x <= board.cols)
  assert(1 <= gate_y)
  assert(gate_y <= board.row_next_gates)
  --#endif

  if gate_y == board.row_next_gates then
    return false
  end

  local gate, start_x, end_x = self:gate_at(gate_x, gate_y)

  if gate.other_x then
    -- SWAP ゲートと CNOT ゲートの場合、
    -- 2 つのゲートの下だけでなく、ゲート間の下がすべて空いている必要がある
    --
    -- (droppable な場合)
    --   C---X
    --  H
    --
    -- (droppable でない場合)
    --   C---X
    --    H
    start_x, end_x = min(gate_x, gate.other_x), max(gate_x, gate.other_x)
  else
    -- それ以外の場合、ゲートの下だけをチェックする。
    -- ただし Garbage ゲートのように幅 (span) が 2 以上の場合があるので、
    -- span を考慮してチェックする
    --
    -- (droppable な場合)
    --   X
    --  H
    --
    -- (droppable でない場合)
    --    X
    --    H
    --
    -- (Garbage ゲートが droppable な場合)
    --   GGGGG
    --  H
    --
    -- (Garbage ゲートが droppable でない場合)
    --   GGGGG
    --    H
    --
    start_x, end_x = gate_x, gate_x + gate.span - 1
  end

  for tmp_x = start_x, end_x do
    if not self:is_empty(tmp_x, y or gate_y + 1) then
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
      self:gate_at(x, y):update(self, x, y)
    end
  end
end

function board:render()
  -- draw idle gates
  for x = 1, board.cols do
    for y = 1, board.row_next_gates do
      local gate = self:gate_at(x, y)
      local screen_x = self:screen_x(x)
      local screen_y = self:screen_y(y) + self:dy()

      if gate:is_swap() and x < gate.other_x then
        local connection_y = self:screen_y(y) + 3
        line(self:screen_x(x) + 3, connection_y,
          self:screen_x(gate.other_x) + 3, connection_y,
          colors.yellow)
      end

      gate:render(screen_x, screen_y)
    end
  end

  local width = board.cols * quantum_gate.size
  local height = board.rows * quantum_gate.size

  -- border left
  line(self._offset_x - 2, self._offset_y,
    self._offset_x - 2, self._offset_y + height,
    colors.white)
  -- border right
  line(self._offset_x + width, self._offset_y,
    self._offset_x + width, self._offset_y + height,
    colors.white)
  -- border bottom
  line(self._offset_x - 1, self._offset_y + height,
    self._offset_x + width - 1, self._offset_y + height,
    colors.white)
end

function board:swap(x_left, x_right, y)
  --#if assert
  assert(x_left < x_right)
  assert(x_right <= board.cols)
  assert(y <= board.rows)
  --#endif

  local left_gate = self:gate_at(x_left, y)
  local right_gate = self:gate_at(x_right, y)

  if not (left_gate:is_idle() and right_gate:is_idle()) then
    return false
  end

  -- 回路が [X-X] のようになっている場合 (X は SWAP ゲートを表す)、
  -- 実際には入れ替えしないが true を返す
  if left_gate:is_swap() and right_gate:is_swap() then
    if left_gate.other_x == x_right then
      --#if assert
      assert(right_gate.other_x == x_left)
      --#endif
      return true
    else
      return false
    end
  end

  -- 回路が X--[XH] のようになっている場合
  -- [XH] は入れ替えできない。
  if left_gate:is_swap() and not right_gate:is_i() then
    --#if assert
    assert(left_gate.other_x < x_left)
    --#endif
    return false
  end
  -- 回路が [HX]--X のようになっている場合も、
  -- [HX] は入れ替えできない。
  if right_gate:is_swap() and not left_gate:is_i() then
    --#if assert
    assert(x_right < right_gate.other_x)
    --#endif
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
  return self._offset_x + (x - 1) * quantum_gate.size
end

function board:screen_y(y)
  return self._offset_y + (y - 1) * quantum_gate.size - self.raised_dots
end

function board:y(screen_y)
  return ceil((screen_y - self._offset_y) / quantum_gate.size + 1)
end

function board:gate_at(x, y)
  --#if assert
  assert(x >= 1, x)
  assert(x <= board.cols, x)
  assert(y >= 1, "y = " .. y .. " >= 1")
  assert(y <= board.row_next_gates, "y = " .. y .. " > board.row_next_gates")
  --#endif

  local gate = self._gates[x][y]

  --#if assert
  assert(gate)
  --#endif

  return gate
end

-- x, y が空かどうかを返す
-- garbage と swap ゲートも考慮する
function board:is_empty(x, y)
  if y > board.row_next_gates then
    return false
  end

  for tmp_x = 1, x - 1 do
    local gate = self:gate_at(tmp_x, y)

    if gate:is_garbage() and x <= tmp_x + gate.span - 1 then
      return false
    end
    if gate:is_swap() and x <= gate.other_x then
      return false
    end
  end

  return self:gate_at(x, y):is_empty()
end

function board:reducible_gate_at(x, y)
  local gate = self:gate_at(x, y)

  if gate:is_reducible() then
    return gate
  end
  return i_gate()
end

function board:put(x, y, gate)
  --#if assert
  assert(x >= 1, x)
  assert(x <= board.cols, x)
  assert(y >= 1, "y = " .. y .. " >= 1")
  assert(y <= board.row_next_gates, "y = " .. y .. " > board.row_next_gates")
  --#endif

  self._gates[x][y] = gate
end

function board:remove_gate(x, y)
  self:put(x, y, i_gate())
end

function board:put_garbage()
  local span = flr(rnd(4)) + 3
  local x = flr(rnd(board.cols - span + 1)) + 1

  self:put(x, 1, garbage_gate(x, span))
end

function board:gates_to_puff()
  local gates = {}

  for x = 1, board.cols do
    for y = 1, board.rows do
      local gate = self:gate_at(x, y)

      if gate.puff then
        gate.x = x
        gate.y = y
        add(gates, gate)
      end
    end
  end

  return gates
end

-------------------------------------------------------------------------------
-- gate reduction
-------------------------------------------------------------------------------

function board:reduce(x, y, include_next_gates)
  local default = { to = {} }

  include_next_gates = include_next_gates or false
  local y1 = y + 1
  local y2 = y + 2
  local y3 = y + 3

  if include_next_gates then
    if y1 > board.row_next_gates then
      return default
    end
  else
    if y1 > board.rows then
      return default
    end
  end

  local gate = self:reducible_gate_at(x, y)
  local other_gate = i_gate()
  local gate_y1 = self:reducible_gate_at(x, y1)
  local gate_y1_other_gate = i_gate()

  if gate.other_x then
    other_gate = self:reducible_gate_at(gate.other_x, y)
  end
  if gate_y1.other_x then
    gate_y1_other_gate = self:reducible_gate_at(gate_y1.other_x, y1)
  end

  if gate_y1:is_i() then
    return default
  end

  --  H          I
  --  H  ----->  I
  if gate:is_h() and
      gate_y1:is_h() then
    return {
      to = { {},
        { dy = 1 } },
    }
  end

  if gate:is_x() then
    if gate_y1:is_x() then
      --  X          I
      --  X  ----->  I
      return {
        to = { {},
          { dy = 1 } },
      }
    end
    if gate_y1:is_z() then
      --  X          I
      --  Z  ----->  Y
      return {
        score = 200,
        to = { {},
          { dy = 1, gate = y_gate() } },
      }
    end
  end

  --  Y          I
  --  Y  ----->  I
  if gate:is_y() and
      gate_y1:is_y() then
    return {
      to = { {},
        { dy = 1 } },
    }
  end

  if gate:is_z() then
    if gate_y1:is_z() then
      --  Z          I
      --  Z  ----->  I
      return {
        to = { {},
          { dy = 1 } },
      }
    elseif gate_y1:is_x() then
      --  Z          I
      --  X  ----->  Y
      return {
        score = 200,
        to = { {},
          { dy = 1, gate = y_gate() } },
      }
    end
  end

  --  S          I
  --  S  ----->  Z
  if gate:is_s() and
      gate_y1:is_s() then
    return {
      to = { {},
        { dy = 1, gate = z_gate() } },
    }
  end

  --  T          I
  --  T  ----->  S
  if gate:is_t() and
      gate_y1:is_t() then
    return {
      to = { {},
        { dy = 1, gate = s_gate() } },
    }
  end

  --  C-X          I I
  --  C-X  ----->  I I
  if gate.other_x == gate_y1.other_x and
      gate:is_control() and other_gate:is_cnot_x() and
      gate_y1:is_control() and gate_y1_other_gate:is_cnot_x() then
    local dx = gate.other_x - x
    return {
      score = 200,
      to = { {}, { dx = dx },
        { dy = 1 }, { dx = dx, dy = 1 } },
    }
  end

  --  S-S          I I
  --  S-S  ----->  I I
  if gate:is_swap() and other_gate:is_swap() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate.other_x == gate_y1.other_x then
    local dx = gate.other_x - x
    return {
      score = 3000,
      to = { {}, { dx = dx },
        { dy = 1 }, { dx = dx, dy = 1 } },
    }
  end

  if include_next_gates then
    if y2 > board.row_next_gates then
      return default
    end
  else
    if y2 > board.rows then
      return default
    end
  end

  local gate_y2 = self:reducible_gate_at(x, y2)
  local gate_y2_other_gate = i_gate()
  if gate_y2.other_x then
    gate_y2_other_gate = self:reducible_gate_at(gate_y2.other_x, y2)
  end

  --  H          I
  --  X          I
  --  H  ----->  Z
  if gate:is_h() and
      gate_y1:is_x() and
      gate_y2:is_h() then
    return {
      score = 400,
      to = { {},
        { dy = 1 },
        { dy = 2, gate = z_gate() } },
    }
  end

  --  H          I
  --  Z          I
  --  H  ----->  X
  if gate:is_h() and
      gate_y1:is_z() and
      gate_y2:is_h() then
    return {
      score = 400,
      to = { {},
        { dy = 1 },
        { dy = 2, gate = x_gate() } },
    }
  end

  --  S          I
  --  Z          I
  --  S  ----->  Z
  if gate:is_s() and
      gate_y1:is_z() and
      gate_y2:is_s() then
    return {
      score = 400,
      to = { {},
        { dy = 1 },
        { dy = 2, gate = z_gate() } },
    }
  end

  --  C-X             I I
  --  X-C             I I
  --  C-X  ----->  SWAP-SWAP
  if gate:is_control() and other_gate:is_cnot_x() and
      gate_y1:is_cnot_x() and gate_y1_other_gate:is_control() and
      gate_y2:is_control() and gate_y2_other_gate:is_cnot_x() and
      gate.other_x == gate_y1.other_x and
      gate.other_x == gate_y2.other_x then
    local dx = gate.other_x - x
    return {
      score = 800,
      to = { {}, { dx = dx },
        { dy = 1 }, { dx = dx, dy = 1 },
        { dy = 2, gate = swap_gate(x + dx) }, { dx = dx, dy = 2, gate = swap_gate(x) } },
    }
  end

  -- H H          I I
  -- C-X  ----->  X-C
  -- H H          I I
  if gate:is_h() and gate_y1:is_control() and self:reducible_gate_at(gate_y1.other_x, y):is_h() and
      gate_y1_other_gate:is_cnot_x() and
      gate_y2:is_h() and self:reducible_gate_at(gate_y1.other_x, y2):is_h() then
    local dx = gate_y1.other_x - x
    return {
      score = 800,
      to = { {}, { dx = dx },
        { dy = 1, gate = cnot_x_gate(x + dx) }, { dx = dx, dy = 1, gate = control_gate(x) },
        { dy = 2 }, { dx = dx, dy = 2 } },
    }
  end

  -- X X          I I
  -- C-X  ----->  C-X
  -- X            I
  if gate:is_x() and gate_y1:is_control() and self:reducible_gate_at(gate_y1.other_x, y):is_x() and
      gate_y1_other_gate:is_cnot_x() and
      gate_y2:is_x() then
    return {
      score = 800,
      to = { {}, { dx = gate_y1.other_x - x }, { dy = 2 } },
    }
  end

  -- Z Z          I I
  -- C-X  ----->  C-X
  --   Z            I
  if gate:is_z() and gate_y1:is_control() and self:reducible_gate_at(gate_y1.other_x, y):is_z() and
      gate_y1_other_gate:is_cnot_x() and
      self:reducible_gate_at(gate_y1.other_x, y2):is_z() then
    local dx = gate_y1.other_x - x
    return {
      score = 800,
      to = { {}, { dx = dx }, { dx = dx, dy = 2 } },
    }
  end

  -- X            I
  -- X-C  ----->  X-C
  -- X            I
  if gate:is_x() and
      gate_y1:is_cnot_x() and gate_y1_other_gate:is_control() and
      gate_y2:is_x() then
    return {
      score = 800,
      to = { {}, { dy = 2 } },
    }
  end

  -- Z            I
  -- C-X  ----->  C-X
  -- Z            I
  if gate:is_z() and
      gate_y1:is_control() and gate_y1_other_gate:is_cnot_x() and
      gate_y2:is_z() then
    return {
      score = 800,
      to = { {}, { dy = 2 } },
    }
  end

  -- Z            I
  -- H X          H I
  -- X-C  ----->  X-C
  -- H X          H I
  local x2 = gate_y2.other_x
  if y <= 9 and
      gate:is_z() and
      gate_y1:is_h() and gate_y2:is_cnot_x() and self:reducible_gate_at(x2, y1):is_x() and
      self:reducible_gate_at(x2, y2):is_control() and
      self:reducible_gate_at(x, y3):is_h() and self:reducible_gate_at(x2, y3):is_x() then
    local dx = gate_y2.other_x - x
    return {
      score = 800,
      to = { {},
        { dx = dx, dy = 1 },
        { dx = dx, dy = 3 } }
    }
  end

  --
  -- SWAP gate rules
  --
  local gate_y2_other_gate_under_swap = i_gate()
  if gate_y1:is_swap() then
    gate_y2_other_gate_under_swap = self:reducible_gate_at(gate_y1.other_x, y2)
  end

  --  H            I
  --  S-S  ----->  S-S
  --    H            I
  if gate:is_h() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate_y2_other_gate_under_swap:is_h() then
    return {
      score = 1000,
      to = { {}, { dx = gate_y1.other_x - x, dy = 2 } }
    }
  end

  --  X            I
  --  S-S  ----->  S-S
  --    X            I
  if gate:is_x() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate_y2_other_gate_under_swap:is_x() then
    return {
      score = 1000,
      to = { {}, { dx = gate_y1.other_x - x, dy = 2 } }
    }
  end

  --  Y            I
  --  S-S  ----->  S-S
  --    Y            I
  if gate:is_y() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate_y2_other_gate_under_swap:is_y() then
    return {
      score = 1000,
      to = { {}, { dx = gate_y1.other_x - x, dy = 2 } }
    }
  end

  --  Z            I
  --  S-S  ----->  S-S
  --    Z            I
  if gate:is_z() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate_y2_other_gate_under_swap:is_z() then
    return {
      score = 1000,
      to = { {}, { dx = gate_y1.other_x - x, dy = 2 } }
    }
  end

  --  S            Z
  --  S-S  ----->  S-S
  --    S            I
  if gate:is_s() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate_y2_other_gate_under_swap:is_s() then
    return {
      score = 1200,
      to = { { gate = z_gate() }, { dx = gate_y1.other_x - x, dy = 2 } }
    }
  end

  --  T            S
  --  S-S  ----->  S-S
  --    T            I
  if gate:is_t() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate_y2_other_gate_under_swap:is_t() then
    return {
      score = 1200,
      to = { { gate = s_gate() }, { dx = gate_y1.other_x - x, dy = 2 } }
    }
  end

  --  C-X          I I
  --  S-S  ----->  S-S
  --  X-C          I I
  if gate:is_control() and other_gate:is_cnot_x() and
      gate_y1:is_swap() and gate_y1_other_gate:is_swap() and
      gate_y2:is_cnot_x() and gate_y2_other_gate:is_control() and
      gate.other_x == gate_y1.other_x and gate.other_x == gate_y2.other_x then
    local dx = gate.other_x - x
    return {
      score = 2000,
      to = { {}, { dx = dx },
        { dy = 2 }, { dx = dx, dy = 2 } }
    }
  end

  return default
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
