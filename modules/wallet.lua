local wallets = {}

local function getWallet(playerId)
    local wallet = wallets[playerId]
    if not wallet then
        wallet = {
            playerId = playerId,
            balance = 0
        }
        wallets[playerId] = wallet
    end

    return wallet
end

return {
    getWallet = getWallet
}
