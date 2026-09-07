-- YutongConfig: 所有硬编码坐标与名称
local V3 = Vector3.new
local cfg = {}

-- 出生点/回原点
cfg.SPAWN_POS = V3(188.8, 2.3, 56.6)

-- 传送点列表（UI 快速传送）
cfg.TELEPORT_POINTS = {
    { name = "2. 出生点",           pos = V3(188.8, 2.3, 56.6) },
    { name = "3. 木材反斗城",       pos = V3(266.7, 2.5, 57.8) },
    { name = "4. 土地商店",         pos = V3(263.0, 2.5, -98.2) },
    { name = "5. VIP商店",          pos = V3(907.7, 2.4, -92.3) },
    { name = "6. 辐射商店",         pos = V3(176.3, 11.5, -2639.3) },
    { name = "7. 桥头商店",         pos = V3(64.2, 2.4, -455.5) },
    { name = "8. 核污染区",         pos = V3(209.1, 13.5, -2758.7) },
    { name = "9. 树苗摊位",         pos = V3(-31.4, 16.7, -2717.7) },
    { name = "10. 車店",            pos = V3(483.0, 5.9, -1473.8) },
    { name = "11. 沼泽商店",        pos = V3(-1274.0, 130.9, -1443.0) },
    { name = "12. 家具店",          pos = V3(478.1, 4.9, -1725.4) },
    { name = "13. 草坪商店",        pos = V3(-566.5, 23.3, -120.8) },
    { name = "14. 快递站",          pos = V3(1894.6, -4.7, 1579.4) },
    { name = "15. 雪山",            pos = V3(1520.1, 412.6, 3284.3) },
    { name = "16. 复仇剑合成点",    pos = V3(6466.8, -95.6, -4540.0) },
    { name = "17. 星空鸭合成点",    pos = V3(-7063.9, 389.7, 4886.1) },
    { name = "18. 三叉戟 永恒剑合成点", pos = V3(-373.8, 12.0, -1340.5) },
    { name = "19. 恶魔鸭合成点",    pos = V3(-224.2, 59.1, 924.8) },
    { name = "20. 唱片商店",        pos = V3(-436.2, 194.1, 1027.2) },
    { name = "21. 地狱火合成点",    pos = V3(-1778.2, 341.7, 1474.3) },
    { name = "22. 天堂剑合成入口",  pos = V3(-411.5, 21.3, -491.5) },
    { name = "23. Doom勋章合成点",  pos = V3(-1290.3, 21.7, -100.0) },
    { name = "24. HL摊位",          pos = V3(-925.2, -247.7, 65.7) },
    { name = "25. Doom剑合成点",    pos = V3(-1486.4, -248.3, 286.4) },
    { name = "26. 石头商店",        pos = V3(-2359.0, 302.3, -1853.1) },
    { name = "27. 海边商店",        pos = V3(6698.3, 2.5, -3563.8) },
    { name = "28. 黑市",            pos = V3(-83.1, 62.2, 1408.3) },
}

-- 柜台坐标（人物落地坐标，Counter Scanner 扫描结果）
cfg.STORE_COUNTER = {
    ["SallysSeasonal"]  = V3(-1275.4, 133.9, -1477.2),
    ["StoneRUs"]        = V3(-2359.0, 303.0, -1853.1),
    ["FineArt"]         = V3(5238.0, -164.0, 740.0),
    ["FineFinds"]       = V3(51.3, 5.1, -454.5),
    ["SeaSide"]         = V3(6698.3, 3.2, -3563.8),
    ["VIPSHOP"]         = V3(947.0, 6.8, -63.8),
    ["HLStand"]         = V3(-921.4, -243.9, 80.1),
    ["MountainSide"]    = V3(-649.3, 161.4, 403.6),
    ["BlackMarket"]     = V3(-83.1, 62.8, 1408.3),
    ["LandStore"]       = V3(283.2, 24.0, -99.1),
    ["LogicStore"]      = V3(4595.3, 9.4, -785.3),
    ["TravelingTrader"] = V3(-304.4, 24.9, -521.5),
    ["FurnitureStore"]  = V3(477.3, 5.6, -1722.4),
    ["SaplingCart"]     = V3(-37.0, 20.9, -2734.3),
    ["PlanterStore"]    = V3(-597.4, 26.3, -111.4),
    ["CarStore"]        = V3(482.6, 6.6, -1474.9),
    ["AutumnCatalog"]   = V3(5970.4, 6.9, 26.4),
    ["Igloo"]           = V3(2311.5, 258.2, 2982.3),
    ["PlantomicsChoice"]= V3(187.1, 15.3, -2664.6),
    ["MusicStore"]      = V3(-412.3, 197.6, 1052.1),
    ["WoodRUs"]         = V3(268.0, 5.2, 67.4),
}

-- 合成点坐标
cfg.CRAFT = {
    -- 恶魔鸭合成祭坛（altar）等待点
    DEMON_DUCK_ALTAR    = V3(-224.2, 59.1, 924.8),
    -- 恶魔鸭材料放置坐标（3个槽位）
    DEMON_DUCK_SLOTS    = {
        V3(-224.01, 58.40, 940.58),
        V3(-232.82, 58.40, 933.19),
        V3(-241.93, 58.40, 925.54),
    },
    -- 复仇剑合成等待点
    VENGEANCE_WAIT      = V3(6464.1, -95.6, -4539.5),
    -- 复仇剑材料放置
    VENGEANCE_DUCK_EVIL = V3(6486.7, -97.4, -4550.9),
    VENGEANCE_DUCK_ANGEL= V3(6447.6, -99.4, -4523.6),
    -- 地狱火合成等待点
    HELLFIRE_WAIT       = V3(-1684.1, 348.9, 1477.7),
    -- 地狱火材料放置
    HELLFIRE_TRIDENT    = V3(-1755.5, 343.9, 1478.5),
    HELLFIRE_DUCK_EVIL  = V3(-1785.6, 343.9, 1495.5),
    -- 永恒剑/三叉戟合成等待点
    ETERNAL_STATION     = V3(-373.8, 12.0, -1340.5),
    -- 永恒剑合成材料放置
    ETERNAL_TRIDENT     = V3(-360.1, 12.3, -1333.8),
    ETERNAL_VENGEANCE   = V3(-371.8, 12.8, -1330.3),
    ETERNAL_DUCK_EVIL   = V3(-383.2, 13.2, -1327.8),
    -- 神剑合成材料放置坐标
    DOOM_SWORD_MATERIALS = {
        { names = {"GodlySword", "Godly"},              pos = V3(-1274.4, 24.5, -93.1),  label = "神剑" },
        { names = {"Eternal", "EternalSword"},           pos = V3(-1285.8, 24.5, -89.6),  label = "永恒剑" },
        { names = {"Hellfire", "HellfireAxe", "HellFire"}, pos = V3(-1296.9, 24.5, -86.7), label = "地狱火" },
        { names = {"Lunaris", "LunarDuck", "LunarisSword"}, pos = V3(-1306.6, 24.6, -84.3), label = "星空" },
    },
    -- Doom剑合成等待点
    DOOM_SWORD_WAIT     = V3(-1497.2, -245.3, 291.0),
    -- 神剑合成等待点（GodlySword craft）
    GODLY_SWORD_WAIT    = V3(1662.8, 401.7, 3280.5),
    -- 星空鸭合成等待点
    LUNAR_DUCK_WAIT     = V3(-7648.2, 322.1, 4233.9),
    -- 星空鸭材料放置
    LUNAR_DUCK_ANGEL    = V3(-7041.8, 391.3, 4906.3),
    LUNAR_DUCK_NORMAL   = V3(-7066.7, 391.4, 4898.7),
    LUNAR_DUCK_EVIL     = V3(-7091.9, 391.4, 4890.9),
}

-- 物品名称
cfg.ITEMS = {
    DUCK_ANGEL  = "DuckAngel",
    DUCK_EVIL   = "DuckEvil",
    DUCK_NORMAL = "Duck",
    LUNAR_DUCK  = "LunarDuck",
    LUNAR_CORE  = "LunarCore",
    ETERNAL     = "Eternal",
    VENGEANCE   = "Vengeance",
    HELLFIRE    = {"Hellfire", "HellfireAxe", "HellFire"},
    GODLY_SWORD = {"GodlySword", "Godly"},
    LUNARIS     = {"Lunaris", "LunarisSword"},
    TRIDENT     = {"Trident", "DemonTrident"},
    DOOM_SWORD  = "DoomSword",
}

_G.YutongConfig = cfg
