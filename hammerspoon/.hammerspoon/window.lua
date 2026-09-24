local M = {}

hs.window.animationDuration = 0

local STEP = 0.06  -- fraction of screen added/removed per resize press

-- remember the frame a window had before we first touched it
local original = {}

local function remember(w)
  local id = w:id()
  if id and original[id] == nil then original[id] = w:frame() end
end

local function place(x, y, w, h)
  return function()
    local f = hs.window.focusedWindow()
    if not f then return end
    remember(f)
    f:move(hs.geometry.rect(x, y, w, h), nil, true, 0)
  end
end

local function scale(factor)
  return function()
    local f = hs.window.focusedWindow()
    if not f then return end
    remember(f)

    local frame  = f:frame()
    local screen = f:screen():frame()
    local dw, dh = screen.w * factor, screen.h * factor

    frame.x = frame.x - dw / 2
    frame.y = frame.y - dh / 2
    frame.w = frame.w + dw
    frame.h = frame.h + dh

    if frame.w < 200 or frame.h < 150 then return end
    if frame.w > screen.w then frame.w = screen.w end
    if frame.h > screen.h then frame.h = screen.h end
    if frame.x < screen.x then frame.x = screen.x end
    if frame.y < screen.y then frame.y = screen.y end
    if frame.x + frame.w > screen.x + screen.w then
      frame.x = screen.x + screen.w - frame.w
    end
    if frame.y + frame.h > screen.y + screen.h then
      frame.y = screen.y + screen.h - frame.h
    end

    f:setFrame(frame, 0)
  end
end

local function restore()
  local f = hs.window.focusedWindow()
  if not f then return end
  local id = f:id()
  if id and original[id] then
    f:setFrame(original[id], 0)
    original[id] = nil
  end
end

local function nextDisplay()
  local f = hs.window.focusedWindow()
  if f then f:moveToScreen(f:screen():next(), false, true, 0) end
end

-- ============================================================
-- BINDS: one line each. Add, remove, reorder freely.
-- ============================================================
M.binds = {
  -- halves
  { "w", place(0,   0,   1,   0.5) },  -- top
  { "s", place(0,   0.5, 1,   0.5) },  -- bottom
  { "a", place(0,   0,   0.5, 1  ) },  -- left
  { "d", place(0.5, 0,   0.5, 1  ) },  -- right

  -- place
  { "m", place(0,    0,    1,   1  ) },  -- maximize

  -- size
  { "q", scale(-STEP) }, -- or 9, 0, +
  { "e", scale( STEP) }, -- e for enlarge

  -- misc
  { "r", restore     },
  { "n", nextDisplay },
}

function M.apply(mods)
  for _, b in ipairs(M.binds) do
    local ok, err = pcall(hs.hotkey.bind, mods, b[1], b[2])
    if not ok then print("bind failed for " .. tostring(b[1]) .. ": " .. tostring(err)) end
  end
end

return M