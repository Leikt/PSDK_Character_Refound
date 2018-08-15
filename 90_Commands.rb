class Game_Character
	# Test if the player is movable
	# @return [Boolean]
	# @author Leikt
	def movable?
		return !(jumping? or moving?)
	end

	# Check the given infos to x, y coords
	# @param *args [Integer], Integer] id of the event on the Map, or coords to look at
	# return [<Integer, Integer>] the coords
	def convert_coords(*args)
		if args[0].is_a?(Game_Character)
			return args[0].x, args[0].y
		else
			case args.size
			when 1
				e=$game_map.events[args[0]]
				return e.x, e.y if () if e
			when 2
				return args[0], args[1]
			end
		end
		return nil, nil
	end
	
	# End of the movement process
	# @param no_follower_move [Boolean] if the follower should not move
	# @author Nuri Yuri
	def movement_process_end(no_follower_move = false)
		update_position_shortcuts
		follower_move unless no_follower_move
		particle_push
		@z = ZTag.index(@system_tag) if ZTag.include?(@system_tag)
		@z = 1 if @z < 1
		@z = 0 if @z == 1 and (@system_tag == BridgeRL or @system_tag == BridgeUD)
		@old_slope = @current_slope
		@current_slope = $game_map.passabilities.get_slope(@x, @y, @z)
	end
	# Increase step prototype (sets @stop_count to 0)
	def increase_steps
		@stop_count = 0
	end
	
	#____________________________________________________
	# >>> CUSTOM MOUVEMENTS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Do custom move
	def move_type_custom
		unless movable?														# Check if mouvement is possible
			return
		end
		while (@move_route_index < @move_route.list.size)					# Iterate each command
			command = @move_route.list[@move_route_index]
			if (command.code == 0)											# Code=0, this is the end of the route
				if @move_route.repeat										# Restart route if it's repeated
					@move_route_index = 0
				else				
					if @move_route_forcing and !@move_route.repeat			# If the route isn't repeated and there is forcing => end the route and load the next one
						index = @move_routes.index {|mr| 					# Calculate index of the ended route (0 : original, 1 : normal, >= 2 : special)
							mr != nil and mr[0] == @move_route}
						if index >= 2										# Delete the ended move route from the list
							@move_routes.delete_at(index)
						elsif index == 1
							@move_routes[1] = nil
						end
						mr = @move_routes.select{|m| m != nil}.last			# Get the next move route
						if mr												# If there is a move route
							@move_route = mr[0]								# Store the RPG::MoveRoute
							@move_route_index = mr[1]						# Store the saved index
							if @move_routes[0] == mr						# If the move route is the original => no forcing.
								@move_route_forcing = false					# 	work also with no route (nil)
							else
								@move_route_forcing = true
							end
						else												# Reset the move route if there is no more routes
							@move_route = nil
							@move_route_index = 0
							@move_route_forcing = false
						end
					end
					@stop_count = 0											# Reset the stop counter (time between two original move command)
				end
				return														# End of the custom move
			end
			code = command.code												# Little optimisation
			if code <= 14 or (code >= 100 and code < 200)					# Action command
				action_type_custom(command)									# Interprete the custom action_custom
				if (!@move_route.skippable and movable?)
					return													# Try to move next frame
				end
				@move_route_index += 1										# Action done, next command
				return
			end
			if code == 15
				wait_type_custom(*command.parameters)
				@move_route_index += 1
				return
			end
			if (code > 14 and code <= 26) or (code >= 200 and code < 300)	# Turn command
				turn_type_custom(command) 									# Interprete the command
				@move_route_index += 1										# Always possible
				return														# Next command
			end
			if (code >= 27 and code < 100) or (code >= 300 and code < 400)													# Misc command (just >= 27 because all the other possiblities already are tested)
				misc_type_custom(command)									# Interprete the command
				@move_route_index += 1										# Always possible
																			# Next command												
			end
		end
	end
	
	# Interprete action type custom
	# @param command [RPG::MoveCommand] the command to execute
	def action_type_custom(command)
		case command.code
		when 1; move_down(command.parameters.fetch(0, true),command.parameters.fetch(0, false))
		when 2; move_left(command.parameters.fetch(0, true),command.parameters.fetch(0, false))
		when 3; move_right(command.parameters.fetch(0, true),command.parameters.fetch(0, false))
		when 4; move_up(command.parameters.fetch(0, true),command.parameters.fetch(0, false))
		when 5; move_lower_left(command.parameters.fetch(0, false))
		when 6; move_lower_right(command.parameters.fetch(0, false))
		when 7; move_upper_left(command.parameters.fetch(0, false))
		when 8; move_upper_right(command.parameters.fetch(0, false))
		when 9; move_random(command.parameters.fetch(0, false))
		when 10; move_toward_player(command.parameters.fetch(0, false))
		when 11; move_away_from_player(command.parameters.fetch(0, false))
		when 12; move_forward(command.parameters[0])
		when 13; move_backward(command.parameters.fetch(0, false))
		when 14; jump(command.parameters[0], command.parameters[1], command.parameters.fetch(2, true), command.parameters.fetch(3, 10), command.parameters.fetch(4, false))
		when MRB::MOVE_TOWARD_TAG; 				move_toward_tags(command.parameters[0], command.parameters.fetch(1, false))
		when MRB::MOVE_AWAY_TAG; 				move_away_from_tags(command.parameters[0], command.parameters.fetch(1, false))
		when MRB::MOVE_FORWARD_DIRECTION_FIXED; move_forward_direction_fixed(command.parameters.fetch(0, false))
		when MRB::FORCE_MOVE_ROUTE; 			force_move_route(command.parameters[0], command.parameters.fetch(1, :normal)); @move_route_index -= 1
		when MRB::WAIT_MOVE_COMPLETION; 		nil
		end
	end

	# Set the number of frame to wait from the given command
	# @param [parameters] the RPG::MoveCommand parameters
	def wait_type_custom(*parameters)
		case parameters.size
		when 1
			@wait_count = (parameters[0] * 2 - 1)			# Classic wait calculation
		when 2
			@wait_count = (parameters[0] + 					# Random range wait calculation
				rand(parameters[1]) * 2 - 1)				# Between A and A+B
		when 3
			@wait_count = (parameters[0] +					# Random range with step calculation
				rand(parameters[1] * 2 - 1) *				# Between A and A+B*C
				parameters[2])								# Wait duration increase by C step from A
		else 
			wait_cnt = parameters[0]						# Random table wait count generation
			dice = parameters[1]							# structure of the array : [min, dice, threshold1, added_value_1, threshold2, add_value_2, ...]
			rnd = rand(dice)								# exemple : [30, 100, 10, 0, 30, 15, 60, 30, 90, 60, 100, 90] (base of 30, 10% chance to add 0, else 30% chance to add 15, ...)
			for i in (2...(parameters.size)).step(2)
				if rnd <= parameters[i]
					wait_cnt += parameters[i+1]
					break
				end
			end
			@wait_count = wait_cnt
		end
	end
	
	# Interprete turn type custom
	# @param command [RPG::MoveCommand] the command to execute
	def turn_type_custom(command)
		case command.code
		when 16; turn_down
		when 17; turn_left
		when 18; turn_right
		when 19; turn_up
		when 20; turn_right_90
		when 21; turn_left_90
		when 22; turn_180
		when 23; turn_right_or_left_90
		when 24; turn_random
		when 25; turn_toward_player
		when 26; turn_away_from_player
		when MRB::TURN_TOWARD_TAG; turn_toward_tags(command.parameters[0])
		when MRB::TURN_AWAY_TAG; turn_away_from_tags(command.parameters[0])
		when MRB::TURN_TOWARD_DIR;
			case command.parameters[0]
			when 2; turn_down
			when 4; turn_left
			when 6; turn_right
			when 8; turn_up
			end
		end
	end
	
	# Interprete misc type custom
	# @param command [RPG::MoveCommand] the command to execute
	def misc_type_custom(command)
		case command.code
		when 27
			$game_switches[command.parameters[0]] = true
			$game_map.need_refresh = true
		when 28
			$game_switches[command.parameters[0]] = false
			$game_map.need_refresh = true
		when 29; @move_speed = command.parameters[0]
		when 30; @move_frequency = command.parameters[0]
		when 31; @walk_anime = true
		when 32; @walk_anime = false
		when 33; @step_anim = true
		when 34; @step_anim = false
		when 35; @direction_fix = true
		when 36; @direction_fix = false
		when 37; set_through
		when 38; reset_through
		when 39; @always_on_top = true
		when 40; @always_on_top = false
		when 41; change_graphics(*command.parameters)
		when 42; @opacity = command.parameters[0]
		when 43; @blend_type = command.parameters[0]
		when 44; $game_system.se_play(command.parameters[0])
		when 45
			last_eval = Yuki::EXC.get_eval_script
			eval_script = command.parameters[0].force_encoding('UTF-8')
			Yuki::EXC.set_eval_script(eval_script)
			result = eval(eval_script)
			Yuki::EXC.set_eval_script(last_eval)
		when MRB::FADE_OPACITY; 		fade_opacity(command.parameters[0], command.parameters[1])
		when MRB::FADE_SCREEN_X_OFFSET; fade_screen_x_offset(command.parameters[0], command.parameters[1], command.parameters[2])
		when MRB::FADE_SCREEN_Y_OFFSET; fade_screen_y_offset(command.parameters[0], command.parameters[1], command.parameters[2],command.parameters[3])
		when MRB::CHANGE_SPEED; 				change_speed(command.parameters[0], command.parameters[1])
		when MRB::CHANGE_SPEED_FOR_ONE_MOVE; 	change_speed_for_this_move(command.parameters[0], command.parameters[1])
		when MRB::CHECK_SLIDING_TAGS; 		check_sliding_tags
		when MRB::CHECK_CRACKED_FLOOR;		move_cracked_floor(command.parameters.fetch(0, false), command.parameters.fetch(1, true))
		when MRB::CHECK_SLIDE_END_HERE; 	end_slide_route unless @system_tag==command.parameters[0]
		when MRB::CHECK_SLIDE_END_THERE; 	end_slide_route unless @front_system_tag==command.parameters[0]
		when MRB::CHECK_STATE_COHERENCE; 	check_state_coherence
		when MRB::DISABLE_ROUTE_REPEAT; 	@move_route.repeat = false if @move_route
		when MRB::PARTICLE_PUSH; 
			if (t = command.parameters[0])
				force_particle_push(t, command.parameters[1])
			else
				particle_push
			end
		when MRB::RESET_CHARA_PATTERN; 		@pattern = @original_pattern = 0;
		when MRB::SET_SKIP_STATE_UPDATE; 	@skip_state_update = command.parameters[0]
		when MRB::SET_INSTANCE_VARIABLE; 	self.instance_variable_set(command.parameters[0], command.parameters[1])
		when MRB::RESET_STATE; 		reset_state
		when MRB::SET_STATE; 		set_state(command.parameters[0])
		when MRB::SET_SUB_STATE; 	set_sub_state(command.parameters[0])
		when MRB::SET_STATES; 		set_states(new_state: command.parameters[0], new_sub_state: command.parameters[1])
		when MRB::RESET_STATE; 		reset_state
		when MRB::RESET_SUB_STATE; 	reset_sub_state
		when MRB::MOVEMENT_PROCESS_END; 	movement_process_end(command.parameters.fetch(0, false))
		when MRB::DELETE_THIS_EVENT; 		$game_map.delete_event(self)
		when MRB::CALL_COMMON_EVENT; 		$game_temp.common_event_id = command.parameters[0]
		when MRB::POKE; 		poke(command.parameters[0], command.parameters[1], command.parameters.fetch(2, command.parameters[1]))
		when MRB::SET_POKING; 	@poking=command.parameters[0]
		when MRB::CHANGE_BLANK_DEPTH; 	@blank_depth = command.parameters[0];
		when MRB::TRANSFER_PLAYER; 		transfer_player(*command.parameters)
		when MRB::CHANGE_SCREEN_TONE; 	change_screen_tone(command.parameters[0], command.parameters[1])
		when MRB::SET_VARIABLE; 
				$game_variables[command.parameters[0]] = command.parameters[1]
				$game_map.need_refresh = true
		end
	end
	
	#____________________________________________________
	# >>> MOUVEMENT RANK 2 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Make the character turn 90° to the left or the right
	def turn_right_or_left_90
		rand(2)==0 ? turn_right_90 : turn_left_90
	end
	# Make the character look away from the given tags
	# @param tags [Symbol, Array<Symbol>] the tags
	# @author Leikt
	def turn_away_from_tags(tags)
	end
	# Make the character look to the given tags
	# @param tags [Symbol, Array<Symbol>] the tags
	# @author Leikt
	def turn_toward_tags(tags)
	end
	# Make the character look away from the player
	def turn_away_from_player
		turn_away_from_position($game_player)
	end
	# Make the character look to the player
	def turn_toward_player
		turn_toward_position($game_player)
	end
	# Make the character move to the tags
	# @param tags [Symbol, Array<Symbol>] the tags
	# @param skip_passable [Boolean, false] true if skip the passability test
	# @author Leikt
	def move_toward_tags(tags, skip_passable=false)
	end
	# Make the character move away from the tags
	# @param tags [Symbol, Array<Symbol>] the tags
	# @param skip_passable [Boolean, false] true if skip the passability test
	# @author Leikt
	def move_away_from_tags(tags, skip_passable=false)
	end
	# Make the character move to the player
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_toward_player(skip_passable=false)
		move_toward_position($game_player)
	end
	# Make the character move away from the player
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_away_from_player(skip_passable=false)
		move_away_from_position($game_player)
	end
	
	#____________________________________________________
	# >>> MOUVEMENT RANK 1 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Make the character turn to random direction
	# @param skip_passable [Boolean, false] true if skip the passability test
	def turn_random
		case (rand(4)+1)
		when 1; turn_down
		when 2; turn_left
		when 3; turn_right
		when 4; turn_up
		end
	end
	# Make the character turn 90° right
	# @param skip_passable [Boolean, false] true if skip the passability test
	def turn_right_90
		case @direction
		when 2; turn_left
		when 4; turn_up
		when 6; turn_down
		when 8; turn_right
		end
	end
	# Make the character turn 90° left
	def turn_left_90
		case @direction
		when 2; turn_right
		when 4; turn_down
		when 6; turn_up
		when 8; turn_left
		end
	end
	# Look directly to a specific position
	# @param *args [Integer, Game_Character, Integer] id of the event on the Map, or coords to look at or the game_character to look at
	def look_to(*args)
		x, y = convert_coords(*args)
		return unless x
		dx = x - @x
		dy = y - @y
		if dx.abs <= dy.abs
			dy < 0 ? turn_up : turn_down
		else
			dx < 0 ? turn_left : turn_right
		end
	end
	alias turn_toward_position look_to
	# Look away from a specific position
	# @param args [Integer, Game_Character, Integer] id of the event on the Map, or coords to look at or the game_character to look at
	# @param skip_passable [Boolean, false] true if skip the passability test
	def turn_away_from_position(position, skip_passable = false)
		x, y = convert_coords(*args)
		return unless x
		dx = x - @x
		dy = y - @y
		if dx.abs <= dy.abs
			dy < 0 ? turn_down(skip_passable) : turn_up(skip_passable)
		else
			dx < 0 ? turn_right(skip_passable) : turn_left(skip_passable)
		end
	end
	# Make the character move to random direction
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_random(skip_passable=false)
		case (rand(4)+1)
		when 1; move_down(false, skip_passable)
		when 2; move_left(false, skip_passable)
		when 3; move_right(false, skip_passable)
		when 4; move_up(false, skip_passable)
		end
	end
	# Make the character move forward
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_forward(skip_passable=false)
		case @direction
		when 2; move_down(false, skip_passable)
		when 4; move_left(false, skip_passable)
		when 6; move_right(false, skip_passable)
		when 8; move_up(false, skip_passable)
		end
	end
	# Make the character move forward based of @direction_fixed variable
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_forward_direction_fixed(skip_passable=false)
		dir = (@direction_fixed ? @direction_fixed : @direction)
		case dir
		when 2; move_down(false, skip_passable)
		when 4; move_left(false, skip_passable)
		when 6; move_right(false, skip_passable)
		when 8; move_up(false, skip_passable)
		end
	end
	# Make the character move backward
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_backward(skip_passable = false)
		last_direction_fix = @direction_fix
		@direction_fix = true
		case @direction
		when 2; move_up(false, skip_passable)
		when 4; move_right(false, skip_passable)
		when 6; move_left(false, skip_passable)
		when 8; move_down(false, skip_passable)
		end
		@direction_fix=last_direction_fix
	end
	# Make the character move toward position
	def move_toward_position(*args)
		x, y = convert_coords(*args)
		return unless x
		dx = @x - x
		dy = @y - y
		abs_dx = dx.abs
		abs_dy = dy.abs
		if abs_dx==abs_dy
			rand(2) == 0 ? abs_dx+=1 : abs_dy+=1
		end
		if abs_dx > abs_dy
			dx > 0 ? move_left : move_right
			if !moving? and dy != 0
				dy > 0 ? move_up : move_down
			end
		else
			dy > 0 ? move_up : move_down
			if !moving? and dx != 0
				dx > 0 ? move_left : move_right
			end
		end
	end
	# Make the character move away position
	def move_away_from_position(*args)
		x, y = convert_coords(*args)
		return unless x
		dx = @x - x
		dy = @y - y
		abs_dx = dx.abs
		abs_dy = dy.abs
		if abs_dx==abs_dy
			rand(2) == 0 ? abs_dx+=1 : abs_dy+=1
		end
		if abs_dx > abs_dy
			dx > 0 ? move_right : move_left
			if !moving? and dy != 0
				dy > 0 ? move_down : move_up
			end
		else
			dy > 0 ? move_down : move_up
			if !moving? and dx != 0
				dx > 0 ? move_right : move_left
			end
		end
	end
	
	
	
	#____________________________________________________
	# >>> MOUVEMENT RANK 0 >>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Make the character facing down
	def turn_down
		return if @direction_fix
		@direction = 2
		@stop_count = 0
		update_position_shortcuts
	end
	# Make the character facing left
	def turn_left
		return if @direction_fix
		@direction = 4
		@stop_count = 0
		update_position_shortcuts
	end
	# Make the character facing right
	def turn_right
		return if @direction_fix
		@direction = 6
		@stop_count = 0
		update_position_shortcuts
	end
	# Make the character facing up
	def turn_up
		return if @direction_fix
		@direction = 8
		@stop_count = 0
		update_position_shortcuts
	end
	# Make the character facing the opposite direction
	def turn_180
		return if @direction_fix
		@direction = 10-@direction
		@stop_count = 0
		update_position_shortcuts
	end
	# Make the character move down
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_down(turn_enabled = true, skip_passable = false)
		turn_down if turn_enabled
		if skip_passable or passable?(@x, @y, 2)
			turn_down
			set_coords(nil, @y+1, true)
			follower_set_next_move(:move_down)
			movement_process_end
			increase_steps
		else
			check_event_trigger_touch(@x, @y+1)
		end
	end
	# Make the character move left
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_left(turn_enabled = true, skip_passable = false)
		turn_left if turn_enabled
		if skip_passable or passable?(@x, @y, 4) 
			turn_left
			set_coords(@x-1, nil, true)
			follower_set_next_move(:move_left)
			movement_process_end
			increase_steps
		else
			check_event_trigger_touch(@x-1, @y)
		end
	end
	# Make the character move right
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_right(turn_enabled = true, skip_passable = false)
		turn_right if turn_enabled
		if skip_passable or passable?(@x, @y, 6)
			turn_right
			set_coords(@x+1, nil, true)
			follower_set_next_move(:move_right)
			movement_process_end
			increase_steps
		else
			check_event_trigger_touch(@x+1, @y)
		end
	end
	# Make the character move up
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_up(turn_enabled = true, skip_passable = false)
		turn_up if turn_enabled
		if skip_passable or passable?(@x, @y, 8)
			turn_up
			set_coords(nil, @y-1, true)
			follower_set_next_move(:move_up)
			movement_process_end
			increase_steps
		else
			check_event_trigger_touch(@x, @y-1)
		end
	end
	# Make the character move diagonal lower left
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_lower_left(skip_passable=false)
		unless @direction_fix
			@direction = (@direction==6 ? 4 : (@direction == 2 ? 8 : @direction))
		end
		if skip_passable or 
				(can_move?(@x, @y, 2) and can_move?(@x, @y + 1, 4)) or
				(can_move?(@x, @y, 4) and can_move?(@x - 1, @y, 2))
			move_follower_to_character
			set_coords(@x-1, @y+1, true)
			follower_move_lower_left
			movement_process_end(true)
			increase_steps
		end
	end
	# Make the character move diagonal lower right
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_lower_right(skip_passable=false)
		unless @direction_fix
			@direction = (@direction==4 ? 6 : (@direction == 2 ? 8 : @direction))
		end
		if skip_passable or 
				(can_move?(@x, @y, 2) and can_move?(@x, @y + 1, 6)) or
				(can_move?(@x, @y, 6) and can_move?(@x + 1, @y, 2))
			move_follower_to_character
			set_coords(@x+1, @y+1, true)
			follower_move_lower_right
			movement_process_end(true)
			increase_steps
		end
	end
	# Make the character move diagonal upper left
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_upper_left(skip_passable=false)
		unless @direction_fix
			@direction = (@direction==6 ? 4 : (@direction == 8 ? 2 : @direction))
		end
		if skip_passable or 
				(can_move?(@x, @y, 8) and can_move?(@x, @y - 1, 4)) or
				(can_move?(@x, @y, 4) and can_move?(@x - 1, @y, 8))
			move_follower_to_character
			set_coords(@x-1, @y-1, true)
			follower_move_upper_left
			movement_process_end(true)
			increase_steps
		end
	end
	# Make the character move diagonal upper right
	# @param turn_enabled [Boolean, true] true if it's just turning
	# @param skip_passable [Boolean, false] true if skip the passability test
	def move_upper_right(skip_passable=false)
		unless @direction_fix
			@direction = (@direction==4 ? 6 : (@direction == 8 ? 2 : @direction))
		end
		if skip_passable or 
				(can_move?(@x, @y, 8) and can_move?(@x, @y - 1, 6)) or
				(can_move?(@x, @y, 6) and can_move?(@x + 1, @y, 8))
			move_follower_to_character
			set_coords(@x+1, @y-1, true)
			follower_move_upper_right
			movement_process_end(true)
			increase_steps
		end
	end
	# Make the Game_Character jump
	# @param x_plus [Integer, 0] the number of tile the Game_Character will jump on x
	# @param y_plus [Integer, 0] the number of tile the Game_Character will jump on y
	# @param follow_move [Boolean, false] if the follower moves when the Game_Character starts jumping
	# @param peak_base [Integer, 10] the height of the jump
	# @param skip_passable [Boolean, false] true if skip the passability test
	def jump(dx=0, dy=0, follow_move=true, peak_base=10, skip_passable = false)
		return if jump_type_moving?
		if dx!=0 or dy!=0
			if dx.abs > dy.abs
				dx < 0 ? turn_left : turn_right
			else
				dy < 0 ? turn_up : turn_down
			end
		end
		nx = @x + dx
		ny = @y + dy
		if (dx == 0 and dy == 0) or passable?(nx, ny, 0) or skip_passable
			straighten
			set_coords(nx, ny)
			distance = Math.sqrt(dx*dx+dy*dy).round
			@jump_peak = peak_base + distance - @move_speed
			@jump_count = @jump_peak * 2
			@stop_count = 0
			@pattern = ((@jump_side=(@jump_side+1)%2)==0 ? 1 : 3) unless follow_move
			movement_process_end(true)
			follower_jump(dx, dy) if follow_move
		end
		particle_push
		update_position_shortcuts
		return (@jump_count > 0)
	end

	def transfer_player(map_id, n_x, n_y, mode=:abs, n_dir=@direction, fading=false)
		if $game_temp.in_battle
			return true
		  end
		  if $game_temp.player_transferring or
			 $game_temp.message_window_showing or
			 $game_temp.transition_processing
			return false
		  end
		  $game_temp.player_transferring = true
		  if mode == :abs
			$game_temp.player_new_map_id = map_id
			$game_temp.player_new_x = n_x + ::Yuki::MapLinker.get_OffsetX
			$game_temp.player_new_y = n_y + ::Yuki::MapLinker.get_OffsetY
			$game_temp.player_new_direction = n_dir
		  else
			$game_temp.player_new_map_id = $game_variables[map_id]
			$game_temp.player_new_x = $game_variables[n_x] + ::Yuki::MapLinker.get_OffsetX
			$game_temp.player_new_y = $game_variables[n_y] + ::Yuki::MapLinker.get_OffsetY
			$game_temp.player_new_direction = n_dir
		  end
		  if fading
			Graphics.freeze
			$game_temp.transition_processing = true
			$game_temp.transition_name = nil.to_s
		  end
		  return false
	end
	def change_screen_tone(tone, duration)
		if tone != Yuki::TJN::TONE[3]
		  $game_screen.start_tone_change(tone, duration * 2)
		else
		  Yuki::TJN.force_update_tone(0)
		end
		return true
	end
end	