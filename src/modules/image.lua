local image_list = {}
local image_info = {}

function getImgPathByName(name)
	for img, info in pairs(image_info) do
		if info.name == name then
			return img
		end
	end
end

ideImage = {
	addImage = function(file)
		if IDE.getCurrentProject() then
			HELPER.run('copyResource',{'image',file:getFilename(),IDE.getCurrentProject()})
		end
	end,

	getObjectList = function() 
		image_list = {}
		local ret_list = {}
		local image_files = love.filesystem.getDirectoryItems(IDE.current_project..'/assets/image')
		for s, img in ipairs(image_files) do
			if not image_info[img] then
				image_info[img] = {
					name=IDE.validateName(img:gsub(extname(img),'')),
					open=false
				}
			end
			table.insert(image_list, img)
			table.insert(ret_list, image_info[img].name)
		end
		return ret_list
	end,

	getAssets = function()
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

				status, new_name = imgui.InputText("name",info.name,300)
				if status then
					info.name = IDE.validateName(new_name, IDE.modules['image'].getObjectList())
					IDE.reload()
				end

				local img_path = "assets/image/"..img
				imgui.InputText("path", img_path, img_path:len())

				UI.drawImage(IDE.current_project..'/'..img_path)

				imgui.End()
			end
		end
	end,	
}

return ideImage