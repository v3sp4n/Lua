script_name('[irc]share my pos')
script_author('Vespan')
script_version('1.0.0')
script_url('www.blast.hk/threads/139887/')


for k,v in ipairs({'luairc.lua','asyncoperations.lua','util.lua','handlers.lua', 'moonloader.lua','vkeys.lua'}) do
	if not doesFileExist(getWorkingDirectory()..'/lib/'..v) then
		error('not does file found '..v)
	end
end

require 'moonloader'
require 'luairc'
channel = '#bruh05'--with #
cmds = {
	'//sp',--share you pos
	'//sb',--share you blip
	'//spp',--share you Permanently pos
	'//gp'
	--[[
	example:write '//sp' - reg cmd '//sp' in samp
	]]
}

local s = irc.new{nick = "nil"}

players = {}
timers = {
	other = {
		clickWarp = -1,
	},

------------------

	_3dMarker = {

	},

	_blip = {

	},
}
_3dMarker = {
}
_blip = {
}

clickWarpPos = false
permanentlyPos = false

ping = 0

notf = {}
font = renderCreateFont('Sitka', 12,0x4)

disconnected = false

function main()
	while not isSampAvailable() do wait(0) end
	while not sampIsLocalPlayerSpawned() do wait(0) end
	wait(5)
	local id = select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))
	local nick = sampGetPlayerNickname(id)
	s.nick = string.format('%s[%s]',nick,id)
	wait(1000*1)

	s:connect("irc.ea.libera.chat")
	s:join(channel) 
	for i = 1,1000 do
		timers._3dMarker[i] = -1
	end	
	for i = 1,1000 do
		timers._blip[i] = -1
	end

	while true do 
		
		-- keys in moonloader/lib/vkeys.lua --
		if isKeyJustPressed(VK_R) and isKeyDown(VK_MBUTTON) and not sampIsCursorActive() then
			if getActiveInterior() == 0 then
				clickWarpPos = not clickWarpPos
				showCursor(clickWarpPos,false)
				remove3dMarker(1000)
			else
				addNotf('~r~you in interior!',3)
			end
		end
		if clickWarpPos then
			local sx, sy = getCursorPos()
			local sw, sh = getScreenResolution()
			if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
				local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0) 
				local camX, camY, camZ = getActiveCameraCoordinates() 
				local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
				if colpoint ~= nil then
					remove3dMarker(1000)
					create3dMarker(1000,colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]+0.3)
				end
				if isKeyJustPressed(VK_RBUTTON) or isKeyJustPressed(VK_LBUTTON) then
					addNotf('~b~you shared coordinates with ~y~ClickWarp~b~!',3)
					timers.other.clickWarp = os.clock()
					clickWarpPos = false
					showCursor(false,false)
					send(string.format('Coordinates with ClickWarp %s,%s,%s', colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]+0.3))
				end
			end
		end
---------------------------------------------------------------------------------------------------------------------------------------
		if timers.other.clickWarp ~= -1 then
			local t = os.clock() - timers.other.clickWarp
			if t > 30 then
				remove3dMarker(1000)
				timers.other.clickWarp = -1
			end
		end
---------------------------------------------------------------------------------------------------------------------------------------
		
		if #timers._3dMarker > 0 then
			for k,v in ipairs(timers._3dMarker) do
				if v ~= nil and v ~= -1 then
					local t = os.clock() - v
					-- addNotf(t,1)
					if t > 30 then
						removeUser3dMarker(_3dMarker[k])
						timers._3dMarker[k] = -1
					end
				end
			end
		end
		if #timers._blip > 0 then
			for k,v in ipairs(timers._blip) do
				if v ~= nil and v ~= -1 then
					local t = os.clock() - v
					-- addNotf(t,1)
					if t > 30 then
						removeBlip(_blip[k])
						timers._blip[k] = -1
					end
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

		wait(0)
	end
end
s:hook("OnRaw", function(line)
	if line:find(s.nick:gsub('%[','%%['):gsub('%]','%%]')) and line:find('QUIT %:Ping timeout%: %d+') then; thisScript():reload(); end

	-- :Vespan_Dark[128]!~lua@194.39.227.110 JOIN #sespan
	if line:find( s.nick:gsub('%[','%%['):gsub('%]','%%]') ) and line:find("JOIN") then
		regCmds()
		local ip,port = sampGetCurrentServerAddress()
		send('connected to '..ip..':'..port)
	end
	if line:find('%:.+!~lua@.+ QUIT') then
		local n = line:match('%:(.+)!~lua.+QUIT')
		local k,v = isStringInTable(players,n)
		if v == n then; table.remove(players,k) end
	end
end)

s:hook("OnChat", function(user, channel, text)
    if text:find('connected to .+%:%d+') then
    	local ip1,port1 = text:match('connected to (.+)%:(%d+)')
    	ip1 = ip1:gsub(' ','')
    	port1 = port1:gsub(' ', ''); port1 = tostring(port1)
    	local ip2,port2 = sampGetCurrentServerAddress()
    	port2 = tostring(port2)
    	if ip1 == ip2 then
    		local _,v = isStringInTable(players,user.nick)
    		if user.nick ~= v then
    			send('OK!')
    			table.insert(players,user.nick)
    		end
    	end
    end

    if text:find('OK!') then
    	local _,v = isStringInTable(players,user.nick)
    	if user.nick ~= v then
    		table.insert(players,user.nick)
    	end
    end

    local _,v = isStringInTable(players,user.nick)
    if user.nick == v and user.nick:find('%S+%[%d+%]') then
    	local id = user.nick:match('%[(%d+)%]')
    	id = id:gsub(' ','')
    	id = tonumber(id)

		if text:find('Coordinates with my pos (%S+),(%S+),(%S+)') then
			addNotf('~b~appeared coordinates with ~y~Pos~b~!',3)
			timers._3dMarker[id] = addTimer(timers._3dMarker[id])
			timers._blip[id] = addTimer(timers._blip[id])

			local x,y,z = text:match('Coordinates with my pos (%S+),(%S+),(%S+)')
			removeUser3dMarker(_3dMarker[id])
			create3dMarker(id,x,y,z)

			removeBlip(_blip[id])	
			_blip[id] = addBlipForCoord(x,y,z); 
			changeBlipColour(_blip[id], '0x'.. ("%06X"):format(bit.band(sampGetPlayerColor(id), 0xFFFFFF)) ..'FF'); 
		end
		if text:find('Coordinates with ClickWarp (%S+),(%S+),(%S+)') then
			addNotf('~b~appeared coordinates with ~y~ClickWarp~b~!',3)
			timers._3dMarker[id] = addTimer(timers._3dMarker[id])
			timers._blip[id] = addTimer(timers._blip[id])

			local x,y,z = text:match('Coordinates with ClickWarp (%S+),(%S+),(%S+)')
			removeUser3dMarker(_3dMarker[id])
			create3dMarker(id,x,y,z)

			removeBlip(_blip[id])	
			_blip[id] = addBlipForCoord(x,y,z); 
			changeBlipColour(_blip[id], '0x'.. 'ffffff' ..'FF'); 
		end
		if text:find('Coordinates with blip (%S+),(%S+)') then
			addNotf('~b~appeared coordinates with ~y~blip~b~!',3)
			timers._blip[id] = addTimer(timers._blip[id])

			local x,y = text:match('Coordinates with blip (%S+),(%S+)')

			removeBlip(_blip[id])	
			_blip[id] = addBlipForCoord(x,y,z); 
			changeBlipColour(_blip[id], '0x'.. 'e82a2a'..'FF'); 
		end
		if text:find('Coordinates with Permanently Pos (%S+),(%S+),(%S+)') then
			timers._blip[id] = os.clock()-25

			local x,y,z = text:match('Coordinates with Permanently Pos (%S+),(%S+),(%S+)')

			removeBlip(_blip[id])	
			_blip[id] = addBlipForCoord(x,y,z); 
			changeBlipColour(_blip[id], '0x'.. ("%06X"):format(bit.band(sampGetPlayerColor(id), 0xFFFFFF)) ..'FF'); 
		end 
		if text:find('%d+ get you pos') then
			local id = text:match('(%d+) get you pos')
			id = tonumber(id);
			local _,myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
			if id == myid then
				if getActiveInterior() == 0 then
					addNotf('~b~you shared coordinates with ~y~you pos~b~!',3)
					local x,y,z = getCharCoordinates(PLAYER_PED)
					send(string.format('Coordinates with my pos %s,%s,%s',x,y,z))
				else
					addNotf('~r~you in interior!',3)
				end
			end
		end


	end
end)

function send(arg); s:sendChat(channel, arg); end

function permanentlyPosf()
	while permanentlyPos do 
		wait(2000)
		local x,y,z = getCharCoordinates(PLAYER_PED)
		send(string.format('Coordinates with Permanently Pos %s,%s,%s',x,y,z))
	end
end
----------------------------------------------------------------------------------------
function isStringInTable(t,s)
	for k,v in ipairs(t) do
		if v == s then
			return k,v
		end
	end
	return nil,nil
end

-- function createBlip(i,x,y); _3dMarker[i] = addBlipForCoord(x,y); changeBlipColour(_3dMarker[i], 0xffffffff); end

function create3dMarker(i,x, y, z); _3dMarker[i] = createUser3dMarker(x, y, z + 1.5, 4); end
function remove3dMarker(i); removeUser3dMarker(_3dMarker[i]); end

function addTimer(t,k)
	if t == -1 or t == nil then
		return os.clock()
	elseif t ~= -1 and t ~= nil then
		local s = t + 5
		return s
	end
end

function addNotf(text,time)
	notf[#notf+1] = {text=text,time=time}

	for k,v in ipairs(notf) do
		local sw,sh = getScreenResolution()
		sw = sw / 2; sh = sh /1.15;
		sh = sh - (#notf*25)
		local timer = os.clock()
		local alpha = 255

		v.text = v.text:gsub('~r~','{c22727}'):gsub('~y~','{f5dc3d}'):gsub('~b~','{3d6bf5}'):gsub('~g~','{1dc42e}')

		lua_thread.create(function()
			while true do wait(0)
				if os.clock()-timer < v.time then
					renderFontDrawText(font,v.text,sw- renderGetFontDrawTextLength(font, v.text) / 2,sh,-1)
				else
					alpha = alpha - 5 
					if alpha > 1 and alpha < 255 then
						renderFontDrawText(font,v.text,sw- renderGetFontDrawTextLength(font, v.text) / 2,sh,'0x' .. string.format("%02x", math.floor(alpha)) .. 'ffffff')
					else
						table.remove(notf,k)
						break
					end
				end
			end
		end)
	end

end

function regCmds()

	addNotf(string.format('\n~y~register cmds ~b~%s %s %s %s',cmds[1],cmds[2],cmds[3],cmds[4]),5)

	sampRegisterChatCommand(cmds[4]:gsub('^/',''),function(id)
		if #id > 0 then
			send(id..' get you pos')
		else
			addNotf('~r~ error arg '..cmds[4]..' [id]',3)
		end
	end)

	sampRegisterChatCommand(cmds[1]:gsub('^/',''),function() 
		if getActiveInterior() == 0 then
			addNotf('~b~you shared coordinates with ~y~you pos~b~!',3)
			local x,y,z = getCharCoordinates(PLAYER_PED)
			send(string.format('Coordinates with my pos %s,%s,%s',x,y,z))
		else
			addNotf('~r~you in interior!',3)
		end
	end)
	sampRegisterChatCommand(cmds[2]:gsub('^/',''),function(); 
		local res,x,y,z = getTargetBlipCoordinates();
		if res then; 
			addNotf('~b~you shared coordinates with ~y~blip~b~!',3)
			send(string.format('Coordinates with blip %s,%s',x,y)); 
		else; 
			addNotf('~r~not found blip!',3); 
		end; 
	end)
	sampRegisterChatCommand(cmds[3]:gsub('^/',''),function()
		permanentlyPos = not permanentlyPos
		addNotf(permanentlyPos and '~b~Permanently Pos ~g~ON' or '~b~Permanently Pos ~r~OFF',3)
		lua_thread.create(permanentlyPosf)
	end)

end

function onReceivePacket(id, bs)
    lua_thread.create(function()
        if id == 32 or id == 33 or id == 36 or id == 37 and disconnected == false then
            disconnected = true 
        end
    end)
end

function onSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
    if id == 25 and disconnected then 
        disconnected = false 
        thisScript():reload()
    end
end  
