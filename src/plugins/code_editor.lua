Class = require "template.plugins.blanke.Class"

local editors = {}

Editor = Class{
	init = function(self, filepath)
		self.filepath = filepath
		self.title = basename(filepath)

		-- read code from file
		local file = io.open(filepath, "r")
	    if file then self.content = file:read("*a") 
	    else self.content = '' end
	    file:close()

		self.editor_open = true
	end,

	draw = function(self)
		if self.editor_open then
			imgui.SetNextWindowSize(300,300,"FirstUseEver")
			status, self.editor_open = imgui.Begin(self.title, true)
		
			--ImGui::InputTextMultiline("##source", text, IM_ARRAYSIZE(text), ImVec2(-1.0f, ImGui::GetTextLineHeight() * 16), ImGuiInputTextFlags_AllowTabInput | (read_only ? ImGuiInputTextFlags_ReadOnly : 0));          
			imgui.PushItemWidth(-1)
			status, new_content = imgui.InputTextMultiline('##'..self.title, self.content, #self.content*2)--, {"AllowTabInput"})
			imgui.PopItemWidth()
			if status then
				-- text changed
				self.content = new_content
			end
			imgui.End()
		else
			editors[self.filepath] = nil
		end
	end,
}

code_editor = {
	project_plugin = true,
	disabled = true,

	editCode = function(filepath)
		if editors[filepath] == nil then
			editors[filepath] = Editor(filepath)
		else
			-- focus on already existing code editor
		end
	end,

	draw = function()
		for e, editor in pairs(editors) do
			editor:draw()
		end
	end,
}

return code_editor