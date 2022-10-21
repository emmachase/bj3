local _ = require("util.score")

local Solyd = require("modules.solyd")

local Cards = require("modules.cards")
local Hooks = require("modules.hooks")
local useAnimation = Hooks.useAnimation

local AnimationRunner = require("modules.animation")
local Ease = require("modules.animation.Ease")

local HandModule = require("components.Hand")
local Hand = HandModule.Hand

local RenderCanvas = require("components.RenderCanvas")

-- return Solyd.wrapComponent("AnimatedHand", function(props)
--     local cx, y = props.cx, props.y

--     local afCards, setAfCards = Solyd.useState({})

--     -- TODO: make useAnimation take a finish function
--     local t = useAnimation(#props.cards ~= #afCards)
--     local finished = false
--     if t and t > 1 then
--         afCards = setAfCards(props.cards)
--         t = nil
--         finished = true
--     end
--     -- local h = 
--     -- if isFilled then
--     --     h = nil
--     -- end

--     -- ease t
--     -- t = t and math.sqrt(t)
--     -- t = t and -1 * t*(t-2); -- quad
--     t = t and t - 1
-- 	t = t and t*t*t + 1;

--     return {
--         Hand { x=x-1+(props.width - getDeckDims(#afCards))/2+amx -- x+1
--         , y=y+24, cards = afCards, clear = clearColor },
--         Hand { x=x-1+(props.width + getDeckDims(#afCards) - getDeckDims(#cards - #afCards) - dmx)/2 - (#afCards > 0 and 1 or -1)       --x+(props.width - getDeckDims(#cards))/2 -- x+1
--         , y=y+24+math.max(0, props.height-props.height*(t or 1)), cards = _.intersectSeq(afCards, cards), clear = clearColor }
--     }
-- end)

---@param containerWidth integer
---@param containerHeight integer
---@param sprite PixelCanvas
local function calculateHandCenter(containerWidth, containerHeight, sprite)
    local w, h = sprite.width, sprite.height
    return (containerWidth - w) / 2, (containerHeight - h) / 2
end

local function AddCardAnimation(width, height, currentHand, card)
    local cardSprite = HandModule.makeSprite({card})
    local handSprite = HandModule.makeSprite(currentHand)
    local combinedSprite = HandModule.makeSprite(_.append(currentHand, card))

    local overlapOffset = #currentHand > 0 and 10 or 0

    return {
        {
            {
                sprite = handSprite, initial = { x = calculateHandCenter(width, height, handSprite), y = 26 },
                steps = {
                    {
                        duration = 0.15,
                        to = { x = calculateHandCenter(width, height, combinedSprite) },
                    }
                }
            },
            {
                sprite = cardSprite, initial = { x = calculateHandCenter(width, height, combinedSprite) + select(1, HandModule.getDeckDims(#currentHand)) - overlapOffset, y = 70 },
                steps = {
                    {
                        duration = 0.5,
                        easing = Ease.outQuart,
                        to = { y = 26 },
                    }
                }
            }
        },
        {
            { sprite = combinedSprite, initial = { x = calculateHandCenter(width, height, combinedSprite), y = 26 } }
        }
    }
end

---@param props { hands: PlayerHand[], activeHand: integer, x: integer, y: integer, width: integer, height: integer, clear: integer}
return Solyd.wrapComponent("AnimatedPlayerHands", function(props)
    local lastHands = Solyd.useRef(function() return _.copyDeep { props.hands, props.activeHand } end)
    local currentAnimation = Solyd.useRef(function() return nil --[[@as AnimationSets]] end)
    
    -- local currentHandSprite = Solyd.useRef(function() return {} end)

    local currentHand = props.hands[props.activeHand]
    local lastHand = lastHands.value[1][lastHands.value[2]]
    if #currentHand > #lastHand then
        local card = currentHand[#currentHand]
        currentAnimation.value = AddCardAnimation(props.width, props.height, lastHands.value[1][lastHands.value[2]], card)
        lastHands.value = _.copyDeep { props.hands, props.activeHand }
    end

    local t = useAnimation(currentAnimation.value ~= nil)

    local visibleSets = Solyd.useRef(function() return {} end)

    if currentAnimation.value and t then
        local sets, isFinished = AnimationRunner.evaluateAnimationSets(currentAnimation.value, t)

        visibleSets.value = sets

        

        print(t, isFinished)
        if isFinished then
            currentAnimation.value = nil
            -- restingState.value = render
        end

        -- return render
    -- else
    --     return restingState.value
    end

    return _.map(visibleSets.value, function(set)
        return RenderCanvas { canvas = set.sprite, x = set.x + props.x, y = set.y + props.y, remap = { [colors.lime] = props.clear } }
    end)
end)
