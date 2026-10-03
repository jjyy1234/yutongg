-- Run QinScript first, completely unmodified
local ok, err = pcall(function()
    loadstring(game:HttpGet('http://QinScript.lol/333/main.lua?XGnb3'))()
end)

-- After it runs, dump all loaded function sources via getgc
task.delay(3, function()
    local seen = {}
    local count = 0
    for _, v in ipairs(getgc(true)) do
        if type(v) == 'function' then
            local ok2, info = pcall(function() return debug.getinfo(v, 'S') end)
            if ok2 and info and info.source and not seen[info.source] then
                local src = info.source
                if #src > 200 and not src:find('CoreGui') and not src:find('RobloxGui') then
                    seen[src] = true
                    count = count + 1
                    pcall(writefile, 'gc_dump_' .. count .. '.lua', src)
                end
            end
        end
    end
    print('[DUMP] wrote ' .. count .. ' files')
end)