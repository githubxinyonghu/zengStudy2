-- 角色三围
TUNING.HOMURA_1_HEALTH = 75  		-- 生命值
TUNING.HOMURA_1_HUNGER = 150		-- 饥饿值
TUNING.HOMURA_1_SANITY = 200		-- 理智值
TUNING.HOMURA_1_SANITY_REGEN = 2.5/60  -- 每秒理智回复

-- 时停设定
HOMURA_GLOBALS.SKILLCD = 8 		-- 冷却时间
HOMURA_GLOBALS.SKILLDURATION = 30 	-- 持续时间
HOMURA_GLOBALS.RADIUS = 40 			-- 作用范围

-- 武器设定
-- * 注意: 配件槽数量定义在 modmain/container.lua，想修改会有些麻烦，你自己找办法吧。
local tuning = {       
    PISTOL = {				-- 手枪

        speed = 30, 		-- 射速
        range = 8,  		-- 射程
        range_var = 0.8, 	-- 射程随机量
        angle = 7,  		-- 子弹最大偏角
        damage1 = 50,  		-- 攻击伤害
        damage2 = 10,  		-- 平a伤害
        width = 1.6,		-- 弹道宽度
        maxammo = 7,		-- 载弹量

        maxhits = 1,
    },

    GUN = {					-- 步枪
    	
    	speed = 40, 		-- 射速
		range = 12,  		-- 射程
		range_var = 0.9, 	-- 射程随机量
		angle = 5,  		-- 子弹最大偏角
		damage1 = 35,  		-- 攻击伤害
		damage2 = 15,  		-- 平a伤害
		width = 1.6,		-- 弹道宽度
		maxammo = 20,		-- 载弹量

		maxhits = 1,		-- 穿透数
    },

    HMG = {					-- 机枪

    	speed = 40, 		-- 射速
		range = 12,  		-- 射程
		range_var = 0.7, 	-- 射程随机量
		angle = 20,  		-- 子弹最大偏角
		damage1 = 25,  		-- 攻击伤害
		damage2 = 10,  		-- 平a伤害
		width = 1.6,		-- 弹道宽度
		maxammo = 80,		-- 载弹量

		maxhits = 1,		-- 穿透数
    },

    RIFLE = {				-- 狙击枪

    	speed = 60, 		-- 射速
		range = 100,  		-- 射程
		range_var = 1.0, 	-- 射程随机量
		angle = 0,  		-- 子弹最大偏角
		damage1 = 200,  	-- 攻击伤害
		damage2 = 5,  		-- 平a伤害
		width = 2.5,		-- 弹道宽度
		maxammo = 5,		-- 载弹量

		maxhits = 2, 		-- 穿透数
    },

    RPG = {					-- 火箭炮

    	speed = 10, 		-- 射速
		range = 15,  		-- 射程
		range_var = 1, 		-- 射程随机量
		angle = 1,  		-- 子弹最大偏角
		damage1 = 300,  	-- 攻击伤害
		damage2 = 15,  		-- 平a伤害
		width = 3,			-- 弹道宽度 *
		maxammo = 1,		-- 载弹量

		maxhits = 1,		-- 穿透数

		infinite_range = true, -- 无限射程
    },

    SNOWPEA = {				-- 寒冰射手

    	speed = 10, 		-- 射速 *
        range = 8,  		-- 射程
        range_var = 1.0, 	-- 射程随机量
        angle = 0,  		-- 子弹最大偏角
        damage1 = 17.5,  	-- 攻击伤害
        damage2 = 10,  		-- 平a伤害
        width = 1.6,		-- 弹道宽度
        maxammo = 10,		-- 载弹量
        maxhits = 1,		-- 穿透数

        ammotaken_mult = 5, -- 填弹效率

        infinite_range = true,  -- 设置为无限射程

        debufftime = 10,    -- 减速buff持续时间
        debuffeffect = 0.4, -- 减速效果值

    },

    TR_GUN = {				-- 饥饿之眼

    	speed = 40, 		-- 射速
		range = 12,  		-- 射程
		range_var = 0.9, 	-- 射程随机量
		angle = 8,  		-- 子弹最大偏角
		damage1 = 25,  		-- 攻击伤害 * 刚好可以击杀小鸟
		damage2 = 10,  		-- 平a伤害
		width = 1.6,		-- 弹道宽度
		maxammo = 30,		-- 载弹量

		maxhits = 1,		-- 穿透数

		eater = true,		-- 可用食物补充耐久
    },

    WATERGUN = {			-- 假日 该武器的伤害机制比较特殊, 见 homura_water.lua

    	speed = 1,	 		-- 射速
		range = 4,  		-- 射程
		attackrange = 3,    -- 射程（触发攻击动作）
		angle = 0,  		-- 子弹最大偏角
		damage1 = 40,		-- 基础攻击伤害
		damagemult = 1.5,   -- 近身攻击加成倍率
		damage2 = 10,  		-- 平a伤害
		width = 1.6,		-- *弹道宽度
		maxammo = 16,		-- 载弹量

		maxhits = math.huge,-- 穿透数

		ammotaken_mult = 8, -- 填弹效率

		radius = 2, 		-- 范围伤害半径
		offset = 1.8,		-- 范围伤害中心点和玩家距离
    },

    STICKBANG = { 			-- 刺雷

    	damage = 250,		-- 爆炸伤害
    	playerdamage = 20, 	-- 对使用者的伤害
    	radius = 4,			-- 爆炸伤害半径
    	radius_trigger = 1.5, 	-- 触发半径
    	offset = 1,			-- 触发圆心和使用者的距离
    	knockback = 4,		-- 击退力度

    	rush_readytime = 15/10, -- 冲刺准备时间
    	rush_speedbonus = 0.6, -- 冲刺速度增益
    },

    BOW = {					-- 魔法弓

    	damage = {			-- 伤害
    		30,				-- *初始
    		30,				-- *蓄力增益/秒
    		150,			-- *极限值
    	},
    	flyingspeed = {		-- 箭矢飞行速度
    		25,				-- *初始
    		2,				-- *蓄力增益/秒
    		40,				-- *极限值
    	}, 		
    	chargetime = {		-- 蓄力时间
    		generic = 1.0,	-- *常规
    		homura = 3.0,	-- *特殊
    	},
    	speedmult = {		-- 蓄力时移速倍率
    		0.4,			-- *常规
    		0.2,			-- *骑牛
    	},

    	width = 2.0, 		-- 弹道宽度
    	range = 12, 		-- 射程
    	maxuses = 100,		-- 耐久
    	angle = 0,			-- 偏移量

    	--* dynamic
    	maxhits = 1,
    	damage1 = 0,
    },


    SUPPORT_BEACON = {		-- 支援信标

    	chargetime = 480, -- 充能时间
    },

    LEARNING = {
    	[1] = 30,			-- 初级工作台手册学习时间
    	[2] = 180, 			-- 高级工作台手册学习时间
    	[3] = 60, 			-- 全息工作台手册学习时间
    },
}

for k,v in pairs(tuning)do
	HOMURA_GLOBALS[k] = assert(HOMURA_GLOBALS[k] == nil, "Value `"..k.."` has been overrided.") and nil or v
end
