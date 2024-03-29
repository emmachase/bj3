local Solyd = require("modules.solyd")
local loadRIF = require("modules.rif")

local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local canvases = require("modules.canvas")
local PixelCanvas = canvases.PixelCanvas

local Sprite = require("components.Sprite")
local cardFont = require("fonts.cardfont")

local cardFirstAnimated = loadRIF("card-a")
local cardFirst  = loadRIF("card")
local cardMiddle = loadRIF("card2")
local cardLast   = loadRIF("card-s")
local cardBack   = loadRIF("cardfill")

local suitHeart   = loadRIF("heart")
local suitSpade   = loadRIF("spade")
local suitClub    = loadRIF("club")
local suitDiamond = loadRIF("diamond")

-- print(cardFirstAnimated.width, cardMiddle.width, cardLast.width)


local function getDeckDims(deckCnt)
    if deckCnt == 0 then
      return 0, 0
    end

    return cardFirstAnimated.width + (deckCnt - 1) * cardMiddle.width + cardLast.width + 1, cardFirstAnimated.height
end

-- print(getDeckDims(1))

local function makeSprite(cards, clear)
    if #cards == 0 then
        return PixelCanvas(getDeckDims(0))
    end

    local canv = PixelCanvas(getDeckDims(#cards))

    local suitSprites = {hearts=suitHeart,diamonds=suitDiamond,spades=suitSpade,clubs=suitClub}
    local cardColors = {hearts=colors.red,diamonds=colors.red,spades=colors.black,clubs=colors.black}

    local function drawFaceValue(v, c, x, y)
        if v == "10" then
            cardFont:write(canv, v, x-2, y, c)
        else
            cardFont:write(canv, v, x, y, c)
        end
    end

    local x, y = 1, 1

    local firstCard = cards[1]
    canv:drawCanvas(cardFirstAnimated, x, y)
    x = x + 1 -- Clip Border

    if firstCard.hidden then
        canv:drawCanvas(cardBack, x + 2, y + 2)
        canv:drawCanvas(cardBack, x + 2, y + 10)
        canv:drawCanvas(cardBack, x + 2, y + 18)
    else
        canv:drawCanvas(suitSprites[firstCard.suit], x + 2, y + 2)
        drawFaceValue(firstCard.rank, cardColors[firstCard.suit], x + 4, y + 19)
    end
    x = x + 10

    for i = 2, #cards do
        local thisCard = cards[i]
        canv:drawCanvas(cardMiddle, x, y)
        if thisCard.hidden then
            canv:drawCanvas(cardBack, x + 3, y + 2)
            canv:drawCanvas(cardBack, x + 3, y + 10)
            canv:drawCanvas(cardBack, x + 3, y + 18)
        else
            canv:drawCanvas(suitSprites[thisCard.suit], x + 3, y + 2)
            drawFaceValue(thisCard.rank, cardColors[thisCard.suit], x + 5, y + 19)
        end
        x = x + 11
    end

    local lastCard = cards[#cards]
    canv:drawCanvas(cardLast, x, y)
    if lastCard.hidden then
        canv:drawCanvas(cardBack, x, y + 2)
        canv:drawCanvas(cardBack, x, y + 10)
        canv:drawCanvas(cardBack, x, y + 18)
    else
        canv:drawCanvas180(suitSprites[lastCard.suit], x, y + 18)
        drawFaceValue(lastCard.rank, cardColors[lastCard.suit], x + 2, y + 3)
    end

    -- print(colors.green)
    -- print(colors.lime)
    canv:mapColors({ [colors.green] = (clear or colors.lime) })

    return canv
end

---@param props { x: number, y: number, cards: Card[], clear: integer? }
local Hand = Solyd.wrapComponent("Hand", function(props)
    if #props.cards == 0 then
        return nil
    end

    -- print("new canva", getDeckDims(#props.cards))
    local canvas = useCanvas(getDeckDims(#props.cards))

    local sprite = Solyd.useMemo(function()
        return makeSprite(props.cards, props.clear)
    end, { props.cards, props.clear })

    return nil, { canvas = { sprite, props.x, props.y } }
    -- return Sprite { sprite = sprite, x = 1, y = 1, remapFrom = colors.green, remapTo = props.clear or colors.lime }, {
    --     canvas = {canvas, props.x, props.y},
    -- }
end)

return {
    Hand = Hand,
    getDeckDims = getDeckDims,
    makeSprite = makeSprite,
}
