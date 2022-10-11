local Solyd = require("modules.solyd")
local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local bigFont = require("fonts.bigfont")

return Solyd.wrapComponent("BigText", function(props)
    local canvas = useCanvas()--Solyd.useContext("canvas")

    Solyd.useEffect(function()
        local fw = props.width or bigFont:getWidth(props.text)

        if props.bg then
            for x = -1, fw do
                for y = -1, bigFont.height do
                    canvas:setPixel(props.x + x, props.y + y, props.bg)
                end
            end
        end

        local cx = props.width and math.floor((props.width - bigFont:getWidth(props.text)) / 2) or 0
        bigFont:write(canvas, props.text, props.x + cx, props.y, props.color or colors.white)

        return function()
            canvas:markRect(props.x-1, props.y-1, fw+2, bigFont.height+2)
        end
    end, { canvas, props.text, props.x, props.y, props.color, props.bg })

    return nil, { canvas = canvas }
end)
