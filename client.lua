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

local sx, sy = guiGetScreenSize()

local queue = {
	init = function(self)
		self.list        = {}
		self.list_order  = {}
		self.count       = 0
		self.progress    = 0
		self.currentRes  = { root = false, name = false }
		self.isActive    = false
		self.lastFile    = false
		return true
	end,

	renderProgress = function(self)
		dxDrawRectangle(sx/2-162, sy-122, 324, 64, BOX_BG_COLOR_1)
		dxDrawRectangle(sx/2-160, sy-120, 320, 60, BOX_BG_COLOR_2)
	
		dxDrawRectangle(sx/2-155, sy-95,  310,               30, PROGRESS_BG_COLOR_1)
		dxDrawRectangle(sx/2-155, sy-95,  310*self.progress, 30, PROGRESS_BG_COLOR_2)
	
		dxDrawText(DOWNLOADING_TEXT..math.floor(self.progress*100).."%",                         sx/2-155, sy-120, sx/2+155, sy-95, TEXT_COLOR, 1,    "default-bold", "left",  "center")
		if SHOW_FILE_NAME and self.currentRes.name then dxDrawText(self.currentRes.name,         sx/2-155, sy-120, sx/2+155, sy-95, TEXT_COLOR, 0.95, "default-bold", "right", "center", true) end
		dxDrawText(SHOW_FILE_NAME and self.lastFile or (self.lastFile and "" or SEARCHING_TEXT), sx/2-150, sy-95,  sx/2+150, sy-65, TEXT_COLOR, 0.95, "default-bold", "left",  "center", true)
	end,

	toggleProgress = function(self, bool)
		self.isActive = bool
		if bool then
			self.renderHandler = function() self:renderProgress() end
			addEventHandler("onClientRender", root, self.renderHandler)
		else
			removeEventHandler("onClientRender", root, self.renderHandler)
			self.renderHandler = nil
		end
	end,

	calculateProgress = function(self)
		local list    = self.list[self.currentRes.root]
		self.progress = 1 - list.back / list.total
		return self.progress
	end,

	sortByPriority = function(self)
		return table.sort(self.list_order, function(a, b)
			return a.priority > b.priority
		end)
	end,

	downloadNext = function(self)
		if self.count <= 0 then return false end
		local resroot = table.remove(self.list_order, 1).resroot

		self.currentRes.root = resroot
		self.currentRes.name = self.list[resroot].resname

		for src, v in pairs(self.list[resroot].files) do
			downloadFile(v.fullpath)
		end
		return resroot
	end,

	add = function(self, resroot, data, blockStart)
		self.list[resroot] = data
		self.count         = self.count + 1

		table.insert(self.list_order, { resroot = resroot, priority = data.priority })
		self:sortByPriority()

		if not blockStart and not self.isActive then
			self:toggleProgress(true)
			Timer(function() self:downloadNext() end, 3000, 1)
		end
		return true
	end,

	getFilePath = function(self, resroot, src)
		return self.list[resroot] and self.list[resroot].files[src].fullpath or false
	end,

	onSuccess = function(self, resroot, src)
		local fullpath = self:getFilePath(resroot, src)
		local back     = self.list[resroot].back - 1

		self.lastFile           = src
		self.list[resroot].back = back
		self:calculateProgress()

		local model = self.list[resroot].files[src].model or nil
		if model and type(model) == "table" then
			for i = 1, #model do
				triggerEvent("pOnFileDownloaded", resroot, src, model[i])
			end
		else
			triggerEvent("pOnFileDownloaded", resroot, src)
		end

		if back <= 0 then
			triggerEvent("pOnDownloadComplete", resroot)
			self:loadModels(resroot)
			
			self.count = self.count - 1

			if self.count > 0 then
				Timer(function() self:downloadNext() end, 1500, 1)
			else
				self:toggleProgress(false)
				self:init()
			end
		end
	end,

	onFail = function(self, resroot, src)
		local fullpath = self:getFilePath(resroot, src)
		local new      = self.list[resroot].files[src].tries + 1

		self.list[resroot].files[src].tries = new

		if new >= MAX_FILE_DOWNLOAD_TRIES then
			return triggerServerEvent("pOnDownloadFailed", localPlayer, src)
		end
		return downloadFile(fullpath)
	end,

	loadModels = function(self, resroot)
		local load_order = {}

		for src, v in pairs(self.list[resroot].files) do
			if v.model and type(v.model) == "table" then
				local fullpath = self:getFilePath(resroot, src)
				local src      = src:match("^.+(%..+)$")

				for i = 1, #v.model do
					table.insert(load_order, { fullpath, src, v.model[i] })
				end
			end
		end
		table.sort(load_order, function(a, b) return a[2] > b[2] end)

		for i, v in pairs(load_order) do
			engineRestoreModel(v[3])

			if v[2] == ".txd" then
				engineImportTXD(engineLoadTXD(v[1]), v[3])
			elseif v[2] == ".dff" then
				engineReplaceModel(engineLoadDFF(v[1]), v[3])
			elseif v[2] == ".col" then
				engineReplaceCOL(engineLoadCOL(v[1]), v[3])
			end
		end
	end
}
queue:init()


addEvent("pDownloader:handler", true)
addEventHandler("pDownloader:handler", resourceRoot, function(...) queue:add(...) end)

addEvent("pDownloader:handler:all", true)
addEventHandler("pDownloader:handler:all", resourceRoot, function(all)
	for i = 1, #all do
		queue:add(all[i][1], all[i][2], i ~= #all)
	end
end)


addEventHandler("onClientFileDownloadComplete", root, function(src, success)
	if success then
		return queue:onSuccess(source, src)
	end
	return queue:onFail(source, src)
end)


addEventHandler("onClientResourceStart", root, function(res)
	if source == resourceRoot then
		triggerServerEvent("pDownloader:request:all", resourceRoot)
	else
		triggerServerEvent("pDownloader:request", resourceRoot, source, res:getName())
	end
end)