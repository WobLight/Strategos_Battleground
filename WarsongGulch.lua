local S, SB
if StrategosCore == nil then 
    StrategosCore = {}
end
S = StrategosCore
setmetatable(S, {__index = getfenv() })
setfenv(1, S)

if StrategosBattleground == nil then 
    StrategosBattleground = {}
end
SB = StrategosBattleground
Object.attach(StrategosBattleground, {"newBattleground"})
setmetatable(SB, {__index = getfenv() })
setfenv(1, SB)

WarsongGulch = {}

setmetatable(WarsongGulch, { __index = Battleground })

CreateFrame("GameTooltip","StrategosWSGFlagFinder",UIParent,"GameTooltipTemplate")

function StrategosWSGFlagFinder_CarrierUnit()
    for i=1,GetNumRaidMembers() do
        local unit = "raid"..i
        for i = 1,16 do
            StrategosWSGFlagFinder:SetOwner(UIParent, "ANCHOR_NONE");
            StrategosWSGFlagFinder:SetUnitBuff(unit,i)
            local sn = StrategosWSGFlagFinderTextLeft1:GetText()
            if sn == "Warsong Flag" then
                StrategosWSGFlagFinder:Hide()
                return unit
            end
        end
    end
    StrategosWSGFlagFinder:Hide()
end

function WarsongGulch.alliedFlagFrame()
    return UnitFactionGroup("player") == "Alliance" and AlwaysUpFrame1DynamicIconButton or AlwaysUpFrame2DynamicIconButton
end
function WarsongGulch.enemyFlagFrame()
    return UnitFactionGroup("player") == "Horde" and AlwaysUpFrame1DynamicIconButton or AlwaysUpFrame2DynamicIconButton
end

function WarsongGulch:lookForCarrier()
    if not (WarsongGulch.alliedFlagFrame() and WarsongGulch.alliedFlagFrame():IsVisible()) then
        return
    end
    local flag = self:alliedCarriedFlag()
    if flag.carrier and flag.carrier.name then
        return
    end
    local uc = StrategosWSGFlagFinder_CarrierUnit()
    if uc then
        flag:pick(UnitName(uc))
        return
    end
    self.finderTimer:start()
end
    
function WarsongGulch:new()
    local o = Battleground:new()
    o.zone = "Warsong Gulch"
    o.flagA = WSGNode:new({ name = "Alliance Flag", faction = 1})
    o.flagH = WSGNode:new({ name = "Horde Flag", faction = 2})
    o.broadcaster = Broadcaster:new("STRTGSWSG")
    o.finderTimer = Timer:new(1)
    o.finderTimer:setActive()
    function StrategosMinimapPlugin:getHighlight(unit)
        if not o.alliedCarriedFlag then return end
        local cu = o:alliedCarriedFlag():findCarrierUnit()
        if unit == cu then
            return nil, 9
        end
    end
    setmetatable(o, self)
    self.__index = self

    Object.connect(o.finderTimer,"triggered", o, o.lookForCarrier)
    Object.connect(o.broadcaster,"messageRecieved", o, o.processMessage)
    return o
end

function WarsongGulch:init()
    local aframe = WarsongGulch.alliedFlagFrame()
    if aframe then
        if aframe:IsVisible() then
            self:alliedCarriedFlag():picked()
            self:lookForCarrier()
        end
        aframe:SetScript("OnShow", function()
            local flag = self:alliedCarriedFlag()
            if not flag.carrier then
                self:alliedCarriedFlag():picked()
                self.finderTimer:start()
            end
        end)
    end
    local eframe = WarsongGulch.enemyFlagFrame()
    if eframe then
        if eframe:IsVisible() then
            self:enemyCarriedFlag():pick()
        end
        eframe:SetScript("OnShow", function()
            self:enemyCarriedFlag():pick()
        end)
    end
end

function WarsongGulch:update()
    for _,flag in {self.flagA, self.flagH} do
        if flag.carrier then
            local r = flag:findCarrierUnit()
            if r then
                local p = UnitHealth(r)/UnitHealthMax(r)
                flag:setCarrierHealth(p)
            else
                flag:setCarrierHealth()
            end
        end
    end
end

WSGNode = {}
setmetatable(WSGNode, { __index = Node })

function WSGNode:new(o)
    o = Node:new(o)
    setmetatable(o, { __index = self })
    StrategosCore.Object.attach(o,{"picked","resetted","captured","dropped","carrierNameChanged","carrierClassChanged","carrierHealthChanged"})
    return o
end

function WSGNode:pick(name)
    if not self.carrier then
        self.timer:stop()
        self.carrier = {}
        self:picked()
    end
    if name then
        self:setCarrierName(name)
    else
        self:setCarrierName("")
    end
end

function WSGNode:drop()
    self.timer:start(10)
    self:dropped()
    self.carrier = nil
    self:carrierNameChanged()
    self:carrierHealthChanged()
end

function WSGNode:capture()
    self.timer:stop()
    self:captured()
    self.carrier = nil
    self:carrierNameChanged()
    self:carrierHealthChanged()
end

function WSGNode:reset()
    self.timer:stop()
    self:resetted()
    self.carrier = nil
    self:carrierNameChanged()
    self:carrierHealthChanged()
end

function WSGNode:setCarrierName(name)
    if not self.carrier then
        self:pick()
    end
    if self.carrier.name ~= name then
        self.carrier.name = name
        self:carrierNameChanged(name)
    end
    if self:isAllied() then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid"..i) == name then
                _, self.carrier.class = UnitClass("raid"..i)
                self:carrierClassChanged()
                break
            end
        end
    else
        currentBattleground:scanEnemyFC()
    end
    if not self.carrier.class then
        RequestBattlefieldScoreData()
    end
end

function WSGNode:setCarrierHealth(p)
    if self.carrier.health == p then
        return
    end
    self.carrier.health = p
    self:carrierHealthChanged(p)
end

function WSGNode:isAllied()
    local f = {"Horde","Alliance"}
    return f[self.faction] == UnitFactionGroup("player")
end

function WSGNode:findCarrierUnit()
    if self.lastUnit and self.carrier and self.carrier.name == UnitName(self.lastUnit) then
        return self.lastUnit
    end
    if self:isAllied() then
        local afc = self.carrier
        if afc and afc.name then
            for i = 1,GetNumRaidMembers() do
                local r = "raid"..i
                if UnitName(r) == afc.name then
                    self.lastUnit = r
                    return r
                end
            end
        end
    else
        local efc = self.carrier
        if efc and efc.name then
            for i = 1,GetNumRaidMembers() do
                for _,r in {"raid"..i.."target", "raid"..i.."targettarget"} do
                    if UnitIsPlayer(r) and UnitName(r) == efc.name then
                        self.lastUnit = r
                        return r
                    end
                end
            end
        end
    end
end

function WarsongGulch:processChatEvent(message, faction)
    local evs = {}
    evs["Warsong Gulch.- 1 minute"] = function()
        self.startTimer:set(60,120)
        self:starting()
    end
    evs["Warsong Gulch.- 30 seconds"] = function() 
        self.startTimer:set(30,120)
        self:starting()
    end
    evs["^Let the.-Warsong Gulch.- beg[iu]n"] = function()
        self.startTimer:stop()
        self:started()
    end
    evs["picked"] = function()
        _,_,name = strfind(message, "by (%w+)")
        local flag = self[faction == 1 and "flagH" or "flagA"]
        flag:pick(name)
    end
    evs["dropped"] = function()
        local flag = self[faction ~= 1 and "flagH" or "flagA"]
        flag:drop(10)
    end
    evs["returned"] = function()
        local flag = self[faction ~= 1 and "flagH" or "flagA"]
        flag:reset()
    end
    evs["captured"] = function()
        self.startTimer:start(23)
        self.flagA:reset()
        self.flagH:reset()
    end
    evs["placed"] = function()
        if strfind(message, "Horde") then
            self.flagH:reset()
        elseif strfind(message, "Alliance") then
            self.flagA:reset()
        else
            self.flagA:reset()
            self.flagH:reset()
        end
    end
    
    for s,f in evs do
        if strfind(message, s) then
            f()
            return
        end
    end
    Battleground.processChatEvent(self, message, faction)
end

function WarsongGulch:scoreUpdate()
    local flag = self:enemyCarriedFlag()
    if flag.carrier and not flag.carrier.class then
        self:scanEnemyFC()
    end 
end

function WarsongGulch:alliedCarriedFlag()
    return UnitFactionGroup("player") == "Alliance" and self.flagH or self.flagA
end

function WarsongGulch:enemyCarriedFlag()
    return UnitFactionGroup("player") == "Alliance" and self.flagA or self.flagH
end

function WarsongGulch:scanEnemyFC()
    local node = self:enemyCarriedFlag()
    if not node.carrier or not node.carrier.name or node.carrier.name == "" then
        return
    end
    for i = 1, GetNumBattlefieldScores() do
        sn, _, _, _, _, _, _, _, sc = GetBattlefieldScore(i)
        if sn == node.carrier.name then
            node.carrier.class = strupper(sc)
            node:carrierClassChanged()
            break
        end
    end
    if not node.carrier.class then
        debug("Cannot find enemy flag carrier class.")
    end
end

function WarsongGulch:requestCarriersData()
    self.broadcaster:sendMessage("REQUEST_CARRIERS","BATTLEGROUND")
end

function WarsongGulch:processMessage(pkt)
    if pkt.msg == "REQUEST_CARRIERS" then
        local reply = ""
        for k,flag in {a=self.flagA, h=self.flagH} do
            if flag.carrier and flag.carrier.name then
                reply = reply .. "\t" ..k..flag.carrier.name
            end
        end
        if reply ~= "" then
            pkt:reply("DATA_CARRIERS"..reply)
        end
    end
end
                
function WarsongGulch:leave()
    self.broadcaster:unregister()
end

