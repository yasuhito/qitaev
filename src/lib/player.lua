---@diagnostic disable: global-in-nil-env, lowercase-global

player_class = new_class()

function player_class._init(_ENV)
  init(_ENV)
end

function player_class.init(_ENV)
  score = 0
end

function player_class.update(_ENV)
  left, right, up, down, x, o = btnp(0), btnp(1), btnp(2), btnp(3), btnp(5), btn(4)
end
