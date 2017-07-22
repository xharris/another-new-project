HELPER = {
	run = function(name, args)
		if args == nil then
			args = {}
		end

		str_args = table.concat(args,' ')
		cmd = 'python src/helper.py '..name..' '..str_args
		os.execute(cmd)
	end
}

table.copy = function(t)
	return {unpack(t)}
end