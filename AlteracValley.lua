local S, SB
if StrategosCore == nil then 
    StrategosCore = {}
end
S = StrategosCore

if StrategosBattleground == nil then 
    StrategosBattleground = {}
end
SB = StrategosBattleground

setmetatable(S, {__index = getfenv() })
setfenv(1, S)

setmetatable(SB, {__index = getfenv() })
setfenv(1, SB)

AVNode = {}
setmetatable(AVNode, { __index = Node })

function AVNode:new(o)
    o = Node:new(o)
    o.timer.duration = 300
    setmetatable(o, { __index = self })
    StrategosCore.Object.attach(o,{"assaulted","defended","captured","destroyed"})
    return o
end

function AVNode:assault(faction)
    self:setFaction(faction, true)
    self.timer:start()
    self:assaulted()
end

function AVNode:defend(faction)
    self:setFaction(faction)
    self.timer:stop()
    self:defended()
end

function AVNode:capture(faction)
    self:setFaction(faction)
    self.timer:stop()
    self:captured()
end

function AVNode:destroy(faction)
    self:setFaction(0)
    self.timer:stop()
    self:destroyed()
end

AlteracValley = {}

setmetatable(AlteracValley, { __index = Battleground })

function AlteracValley:new()
    local o = Battleground:new()
    o.zone = "Alterac Valley"
    setmetatable(o, self)
    self.__index = self
    o.nodes = {}
    return o
end

function AlteracValley:processChatEvent(message, faction)
    local evs = {}
    evs["1 minute.-Alterac Valley"] = function()
        self.startTimer:set(60)
        self:starting()
    end
    evs["30 seconds.-Alterac Valley"] = function() 
        self.startTimer:set(30)
        self:starting()
    end
    evs["Alterac Valley.- has begun"] = function()
        self.startTimer:stop()
        self:started()
    end
    evs["The (.*) is under attack"] = function(_,_,a)
        self.nodes[a]:assault(faction)
    end
    evs["The (.*) was taken by"] = function(_,_,a)
        local node = self.nodes[a]
        if node.assaultingFaction == faction then
            node:capture(faction)
        else
            node:defend(faction)
        end
    end
    evs["^(.*) was destroyed by"] = function(_,_,a)
        self.nodes[a]:destroy()
    end
    for s,f in evs do
        local r = {strfind(message, s)}
        if getn(r) > 0 then
            f(unpack(r))
            return
        end
    end
    Battleground.processChatEvent(self, message, faction)
end

function AlteracValley:updateWorldStates()
    SetMapToCurrentZone()
    if not next(self.nodes) then
        for i = 1,GetNumMapLandmarks() do
            local name, descr, textureIndex, x, y = GetMapLandmarkInfo(i)
            local f = AlteracPOILookup[name]
            if f then
                local node = AVNode:new(name)
                self.nodes[name] = node
                node.id = i
                f:setNode(node)
                if descr == "Alliance Controlled" then
                    node:setFaction(1)
                elseif descr == "Horde Controlled" then
                    node:setFaction(2)
                elseif descr == "In Conflict" then
                    if textureIndex == 3 or textureIndex == 8 then
                        if strfind(name, "Tower") then
                            node:setFaction(2)
                        elseif name ~= "Snowfall Graveyard" then
                            node:setFaction(2)
                        end
                        node:setFaction(1,1)
                        f.ring:Show()
                    elseif textureIndex == 11 or textureIndex == 13 then
                        if strfind(name, "Bunker") then
                            node:setFaction(1)
                        elseif name ~= "Snowfall Graveyard" then
                            node:setFaction(1)
                        end
                        node:setFaction(2,1)
                        f.ring:Show()
                    end
                end
                tinsert(StrategosMinimapPlugin.frames, f)
                f.pin:SetTexCoord(WorldMap_GetPOITextureCoords(textureIndex))
                f:Show()
            end
        end
    end
    for i = 1,GetNumMapLandmarks() do
        local name, descr, textureIndex, x, y = GetMapLandmarkInfo(i)
        local f = AlteracPOILookup[name]
        if f then
            f.pin:SetTexCoord(WorldMap_GetPOITextureCoords(textureIndex))
        end
    end
end
