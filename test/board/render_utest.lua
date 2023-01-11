require("engine/test/bustedhelper")
require("test/test_helper")

require("lib/block")
require("lib/board")
require("lib/garbage_block")

describe('board #solo', function()
  local board

  before_each(function()
    board = board_class()
  end)

  describe('render', function()
    it("空の盤面を表示する", function()
      assert.has_no_errors(function() board:render() end)
    end)
  end)
end)
