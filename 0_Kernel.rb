module Kernel
	# Display the arguments with color in the last slot
	# @param *args [Object, Integer] object to display, last integer is the color
	def pcc(*args)
		if args.last.is_a?(Integer)
			cc args.pop
		end
		pc args.join()
		cc 0x07
	end

	def mi
		return $game_system.map_interpreter
	end
end