class Game_Player
	# Generate the number of steps remaining to the next encounter
	def make_encounter_count
		if ($game_map.map_id != 0)
			n = $game_map.encounter_step
			@encounter_count = rand(n) + rand(n) + 1
		end
	end
	# Increases a step and displays related things
	def increase_steps
		super
		unless @move_route_forcing or $game_system.map_interpreter.running? or 
							$game_temp.message_window_showing or sliding?
			data = $pokemon_party.increase_steps											# Interaction considering mouvement
			$scene.display_step_info(data) if data.size > 0 and 
												$scene.class == Scene_Map
		end
	end
end	