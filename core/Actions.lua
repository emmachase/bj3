local Cards = require("modules.cards")

local function canHit(player, hand)
    local optimalHand = Cards.getHandValue(hand, true, false)
    return optimalHand < 21
    and not hand.didDoubleDown
    and not hand.didStand
    -- return not hand.didDoubleDown
end

local function canDealerHit(dealer, hand)
    local optimalHand = Cards.getHandValue(hand, true, false)
    return optimalHand < 17
end

-- local function canStand

---@param player Player
---@param hand PlayerHand
local function canDoubleDown(player, hand)
    return #hand == 2
    and player.money >= hand.bet
    -- and not hand.didDoubleDown
end

---@param player Player
---@param hand PlayerHand
local function canSplit(player, hand)
    return #hand == 2
    and player.money >= hand.bet
    and Cards.baseValue[hand[1].rank] == Cards.baseValue[hand[2].rank]
    -- and not hand.didDoubleDown
end

return {
    canHit = canHit,
    canDealerHit = canDealerHit,
    canDoubleDown = canDoubleDown,
    canSplit = canSplit,
}
