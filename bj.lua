--- Imports
local _ = require("util.score")

local display = require("modules.display")
local auth = require("modules.auth")
auth.initialize(display.mon)

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local BasicText = require("components.BasicText")
local BigText = require("components.BigText")
local ChipStack = require("components.ChipStack")
local PlayerSlot = require("components.PlayerSlot")
local DealerModule = require("components.Dealer")
local RenderCanvas = require("components.RenderCanvas")
local Dealer, getDealerContext = DealerModule.Dealer, DealerModule.getDealerContext
local Core = require("core.GameState")
local GameRunner = require("core.GameRunner")
local Krist = require("core.krist")

local loadRIF = require("modules.rif")
local banner = loadRIF("hi")
--- End Imports

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas()

    return _.flat {
        BigText { text="Lyqyd Blackjack", x=124, y=10, bg=colors.lime },
        -- BigText { text="PAYS 2:1   BLACKJACK PAYS 3:2   PAYS 2:1", x=55, y=120, bg=colors.green, color=colors.red },
        -- BigText { text="Dealer must stand on all 17s", x=91, y=133, bg=colors.green },

        RenderCanvas {
            canvas = banner,
            x = 1,
            y = 30,
        },

        -- ChipStack {
        --     x = 10 + 10*0 + math.cos(props.t)*50+50,
        --     y = 9 + math.sin(props.t)*30+50,
        --     chipCount = 1,
        --     chipValue = 1
        -- },

        -- ChipStack {
        --     x = 10 + 10 + math.cos(props.t)*50+50,
        --     y = 9 + math.sin(props.t)*30+50,
        --     chipCount = 2,
        --     chipValue = 5
        -- },

        -- ChipStack {
        --     x = 10 + 10*2 + math.cos(props.t)*50+50,
        --     y = 9 + math.sin(props.t)*30+50,
        --     chipCount = 4,
        --     chipValue = 10
        -- },

        -- ChipStack {
        --     x = 10 + 10*3 + math.cos(props.t)*50+50,
        --     y = 9 + math.sin(props.t)*30+50,
        --     chipCount = 5,
        --     chipValue = 25
        -- },

        -- ChipStack {
        --     x = 10 + 10*4 + math.cos(props.t)*50+50,
        --     y = 9 + math.sin(props.t)*30+50,
        --     chipCount = 4,
        --     chipValue = 100
        -- },

        _.rangeMap(3, function(i)
            local width = math.floor((canvas.width - 10)/3)-2
            local player = props.gameState.players[i]
            return PlayerSlot {
                x = 3 + (i-1)*(width+6),
                width = width, height = 75,
                playerId = i,
                player = player,
                timeout = player and player.timeoutAt and (1 - (os.epoch("utc") - player.startTimeoutAt) / (player.timeoutAt - player.startTimeoutAt)) or nil
                -- onStand = function()
                --     setStandCount(standCount + 1)
                -- end
            }
        end),

        Dealer {},

        BasicText { 
            text = "To deposit, run /pay " .. Krist.config.metaname .. "@" .. Krist.config.name .. ".kst <amount>",
            align = "center",
            width = canvas.width/2,
            x = 1,
            y = canvas.height/3
        },
    }, {
        canvas = {canvas, 1, 1},
        gameState = props.gameState or {}
    }
end)



local t = 0
local tree = nil
local lastClock = os.epoch("utc")

local lastCanvasStack = {}
local lastCanvasHash = {}
local function diffCanvasStack(newStack)
    -- Find any canvases that were removed
    local removed = {}
    local kept, newCanvasHash = {}, {}
    for i = 1, #lastCanvasStack do
        removed[lastCanvasStack[i][1]] = lastCanvasStack[i]
    end
    for i = 1, #newStack do
        if removed[newStack[i][1]] then
            kept[#kept+1] = newStack[i]
            removed[newStack[i][1]] = nil
            newStack[i][1].allDirty = false
        else -- New
            newStack[i][1].allDirty = true
        end

        newCanvasHash[newStack[i][1]] = newStack[i]
    end

    -- Mark rectangle of removed canvases on bgCanvas (TODO: using bgCanvas is a hack)
    for _, canvas in pairs(removed) do
        display.bgCanvas:dirtyRect(canvas[2], canvas[3], canvas[1].width, canvas[1].height)
    end

    -- For each kept canvas, mark the bounds if the new bounds are different
    for i = 1, #kept do
        local newCanvas = kept[i]
        local oldCanvas = lastCanvasHash[newCanvas[1]]
        if oldCanvas then
            if oldCanvas[2] ~= newCanvas[2] or oldCanvas[3] ~= newCanvas[3] then
                -- TODO: Optimize this?
                display.bgCanvas:dirtyRect(oldCanvas[2], oldCanvas[3], oldCanvas[1].width, oldCanvas[1].height)
                display.bgCanvas:dirtyRect(newCanvas[2], newCanvas[3], newCanvas[1].width, newCanvas[1].height)
            end
        end
    end

    lastCanvasStack = newStack
    lastCanvasHash = newCanvasHash
end

local gameState = Core.GameState.new()
Krist.start(gameState)

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

        if gameState.players[1] == nil and gameState.players[2] == nil and gameState.players[3] == nil then
            if deltaTimer then
                os.cancelTimer(deltaTimer)
                deltaTimer = nil
            end
        else
            local clock = os.epoch("utc")
            local dt = (clock - lastClock)/1000
            if dt > 0.1 then
                -- Timer must've died, restart it
                deltaTimer = os.startTimer(0)
            end
        end

        local e = { os.pullEvent() }
        local name = e[1]
        if name == "timer" and e[2] == deltaTimer then
            local clock = os.epoch("utc")
            local dt = (clock - lastClock)/1000
            t = t + dt
            lastClock = clock
            deltaTimer = os.startTimer(0)

            hooks.tickAnimations(dt)
        elseif name == "mouse_click" then
            local x, y = e[3], e[4]
            local node = hooks.findNodeAt(context.aabb, x, y, "dummy-id")
            if node then
                node.onClick({ name = "anemonemma", id = "dummy-id" })
            end

            if deltaTimer == nil then
                deltaTimer = os.startTimer(0)
            end
        elseif name == "monitor_touch" then
            local x, y = e[3], e[4]
            local player = auth.reconcileTouch(x, y)
            if player then
                local node = hooks.findNodeAt(context.aabb, x, y, player.id)
                if node then
                    node.onClick(player)
                end
            else
                -- TODO: Yell at the players
            end
        elseif name == "websocket_message" then
            local data = textutils.unserializeJSON(e[3])
            if data.type == "event" then
                if data.event == "transaction" then
                    Krist.handleTransaction(data.transaction)
                end
            end
        elseif name == "websocket_closed" then
            Krist.restart()
            deltaTimer = os.startTimer(0) -- Make sure the timer is still running
        end
    end
end)

Krist.stop()

display.mon.setBackgroundColor(colors.black)
display.mon.clear()
if display.mon.setTextScale then display.mon.setTextScale(1) end
display.mon.setCursorPos(1, 1)
display.mon.setTextColor(colors.white)
display.mon.write("Blackjack has exited.")
