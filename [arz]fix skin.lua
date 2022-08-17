
sampev = require'samp.events'

textdraws = {
	disconnected = false,
	step = 1,
	clockPage = 0,
	clockTimeout = 0,

	put = 2302,
	inventory = 0,
	skin = {x=347.13317871094,y=220.02938842773,id=-1,text='ID%:%d+',modelId=0},
	click = {x=327.59722900391,y=202.93333435059,id=-1,text='LD_SPAC%:whit'},

	page = {
		[1] = 2107,
		[2] = 2108,
		[3] = 2109,
		["cur"] = 1,
	},
}

function main()
	while not isSampAvailable() do wait(0) end

	if not sampGetCurrentServerName():find('Arizona') then
		thisScript():unload()
	end

	while true do wait(0)

		freezeCharPosition(PLAYER_PED,textdraws.step ~= 0 and true or false)

		if sampGetGamestate() ~= 3 and not textdraws.disconnected then
			textdraws.disconnected = true
		end

		if textdraws.step ~= 0 or textdraws.disconnected then
			local sw,sh = getScreenResolution()
			renderDrawBox(0,0,sw,sh, 0xAAcc0000)
		end

		if sampIsLocalPlayerSpawned() and textdraws.step == 1 or textdraws.disconnected then
			wait(2000)
			textdraws.clockPage = os.clock()
			textdraws.clockTimeout = os.clock()
			sampSendChat('/invent')
			textdraws.step = 2
			textdraws.disconnected = false
		end

		if textdraws.clockTimeout ~= 0 and os.clock()-textdraws.clockTimeout > 3 then
			textdraws.step = 0
			textdraws.clockTimeout = 0
		end
		if textdraws.step == 2 and sampTextdrawGetString(textdraws.inventory) == 'INVENTORY' then
			if textdraws.skin.id == -1 and textdraws.click.id ~= -1 then
				if os.clock()-textdraws.clockTimeout > 1 then
					textdraws.click.id = -1

					textdraws.step = 0
					textdraws.clockTimeout = 0
					close_inventory()
				end
			end
		end

		if textdraws.step == 2 then
			if textdraws.skin.id ~= -1 and textdraws.click.id ~= -1 then
				textdraws.clockTimeout = os.clock()
				sampSendClickTextdraw(textdraws.click.id)
				textdraws.step = 3
			end
		end

	end
end



function sampev.onShowTextDraw(id, data)
	-- sampAddChatMessage(string.format('x=%s,y=%s',data.position.x,data.position.y),-1)
	-- [textdraw]id 2138,x 539.67504882813,y 391.37145996094,text LD_SPAC:white; CLICK
	-- [textdraw]id 2139,x 574.83972167969,y 424.34240722656,text ID:463;
	-- [textdraw]id 2105,x 764.34228515625,y 212.16439819336,text INVENTORY;

	if data.text == 'INVENTORY' then
		textdraws.inventory = id
	end

	if textdraws.skin.id == -1 and math.floor(data.position.x) == math.floor(textdraws.skin.x) and math.floor(data.position.y) == math.floor(textdraws.skin.y) then
		textdraws.skin.id = id
	end

	if textdraws.click.id == -1 and math.floor(data.position.x) == math.floor(textdraws.click.x) and math.floor(data.position.y) == math.floor(textdraws.click.y) then
		textdraws.click.id = id
	end

	--------

	if textdraws.skin.id ~= -1 and data.text:find(textdraws.skin.text) and textdraws.step == 3 then
		sampSendClickTextdraw((id-1))
		textdraws.step = 4
	end

	if textdraws.step == 4 then
		if data.text:find('PUT') then
			sampSendClickTextdraw(textdraws.put)
			close_inventory()
			textdraws.step = 0
		end
	end

	if textdraws.step == 3 then
		textdraws.page.cur = 1
		lua_thread.create(function()
			while (textdraws.step == 3) do wait(0)
				if os.clock() - textdraws.clockPage >= 0.50 then
					if textdraws.step == 3 and textdraws.page.cur < 3 then
						textdraws.page.cur = textdraws.page.cur + 1
						textdraws.clockPage = os.clock()
						sampSendClickTextdraw(textdraws.page[textdraws.page.cur])
					elseif textdraws.page.cur > 3 then
						close_inventory()
						break
					else
						close_inventory()
						break
					end
				end

			end
		end)
	end

end

function close_inventory(); sampSendClickTextdraw(0xFFFF); end