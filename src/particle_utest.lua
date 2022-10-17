require("engine/test/bustedhelper")
require("particle")

describe('particle', function()
  describe('constructor', function()
    it("x, y, color を指定してパーティクルを作ることができる", function()
      assert.has_no.errors(function()
        create_particle(1, 1, 1)
      end)
    end)
  end)

  describe('.update', function()
    it("すべてのパーティクル状態を更新する", function()
      create_particle(1, 1, 1)

      assert.has_no.errors(function()
        update_particles()
      end)
    end)
  end)

  describe('.render', function()
    it("すべてのパーティクルを描画する", function()
      create_particle(1, 1, 1)

      assert.has_no.errors(function()
        render_particles()
      end)
    end)
  end)
end)
