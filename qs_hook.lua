-- Hook via hookfunction, no script modification needed
local old_ls = hookfunction(loadstring, function(code, ...)
    local n = (typeof and typeof(code) == 'string') and #code or 0
    if n > 100 then
        local idx = (not _G.__dumpcount and 1 or _G.__dumpcount + 1)
        _G.__dumpcount = idx
        pcall(writefile, 'qs_dump_' .. idx .. '.lua', tostring(code))
    end
    return old_ls(code, ...)
end)

-- Now load QinScript fresh from URL (unmodified)
loadstring(game:HttpGet('http://QinScript.lol/333/main.lua?XGnb3'))()