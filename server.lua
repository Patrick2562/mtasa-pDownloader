--[[
        _____                      _                 _           
       |  __ \                    | |               | |          
  _ __ | |  | | _____      ___ __ | | ___   __ _  __| | ___ _ __ 
 | '_ \| |  | |/ _ \ \ /\ / / '_ \| |/ _ \ / _` |/ _` |/ _ \ '__|
 | |_) | |__| | (_) \ V  V /| | | | | (_) | (_| | (_| |  __/ |   
 | .__/|_____/ \___/ \_/\_/ |_| |_|_|\___/ \__,_|\__,_|\___|_|   
 | |                                                             
 |_|                                                             


 -- https://github.com/Patrick2562/mtasa-pDownloader
 -- https://mtasa.com/discord
]]

local function request(client, resroot, resname, onlyReturn)
	local metaPath = ":"..resname.."/meta.xml"
	local meta     = XML.load(metaPath, true)
	assert(meta, "Failed to read meta-data, in " .. resname)

	local pDownloader = meta:findChild("pDownloader", 0)
	if not pDownloader then return false end
	pDownloader = tonumber(pDownloader:getValue()) or pDownloader:getValue()
	assert(pDownloader, "Invalid <pDownloader> value in "..metaPath..", expected <number or `true`>, got "..type(pDownloader).." ("..tostring(pDownloader)..")")

	local childs = meta:getChildren()
	local list   = { priority = pDownloader == "true" and 1 or pDownloader, back = 0, total = 0, resname = resname, files = {} }

	for i = 1, #childs do
		local child = childs[i]

		if child:getName() == "file" then
			local download = child:getAttribute("download")

			if download and download == "false" then
				local src   = child:getAttribute("src")
				local model = child:getAttribute("model")
				list.total  = list.total + 1
				list.files[src]  = { fullpath = ":"..resname.."/"..src, tries = 0, model = (model and #model > 0) and split(model, ",") or false }
			end
		end
	end

	if list.total > 0 then
		list.back = list.total
		
		if not onlyReturn then
			triggerClientEvent(client, "pDownloader:handler", resourceRoot, resroot, list)
		end
	end

	meta:unload()
	meta   = nil
	childs = nil
	collectgarbage()

	return list
end

addEvent("pDownloader:request", true)
addEventHandler("pDownloader:request", resourceRoot, function(resroot, resname)
	assert(client and resroot and resname, "Invalid arguments in event "..eventName)
	request(client, resroot, resname)
end)

addEvent("pDownloader:request:all", true)
addEventHandler("pDownloader:request:all", resourceRoot, function()
	assert(client, "Invalid arguments in event "..eventName)

	local all       = {}
	local resources = Resource.getAll()
	
	for i = 1, #resources do
		local res = resources[i]

		if res:getState() == "running" then
			local resroot = res:getRootElement()
			local list    = request(client, resroot, res:getName(), true)
			
			if list then
				table.insert(all, {resroot, list})
			end
		end
	end

	if #all > 0 then
		triggerClientEvent(client, "pDownloader:handler:all", resourceRoot, all)
	end
end)

addEvent("pOnDownloadFailed", true)
addEventHandler("pOnDownloadFailed", root, function(path)
	assert(source and path, "Invalid arguments in event "..eventName)
	source:kick("pDownloader", "Failed to download `"..path.."`")
end)