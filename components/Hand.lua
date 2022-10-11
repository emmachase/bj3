local Solyd = require("modules.solyd")
local loadRIF = require("modules.rif")

local hooks = require("modules.hooks")
local useCanvas = hooks.useCanvas

local canvases = require("modules.canvas")
local PixelCanvas = canvases.PixelCanvas

local Sprite = require("components.Sprite")
local cardFont = require("fonts.cardfont")

local cardFirstAnimated = loadRIF("res/card-a.rif")
local cardFirst  = loadRIF("res/card.rif")
local cardMiddle = loadRIF("res/card2.rif")
local cardLast   = loadRIF("res/card-s.rif")
local cardBack   = loadRIF("res/cardfill.rif")

local suitHeart   = loadRIF("res/heart.rif")
local suitSpade   = loadRIF("res/spade.rif")
local suitClub    = loadRIF("res/club.rif")
local suitDiamond = loadRIF("res/diamond.rif")


local function getDeckDims(deckCnt)
    if deckCnt == 0 then
      return 0, 0
    end

    return cardFirstAnimated.width + (deckCnt - 1) * cardMiddle.width + cardLast.width, cardFirstAnimated.height
end

---@param props { x: number, y: number, cards: Card[], clear: integer? }
local Hand = Solyd.wrapComponent("Hand", function(props)
    local canvas = useCanvas()

    local sprite = Solyd.useMemo(function()
        local cards = props.cards
        if #cards == 0 then
            return PixelCanvas(getDeckDims(0))
        end

        local canv = PixelCanvas(getDeckDims(#props.cards))

        local suitSprites = {hearts=suitHeart,diamonds=suitDiamond,spades=suitSpade,clubs=suitClub}
        local colors = {hearts=colors.red,diamonds=colors.red,spades=colors.black,clubs=colors.black}

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
            drawFaceValue(firstCard.rank, colors[firstCard.suit], x + 4, y + 19)
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
                drawFaceValue(thisCard.rank, colors[thisCard.suit], x + 5, y + 19)
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
            drawFaceValue(lastCard.rank, colors[lastCard.suit], x + 2, y + 3)
        end

        return canv
    end, { props.cards })

    return Sprite { sprite = sprite, x = props.x, y = props.y, remapFrom = colors.green, remapTo = props.clear or colors.lime }, {
        canvas = canvas,
    }
end)

return {
    Hand = Hand,
    getDeckDims = getDeckDims
}
