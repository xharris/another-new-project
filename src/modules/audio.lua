local audio_list = {}
local audio_info = {}

local getAudByPathName = function(name)
	for aud, info in pairs(audio_info) do
		if info.name == name then
			return aud
		end
	end
end

-- https://gist.github.com/jesseadams/791673
function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
  return ''
end

local updateAudioList_timer
local object_list = {}
function updateAudioList()
	audio_list = {}
	object_list = {}
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
		table.insert(object_list, audio_info[aud].name)
	end
end

ideAudio = {
	addAudio = function(file)
		if IDE.isProjectOpen() then
			HELPER.run('copyResource',{'audio',file:getFilename(),IDE.getProjectPath()})
		end
	end,

	onOpenProject = function()
		updateAudioList()
		updateAudioList_timer = Timer()
		updateAudioList_timer:every(updateAudioList, UI.getSetting('project_reload_timer').value):start()
	end,

	getObjectList = function() 
		return object_list
	end,

	getAssets = function()
		updateAudioList()
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
				status, info.open = imgui.Begin(aud, true, {"AlwaysAutoResize"})

				if not info._asset then
					info._asset = assets[info.name]()
				end

				-- name
				status, new_name = imgui.InputText("name",info.name,300)
				if status then
					info.name = IDE.validateName(new_name, IDE.modules['image'].getObjectList())
					IDE.reload()
				end

				-- path (read-only)
				local aud_path = "assets/audio/"..aud
				imgui.InputText("path", aud_path, aud_path:len())

				-- duration
				imgui.Text("duration "..SecondsToClock(info._asset:getDuration("seconds")))

				-- play sound
				if not info._asset:isPlaying() and UI.drawIconButton("play", "play") then
					love.audio.play(info._asset)
				
				-- pause 
				elseif info._asset:isPlaying() and UI.drawIconButton("pause", "pause") then
					love.audio.pause(info._asset)
				end
				imgui.SameLine()

				-- stop
				if UI.drawIconButton("stop", "stop playing") then
					love.audio.stop(info._asset)
				end
				imgui.SameLine()

				local progress = 0
				local progress_text = info.name
				if info._asset then
					progress = info._asset:tell("seconds")/info._asset:getDuration("seconds")
					progress_text = SecondsToClock(info._asset:tell("seconds"))
				end
				imgui.ProgressBar(progress, 0, 0, progress_text)

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