pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
#include array.lua
#include colors.lua
#include quantum_gate.lua
#include board.lua
#include gate_reduction_rules.lua
#include player.lua
#include score_popup.lua
#include i_gate.lua
#include h_gate.lua
#include x_gate.lua
#include y_gate.lua
#include z_gate.lua
#include s_gate.lua
#include t_gate.lua
#include control_gate.lua
#include cnot_x_gate.lua
#include swap_gate.lua
#include quantum_gate_types.lua
#include garbage_unitary.lua

-- tests
#include test_helper.lua
#include test_board.lua

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
