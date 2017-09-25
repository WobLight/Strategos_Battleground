StrategosBattlegroundUIController = {}

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
Object.attach(StrategosBattleground, {"newBattleground"})

setmetatable(SB, {__index = getfenv() })
setfenv(1, SB)

function StrategosBattlegroundUIController:initWSGFrame(node, button, icon)
    local function getIcon(idx)
        local sx, sy = mod(idx,4), floor(idx/4)
        return sx/4, (sx +1)/4, sy/4, (sy +1)/4
    end
    local classIdx = {
        WARRIOR = 0,
        MAGE = 1,
        ROGUE = 2,
        DRUID = 3,
        HUNTER = 4,
        SHAMAN = 5,
        PRIEST = 6,
        WARLOCK = 7,
        PALADIN = 8
    }
    local function onClassChanged()
        if node.carrier and node.carrier.class then
            icon:SetTexCoord(getIcon(classIdx[node.carrier.class]))
            icon:Show()
        else
            icon:Hide()
        end
    end
    Object.connect(node, "picked", button, button.Show)
    Object.connect(node, "resetted", button, button.Hide)
    Object.connect(node, "carrierClassChanged", nil, onClassChanged)
    Object.connect(node, "carrierHealthChanged", nil,  function(p)
        if p then
            button:SetTextColor((1 - p)*2,p*2,0)
        else
            button:SetTextColor(1,1,1)
        end
    end)
    Object.connect(node, "carrierNameChanged", nil,  function(name)
        if  name then
            if name ~= "" then
                button:SetText(name)
            else
                button:SetText("?????")
            end
        else
            button:SetText("|c77665544_GROUND_|r")
        end
    end)
    function button:onClick()
        if node.carrier then
            if node.carrier.name then
                local old = ERR_UNIT_NOT_FOUND
                ERR_UNIT_NOT_FOUND = "Enemy carrier not in sight range."
                TargetByName(node.carrier.name, 1)
                ERR_UNIT_NOT_FOUND = old
            else
                -- allow to set?
            end
        end
    end
    getglobal(button:GetName().."Ring"):setTimer(node.timer)
end

function StrategosBattlegroundUIController:init(bg)
    if bg.zone == "Warsong Gulch" then
        StrategosBattlegroundUIController:initWSGFrame(bg.flagA, StrategosHordeCarrier, StrategosHordeCarrierIcon)
        StrategosBattlegroundUIController:initWSGFrame(bg.flagH, StrategosAllianceCarrier, StrategosAllianceCarrierIcon)
        Object.connect(bg, "finished", StrategosAllianceCarrier, StrategosAllianceCarrier.Hide)
        Object.connect(bg, "finished", StrategosHordeCarrier, StrategosAllianceCarrier.Hide)
    elseif bg.zone == "Arathi Basin" then
        StrategosArathiScoreBar:SetMinMaxValues(0,10000)
        StrategosArathiScoreBar:Show()
        StrategosArathiScoreBar:SetScript("OnUpdate", function()
            local winner = GetBattlefieldWinner()
            local v, c, b, t = 0, {0.5, 0.5, 0.5}, {0.5, 0.5, 0.5}, {}
            local text = "%s wins in: %d:%02d"
            if winner == 1 then
                text = VICTORY_TEXT1
                c = {0,0,1}
                v = 1
            elseif winner == 0 then
                text = VICTORY_TEXT0
                c = {1,0,0}
                v = 1
            else
                local t1, t2 = bg:timeToWin(1), bg:timeToWin(2)
                if not (t1 or t2) then
                    text = "Stalling"
                elseif not t1 then
                    t = {"Horde", floor(t2/60), mod(t2,60)}
                    b = {1,0,0}
                elseif not t2 then
                    t = {"Alliance", floor(t1/60), mod(t1,60)}
                    b = {0,0,1}
                elseif t1 > t2 then
                    t = {"Horde", floor(t2/60), mod(t2,60)}
                    v = 1-t2/t1
                    c = {1,0,0}
                    b = {0,0,1}
                else
                    t = {"Alliance", floor(t1/60), mod(t1,60)}
                    v = 1-t1/t2
                    c = {0,0,1}
                    b = {1,0,0}
                end
            end
            this:SetValue(v*10000)
            this:SetStatusBarColor(unpack(c))
            this:SetBackdropColor(unpack(b))
            StrategosArathiScoreBarText:SetText(format(text, unpack(t)))
            this:SetWidth((AlwaysUpFrame1Text:GetWidth() + AlwaysUpFrame2Text:GetWidth())/2)
        end)
        Object.connect(bg, "finished", StrategosArathiScoreBar, StrategosArathiScoreBar.Hide)
    end
    StrategosBGStartRing:setTimer(bg.startTimer)
end

Object.attach(StrategosBattlegroundUIController)
Object.connect(StrategosBattleground, "newBattleground", StrategosBattlegroundUIController, StrategosBattlegroundUIController.init)
