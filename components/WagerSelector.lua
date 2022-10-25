local _ = require("util.score")

local Solyd = require("modules.solyd")

local canvases = require("modules.canvas")
local PixelCanvas = canvases.PixelCanvas

local bigFont = require("fonts.bigfont")

local loadRIF = require("modules.rif")
local plus  = loadRIF("res/plus.rif")
local minus = loadRIF("res/minus.rif")

-- local hooks = require("modules.hooks")
-- local useCanvas = hooks.useCanvas

return Solyd.wrapComponent("WagerSelector", function(props)
    local x = 5
    local alignTo = x + 22

    local plus1 = props.balance >= 1
    local plus5 = props.balance >= 5
    local plus10 = props.balance >= 10
    local plus25 = props.balance >= 25
    local plus50 = props.balance >= 50
    local plus100 = props.balance >= 100

    local minus1 = props.wager >= 1
    local minus5 = props.wager >= 5
    local minus10 = props.wager >= 10
    local minus25 = props.wager >= 25
    local minus50 = props.wager >= 50
    local minus100 = props.wager >= 100

    local sprite = Solyd.useMemo(function()
        local canv = PixelCanvas(40, 80)

        if plus1   or minus1   then bigFont:writeRight(canv, "1",   alignTo,  1, colors.white) end
        if plus5   or minus5   then bigFont:writeRight(canv, "5",   alignTo, 11, colors.white) end
        if plus10  or minus10  then bigFont:writeRight(canv, "10",  alignTo, 21, colors.white) end
        if plus25  or minus25  then bigFont:writeRight(canv, "25",  alignTo, 31, colors.white) end
        if plus50  or minus50  then bigFont:writeRight(canv, "50",  alignTo, 41, colors.white) end
        if plus100 or minus100 then bigFont:writeRight(canv, "100", alignTo, 51, colors.white) end

        local plusX = alignTo + 2
        if plus1   then canv:drawCanvas(plus, plusX,  2, colors.green, colors.yellow) end
        if plus5   then canv:drawCanvas(plus, plusX, 12, colors.green, colors.yellow) end
        if plus10  then canv:drawCanvas(plus, plusX, 22, colors.green, colors.yellow) end
        if plus25  then canv:drawCanvas(plus, plusX, 32, colors.green, colors.yellow) end
        if plus50  then canv:drawCanvas(plus, plusX, 42, colors.green, colors.yellow) end
        if plus100 then canv:drawCanvas(plus, plusX, 52, colors.green, colors.yellow) end

        local minusX = x
        if minus1   then canv:drawCanvas(minus, minusX, 2 , colors.red, colors.yellow) end
        if minus5   then canv:drawCanvas(minus, minusX, 12, colors.red, colors.yellow) end
        if minus10  then canv:drawCanvas(minus, minusX, 22, colors.red, colors.yellow) end
        if minus25  then canv:drawCanvas(minus, minusX, 32, colors.red, colors.yellow) end
        if minus50  then canv:drawCanvas(minus, minusX, 42, colors.red, colors.yellow) end
        if minus100 then canv:drawCanvas(minus, minusX, 52, colors.red, colors.yellow) end

        -- canv:drawCanvas(plus, plusX + 8, 2 , colors.green, colors.yellow)
        -- canv:drawCanvas(plus, plusX + 8, 12, colors.green, colors.yellow)
        -- canv:drawCanvas(plus, plusX + 8, 22, colors.green, colors.yellow)
        -- canv:drawCanvas(plus, plusX + 8, 32, colors.green, colors.yellow)
        -- canv:drawCanvas(plus, plusX + 8, 42, colors.green, colors.yellow)
        -- canv:drawCanvas(plus, plusX + 8, 52, colors.green, colors.yellow)

        -- canv:drawRect(props.clear or colors.green, 1, 1, canv.width, canv.height)

        -- canv:drawCanvas(chipStackTopColors[props.chipValue], 2, 2)
        -- for i = 1, props.chipCount - 1 do
        --     canv:drawCanvas(chipStackMiddleColors[props.chipValue], 2, chipStackTop.height + i * chipStackMiddle.height - 1)
        -- end
        -- canv:drawCanvas(chipStackBottomColors[props.chipValue], 2, height - chipStackBottom.height + 2)

        return canv
    end, {
        plus1  , minus1  ,
        plus5  , minus5  ,
        plus10 , minus10 ,
        plus25 , minus25 ,
        plus50 , minus50 ,
        plus100, minus100,
    })

    return nil, { 
        canvas = { sprite, props.x, props.y },
        aabb = _.filterTruthy { __type = "list",
            minus1   and { x = props.x + x - 3, y = props.y +  1, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager - 1) end },
            minus5   and { x = props.x + x - 3, y = props.y + 11, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager - 5) end },
            minus10  and { x = props.x + x - 3, y = props.y + 21, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager - 10) end },
            minus25  and { x = props.x + x - 3, y = props.y + 31, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager - 25) end },
            minus50  and { x = props.x + x - 3, y = props.y + 41, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager - 50) end },
            minus100 and { x = props.x + x - 3, y = props.y + 51, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager - 100) end },

            plus1   and { x = props.x + x + minus.width + 10, y = props.y +  1, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager + 1) end },
            plus5   and { x = props.x + x + minus.width + 10, y = props.y + 11, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager + 5) end },
            plus10  and { x = props.x + x + minus.width + 10, y = props.y + 21, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager + 10) end },
            plus25  and { x = props.x + x + minus.width + 10, y = props.y + 31, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager + 25) end },
            plus50  and { x = props.x + x + minus.width + 10, y = props.y + 41, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager + 50) end },
            plus100 and { x = props.x + x + minus.width + 10, y = props.y + 51, w = 10 + plus.width, h = 10, onClick = function() props.setWager(props.wager + 100) end },
        }
    }
end)
