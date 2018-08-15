class Interpreter_RMXP
	attr_accessor :wait_count

	DIR_SYM_TO_INT = {up: 8, down:2, left:4, right:6}

	# <DEBUG> display the first 100 colors of the console
	def console_colors
		100.times do |code|
			pcc "code : 0x#{code.to_s(16)}", code
		end
	end
	# Change the particle
	# @param name [Symbol] the particle name
	# @param id [Integer] the new set id
	# @author Leikt
	def select_particle_set(name, id)
		Yuki::Particles.select_set(name, id)
	end
	# Count the CrackedFloor tags in the given area. Result : [soil count, cracked soil count, hole count]
	# @param sx [Integer] the start x
	# @param sy [Integer] the start y
	# @param w [Integer] the rectangle width (number of tested columns)
	# @param h [Integer] the rectangle height (number of tested lines)
	# @return [Array<Integer>] the result
	# @author Leikt
	def count_cracked_floor(sx, sy, w, h)
		countSoil = 0
		countCracked = 0
		countHole = 0
		for x in sx...(sx+w)
			for y in sy...(sy+h)
				case $game_map.get_filtered_system_tags(x, y, GameData::SystemTags::CrackedFloorTags)[0]
				when GameData::SystemTags::WillCrackSoil
					countSoil += 1
				when GameData::SystemTags::CrackedSoil
					countCracked += 1
				when GameData::SystemTags::Hole
					countHole += 1
				end
			end
		end
		return [countSoil, countCracked, countHole]
	end
	
	# Force the palyer to slide
	# @param direction [Symbol] the direction of the slide (:down, :left, :right, :up)
	# @param spin [Boolean] true if the player will turn on himself (by default : false)
	# @param throwed [Boolean] true if the slide continue untile obstacle (by default : true)
	def set_player_sliding(direction, spin=false, throwed=true)
		gp.set_sliding_param(DIR_SYM_TO_INT[direction], spin, throwed)
	end

	# Call the private eval method
	# @param script [String] the script to evaluate
	# @return [Boolean]
	def eval_script(script)
		return eval(script)
	end
end