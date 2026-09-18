-- v8_globals.lua — 共享变量和工具函数
-- YUTONG v8 模块化：全局共享变量、UI 框架、白名单、Kick 逻辑
-- 所有模块通过 _G.V8 表访问共享变量

local V8 = _G.V8 or {}
_G.V8 = V8

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")