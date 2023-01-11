require("engine/test/bustedhelper")
require("lib/helpers")
require("lib/cursor")
require("lib/qpu")
require("lib/game")
require("lib/board")

local profiler = require("lib/profiler")

describe('パフォーマンス #solo', function()
  it("QPU vs QPU のプロファイルを取る", function()
    local qpu1_cursor = cursor_class()
    local qpu2_cursor = cursor_class()
    local qpu1_board = board_class(qpu1_cursor)
    local qpu2_board = board_class(qpu2_cursor)
    local qpu1 = create_qpu(qpu1_board)
    local qpu2 = create_qpu(qpu2_board)
    local game = game_class()

    qpu1:init()
    qpu1_board:put_random_blocks()
    qpu1_board.block_offset_target = { 48, 15 }
    qpu1_board.attack_ion_target = { 78, 15 }
    qpu1_cursor:init()

    qpu2:init()
    qpu2_board:put_random_blocks()
    qpu2_board.block_offset_target = { 78, 15 }
    qpu2_board.attack_ion_target = { 48, 15 }
    qpu2_cursor:init()

    game:init()
    game:add_player(qpu1, qpu1_board, qpu2_board)
    game:add_player(qpu2, qpu2_board, qpu1_board)

    profiler.start()
    for i = 1, 2000 do
      game:update()
    end
    profiler.stop()

    profiler.report("profiler.log")
  end)
end)
