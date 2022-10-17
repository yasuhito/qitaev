require("engine/test/bustedhelper")

local particle = require("particle")

describe('particle', function()
  describe('constructor', function()
    it("x, y, color を指定してパーティクルを作ることができる", function()
      assert.has_no.errors(function()
        particle(1, 1, 1)
      end)
    end)
  end)

  describe('.update', function()
    it("すべてのパーティクル状態を更新する", function()
      particle(1, 1, 1)

      assert.has_no.errors(function()
        particle.update()
      end)
    end)
  end)

  describe('.render', function()
    it("すべてのパーティクルを描画する", function()
      particle(1, 1, 1)

      assert.has_no.errors(function()
        particle.render()
      end)
    end)
  end)
end)