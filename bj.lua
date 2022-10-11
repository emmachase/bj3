--- Imports
local _ = require("util.score")

local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local display = require("modules.display")

local Sprite = require("components.Sprite")
local BigText = require("components.BigText")
local ChipStack = require("components.ChipStack")
local PlayerSlot = require("components.PlayerSlot")
local DealerModule = require("components.Dealer")
local Dealer, getDealerContext = DealerModule.Dealer, DealerModule.getDealerContext
--- End Imports

local Main = Solyd.wrapComponent("Main", function(props)
    local canvas = useCanvas()

    local standCount, setStandCount = Solyd.useState(0)
    local dealerContext = getDealerContext(standCount)

    return _.flat {
        BigText { text="Justy Blackjack", x=50, y=10, bg=colors.lime },

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
                x = 3 + (i-1)*(width+6), width = width, height = 75,
                onStand = function()
                    setStandCount(standCount + 1)
                end
            }
        end),
    }, { canvas = canvas, dealerContext = dealerContext }
end)



os.startTimer(0)

local t = 0
local tree = nil
local lastClock = os.epoch("utc")

while true do
    tree = Solyd.render(tree, Main {t = t})

    local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })
    -- print(#context.canvas)

    display.ccCanvas:composite(display.bgCanvas, unpack(context.canvas))
    display.ccCanvas:outputDirty(display.mon)

-- TODO: Collect unmounted canvases and mark screen as dirty?

    local e = { os.pullEvent() }
    local name = e[1]
    if name == "timer" then
        local clock = os.epoch("utc")
        local dt = (clock - lastClock)/1000
        t = t + dt
        lastClock = clock
        os.startTimer(0)

        hooks.tickAnimations(dt)
    elseif name == "monitor_touch" then
        local x, y = e[3], e[4]
        local node = hooks.findNodeAt(context.aabb, x, y)
        if node then
            node.onClick()
        end
    end
end
