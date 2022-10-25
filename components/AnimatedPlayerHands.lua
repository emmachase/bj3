local _ = require("util.score")

local Solyd = require("modules.solyd")

local Cards = require("modules.cards")
local Hooks = require("modules.hooks")
local useAnimation = Hooks.useAnimation
local Animation = require("modules.hooks.animation")

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
---@param spriteWidth integer
local function calculateHandCenter(containerWidth, containerHeight, spriteWidth)
    -- local w = sprite.width--, sprite.height
    return 1 + (containerWidth - spriteWidth) / 2 -- , (containerHeight - h) / 2
end

local function AddCardAnimation(width, height, currentHand, card)
    local cardSprite = HandModule.makeSprite({card})
    local handSprite = HandModule.makeSprite(currentHand)
    local combinedSprite = HandModule.makeSprite(_.append(currentHand, card))

    local overlapOffset = #currentHand > 0 and 10 or 0

    return {
        {
            {
                sprite = handSprite, initial = { x = calculateHandCenter(width, height, handSprite.width), y = 26 },
                steps = {
                    {
                        duration = 0.15,
                        to = { x = calculateHandCenter(width, height, combinedSprite.width) },
                    }
                }
            },
            {
                sprite = cardSprite, initial = { x = calculateHandCenter(width, height, combinedSprite.width) + select(1, HandModule.getDeckDims(#currentHand)) - overlapOffset, y = 70 },
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
            { sprite = combinedSprite, initial = { x = calculateHandCenter(width, height, combinedSprite.width), y = 26 } }
        }
    }
end

local function SplitHandsAnimation(width, height, hand1, hand2)
    local hand1Sprite = HandModule.makeSprite(hand1)
    local hand2Sprite = HandModule.makeSprite(hand2)

    -- local cardWidth = HandModule.getDeckDims(1)
    local oneCardX = calculateHandCenter(width, height, hand1Sprite.width)
    local twoCardX = calculateHandCenter(width, height, HandModule.getDeckDims(2))

    return { nobg = true,
        {
            {
                sprite = hand2Sprite, initial = { x = twoCardX, y = 26 },
                steps = {
                    {
                        duration = 0.5,
                        easing = { x = Ease.outQuart, y = Ease.inQuad },
                        to = { x = 1, y = 69 - 1 },
                    }
                }
            },
            {
                sprite = hand1Sprite, initial = { x = twoCardX + 11, y = 26 },
                steps = {
                    {
                        duration = 0.5,
                        -- easing = Ease.outQuart,
                        to = { x = oneCardX },
                    }
                }
            }
        }
    }, { sprite = hand2Sprite, x = 1, y = 68 }
end

local function SwapHandsAnimationLTR(width, height, unpackingHand, packingHand)
    local unpackingSprite = HandModule.makeSprite(unpackingHand)
    local packingSprites = _.map(packingHand, function(c) return HandModule.makeSprite({ c }) end)

    -- local cardWidth = HandModule.getDeckDims(1)
    local oneCardX = calculateHandCenter(width, height, unpackingSprite.width)
    local yCardX = calculateHandCenter(width, height, HandModule.getDeckDims(#packingHand))

    return { nobg = true,
        {
            {
                sprite = unpackingSprite, initial = { x = 1, y = 68 },
                steps = {
                    {
                        duration = 0.5,
                        easing = { x = Ease.inQuad, y = Ease.outQuart },
                        to = { x = oneCardX, y = 26 },
                    }
                }
            },
            unpack(_.map(packingSprites, function(s, i) return {
                sprite = s, initial = { x = yCardX + (i-1)*11, y = 26 },
                steps = {
                    {
                        duration = 0.5,
                        easing = { x = Ease.outQuart, y = Ease.inQuad },
                        to = { x = width-21, y = 69 - 1 },
                    }
                }
            } end))
        }
    }, { sprite = packingSprites[#packingSprites], x = width-21, y = 68 }
end

local function SwapHandsAnimationRTL(width, height, unpackingHand, packingHand)
    local packingSprites = _.map(packingHand, function(c) return HandModule.makeSprite({ c }) end)
    local unpackingSprites = _.map(unpackingHand, function(c) return HandModule.makeSprite({ c }) end)

    -- local cardWidth = HandModule.getDeckDims(1)
    local unpackingCardsX = calculateHandCenter(width, height, HandModule.getDeckDims(#unpackingHand))
    local packingCardsX = calculateHandCenter(width, height, HandModule.getDeckDims(#packingHand))

    return { nobg = true,
        _.flat {
            -- {
            --     sprite = unpackingSprite, initial = { x = width-21, y = 68 },
            --     steps = {
            --         {
            --             duration = 0.5,
            --             easing = { x = Ease.inQuad, y = Ease.outQuart },
            --             to = { x = unpackingCardsX, y = 26 },
            --         }
            --     }
            -- },
            _.map(unpackingSprites, function(s, i) return {
                sprite = s, initial = { x = width-21, y = 68 },
                steps = {
                    {
                        duration = 0.5,
                        easing = { x = Ease.inQuad, y = Ease.outQuart },
                        to = { x = unpackingCardsX + (i-1)*11, y = 26 },
                    }
                }
            } end),
            _.map(packingSprites, function(s, i) return {
                sprite = s, initial = { x = packingCardsX + (i-1)*11, y = 26 },
                steps = {
                    {
                        duration = 0.5,
                        easing = { x = Ease.outQuart, y = Ease.inQuad },
                        to = { x = 1, y = 69 - 1 },
                    }
                }
            } end)
        }
    }, { sprite = packingSprites[#packingSprites], x = 1, y = 68 }
end

---@param props { player: Player, hands: PlayerHand[], activeHand: integer, x: integer, y: integer, width: integer, height: integer, clear: integer}
return Solyd.wrapComponent("AnimatedPlayerHands", function(props)
    local lastHands = Solyd.useRef(function() return _.copyDeep { props.hands, props.activeHand } end)
    local currentAnimation = Solyd.useRef(function() return nil --[[@as AnimationSets]] end)
    local bgSprite = Solyd.useRef(function() return nil --[[@as { sprite: PixelCanvas, x: integer, y: integer }]] end)

    -- local currentHandSprite = Solyd.useRef(function() return {} end)

    local currentHand = props.hands[props.activeHand]
    local lastHand = lastHands.value[1][lastHands.value[2]]
    if props.activeHand ~= lastHands.value[2] then
        -- switch
        local hand1 = lastHands.value[1][lastHands.value[2]]
        local hand2 = props.hands[props.activeHand]
        if props.activeHand == 1 then
            currentAnimation.value, bgSprite.value = SwapHandsAnimationRTL(props.width, props.height, hand2, hand1)
        else
            currentAnimation.value, bgSprite.value = SwapHandsAnimationLTR(props.width, props.height, hand2, hand1)
        end
        lastHands.value = _.copyDeep { props.hands, props.activeHand }
    elseif #props.hands > #lastHands.value[1] then
        -- split
        currentAnimation.value, bgSprite.value = SplitHandsAnimation(props.width, props.height, props.hands[1], props.hands[2])
        lastHands.value = _.copyDeep { props.hands, props.activeHand }
    elseif #currentHand > #lastHand then
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
            if props.player.animationKey then
                Animation.animationFinished[props.player.animationKey] = true
                props.player.animationKey = nil
            end
            -- restingState.value = render
        end

        -- return render
    -- else
    --     return restingState.value
    end

    return _.append(_.map(visibleSets.value, function(set)
        return RenderCanvas { canvas = set.sprite, x = set.x + props.x, y = set.y + props.y, remap = { [colors.lime] = props.clear } }
    end), (not (currentAnimation.value and currentAnimation.value.nobg)) and bgSprite.value and RenderCanvas { canvas = bgSprite.value.sprite, x = bgSprite.value.x + props.x, y = bgSprite.value.y + props.y, remap = { [colors.lime] = props.clear } })
end)
