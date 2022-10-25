local util = require("util.misc")

local Solyd = require("modules.solyd")
local AnimationRunner = require("modules.animation")
local Hooks = require("modules.hooks")
local useAnimation = Hooks.useAnimation
local Animation = require("modules.hooks.animation")
local Ease = require("modules.animation.Ease")
local display = require("modules.display")

local ChipGroup = require("components.ChipGroup")

return Solyd.wrapComponent("Payout", function(props)
    local canvas = Solyd.useContext("canvas")

    local animation = Solyd.useMemo(function()
        local sprite = util.bakeToCanvas(ChipGroup {
            amount = props.amount,
            x = 1,
            y = 1,
            nocenter = true
        })

        return {
            sprite = sprite, initial = { x = display.bgCanvas.width/2, y = -sprite.height-3 },
            steps = {
                {
                    duration = 1,
                    easing = { x = Ease.inOutQuad, y = Ease.outInQuad },
                    to = { x = props.targetX, y = props.targetY },
                }
            }
        }
    end, { props.amount, props.targetX, props.targetY })

    local t = useAnimation(true)
    local state, _, finished = AnimationRunner.evaluateSingleAnimation(animation, t)

    if finished then
        Animation.animationFinished[props.animationKey] = true
    end

    local x, y = math.floor((state.x - state.sprite.width + 1)/2)*2, math.floor((state.y - state.sprite.height + 1)/3)*3
    return nil, { canvas = { state.sprite, x, y } }
end)
