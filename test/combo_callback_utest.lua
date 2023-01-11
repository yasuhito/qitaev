require("engine/test/bustedhelper")
require("test/test_helper")
require("lib/helpers")
require("lib/game")
require("lib/board")
require("lib/block")
require("lib/cursor")

local match = require("luassert.match")

describe('コンボ (同時消し) のコールバック #solo', function()
  local board

  before_each(function()
    board = board_class()
    stub(game_class, "combo_callback")
  end)

  it("4-コンボ発生でコールバックが呼ばれる", function()
    -- [X H]         H X <- 4-combo
    --  H X  ----->  H X
    board:put(1, 2, block_class("x"))
    board:put(1, 1, block_class("h"))
    board:put(2, 2, block_class("h"))
    board:put(2, 1, block_class("x"))

    board:swap(1, 1)
    wait_swap_to_finish(board)

    local combo_callback = assert.spy(game_class.combo_callback)
    board:update(game_class)

    combo_callback.was_called(1)
    combo_callback.was_called_with(4, 2, 2, match._, match._, match._)
  end)

  it("5-コンボ発生でコールバックが呼ばれる", function()
    --    S            S <- 5-combo
    -- [Z H]         H Z
    --  H S  ----->  H S
    board:put(2, 3, block_class("s"))
    board:put(1, 2, block_class("z"))
    board:put(2, 2, block_class("h"))
    board:put(1, 1, block_class("h"))
    board:put(2, 1, block_class("s"))

    board:swap(1, 2)
    wait_swap_to_finish(board)

    local combo_callback = assert.spy(game_class.combo_callback)
    board:update(game_class)

    combo_callback.was_called(1)
    combo_callback.was_called_with(5, 2, 3, match._, match._, match._)
  end)

  it("6-コンボ発生でコールバックが呼ばれる", function()
    -- [S H]        H S <- 6-combo
    --  X Z         Z X
    --  H S  -----> H S
    board:put(1, 3, block_class("s"))
    board:put(2, 3, block_class("h"))
    board:put(1, 2, block_class("x"))
    board:put(2, 2, block_class("z"))
    board:put(1, 1, block_class("h"))
    board:put(2, 1, block_class("s"))

    board:swap(1, 3)
    wait_swap_to_finish(board)

    local combo_callback = assert.spy(game_class.combo_callback)
    board:update(game_class)

    combo_callback.was_called(1)
    combo_callback.was_called_with(6, 2, 3, match._, match._, match._)
  end)

  it("7-コンボ発生でコールバックが呼ばれる", function()
    --    T            T <- 7-combo
    --  H Z          H Z
    --  X S          X S
    -- [T H]  -----> H T
    board:put(2, 4, block_class("t"))
    board:put(1, 3, block_class("h"))
    board:put(2, 3, block_class("z"))
    board:put(1, 2, block_class("x"))
    board:put(2, 2, block_class("s"))
    board:put(1, 1, block_class("t"))
    board:put(2, 1, block_class("h"))

    board:swap(1, 1)
    wait_swap_to_finish(board)

    local combo_callback = assert.spy(game_class.combo_callback)
    board:update(game_class)

    combo_callback.was_called(1)
    combo_callback.was_called_with(7, 2, 4, match._, match._, match._)
  end)
end)
