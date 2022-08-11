pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
#include colors.lua
-- #include dropping_particle.lua
-- #include game.lua
-- #include player_cursor.lua
#include quantum_gate.lua
#include board.lua
-- #include puff_particle.lua
#include gate_reduction_rules.lua
#include player.lua
#include score_popup.lua
#include i_gate.lua
#include h_gate.lua
#include x_gate.lua
#include y_gate.lua
#include z_gate.lua
#include s_gate.lua

-- tests
#include test_helper.lua
#include test_quantum_gate.lua
#include test_board.lua

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
