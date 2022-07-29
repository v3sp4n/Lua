----------------------------------------------------------------------------------------------------------------
sampev = require'samp.events'

font = renderCreateFont('Sitka', 10,0x4)


function main()
    repeat wait(100) until isSampAvailable()
    while true do wait(0)
        text = sampGetChatInputText()
    
        if text:find('%d+') and text:find('[-+/*^%%]') and not text:find('%a+') and text ~= nil then
            ok, number = pcall(load('return '..text))
            result = 'result: '..number
        end

        if text:find('%d+%%%*%d+') then
            number1, number2 = text:match('(%d+)%%%*(%d+)')
            number = number1*number2/100
            ok, number = pcall(load('return '..number))
            result = 'result: '..number
        end

        if text:find('%d+%%%/%d+') then
            number1, number2 = text:match('(%d+)%%%/(%d+)')
            number = number2/number1*100
            ok, number = pcall(load('return '..number))
            result = 'result: '..number
        end

        if text:find('%d+/%d+%%') then
            number1, number2 = text:match('(%d+)/(%d+)%%')
            number = number1*100/number2
            ok, number = pcall(load('return '..number))
            result = 'result: '..number..'%'
        end


        
        if text == 'calc' then
            help = true
        else
            help = false
        end


        if text == '' then
            ok = false
        end
        if sampIsChatInputActive() and ok then
            local input = sampGetInputInfoPtr()
            local input = getStructElement(input, 0x8, 4)
            local windowPosX = getStructElement(input, 0x8, 4)
            local windowPosY = getStructElement(input, 0xC, 4)
            renderFontDrawText(font,number_separator(result),windowPosX,windowPosY+125,-1)
        end

    end
end

local punct_chars = '[ %%!"#&\'()*+,-./:;<=>?@%[\\%]^`{|}~]'
function process_match(punct, char, word)
    if punct == char then
        return char .. word
    end

    if punct == '' or #word < 2 then
        return punct .. char .. word
    end

    if word:upper() == 'SELF' then
        local replace
        local _, localPlayerId = sampGetPlayerIdByCharHandle(playerPed)
        if char == '#' then replace = tostring(localPlayerId)
        else replace = sampGetPlayerNickname(localPlayerId)
        end
        return punct .. replace
    end

    -- try to find player by id
    local playerId = tonumber(word)
    if playerId ~= nil then
        if sampIsPlayerConnected(playerId) then
            if char == '%' then return punct .. sampGetPlayerNickname(playerId)
            else return punct .. tostring(playerId)
            end
        end
    end

    -- find player by the part of nickname
    local replace = nil
    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) then
            local nick = sampGetPlayerNickname(i)
            if string.find(nick:upper(), word:upper(), 1, true) ~= nil then
                if replace ~= nil then
                    global_error = 'Too many matches.'
                    return nil
                end
                replace = char == '%' and nick or tostring(i)
            end
        end
    end

    if replace ~= nil then
        return punct .. replace
    else
        global_error = "No player '" .. word .. "'."
        return nil
    end
end

function on_send_chat(msg)
    global_error = nil
    msg = string.gsub(' ' .. msg, '([ %%!"#&\'()*+,-./:;<=>?@%[\\%]^`{|}~]?)([%%#])([%w_�-��-���]+)', process_match)
    if global_error then
        sampAddChatMessage('[{E3E300}Chat Bliss{EEEEEE}] {EE3333}' .. global_error, 0xEEEEEE)
        return nil
    end
    return msg:sub(2)
end

function number_separator(n) 
    local left, num, right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end


function sampev.onSendChat(msg)
    if msg:find('^%.%..+') then
        local cmd,t = msg:match('%.(%S+)(.*)')
        local send = "//" .. translite(string.sub(cmd, 2)) .. t
        sampProcessChatInput(send)
        return false
    elseif msg:find('^%..+') then
        local cmd,t = msg:match('%.(%S+)(.*)')
        local send = "/" .. translite(string.sub(cmd, 1)) .. t
        sampProcessChatInput(send)
        return false
    end
    
    msg = on_send_chat(msg)
    if msg == nil then
        return false
    end
    return {msg}
end

function sampev.onSendCommand(msg)
    msg = on_send_chat(msg)
    if msg == nil then
        return false
    end
    return {msg}
end

function sampev.onSendDialogResponse(id, button, index, text)
    if sampGetCurrentDialogType() == 1 or sampGetCurrentDialogType() == 3 then
        text = on_send_chat(text)
        if text == nil then
            return false
        end
        return {id, button, index, text}
    end
end

function translite(text)
local chars = {}
    chars["�"] = "q"
    chars["�"] = "w"
    chars["�"] = "e"
    chars["�"] = "r"
    chars["�"] = "t"
    chars["�"] = "y"
    chars["�"] = "u"
    chars["�"] = "i"
    chars["�"] = "o"
    chars["�"] = "p"
    chars["�"] = "["
    chars["�"] = "]"
    chars["�"] = "a"
    chars["�"] = "s"
    chars["�"] = "d"
    chars["�"] = "f"
    chars["�"] = "g"
    chars["�"] = "h"
    chars["�"] = "j"
    chars["�"] = "k"
    chars["�"] = "l"
    chars["�"] = ";"
    chars["�"] = "'"
    chars["�"] = "z"
    chars["�"] = "x"
    chars["�"] = "c"
    chars["�"] = "v"
    chars["�"] = "b"
    chars["�"] = "n"
    chars["�"] = "m"
    chars["�"] = ","
    chars["�"] = "."
    chars["�"] = "Q"
    chars["�"] = "Q"
    chars["�"] = "W"
    chars["�"] = "E"
    chars["�"] = "R"
    chars["�"] = "T"
    chars["�"] = "Y"
    chars["�"] = "U"
    chars["�"] = "I"
    chars["�"] = "O"
    chars["�"] = "{"
    chars["�"] = "}"
    chars["�"] = "A"
    chars["�"] = "S"
    chars["�"] = "D"
    chars["�"] = "F"
    chars["�"] = "G"
    chars["�"] = "H"
    chars["�"] = "J"
    chars["�"] = "K"
    chars["�"] = "L"
    chars["�"] = ":"
    chars["�"] = "\""
    chars["�"] = "Z"
    chars["�"] = "X"
    chars["�"] = "C"
    chars["�"] = "V"
    chars["�"] = "B"
    chars["�"] = "N"
    chars["�"] = "M"
    chars["�"] = "<"
    chars["�"] = ">"

    for k, v in pairs(chars) do
        text = string.gsub(text, k, v)
    end
    return text
end