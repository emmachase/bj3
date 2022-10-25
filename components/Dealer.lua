local Solyd = require("modules.solyd")

local Cards = require("modules.cards")

local BigText = require("components.BigText")
local HandModule = require("components.Hand")
local Hand = HandModule.Hand

local Animation = require("modules.hooks.animation")

local function getDealerContext(standCount)
    local revealed, setRevealed = Solyd.useState(false)
    if standCount == 3 and not revealed then
        revealed = setRevealed(true)
    end

    local deck = Solyd.useRef(Cards.newDeck)

    return {
        deck = deck.value,
        revealed = revealed,
        setRevealed = setRevealed
    }
end

local Dealer = Solyd.wrapComponent("Dealer", function(props)
    -- local cards = Solyd.useRef(function()
    --     local hidden = table.remove(dealerContext.deck, 1)
    --     hidden.hidden = true

    --     return { table.remove(dealerContext.deck, 1), hidden }
    -- end)

    -- if dealerContext.revealed then
    --     cards.value[2].hidden = false
    -- end

    local gameState = Solyd.useContext("gameState") ---@type GameState

    -- local numCards, setNumCards = Solyd.useState(0)
    -- local anim = Animation.useAnimation(numCards ~= #gameState.dealer.hand)
    -- if anim and anim > 0.25 and numCards ~= #gameState.dealer.hand then
    --     setNumCards(#gameState.dealer.hand)
    for i = 1, #gameState.dealer.hand do
        Animation.animationFinished[gameState.dealer.hand[i].uid] = true
    end

    local cards = gameState.dealer.hand
    local softValue = Cards.getHandValue(cards, false, true)
    local hardValue = Cards.getHandValue(cards, false, false)

    local isBlackjack, valueText = false, nil
    if hardValue == 21 and #cards == 2 then
        valueText = "Blackjack"
        isBlackjack = true
    elseif softValue > 0 then
        if softValue == hardValue then
            valueText = tostring(softValue)
        else
            valueText = tostring(softValue) .. "/" .. tostring(hardValue)
        end
    end


    -- end
    -- print("rerender", #gameState.dealer.hand)

    -- if #gameState.dealer.hand == 0 then
    --     print("wpo")
    --     return {
    --         Hand { x=150, y=100, cards = cards.value },
    --     }
    -- else
    -- if #gameState.dealer.hand > 0 then
    -- print("isopqaue", gameState.dealer.hand)
    -- print("rerender")
        return {
            Hand { x=150, y=92, cards = {unpack(gameState.dealer.hand)} },

            BigText {
                x = 150,
                y = 122,
                -- width = 50,
                text = valueText or "",
                color = colors.white,
                bg = valueText and colors.green or nil,
            },
        }
        
    -- end
    -- end

end)

return {
    Dealer = Dealer,
    getDealerContext = getDealerContext
}
