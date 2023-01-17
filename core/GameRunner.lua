local GameState = require("core.GameState")

local Animations = require("modules.hooks.animation")

local function areAnimationsFinished(uid)
    local finished = Animations.animationFinished[uid]
    if finished then
        Animations.animationFinished[uid] = nil
        return true
    end

    return false
end

local function isPlayerInputReady()
    return false -- TODO
end

local function launchGame(gameState, mainFunction)
    local gameCoroutine = coroutine.create(function() GameState.runGame(gameState) end)
    local mainCoroutine = coroutine.create(mainFunction)

    local gameFilter ---@type "animationFinished" | "waitForPlayerInput"
    local uidFilter

    local eventFilter
    local eventBacklog = {}

    while true do
        local e = (eventFilter == nil and #eventBacklog > 0) and table.remove(eventBacklog, 1) or { os.pullEventRaw() }

        if e[1] == "terminate" then
            break
        end

        if eventFilter and e[1] ~= eventFilter then
            eventBacklog[#eventBacklog+1] = e
        else
            local status, result = coroutine.resume(mainCoroutine, unpack(e))
            eventFilter = result
            if not status then
                error(result)
            end
        end

        if coroutine.status(mainCoroutine) == "dead" then
            break
        end

        local canResume = coroutine.status(gameCoroutine) ~= "dead" -- true
        if gameFilter == "animationFinished" then
            canResume = areAnimationsFinished(uidFilter)
        elseif gameFilter == "waitForPlayerInput" then
            canResume = isPlayerInputReady()
        elseif gameFilter == "timer" then
            canResume = e[1] == "timer" and e[2] == uidFilter
        end

        if canResume then
            -- print("resuming...")
            status, gameFilter, uidFilter = coroutine.resume(gameCoroutine)

            if not status then
                error(gameFilter)
            end

            if coroutine.status(gameCoroutine) == "dead" then
                -- TODO: Reset game state
                -- gameCoroutine = coroutine.create(GameState.runGame)
                -- error("oops")
            end
        end
    end
end

return {
    launchGame = launchGame,
}
