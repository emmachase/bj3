-- Read 8-bit signed pcm from file

local base64 = require("util.base64")
local data = base64.decode(require("audio.cardFan2"))

-- local handle = fs.open("audio/cardFan2.u8", "rb")
-- local data = handle.readAll()
-- handle.close()

local samples = {}
for i = 1, #data do
    samples[i] = data:byte(i) - 128
end

local speaker = peripheral.find("speaker")
local bSize = 1024*16

local t, dt = 0, 2 * math.pi * 220 / 48000

local function play()
    local position = 0
    local buffer
    while position < #samples do
        buffer = {}
        for i = 1, bSize do
            -- buffer[i] = math.floor(127*math.sin((i+position)/(400))) --samples[i+position] or 0
            -- print(buffer[i])
            buffer[i] = 1.5*(samples[i+position] or 0)
            -- buffer[i] = 0.5*math.floor(math.sin(t) * 127)
            -- t = (t + dt) % (math.pi * 2)
        end
        position = position + bSize

        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
        -- if position > #samples then
        --     return
        -- end
    end
end

play()
