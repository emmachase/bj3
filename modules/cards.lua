local _ = require("util.score")

---@class Card
---@field suit "spades" | "hearts" | "diamonds" | "clubs"
---@field rank "A" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "10" | "J" | "Q" | "K"
---@field hidden boolean?

---@alias PlayerHand { bet: integer, [integer]: Card }

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
    local deck = {__opaque = true}
    for _, suit in ipairs(suits) do
        for _, rank in ipairs(ranks) do
            deck[#deck + 1] = { suit = suit, rank = rank } -- math.random()>0.5 and "A" or "10" }
        end
    end
    return _.shuffle(deck)
end


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

return {
    newDeck = newDeck,
    getHandValue = getHandValue,

    cardToString = function(card)
        return card.rank .. " of " .. card.suit
    end,

    suits = suits,
    ranks = ranks,
    baseValue = baseValue,
}
