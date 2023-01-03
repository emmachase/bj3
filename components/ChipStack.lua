local Solyd = require("modules.solyd")
local loadRIF = require("modules.rif")

local hooks = require("modules.hooks")
local useCanvas, useBoundingBox = hooks.useCanvas, hooks.useBoundingBox

local canvases = require("modules.canvas")
local PixelCanvas = canvases.PixelCanvas

local Sprite = require("components.Sprite")


local chip = loadRIF("chip")
local chipStackBottom = loadRIF("chipstack-bottom")
local chipStackMiddle = loadRIF("chipstack-middle")
local chipStackTop    = loadRIF("chipstack-top")

local chipColor = {
    [1] = colors.white,
    [5] = colors.red,
    [10] = colors.cyan,
    [25] = colors.darkGreen,
    [100] = colors.black,
}

local chipStackBottomColors = {}
for value, color in pairs(chipColor) do
    local flipWhite = color == colors.white and colors.lightGray or nil
    chipStackBottomColors[value] = chipStackBottom:clone():mapColors({[colors.red] = color, [colors.white] = flipWhite})
end

local chipStackMiddleColors = {}
for value, color in pairs(chipColor) do
    local flipWhite = color == colors.white and colors.lightGray or nil
    chipStackMiddleColors[value] = chipStackMiddle:clone():mapColors({[colors.red] = color, [colors.white] = flipWhite})
end

local chipStackTopColors = {}
for value, color in pairs(chipColor) do
    local flipWhite = color == colors.white and colors.lightGray or nil
    local mapYtoColor = color == colors.white and colors.black or colors.yellow
    chipStackTopColors[value] = chipStackTop:clone():mapColors({[colors.red] = color, [colors.white] = flipWhite, [colors.yellow] = mapYtoColor})
end


---@param props { x: integer, y: integer, chipCount: integer, chipValue: integer, clear: integer?, onClick: function? }
return Solyd.wrapComponent("ChipStack", function(props)
    if props.chipCount == 0 then
        return
    end

    local height = chipStackTop.height + (props.chipCount - 1) * chipStackMiddle.height + chipStackBottom.height
    local offsetY = height - chipStackTop.height - chipStackMiddle.height - chipStackBottom.height

    -- local canvas = useCanvas(chipStackTop.width + 2, height + 2)

    local sprite = Solyd.useMemo(function()
        local canv = PixelCanvas(chipStackTop.width + 2, height + 2)

        canv:drawRect(props.clear or colors.green, 1, 1, canv.width, canv.height)

        canv:drawCanvas(chipStackTopColors[props.chipValue], 2, 2)
        for i = 1, props.chipCount - 1 do
            canv:drawCanvas(chipStackMiddleColors[props.chipValue], 2, chipStackTop.height + i * chipStackMiddle.height - 1)
        end
        canv:drawCanvas(chipStackBottomColors[props.chipValue], 2, height - chipStackBottom.height + 2)

        return canv
    end, { props.chipCount, props.chipValue, props.clear })

    return nil, {
        canvas = {sprite, math.floor(props.x/2)*2, math.floor((props.y - offsetY)/3)*3, chk = props.key ~= nil},
        aabb = props.onClick and useBoundingBox(props.x, props.y - offsetY, chipStackTop.width, height, props.onClick)
    }
    -- return Sprite {
    --     sprite = sprite,
    --     x = 1,
    --     y = 1
    -- }, {
    --     canvas = {canvas, math.floor(props.x/2)*2, math.floor((props.y - offsetY)/3)*3},
    -- }
end)
