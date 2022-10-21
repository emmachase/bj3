local Solyd = require("modules.solyd")

---@param props { canvas: PixelCanvas, x: integer, y: integer, remap: table }
return Solyd.wrapComponent("RenderCanvas", function(props)
    local remapped = Solyd.useMemo(function()
        return props.canvas:mapColors(props.remap)
    end, {props.canvas, props.remap})

    return {}, { canvas = { remapped, props.x, props.y } }
end)
