local hyper = {"cmd", "alt", "ctrl", "shift"}

require("window").apply(hyper)

-- reload on hyper + 8
hs.hotkey.bind(hyper, "8", hs.reload)

-- auto-reload when the config changes
local watchPath = hs.fs.symlinkAttributes(os.getenv("HOME") .. "/.hammerspoon", "target")
                  or (os.getenv("HOME") .. "/.hammerspoon")

configWatcher = hs.pathwatcher.new(watchPath, function(files)
  for _, f in ipairs(files) do
    if f:sub(-4) == ".lua" then hs.reload(); return end
  end
end):start()

-- these two lines load the scratchpad from scratchpad.lua
local scratchpad = require("scratchpad")
hs.hotkey.bind(hyper, "space", scratchpad.toggle)

hs.alert.show("hammerspoon loaded")