-- 代码作者：ti_Tout

--------------------------------------------------------------------------
--[[ 修改默认的科技树生成方式 ]]
--------------------------------------------------------------------------

local TechTree = require("techtree")

table.insert(TechTree.AVAILABLE_TECH, "HOMURA_TECH")

--------------------------------------------------------------------------
--[[ 制作等级中加入自己的部分 ]]
--------------------------------------------------------------------------

TECH.NONE.HOMURA_TECH = 0
TECH.HOMURA_TECH_ONE = { HOMURA_TECH = 2 }
TECH.HOMURA_TECH_THREE = { HOMURA_TECH = 4 }

--------------------------------------------------------------------------
--[[ 解锁等级中加入自己的部分 ]]
--------------------------------------------------------------------------

for k,v in pairs(TUNING.PROTOTYPER_TREES) do
    v.HOMURA_TECH = 0
end

TUNING.PROTOTYPER_TREES.HOMURA_TECH_ONE = TechTree.Create({
    HOMURA_TECH = 2,
})

TUNING.PROTOTYPER_TREES.HOMURA_TECH_THREE = TechTree.Create({
    HOMURA_TECH = 4,
})

--------------------------------------------------------------------------
--[[ 修改全部制作配方，对缺失的值进行补充 ]]
--------------------------------------------------------------------------

for i, v in pairs(AllRecipes) do
	v.level.HOMURA_TECH = v.level.HOMURA_TECH or 0
end