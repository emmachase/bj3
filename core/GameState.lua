local Cards = require("modules.cards")
local Iterators = require("util.iter")
local list = Iterators.list

---@alias Player { hand: Card[], bet: integer? }
---@alias Dealer { hand: Card[] }

---@class GameState
---@field deck Card[]
---@field dealer Dealer
---@field players Player[]
local GameState = {}
local GameState_mt = { __index = GameState }

function GameState.new()
    local self = setmetatable({}, GameState_mt)

    self.deck = Cards.newDeck()
    self.dealer = {hand = {}}
    self.players = {}

    return self
end

local function waitForAnimation()
    coroutine.yield("animationFinished")
end

function GameState:dealTo(player, hidden)
    local card = table.remove(self.deck, 1)
    if hidden then
        card.hidden = true
    end

    table.insert(player.hand, card)
    waitForAnimation()
end

-- Anytime the game state is resumed, animation should be finished instantly. (call animation finish hooks)
local function runGame(state)
    for i = 1, 2 do
        for player in list(state.players) do
            state:dealTo(player)
        end
        state:dealTo(state.dealer, --[[hidden:]] i == 2)
    end

    coroutine.yield("waitForPlayerInput")
end

return {
    GameState = GameState,
    runGame = runGame,
}

--[[

Dealer StateMachine:

    init
        - (condition: none) -> deal

    deal (entry action: dealHands)

    dealerTurnEnd

]]