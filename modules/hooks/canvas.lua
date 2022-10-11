local Solyd = require("modules.solyd")
local display = require("modules.display")

---@return PixelCanvas
local function useCanvas()
    local c = Solyd.useRef(function()
        return display.ccCanvas.pixelCanvas:newFromSize()
    end).value

    return c
end

return useCanvas
