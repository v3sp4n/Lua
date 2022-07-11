
function main()
	while not isSampAvailable() do wait(0) end
	while not sampIsLocalPlayerSpawned() do wait(0) end
	for i = 1,10 do 
		sampAddChatMessage('TEST '..i,-1)
	end
	wait(-1)
end