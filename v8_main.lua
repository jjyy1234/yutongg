-- v8_main.lua — YUTONG v8 主入口
-- 加载白名单、Kick 非授权用户、loadstring 各模块

local BASE = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/"
local function load(f)
    loadstring(game:HttpGet(BASE..f, true))()
end

load("v8_globals.lua")
if not _G.V8.authorized then return end
load("v8_fly.lua")
load("v8_esp.lua")
load("v8_teleport.lua")
load("v8_buy.lua")
load("v8_wood.lua")
load("v8_other.lua")
load("v8_debug.lua")
