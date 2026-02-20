--[[ use this to work

_G.traittokens= true
_G.stars= true
_G.luckpotion= true
_G.dropspotion= true
_G.ascendticket= true
_G.statchips= true 
loadstring(game:HttpGet("https://raw.githubusercontent.com/JustLegits/miscscript/main/AnimeStoryCoinshop.lua",true))()

]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("API"):WaitForChild("Utils"):WaitForChild("network"):WaitForChild("RemoteEvent")

-- Stock amounts
local ITEM_STOCKS = {
    ["Ascend Ticket"] = 1,
    ["Drops Potion I"] = 1,
    ["Elite Stat Chips"] = 3,
    ["Green Star"] = 10,
    ["Luck Potion I"] = 1,
    ["Purple Star"] = 5,
    ["Red Star"] = 5,
    ["Stat Chips"] = 10,
    ["Trait Tokens"] = 10,
    ["Yellow Star"] = 5
}

-- Map _G variables to the exact in-game item names
local itemMappings = {
    traittokens = {"Trait Tokens"},
    stars = {"Green Star", "Purple Star", "Red Star", "Yellow Star"},
    luckpotion = {"Luck Potion I"},
    luckpotions = {"Luck Potion I"}, 
    dropspotion = {"Drops Potion I"},
    ascendticket = {"Ascend Ticket"},
    statchips = {"Stat Chips", "Elite Stat Chips"}
}

local function attemptPurchase()
    for globalKey, exactNames in pairs(itemMappings) do
        -- If you turned this option to true in your executor...
        if _G[globalKey] == true then
            for _, itemName in ipairs(exactNames) do
                local stockAmt = ITEM_STOCKS[itemName]
                
                if stockAmt then
                    local args = {
                        "shop_purchase",
                        "Coins Shop",
                        itemName
                    }
                    
                    -- Buy the exact hardcoded amount
                    for i = 1, stockAmt do
                        pcall(function()
                            remote:FireServer(unpack(args))
                        end)
                        task.wait(0.5) -- delay to prevent remote spam kicks
                    end
                end
            end
        end
    end
end

-- Start the infinite background loop
task.spawn(function()
    while true do
        pcall(attemptPurchase)
        task.wait(1200)
    end
end)
