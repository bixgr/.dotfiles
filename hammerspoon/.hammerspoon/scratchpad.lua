-- scratchpad.lua
-- A toggleable floating text box. Text autosaves to a plain file.

local M = {}

local notePath = os.getenv("HOME") .. "/.hammerspoon/scratchpad.txt"
local view = nil        -- the window, created once and reused
local prevWin = nil     -- whatever window you were in before opening

-- File helpers ---------------------------------------------------------

local function readNote()
  local f = io.open(notePath, "r")
  if not f then return "" end
  local text = f:read("*a")
  f:close()
  return text
end

local function writeNote(text)
  local f = io.open(notePath, "w")
  if f then
    f:write(text)
    f:close()
  end
end

-- Messages coming FROM the page (JavaScript) back INTO Lua ------------

local controller = hs.webview.usercontent.new("pad")
controller:setCallback(function(msg)
  local body = msg.body
  if body.type == "save" then
    writeNote(body.text)
  elseif body.type == "hide" then
    M.hide()
  end
end)

-- The page itself -------------------------------------------------------

local function buildHTML()
  -- JSON-encode the saved text so quotes and newlines can't break the page
  local initial = hs.json.encode({ text = readNote() })
  return [[
<!doctype html>
<html><head><meta charset="utf-8"><style>
  :root { --bg: #fdfdfb; --fg: #1d1d1f; }
  @media (prefers-color-scheme: dark) { :root { --bg: #1e1e1e; --fg: #e8e8e8; } }
  html, body { margin: 0; height: 100%; background: var(--bg); }
  textarea {
    box-sizing: border-box; width: 100%; height: 100%;
    border: 0; outline: 0; resize: none; padding: 16px;
    background: var(--bg); color: var(--fg);
    font: 14px/1.5 -apple-system, BlinkMacSystemFont, sans-serif;
  }
</style></head><body>
<textarea id="t" spellcheck="false" placeholder="Type anything"></textarea>
<script>
  const t = document.getElementById("t");
  const send = (m) => window.webkit.messageHandlers.pad.postMessage(m);
  t.value = ]] .. initial .. [[.text;

  let timer;
  t.addEventListener("input", () => {
    clearTimeout(timer);
    timer = setTimeout(() => send({ type: "save", text: t.value }), 300);
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") send({ type: "hide" });
  });
</script>
</body></html>]]
end

local function create()
  local screen = hs.screen.mainScreen():frame()
  local w, h = 480, 360
  local rect = {
    x = screen.x + (screen.w - w) / 2,
    y = screen.y + (screen.h - h) / 2,
    w = w, h = h,
  }

  view = hs.webview.new(rect, {}, controller)
    :windowStyle({ "titled", "closable", "resizable" })
    :windowTitle("Scratchpad")
    :level(hs.drawing.windowLevels.floating)  -- stays above other windows
    :allowTextEntry(true)                     -- without this you can't type
    :deleteOnClose(false)
    :html(buildHTML())
end

-- Public functions ------------------------------------------------------

function M.show()
  if not view then create() end
  prevWin = hs.window.focusedWindow()
  view:show()
  local win = view:hswindow()
  if win then win:focus() end
  view:evaluateJavaScript("document.getElementById('t').focus()")
end

function M.hide()
  if not view then return end
  view:hide()
  if prevWin then prevWin:focus() end
end

function M.toggle()
  if view and view:isVisible() then
    M.hide()
  else
    M.show()
  end
end

return M
