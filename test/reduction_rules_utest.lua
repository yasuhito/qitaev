require("engine/test/bustedhelper")
require("test/test_helper")

require("lib/block")
require("lib/board")
require("lib/cursor")

-- TODO: assert.is_i とかをほかのテストでも使えるようにする

-- https://github.com/lunarmodules/say
local say = require("say")

local function is_i(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "i"
end

say:set("assertion.is_i.positive", "Expected %s \nto be an I block")
say:set("assertion.is_i.negative", "Expected %s \n not to be an I block")
assert:register("assertion", "is_i", is_i, "assertion.is_i.positive", "assertion.is_i.negative")

local function is_h(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "h"
end

say:set("assertion.is_h.positive", "Expected %s \nto be an H block")
say:set("assertion.is_h.negative", "Expected %s \n not to be an H block")
assert:register("assertion", "is_h", is_h, "assertion.is_h.positive", "assertion.is_h.negative")

local function is_x(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "x"
end

say:set("assertion.is_x.positive", "Expected %s \nto be an X block")
say:set("assertion.is_x.negative", "Expected %s \n not to be an X block")
assert:register("assertion", "is_x", is_x, "assertion.is_x.positive", "assertion.is_x.negative")

local function is_y(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "y"
end

say:set("assertion.is_y.positive", "Expected %s \nto be a Y block")
say:set("assertion.is_y.negative", "Expected %s \n not to be a Y block")
assert:register("assertion", "is_y", is_y, "assertion.is_y.positive", "assertion.is_y.negative")

local function is_z(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "z"
end

say:set("assertion.is_z.positive", "Expected %s \nto be a Z block")
say:set("assertion.is_z.negative", "Expected %s \n not to be a Z block")
assert:register("assertion", "is_z", is_z, "assertion.is_z.positive", "assertion.is_z.negative")

local function is_s(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "s"
end

say:set("assertion.is_s.positive", "Expected %s \nto be an S block")
say:set("assertion.is_s.negative", "Expected %s \n not to be an S block")
assert:register("assertion", "is_s", is_s, "assertion.is_s.positive", "assertion.is_s.negative")

local function is_control(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "control"
end

say:set("assertion.is_control.positive", "Expected %s \nto be a CONTROL block")
say:set("assertion.is_control.negative", "Expected %s \n not to be a CONTROL block")
assert:register("assertion", "is_control", is_control, "assertion.is_control.positive", "assertion.is_control.negative")

local function is_cnot_x(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "cnot_x"
end

say:set("assertion.is_cnot_x.positive", "Expected %s \nto be a X (CNOT) block")
say:set("assertion.is_cnot_x.negative", "Expected %s \n not to be a X (CNOT) block")
assert:register("assertion", "is_cnot_x", is_cnot_x, "assertion.is_cnot_x.positive", "assertion.is_cnot_x.negative")

local function is_swap(_state, arguments)
  if not type(arguments[1]) == "table" or #arguments ~= 1 then
    return false
  end

  return arguments[1].type == "swap"
end

say:set("assertion.is_swap.positive", "Expected %s \nto be a SWAP block")
say:set("assertion.is_swap.negative", "Expected %s \n not to be a SWAP block")
assert:register("assertion", "is_swap", is_swap, "assertion.is_swap.positive", "assertion.is_swap.negative")

describe('ブロックの簡約ルール #solo', function()
  local board

  before_each(function()
    board = board_class()
  end)

  it('HH → I', function()
    board:put(1, 2, block_class("h"))
    board:put(1, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('XX → I', function()
    board:put(1, 2, block_class("x"))
    board:put(1, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('YY → I', function()
    board:put(1, 2, block_class("y"))
    board:put(1, 1, block_class("y"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('ZZ → I', function()
    board:put(1, 2, block_class("z"))
    board:put(1, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('SS → Z', function()
    board:put(1, 2, block_class("s"))
    board:put(1, 1, block_class("s"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_z(board:block_at(1, 1).new_block)
  end)

  it('TT → S', function()
    board:put(1, 2, block_class("t"))
    board:put(1, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_s(board:block_at(1, 1).new_block)
  end)

  it('XZ → Y', function()
    board:put(1, 2, block_class("x"))
    board:put(1, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_y(board:block_at(1, 1).new_block)
  end)

  it('ZX → Y', function()
    board:put(1, 2, block_class("z"))
    board:put(1, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_y(board:block_at(1, 1).new_block)
  end)

  it('should reduce HXH', function()
    board:put(1, 3, block_class("h"))
    board:put(1, 2, block_class("x"))
    board:put(1, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_z(board:block_at(1, 1).new_block)
  end)

  it('should reduce HZH', function()
    board:put(1, 3, block_class("h"))
    board:put(1, 2, block_class("z"))
    board:put(1, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_x(board:block_at(1, 1).new_block)
  end)

  it('should reduce SZS', function()
    board:put(1, 3, block_class("s"))
    board:put(1, 2, block_class("z"))
    board:put(1, 1, block_class("s"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_z(board:block_at(1, 1).new_block)
  end)

  it('should reduce TST', function()
    board:put(1, 3, block_class("t"))
    board:put(1, 2, block_class("s"))
    board:put(1, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_z(board:block_at(1, 1).new_block)
  end)

  it('should reduce TZST', function()
    board:put(1, 4, block_class("t"))
    board:put(1, 3, block_class("z"))
    board:put(1, 2, block_class("s"))
    board:put(1, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 4).new_block)
    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('should reduce TSZT', function()
    board:put(1, 4, block_class("t"))
    board:put(1, 3, block_class("s"))
    board:put(1, 2, block_class("z"))
    board:put(1, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 4).new_block)
    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('should reduce C-X x2', function()
    board:put(1, 2, control_block(3))
    board:put(3, 2, cnot_x_block(1))
    board:put(1, 1, control_block(3))
    board:put(3, 1, cnot_x_block(1))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  it('should reduce X-C x2', function()
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(1, 1, cnot_x_block(3))
    board:put(3, 1, control_block(1))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  -- これは消えてはダメ
  --
  --   C-X
  -- X-C X-C
  it('まちがった C-X x2 は消えない', function()
    board:put(2, 2, control_block(3))
    board:put(3, 2, cnot_x_block(2))

    board:put(1, 1, cnot_x_block(2))
    board:put(2, 1, control_block(1))
    board:put(3, 1, cnot_x_block(4))
    board:put(4, 1, control_block(3))

    local reduction = board:reduce(2, 1)

    assert.are_equal(0, #reduction.to)
  end)

  -- C-X          I I
  -- X-C          I I
  -- C-X  ----->  S-S
  it('should reduce C-X X-C C-X', function()
    board:put(1, 3, control_block(3))
    board:put(3, 3, cnot_x_block(1))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(1, 1, control_block(3))
    board:put(3, 1, cnot_x_block(1))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_swap(board:block_at(1, 1).new_block)
    assert.are_equal(3, board:block_at(1, 1).new_block.other_x)
    assert.is_swap(board:block_at(3, 1).new_block)
    assert.are_equal(1, board:block_at(3, 1).new_block.other_x)
  end)

  -- X-C          I I
  -- C-X          I I
  -- X-C  ----->  S-S
  it('should reduce C-X X-C C-X', function()
    board:put(1, 3, cnot_x_block(3))
    board:put(3, 3, control_block(1))
    board:put(1, 2, control_block(3))
    board:put(3, 2, cnot_x_block(1))
    board:put(1, 1, cnot_x_block(3))
    board:put(3, 1, control_block(1))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_swap(board:block_at(1, 1).new_block)
    assert.are_equal(3, board:block_at(1, 1).new_block.other_x)
    assert.is_swap(board:block_at(3, 1).new_block)
    assert.are_equal(1, board:block_at(3, 1).new_block.other_x)
  end)

  it('should reduce HH C-X HH', function()
    board:put(1, 3, block_class("h"))
    board:put(3, 3, block_class("h"))
    board:put(1, 2, control_block(3))
    board:put(3, 2, cnot_x_block(1))
    board:put(1, 1, block_class("h"))
    board:put(3, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_cnot_x(board:block_at(1, 2).new_block)
    assert.are_equal(3, board:block_at(1, 2).new_block.other_x)
    assert.is_control(board:block_at(3, 2).new_block)
    assert.are_equal(1, board:block_at(3, 2).new_block.other_x)
    assert.is_i(board:block_at(1, 1).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  it('should reduce HH X-C HH', function()
    board:put(1, 3, block_class("h"))
    board:put(3, 3, block_class("h"))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(1, 1, block_class("h"))
    board:put(3, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_control(board:block_at(1, 2).new_block)
    assert.are_equal(3, board:block_at(1, 2).new_block.other_x)
    assert.is_cnot_x(board:block_at(3, 2).new_block)
    assert.are_equal(1, board:block_at(3, 2).new_block.other_x)
    assert.is_i(board:block_at(1, 1).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  it('should reduce XX C-X X', function()
    board:put(1, 3, block_class("x"))
    board:put(3, 3, block_class("x"))
    board:put(1, 2, control_block(3))
    board:put(3, 2, cnot_x_block(1))
    board:put(1, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_control(board:block_at(1, 2))
    assert.is_cnot_x(board:block_at(3, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('should reduce XX X-C X', function()
    board:put(1, 3, block_class("x"))
    board:put(3, 3, block_class("x"))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(3, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_cnot_x(board:block_at(1, 2))
    assert.is_control(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  it('should reduce ZZ C-X Z', function()
    board:put(1, 3, block_class("z"))
    board:put(3, 3, block_class("z"))
    board:put(1, 2, control_block(3))
    board:put(3, 2, cnot_x_block(1))
    board:put(3, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_control(board:block_at(1, 2))
    assert.is_cnot_x(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  it('should reduce ZZ X-C Z', function()
    board:put(1, 3, block_class("z"))
    board:put(3, 3, block_class("z"))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(1, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_cnot_x(board:block_at(1, 2))
    assert.is_control(board:block_at(3, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('should reduce X C-X X', function()
    board:put(3, 3, block_class("x"))
    board:put(1, 2, control_block(3))
    board:put(3, 2, cnot_x_block(1))
    board:put(3, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_control(board:block_at(1, 2))
    assert.is_cnot_x(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  it('should reduce X X-C X', function()
    board:put(1, 3, block_class("x"))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(1, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_cnot_x(board:block_at(1, 2))
    assert.is_control(board:block_at(3, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('should reduce Z C-X Z', function()
    board:put(1, 3, block_class("z"))
    board:put(1, 2, control_block(3))
    board:put(3, 2, cnot_x_block(1))
    board:put(1, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_control(board:block_at(1, 2))
    assert.is_cnot_x(board:block_at(3, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  it('should reduce Z X-C Z', function()
    board:put(3, 3, block_class("z"))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(3, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_cnot_x(board:block_at(1, 2))
    assert.is_control(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  it('should reduce S-S x2', function()
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(1, 1, swap_block(3))
    board:put(3, 1, swap_block(1))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 2).new_block)
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(1, 1).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  H            I
  --  S-S  ----->  S-S
  --    H            I
  it('H S-S H を簡約する', function()
    board:put(1, 3, block_class("h"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(1, 1, block_class("x")) -- 適当なゴミを置いとく
    board:put(3, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --    H            I
  --  S-S  ----->  S-S
  --  H            I
  it('H S-S H を簡約する (反対側)', function()
    board:put(3, 3, block_class("h"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(1, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  --  X            I
  --  S-S  ----->  S-S
  --    X            I
  it('X S-S X を簡約する', function()
    board:put(1, 3, block_class("x"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --    X            I
  --  S-S  ----->  S-S
  --  X            I
  it('X S-S X を簡約する (反対側)', function()
    board:put(3, 3, block_class("x"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(1, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  --  Y            I
  --  S-S  ----->  S-S
  --    Y            I
  it('should reduce Y S-S Y', function()
    board:put(1, 3, block_class("y"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("y"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  Z            I
  --  S-S  ----->  S-S
  --    Z            I
  it('should reduce Z S-S Z', function()
    board:put(2, 3, block_class("z"))
    board:put(2, 2, swap_block(4))
    board:put(4, 2, swap_block(2))
    board:put(2, 1, cnot_x_block(1)) -- 適当なゴミを置いとく
    board:put(4, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(2, 3).new_block)
    assert.is_swap(board:block_at(2, 2))
    assert.is_swap(board:block_at(4, 2))
    assert.is_i(board:block_at(4, 1).new_block)
  end)

  --  s            Z
  --  S-S  ----->  S-S
  --    s            I
  it('should reduce S S-S S', function()
    board:put(1, 3, block_class("s"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("s"))

    board:reduce_blocks()

    assert.is_z(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  T            S
  --  S-S  ----->  S-S
  --    T            I
  it('should reduce T S-S T', function()
    board:put(1, 3, block_class("t"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_s(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  X            Y
  --  S-S  ----->  S-S
  --    Z            I
  it('should reduce X S-S Z', function()
    board:put(1, 3, block_class("x"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_y(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  H            I
  --  X            Z
  --  S-S  ----->  S-S
  --    H            I
  it('should reduce HX S-S H', function()
    board:put(1, 4, block_class("h"))
    board:put(1, 3, block_class("x"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 4).new_block)
    assert.is_z(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  H            Z
  --  S-S  ----->  S-S
  --    X            I
  --    H            I
  it('should reduce H S-S XH', function()
    board:put(1, 4, block_class("h"))
    board:put(1, 3, swap_block(3))
    board:put(3, 3, swap_block(1))
    board:put(3, 2, block_class("x"))
    board:put(3, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_z(board:block_at(1, 4).new_block)
    assert.is_swap(board:block_at(1, 3))
    assert.is_swap(board:block_at(3, 3))
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  H            I
  --  Z            X
  --  S-S  ----->  S-S
  --    H            I
  it('should reduce HZ S-S H', function()
    board:put(1, 4, block_class("h"))
    board:put(1, 3, block_class("z"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 4).new_block)
    assert.is_x(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  H            X
  --  S-S  ----->  S-S
  --    Z            I
  --    H            I
  it('should reduce H S-S ZH', function()
    board:put(1, 4, block_class("h"))
    board:put(1, 3, swap_block(3))
    board:put(3, 3, swap_block(1))
    board:put(3, 2, block_class("z"))
    board:put(3, 1, block_class("h"))

    board:reduce_blocks()

    assert.is_x(board:block_at(1, 4).new_block)
    assert.is_swap(board:block_at(1, 3))
    assert.is_swap(board:block_at(3, 3))
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  S            I
  --  Z            Z
  --  S-S  ----->  S-S
  --    S            I
  it('should reduce SZ S-S S', function()
    board:put(1, 4, block_class("s"))
    board:put(1, 3, block_class("z"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("s"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 4).new_block)
    assert.is_z(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  S            Z
  --  S-S  ----->  S-S
  --    Z            I
  --    S            I
  it('should reduce S S-S ZS', function()
    board:put(1, 4, block_class("s"))
    board:put(1, 3, swap_block(3))
    board:put(3, 3, swap_block(1))
    board:put(3, 2, block_class("z"))
    board:put(3, 1, block_class("s"))

    board:reduce_blocks()

    assert.is_z(board:block_at(1, 4).new_block)
    assert.is_swap(board:block_at(1, 3))
    assert.is_swap(board:block_at(3, 3))
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  T            I
  --  S            Z
  --  S-S  ----->  S-S
  --    T            I
  it('should reduce TS S-S T', function()
    board:put(1, 4, block_class("t"))
    board:put(1, 3, block_class("s"))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(3, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 4).new_block)
    assert.is_z(board:block_at(1, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  T            Z
  --  S-S  ----->  S-S
  --    S            I
  --    T            I
  it('should reduce T S-S ST', function()
    board:put(1, 4, block_class("t"))
    board:put(1, 3, swap_block(3))
    board:put(3, 3, swap_block(1))
    board:put(3, 2, block_class("s"))
    board:put(3, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_z(board:block_at(1, 4).new_block)
    assert.is_swap(board:block_at(1, 3))
    assert.is_swap(board:block_at(3, 3))
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  T            I
  --  S-S  ----->  S-S
  --    Z            I
  --    S            I
  --    T            I
  it('should reduce T S-S ZST', function()
    board:put(1, 5, block_class("t"))
    board:put(1, 4, swap_block(3))
    board:put(3, 4, swap_block(1))
    board:put(3, 3, block_class("z"))
    board:put(3, 2, block_class("s"))
    board:put(3, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 5).new_block)
    assert.is_swap(board:block_at(1, 4))
    assert.is_swap(board:block_at(3, 4))
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  T            I
  --  S-S  ----->  S-S
  --    S            I
  --    Z            I
  --    T            I
  it('should reduce T S-S SZT', function()
    board:put(1, 5, block_class("t"))
    board:put(1, 4, swap_block(3))
    board:put(3, 4, swap_block(1))
    board:put(3, 3, block_class("s"))
    board:put(3, 2, block_class("z"))
    board:put(3, 1, block_class("t"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 5).new_block)
    assert.is_swap(board:block_at(1, 4))
    assert.is_swap(board:block_at(3, 4))
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_i(board:block_at(3, 2).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  Z            I
  --  H X          H I
  --  X-C  ----->  X-C
  --  H X          H I
  it('should reduce Z HX X-C HX', function()
    board:put(1, 4, block_class("z"))
    board:put(1, 3, block_class("h"))
    board:put(3, 3, block_class("x"))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(1, 1, block_class("h"))
    board:put(3, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 4).new_block)
    assert.is_h(board:block_at(1, 3))
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_cnot_x(board:block_at(1, 2))
    assert.is_control(board:block_at(3, 2))
    assert.is_h(board:block_at(1, 1))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  X            I
  --  H Z          H I
  --  X-C  ----->  X-C
  --  H            H
  --  X            I
  it('should reduce X HZ X-C H X', function()
    board:put(1, 5, block_class("x"))
    board:put(1, 4, block_class("h"))
    board:put(3, 4, block_class("z"))
    board:put(1, 3, cnot_x_block(3))
    board:put(3, 3, control_block(1))
    board:put(1, 2, block_class("h"))
    board:put(1, 1, block_class("x"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 5).new_block)
    assert.is_h(board:block_at(1, 4))
    assert.is_i(board:block_at(3, 4).new_block)
    assert.is_cnot_x(board:block_at(1, 3))
    assert.is_control(board:block_at(3, 3))
    assert.is_h(board:block_at(1, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  --  H Z          H I
  --  X-C  ----->  X-C
  --  H Z          H I
  it('should reduce HZ X-C HZ', function()
    board:put(1, 3, block_class("h"))
    board:put(3, 3, block_class("z"))
    board:put(1, 2, cnot_x_block(3))
    board:put(3, 2, control_block(1))
    board:put(1, 1, block_class("h"))
    board:put(3, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_h(board:block_at(1, 3))
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_cnot_x(board:block_at(1, 2))
    assert.is_control(board:block_at(3, 2))
    assert.is_h(board:block_at(1, 1))
    assert.is_i(board:block_at(3, 1).new_block)
  end)

  --  Z            I
  --  H            H
  --  X-C  ----->  X-C
  --  H            H
  --  Z            I
  it('should reduce Z H X-C H Z', function()
    board:put(1, 5, block_class("z"))
    board:put(1, 4, block_class("h"))
    board:put(1, 3, cnot_x_block(3))
    board:put(3, 3, control_block(1))
    board:put(1, 2, block_class("h"))
    board:put(1, 1, block_class("z"))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 5).new_block)
    assert.is_h(board:block_at(1, 4))
    assert.is_cnot_x(board:block_at(1, 3))
    assert.is_control(board:block_at(3, 3))
    assert.is_h(board:block_at(1, 2))
    assert.is_i(board:block_at(1, 1).new_block)
  end)

  --  C-X          I I
  --  S-S  ----->  S-S
  --  X-C          I I
  it('should reduce C-X S-S X-C', function()
    board:put(1, 3, control_block(3))
    board:put(3, 3, cnot_x_block(1))
    board:put(1, 2, swap_block(3))
    board:put(3, 2, swap_block(1))
    board:put(1, 1, cnot_x_block(3))
    board:put(3, 1, control_block(1))

    board:reduce_blocks()

    assert.is_i(board:block_at(1, 3).new_block)
    assert.is_i(board:block_at(3, 3).new_block)
    assert.is_swap(board:block_at(1, 2))
    assert.is_swap(board:block_at(3, 2))
    assert.is_i(board:block_at(1, 1).new_block)
    assert.is_i(board:block_at(3, 1).new_block)
  end)
end)
