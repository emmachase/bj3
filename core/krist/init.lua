local logger = require("modules.logger")

local commonmeta = require("core.krist.commonmeta")
local wallets = require("modules.wallet")
-- local sensor = peripheral.find("manipulator")

local Krist = {}

local config, websocket
local gameState ---@type GameState

function Krist.start(newGameState)
    config = dofile("config.lua")
    Krist.config = config

    local startUrl = http.post("https://" .. config.node .. "/ws/start", "privatekey="..config.pkey)
    local startData = textutils.unserializeJSON(startUrl.readAll())

    websocket = http.websocket(startData.url)
    websocket.send(textutils.serializeJSON({
        id=1,
        type="get_subscription_level"
    }))
    gameState = newGameState
end

function Krist.stop()
    websocket.close()
end

function Krist.restart()
    websocket = http.websocket(websocket.url)
end

local function findUUID(name)
    if name == nil then return nil end
    for _, player in pairs(gameState.players) do
        local entity = player.entity
        if entity.name:lower() == name:lower() then
            return entity.id
        end
    end
end

function Krist.refund(reason, transaction, meta)
    if not meta then
        meta = commonmeta.parse(transaction.metadata)
    end

    local returnTo = transaction.from
    if meta and meta.meta["return"] then
        returnTo = meta.meta["return"]
    end

    Krist.pay(reason, returnTo, transaction.value)
end

function Krist.pay(meta, to, amount)
    amount = math.floor(amount)
    if amount <= 0 then
        return
    end

    logger.log("Sending " .. amount .. " KST to " .. to .. " with metadata " .. meta)

    http.request("https://" .. config.node .. "/transactions", textutils.serializeJSON({
        privatekey = config.pkey,
        to = to:lower(),
        amount = amount,
        metadata = meta
    }), {["Content-Type"] = "application/json"})
end

function Krist.handleTransaction(transaction)
    if transaction.to == config.address then
        local meta = commonmeta.parse(transaction.metadata)
        if transaction.sent_name == config.name and transaction.sent_metaname == config.metaname then -- meta.domain == config.name then
            logger.log("Received transaction from " .. transaction.from .. " (user: " .. (meta and meta.meta.username or "UNKNOWN") .. ") of " .. transaction.value .. " KST")

            local target = meta and meta.meta.username
            local uuid = findUUID(target)
            if not uuid then
                Krist.refund("error=You're not part of the game, click a spot to join first", transaction, meta)
                return
            end

            local wallet = wallets.getWallet(uuid)
            wallet.balance = wallet.balance + transaction.value
            gameState:resetTimeouts(true)
        end
    end
end

return Krist
