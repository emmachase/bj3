local Solyd = require("modules.solyd")

local Cards = require("modules.cards")
local HandModule = require("components.Hand")
local Hand = HandModule.Hand


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

    local dealerContext = Solyd.useContext("dealerContext")

    local cards = Solyd.useRef(function()
        local hidden = table.remove(dealerContext.deck, 1)
        hidden.hidden = true

        return { table.remove(dealerContext.deck, 1), hidden }
    end)

    if dealerContext.revealed then
        cards.value[2].hidden = false
    end

    return {
        Hand { x=150, y=100, cards = cards.value },
    }

end)

return {
    Dealer = Dealer,
    getDealerContext = getDealerContext
}
