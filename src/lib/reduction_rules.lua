-- map function
local function transform(t, func)
  local transformed_t = {}
  for key, value in pairs(t) do
    transformed_t[key] = func(value)
  end
  return transformed_t
end

-- 注意: ルールの行数を昇り順にならべておくことで、
-- マッチする時に途中で探索を切り上げることができるようにする
local reduction_rules = {
  h = {
    -- H          I
    -- H  ----->  I
    "h\nh|,,\n,-1,|2|",

    -- H          I
    -- X          I
    -- H  ----->  Z
    "h\nx\nh|,,\n,-1,\n,-2,z|2|3",

    -- H          I
    -- Z          I
    -- H  ----->  X
    "h\nz\nh|,,\n,-1,\n,-2,x|3|3",

    -- H H          I I
    -- C-X  ----->  X-C
    -- H H          I I
    --
    -- H H          I I
    -- X-C  ----->  C-X
    -- H H          I I
    "h,h\ncontrol,cnot_x\nh,h|,,\ntrue,,\n,-1,cnot_x\ntrue,-1,control\n,-2,\ntrue,-2,|6|10",

    -- H            I
    -- S-S  ----->  S-S
    --   H            I
    --
    --   H            I
    -- S-S  ----->  S-S
    -- H            I
    "h\nswap,swap\n?,h|,,\ntrue,-2,|2|5",

    -- H Z          H I
    -- X-C  ----->  X-C
    -- H Z          H I
    --
    -- Z H          I H
    -- C-X  ----->  X-C
    -- Z H          I H
    "h,z\ncnot_x,control\nh,z|true,,\ntrue,-2,|2|10",

    -- H            I
    -- X            Z
    -- S-S  ----->  S-S
    --   H            I
    --
    --   H            I
    --   X            Z
    -- S-S  ----->  S-S
    -- H            I
    "h\nx\nswap,swap\n?,h|,,\n,-1,z\ntrue,-3,|3|7",

    -- H            Z
    -- S-S  ----->  S-S
    --   X            I
    --   H            I
    --
    --   H            Z
    -- S-S  ----->  S-S
    -- X            I
    -- H            I
    "h\nswap,swap\n?,x\n?,h|,,z\ntrue,-2,\ntrue,-3,|3|7",

    -- H            I
    -- Z            X
    -- S-S  ----->  S-S
    --   H            I
    --
    --   H            I
    --   Z            X
    -- S-S  ----->  S-S
    -- H            I
    "h\nz\nswap,swap\n?,h|,,\n,-1,x\ntrue,-3,|3|7",

    -- H            X
    -- S-S  ----->  S-S
    --   Z            I
    --   H            I
    --
    --   H            X
    -- S-S  ----->  S-S
    -- Z            I
    -- H            I
    "h\nswap,swap\n?,z\n?,h|,,x\ntrue,-2,\ntrue,-3,|3|7",
  },

  x = {
    -- X          I
    -- X  ----->  I
    "x\nx|,,\n,-1,|2|",

    -- X          I
    -- Z  ----->  Y
    "x\nz|,,\n,-1,y|2|2",

    -- X X          I I
    -- C-X  ----->  C-X
    -- X            I
    --
    -- X X          I I
    -- X-C  ----->  X-C
    --   X            I
    "x,x\ncontrol,cnot_x\nx|,,\ntrue,,\n,-2,|3|8",

    -- X            I
    -- X-C  ----->  X-C
    -- X            I
    --
    --   X            I
    -- C-X  ----->  C-X
    --   X            I
    "x\ncnot_x,control\nx|,,\n,-2,|2|6",

    -- X            I
    -- S-S  ----->  S-S
    --   X            I
    --
    --   X            I
    -- S-S  ----->  S-S
    -- X            I
    "x\nswap,swap\n?,x|,,\ntrue,-2,|2|5",

    -- X            Y
    -- S-S  ----->  S-S
    --   Z            I
    --
    --   X            Y
    -- S-S  ----->  S-S
    -- Z            I
    "x\nswap,swap\n?,z|,,y\ntrue,-2,|2|6",

    -- X            I
    -- H Z          H I
    -- X-C  ----->  X-C
    -- H            H
    -- X            I
    --
    --   X            I
    -- Z H          I H
    -- C-X  ----->  C-X
    --   H            H
    --   X            I
    "x\nh,z\ncnot_x,control\nh\nx|,,\ntrue,-1,\n,-4,|3|10",
  },

  y = {
    -- Y          I
    -- Y  ----->  I
    "y\ny|,,\n,-1,|2|",

    -- Y            I
    -- S-S  ----->  S-S
    --   Y            I
    --
    --   Y            I
    -- S-S  ----->  S-S
    -- Y            I
    "y\nswap,swap\n?,y|,,\ntrue,-2,|2|5",
  },

  z = {
    -- Z          I
    -- Z  ----->  I
    "z\nz|,,\n,-1,|2|",

    -- Z          I
    -- X  ----->  Y
    "z\nx|,,\n,-1,y|2|2",

    -- Z Z          I I
    -- C-X  ----->  C-X
    --   Z            I
    --
    -- Z Z          I I
    -- X-C  ----->  X-C
    -- Z            I
    "z,z\ncontrol,cnot_x\n?,z|,,\ntrue,,\ntrue,-2,|3|8",

    -- Z            I
    -- C-X  ----->  C-X
    -- Z            I
    --
    --   Z            I
    -- X-C  ----->  X-C
    --   Z            I
    "z\ncontrol,cnot_x\nz|,,\n,-2,|2|6",

    -- Z            I
    -- S-S  ----->  S-S
    --   Z            I
    --
    --   Z            I
    -- S-S  ----->  S-S
    -- Z            I
    "z\nswap,swap\n?,z|,,\ntrue,-2,|2|5",

    -- Z            I
    -- H X          H I
    -- X-C  ----->  X-C
    -- H X          H I
    --
    --   Z            I
    -- X H          I H
    -- C-X  ----->  C-X
    -- X H          I H
    "z\nh,x\ncnot_x,control\nh,x|,,\ntrue,-1,\ntrue,-3,|3|10",

    -- Z            I
    -- H            H
    -- X-C  ----->  X-C
    -- H            H
    -- Z            I
    --
    --   Z            I
    --   H            H
    -- C-X  ----->  C-X
    --   H            H
    --   Z            I
    "z\nh\ncnot_x,control\nh\nz|,,\n,-4,|2|10"
  },

  s = {
    -- S          I
    -- S  ----->  Z
    "s\ns|,,\n,-1,z|2|",

    -- S          I
    -- Z          I
    -- S  ----->  X
    "s\nz\ns|,,\n,-1,\n,-2,z|3|3",

    -- S            Z
    -- S-S  ----->  S-S
    --   S            I
    --
    --   S            Z
    -- S-S  ----->  S-S
    -- S            I
    "s\nswap,swap\n?,s|,,z\ntrue,-2,|2|5",

    -- S            I
    -- Z            Z
    -- S-S  ----->  S-S
    --   S            I
    --
    --   S            I
    --   Z            Z
    -- S-S  ----->  S-S
    -- S            I
    "s\nz\nswap,swap\n?,s|,,\n,-1,z\ntrue,-3,|3|7",

    -- S            Z
    -- S-S  ----->  S-S
    --   Z            I
    --   S            I
    --
    --   S            Z
    -- S-S  ----->  S-S
    -- Z            I
    -- S            I
    "s\nswap,swap\n?,z\n?,s|,,z\ntrue,-2,\ntrue,-3,|3|7"
  },

  t = {
    -- T          I
    -- T  ----->  S
    "t\nt|,,\n,-1,s|2|",

    -- T          I
    -- S          I
    -- T  ----->  Z
    "t\ns\nt|,,\n,-1,\n,-2,z|3|3",

    -- T            S
    -- S-S  ----->  S-S
    --   T            I
    --
    --   T            S
    -- S-S  ----->  S-S
    -- T            I
    "t\nswap,swap\n?,t|,,s\ntrue,-2,|2|5",

    -- T          I
    -- Z          I
    -- S          I
    -- T  ----->  I
    "t\nz\ns\nt|,,\n,-1,\n,-2,\n,-3,|4|4",

    -- T          I
    -- S          I
    -- Z          I
    -- T  ----->  I
    "t\ns\nz\nt|,,\n,-1,\n,-2,\n,-3,|4|4",

    -- T            I
    -- S            Z
    -- S-S  ----->  S-S
    --   T            I
    --
    --   T            I
    --   S            Z
    -- S-S  ----->  S-S
    -- S            I
    "t\ns\nswap,swap\n?,t|,,\n,-1,z\ntrue,-3,|3|7",

    -- T            Z
    -- S-S  ----->  S-S
    --   S            I
    --   T            I
    --
    --   T            Z
    -- S-S  ----->  S-S
    -- S            I
    -- T            I
    "t\nswap,swap\n?,s\n?,t|,,z\ntrue,-2,\ntrue,-3,|3|7",

    -- T            I
    -- S-S  ----->  S-S
    --   Z            I
    --   S            I
    --   T            I
    --
    --   T            I
    -- S-S  ----->  S-S
    -- Z            I
    -- S            I
    -- T            I
    "t\nswap,swap\n?,z\n?,s\n?,t|,,\ntrue,-2,\ntrue,-3,\ntrue,-4,|4|8",

    -- T            I
    -- S-S  ----->  S-S
    --   S            I
    --   Z            I
    --   T            I
    --
    --   T            I
    -- S-S  ----->  S-S
    -- S            I
    -- Z            I
    -- T            I
    "t\nswap,swap\n?,s\n?,z\n?,t|,,\ntrue,-2,\ntrue,-3,\ntrue,-4,|4|8"
  },

  control = {
    -- C-X          I I
    -- X-C          I I
    -- C-X  ----->  S-S
    --
    -- X-C          I I
    -- C-X          I I
    -- X-C  ----->  S-S
    -- "control,cnot_x\ncnot_x,control\ncontrol,cnot_x|,,\ntrue,,\n,1,\ntrue,1,\n,2,swap\ntrue,2,swap|6|10",

    --  C-X          I I
    --  S-S  ----->  S-S
    --  X-C          I I
    "control,cnot_x\nswap,swap\ncnot_x,control|,,\ntrue,,\n,-2,\ntrue,-2,|4|10"
  },

  cnot_x = {
    -- X-C          I I
    -- X-C  ----->  I I
    --
    -- C-X          I I
    -- C-X  ----->  I I
    "cnot_x,control\ncnot_x,control|,,\ntrue,,\n,-1,\ntrue,-1,|4|5",

    -- X-C          I I
    -- C-X          I I
    -- X-C  ----->  S-S
    --
    -- C-X          I I
    -- X-C          I I
    -- C-X  ----->  S-S
    "cnot_x,control\ncontrol,cnot_x\ncnot_x,control|,,\ntrue,,\n,-1,\ntrue,-1,\n,-2,swap\ntrue,-2,swap|6|10",
  },

  swap = {
    -- S-S          I
    -- S-S  ----->  I
    "swap,swap\nswap,swap|,,\ntrue,,\n,-1,\ntrue,-1,|4|30"
  }
}

for first_block, rules in pairs(reduction_rules) do
  for i, each in pairs(reduction_rules[first_block]) do
    local pattern, reduce_to, block_count, score = unpack(split(each, "|"))
    ---@diagnostic disable-next-line: assign-type-mismatch
    reduction_rules[first_block][i] = {
      transform(split(pattern, "\n"), split),
      transform(split(reduce_to, "\n"), function(to)
        local attrs = split(to)
        return {
          dx = attrs[1] ~= "",
          dy = attrs[2] == "" and nil or tonum(attrs[2]),
          block_type = attrs[3] == "" and 'i' or attrs[3]
        }
      end),
      tonum(block_count),
      tonum(score),
      each -- original string
    }
  end
end

return reduction_rules
