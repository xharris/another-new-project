local image_list = {}
local image_info = {}
local zoom = 1
local zoom_range = {0.25, 20}

function getImgPathByName(name)
	for img, info in pairs(image_info) do
		if info.name == name then
			return img
		end
	end
end

local updateImageList_timer
local object_list = {}
function updateImageList()
	image_list = {}
	object_list = {}
	local image_files = SYSTEM.scandir(IDE.getProjectPath()..'/assets/image')

	for s, img in ipairs(image_files) do
		if not image_info[img] then
			image_info[img] = {
				name=IDE.validateName(img:gsub(extname(img),'')),
				open=false
			}
		end
		table.insert(image_list, img)
		table.insert(object_list, image_info[img].name)
	end
end

ideImage = {
	addImage = function(file)
		if IDE.isProjectOpen() then
			local filename = SYSTEM.cleanPath(file:getFilename())
			SYSTEM.copy(filename, IDE.getProjectPath()..'/assets/image/'..basename((filename)))
		end
	end,

	onOpenProject = function()
	end,

	getObjectList = function()
		if not updateImageList_timer then
			updateImageList()
			updateImageList_timer = Timer()
			updateImageList_timer:every(updateImageList, UI.getSetting('project_reload_timer').value):start() 
		end
		return object_list
	end,

	getAssets = function()
		updateImageList()
		local ret_str = ''
		for i, img in ipairs(image_list) do
			local img_info = image_info[img]

			ret_str = ret_str..""
			.."\nfunction assets:"..img_info.name.."()\n"
			.."\tlocal new_img = love.graphics.newImage(asset_path..\'assets/image/"..img.."\')\n"
			--.."\tnew_img:setFilter('"+params.min+"', '"+params.mag+"', "+params.anisotropy+")\n"
			--.."\t"+comment_wrap+"new_img:setWrap('"+params["[wrap]horizontal"]+"', '"+params["[wrap]vertical"]+"')\n"
			.."\treturn new_img\n"
			.."end\n";
		end
		return ret_str
	end,

	edit = function(name)
		image_info[getImgPathByName(name)].open = true
	end,

	draw = function()
		for img, info in pairs(image_info) do
			if info.open then
				imgui.SetNextWindowSize(300,300,"FirstUseEver")
				status, info.open = imgui.Begin(info.name..'###'..img, true)

				-- image name (editable)
				status, new_name = imgui.InputText("name",info.name,300)
				if status then
					info.name = IDE.validateName(new_name, IDE.modules['image'].getObjectList())
					IDE.reload()
				end

				-- image path
				local img_path = "assets/image/"..img
				imgui.InputText("path", img_path, img_path:len())

				-- image size
				local image, img_width, img_height = UI.loadImage(IDE.getShortProjectPath()..'/'..img_path)
				imgui.Text(string.format("size: %d x %d", img_width, img_height))

				-- zoom
	        	imgui.PushItemWidth(120)
				local zoom_status, new_zoom = imgui.InputFloat('zoom', zoom, 0.25, 1, 2)
				if zoom_status then
					zoom = new_zoom
				end
				if zoom < zoom_range[1] then zoom = zoom_range[1] end
				if zoom > zoom_range[2] then zoom = zoom_range[2] end

				imgui.Image(image, img_width*zoom, img_height*zoom, 0, 0, 1, 1, 255, 255, 255, 255, UI.getColor('love2d'))
				
				imgui.End()
			end
		end
	end,	
}

return ideImage