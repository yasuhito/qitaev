require("engine/test/bustedhelper")
require("lib/helpers")
require("lib/garbage_block")
require("lib/board")
require("lib/cursor")

describe('garbage_block', function()
  describe('span', function()
    it("幅はデフォルトで 6", function()
      local garbage = garbage_block()

      assert.are_equal(6, garbage.span)
    end)

    it("幅 (span) を指定して生成", function()
      local garbage = garbage_block(3)

      assert.are_equal(3, garbage.span)
    end)

    it("幅を 2 以下に指定するとエラー", function()
      ---@diagnostic disable-next-line: param-type-mismatch
      assert.error(function() garbage_block(2) end)
    end)

    it("幅を 7 以上に指定するとエラー", function()
      ---@diagnostic disable-next-line: param-type-mismatch
      assert.error(function() garbage_block(7) end)
    end)
  end)

  describe('height', function()
    it("高さはデフォルトで 1", function()
      local garbage = garbage_block(3)

      assert.are_equal(1, garbage.height)
    end)

    it("高さ (height) を指定して生成", function()
      local garbage = garbage_block(3, 4)

      assert.are_equal(4, garbage.height)
    end)
  end)

  describe('body_color', function()
    it("色を指定して生成", function()
      local garbage = garbage_block(6, 1, 2)

      assert.are_equal(2, garbage.body_color)
    end)

    it("色が正しくない場合エラー", function()
      ---@diagnostic disable-next-line: param-type-mismatch
      assert.error(function() garbage_block(1) end)
    end)

    it("色に応じて inner_border_color をセットする", function()
      assert.are_equal(14, garbage_block(6, 1, 2).inner_border_color)
      assert.are_equal(11, garbage_block(6, 1, 3).inner_border_color)
      assert.are_equal(9, garbage_block(6, 1, 4).inner_border_color)
    end)
  end)

  describe('render', function()
    it('おじゃまブロックの本体、影、内側の枠線を描画', function()
      local garbage = garbage_block(6, 1, 2)
      spy.on(garbage, "_render_box")

      garbage:render(50, 50)

      ---@diagnostic disable-next-line: undefined-field
      assert.spy(garbage._render_box).was_called(3)
      ---@diagnostic disable-next-line: undefined-field
      assert.spy(garbage._render_box).was_called_with(51, 51, 95, 55, 14)
    end)
  end)
end)

describe("board", function()
  describe("_is_part_of_garbage", function()
    it("指定した座標がおじゃまブロックに含まれるかどうかを判定", function()
      local board = board_class()

      -- 行
      --  9 _ _ _ _ _ _
      -- 10 _ g g g _ _
      -- 11 _ g g g _ _
      -- 12 _ g g g _ _
      -- 13 _ _ _ _ _ _
      board:put(2, 12, garbage_block(3, 3))

      -- 9 行目
      assert.is_false(board:_is_part_of_garbage(1, 9))
      assert.is_false(board:_is_part_of_garbage(2, 9))
      assert.is_false(board:_is_part_of_garbage(3, 9))
      assert.is_false(board:_is_part_of_garbage(4, 9))
      assert.is_false(board:_is_part_of_garbage(5, 9))
      assert.is_false(board:_is_part_of_garbage(6, 9))

      -- 10 行目
      assert.is_false(board:_is_part_of_garbage(1, 10))
      assert.is_true(board:_is_part_of_garbage(2, 10))
      assert.is_true(board:_is_part_of_garbage(3, 10))
      assert.is_true(board:_is_part_of_garbage(4, 10))
      assert.is_false(board:_is_part_of_garbage(5, 10))
      assert.is_false(board:_is_part_of_garbage(6, 10))

      -- 11 行目
      assert.is_false(board:_is_part_of_garbage(1, 11))
      assert.is_true(board:_is_part_of_garbage(2, 11))
      assert.is_true(board:_is_part_of_garbage(3, 11))
      assert.is_true(board:_is_part_of_garbage(4, 11))
      assert.is_false(board:_is_part_of_garbage(5, 11))
      assert.is_false(board:_is_part_of_garbage(6, 11))

      -- 12 行目
      assert.is_false(board:_is_part_of_garbage(1, 12))
      assert.is_true(board:_is_part_of_garbage(2, 12))
      assert.is_true(board:_is_part_of_garbage(3, 12))
      assert.is_true(board:_is_part_of_garbage(4, 12))
      assert.is_false(board:_is_part_of_garbage(5, 12))
      assert.is_false(board:_is_part_of_garbage(6, 12))

      -- 13 行目
      assert.is_false(board:_is_part_of_garbage(1, 13))
      assert.is_false(board:_is_part_of_garbage(2, 13))
      assert.is_false(board:_is_part_of_garbage(3, 13))
      assert.is_false(board:_is_part_of_garbage(4, 13))
      assert.is_false(board:_is_part_of_garbage(5, 13))
      assert.is_false(board:_is_part_of_garbage(6, 13))
    end)
  end)
end)
