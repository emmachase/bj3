--- Imports
local Solyd = require("solyd")
local loadRIF = require("rif")

local createFont = require("font")

local canvases = require("canvas")
local PixelCanvas = canvases.PixelCanvas
local TeletextCanvas = canvases.TeletextCanvas
local TextCanvas = canvases.TextCanvas

local _ = require("score")

local setRikoPalette = require("rikoP")
--- End Imports


local mon = peripheral.find("monitor")
mon.setTextScale(0.5)

local ccCanvas = TeletextCanvas(colors.green, mon.getSize())
ccCanvas:outputFlush(mon)

local bgCanvas = ccCanvas.pixelCanvas:newFromSize()
for y = 1, bgCanvas.height do
    for x = 1, bgCanvas.width do
        -- T-Piece
        bgCanvas:setPixel(x, y, math.floor(((x)+y)/5) % 2 == 0 and colors.lime or colors.green)
        if math.floor(((-x)+y)/5) % 2 == 0 then
            bgCanvas:setPixel(x, y, colors.green)
        end

        -- 2x2 grid
        -- bgCanvas:setPixel(x, y, (x % 4 < 2) ~= (y % 4 < 2) and colors.green or colors.lime)

        -- bgCanvas:setPixel(x, y, (x/2-y/2) % 2 < 1 and colors.green or colors.lime)
    end
end

-- local pixCanvas = ccCanvas.pixelCanvas:newFromSize()

local playerSlotEmpty = loadRIF("res/cum.rif")

local cardFirst  = loadRIF("res/card.rif")
local cardFirstAnimated  = loadRIF("res/card-a.rif")
local cardMiddle = loadRIF("res/card2.rif")
local cardLast   = loadRIF("res/card-s.rif")
local cardBack   = loadRIF("res/cardfill.rif")

local suitHeart   = loadRIF("res/heart.rif")
local suitSpade   = loadRIF("res/spade.rif")
local suitClub    = loadRIF("res/club.rif")
local suitDiamond = loadRIF("res/diamond.rif")

local chip = loadRIF("res/chip.rif")
local chipStackBottom = loadRIF("res/chipstack-bottom.rif")
local chipStackMiddle = loadRIF("res/chipstack-middle.rif")
local chipStackTop    = loadRIF("res/chipstack-top.rif")

local chipColor = {
    [1] = colors.white,
    [5] = colors.red,
    [10] = colors.cyan,
    [25] = colors.lime,
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


local cardFontSheet = loadRIF("res/font.rif")
local cardFont = createFont(cardFontSheet, " 0123456789AJQK")

local bigFontSheet = loadRIF("res/cfont.rif")
local bigFont = createFont(bigFontSheet, " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-,.")

-- for i = 2, 50 do
--     for j = 2, 50 do
--         local color = 2^math.random(0, 15)
--         for y = 1, 3 do
--             for x = 1, 2 do
--                 bgCanvas:setPixel(i*2 + x - 2, j*3 + y - 3, color)
--             end
--         end
--     end
-- end

-- local canvasStack = {}
-- local AABBStack = {}

-- local Pixel = Solyd.wrapComponent(function(props, oldProps)
--     if oldProps then
--         -- mon.setCursorPos(oldProps.x, oldProps.y)
--         -- mon.setBackgroundColor(colors.black)
--         -- mon.write(" ")
--         for i = 0, 9 do
--             for j = 0, 35 do
--                 pixCanvas:mark(oldProps.x + i, oldProps.y + j)
--             end
--         end
--     end

--     -- mon.setCursorPos(props.x, props.y)
--     -- mon.setBackgroundColor(colors.red)
--     -- mon.write(" ")
--     -- local color = 2^math.random(0, 15)
--     for i = 0, 9 do
--         for j = 0, 35 do
--             pixCanvas:setPixel(props.x + i, props.y + j, colors.purple)
--         end
--     end
--     -- print(props.x, props.y)
-- end)

-- TODO: Topographically order the canvas stack

---@return PixelCanvas
local function useCanvas()
    local c = Solyd.useRef(function()
        return ccCanvas.pixelCanvas:newFromSize()
    end).value

    return c
end

local Canvas = Solyd.wrapComponent("Canvas", function(props)
    local canvas = useCanvas()

    Solyd.useEffect(function()
        return function()
            ccCanvas.pixelCanvas:markCanvas(canvas, 0, 0)
        end
    end)

    return props.children, {
        canvas = canvas
    }
end)

local function useBoundingBox(x, y, w, h, onClick)
    local box = Solyd.useRef(function()
        return { x = x, y = y, w = w, h = h, onClick = onClick }
    end).value

    box.x = x
    box.y = y
    box.w = w
    box.h = h
    box.onClick = onClick

    return box
end

local animationRequests = {}

---@return number?
local function useAnimation(playing)
    -- local anim = Solyd.useRef(function()
    --     return { playing = playing, frame = 0, time = 0 }
    -- end).value
    local t, setT = Solyd.useState(0)

    if playing then
        -- Request animation frame
        animationRequests[#animationRequests + 1] = {t, setT}

        return t
    elseif t ~= 0 then
        setT(0)
        return
    end
end

local Sprite = Solyd.wrapComponent("Sprite", function(props)
    local canvas = Solyd.useContext("canvas")

    Solyd.useEffect(function()
        -- local s, x, y = props.sprite, props.x, props.y
        canvas:drawCanvas(props.sprite, props.x, props.y, props.remapFrom, props.remapTo)
        -- canvas:drawCanvasRotated(props.sprite, props.x, props.y, props.angle or 0)
        return function()
            canvas:markCanvas(props.sprite, props.x, props.y)
            -- canvas:markCanvasRotated(props.sprite, props.x, props.y, props.angle or 0)
        end
    end, { props.sprite, props.x, props.y, props.remapFrom, props.remapTo })
end)

local BigText = Solyd.wrapComponent("BigText", function(props)
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

-- local Text = Solyd.wrapComponent("Text", function(props, oldProps)
--     local canvas --[[@type { value: TextCanvas }]] = Solyd.useRef(function()
--         local c = TextCanvas(ccCanvas.width, ccCanvas.height)
--         canvasStack[#canvasStack + 1] = c
--         return c
--     end)

--     if oldProps then
--         canvas.value:markText(props.text, oldProps.x, oldProps.y)

--         if props == nil then
--             return -- unmounting
--         end
--     end

--     canvas.value:write(props.text, props.x, props.y, colors.white, colors.black)
-- end)

local function getDeckDims(deckCnt)
    if deckCnt == 0 then
      return 0, 0
    end
  
    return cardFirstAnimated.width + (deckCnt - 1) * cardMiddle.width + cardLast.width, cardFirstAnimated.height
end

---@class Card
---@field suit "spades" | "hearts" | "diamonds" | "clubs"
---@field rank "A" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "10" | "J" | "Q" | "K"
---@field hidden boolean?

local suits = { "spades", "hearts", "diamonds", "clubs" }
local ranks = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }
local baseValue = {
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["J"] = 10,
    ["Q"] = 10,
    ["K"] = 10,
    ["10"] = 10
}

local function newDeck()
    local deck = {}
    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            deck[#deck + 1] = { suit = suit, rank = rank }
        end
    end
    return _.shuffle(deck)
end

local deck = newDeck()

---@param hand Card[]
---@param trueValue boolean
---@param soft boolean
---@return integer
local function getHandValue(hand, trueValue, soft)
    local aces = 0
    local value = 0

    -- First add up all non-aces
    for i = 1, #hand do
        if trueValue or not hand[i].hidden then
            if hand[i].rank == "A" then
                aces = aces + 1
            else
                value = value + baseValue[hand[i].rank]
            end
        end
    end

    if soft then
        return value + aces
    end

    -- Now find the least number of aces that need to count as 1 for it to not be a bust
    local finalValue
    for i = aces, 0, -1 do
        finalValue = value + (i * 11) + (aces - i)
        if finalValue <= 21 then
            break
        end
    end

    return finalValue
end

local Button = Solyd.wrapComponent("Button", function(props)
    -- local canvas = Solyd.useContext("canvas")
    -- local canvas = useCanvas()

    return BigText {
        text = props.text,
        x = props.x,
        y = props.y,
        bg = props.bg,
        color = props.color,
        width = props.width,
    }, {
        -- canvas = canvas,
        aabb = useBoundingBox(props.x, props.y, props.width or bigFont:getWidth(props.text), bigFont.height, props.onClick),
    }
end)

---@param props { x: integer, y: integer, chipCount: integer, chipValue: integer }
local ChipStack = Solyd.wrapComponent("ChipStack", function(props)
    local canvas = useCanvas()

    local height = chipStackTop.height + (props.chipCount - 1) * chipStackMiddle.height + chipStackBottom.height
    local offsetY = height - chipStackTop.height - chipStackMiddle.height - chipStackBottom.height

    local sprite = Solyd.useMemo(function()
        

        local canv = PixelCanvas(chipStackTop.width + 2, height + 2)

        canv:drawRect(colors.green, 1, 1, canv.width, canv.height)

        canv:drawCanvas(chipStackTopColors[props.chipValue], 2, 2)
        for i = 1, props.chipCount - 1 do
            canv:drawCanvas(chipStackMiddleColors[props.chipValue], 2, chipStackTop.height + i * chipStackMiddle.height - 1)
        end
        canv:drawCanvas(chipStackBottomColors[props.chipValue], 2, height - chipStackBottom.height + 2)
        
        return canv
    end, { props.chipCount, props.chipValue })

    

    return Sprite {
        sprite = sprite,
        x = math.floor(props.x/2)*2,
        y = math.floor((props.y - offsetY)/3)*3
    }, {
        canvas = canvas,
    }
end)

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

local function getDealerContext(standCount)
    local revealed, setRevealed = Solyd.useState(false)
    if standCount == 3 and not revealed then
        revealed = setRevealed(true)
    end

    return {
        revealed = revealed,
        setRevealed = setRevealed
    }
end

local Dealer = Solyd.wrapComponent("Dealer", function(props)

    local dealerContext = Solyd.useContext("dealerContext")

    local cards = Solyd.useRef(function()
        local hidden = table.remove(deck, 1)
        hidden.hidden = true

        return { table.remove(deck, 1), hidden }
    end)

    if dealerContext.revealed then
        cards.value[2].hidden = false
    end

    return {
        Hand { x=150, y=100, cards = cards.value },
    }

end)

---@param props { x: integer, width: integer, height: integer, onStand: fun() }
local PlayerSlot = Solyd.wrapComponent("PlayerSlot", function(props)
    -- local filledCanvas = useCanvas()
    -- local canvas = useCanvas()

    local isFilled, setFilled = Solyd.useState(false)

    local cards, setCards = Solyd.useState({})

    local afCards, setAfCards = Solyd.useState({})

    local softValue = getHandValue(afCards, false, true)
    local hardValue = getHandValue(afCards, false, false)

    local didBust = softValue > 21
    local clearColor = didBust and colors.red or colors.lime

    local emptySprite = Solyd.useMemo(function()
        local canv = PixelCanvas(props.width, props.height)
        
        canv:drawCanvas(
            playerSlotEmpty,
            (props.width - playerSlotEmpty.width)/2,
            (props.height - playerSlotEmpty.height)/2
        )

        return canv
    end, { props.width, props.height })

    local hitSprite = Solyd.useMemo(function()
        local canv = PixelCanvas(props.width, props.height)
        
        canv:drawRect(clearColor, 1, 1, props.width, props.height) --drawCanvas(playerSlotEmpty, (props.width - playerSlotEmpty.width)/2, 25)

        return canv
    end, { clearColor, props.width, props.height })

    local x, y = props.x, ccCanvas.pixelCanvas.height-props.height-2

    local t = useAnimation(#cards ~= #afCards)
    local finished = false
    if t and t > 1 then
        afCards = setAfCards(cards)
        t = nil
        finished = true
    end
    -- local h = 
    -- if isFilled then
    --     h = nil
    -- end

    -- ease t
    -- t = t and math.sqrt(t)
    -- t = t and -1 * t*(t-2); -- quad
    t = t and t - 1
	t = t and t*t*t + 1;

    local dealerContext = Solyd.useContext("dealerContext")
    local stood, setStood = Solyd.useState(false)

    -- I have no fucking clue whats happening here
    local dmx = ((getDeckDims(#cards) - getDeckDims(#afCards))/2 + (#afCards > 0 and -1 or 0))*(#afCards > 0 and 1 or 0)
    local amx = -math.min(dmx, (t or 0)*2*dmx)

    if isFilled then
        local canAct = not didBust and not t and not dealerContext.revealed and not stood
        
        local valueText
        if softValue > 0 then
            if softValue == hardValue then
                valueText = tostring(softValue)
            else
                valueText = tostring(softValue) .. "/" .. tostring(hardValue)
            end
        end

        return {
            -- Canvas {
            --     key = "filled",
            --     children = {
                Sprite { sprite = hitSprite, x = x, y = y },
                Hand { x=x-1+(props.width - getDeckDims(#afCards))/2+amx -- x+1
                , y=y+24, cards = afCards, clear = clearColor },
                Hand { x=x-1+(props.width + getDeckDims(#afCards) - getDeckDims(#cards - #afCards) - dmx)/2 - (#afCards > 0 and 1 or -1)       --x+(props.width - getDeckDims(#cards))/2 -- x+1
                , y=y+24+math.max(0, props.height-props.height*(t or 1)), cards = _.intersectSeq(afCards, cards), clear = clearColor },
                Button {
                    x = x+2,
                    y = y+2,
                    width = props.width-4,
                    text = canAct and "Stand" or "",
                    bg = canAct and colors.red,
                    color = colors.white,
                    onClick = function()
                        setStood(true)
                        props.onStand()
                    end,
                },
                BigText {
                    x = x+2,
                    y = y+14,
                    width = props.width-4,
                    text = valueText or "",
                    color = colors.white,
                    bg = clearColor,
                }
            --     }
            -- }
            -- getHandValue(cards, true, true) > 21 and BigText { text = "UR A FUCKING IDIOT", x=x+10, y=y-10, color=colors.red },
        }, {
            -- canvas = canvas,
            aabb = useBoundingBox(x, y, emptySprite.width, emptySprite.height, function()
                if canAct and (not finished) then
                    setCards(_.append(cards, table.remove(deck, 1)))
                end
            end)
        }
    else
        return {
             
                -- key = "waiting",
                -- children = 
                Sprite { sprite = emptySprite, x = x, y = y }
            
        }, {
            -- canvas = canvas,
            aabb = useBoundingBox(x, y, emptySprite.width, emptySprite.height, function()
                setFilled(true)
                setCards({ table.remove(deck, 1), table.remove(deck, 1) })
            end)
        }
    end
end)

local Main = Solyd.wrapComponent("Main", function(props)
    print("rendered", os.epoch("utc"))
    -- return _.map(props.players, function(player)
        
    -- end)
    local canvas = useCanvas()

    -- local hx = math.floor(math.cos(props.t/3)*80 + 90)
    -- local hy = math.floor(math.sin(props.t/3)*80 + 90)
    
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

        -- Text { text = "Hello, world!", x = math.sin(props.t)*20+40, y = 20 },
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

        -- Sprite { sprite = chip, x = 11, y = 10, remapFrom = nil, remapTo = colors.green },
    
        -- Sprite { sprite = chip, x = 11, y = 22, remapFrom = nil, remapTo = colors.green },
        -- Sprite { sprite = chip, x = 11, y = 34, remapFrom = nil, remapTo = colors.green },
        -- PlayerSlot { x = 5,   width = 75, height = 75 },
        -- PlayerSlot { x = 100, width = 75, height = 75 },
        -- PlayerSlot { x = 195, width = 75, height = 75 },

        -- Hand { x=10, y=10, cards = {
        --     { suit = "diamonds", rank = "10" },
        --     { suit = "spades", rank = "A" },
        --     { suit = "clubs", rank = "J" }
        -- } },

        -- BigText { text = "Hello world", x = 80 + math.sin(props.t)*20, y = 40, color = colors.white },

        -- Hand { x=10, y=40, cards = {
        --     { suit = "hearts", rank = "2" },
        --     { suit = "spades", rank = "7" },
        --     { suit = "diamonds", rank = "9" },
        --     { suit = "clubs", rank = "K" },
        -- } },

        -- Hand { x=hx, y=hy, cards = {
        --     { suit = "diamonds", rank = "10" },
        --     { suit = "spades", rank = "A" },
        --     { suit = "clubs", rank = "J" }
        -- } },

        -- Hand { x=hx+33, y=hy+15+20*math.sin(props.t), cards = {
        --     { suit = "hearts", rank = "2" },
        --     { suit = "spades", rank = "7" },
        --     { suit = "diamonds", rank = "9" },
        --     { suit = "clubs", rank = "K" },
        -- } },

        


        -- BouncingCard { t = 0 },

        -- BouncingCard { t = props.t/2 },
        -- BouncingCard { t = (props.t + 2)/1.5 },
        -- BouncingCard { t = (props.t + 4)/1.2 },
        -- BouncingCard { t = (props.t + 5)/1.2 },
        -- BouncingCard { t = (props.t + 6)/1.2 },
        -- BouncingCard { t = (props.t + 7)/1.2 },
        -- BouncingCard { t = props.t/2 },
        -- BouncingCard { t = (props.t + 2)/1.5 },
        -- BouncingCard { t = (props.t + 4)/1.2 },
        -- BouncingCard { t = (props.t + 5)/1.2 },
        -- BouncingCard { t = (props.t + 6)/1.2 },
        -- BouncingCard { t = (props.t + 7)/1.2 },
    }, { canvas = canvas, dealerContext = dealerContext }
end)

local function findNodeAt(boxes, x, y)
    for i = #boxes, 1, -1 do
        local box = boxes[i]
        if x >= box.x and x < box.x + box.w and y >= box.y and y < box.y + box.h then
            return box
        end
    end
end

os.startTimer(0)

local t = 0
local tree = nil
local lastClock = os.epoch("utc")
-- local oldCanveses = {}
-- local function unmountMissingCanvases(newCanvases)
--     for k, v in pairs(oldCanvases) do
--         if not newCanvases[k] then
--             v:destroy()
--         end
--     end

--     oldCanvases = newCanvases
-- end

-- mon.setPaletteColor(colors.lime, 0x4e9546)
setRikoPalette(mon)

while true do
    tree = Solyd.render(tree, Main {t = t})

    local context = Solyd.getTopologicalContext(tree, { "canvas", "aabb" })
    -- print(#context.canvas)

    ccCanvas:composite(bgCanvas, unpack(context.canvas))
    ccCanvas:outputDirty(mon)

-- TODO: Collect unmounted canvases and mark screen as dirty?

    local e = { os.pullEvent() }
    local name = e[1]
    if name == "timer" then
        local clock = os.epoch("utc")
        local dt = (clock - lastClock)/1000
        t = t + dt
        lastClock = clock
        os.startTimer(0)

        -- Clone the queue to avoid mutating it while iterating
        local animationQueue = {unpack(animationRequests)}
        animationRequests = {}
        for _, v in ipairs(animationQueue) do
            local aT, setT = v[1], v[2]
            setT(aT + dt)
        end
    elseif name == "monitor_touch" then
        local x, y = e[3], e[4]
        local node = findNodeAt(context.aabb, x*2, y*3)
        if node then
            node.onClick()
        end
    end
end
