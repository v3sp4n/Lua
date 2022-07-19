script_name('TreasureMAP')
script_version('3.0')
script_author("Cosmo")
encoding = require 'encoding'; encoding.default = 'CP1251'; u8 = encoding.UTF8
requests = require 'requests'
sampev = require 'samp.events'
ini = require 'inicfg'
cfg = ini.load({
    main = {
    	radius = 500,
    	color_s = 1,
    	color_f = 2,
    	react = 10,
    	markers = true,
    	fullmap = true
    }
}, "TreasureMAP")

local coords = {}
local pool = {}
local finded = {}
local markers = {}
local otvets,copyOtvets = {},{}

local reaction = {-1, 3, 5, 10, 15}

local colors = {
	[1] = {0x00FF00FF, 	'Зелёный'},
	[2] = {0xFFFF00FF, 	'Жёлтый'},
	[3] = {0xFF0000FF, 	'Красный'},
	[4] = {0x6666FFFF, 	'Синий'},
	[5] = {0xFF5000FF, 	'Рыжий'},
	[6] = {0xFFFFFFFF, 	'Белый'},
	[7] = {0xFF00FFFF, 	'Розовый'},
	[8] = {0xAAAAAAFF, 	'Серый'},
	[9] = {0x00FFFFFF, 	'Голубой'},
	[10] = {0xFF6060FF, 'Малиновый'}
}
local colors2 = {
	[1] = 0x8000FF00,
	[2] = 0x80FFFF00,
	[3] = 0x80FF0000,
	[4] = 0x806666FF,
	[5] = 0x80FF5000,
	[6] = 0x80FFFFFF,
	[7] = 0x80FF00FF,
	[8] = 0x80AAAAAA,
	[9] = 0x8000FFFF,
    [10] = 0x80FF6060
}

------------
local state = false
local exact_count = 0
font = renderCreateFont('Tahoma', 12,0x4)

function main()
	while not isSampAvailable() do wait(100) end

	local result = false
	result, coords, exact_count = getCoordOnMap()
	if result == false then
		for i = 1,5 do
			sampAddChatMessage('TreasureMAP НЕТ .json ФАЙЛОВ С КООРДИНАТАМИ-ОТВЕТАМИ',0xff0000)
		end
		error('NOT FOUND .json FILES!')
	end
	sampRegisterChatCommand('trmap', show_menu)

	addEventHandler('onScriptTerminate', function(script, quit)
		if script == thisScript() then 
			ini.save(cfg, 'TreasureMAP.ini')
			remove_markers()
			remove_all() 
		end
	end)


	local ircBool,irc = irc_()
	while ircBool do
		wait(1234)
		irc.hideMsgOnChat('[TreasureMAP.lua]')
		break
	end

	while true do

		remove_markers()

		if state then
			local ircBool,irc = irc_()
			local sw,sh = getScreenResolution()			

			local A = { getCharCoordinates(PLAYER_PED) }
			
			for i, B in ipairs(coords) do
				local dist = getDistanceBetweenCoords3d(A[1], A[2], A[3], B[1], B[2], B[3])


				if not cfg.main.fullmap and B[4] == 0 then
    				if pool[i] ~= nil then
    					removeBlip(pool[i])
    					pool[i] = nil
    				end
					goto skip
				end

				if dist <= 20 and cfg.main.markers then 
					markers[i] = createUser3dMarker(B[1], B[2], B[3] + 1.5, 4)
				end

				if dist <= 35 and finded[i] ~= true then
					sampCreate3dTextEx(i, "METKA "..i, colors2[cfg.main.color_s], B[1], B[2], B[3]+0.3, 50, true, -1,-1)
				elseif dist <= 35 and finded[i] == true then
					sampCreate3dTextEx(i, "METKA "..i, colors2[cfg.main.color_f], B[1], B[2], B[3]+0.3, 50, true, -1,-1)
				elseif dist > 35 then
					sampDestroy3dText(i)
				end

				if dist <= cfg.main.radius and pool[i] == nil then
					pool[i] = addBlipForCoord(B[1], B[2], B[3])
					changeBlipColour(pool[i], finded[i] and colors[cfg.main.color_f][1] or colors[cfg.main.color_s][1])
				elseif dist <= cfg.main.react and finded[i] == nil then
					-- sampAddChatMessage('change ',-1)
					if ircBool then irc.sendToChat('[TreasureMAP.lua] change blip '..i,true) end
					finded[i] = true
					changeBlipColour(pool[i], colors[cfg.main.color_f][1])
				elseif dist > cfg.main.radius and pool[i] ~= nil then
					sampDestroy3dText(i)
					removeBlip(pool[i])
					pool[i] = nil
				end
				::skip::
			end


			if ircBool then
				irc.hideMsgOnChat('[TreasureMAP.lua]')
				if irc.GetMsg(1,'text'):find('%[TreasureMAP%.lua%] change blip (%d+)') then
					-- //iss [TreasureMAP] change blip 
					local i = irc.GetMsg(1,'text'):match('blip (%d+)')
					i = tonumber(i)
					if finded[i] ~= true then
						irc.addnotf(irc.GetMsg(1,'user') .. ' ~g~check '..i,2)
						changeBlipColour(pool[i], colors[cfg.main.color_f][1])	
						finded[i] = true
					elseif finded[i] == true then
						irc.addnotf(irc.GetMsg(1,'user') .. ' ~y~check '..i,2)
					end
					irc.changeMsg(1,'text','-')
				end
			else
				printStringNow('~r~IRC NOT LOADED!',1)
			end

			--2680 1271 KLAD
			for _, v in pairs(getAllObjects()) do
				local result, oX, oY, oZ = getObjectCoordinates(v)
				local models = getObjectModel(v)
				if models == 2680 --[[and models == 1271]] then
					-- local dist = getDistanceBetweenCoords3d(oX,oY,oZ, x2, y2, z2)
					local dist = math.sqrt( (A[1] - oX) ^ 2 + (A[2] - oY) ^ 2 + (A[3] - oZ) ^ 2 )
					local p1, p2 = convert3DCoordsToScreen(A[1], A[2], A[3])
		      		local p3, p4 = convert3DCoordsToScreen(oX, oY, oZ)

					if dist < 10 then
						local text = '~r~KLAD! Distance '..(dist)
						printStringNow(text,1)

						if isPointOnScreen(oX, oY, oZ, 3.0) then
							renderDrawLine(p1, p2, p3, p4, 3.0, 0xffff0000)
						end
					
					end

				end

			end

		end

		local result, button, list, _ = sampHasDialogRespond(101)
		if result and button == 1 then
			if list == 0 then
				state = not state
				if not state then remove_all() end
				show_menu()
			elseif list == 2 then
				cfg.main.fullmap = not cfg.main.fullmap
				show_menu()
			elseif list == 3 or list == 4 then
				cur_color = (list == 3 and 1 or 2)
				change_color()
			elseif list == 5 then
				for i = 1, #reaction do
					if cfg.main.react == reaction[i] then
						cfg.main.react = reaction[i + 1] or reaction[1]
						if cfg.main.react == -1 then finded = {}; remove_all(true) end
						show_menu()
						break
					end
				end 
			elseif list == 6 then
				cfg.main.markers = not cfg.main.markers
				show_menu()
			elseif list == 1 then
				local max = 1000
				for i = 100, max, 100 do
					if cfg.main.radius == i then
						cfg.main.radius = (i == max and 100 or i + 100)
						show_menu()
						break
					end
				end 
			elseif list == 7 then
				for i, B in ipairs(coords) do
					sampDestroy3dText(i)
					removeBlip(pool[i])
					pool[i] = nil
					finded[i] = nil
				end
			elseif list == 8 then
				sampShowDialog(103,'Ответ на вопрос из клада','тут напишите вопрос\nВАЖНО соблюдать заглавные буквы!','ok','cancel',1)
			else
				show_menu()
			end
		elseif result and button == 0 then
			ini.save(cfg, 'TreasureMAP.ini')
		end

		local result, button, _, input = sampHasDialogRespond(102)
		if result then
			input = tonumber(input)
			if input ~= nil and button == 1 then
				if input < 1 or input > #colors then
					change_color()
				else
					cfg.main[cur_color == 1 and 'color_s' or 'color_f'] = input
					remove_all(true)
					show_menu()
				end
			else
				show_menu()
			end
		end

		local result, button, _, input = sampHasDialogRespond(103)
		if result and button == 1 then
			if #input > 0 then
				local asd = {}
				copyOtvets = {}
				for k,v in ipairs(otvets) do
					local vopros,otvet = v:match('(.+)|||(.+)')
					if (vopros):find(input) then
						if vopros ~= nil and otvet ~= nil then
							table.insert(asd,vopros .. '\t'..otvet)
							table.insert(copyOtvets,''..(otvet))
						end
					end
	 			end
	 			if #asd > 0 then
					sampShowDialog(106,'Вопрос '..input..',возможные ответы:','Вопрос\tОтвет\n'..table.concat(asd,'\n'),'Скопировать!','Попробывать еще раз..',5)
				else
					sampShowDialog(105,input,'Не найдены ответы!',':=-((','попробывать еще раз..',0)
				end
			end
		end
		local result, button, _, _ = sampHasDialogRespond(105)
		if result and button == 0 then
			sampShowDialog(103,'Ответ на вопрос из клада','тут напишите вопрос\nВАЖНО соблюдать заглавные буквы!','ok','cancel',1)
		end
		local result, button, list, _ = sampHasDialogRespond(106)
		if result and button == 1 then
			setClipboardText(copyOtvets[list+1])
		end
		wait(0)
	end
end

function show_menu()
	sampShowDialog(101, '{FF6060}TreasureMAP {FFFFFF}| ' .. #coords .. plural(#coords, {' точка', ' точки', ' точек'}), 
string.format([[
Карта %s
Радиус: {FF6060}%s{FFFFFF} м.
Отображать: %s
Цвет обычных: %s
Цвет проверенных: %s
Радиус проверки: {FF6060}%s{FFFFFF}
3D маркеры: %s
Удалить все проверенные метки
Ответ на вопрос
 
Автор: {FF6060}Cosmo
]], 
	state and '{FF6060}работает' or '{777777}не работает', 
	cfg.main.radius,
	cfg.main.fullmap and ('{FF6060}Все (%d)'):format(#coords) or ('{FF6060}Только точные (%d)'):format(exact_count),
	('{%06X}%s'):format(rgba_to_rgb(colors[cfg.main.color_s][1]), colors[cfg.main.color_s][2]),
	('{%06X}%s'):format(rgba_to_rgb(colors[cfg.main.color_f][1]), colors[cfg.main.color_f][2]),
	cfg.main.react == -1 and 'Отключен' or cfg.main.react .. ' м.',
	cfg.main.markers and '{FF6060}Включены' or '{777777}Отключены'
	), 
'Выбрать', 'Закрыть', 2)
end

function change_color()
	local get_colors = function()
		local result = ''
		for i = 1, #colors do
			result = ('%s{FFFFFF}%s = {%06X}%s'):format(result .. (i % 2 == 0 and '\t\t' or '\n'), i, rgba_to_rgb(colors[i][1]), colors[i][2])
		end
		return result
	end
	sampShowDialog(102, '{FF6060}TreasureMAP {FFFFFF}| Выбор цвета', 
		string.format('%s\n\n{AAAAAA}Введите номер цвета:', get_colors()),
		'Выбрать', 'Назад', 1
	)
end

function remove_all(bool_update)
	for i = 1, #coords do
		if pool[i] ~= nil then
			if bool_update then
				changeBlipColour(pool[i], finded[i] and colors[cfg.main.color_f][1] or colors[cfg.main.color_s][1])
			else
				removeBlip(pool[i])
				pool[i] = nil
			end
		end
		sampDestroy3dText(i)
	end
end

function remove_markers()
	for i, marker in pairs(markers) do
    	removeUser3dMarker(marker)
    	markers[i] = nil
	end
end

function rgba_to_rgb(rgba)
	local r = bit.band(bit.rshift(rgba, 24), 0xFF)
	local g = bit.band(bit.rshift(rgba, 16), 0xFF)
	local b = bit.band(bit.rshift(rgba, 8), 0xFF)
	return bit.bor(bit.bor(b, bit.lshift(g, 8)), bit.lshift(r, 16))
end

function plural(n, forms)
	n = math.abs(n) % 100
	if n % 10 == 1 and n ~= 11 then
		return forms[1]
	elseif 2 <= n % 10 and n % 10 <= 4 and (n < 10 or n >= 20) then
		return forms[2]
	end
	return forms[3]
end

function getCoordOnMap() 

		-- local responseOtvets = requests.get(
		-- 	'https://arzmap.fun/developer.php',
		-- 	{
		-- 		params = {['answer'] = 'true'},
		-- 		headers = {
		-- 			['user-agent'] = 'Mozilla/5.0'
		-- 		},
		-- 		timeout = 30
		-- 	}
		-- )
		-- local j = decodeJson(responseOtvets.text)
		-- if type(j) == 'table' then
		-- 	for k,v in ipairs(j) do
		-- 		table.insert(otvets,u8:decode(v[1]) .. '|||'..u8:decode(v[2]))
		-- 	end
		-- end

		-- local response = requests.get(
		-- 	'https://arzmap.fun/developer.php',
		-- 	{
		-- 		params = {['coord'] = 'true'},
		-- 		headers = {
		-- 			['user-agent'] = 'Mozilla/5.0'
		-- 		},
		-- 		timeout = 30
		-- 	}
		-- )
		-- local code = response.status_code
		-- if code == 200 then
		-- 	local result = decodeJson(response.text)
		-- 	if type(result) == 'table' then
		-- 		local exact = 0
		-- 		for i, v in ipairs(result) do
		-- 			if v[4] == 1 then exact = exact + 1 end
		-- 		end
				
		-- 		return true, result, exact
		-- 	else
		-- 		return false
		-- 	end
		-- else
		-- 	return false
		-- end

	local path = getWorkingDirectory()..'/config/'
	if doesFileExist(path..'TreasureMAP answer.json') and doesFileExist(path..'TreasureMAP coords.json') then
		local answerFile = io.open(path..'TreasureMAP answer.json','r+')
		local answerJson = decodeJson(answerFile:read('*a'))
		for k,v in ipairs(answerJson) do
			table.insert(otvets,u8:decode(v[1]) .. '|||'..u8:decode(v[2]))
		end

		local coordsFile = io.open(path..'TreasureMAP coords.json','r+')
		local coordsJson = decodeJson(coordsFile:read('*a'))
		local exact = 0
		for i, v in ipairs(coordsJson) do
			if v[4] == 1 then exact = exact + 1 end
		end

		return true, coordsJson, exact
	else
		return false,nil,0
	end


end

function sampev.onShowDialog(id, style, caption, b1, b2, text) 
	if caption:find('Взлом.+%Клад') then
		
			local vop = text:match('(%S+) ?')
			if vop ~= nil then

				for k,v in ipairs(otvets) do
					local vopros,otvet = v:match('(.+)|||(.+)')
					if (vopros):find(vop) then
						sampAddChatMessage(vopros .. ' > '..otvet,-1)
					end
	 			end

	 		end
	end
end

function irc_()
	local ircc = nil
	local c = 0
	for i, s in pairs(script.list()) do
		if s.name == 'IRC CHAT' and c == 0 then
			s = import 'irc.lua'
			c = 1
			return true,s
		end
	end
	c = 0
	return false,nil
end