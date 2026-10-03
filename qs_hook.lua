-- Step 1: check if script runs at all
local ok, err = pcall(function()
    loadstring(game:HttpGet('http://QinScript.lol/333/main.lua?XGnb3'))()
end)
print('[QS] pcall result:', ok, err)

-- Step 2: dump via getgc regardless
task.delay(5, function()
    local count = 0
    local seen = {}
    for _, v in ipairs(getgc(true)) do
        if type(v) == 'function' then
            local s = getfenv and getfenv(v) or nil
            local ok2, src = pcall(function()
                return debug.getinfo(v, 'S').source
            end)
            if ok2 and src and #src > 500 and not seen[src] then
                seen[src] = true
                count = count + 1
                pcall(writefile, 'gc_' .. count .. '.lua', src)
                print('[GC]', count, #src)
            end
        end
    end
    print('[DONE] total:', count)
end)