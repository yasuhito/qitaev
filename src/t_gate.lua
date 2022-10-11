require("engine/core/class")

local gate = require("gate")
local t_gate = derived_class(gate)

function t_gate:_init()
  gate._init(self, 't')
  self.sprites = {
    idle = 5,
    swapping_with_left = 5,
    swapping_with_right = 5,
    dropping = 5,
    match = { up = 13, middle = 29, down = 45 }
  }
end

return t_gate
