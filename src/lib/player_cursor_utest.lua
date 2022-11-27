require("engine/test/bustedhelper")
require("lib/board")
require("lib/player_cursor")

describe('player_cursor', function()
  local player_cursor

  before_each(function()
    player_cursor = create_player_cursor(create_board())
  end)

  describe('constructor', function()
    it('should be placed at x = 3, y = 6 by default', function()
      assert.are_equal(3, player_cursor.x)
      assert.are_equal(11, player_cursor.y)
    end)
  end)

  describe('move_left', function()
    it("should move left", function()
      player_cursor:move_left()

      assert.are_equal(2, player_cursor.x)
      assert.are_equal(11, player_cursor.y)
    end)

    it("should not move any further to the left when reaching the left edge", function()
      player_cursor:move_left() -- x = 2
      player_cursor:move_left() -- x = 1

      player_cursor:move_left()

      assert.are_equal(1, player_cursor.x)
      assert.are_equal(11, player_cursor.y)
    end)
  end)

  describe('move_right', function()
    it("should move right", function()
      player_cursor:move_right()

      assert.are_equal(4, player_cursor.x)
      assert.are_equal(11, player_cursor.y)
    end)

    it("should not move any further to the right when reaching the right edge", function()
      player_cursor:move_right() -- x = 4
      player_cursor:move_right() -- x = 5

      player_cursor:move_right()

      assert.are_equal(5, player_cursor.x)
      assert.are_equal(11, player_cursor.y)
    end)
  end)

  describe('move_up', function()
    it("should move up", function()
      player_cursor:move_up()

      assert.are_equal(3, player_cursor.x)
      assert.are_equal(10, player_cursor.y)
    end)

    it("should not move any upper when reaching the dead line", function()
      player_cursor:move_up() -- y = 10
      player_cursor:move_up() -- y = 9
      player_cursor:move_up() -- y = 8
      player_cursor:move_up() -- y = 7

      player_cursor:move_up()

      assert.are_equal(3, player_cursor.x)
      assert.are_equal(7, player_cursor.y)
    end)
  end)

  describe('move_down', function()
    it("should move down", function()
      player_cursor:move_down()

      assert.are_equal(3, player_cursor.x)
      assert.are_equal(12, player_cursor.y)
    end)

    it("should not move any further down when reaching the bottom", function()
      player_cursor:move_down() -- y = 7
      player_cursor:move_down() -- y = 8
      player_cursor:move_down() -- y = 9
      player_cursor:move_down() -- y = 10
      player_cursor:move_down() -- y = 11
      player_cursor:move_down() -- y = 12
      player_cursor:move_down() -- y = 13
      player_cursor:move_down() -- y = 14
      player_cursor:move_down() -- y = 15
      player_cursor:move_down() -- y = 16
      player_cursor:move_down() -- y = 17

      player_cursor:move_down()

      assert.are_equal(3, player_cursor.x)
      assert.are_equal(17, player_cursor.y)
    end)
  end)

  describe('update', function()
    it("should increment its tick", function()
      local tick = player_cursor._tick

      player_cursor:update()

      assert.are_equal(tick + 1, player_cursor._tick)
    end)
  end)

  describe("render", function()
    it("should render without errors", function()
      assert.has_no.errors(function() player_cursor:render() end)
    end)
  end)
end)