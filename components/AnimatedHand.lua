local Solyd = require("modules.solyd")

local Cards = require("modules.cards")
local Hooks = require("modules.hooks")
local useAnimation = Hooks.useAnimation

local HandModule = require("components.Hand")
local Hand = HandModule.Hand

return Solyd.wrapComponent("AnimatedHand", function(props)
    local cx, y = props.cx, props.y

    local afCards, setAfCards = Solyd.useState({})

    local t = useAnimation(#props.cards ~= #afCards)
    local finished = false
    if t and t > 1 then
        afCards = setAfCards(props.cards)
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

    return {
        Hand { x=x-1+(props.width - getDeckDims(#afCards))/2+amx -- x+1
        , y=y+24, cards = afCards, clear = clearColor },
        Hand { x=x-1+(props.width + getDeckDims(#afCards) - getDeckDims(#cards - #afCards) - dmx)/2 - (#afCards > 0 and 1 or -1)       --x+(props.width - getDeckDims(#cards))/2 -- x+1
        , y=y+24+math.max(0, props.height-props.height*(t or 1)), cards = _.intersectSeq(afCards, cards), clear = clearColor }
    }
end)
