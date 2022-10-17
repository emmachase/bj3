local score = {}

---Applies {fun} to each element of {list} and returns a list of the results.
---@generic T, U
---@param list T[]
---@param fun fun(x: T): U
---@return U[]
function score.map(list, fun)
    local result = {__type = "list"}
    for i, v in ipairs(list) do
        result[i] = fun(v)
    end
    return result
end

function score.range(start, stop, step)
    local result = {__type = "list"}
    if step == nil then
        step = 1
    end
    if stop == nil then
        stop = start
        start = 1
    end
    for i = start, stop, step do
        result[#result + 1] = i
    end
    return result
end

function score.rangeMap(start, stop, step, fun)
    if type(start) == "function" then
        fun = start
        start = 1
        stop = nil
        step = nil
    elseif type(stop) == "function" then
        fun = stop
        stop = start
        start = 1
        step = nil
    elseif type(step) == "function" then
        fun = step
        step = 1
    end

    return score.map(score.range(start, stop, step), fun)
end

---Returns a list of the elements from {list} that satisfy the predicate {fun}.
---@generic T
---@param list T[]
---@param fun fun(x: T): boolean
---@return T[]
function score.filter(list, fun)
    local result = {__type = "list"}
    for i, v in ipairs(list) do
        if fun(v) then
            result[#result + 1] = v
        end
    end
    return result
end

function score.intersectSeq(list1, list2)
    local result = {__type = "list"}
    if #list1 > #list2 then
        list1, list2 = list2, list1
    end

    for i = #list1 + 1, #list2 do
        result[#result + 1] = list2[i]
    end
    return result
end

function score.flat(list)
    local result = {__type = "list"}
    for i, v in ipairs(list) do
        if v.__type == "list" then
            for j, w in ipairs(v) do
                result[#result + 1] = w
            end
        else
            result[#result + 1] = v
        end
    end
    return result
end

---Fisher yates shuffle
---@generic T
---@param list T[]
---@return T[]
function score.shuffle(list)
    local n = #list
    while n > 2 do
        local k = math.random(n)
        list[n], list[k] = list[k], list[n]
        n = n - 1
    end
    return list
end

function score.append(list, value)
    list = {unpack(list)}
    list[#list + 1] = value
    return list
end

return score
