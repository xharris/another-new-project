HELPER = {
	py_location = 'src/helper.py',
	run = function(name, args)
		if args == nil then
			args = {}
		end

		local str_args = table.concat(args,' ')
		cmd = 'python '..HELPER.py_location..' '..name..' '..str_args
		--print(cmd)
		local handle = io.popen(cmd)
		local result = handle:read("*a"):trim()
		handle:close()
		
		if result ~= '' then
			return loadstring(result)()
		end
	end,

	copyScript = function(template_path, dest, replacements)
		-- make sure project folder exists
		SYSTEM.mkdir(dirname(dest))

		-- read template file and make replacements
		local s_template = ''
		for line in io.lines(template_path) do
			for r_old, r_new in pairs(replacements) do
				s_template = s_template .. line:gsub(r_old, r_new) .. '\n'
			end
		end

		-- write it
		print('write to '..dest)
		local f_output = io.open(dest, 'w')
		f_output:write(s_template)
		f_output:close()
	end
}