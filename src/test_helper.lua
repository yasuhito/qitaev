require("gate_class")

function wait_swap_to_finish(board)
  for _i = 1, 1 + gate_swap_animation_frame_count do
    board:update()
  end
end

function i_gate()
  local i = gate_class("i")
  i.type_string = "_"
  return i
end

function h_gate()
  return gate_class("h")
end

function x_gate()
  return gate_class("x")
end

function y_gate()
  return gate_class("y")
end

function z_gate()
  return gate_class("z")
end

function s_gate()
  return gate_class("s")
end

function t_gate()
  return gate_class("t")
end

function control_gate(other_x)
  local control = gate_class('control')
  control.other_x = other_x
  return control
end

function cnot_x_gate(other_x)
  local cnot_x = gate_class('cnot_x')
  cnot_x.other_x = other_x
  return cnot_x
end

function swap_gate(other_x)
  local swap = gate_class('swap')
  swap.other_x = other_x
  swap.type_string = "S"
  return swap
end

function garbage_match_gate()
  return gate_class("!")
end
