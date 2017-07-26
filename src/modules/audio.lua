local audio_list = {}
local audio_info = {}

local getAudByPathName = function(name)
	for aud, info in pairs(audio_info) do
		if info.name == name then
			return aud
		end
	end
end

ideAudio = {
	addAudio = function(file)
		if IDE.isProjectOpen() then
			HELPER.run('copyResource',{'audio',file:getFilename(),IDE.getProjectPath()})
		end
	end,

	getObjectList = function() 
		audio_list = {}
		local ret_list = {}
		local audio_files = SYSTEM.scandir(IDE.getProjectPath()..'/assets/audio')
		for s, aud in ipairs(audio_files) do
			if not audio_info[aud] then
				audio_info[aud] = {
					name=IDE.validateName(aud:gsub(extname(aud),'')),
					open=false,
					_asset=nil,
					type="stream"
				}
			end
			table.insert(audio_list, aud)
			table.insert(ret_list, audio_info[aud].name)
		end
		return ret_list
	end,

	getAssets = function()
		local ret_str = ''
		for i, aud in ipairs(audio_list) do
			local aud_info = audio_info[aud]

			ret_str = ret_str..""
			.."\nfunction assets:"..aud_info.name.."()\n"
			.."\tlocal new_aud = love.audio.newSource(asset_path..\'assets/audio/"..aud.."\',\'"..aud_info.type.."\')\n"
			--.."\tnew_img:setFilter('"+params.min+"', '"+params.mag+"', "+params.anisotropy+")\n"
			--.."\t"+comment_wrap+"new_img:setWrap('"+params["[wrap]horizontal"]+"', '"+params["[wrap]vertical"]+"')\n"
			.."\treturn new_aud\n"
			.."end\n";
		end
		return ret_str
	end,

	edit = function(name)
		audio_info[getAudByPathName(name)].open = true
	end,

	draw = function()
		for aud, info in pairs(audio_info) do
			if info.open then
				imgui.SetNextWindowSize(300,300,"FirstUseEver")
				status, info.open = imgui.Begin(aud, true)

				-- name
				status, new_name = imgui.InputText("name",info.name,300)
				if status then
					info.name = IDE.validateName(new_name, IDE.modules['image'].getObjectList())
					IDE.reload()
				end

				-- path (read-only)
				local aud_path = "assets/audio/"..aud
				imgui.InputText("path", aud_path, aud_path:len())

				-- play sound
				if imgui.Button("play") then
					info._asset = assets[info.name]()
					love.audio.play(info._asset)
				end
				if imgui.Button("stop") and info._asset then
					love.audio.stop(info._asset)
				end

				imgui.End()
			else
				if info._asset then
					love.audio.stop(info._asset)
				end
			end
		end
	end,	
}

return ideAudio