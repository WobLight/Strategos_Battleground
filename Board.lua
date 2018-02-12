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

function StrategosBattlegroundUIController:initWSGFrame(node, frame)
    local name = frame:GetName()
    local button = getglobal(name .. "Button")
    local bar = getglobal(name .. "Bar")
    local icon = getglobal(name .. "Icon")
    local ring = getglobal(name .. "Ring")
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
    Object.connect(node, "picked", frame, frame.Show)
    Object.connect(node, "resetted", frame, frame.Hide)
    Object.connect(node, "carrierClassChanged", nil, onClassChanged)
    Object.connect(node, "carrierHealthChanged", nil,  function (p)
        if StrategosWSGSettings.carriersBars then
            if p then
                bar:SetValue(p*100)
                bar:SetStatusBarColor((1 - p)*2,p*2,0,1)
                bar:Show()
            else
                bar:Hide()
            end
            if frame.faction == 1 then
                button:SetTextColor(0,0,1)
            else
                button:SetTextColor(1,0,0)
            end
        else
            if p then
                button:SetTextColor((1 - p)*2,p*2,0)
            else
                button:SetTextColor(1,1,1)
            end
            bar:Hide()
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
            button:SetText(strarg("|c77665544_%1_|r",tr("WARSONG_FLAG_GROUND","client")))
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
    bar:SetMinMaxValues(0,100)
    ring:setTimer(node.timer)
end

function StrategosBattlegroundUIController:init(bg)
    if bg.zone == "Warsong Gulch" then
        StrategosBattlegroundUIController:initWSGFrame(bg.flagA, StrategosHordeCarrier)
        StrategosBattlegroundUIController:initWSGFrame(bg.flagH, StrategosAllianceCarrier)
        Object.connect(bg, "finished", StrategosAllianceCarrier, StrategosAllianceCarrier.Hide)
        Object.connect(bg, "finished", StrategosHordeCarrier, StrategosAllianceCarrier.Hide)
    elseif bg.zone == "Arathi Basin" then
        StrategosArathiScoreBar:SetMinMaxValues(0,10000)
        StrategosArathiScoreBar:Show()
        StrategosArathiScoreBar:SetScript("OnUpdate", function()
            local winner = GetBattlefieldWinner()
            local v, c, b, t = 0, {0.5, 0.5, 0.5}, {0.5, 0.5, 0.5}, nil
            local text
            if winner == 1 then
                text = "ARATHI_BOARD_WIN_FACTION1"
                c = {0,0,1}
                v = 1
            elseif winner == 0 then
                text = "ARATHI_BOARD_WIN_FACTION0"
                c = {1,0,0}
                v = 1
            else
                local t1, t2 = bg:timeToWin(1), bg:timeToWin(2)
                if not (t1 or t2) then
                    text = "ARATHI_BOARD_STALL"
                elseif not t1 then
                    text = "ARATHI_BOARD_WINNING_FACTION0"
                    t = t2
                    b = {1,0,0}
                elseif not t2 then
                    text = "ARATHI_BOARD_WINNING_FACTION1"
                    t = t1
                    b = {0,0,1}
                elseif t1 > t2 then
                    text = "ARATHI_BOARD_WINNING_FACTION0"
                    t = t2
                    v = 1-t2/t1
                    c = {1,0,0}
                    b = {0,0,1}
                else
                    text = "ARATHI_BOARD_WINNING_FACTION1"
                    t = t1
                    v = 1-t1/t2
                    c = {0,0,1}
                    b = {1,0,0}
                end
            end
            this:SetValue(v*10000)
            this:SetStatusBarColor(unpack(c))
            this:SetBackdropColor(unpack(b))
            local text = trl(text, t and { time = format("%d:%02d",floor(t/60),floor(t/60))})
            StrategosArathiScoreBarText:SetText(text("client"))
            StrategosArathiScoreBarText.announce = text("chat")
            this:SetWidth((AlwaysUpFrame1Text:GetWidth() + AlwaysUpFrame2Text:GetWidth())/2)
        end)
        Object.connect(bg, "finished", StrategosArathiScoreBar, StrategosArathiScoreBar.Hide)
    end
    StrategosBGStartRing:setTimer(bg.startTimer)
end

Object.attach(StrategosBattlegroundUIController)
Object.connect(StrategosBattleground, "newBattleground", StrategosBattlegroundUIController, StrategosBattlegroundUIController.init)
