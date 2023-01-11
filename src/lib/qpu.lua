---@diagnostic disable: lowercase-global, global-in-nil-env

require("lib/block")

local function _is_empty(board, block_x, block_y)
  if block_x < 1 or board.cols < block_x or board.rows < block_y then
    return false
  end

  return board.blocks[block_y][block_x]:is_idle() and board:is_block_empty(block_x, block_y)
end

local function _is_match(board, block_x, block_y, block)
  if board.rows < block_y then
    return false
  end

  local other_block = board.blocks[block_y][block_x]
  return other_block.type == block.type and other_block:is_idle()
end

local function _is_swappable(board, block_x, block_y)
  if block_x < 1 or board.cols < block_x then
    return false
  end

  local block = board.blocks[block_y][block_x]
  return block:is_idle() and (board:is_block_empty(block_x, block_y) or block:is_single_block())
end

-- 新しい QPU プレーヤーを返す
--
-- level 3: easy, 2: normal, 1: hard
function create_qpu(board, _level)
  local qpu = setmetatable({
    board = board,
    cursor = board and board.cursor or nil,
    level = _level or 2,

    init = function(_ENV)
      -- raise はテスト用で、false にすると QPU プレーヤーは x を押さない
      -- 通常は常に true
      score, commands, sleep, raise = 0, {}, true, true
    end,

    update = function(_ENV)
      left, right, up, down, x, o = false, false, false, false, false, false

      local next_command = commands[1]
      if next_command then
        del(commands, next_command)
        _ENV[next_command] = true
      else
        if raise and board.top_block_y < 7 then
          add(commands, "o")
          add_sleep_command(_ENV, 3)
        else
          return for_all_reducible_blocks(_ENV, _reduce_cnot) or
              for_all_reducible_blocks(_ENV, _flatten_block) or
              board.contains_garbage_match_block or
              for_all_reducible_blocks(_ENV, _reduce_single_block)
        end
      end
    end,

    _flatten_block = function(_ENV, each, each_x, each_y)
      -- 二列目より上のブロックについて、空のブロックがあればそこに落とす
      if 1 < each_y and each:is_single_block() then
        if find_left_and_right(_ENV, _is_empty, each, false, true) then
          return true
        end
      end
    end,

    _reduce_single_block = function(_ENV, each, each_x, each_y)
      if each:is_single_block() then
        -- 下の行とマッチするか走査
        if each_y > 1 then
          if find_left_and_right(_ENV, _is_match, each) then
            return true
          end
        end

        -- 上の行とマッチするか走査
        if each_y < board.rows then
          if find_left_and_right(_ENV, _is_match, each, true) then
            return true
          end
        end
      end
    end,

    _reduce_cnot = function(_ENV, each, each_x, each_y)
      local upper_block = each_y < board.rows and board:reducible_block_at(each_x, each_y + 1) or block_class("i")
      local lower_block = each_y > 1 and board:reducible_block_at(each_x, each_y - 1) or block_class("i")

      if not each:is_single_block() then
        -- d-2. 上の X-C を左にずらす
        --
        -- [X--]-C
        --  X-C  ■
        if each.type == "cnot_x" and each.other_x == each_x + 2 and
            lower_block.type == "cnot_x" and
            lower_block.other_x == each_x + 1 then
          move_and_swap(_ENV, each_x + 1, each_y)
          return true
        end

        -- e-2. 下の X-C を左にずらす
        --
        --  X-C  ■
        -- [X--]-C
        if each.type == "cnot_x" and each.other_x == each_x + 2 and
            upper_block.type == "cnot_x" and
            upper_block.other_x == each_x + 1 then
          move_and_swap(_ENV, each_x + 1, each_y)
          return true
        end

        -- a. CNOT を縮める
        --
        --   [X-]--C
        --   [C-]--X
        if (each.type == "cnot_x" or each.type == "control") and each_x + 1 < each.other_x then
          move_and_swap(_ENV, each_x, each_y)
          return true
        end

        -- b. CNOT を同じ方向 (右がC) にそろえる
        --
        --   C-X --> X-C
        --   X-C --> X-C
        if each.type == "control" and each.other_x == each_x + 1 then
          move_and_swap(_ENV, each_x, each_y)
          return true
        end

        -- c. CNOT を右に移動
        --
        --   X-[C ]
        if each_x < board.cols and
            each.type == "control" and each.other_x < each_x and _is_empty(board, each_x + 1, each_y) then
          move_and_swap(_ENV, each_x, each_y)
          return true
        end

        -- d-1. 上の X-C を左にずらす
        --
        -- [  X]-C
        --  X-C  ■
        if each_x > 1 and each_y > 1 and
            _is_empty(board, each_x - 1, each_y) and each.type == "cnot_x" and each.other_x == each_x + 1 and
            lower_block.type == "control" and
            lower_block.other_x == each_x - 1 then
          move_and_swap(_ENV, each_x - 1, each_y)
          return true
        end

        -- e. 下の X-C を左にずらす
        --
        --  X-C  ■
        -- [  X]-C
        if each_x > 1 and
            _is_empty(board, each_x - 1, each_y) and each.type == "cnot_x" and each.other_x == each_x + 1 and
            upper_block.type == "control" and
            upper_block.other_x == each_x - 1 then
          move_and_swap(_ENV, each_x - 1, each_y)
          return true
        end
      end
    end,

    find_left_and_right = function(_ENV, f, block, upper)
      local block_x, block_y, other_row_block_y = block.x, block.y, block.y + (upper and 1 or -1)
      local find_left, find_right = true, true

      for dx = 1, board.cols - 1 do
        if not (find_left or find_right) then
          return false
        end

        if find_left then
          if _is_swappable(board, block_x - dx, block_y) then
            if f(board, block_x - dx, other_row_block_y, block) then
              move_and_swap(_ENV, block_x - 1, block_y)
              return true
            end
          else
            find_left = false
          end
        end

        if find_right then
          if _is_empty(board, block_x + dx, block_y) then
            if f(board, block_x + dx, other_row_block_y, block) then
              move_and_swap(_ENV, block_x, block_y)
              return true
            end
          else
            find_right = false
          end
        end
      end

      return false
    end,

    move_and_swap = function(_ENV, block_x, block_y)
      add_move_command(_ENV, block_x < cursor.x and "left" or "right", abs(cursor.x - block_x))
      add_move_command(_ENV, block_y < cursor.y and "down" or "up", abs(cursor.y - block_y))
      add_swap_command(_ENV)
    end,

    add_move_command = function(_ENV, direction, count)
      for i = 1, count do
        add(commands, direction)

        if sleep then
          add_sleep_command(_ENV, ceil_rnd(level * 8))
        end
      end
    end,

    add_swap_command = function(_ENV)
      add(commands, "x")
      -- NOTE: ブロックの入れ替えコマンドを送った後は、
      -- 必ず次のように入れ替え完了するまで sleep する。
      -- これをしないと「左に連続して移動して落とす」などの
      -- 操作がうまく行かない。
      add_sleep_command(_ENV, 4)
    end,

    add_sleep_command = function(_ENV, count)
      for i = 1, count do
        add(commands, "sleep")
      end
    end,

    for_all_reducible_blocks = function(_ENV, f)
      for each_y = 12, 1, -1 do
        for each_x = 1, board.cols do
          local each = board.reducible_blocks[each_y][each_x]
          if each and f(_ENV, each, each_x, each_y) then
            return true
          end
        end
      end

      return false
    end
  }, { __index = _ENV })

  qpu:init()

  return qpu
end
