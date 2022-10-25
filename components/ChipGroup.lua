local _ = require("util.score")

local Solyd = require("modules.solyd")

local ChipStack = require("components.ChipStack")

local function makeStacks(amount)
    local num100Chips = math.floor(amount/100)
    local num25Chips  = math.floor((amount - num100Chips*100)/25)
    local num10Chips  = math.floor((amount - num100Chips*100 - num25Chips*25)/10)
    local num5Chips   = math.floor((amount - num100Chips*100 - num25Chips*25 - num10Chips*10)/5)
    local num1Chips   = math.floor((amount - num100Chips*100 - num25Chips*25 - num10Chips*10 - num5Chips*5)/1)

    local stacks = {}
    if num1Chips   > 0 then stacks[#stacks+1] = { value =   1, count = num1Chips   } end
    if num5Chips   > 0 then stacks[#stacks+1] = { value =   5, count = num5Chips   } end
    if num10Chips  > 0 then stacks[#stacks+1] = { value =  10, count = num10Chips  } end
    if num25Chips  > 0 then stacks[#stacks+1] = { value =  25, count = num25Chips  } end
    if num100Chips > 0 then stacks[#stacks+1] = { value = 100, count = num100Chips } end

    return stacks
end

---@param props { x: integer, y: integer, amount: integer, nocenter: boolean?, clear: integer? }
return Solyd.wrapComponent("ChipGroup", function(props)
    local stacks = makeStacks(props.amount)

    local x = props.x - #stacks*10/2
    if props.nocenter then
        x = props.x
    end

    return _.map(stacks, function(stack)
        local chipStack = ChipStack {
            x = x,
            y = props.y,
            chipValue = stack.value,
            chipCount = stack.count,
            clear = props.clear or colors.lime,
            key = stack.value,
        }
        if stack.count >0 then
        x = x + 10
    end
        return chipStack
    end)
end)
