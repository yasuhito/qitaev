pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
#include colors.lua
#include drop_particle.lua
#include game.lua
#include player_cursor.lua
#include quantum_gate.lua
#include board.lua
#include puff_particle.lua
#include gate_reduction_rules.lua
#include score_popup.lua
#include player.lua
#include state_machine.lua
#include i_gate.lua
#include h_gate.lua
#include x_gate.lua
#include y_gate.lua
#include z_gate.lua
#include s_gate.lua
#include t_gate.lua
#include control_gate.lua
#include swap_gate.lua
#include quantum_gate_types.lua

function _init()
  game:init()
end

function _update60()
  game:update()
end

function _draw()
  game:draw()
end

__gfx__
0888880000ccc000099999000eeeee000bbbbb0002222200000000000000000006ddd60000d6d00006ddd600066666000d66660006666600000000000c000c00
8e888e800cc6cc009f999f90efffffe0bb3333b02eeeee200000000009000900d6ddd6d00dd6dd00dd6d6dd0dddd6dd0d6ddddd0ddd6ddd0000d000005c0c500
8e888e80ccc6ccc099f9f990eeeefee0b3bbbbb0222e22200009000005909500d66666d0d66666d0ddd6ddd0ddd6ddd0dd666dd0ddd6ddd000ddd000005c5000
8eeeee80c66666c0999f9990eeefeee0bb333bb0222e22200099900000595000d6ddd6d0ddd6ddd0ddd6ddd0dd6dddd0ddddd6d0ddd6ddd0001d100000c5c000
8e888e80ccc6ccc0999f9990eefeeee0bbbbb3b0222e22200049400000959000d6ddd6d0ddd6ddd0ddd6ddd0d66666d0d6666dd0ddd6ddd0000000000c505c00
8e888e801cc6cc10999f9990efffffe0b3333bb0222e22200000000009505900ddddddd01ddddd10ddddddd0ddddddd0ddddddd0ddddddd00000000005000500
1888881001ccc100199999101eeeee101bbbbb101222221000000000050005001ddddd1001ddd1001ddddd101ddddd101ddddd101ddddd100000000000000000
01111100001110000111110001111100011111000111110000000000000000000111110000111000011111000111110001111100011111000000000000000000
0888880000ccc000099999000eeeee000bbbbb000222220000000000000000000ddddd0000ddd0000ddddd000ddddd000ddddd000ddddd000000000000000000
888888800ccccc0099999990eeeeeee0bbbbbbb0222222200000000000000000d6ddd6d00dd6dd00d6ddd6d0d66666d0dd6666d0d66666d0000000000c000c00
88888880ccccccc099999990eeeeeee0bbbbbbb0222222200000000009000900d6ddd6d0ddd6ddd0dd6d6dd0dddd6dd0d6ddddd0ddd6ddd0000d000005c0c500
8e888e80ccc6ccc09f999f90efffffe0bb3333b02eeeee200009000005909500d66666d0d66666d0ddd6ddd0ddd6ddd0dd666dd0ddd6ddd000ddd000005c5000
8e888e80ccc6ccc099f9f990eeeefee0b3bbbbb0222e22200099900000595000d6ddd6d0ddd6ddd0ddd6ddd0dd6dddd0ddddd6d0ddd6ddd0001d100000c5c000
8eeeee8016666610999f9990eeefeee0bb333bb0122e22100049400000959000d6ddd6d01dd6dd10ddd6ddd0d66666d0d6666dd0ddd6ddd0000000000c505c00
1e888e1001c6c100199f99101efeee101bbbb3100111110000000000095059001ddddd1001ddd1001ddddd101ddddd101ddddd101ddddd100000000005000500
01111100001110000111110001111100011111000000000000000000050005000111110000111000011111000111110001111100011111000000000000000000
0e888e0000c6c0000f999f000fffff000b3333000eeeee0000000000090009000ddddd0000ddd0000ddddd000ddddd000ddddd000ddddd000000000000000000
8e888e800cc6cc0099f9f990eeeefee0b3bbbbb0222e22200009000005909500ddddddd00ddddd00ddddddd0ddddddd0ddddddd0ddddddd00000000000000000
8eeeee80c66666c0999f9990eeefeee0bb333bb0222e22200099900000595000d6ddd6d0ddd6ddd0d6ddd6d0d66666d0dd6666d0d66666d0000000000c000c00
8e888e80ccc6ccc0999f9990eefeeee0bbbbb3b0222e22200049400000959000d6ddd6d0ddd6ddd0dd6d6dd0dddd6dd0d6ddddd0ddd6ddd0000d000005c0c500
8e888e80ccc6ccc0999f9990efffffe0b3333bb0222e22200000000009505900d66666d0d66666d0ddd6ddd0ddd6ddd0dd666dd0ddd6ddd000ddd000005c5000
888888801ccccc1099999990eeeeeee0bbbbbbb0222222200000000005000500d6ddd6d01dd6dd10ddd6ddd0dd6dddd0ddddd6d0ddd6ddd0001d100000c5c000
1888881001ccc100199999101eeeee101bbbbb1012222210000000000000000016ddd61001d6d1001dd6dd101666661016666d101dd6dd10000000000c505c00
01111100001110000111110001111100011111000111110000000000000000000111110000111000011111000111110001111100011111000000000005000500
0eeeee0000666000099f99000eefee000b333b00022e220000090000059095000000000000000000000000000000000000000000000000000000000000000000
8e888e800cc6cc00999f9990eefeeee0bbbbb3b0222e222000999000005950000000000000000000000000000000000000000000000000000000000000000000
8e888e80ccc6ccc0999f9990efffffe0b3333bb0222e222000494000009590000000000000000000000000000000000000000000000000000000000000000000
88888880ccccccc099999990eeeeeee0bbbbbbb02222222000000000095059000000000000000000000000000000000000000000000000000000000000000000
88888880ccccccc099999990eeeeeee0bbbbbbb02222222000000000050005000000000000000000000000000000000000000000000000000000000000000000
888888801ccccc1099999990eeeeeee0bbbbbbb02222222000000000000000000000000000000000000000000000000000000000000000000000000000000000
1888881001ccc100199999101eeeee101bbbbb101222221000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111100001110000111110001111100011111000111110000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050003333303333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050505003777303777773000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050003733303337333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050505003730000037300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050003330000033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333003333333003333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37773003777773003777300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37333003337333003337300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
37300050037300500037305000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
33300050033300500033305000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
33300050033300500033305000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
37300050037300500037305000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
37333053337333503337305000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
37773053777773503777305000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
33333053333333503333305000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000661111600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000616666600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000661116600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666661600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000611116600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000611111600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666166600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666166600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666166600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666166600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000616661600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000661616600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666166600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666166600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000666166600005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000666660006666600066666000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000616661606166616061111160616661600005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000616661606616166066661660616661600005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000611111606661666066616660611111600005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000616661606661666066166660616661600005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000616661606661666061111160616661600005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000066666000666660006666600066666000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600066666000666660006666600066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07061111160661111606111116061666160611111606111116070000000000000000000000000000000000000000000000000000000000000000000000000000
07066661660616666606666166061666160666616606661666070000000000000000000000000000000000000000000000000000000000000000000000000000
07066616660661116606661666061111160666166606661666070000000000000000000000000000000000000000000000000000000000000000000000000000
07066166660666661606616666061666160661666606661666070000000000000000000000000000000000000000000000000000000000000000000000000000
07061111160611116606111116061666160611111606661666070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600066666000666660006666600066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600006660000666660006666600066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160066166006166616061111160661111606166616070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160666166606166616066616660616666606166616070000000000000000000000000000000000000000000000000000000000000000000000000000
07061111160611111606111116066616660661116606111116070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160666166606166616066616660666661606166616070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160066166006166616066616660611116606166616070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600006660000666660006666600066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600066666000666660000666000066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07066111160616661606111116006616600611111606611116070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666660616661606661666066616660666616606166666070000000000000000000000000000000000000000000000000000000000000000000000000000
07066111660611111606661666061111160666166606611166070000000000000000000000000000000000000000000000000000000000000000000000000000
07066666160616661606661666066616660661666606666616070000000000000000000000000000000000000000000000000000000000000000000000000000
07061111660616661606661666006616600611111606111166070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600066666000666660000666000066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600006660000666660006666600066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160066166006111116061666160616661606111116070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160666166606666166061666160661616606666166070000000000000000000000000000000000000000000000000000000000000000000000000000
07061111160611111606661666061111160666166606661666070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160666166606616666061666160666166606616666070000000000000000000000000000000000000000000000000000000000000000000000000000
07061666160066166006111116061666160666166606111116070000000000000000000000000000000000000000000000000000000000000000000000000000
07006666600006660000666660006666600066666000666660070000000000000000000000000000000000000000000000000000000000000000000000000000
07000050000000500000005000000050000000500000005000070000000000000000000000000000000000000000000000000000000000000000000000000000
07050555050505550505055505050555050505450505656565070000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbb0bbb00bb000000000b000bbb000b0b000bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b000b0b0b0000b000000b000b0b00b00b000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bb00bbb0bbb000000000bbb0b0b00b00bbb0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b000b00000b00b000000b0b0b0b00b00b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b000b000bb0000000000bbb0bbb0b000bbb0bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000100002202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001003011030110300672007720067200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002b0102d01031010336102e0102f0103160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000178201d820248202b8202f83030830328303483035830308302b8301c8301c8301c8301c8301c8301c8301f830238302483029830248301f8201f8201e8201f8202282024830298302e8303382037820
000400000ab3008b300ab300cb3007b300ab300bb3009b300cb300bb300db300bb300bb300cb300bb300bb3009b300bb300fb300cb300cb300fb300cb300db300000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000200c043000003350030100246250000033500000000c000000000c04300000246250000033500000000c043000003350000000246250000033500000000c000000000c0431660024625000003350000000
a31000003f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f617006073f61700607
2f1000001c7551c7051c7551a7551c7551c7051c7551a7551c7551c7051c7551a7551c7551c7051c7551a7551c7551c7051c7551a7551c7551c7051c7551a7551c7551c7051c7551a7551c7551c7051c7551a755
010800001c7351b7351c7351b7351b7351b735187351b7351b735187351b7351b735187351b7351b735187351b7351b735187351b7351b735187351b7351d7351d7351e7351e7351f7351d7351c7351e7351e735
__music__
04 06070844

