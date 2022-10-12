local _ = require("util.score")

local Solyd = require("modules.solyd")
local Cards = require("modules.cards")
local Display = require("modules.display")

local Canvas = require("modules.canvas")
local PixelCanvas = Canvas.PixelCanvas

local hooks = require("modules.hooks")
local useAnimation, useBoundingBox = hooks.useAnimation, hooks.useBoundingBox

local Sprite = require("components.Sprite")
local BigText = require("components.BigText")
local Button = require("components.Button")
local HandModule = require("components.Hand")
local Hand, getDeckDims = HandModule.Hand, HandModule.getDeckDims

local loadRIF = require("modules.rif")
local playerSlotEmpty = loadRIF("res/cum.rif")

---@param props { x: integer, width: integer, height: integer, onStand: fun() }
return Solyd.wrapComponent("PlayerSlot", function(props)
    -- local filledCanvas = useCanvas()
    -- local canvas = useCanvas()

    local isFilled, setFilled = Solyd.useState(false)

    local cards, setCards = Solyd.useState({})

    local afCards, setAfCards = Solyd.useState({})

    local softValue = Cards.getHandValue(afCards, false, true)
    local hardValue = Cards.getHandValue(afCards, false, false)

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

    local x, y = props.x, Display.ccCanvas.pixelCanvas.height-props.height-2

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
    local dmx = ((getDeckDims(#cards) - getDeckDims(#afCards))/2)*(#afCards > 0 and 1 or 0)
    local amx = -math.min(dmx, (t or 0)*2*dmx)

    if isFilled then
        local canAct = not didBust and not dealerContext.revealed and not stood
        
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
                Hand { x=x+(props.width - getDeckDims(#afCards))/2+amx -- x+1
                , y=y+26, cards = afCards, clear = clearColor },
                Hand { x=x+(props.width + getDeckDims(#afCards) - getDeckDims(#cards - #afCards) - dmx)/2 - (#afCards > 0 and 2 or 0)       --x+(props.width - getDeckDims(#cards))/2 -- x+1
                , y=y+26+math.max(0, props.height-props.height*(t or 1)), cards = _.intersectSeq(afCards, cards), clear = clearColor },
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
                    setCards(_.append(cards, table.remove(dealerContext.deck, 1)))
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
                setCards({ table.remove(dealerContext.deck, 1), table.remove(dealerContext.deck, 1) })
            end)
        }
    end
end)
