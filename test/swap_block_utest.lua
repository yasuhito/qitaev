require("engine/test/bustedhelper")
require("test/test_helper")

describe('swap_block', function()
  local swap

  before_each(function()
    swap = swap_block(2)
  end)

  describe("is_i", function()
    it("should return false", function()
      assert.is_false(swap.type == "i")
    end)
  end)

  describe("is_garbage", function()
    it("should return false", function()
      assert.is_false(swap.type == "g")
    end)
  end)

  describe("is_idle", function()
    it("should return true", function()
      assert.is_true(swap:is_idle())
    end)
  end)

  describe("is_swapping", function()
    it("should return false", function()
      assert.is_false(swap:is_swapping())
    end)
  end)

  describe("is_falling", function()
    it("should return false", function()
      assert.is_false(swap:is_falling())
    end)
  end)

  describe("is_match", function()
    it("should return false", function()
      assert.is_false(swap:is_match())
    end)
  end)

  describe("stringify", function()
    it("should return 'X '", function()
      assert.are.equals("X ", stringify(swap))
    end)
  end)
end)
