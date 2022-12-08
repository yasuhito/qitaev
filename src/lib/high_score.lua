local high_score = new_class()

function high_score:_init(id)
   cartdata(id)
end

function high_score:get()
  return dget(0) or 0
end

function high_score:put(score)
  if dget(0) < score then
    dset(0, score)
    return true
  end

  return false
end

return high_score