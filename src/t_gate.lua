require("engine/core/class")

local gate = require("gate")
local t_gate = derived_class(gate)
local sprites_dropped = split("21,21,21,21,53,53,37,37,37,21,21,21")

function t_gate:_init()
  gate._init(self, 't')
  self.sprites = {
    default = 5,
    dropped = sprites_dropped,
    match = "14,14,14,30,30,30,14,14,14,46,46,46,5,5,5,62"
  }
end

return t_gate
