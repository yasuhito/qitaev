local effect_set = new_class()

function effect_set:_init()
  self.all = {}
end

function effect_set:_add(f)
  local _ENV = setmetatable({}, { __index = _ENV })
  f(_ENV)
  add(self.all, _ENV)
end

function effect_set:update_all()
  foreach(self.all, function(each)
    self._update(each, self)
  end)
end

function effect_set:render_all()
  foreach(self.all, function(each)
    self._render(each, self)
  end)
  self:post_render_all()
end

function effect_set:post_render_all()
  -- NOP
end

return effect_set
