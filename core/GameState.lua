local Actions = require("core.Actions")
local Cards = require("modules.cards")
local Wallet = require("modules.wallet")
local Krist = require("core.krist")

local Iterators = require("util.iter")
local list = Iterators.list

---@alias PlayerEntity { id: string, name: string, displayName: string }
---@alias Player { hands: PlayerHand[], activeHand: integer, bet: integer?, entity: PlayerEntity }
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

function GameState:resetGame()
    self.deck = Cards.newDeck()
    self.dealer = {hand = {}}
    for i = 1, 3 do
        if self.players[i] then
            self.players[i].hands = { {} }
            self.players[i].bet = nil
            self.players[i].activeHand = 1
        end
    end
    self.running = false
end

function GameState:removePlayer(playerId)
    local player = self.players[playerId]
    self.players[playerId] = nil

    -- Check if there are any remaining players with the same UUID
    for _, player2 in pairs(self.players) do
        if player2.entity.id == player.entity.id then
            return
        end
    end

    -- Otherwise, we need to cash out the player
    local wallet = Wallet.getWallet(player.entity.id)
    Krist.pay("message=Congratulations! Here are your winnings!", player.entity.name .. "@sc.kst", wallet.balance)
    wallet.balance = 0
end

local function waitForAnimation(uid)
    coroutine.yield("animationFinished", uid)
end

---@generic T
---@param xs T[]
---@return fun(): T
local function playerList(xs)
    local i = 4
    return function()
        if i == 1 then return end

        repeat
            i = i - 1
            if xs[i] then
                return xs[i], i
            end
        until i <= 1
    end
end

local startTimeoutAt
function GameState:resetTimeouts(soft)
    if soft and startTimeoutAt == nil then
        return
    end

    startTimeoutAt = os.epoch("utc") + 20*1000

    -- Reset the timer for all players
    for player2 in playerList(self.players) do
        player2.timeoutAt = startTimeoutAt
        player2.startTimeoutAt = os.epoch("utc")
    end
end

function GameState:playersReady()
    local ready, count = 0, 0
    for player in playerList(self.players) do
        if player.bet then
            ready = ready + 1
        end
        count = count + 1

        if player.timeoutAt == nil then
            self:resetTimeouts()
        end
    end

    if count == 0 then
        startTimeoutAt = nil
    end

    if startTimeoutAt and os.epoch("utc") > startTimeoutAt then
        for player, playerId in playerList(self.players) do
            if not player.bet then
                -- Remove player
                self:removePlayer(playerId)
            end
        end
        startTimeoutAt = nil
        return ready > 0
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
    coroutine.yield() -- Allow animation buffer to clear
end

function GameState:processAction(player, hand, input)
    if input == "hit" then
        self:dealTo(hand)
    elseif input == "stand" then
        hand.didStand = true
    elseif input == "double" then
        local wallet = Wallet.getWallet(player.entity.id)
        wallet.balance = wallet.balance - hand.bet
        player.bet = player.bet + hand.bet
        hand.bet = hand.bet * 2
        self:dealTo(hand)
        hand.didDoubleDown = true
    elseif input == "split" then
        local wallet = Wallet.getWallet(player.entity.id)
        wallet.balance = wallet.balance - hand.bet
        player.hands = { { bet = hand.bet, hand[2] }, { bet = hand.bet, hand[1] } }

        cardUid = cardUid + 1
        player.animationKey = cardUid
        waitForAnimation(cardUid)
        coroutine.yield()
    end
end

-- Anytime the game state is resumed, animation should be finished instantly. (call animation finish hooks)
---@param state GameState
local function runGame(state)
    state.running = false
    while not state:playersReady() do
        coroutine.yield()
    end

    -- Game is starting
    state.running = true
    startTimeoutAt = nil

    -- Set bets
    for player in playerList(state.players) do
        player.timeoutAt = nil
        player.startTimeoutAt = nil

        player.hands[1].bet = player.bet
    end

    for i = 1, 2 do
        for player in playerList(state.players) do
            -- print("Dealing to player")
            state:dealTo(player.hands[1])
        end
        -- print("Dealing to dealer")
        state:dealTo(state.dealer.hand, --[[hidden:]] i == 2)
    end

    for player in playerList(state.players) do
        while true do
            if #player.hands[player.activeHand] < 2 then
                state:dealTo(player.hands[player.activeHand])
            end

            while Actions.canHit(player, player.hands[player.activeHand]) do
                -- print("Waiting for player")
                player.requestInput = true

                local timeoutAt = os.epoch("utc") + 10*1000
                player.timeoutAt = timeoutAt
                player.startTimeoutAt = os.epoch("utc")

                while player.input == nil do
                    coroutine.yield()

                    if os.epoch("utc") > timeoutAt then
                        player.input = "stand"
                    end
                end

                player.requestInput = false
                player.timeoutAt = nil
                player.startTimeoutAt = nil

                state:processAction(player, player.hands[player.activeHand], player.input)
                player.input = nil

                if #player.hands[player.activeHand] < 2 then
                    state:dealTo(player.hands[player.activeHand])
                end
            end

            if player.activeHand == #player.hands then
                break
            else
                if Actions.isSpecial(player, player.hands[player.activeHand]) then
                    local displayTimer = os.startTimer(1)
                    coroutine.yield("timer", displayTimer)
                end

                player.activeHand = player.activeHand + 1
                cardUid = cardUid + 1
                player.animationKey = cardUid
                waitForAnimation(cardUid)
            end

            coroutine.yield() -- Give buffer frame for animations
        end

        -- player.
        -- coroutine.yield("waitForPlayerInput", player)
    end

    -- Reveal hole
    state.dealer.hand[2].hidden = false

    -- Dealer hits until 17
    while Actions.canDealerHit(state.dealer, state.dealer.hand) do
        -- print("Waiting for dealer")
        state:dealTo(state.dealer.hand)
    end

    local displayTimer = os.startTimer(1)
    coroutine.yield("timer", displayTimer)

    -- Pay out bets
    for player in playerList(state.players) do
        local wallet = Wallet.getWallet(player.entity.id)
        for handIndex = #player.hands, 1, -1 do --, hand in ipairs(player.hands) do
            local hand = player.hands[handIndex]

            -- Switch to the hand if not already on it
            if player.activeHand ~= handIndex then
                player.activeHand = handIndex
                cardUid = cardUid + 1
                player.animationKey = cardUid
                waitForAnimation(cardUid)

                displayTimer = os.startTimer(1)
                coroutine.yield("timer", displayTimer)
            end

            local payout, message = Actions.payout(player, hand, state.dealer)
            player.message = message

            if payout - hand.bet > 0 then
                -- Play animation
                player.payout = payout - hand.bet
                cardUid = cardUid + 1
                player.animationKey = cardUid
                waitForAnimation(cardUid)
                player.payout = nil
            end

            wallet.balance = wallet.balance + payout

            -- Allow time to read message
            displayTimer = os.startTimer(0.75)
            coroutine.yield("timer", displayTimer)
            player.message = nil
        end
    end

    state:resetGame()

    return runGame(state) -- Tail call optimization go brr
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