script_author('lovandog')
script_name('Карта Кладов')
script_version('1.3')

local sampev = require 'lib.samp.events'

local sName = '{6398c9}[TRMAP-RESTORE]{FFFFFF} – '
local zoneActive = false
local mapUsed = false
local kdcond = false
local endkd = 'Неизвестно.'

function main()
    while not isSampAvailable() do wait(0) end
    wait(100)
    sampRegisterChatCommand('zonedel', function()
        removeGangZone(610)
        sampAddChatMessage(sName .. 'Прошлая территория была удалена!', -1)
    end)
    sampRegisterChatCommand('zonecopy', function()
        if mapUsed then
            setClipboardText('/zonepaste l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down)
            sampAddChatMessage(sName .. 'Скопировано! Отправь это человеку, с которым хочешь поделиться координатами.', -1)
        else
            sampAddChatMessage(sName .. 'Активируй карту кладов, чтобы скопировать координаты.', -1)
        end
    end)
    sampRegisterChatCommand('zonepaste', function(coord)
        zonepaste = not zonepaste
        if zonepaste then
            if #coord ~= 0 then
                if coord:match('l: (.*); u: (.*); r: (.*); d: (.*)') then
                    pLeft, pUp, pRight, pDown = coord:match('l: (.*); u: (.*); r: (.*); d: (.*)')
                    removeGangZone(610)
                    addGangZone(610, pLeft, pUp, pRight, pDown, -2130706433) -- -1000070000
                    zoneActive = true
                    sampAddChatMessage(sName .. 'Территория была успешно добавлена на твою карту!', -1)
                else
                    sampAddChatMessage(sName .. 'Не тот формат! Вставь сюда координаты, которые тебе отправил друг с картой кладов.', -1)
                end
            else
                sampAddChatMessage(sName .. 'Ты ничего не ввёл! Вставь сюда координаты, которые тебе отправил друг с картой кладов.', -1)
            end
        else
            if zoneActive then
                removeGangZone(610)
                zoneActive = false
                sampAddChatMessage(sName .. 'Территория была удалена. Чтобы вернуть, введи координаты еще раз!', -1)
            else
                sampAddChatMessage(sName .. 'Не тот формат! Вставь сюда координаты, которые тебе отправил друг с картой кладов.', -1)
            end
        end
    end)
    sampRegisterChatCommand('iskd', function(arg)
        if kdcond == true then
            sampAddChatMessage('{FF0000}[TRMAP-RESTORE]{FFFFFF} – У тебя кулдаун. Ты не можешь использовать карту! Твой кулдаун кончится ' .. endkd, -1)
        elseif kdcond == false then
            sampAddChatMessage('{3cb043}[TRMAP-RESTORE]{FFFFFF} – Кулдауна нет. Можно использовать карту!', -1)
        end
    end)
    while true do
        wait(0)
        local timenow = os.date('%X')
        if timenow == endkd then
            printStyledString('~r~COOLDOWN END', 5000, 6)
            sampAddChatMessage('{3cb043}[TRMAP-RESTORE]{FFFFFF} – Кулдаун прошел! Карту можно использовать!', -1)
            kdcond = false
            endkd = 'Неизвестно.'
        end
    end
end


function sampev.onCreateGangZone(zoneId, squareStart, squareEnd, color)
    if color == -16776961 then
        mapUsed = true
        kladZone = zoneId
        left = squareStart.x
        up = squareStart.y
        right = squareEnd.x
        down = squareEnd.y
        print('l: ' .. left .. '; u: ' .. up .. '; r: ' .. right .. '; d: ' .. down)
        sampAddChatMessage(sName .. 'Территория найдена! После ее исчезновения она будет автоматически восстановлена.', -1)
        sampAddChatMessage(sName .. 'Чтобы скопировать ее координаты, пропиши /zonecopy', -1)
    end
end

function sampev.onGangZoneDestroy(zoneId1)
    if zoneId1 == kladZone then 
        removeGangZone(610)
        addGangZone(610, left, up, right, down, -2130706433)
        zoneActive = true
        sampAddChatMessage(sName .. 'Территория возвращена! Отсчёт кулдауна запущен!', -1)

        timekd = os.date('%X') -- 17:04:00
        hourkd, minutekd, secundkd = timekd:match('(%d+):(%d+):(%d+)')
        if minutekd + 30 < 60 then
            endkd = hourkd .. ':' .. tonumber(minutekd) + 30 .. ':' .. secundkd
        else
            endkd = hourkd + 1 .. ':' .. tonumber(minutekd) - 60 + 30 .. ':' .. secundkd
        end
        kdcond = true
    end
end

function addGangZone(id, left, up, right, down, color) -- Создание ганг-зоны.
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetBitStreamWriteFloat(bs, left)
    raknetBitStreamWriteFloat(bs, up)
    raknetBitStreamWriteFloat(bs, right)
    raknetBitStreamWriteFloat(bs, down)
    raknetBitStreamWriteInt32(bs, color)
    raknetEmulRpcReceiveBitStream(108, bs)
    raknetDeleteBitStream(bs)
end


function removeGangZone(id) -- Удаление ганг-зоны по ID
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetEmulRpcReceiveBitStream(120, bs)
    raknetDeleteBitStream(bs)
end