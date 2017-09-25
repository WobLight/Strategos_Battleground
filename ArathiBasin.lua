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

ABNode = {}
setmetatable(ABNode, { __index = Node })

function ABNode:new(o)
    o = Node:new(o)
    o.timer.duration = 60
    setmetatable(o, { __index = self })
    StrategosCore.Object.attach(o,{"assaulted","defended","captured"})
    return o
end

function ABNode:assault(faction)
    self:setFaction(faction, true)
    self.timer:start()
    self:assaulted()
end

function ABNode:defend(faction)
    self:setFaction(faction)
    self.timer:stop()
    self:defended()
end

function ABNode:capture(faction)
    self:setFaction(faction)
    self.timer:stop()
    self:captured()
end

ArathiBasin = {}

setmetatable(ArathiBasin,{ __index = Battleground })

function ArathiBasin:new()
    local o = Battleground:new()
    o.zone = "Arathi Basin"
    setmetatable(o, self)
    self.__index = self
    o.nodes = {
        blacksmith = ABNode:new("Blacksmith"),
        farm = ABNode:new("Farm"),
        stables = ABNode:new("Stables"),
        mine = ABNode:new("Gold Mine")
    }
    o.nodes["lumber mill"] = ABNode:new("Lumber Mill")
    if StrategosMinimap then
        for _,b in {{StrategosMinimapArathiIndicatorST, o.nodes.stables}, 
                    {StrategosMinimapArathiIndicatorGM, o.nodes.mine},
                    {StrategosMinimapArathiIndicatorBS, o.nodes.blacksmith},
                    {StrategosMinimapArathiIndicatorLM, o.nodes["lumber mill"]},
                    {StrategosMinimapArathiIndicatorFM, o.nodes.farm}} do
            b[1]:setNode(b[2])
            tinsert(StrategosMinimapPlugin.frames, b[1])
            b[1]:Show()
        end
    end
    Object.attach(o,{"updateWinTime"})
    o.team = {{},{}}
    return o
end

function ArathiBasin:updateWorldStates()
    local now = GetTime()
    for i=1,2 do
        local _, msg = GetWorldStateUIInfo(i)
        if not msg then
            return
        end
        local _,_, n, s = strfind(msg, "(%d).-(%d+)/")
        n = tonumber(n)
        s = tonumber(s)
        if self.team[i].lastN ~= n or self.team[i].lastScore ~= s then
            if self.team[i].lastScore ~= s then
                self.team[i].lastScore = s
                self.team[i].lastTime = now
            end
            if n == 0 then
                self.team[i].winTime = nil
            else
                local tt = n == 5 and 1 or (5 - n) * 3
                local w = ceil((2000 - s) / 10 * tt)
                if n == 5 then
                    w = w / 3
                end
                self.team[i].winTime = self.team[i].lastTime + w
                self:updateWinTime(i, self.team[i].winTime)
            end
        end
    end
end

function ArathiBasin:timeToWin(team)
    local time = self.team[team].winTime
    return time and time - GetTime() or nil
end

function ArathiBasin:processChatEvent(message, faction)
    local evs = {}
    evs["Arathi Basin.- 1 minute"] = function()
        self.startTimer:set(60)
        self:starting()
    end
    evs["Arathi Basin.- 30 seconds"] = function() 
        self.startTimer:set(30)
        self:starting()
    end
    evs["Arathi Basin.- has begun"] = function()
        self.startTimer:stop()
        self:started()
    end
    evs["claims the"] = function()
        _,_,name = strfind(message, "claims the ([%w%s]+)")
        self.nodes[name]:assault(faction)
    end
    evs["assaulted the"] = function()
        _,_,name = strfind(message, "assaulted the ([%w%s]+)")
        self.nodes[name]:assault(faction)
    end
    evs["taken the"] = function()
        _,_,name = strfind(message, "taken the ([%w%s]+)")
        self.nodes[name]:capture(faction)
    end
    evs["defended the"] = function()
        _,_,name = strfind(message, "defended the ([%w%s]+)")
        self.nodes[name]:defend(faction)
    end
    
    for s,f in evs do
        if strfind(message, s) then
            f()
            return
        end
    end
    Battleground.processChatEvent(self, message, faction)
end

function ArathiBasin:leave()
    self.statesHandler:UnregisterEvent("UPDATE_WORLD_STATES")
end
