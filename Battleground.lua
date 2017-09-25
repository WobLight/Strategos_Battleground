local S, SB
if StrategosCore == nil then 
    StrategosCore = {}
end

if StrategosBattleground == nil then 
    StrategosBattleground = {}
end

S = StrategosCore
setmetatable(S, {__index = getfenv() })
setfenv(1, S)

SB = StrategosBattleground
Object.attach(StrategosBattleground, {"newBattleground"})
setmetatable(SB, {__index = getfenv() })
setfenv(1, SB)

StrategosMinimapPlugin = {
    name = "Battleground"
}

EventHandler = CreateFrame("frame")
local Strategos_EventList = {
    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED",
    "CHAT_MSG_BG_SYSTEM_NEUTRAL",
    "CHAT_MSG_BG_SYSTEM_ALLIANCE",
    "CHAT_MSG_BG_SYSTEM_HORDE",
    "CHAT_MSG_MONSTER_YELL",
    "PLAYER_ENTERING_WORLD",
    "UPDATE_WORLD_STATES",
    "UPDATE_BATTLEFIELD_SCORE"
}

EventHandler:SetScript("OnEvent",function()
    local handle = EventHandler[event]
    if handle then
        handle(this)
    else
        debug("unhandled event \""..event.."\"")
    end
end)

EventHandler:SetScript("OnUpdate", function()
    if currentBattleground then
        currentBattleground:update()
    end
end)

function register()
    for _, e in Strategos_EventList do
        EventHandler:RegisterEvent(e)
    end
end
register()
function unregister()
    for _, e in Strategos_EventList do
        EventHandler:UnregisterEvent(e)
    end
end

function EnteringZone()
    local zone = GetRealZoneText()
    if currentBattleground and currentBattleground.zone ~= zone then
        currentBattleground:_leave()
        currentBattleground = nil
    end
    if not currentBattleground then
        if zone == "Warsong Gulch" then
            currentBattleground = WarsongGulch:new()
        elseif zone == "Arathi Basin" then
            currentBattleground = ArathiBasin:new()
        elseif zone == "Alterac Valley" then
            currentBattleground = AlteracValley:new()
        end
        if currentBattleground then
            SB:newBattleground(currentBattleground)
            currentBattleground:init()
        end
    end
end

function HandleMessage(message, faction)
    if faction <= 0 then
        if strfind(message, "[aA]lliance") then
            faction = 1
        elseif strfind(message, "[Hh]orde") then
            faction = 2
        end
    end
    if currentBattleground then
        currentBattleground:processChatEvent(message,  faction)
    end
end

EventHandler.ZONE_CHANGED_NEW_AREA = EnteringZone
EventHandler.ZONE_CHANGED = EnteringZone
EventHandler.PLAYER_ENTERING_WORLD = EnteringZone

EventHandler.CHAT_MSG_BG_SYSTEM_NEUTRAL = function() HandleMessage(arg1, 0) end
EventHandler.CHAT_MSG_BG_SYSTEM_ALLIANCE = function()  HandleMessage(arg1, 1) end
EventHandler.CHAT_MSG_BG_SYSTEM_HORDE = function()  HandleMessage(arg1, 2) end
EventHandler.CHAT_MSG_MONSTER_YELL = function()  HandleMessage(arg1, -1) end

function EventHandler.UPDATE_WORLD_STATES()
    if currentBattleground then
        currentBattleground:updateWorldStates()
    end
end

function EventHandler.UPDATE_BATTLEFIELD_SCORE()
    if currentBattleground then
        currentBattleground:scoreUpdate()
    end
end

Node = {}

function Node:new(o)
    if type(o) == "string" then
        o = {name = o}
    end
    StrategosCore.Object.attach(o,{"factionChanged"})
    setmetatable(o, self)
    self.__index = self
    o.timer = Timer:new()
    return o
end

function Node:setFaction(faction, contesting)
    if self.faction == faction then
        return
    end
    if contesting then
        self.assaultingFaction = faction
    else
        self.faction = faction
        self.assaultingFaction = faction
    end
    self:factionChanged()
end

Battleground = {}
function Battleground:new()
    local o = { startTimer = Timer:new(), nodes = {} }
    Object.attach(o,{"starting","started","finished"})
    setmetatable(o, self)
    self.__index = self
    if StrategosMinimap then
        StrategosBattlegroundMinimapStarting:setTimer(o.startTimer)
        StrategosMinimapPlugin.frames = { StrategosBattlegroundMinimapStarting }
    end
    local time = GetBattlefieldInstanceRunTime()/1000
    if time ~= 0 and time < 120 then
        o.startTimer:set(120 - time, 120)
        o:starting()
    end
    return o
end

function Battleground:init()
end

function Battleground:update()
end

local ArathiBases = {
    ST = {
        x = 0.3747319206595421,
        y = 0.2917306870222092
    },
    GM = {
        x = 0.5751497000455856,
        y = 0.3086424916982651
    },
    BS = {
        x = 0.4622423946857452,
        y = 0.4537641629576683
    },
    LM = {
        x = 0.4039658159017563,
        y = 0.5570576936006546
    },
    FM = {
        x = 0.5603127181529999,
        y = 0.5996280610561371
    }
}

local AlteracBases = {
    WFWT    = {
        name = "West Frostwolf Tower",
        x = 0.625,
        y = 0.9
    },
    EFWT    = {
        name = "East Frostwolf Tower",
        x = 0.7,
        y = 0.9
    },
    IBT     = {
        name = "Iceblood Tower",
        x = 0.7,
        y = 0.7375
    },
    TP      = {
        name = "Tower Point",
        x = 0.625,
        y = 0.7375
    },
    IBGY    = {
        name =  "Iceblood Graveyard",
        x = 0.3,
        y = 0.60
    },
    FWGY    = {
        name = "Frostwolf Graveyard",
        x = 0.3,
        y = 0.75
    },
    FWRH    = {
        name = "Frostwolf Relief Hut",
        x = 0.3,
        y = 0.9
    },
    DBNB    = {
        name = "Dun Baldar North Bunker",
        x = 0.625,
        y = 0.25
    },
    DBSB    = {
        name = "Dun Baldar South Bunker",
        x = 0.7,
        y = 0.25
    },
    IWB     = {
        name = "Icewing Bunker",
        x = 0.625,
        y = 0.4125
    },
    SHB     = {
        name = "Stonehearth Bunker",
        x = 0.7,
        y = 0.4125
    },
    SPAS    = {
        name = "Stormpike Aid Station",
        x = 0.3,
        y = 0.15
    },
    SPGY    = {
        name = "Stormpike Graveyard",
        x = 0.3,
        y = 0.3
    },
    SHGY    = {
        name = "Stonehearth Graveyard",
        x = 0.3,
        y = 0.45
    },
    SFGY    = {
        name = "Snowfall Graveyard",
        x = 0.6625,
        y = 0.575
    }
}

AlteracPOILookup = {}

function StrategosMinimapPlugin:load()
    CreateFrame("Frame","StrategosBattlegroundMinimapStarting",StrategosMinimap,"StrategosRingFrameTemplate")
    StrategosMinimapPOI:new(StrategosBattlegroundMinimapStarting)
    StrategosBattlegroundMinimapStarting:SetPoint("CENTER",StrategosMinimap)
    StrategosBattlegroundMinimapStarting.buildTooltip = function(self)
        local left = self.timer:remaning()
        local m,s = floor(left/60), mod(left, 60)
        return format("Starting in: %d:%02d", m, s)
    end
    StrategosBattlegroundMinimapStarting.buildMenu = function(self)
        if self.timer:remaning() then
            UIDropDownMenu_AddButton({
                text = "[BG] Starting in...",
                func = function()
                    local left = self.timer:remaning()
                    if left then
                        local m,s = floor(left/60), mod(left, 60)
                        SendChatMessage(format("Starting in: %d:%02d", m, s), "BATTLEGROUND")
                    end
                end
            })
        end
    end
    
    for n,b in ArathiBases do
        local f = getglobal("StrategosMinimapArathiIndicator"..n)
        if not f then
            f = CreateFrame("Frame", "StrategosMinimapArathiIndicator"..n, StrategosMinimap, "StrategosIndicatorFrameTemplate")
            StrategosMinimapPOI:new(f)
            f:SetPoint("CENTER", StrategosMinimap, "TOPLEFT", b.x * StrategosMinimap:GetWidth(), -b.y * StrategosMinimap:GetHeight())
            f.buildTooltip = function(self, t)
                local left = self.node.timer:remaning()
                if left then
                    local m,s = floor(left/60), mod(left, 60)
                    return format(self.node.name..": %d:%02d", m, s)
                end
            end
            f.buildMenu = function(self)
                if self.node.timer:remaning() then
                    UIDropDownMenu_AddButton({
                        text = "[BG] " .. self.node.name,
                        func = function()
                            local left = self.node.timer:remaning()
                            if left then
                                local m,s = floor(left/60), mod(left, 60)
                                SendChatMessage(format(self.node.name..": %d:%02d", m, s), "BATTLEGROUND")
                            end
                        end
                    })
                end
            end
        end
    end
    
    for n,b in AlteracBases do
        local f = getglobal("StrategosMinimapAlteracIndicator"..n)
        if not f then
            f = CreateFrame("Frame", "StrategosMinimapAlteracIndicator"..n, StrategosMinimap, "StrategosIndicatorFrameTemplate")
            f:SetPoint("CENTER", StrategosMinimap, "TOPLEFT", b.x * StrategosMinimap:GetWidth(), -b.y * StrategosMinimap:GetHeight())
            AlteracPOILookup[b.name] = f
            StrategosMinimapPOI:new(f)
            f.name = b.name
            f.buildTooltip = function(self, t)
                local left = self.node.timer:remaning()
                if left then
                    local m,s = floor(left/60), mod(left, 60)
                    return format(self.node.name..": %d:%02d", m, s)
                end
            end
            f.buildMenu = function(self)
                if self.node.timer:remaning() then
                    UIDropDownMenu_AddButton({
                        text = "[BG] " .. self.node.name,
                        func = function()
                            local left = self.node.timer:remaning()
                            if left then
                                local m,s = floor(left/60), mod(left, 60)
                                SendChatMessage(format(self.node.name..": %d:%02d", m, s), "BATTLEGROUND")
                            end
                        end
                    })
                end
            end
            f.pin:SetTexture("Interface\\Minimap\\POIIcons")
            f.colorful = true
            f:Hide()
        end
    end
    
    local f = getglobal("StrategosMinimapEFCIndicator")
    if not f then
        f = CreateFrame("Model", "StrategosMinimapEFCIndicator", StrategosMinimap)
        f:SetWidth(125)
        f:SetHeight(125)
        f:SetPosition(-0.0125,-0.0125,0)
        f:SetModel("Interface\\MiniMap\\Ping\\MinimapPing.mdx")
        f.closeTimer = Timer:new(2.5)
        f.farTimer = Timer:new(2.5)
        f:SetScript("OnUpdate",function()
            if f.closeTimer:remaning() then
                this:ClearAllPoints()
                this:SetPoint("CENTER", getglobal("StrategosMinimapDot"..this.closeIndex))
                this:SetScale(0.4)
                this:SetAlpha(1)
                this:Show()
            elseif f.farTimer:remaning() then
                this:ClearAllPoints()
                this:SetPoint("CENTER", getglobal("StrategosMinimapDot"..this.farIndex))
                this:SetScale(1)
                this:SetAlpha(0.33)
                this:Show()
            else
                this:Hide()
            end
        end)
        Object.connect(f.closeTimer, "started", f, f.Show)
        Object.connect(f.farTimer, "started", f, f.Show)
    end
end

function Battleground:scoreUpdate()
end

function Battleground:updateWorldStates()
end

function Battleground:leave()
end

function Battleground:_leave()
    self:leave()
    self:finished()
    self.startTimer:stop()
    function StrategosMinimapPlugin:getHighlight() end
    for _,f in StrategosMinimapPlugin.frames or {} do
        f:Hide()
    end
    StrategosMinimapPlugin.frames = {}
end

function Battleground:processChatEvent(message, faction)
    debug(format("Unhandled chat \"%s\" faction %d", message, faction))
end

if not StrategosMinimap_Plugins then
    getfenv(0).StrategosMinimap_Plugins = {}
end

function Battleground:processAddOnMessage()
end

tinsert(StrategosMinimap_Plugins, StrategosMinimapPlugin)
