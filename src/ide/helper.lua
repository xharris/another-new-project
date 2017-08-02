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
		print(result)
		if result ~= '' then
			return loadstring(result)()
		end
	end
}

table.copy = function(t)
	return {unpack(t)}
end