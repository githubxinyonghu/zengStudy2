table.insert(Assets, Asset("ANIM", "anim/homura_peruse.zip"))

local function UpdateActionMeter(inst, starttime)
    inst.player_classified.actionmeter:set_local(math.min(255, math.floor((GetTime() - starttime) * 10 + 2.5)))
end

local function StartActionMeter(inst, duration)
    if inst.HUD ~= nil then
        inst.HUD:ShowRingMeter(inst:GetPosition(), duration)
    end
    inst.player_classified.actionmetertime:set(math.min(255, math.floor(duration * 10 + .5)))
    inst.player_classified.actionmeter:set(2)
    if inst.sg.mem.actionmetertask == nil then
        inst.sg.mem.actionmetertask = inst:DoPeriodicTask(.1, UpdateActionMeter, nil, GetTime())
    end
end

local function StopActionMeter(inst, flash)
    if inst.HUD ~= nil then
        inst.HUD:HideRingMeter(flash)
    end
    if inst.sg.mem.actionmetertask ~= nil then
        inst.sg.mem.actionmetertask:Cancel()
        inst.sg.mem.actionmetertask = nil
        inst.player_classified.actionmeter:set(flash and 1 or 0)
    end
end

local function CommonStopReading()
    return EventHandler("homura_stoplearning", function(inst)
        inst.sg.statemem.reading = false
        inst.sg:GoToState("homura_book_close")
    end)
end

local function CheckReading(inst)
    if not inst.sg.statemem.reading then
        inst.components.homura_reader:StopReading()
    end
end

local function CheckReadingAndEquip(inst)
    if not inst.sg.statemem.reading then
        inst.components.homura_reader:StopReading()
        StopActionMeter(inst)
        if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
            inst.AnimState:Hide("ARM_normal")
        end
    end
end

local open = State{
    name = "homura_book_open",
    tags = { "doing" },

    onenter = function(inst)
        local action = inst:GetBufferedAction()
        local book = action and action.invobject
        local level = book and book.level
        if level ~= nil then
            inst.AnimState:OverrideSymbol("book", "swap_homura_book_"..level, "book")
        end

        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("action_uniqueitem_pre")
        inst.AnimState:Show("ARM_normal")
        inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and inst.bufferedaction.invobject or nil)
    end,

    timeline = {
        TimeEvent(8*FRAMES, function(inst)
            inst.sg.statemem.reading = true
            inst.sg:GoToState("homura_book_loop")
        end),
    },

    events =
    {
        CommonStopReading(),
    },

    onexit = function(inst)
        CheckReadingAndEquip(inst)
    end,
}

local loop = State{
    name = "homura_book_loop",
    tags = { "doing" },

    onenter = function(inst, loop)
        inst.AnimState:PlayAnimation("homura_peruse")
        inst.AnimState:Show("ARM_normal")
        if loop then
            inst.AnimState:SetTime(63* FRAMES)
            inst.sg.statemem.loop = true
        end

        inst.components.locomotor:Stop()
    end,

    timeline = {
        TimeEvent(3 * FRAMES, function(inst)
            if inst.sg.statemem.loop then
                inst.SoundEmitter:PlaySound("dontstarve/characters/actions/page_turn")
            end
        end),
        TimeEvent(32 * FRAMES, function(inst)
            if inst.sg.statemem.loop then
                inst.sg.statemem.reading = true
                inst.sg:GoToState("homura_book_loop", true)
            end
        end),
        ------------- First in -------------
        TimeEvent(25 * FRAMES, function(inst)
            if not inst.sg.statemem.loop then
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book")
                inst:PerformBufferedAction()
            end
        end),
        TimeEvent(67 * FRAMES, function(inst)
            if not inst.sg.statemem.loop then
                inst.SoundEmitter:PlaySound("dontstarve/characters/actions/page_turn")
            end
        end),
        TimeEvent(95 * FRAMES, function(inst)
            if not inst.sg.statemem.loop then
                inst.sg.statemem.reading = true
                inst.sg:GoToState("homura_book_loop", true)
            end
        end),
    },

    events = {
        CommonStopReading(),
        EventHandler("homuraevt_finishlearning", function(inst)
            inst.sg:GoToState("homura_book_close")
        end),
    },

    onupdate = function(inst)
        if not CanEntitySeeTarget(inst, inst) then
            inst.sg:GoToState("homura_book_close")
        end
    end,

    onexit = function(inst)
        CheckReadingAndEquip(inst)
    end,
}

local close = State{
    name = "homura_book_close",
    tags = { "idle", "nodangle" },

    onenter = function(inst)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("reading_pst")
    end,

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
				inst.sg:GoToState(inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil and "item_out" or "idle")
            end
        end),
    },
}

AddStategraphState("wilson", open)
AddStategraphState("wilson", loop)
AddStategraphState("wilson", close)
