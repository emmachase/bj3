--- Imports
local _ = require("util.score")

local display = require("modules.display")
local auth = require("modules.auth")
auth.initialize(display.mon)

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local BigText = require("components.BigText")
local ChipStack = require("components.ChipStack")
local PlayerSlot = require("components.PlayerSlot")
local DealerModule = require("components.Dealer")
local Dealer, getDealerContext = DealerModule.Dealer, DealerModule.getDealerContext
local Core = require("core.GameState")
local GameRunner = require("core.GameRunner")
--- End Imports

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas()

    return _.flat {
        BigText { text="Lyqyd Blackjack", x=124, y=10, bg=colors.lime },

        ChipStack {
            x = 10 + 10*0 + math.cos(props.t)*50+50,
            y = 9 + math.sin(props.t)*30+50,
            chipCount = 1,
            chipValue = 1
        },

        ChipStack {
            x = 10 + 10 + math.cos(props.t)*50+50,
            y = 9 + math.sin(props.t)*30+50,
            chipCount = 2,
            chipValue = 5
        },

        ChipStack {
            x = 10 + 10*2 + math.cos(props.t)*50+50,
            y = 9 + math.sin(props.t)*30+50,
            chipCount = 4,
            chipValue = 10
        },

        ChipStack {
            x = 10 + 10*3 + math.cos(props.t)*50+50,
            y = 9 + math.sin(props.t)*30+50,
            chipCount = 5,
            chipValue = 25
        },

        ChipStack {
            x = 10 + 10*4 + math.cos(props.t)*50+50,
            y = 9 + math.sin(props.t)*30+50,
            chipCount = 4,
            chipValue = 100
        },

        Dealer {},
        _.rangeMap(3, function(i)
            local width = math.floor((canvas.width - 10)/3)-2
            return PlayerSlot {
                x = 3 + (i-1)*(width+6),
                width = width, height = 75,
                playerId = i,
                -- onStand = function()
                --     setStandCount(standCount + 1)
                -- end
            }
        end),
    }, {
        canvas = {canvas, 1, 1},
        gameState = props.gameState or {}
    }
end)



local t = 0
local tree = nil
local lastClock = os.epoch("utc")

local lastCanvasStack = {}
local weed
local function diffCanvasStack(newStack)
    -- Find any canvases that were removed
    local removed = {}
    local kept = {}
    for i = 1, #lastCanvasStack do
        removed[lastCanvasStack[i][1]] = lastCanvasStack[i]
    end
    for i = 1, #newStack do
        if newStack[i].chk then
            weed = newStack[i]
            local numdirty = 0
            for _, _ in pairs(newStack[i][1].dirty) do
                numdirty = numdirty + 1
            end
        end

        if removed[newStack[i][1]] then
            kept[#kept+1] = newStack[i]
            removed[newStack[i][1]] = nil
        end
    end

    -- Mark rectangle of removed canvases on bgCanvas (TODO: using bgCanvas is a hack)
    for _, canvas in pairs(removed) do
        display.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width, canvas[1].height)
    end

    -- For each kept canvas, mark the bounds if the new bounds are different
    for i = 1, #kept do
        local oldCanvas = lastCanvasStack[i]
        local newCanvas = newStack[i]
        if oldCanvas[2] ~= newCanvas[2] or oldCanvas[3] ~= newCanvas[3] then
            -- TODO: Optimize this?
            display.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width, oldCanvas[1].height)
            display.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width, newCanvas[1].height)
        end
    end

    lastCanvasStack = newStack
end

local gameState = Core.GameState.new()

local deltaTimer = os.startTimer(0)
GameRunner.launchGame(gameState, function()
    while true do
        tree = Solyd.render(tree, Main {t = t, gameState = gameState})

        local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })

        diffCanvasStack(context.canvas)

        local t1 = os.epoch("utc")
        display.ccCanvas:composite({display.bgCanvas, 1, 1}, unpack(context.canvas))
        display.ccCanvas:outputDirty(display.mon)
        local t2 = os.epoch("utc")
        -- print("Render time: " .. (t2-t1) .. "ms")

        local e = { os.pullEvent() }
        local name = e[1]
        if name == "timer" and e[2] == deltaTimer then
            local clock = os.epoch("utc")
            local dt = (clock - lastClock)/1000
            t = t + dt
            lastClock = clock
            deltaTimer = os.startTimer(0)

            hooks.tickAnimations(dt)
        elseif name == "monitor_touch" then
            local x, y = e[3], e[4]
            local player = auth.reconcileTouch(x, y)
            if player then
                local node = hooks.findNodeAt(context.aabb, x, y)
                if node then
                    node.onClick(player)
                end
            else
                -- TODO: Yell at the players
            end
        end
    end
end)
