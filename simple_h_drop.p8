pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- animation study for dropping gates etc.

-- x: the initial x position of the cursor
-- y: the initial y position of the cursor
-- cursor_color: the color of the cursor
player = {x = 1, y = 1, cursor_color = 10}

-- all gates that can be placed on the board
gates = {"h", "x", "y", "z", "s", "t"}

gates_dropping = {}

gate = {
  create = function(self, type, x, y)
    return {
      type = type,
      x = x,
      y = y,
      drop_dy = nil,
      drop_y = nil,
      drop_callback = nil,

      drop = function(self, n_gates, callback)
        assert(n_gates > 0)

        printh("gate:drop(" .. n_gates .. ")")

        local dy = n_gates * 8

        self.drop_y = self.y + dy
        self.drop_callback = callback
      end,

      -- todo: animate() は board.table にハ✽しっている gate にしかハなかヘく😐されないのネ▒せ、
      -- アニメネ⬇️もションをする gate フ⬆️そのハさ웃ヒˇぬをノやうるハよ✽ヘす▒あり。
      animate = function(self)
        if (self.drop_y == nil) then return end

        self:_animate_drop()
      end,

      _animate_drop = function(self)
        if (self.drop_dy == nil) then
          self.drop_dy = game.drop_dy
        end

        if (self.y + self.drop_dy < self.drop_y) then
          self.y += self.drop_dy
          self.drop_dy += game.drop_ay
        elseif (self.y + self.drop_dy >= self.drop_y) then
          self.y = self.drop_y
          if (self.drop_callback) then
            self.drop_callback()
          end
          self.drop_callback = nil
          self.drop_y = nil
        end
      end,

      draw = function(self)
        local sprite_id = nil

        for index, type in pairs(gates) do
          if (type == self.type) then
            sprite_id = index - 1
          end
        end
        assert(sprite_id ~= nil)

        spr(sprite_id, self.x, self.y)
      end
    }
  end
}

-- animation to drop gate
gate_drop_animation = {
  create = function(self, x, y, dy)
    assert(x > 0 and x <= game.board.cols)
    assert(y > 0 and y <= game.board.rows)

    local gate = game.board:gate_at(x, y)
    assert(gate ~= nil)
    assert(dy ~= nil)

    if (dy == 0) then
      if (gates_dropping[x] == nil) gates_dropping[x] = {}
      gates_dropping[x][y] = false
      return
    end

    printh("dropping gate: " .. gate.type)

    local callback = function()
      -- todo: y ... y + dy - 1 は *すネ▒みて* nil にする
      for ty = y, y + dy do
        game.board:clear_gate(x, ty)
        game.board._reduce[x][ty] = nil
      end
      for ty = y, y + dy do
        game.board._reduce[x][ty] = nil
      end

      game.board:create_gate(gate.type, x, y + dy)

      del(game.animation_objects, gate)
      gates_dropping[x][y] = false

      printh("")
      printh("--- drop callback ---")
      printh("x: " .. x)
      printh("y: " .. y)
      printh("dy: " .. dy)
      game.board:print_table_view()
    end

    game.board:mark_reduce(x, y, "i")

    gate:drop(dy, callback)
    add(game.animation_objects, gate)

    printh("")
    printh("---  drop  ---")
    for _y = 1, game.board.rows do
      local line = ""
      for _x = 1, game.board.cols do
        local gate = game.board._table_view[_x][_y]
        if (gate) then
          if x == _x and y == _y then
            line = line .. " " .. gate.type .. dy
          else
            line = line .. " " .. gate.type .. " "
          end
        else
          line = line .. " _ "
        end
      end
      printh(line)
    end
  end
}

-- animation to reduce gates
--   - hh, xx, yy, zz -> i
--   - ss -> z
--   - tt -> s
--   - zx, xz -> y
--   - hxh -> z
--   - hzh -> x
--   - szs -> z
gate_reduce_animation = {
  -- create an animation to reduce multiple gates.
  --
  -- x: x-coordinate of the top gate to be reduced
  -- y: y-coordinate of the top gate to be reduced
  -- type: type of reduction
  create = function(self, type, x, y)
    assert(type == "hh" or
      type == "xx" or
      type == "yy" or
      type == "zz" or
      type == "ss" or
      type == "tt" or
      type == "zx" or
      type == "xz" or
      type == "hxh" or
      type == "hzh" or
      type == "szs")
    assert(x > 0 and x <= game.board.cols)
    assert(y > 0 and y <= game.board.rows)

    local gate = game.board:fetch(x, y)
    local dy = nil
    local reduce_to = nil

    if (type == "hh" or type == "xx" or type == "yy" or type == "zz") then
      dy = 1
      reduce_to = "i"
    end
    if (type == "ss") then
      dy = 1
      reduce_to = "z"
    end
    if (type == "tt") then
      dy = 1
      reduce_to = "s"
    end
    if (type == "zx" or type == "xz") then
      dy = 1
      reduce_to = "y"
    end
    if (type == "hxh") then
      dy = 2
      reduce_to = "z"
    end
    if (type == "hzh") then
      dy = 2
      reduce_to = "x"
    end
    if (type == "szs") then
      dy = 2
      reduce_to = "z"
    end
    assert(dy)
    assert(reduce_to)

    local callback = function()
      for ty = y, y + dy do
        game.board:clear_gate(x, ty)
        game.board._reduce[x][ty] = nil
      end

      if (reduce_to ~= "i") then
        game.board:create_gate(reduce_to, x, y + dy)
      end
      del(game.animation_objects, gate)

      printh("")
      printh("--- reduce animation callback ---")
      for y = 1, game.board.rows do
        local line = ""
        for x = 1, game.board.cols do
          local gate = game.board._table_view[x][y]
          if (gate) then
            line = line .. " " .. gate.type .. " "
          else
            line = line .. " _ "
          end
        end
        printh(line)
      end
    -- game.board:print_table_view()
    end

    if (dy == 1) then
      game.board:mark_reduce(x, y, "i")
      game.board:mark_reduce(x, y + 1, reduce_to)
      gate:drop(dy, callback)
      add(game.animation_objects, gate)
      return
    end

    if (dy == 2) then
      game.board:mark_reduce(x, y, "i")
      game.board:mark_reduce(x, y + 1, "i")
      game.board:mark_reduce(x, y + 2, reduce_to)
      gate:drop(dy, callback)
      add(game.animation_objects, gate)
      return
    end

    assert(false, "we should not reach here")
  end
}

board = {
  cols = 0,
  rows = 0,
  _gate_size = 8,
  _table_view = {},
  _table_reduced = {},
  _reduce = {},

  init = function(self, cols, rows)
    self.cols = cols
    self.rows = rows

    for x = 1, cols do
      self._table_view[x] = {}
      self._table_reduced[x] = {}
      self._reduce[x] = {}
    end
  end,

  gate_at = function(self, x, y)
    assert(x > 0 and x <= self.cols)
    assert(y > 0 and y <= self.rows)

    return self._table_view[x][y]
  end,

  fetch = function(self, x, y)
    local gate = self:gate_at(x, y)
    assert(gate)

    return gate
  end,

  mark_reduce = function(self, x, y, value)
    assert(x > 0 and x <= self.cols)
    assert(y > 0 and y <= self.rows)

    self._reduce[x][y] = value
  end,

  clear_gate = function(self, x, y)
    printh("board:clear_gate(" .. x .. ", " .. y .. ")")

    assert(x > 0 and x <= self.cols)
    assert(y > 0 and y <= self.rows)

    self._table_view[x][y] = nil
  -- self._reduce[x][y] = false
  end,

  -- create the specified gate and place it at x, y
  create_gate = function(self, gate_name, x, y)
    -- printh("board:create_gate(" .. gate_name .. ", " .. x .. ", " .. y .. ")")

    assert(x > 0 and x <= self.cols)
    assert(y > 0 and y <= self.rows)

    -- todo: 8 を _gate_size なネ▒たのハなあヒˇぬにする
    local gate = gate:create(gate_name, x * self._gate_size, y * self._gate_size)
    assert(gate ~= nil)

    self._table_view[x][y] = gate
    self._table_reduced[x][y] = gate
  end,

  -- place the gate at specified x, y
  assign_gate = function(self, x, y, gate)
    if (gate == nil) then
      self:clear_gate(x, y)
    else
      gate.x = x * self._gate_size
      gate.y = y * self._gate_size
      self._table_view[x][y] = gate
    end
  end,

  update_gate_positions = function(self)
    foreach(game.animation_objects, function(each)
        each:animate()
      end)
  end,

  draw_gates = function(self)
    for x = 1, self.cols do
      for y = 1, self.rows do
        spr(16, x * 8, y * 8)
      end
    end

    for x, col in pairs(self._table_view) do
      for y, gate in pairs(col) do
        if (self._reduce[x][y] == nil) then
          gate:draw()
        end
      end
    end

    foreach(game.animation_objects, function(each)
        each:draw()
      end)
  end,

  reduce_gates = function(self)
    local reduced = false

    for x=1, self.cols do
      for y=self.rows-1, 1, -1 do
        local gate = nil
        if (self._reduce[x][y] == nil) then
          gate = self._table_view[x][y]
        end

        if (gate and gate.type) then
          local reduceable = self:reduce(gate.type, x, y)
          if (reduceable ~= false) then
            reduced = true
            gate_reduce_animation:create(reduceable.reduction_type, x, y)
          end
        end
      end
    end

    if (reduced) then
      printh("")
      printh("--- reduce ---")
      for y = 1, self.rows do
        local line = ""
        for x = 1, self.cols do
          local gate = self._table_view[x][y]
          if (gate) then
            if self._reduce[x][y] then
              line = line .. "-" .. gate.type .. "-"
            else
              line = line .. " " .. gate.type .. " "
            end
          else
            line = line .. " _ "
          end
        end
        printh(line)
      end
    end
  end,

  drop_gates = function(self)
    for x = 1, self.cols do
      local num_drop = 0

      for y = self.rows, 1, -1 do
        local gate = nil

        if (gates_dropping[x] == nil or gates_dropping[x][y] ~= true) then
          if (self._reduce[x][y] ~= nil and self._reduce[x][y] ~= "i") then
            gate = self._reduce[x][y]
          end
          if (self._table_view[x][y] ~= nil) then
            gate = self._table_view[x][y]
          end

          if (gate == nil) then
            num_drop += 1
          elseif (num_drop > 0) then
            gate_drop_animation:create(x, y, num_drop)
            if (gates_dropping[x] == nil) gates_dropping[x] = {}
            gates_dropping[x][y] = true
          end
        end
      end
    end
  end,

  reduce = function(self, gate_type, x, y)
    local lower_gate = nil
    local lower_lower_gate = nil
    local reduction_type = nil

    if (self._table_view[x][y + 1] and self._reduce[x][y + 1] == nil) then
      lower_gate = self._table_view[x][y + 1]
    end
    if (y + 2 <= self.rows and self._table_view[x][y + 2] and self._reduce[x][y + 2] == nil) then
      lower_lower_gate = self._table_view[x][y + 2]
    end

    if (lower_gate == nil) then return false end

    if (gate_type == lower_gate.type) then
      if (gate_type == "h") then
        return {reduction_type = "hh", reduce_to = "i", num_reduced_gates = 1}
      end
      if (gate_type == "x") then
        return {reduction_type = "xx", reduce_to = "i", num_reduced_gates = 1}
      end
      if (gate_type == "y") then
        return {reduction_type = "yy", reduce_to = "i", num_reduced_gates = 1}
      end
      if (gate_type == "z") then
        return {reduction_type = "zz", reduce_to = "i", num_reduced_gates = 1}
      end
      if (gate_type == "s") then
        return {reduction_type = "ss", reduce_to = "z", num_reduced_gates = 1}
      end
      if (gate_type == "t") then
        return {reduction_type = "tt", reduce_to = "s", num_reduced_gates = 1}
      end

      assert(false, "should not reach here")
    end

    if (gate_type == "z" and lower_gate.type == "x") then
      return {reduction_type = "zx", reduce_to = "y", num_reduced_gates = 1}
    end

    if (gate_type == "x" and lower_gate.type == "z") then
      return {reduction_type = "xz", reduce_to = "y", num_reduced_gates = 1}
    end

    if (lower_lower_gate) then
      if (gate_type == "h" and lower_gate.type == "x" and lower_lower_gate.type == "h") then
        return {reduction_type = "hxh", reduce_to = "z", num_reduced_gates = 2}
      end

      if (gate_type == "h" and lower_gate.type == "z" and lower_lower_gate.type == "h") then
        return {reduction_type = "hzh", reduce_to = "x", num_reduced_gates = 2}
      end

      if (gate_type == "s" and lower_gate.type == "z" and lower_lower_gate.type == "s") then
        return {reduction_type = "szs", reduce_to = "z", num_reduced_gates = 2}
      end
    end

    return false
  end,

  -- debug print the current table contents
  print_table_view = function(self)
    printh("table view")
    for y = 1, self.rows do
      local line = "   "
      for x = 1, self.cols do
        local gate = self._table_view[x][y]
        if (gate) then
          line = line .. " " .. gate.type .. " "
        else
          line = line .. " _ "
        end
      end
      printh(line)
    end

    printh("")
    for y = 1, self.rows do
      local line = ""
      for x = 1, self.cols do
        local gate = self._reduce[x][y]
        if (gate) then
          line = line .. "t"
        else
          line = line .. "f"
        end
      end
      printh(line)
    end
  end,

  print_table_reduced = function(self)
    printh("table (reducued)")
    for y = 1, self.rows do
      local line = "  "
      for x = 1, self.cols do
        local gate = self._table_reduced[x][y]
        if (gate) then
          line = line .. gate.type
        else
          line = line .. " "
        end
      end
      printh(line)
    end
  end
}

game = {
  board = board,
  board_cols = 5,
  board_rows = 5,
  -- board_cols = 10,
  -- board_rows = 10,
  drop_dy = 0.1,
  drop_ay = 0,
  -- drop_dy = 1,
  -- drop_ay = 0.5,

  -- all objects currently displaying animation
  animation_objects = {},

  init = function(self)
    self.board:init(self.board_cols, self.board_rows)

    -- fill board with random gates
    for x = 1, self.board.cols do
      for y = self.board.rows, 1, -1 do
        self.board:create_gate(self:_unreduceable_random_gate_name(x, y), x, y)
      end
    end

    printh("")
    printh("--- init ---")
    for y = 1, self.board.rows do
      local line = ""
      for x = 1, self.board.cols do
        local gate = self.board._table_view[x][y]
        if (gate) then
          line = line .. " " .. gate.type .. " "
        else
          line = line .. " _ "
        end
      end
      printh(line)
    end
  end,

  _unreduceable_random_gate_name = function(self, x, y)
    local gate_name = nil

    repeat
      gate_name = gates[flr(rnd(#gates)) + 1]
    until (not self.board:reduce(gate_name, x, y))
    assert(gate_name)

    return gate_name
  end,

  handle_key_events = function(self)
    -- left
    if btnp(0) then
      if player.x >= 2 then
        player.x -= 1
      end
    end

    -- right
    if btnp(1) then
      if player.x <= self.board_cols - 2 then
        player.x += 1
      end
    end

    -- up
    if btnp(2) then
      if player.y > 1 then
        player.y -= 1
      end
    end

    -- down
    if btnp(3) then
      if player.y < self.board_rows then
        player.y += 1
      end
    end

    -- swap
    if (btnp(4)) then
      self:swap()
    end
  end,

  update = function(self)
    self.board:reduce_gates()
    self.board:drop_gates()
    self.board:update_gate_positions()
  end,

  swap = function(self)
    local left_gate = self.board:gate_at(player.x, player.y)
    local right_gate = self.board:gate_at(player.x + 1, player.y)

    self.board:assign_gate(player.x, player.y, right_gate)
    self.board:assign_gate(player.x + 1, player.y, left_gate)

    printh("")
    printh("--- swap ---")

    for y = 1, self.board.rows do
      local line = ""
      for x = 1, self.board.cols do
        local gate = self.board._table_view[x][y]
        if (gate) then
          if (x == player.x and y == player.y) then  -- left gate
            line = line .. "[" .. gate.type .. "]"
          elseif (x == player.x + 1 and y == player.y) then  -- right gate
            line = line .. "[" .. gate.type .. "]"
          else
            line = line .. " " .. gate.type .. " "
          end
        else
          line = line .. "   "
        end
      end
      printh(line)
    end
  end,

  draw = function(self)
    cls()
    self.board:draw_gates()
    self.draw_cursor()
  end,

  draw_cursor = function()
    local rect_x = player.x * 8 - 1
    local rect_y = player.y * 8 - 1
    rect(rect_x, rect_y, rect_x+16, rect_y+8, player.cursor_color)
  end
}

function _init()
  game:init()
end

function _update()
  game:handle_key_events()
  game:update()
end

function _draw()
  game:draw()
end
__gfx__
33333330003330003333333033333330444444402222222055555550000000000000000000000000000000000000000000000000000000000000000000000000
37333730033733003733373037777730447777402777772055000550000000000000000000000000000000000000000000000000000000000000000000000000
37333730333733303373733033337330474444402227222055505550000000000000000000000000000000000000000000000000000000000000000000000000
37777730377777303337333033373330447774402227222055505550000000000000000000000000000000000000000000000000000000000000000000000000
37333730333733303337333033733330444447402227222055505550000000000000000000000000000000000000000000000000000000000000000000000000
37333730033733003337333037777730477774402227222055000550000000000000000000000000000000000000000000000000000000000000000000000000
33333330003330003333333033333330444444402222222055555550000000000000000000000000000000000000000000000000000000000000000000000000
00050000000500000005000000050000000500000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

