-- v8_main.lua — YUTONG v8 主入口
local BASE = "https://raw.githubusercontent.com/jjyy1234/yutongg/main/"
local function load(f)
    local ok, err = pcall(function()
        local src = game:HttpGet(BASE..f, true)
        local fn, lerr = loadstring(src)
        if fn then fn() else error("[v8] 语法错误 "..f.."\n"..tostring(lerr)) end
    end)
    if not ok then warn("[v8] 加载失败: "..f.." | "..tostring(err)) end
end

load("v8_globals.lua")
if not _G.V8 or not _G.V8.authorized then return end
load("v8_fly.lua")
load("v8_esp.lua")
load("v8_teleport.lua")
load("v8_buy.lua")
load("v8_wood.lua")
load("v8_other.lua")
load("v8_debug.lua")
