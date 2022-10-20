local Solyd = require("modules.solyd")

local Cards = require("modules.cards")
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
        return Hand { x=150, y=100, cards = {unpack(gameState.dealer.hand)} }
        
    -- end
    -- end

end)

return {
    Dealer = Dealer,
    getDealerContext = getDealerContext
}
