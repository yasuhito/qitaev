require("engine/test/bustedhelper")
require("test_helper")
require("board")

describe('ゲートの入れ替え', function()
  local board

  before_each(function()
    board = create_board()
  end)

  describe('フレーム数', function()
    it("入れ替えると状態が swapping になる", function()
      board:put(1, 16, h_gate())
      board:put(2, 16, x_gate())

      board:swap(1, 16)

      assert.is_true(board:gate_at(1, 16):is_swapping())
    end)

    it("4 フレームで入れ替わる", function()
      board:put(1, 17, h_gate())
      board:put(2, 17, x_gate())

      -- swap 開始フレーム
      board:swap(1, 17)
      board:update()
      assert.is_true(board:gate_at(1, 17):is_swapping())
      assert.is_true(board:gate_at(2, 17):is_swapping())

      board:update()
      assert.is_true(board:gate_at(1, 17):is_swapping())
      assert.is_true(board:gate_at(2, 17):is_swapping())

      board:update()
      assert.is_true(board:gate_at(1, 17):is_swapping())
      assert.is_true(board:gate_at(2, 17):is_swapping())

      board:update()
      assert.is_true(board:gate_at(1, 17):is_swapping())
      assert.is_true(board:gate_at(2, 17):is_swapping())

      board:update()

      assert.is_true(board:gate_at(1, 17):is_idle())
      assert.is_true(board:gate_at(2, 17):is_idle())
    end)
  end)

  describe('I ゲートとの入れ替え', function()
    --
    -- [H ] (H と I を入れ換え)
    it("入れ替え中の I ゲートは empty でない", function()
      board:put(1, 16, h_gate())

      board:swap(1, 16)

      assert.is_false(board:gate_at(2, 16):is_empty())
    end)
  end)
end)
