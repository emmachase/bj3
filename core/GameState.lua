local Actions = require("core.Actions")
local Cards = require("modules.cards")
local Wallet = require("modules.wallet")

local Iterators = require("util.iter")
local list = Iterators.list

---@alias Player { hand: PlayerHand, bet: integer?, money: integer }
---@alias Dealer { hand: PlayerHand }

---@class GameState
---@field deck Card[]
---@field dealer Dealer
---@field players Player[]
---@field running boolean
local GameState = {}
local GameState_mt = { __index = GameState }

function GameState.new()
    local self = setmetatable({}, GameState_mt)

    self.deck = Cards.newDeck()
    self.dealer = {hand = {}}
    self.players = {}
    self.running = false

    return self
end

local function waitForAnimation(uid)
    coroutine.yield("animationFinished", uid)
end

local function playerList(xs)
    local i = 4
    return function()
        if i == 1 then return end

        repeat
            i = i - 1
            if xs[i] then
                return xs[i]
            end
        until i <= 1
    end
end

function GameState:playersReady()
    local ready, count = 0, 0
    for player in playerList(self.players) do
        if player.bet then
            ready = ready + 1
        end
        count = count + 1
    end

    return count > 0 and ready == count
end

local cardUid = 0
function GameState:dealTo(hand, hidden)
    local card = table.remove(self.deck, 1)
    cardUid = cardUid + 1
    card.uid = cardUid
    if hidden then
        card.hidden = true
    end

    table.insert(hand, card)
    waitForAnimation(card.uid)
end

function GameState:processAction(player, hand, input)
    if input == "hit" then
        self:dealTo(hand)
    elseif input == "stand" then
        hand.didStand = true
    elseif input == "double" then
        local wallet = Wallet.getWallet(player.entity.id)
        wallet.balance = wallet.balance - hand.bet
        hand.bet = hand.bet * 2
        self:dealTo(hand)
        hand.didDoubleDown = true
    elseif input == "split" then
        -- TODO
    end
end

-- Anytime the game state is resumed, animation should be finished instantly. (call animation finish hooks)
local function runGame(state)
    state.running = false
    while not state:playersReady() do
        coroutine.yield()
    end

    -- Game is starting
    state.running = true

    -- Set bets
    for player in playerList(state.players) do
        player.hand.bet = player.bet
    end

    for i = 1, 2 do
        for player in playerList(state.players) do
            print("Dealing to player")
            state:dealTo(player.hand)
        end
        print("Dealing to dealer")
        state:dealTo(state.dealer.hand, --[[hidden:]] i == 2)
    end

    for player in playerList(state.players) do
        while Actions.canHit(player, player.hand) do
            print("Waiting for player")
            player.requestInput = true

            while player.input == nil do
                coroutine.yield()
            end

            player.requestInput = false

            state:processAction(player, player.hand, player.input)
            player.input = nil
        end

        -- player.
        -- coroutine.yield("waitForPlayerInput", player)
    end

    -- Reveal hole
    state.dealer.hand[2].hidden = false

    -- Dealer hits until 17
    while Actions.canDealerHit(state.dealer, state.dealer.hand) do
        print("Waiting for dealer")
        state:dealTo(state.dealer.hand)
    end
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