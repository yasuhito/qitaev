require("engine/test/bustedhelper")
require("engine/render/color")
require("test/test_helper")
require("lib/helpers")
require("lib/cursor")
require("lib/qpu")
require("lib/board")
require("lib/block")

describe('qpu #solo', function()
  describe('create_qpu', function()
    it("creates a qpu with score = 0", function()
      local qpu = create_qpu()

      assert.are_equal(0, qpu.score)
    end)
  end)

  describe('init', function()
    it("resets score", function()
      local qpu = create_qpu()
      qpu.score = 1

      qpu:init()

      assert.are_equal(0, qpu.score)
    end)
  end)

  describe('update', function()
    local board
    local cursor
    local qpu

    before_each(function()
      cursor = cursor_class()
      board = board_class(cursor)
      qpu = create_qpu(board)
      qpu.sleep = false
      qpu.raise = false
    end)

    describe("CNOT を消す", function()
      -- [X-]-C
      it("CNOT を X 側から縮める", function()
        board:put(1, 1, cnot_x_block(3))
        board:put(3, 1, control_block(1))
        cursor.x = 1
        cursor.y = 1

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      -- [C-]-X
      it("CNOT を C 側から縮める", function()
        board:put(1, 1, control_block(3))
        board:put(3, 1, cnot_x_block(1))
        cursor.x = 1
        cursor.y = 1

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      -- [C-X]
      it("CNOT を同じ方向 (右が C) にそろえる", function()
        board:put(1, 1, control_block(2))
        board:put(2, 1, cnot_x_block(1))
        cursor.x = 1
        cursor.y = 1

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      -- X-[C ]
      it("CNOT を右に移動", function()
        board:put(1, 1, cnot_x_block(2))
        board:put(2, 1, control_block(1))
        cursor.x = 2
        cursor.y = 1

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)


      -- [  X]-C
      --  X-C  ■
      it("上の X-C を左にずらす (step 1)", function()
        board:put(5, 2, cnot_x_block(6))
        board:put(6, 2, control_block(5))
        board:put(4, 1, cnot_x_block(5))
        board:put(5, 1, control_block(4))
        board:put(6, 1, block_class("t"))
        cursor.x = 4
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --  X[--C]
      --  X-C ■
      it("上の X-C を左にずらす (step 2)", function()
        board:put(4, 2, cnot_x_block(6))
        board:put(6, 2, control_block(4))
        board:put(4, 1, cnot_x_block(5))
        board:put(5, 1, control_block(4))
        board:put(6, 1, block_class("t"))
        cursor.x = 5
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --  X-C  ■
      -- [  X]-C
      it("下の X-C を左にずらす (step 1)", function()
        board:put(4, 2, cnot_x_block(5))
        board:put(5, 2, control_block(4))
        board:put(6, 2, block_class("t"))
        board:put(5, 1, cnot_x_block(6))
        board:put(6, 1, control_block(5))
        cursor.x = 4
        cursor.y = 1

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --  X-C ■
      --  X[--C]
      it("下の X-C を左にずらす (step 2)", function()
        board:put(4, 2, cnot_x_block(5))
        board:put(5, 2, control_block(4))
        board:put(6, 2, block_class("t"))
        board:put(4, 1, cnot_x_block(6))
        board:put(6, 1, control_block(4))
        cursor.x = 5
        cursor.y = 1

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)
    end)

    describe('ブロックをならす', function()
      -- [T  ]
      --  X _ _ _ _ _
      it("左壁ぎわのブロックを右に落とす", function()
        board:put(1, 2, block_class("t"))
        board:put(1, 1, block_class("x"))
        cursor.x = 1
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --        [  T]
      -- _ _ _ _ _ X
      it("右壁ぎわのブロックを左に落とす", function()
        board:put(6, 2, block_class("t"))
        board:put(6, 1, block_class("x"))
        cursor.x = 5
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --   [T  ]
      --  X X _ _ _ _
      it("ブロックを右に落とす", function()
        board:put(2, 2, block_class("t"))
        board:put(1, 1, block_class("x"))
        board:put(2, 1, block_class("x"))
        cursor.x = 2
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --       [  T]
      --  _ _ _ _ X X
      it("ブロックを左に落とす", function()
        board:put(5, 2, block_class("t"))
        board:put(5, 1, block_class("x"))
        board:put(6, 1, block_class("x"))
        cursor.x = 4
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      -- [  T]
      --  X X _ _ _ _
      it("カーソルを 1 つ右に動かしてから、ブロックを右に落とす", function()
        board:put(2, 2, block_class("t"))
        board:put(1, 1, block_class("x"))
        board:put(2, 1, block_class("x"))
        cursor.x = 1
        cursor.y = 2

        qpu:update()

        assert.are_equal(6, #qpu.commands)
        assert.are_equal("right", qpu.commands[1])
        assert.are_equal("x", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
        assert.are_equal("sleep", qpu.commands[6])
      end)

      --         [T  ]
      --  _ _ _ _ X X
      it("カーソルを 1 つ左に動かしてから、ブロックを左に落とす", function()
        board:put(2, 2, block_class("t"))
        board:put(2, 1, block_class("x"))
        board:put(3, 1, block_class("x"))
        cursor.x = 2
        cursor.y = 2

        qpu:update()

        assert.are_equal(6, #qpu.commands)
        assert.are_equal("left", qpu.commands[1])
        assert.are_equal("x", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
        assert.are_equal("sleep", qpu.commands[6])
      end)

      --     [T  ]
      --  _ _ X X _ _
      it("カーソルを 1 つ左に動かしてから、ブロックを左に落とす", function()
        board:put(3, 2, block_class("t"))
        board:put(3, 1, block_class("x"))
        board:put(4, 1, block_class("x"))
        cursor.x = 3
        cursor.y = 2

        qpu:update()

        assert.are_equal(6, #qpu.commands)
        assert.are_equal("left", qpu.commands[1])
        assert.are_equal("x", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
        assert.are_equal("sleep", qpu.commands[6])
      end)

      --     [  T]
      --  _ _ X X _ _
      it("カーソルを 1 つ右に動かしてから、ブロックを右に落とす", function()
        board:put(4, 2, block_class("t"))
        board:put(3, 1, block_class("x"))
        board:put(4, 1, block_class("x"))
        cursor.x = 3
        cursor.y = 2

        qpu:update()

        assert.are_equal(6, #qpu.commands)
        assert.are_equal("right", qpu.commands[1])
        assert.are_equal("x", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
        assert.are_equal("sleep", qpu.commands[6])
      end)
    end)

    describe('ブロックをマッチさせて消す', function()
      -- [T  ]
      --  X T X X X X
      it("右に動かしてマッチ", function()
        board:put(1, 2, block_class("t"))
        board:put(1, 1, block_class("x"))
        board:put(2, 1, block_class("t"))
        board:put(3, 1, block_class("x"))
        board:put(4, 1, block_class("x"))
        board:put(5, 1, block_class("x"))
        board:put(6, 1, block_class("x"))
        cursor.x = 1
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --         [  T]
      --  X X X X T X
      it("左に動かしてマッチ", function()
        board:put(6, 2, block_class("t"))
        board:put(1, 1, block_class("x"))
        board:put(2, 1, block_class("x"))
        board:put(3, 1, block_class("x"))
        board:put(4, 1, block_class("x"))
        board:put(5, 1, block_class("t"))
        board:put(6, 1, block_class("x"))
        cursor.x = 5
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --   [T  ]
      --  X X T X X X
      it("右に動かしてマッチ", function()
        board:put(2, 2, block_class("t"))
        board:put(1, 1, block_class("x"))
        board:put(2, 1, block_class("x"))
        board:put(3, 1, block_class("t"))
        board:put(4, 1, block_class("x"))
        board:put(5, 1, block_class("x"))
        board:put(6, 1, block_class("x"))
        cursor.x = 2
        cursor.y = 2

        qpu:update()

        assert.are_equal(5, #qpu.commands)
        assert.are_equal("x", qpu.commands[1])
        assert.are_equal("sleep", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
      end)

      --         [T  ]
      --  X X X T X X
      it("左に動かしてマッチ", function()
        board:put(5, 2, block_class("t"))
        board:put(1, 1, block_class("x"))
        board:put(2, 1, block_class("x"))
        board:put(3, 1, block_class("x"))
        board:put(4, 1, block_class("t"))
        board:put(5, 1, block_class("x"))
        board:put(6, 1, block_class("X"))
        cursor.x = 5
        cursor.y = 2

        qpu:update()

        assert.are_equal(6, #qpu.commands)
        assert.are_equal("left", qpu.commands[1])
        assert.are_equal("x", qpu.commands[2])
        assert.are_equal("sleep", qpu.commands[3])
        assert.are_equal("sleep", qpu.commands[4])
        assert.are_equal("sleep", qpu.commands[5])
        assert.are_equal("sleep", qpu.commands[6])
      end)
    end)

    -- -- ボードが次のようになっているとき、
    -- -- T を左に動かしてマッチ
    -- --
    -- --  H[T  ]
    -- --  T X Y Y Y Y
    -- it("左に動かしてマッチ (他のブロックとの入れ替えあり)", function()
    --   board:put(1, 2, block_class("h"))
    --   board:put(2, 2, block_class("t"))
    --   board:put(1, 1, block_class("t"))
    --   board:put(2, 1, block_class("x"))
    --   board:put(3, 1, block_class("y"))
    --   board:put(4, 1, block_class("y"))
    --   board:put(5, 1, block_class("y"))
    --   board:put(6, 1, block_class("y"))
    --   cursor.x = 2
    --   cursor.y = 2

    --   qpu:update()

    --   assert.are_equal(6, #qpu.commands)
    --   assert.are_equal("left", qpu.commands[1])
    --   assert.are_equal("x", qpu.commands[2])
    --   assert.are_equal("sleep", qpu.commands[3])
    --   assert.are_equal("sleep", qpu.commands[4])
    --   assert.are_equal("sleep", qpu.commands[5])
    --   assert.are_equal("sleep", qpu.commands[6])
    -- end)

    -- -- ボードが次のようになっているとき、
    -- -- T を右に動かしてマッチ
    -- --
    -- --         [T H]
    -- --  _ _ _ X X T
    -- it("右に動かしてマッチ (入れ替えあり)", function()
    --   board:put(5, 2, block_class("t"))
    --   board:put(6, 2, block_class("h"))
    --   board:put(1, 1, block_class("x"))
    --   board:put(2, 1, block_class("x"))
    --   board:put(3, 1, block_class("x"))
    --   board:put(4, 1, block_class("x"))
    --   board:put(5, 1, block_class("x"))
    --   board:put(6, 1, block_class("t"))
    --   cursor.x = 5
    --   cursor.y = 2

    --   qpu:update()

    --   -- assert.are_equal(5, #qpu.commands)
    --   assert.are_equal("x", qpu.commands[1])
    --   assert.are_equal("sleep", qpu.commands[2])
    --   assert.are_equal("sleep", qpu.commands[3])
    --   assert.are_equal("sleep", qpu.commands[4])
    --   assert.are_equal("sleep", qpu.commands[5])
    -- end)

    -- ボードが次のようになっているとき、
    -- H を左に 1 マス動かす
    --
    --   [  H]
    --    T T T T T
    it("左に 1 マス動かす", function()
      board:put(3, 2, block_class("h"))
      board:put(2, 1, block_class("t"))
      board:put(3, 1, block_class("t"))
      board:put(4, 1, block_class("t"))
      board:put(5, 1, block_class("t"))
      board:put(6, 1, block_class("t"))
      cursor.x = 2
      cursor.y = 2

      qpu:update()

      assert.are_equal(5, #qpu.commands)
      assert.are_equal("x", qpu.commands[1])
      assert.are_equal("sleep", qpu.commands[2])
      assert.are_equal("sleep", qpu.commands[3])
      assert.are_equal("sleep", qpu.commands[4])
      assert.are_equal("sleep", qpu.commands[5])
    end)

    -- -- ボードが次のようになっているとき、
    -- -- H を左に 1 マス動かす
    -- --
    -- --   [  H]
    -- --  H T T T T T
    -- it("左に 1 マス動かす", function()
    --   board:put(3, 2, block_class("h"))
    --   board:put(1, 1, block_class("h"))
    --   board:put(2, 1, block_class("t"))
    --   board:put(3, 1, block_class("t"))
    --   board:put(4, 1, block_class("t"))
    --   board:put(5, 1, block_class("t"))
    --   board:put(6, 1, block_class("t"))
    --   cursor.x = 2
    --   cursor.y = 2

    --   qpu:update()

    --   assert.are_equal(5, #qpu.commands)
    --   assert.are_equal("x", qpu.commands[1])
    --   assert.are_equal("sleep", qpu.commands[2])
    --   assert.are_equal("sleep", qpu.commands[3])
    --   assert.are_equal("sleep", qpu.commands[4])
    --   assert.are_equal("sleep", qpu.commands[5])
    -- end)

    -- -- ボードが次のようになっているとき、
    -- -- H を左に 1 マス動かす
    -- --
    -- --  H g g g g g
    -- -- [  H]
    -- it("左に 1 マス動かしてマッチ", function()
    --   board:put(1, 2, block_class("h"))
    --   board:put(2, 2, garbage_block(5, 1))
    --   board:put(2, 1, block_class("h"))
    --   cursor.x = 1
    --   cursor.y = 1

    --   qpu:update()

    --   assert.are_equal(5, #qpu.commands)
    --   assert.are_equal("x", qpu.commands[1])
    --   assert.are_equal("sleep", qpu.commands[2])
    --   assert.are_equal("sleep", qpu.commands[3])
    --   assert.are_equal("sleep", qpu.commands[4])
    --   assert.are_equal("sleep", qpu.commands[5])
    -- end)
  end)
end)
