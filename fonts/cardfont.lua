local loadRIF = require("modules.rif")
local createFont = require("modules.font")

local cardFontSheet = loadRIF("font")
local cardFont = createFont(cardFontSheet, " 0123456789AJQK")

return cardFont
