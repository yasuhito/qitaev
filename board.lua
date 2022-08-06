board = {
  default_cols = 6,
  default_rows = 12,
  default_next_rows = 1,

  new = function(self, top, left)
    local b = {
      init = function(self, top, left)
        self.top = top or 0
        self.left = left or 0
        self.cols = board.default_cols
        self.rows = board.default_rows
        self.rows_plus_next_rows = self.rows + board.default_next_rows
        self._gate = {}
        self._raised_dots = 0

        for x = 1, self.cols do
          self._gate[x] = {}
          for y = self.rows_plus_next_rows, 1, -1 do
            self:put(x, y, quantum_gate:i())
          end
        end

        return self
      end,

      initialize_with_random_gates = function(self)
        for x = 1, self.cols do
          for y = self.rows_plus_next_rows, 1, -1 do
            if y >= self.rows - 2 or
               (y < self.rows - 2 and y >= 6 and rnd(1) > (y - 11) * -0.1 and (not self:gate_at(x, y + 1):is_i())) then
              repeat
                self:put(x, y, self:_random_gate())
              until (#gate_reduction_rules:reduce(self, x, y, true) == 0)
            else
              self:put(x, y, quantum_gate:i())
            end
          end
        end      
      end,

      gate_at = function(self, x, y)
        assert(x)
        assert(x and x >= 1 and x <= self.cols)
        assert(y and y >= 1 and y <= self.rows_plus_next_rows)

        local gate = self._gate[x][y]
        assert(gate)

        return gate
      end,

      reducible_gate_at = function(self, x, y)
        local gate = self:gate_at(x, y)

        if gate:is_reducible() then
          return gate
        end
        
        return quantum_gate:i()
      end,      

      put = function(self, x, y, gate)
        assert(x and x >= 1 and x <= self.cols)
        assert(y and y >= 1 and y <= self.rows_plus_next_rows)

        self._gate[x][y] = gate
      end,
      
      screen_x = function(self, board_x)
        return self.left + (board_x - 1) * quantum_gate.size
      end,

      screen_y = function(self, board_y)
        return self.top + (board_y - 1) * quantum_gate.size - self._raised_dots
      end,

      update = function(self)
        self:reduce()
        self:drop_gates()
        self:update_gates()
      end,

      draw = function(self)
        -- wires
        for i = 1, 6 do
          line(self.left + 3 + (i - 1) * quantum_gate.size, self.top - 1,
               self.left + 3 + (i - 1) * quantum_gate.size, self.top - 1 + self.rows * quantum_gate.size,
               colors.dark_grey)
        end

        -- gates
        for bx = 1, self.cols do
          for by = self.rows_plus_next_rows, 1, -1 do
            local x = self.left + (bx - 1) * quantum_gate.size
            local y = self.top + (by - 1) * quantum_gate.size
            local gate = self:gate_at(bx, by)

            if gate:is_swapping_with_left() then
              gate:draw(x + 4, y - self._raised_dots)
            elseif gate:is_swapping_with_right() then
              gate:draw(x - 4, y - self._raised_dots)
            else
              gate:draw(x, y - self._raised_dots)
            end
          end
        end

        -- draw cnot laser
        for bx = 1, self.cols do
          for by = self.rows_plus_next_rows, 1, -1 do
            local gate = self:gate_at(bx, by)

            if gate:is_control() then
              if gate.laser and gate.tick_laser and (gate.tick_laser % 4 == 0 or gate.tick_laser % 4 == 1) then
                local lx0 = self:screen_x(bx) + 3
                local ly0 = self:screen_y(by) + 3
                local lx1 = self:screen_x(gate.cnot_x_x) + 3
                local ly1 = ly0
                local laser_color = flr(rnd(5)) == 0 and colors.dark_purple or colors.yellow

                line(lx0, ly0, lx1, ly1, laser_color)
              end
            end
          end
        end

        -- draw swap laser
        for bx = 1, self.cols do
          for by = self.rows, 1, -1 do
            local gate = self:gate_at(bx, by)

            if gate:is_swap() then
              if gate.laser and gate.tick_laser and (gate.tick_laser % 4 == 0 or gate.tick_laser % 4 == 1) then
                local lx0 = self:screen_x(bx) + 3
                local ly0 = self:screen_y(by) + 3
                local lx1 = self:screen_x(gate.other_x) + 3
                local ly1 = ly0
                local laser_color = flr(rnd(5)) == 0 and colors.dark_purple or colors.yellow

                line(lx0, ly0, lx1, ly1, laser_color)
              end
            end
          end
        end        

        -- draw cnot and swap gates over the cnot and swap laser
        for bx = 1, self.cols do
          for by = self.rows_plus_next_rows, 1, -1 do
            local x = self.left + (bx - 1) * quantum_gate.size
            local y = self.top + (by - 1) * quantum_gate.size
            local gate = self:gate_at(bx, by)

            if gate:is_control() or gate:is_cnot_x() or gate:is_swap() then
              gate:draw(x, y - self._raised_dots)
            end

            if (by == self.rows_plus_next_rows) then
              spr(64, x, y - self._raised_dots)
            end
          end
        end

        -- mask next row outside the border
        rectfill(self.left - 1, self.top + self.rows * quantum_gate.size,
                 self.left + self.cols * quantum_gate.size - 1, self.top + (self.rows + 1) * quantum_gate.size,
                 colors.black)

        -- border left
        line(self.left - 2, self.top - 1,
             self.left - 2, self.top + self.rows * quantum_gate.size,
             colors.white)
        -- border bottom
        line(self.left - 2, self.top + self.rows * quantum_gate.size,
             self.left + self.cols * quantum_gate.size, self.top + self.rows * quantum_gate.size, colors.white)
        -- border right
        line(self.left + self.cols * quantum_gate.size, self.top - 1,
             self.left + self.cols * quantum_gate.size, self.top + self.rows * quantum_gate.size, colors.white)
      end,

      swap = function(self, x_left, x_right, y)
        local left_gate = self:gate_at(x_left, y)
        local right_gate = self:gate_at(x_right, y)

        if not self:is_swappable(left_gate, right_gate) then
          return false
        end

        left_gate:start_swap_with_right(x_right)
        right_gate:start_swap_with_left(x_left)

        sfx(2)        
      end,

      is_swappable = function(self, left_gate, right_gate)
        if not (left_gate:is_idle() or left_gate:is_dropped()) then
          return false
        end
        if not (right_gate:is_idle() or right_gate:is_dropped()) then
          return false
        end
        if left_gate:is_swapping() or right_gate:is_swapping() then
          return false
        end

        -- i c
        if left_gate:is_i() and right_gate:is_control() then
          return true
        end

        -- i x
        if left_gate:is_i() and right_gate:is_cnot_x() then
          return true
        end        

        -- c ?
        if left_gate:is_control() then
          if right_gate:is_i() then -- c i
            return true
          elseif not right_gate:is_cnot_x() then -- c-?-..-x
            return false             
          end
        end

        -- ? c
        if right_gate:is_control() then
          if left_gate:is_i() then -- i c
            return true
          elseif not left_gate:is_cnot_x() then -- x-?- .. -c
            return false
          end
        end

        -- x ?
        if left_gate:is_cnot_x() then
          if right_gate:is_i() then -- x i          
            return true
          elseif not right_gate:is_control() then -- x-?-..-c
            return false
          end
        end

        -- ? x
        if right_gate:is_cnot_x() then
          if left_gate:is_i() then -- i x
            return true
          elseif not left_gate:is_control() then -- c-?-..-x
            return false
          end
        end

        -- c-x
        if left_gate:is_control() and right_gate:is_cnot_x() then
          return left_gate.cnot_x_x == right_gate.cnot_c_x + 1
        end

        -- x-c
        if left_gate:is_cnot_x() and right_gate:is_control() then
          return left_gate.cnot_c_x == right_gate.cnot_x_x + 1
        end

        -- i s
        if left_gate:is_i() and right_gate:is_swap() then
          return true
        end

        -- s ?
        if left_gate:is_swap() then
          if right_gate:is_i() then -- s i
            return true
          elseif not right_gate:is_swap() then -- s-?-..-s
            return false             
          end
        end

        -- ? s
        if right_gate:is_swap() then
          if left_gate:is_i() then -- i s
            return true
          elseif not left_gate:is_swap() then -- s-?- .. -s
            return false
          end
        end

        -- s-s
        if left_gate:is_swap() and right_gate:is_swap() and
           (left_gate.other_x == right_gate.other_x + 1) then
          return true
        end

        if (right_gate:is_idle() or right_gate:is_dropped()) and 
           (left_gate:is_idle() or left_gate:is_dropped()) then
          return true
        end

        return false
      end,

      reduce = function(self)
        for x = 1, self.cols do
          for y = self.rows - 1, 1, -1 do
            if self:gate_at(x, y):is_reducible() then
              reduction = gate_reduction_rules:reduce(self, x, y)
              local delay_disappear = (#reduction - 1) * 20 + 20

              for index, r in pairs(reduction) do
                sfx(4)
                local delay_puff = (index - 1) * 20
                self:gate_at(x + r.dx, y + r.dy):replace_with(r.gate, delay_puff, delay_disappear)
                delay_puff += 20
              end
            end
          end
        end
      end,

      gates_in_action = function(self)
        local gates = {}

        for x = 1, self.cols do
          for y = 1, self.rows do
            local gate = self:gate_at(x, y)
            if not gate:is_idle() then
              add(gates, gate)
            end
          end
        end

        return gates
      end,

      bottommost_gates_of_fallen_gates = function(self)
        local gates = {}

        for x = 1, self.cols do
          for y = 1, self.rows do
            local gate = self:gate_at(x, y)
            local gate_below = self:gate_at(x, y + 1)

            if ((not gate:is_i()) and
                gate:is_dropped() and
                gate.tick_drop == 0 and
                (gate_below == nil or (not gate_below:is_dropped()))) then
              gate.x = x
              gate.y = y
              add(gates, gate)
            end
          end
        end

        return gates
      end,

      gates_to_puff = function(self)
        local gates = {}

        for x = 1, self.cols do
          for y = 1, self.rows do
            local gate = self:gate_at(x, y)

            if gate.puff then
              gate.x = x
              gate.y = y
              add(gates, gate)
            end
          end
        end

        return gates
      end,

      drop_gates = function(self)
        for x = 1, self.cols do
          for y = self.rows - 1, 1, -1 do
            local tmp_y = y
            local gate = self:gate_at(x, tmp_y)

            while ((not gate:is_i()) and
                   (not gate:is_control()) and
                   (not gate:is_cnot_x()) and
                   (not gate:is_swap()) and
                   (tmp_y < self.rows) and
                    self:_is_droppable(x, tmp_y)) do
              self:put(x, tmp_y + 1, gate)
              self:put(x, tmp_y, quantum_gate:i())
              tmp_y += 1
            end

            if (tmp_y > y) then
              gate:dropped()
            end
          end
        end

        -- drop cnot pairs
        for x = 1, self.cols do
          for y = self.rows - 1, 1, -1 do
            local tmp_y = y
            local gate = self:gate_at(x, tmp_y)

            while self:_is_control_gate_part_of_droppable_cnot(gate, x, tmp_y) do
              local cnot_c = gate
              local cnot_x = self:gate_at(cnot_c.cnot_x_x, tmp_y)

              assert(cnot_x:is_cnot_x())

              self:put(x, tmp_y + 1, cnot_c)
              self:put(x, tmp_y, quantum_gate:i())
              self:put(cnot_c.cnot_x_x, tmp_y + 1, cnot_x)
              self:put(cnot_c.cnot_x_x, tmp_y, quantum_gate:i())

              tmp_y += 1
              gate = self:gate_at(x, tmp_y)
            end

            if (tmp_y > y) then
              self:gate_at(x, tmp_y):dropped()
            end
          end
        end

        -- drop swap pairs
        for x = 1, self.cols do
          for y = self.rows - 1, 1, -1 do
            local tmp_y = y
            local gate = self:gate_at(x, tmp_y)

            while self:_is_swap_gate_part_of_droppable_swap_pair(gate, x, tmp_y) do
              local swap_a = gate
              local swap_b = self:gate_at(swap_a.other_x, tmp_y)

              assert(swap_b:is_swap())

              self:put(x, tmp_y + 1, swap_a)
              self:put(x, tmp_y, quantum_gate:i())
              self:put(swap_a.other_x, tmp_y + 1, swap_b)
              self:put(swap_a.other_x, tmp_y, quantum_gate:i())

              tmp_y += 1
              gate = self:gate_at(x, tmp_y)
            end

            if (tmp_y > y) then
              self:gate_at(x, tmp_y):dropped()
            end
          end
        end
      end,

      -- checks if the gate at (x,y) can be dropped down
      --
      --  x
      -- y___  returns true
      --
      --  x
      -- _y__  returns false
      --
      --  x
      -- c--x  returns false
      --
      --  x
      -- s--s  returns false
      --
      _is_droppable = function(self, x, y)
        assert(x and x >= 1 and x <= self.cols)
        assert(y and y >= 1 and y <= self.rows - 1)

        if (y > self.rows - 1) return false

        local gate = self:gate_at(x, y)
        local gate_below = self:gate_at(x, y + 1)

        return ((gate:is_idle() or gate:is_dropped()) and
                gate_below:is_i() and
                gate_below:is_idle() and
                (not self:_overlap_with_cnot(x, y + 1)) and
                (not self:_overlap_with_swap(x, y + 1)))
      end,

      -- checks if
      --   - gate is a control gate and
      --   - the entire cnot including the gate can be dropped down
      --
      --  c---x
      -- x______  returns true
      --
      --  c---x
      -- __x____  returns false
      --
      --   c-x
      -- c-----x  returns false
      --
      --   c-x
      -- s-----s  returns false
      --
      _is_control_gate_part_of_droppable_cnot = function(self, gate, x, y)
        if (not gate:is_control()) return false
        if (y > self.rows - 1) return false

        local min_x = min(x, gate.cnot_x_x)
        local max_x = max(x, gate.cnot_x_x)

        for cnot_x = min_x, max_x do
          if (not self:_is_droppable(cnot_x, y)) return false
        end

        return true
      end,

      -- checks if
      --   - gate is a swap gate and
      --   - the entire swap pair including the gate can be dropped down
      --
      --  s---s
      -- x______  returns true
      --
      --  s---s
      -- __x____  returns false
      --
      --   s-s
      -- c-----x  returns false
      --
      --   s-s
      -- s-----s  returns false
      --
      _is_swap_gate_part_of_droppable_swap_pair = function(self, gate, x, y)
        if (not gate:is_swap()) return false
        if (y > self.rows - 1) return false

        assert(gate.other_x)

        local min_x = min(x, gate.other_x)
        local max_x = max(x, gate.other_x)

        for swap_x = min_x, max_x do
          if (not self:_is_droppable(swap_x, y)) return false
        end

        return true
      end,

      _overlap_with_cnot = function(self, x, y)
        local control_gate = nil
        local x_gate = nil

        local control_gate_x = nil
        local x_gate_x = nil

        for bx = 1, self.cols do
          local gate = self:gate_at(bx, y)

          if gate:is_control() and (not gate:is_match()) then
            control_gate = gate
            control_gate_x = bx
            x_gate = self:gate_at(control_gate.cnot_x_x, y)
            x_gate_x = control_gate.cnot_x_x
          end
        end

        if control_gate == nil then
          return false
        end

        if (control_gate_x < x and x < x_gate_x) or
           (x_gate_x < x and x < control_gate_x) then
          return true
        end

        return false
      end,

      _overlap_with_swap = function(self, x, y)
        local swap_a = nil
        local swap_b = nil

        local swap_a_x = nil
        local swap_b_x = nil

        for bx = 1, self.cols do
          local gate = self:gate_at(bx, y)

          if gate:is_swap() and (not gate:is_match()) then
            swap_a = gate
            swap_a_x = bx
            swap_b = self:gate_at(swap_a.other_x, y)
            swap_b_x = swap_a.other_x
          end
        end

        if swap_a == nil then
          return false
        end

        if (swap_a_x < x and x < swap_b_x) or
           (swap_b_x < x and x < swap_a_x) then
          return true
        end

        return false
      end,

      is_game_over = function(self)
        for x = 1, self.cols do
          if not self:gate_at(x, 1):is_i() then
            return true
          end
        end

        return false
      end,

      insert_gates_at_bottom = function(self)
        for x = 1, self.cols do
          for y = 1, self.rows_plus_next_rows - 1 do
            if y == 1 then
              assert(self:gate_at(x, 1):is_i())
            end

            self:put(x, y, self:gate_at(x, y + 1))
          end
        end

        for x = 1, self.cols do
          repeat
            self:put(x, self.rows_plus_next_rows, self:_random_gate())
          until (#gate_reduction_rules:reduce(self, x, self.rows, true) == 0)
        end

        -- maybe add cnot
        if rnd(1) < player:cnot_probability() then
          local cnot_c_x = flr(rnd(self.cols)) + 1
          local cnot_x_x = nil
          repeat
            cnot_x_x = flr(rnd(self.cols)) + 1
          until cnot_x_x ~= cnot_c_x

          local x_gate = quantum_gate:x(cnot_c_x)
          local control_gate = quantum_gate:control(cnot_x_x)
          self:put(cnot_x_x, self.rows_plus_next_rows, x_gate)
          self:put(cnot_c_x, self.rows_plus_next_rows, control_gate)

          local cnot_left_x = min(cnot_c_x, cnot_x_x)
          local cnot_right_x = max(cnot_c_x, cnot_x_x)
          for x = cnot_left_x + 1, cnot_right_x - 1 do
            self:put(x, self.rows_plus_next_rows, quantum_gate:i())
          end          
        end
      end,

      update_gates = function(self)
        local gates_to_swap = {}

        for x = 1, self.cols do
          for y = 1, self.rows_plus_next_rows do
            local gate = self:gate_at(x, y)
            gate:update()

            -- match
            if gate:is_match() and gate.tick_match == 0 then
              sfx(4)
            end

            -- update paired gates (cnot and swap) properly
            if gate:is_swapping() and gate.tick_swap == quantum_gate._num_frames_swap then
              add(gates_to_swap, { ["gate"] = gate, ["y"] = y })

              if gate:is_control() then
                if gate.cnot_x_x == gate.swap_new_x and gate.swap_new_x + 1 == x then
                  -- c swapped with left x
                  --    x - c (swap)
                  -- -> c - x
                  gate.cnot_x_x = gate.swap_new_x + 1
                elseif gate.cnot_x_x == gate.swap_new_x and x + 1 == gate.swap_new_x then
                  -- c swapped with right x
                  --    c - x (swap)
                  -- -> x - c
                  gate.cnot_x_x = gate.swap_new_x - 1
                elseif gate.swap_new_x < gate.cnot_x_x then
                  -- c swapped with right gate (not x)
                  --    c - - x (swap)
                  -- -> _ c - x
                  assert(self:gate_at(gate.cnot_x_x, y):is_cnot_x())
                  self:gate_at(gate.cnot_x_x, y).cnot_c_x = gate.swap_new_x
                elseif gate.cnot_x_x < gate.swap_new_x then
                  -- c swapped with left gate (not x)
                  --    x - - c (swap)
                  -- -> x _ c _
                  assert(self:gate_at(gate.cnot_x_x, y):is_cnot_x())
                  self:gate_at(gate.cnot_x_x, y).cnot_c_x = gate.swap_new_x
                end
              end

              if gate:is_cnot_x() then
                if gate.cnot_c_x == gate.swap_new_x and gate.swap_new_x + 1 == x then
                  -- x swapped with left c
                  --    c - x (swap)
                  -- -> x - c
                  gate.cnot_c_x = gate.swap_new_x + 1
                elseif gate.cnot_c_x == gate.swap_new_x and x + 1 == gate.swap_new_x then
                  -- x swapped with right c
                  --    x - c (swap)
                  -- -> c - x
                  gate.cnot_c_x = gate.swap_new_x - 1
                elseif gate.swap_new_x < gate.cnot_c_x then
                  -- x swapped with right gate (not c)
                  --    x - - c (swap)
                  -- -> _ x - c
                  assert(self:gate_at(gate.cnot_c_x, y):is_control())
                  self:gate_at(gate.cnot_c_x, y).cnot_x_x = gate.swap_new_x
                elseif gate.cnot_c_x < gate.swap_new_x then
                  -- x swapped with left gate (not c)
                  --    c - - x (swap)
                  -- -> c - x _
                  assert(self:gate_at(gate.cnot_c_x, y):is_control())
                  self:gate_at(gate.cnot_c_x, y).cnot_x_x = gate.swap_new_x
                end
              end

              if gate:is_swap() then
                if gate.other_x == gate.swap_new_x and gate.other_x + 1 == x then
                  -- s swapped with left s
                  --    s - s (swap)
                  -- -> s - s
                  gate.other_x = gate.swap_new_x + 1
                elseif gate.other_x == gate.swap_new_x and x + 1 == gate.swap_new_x then
                  -- s swapped with right s
                  --    s - s (swap)
                  -- -> s - s
                  gate.other_x = gate.swap_new_x - 1
                elseif gate.swap_new_x < gate.other_x then
                  -- s swapped with right gate (not s)
                  --    s ? - s (swap)
                  -- -> ? s - s
                  assert(self:gate_at(gate.other_x, y):is_swap())
                  self:gate_at(gate.other_x, y).other_x = gate.swap_new_x
                elseif gate.other_x < gate.swap_new_x then
                  -- s swapped with left gate (not s)
                  --    s - ? s (swap)
                  -- -> s _ s ?
                  assert(self:gate_at(gate.other_x, y):is_swap())
                  self:gate_at(gate.other_x, y).other_x = gate.swap_new_x
                end
              end
            end
          end
        end

        foreach(gates_to_swap, function(each)
          self:put(each.gate.swap_new_x, each.y, each.gate)
        end)        
      end,

      raise_one_dot = function(self)
        self._raised_dots += 1
        if self._raised_dots == 8 then
          self._raised_dots = 0
        end
      end,

      game_over = function(self)
        self._state = "game over"
      end,

      -- private

      _random_gate = function(self)
        local gate = nil

        repeat
          gate = quantum_gate:random()
        until ((not gate:is_i()) and (not gate:is_control()) and (not gate:is_swap()))

        return gate
      end,
    }

    return b:init(top, left)
  end,
}
