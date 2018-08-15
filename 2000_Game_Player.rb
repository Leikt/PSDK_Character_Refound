class Game_Player < Game_Character	
	attr_reader :fishing_counter
	attr_accessor :cracked_route
	attr_accessor :diving_route
	attr_reader :diving_tp_index
	# Initialize the game player
	def initialize
		super
		add_tags [:player, :human, :trainer]		# Add logical tags to the player
		@move_speed = 3
		@saved_speeds = {:default => 3}
		@speed_bike_acc = 0
		@speed_bike_acc_move_count = 0
		@skip_state_update = false
		@particle_use_sound = true
		@fishing_counter = 0
		@underwater_level = 0
		@cracked_route = CRACKED_FLOOR_FALL_ROUTE
		@diving_route = nil
	end
	def initialize_passability
		super
		add_passability(Passabilities::WALK)
		add_passability(Passabilities::LEDGE)
		add_passability(Passabilities::STAIR)
		add_passability(Passabilities::BRIDGE)
		add_passability(Passabilities::SLOPE)
		add_passability(Passabilities::SLIDING_LEDGE)
		add_passability(Passabilities::SWAMP)
		add_passability(Passabilities::SLIDING)
		add_passability(Passabilities::GRASS)
		add_passability(Passabilities::TALL_GRASS)
		add_passability(Passabilities::SURF_TRANSITION)
		add_passability(Passabilities::WATERFALL)
		add_passability(Passabilities::CRACKED_FLOOR)
		add_passability(Passabilities::UNDERWATER_ZONE)
	end
	def init_counters
		super
		@state_freeze_count = 0
		@wturn = 0
		@bump_delay = 0
		@encounter_count = 0
		@sub_state_counter = 0
		@sub_state_counter_2 = 0
	end
	def moveto(x, y)
		super(x, y, true)
		center(x, y)				# Center the player on the map
		make_encounter_count		# Generate the step before next encounter
	end
	def update
		super
	end
	def update_start
		super
		@last_dir4 = @dir4													# Update the input data once in the frame
		@dir4 = Input.dir4
		@pressed_B = Input.press?(:B)
		@pressed_A = Input.press?(:A)
		@triggered_A = Input.trigger?(:A)
		@on_slope = (@z<= 1 and one_of_system_tags_here?(SlopesTags))		# Check if the player is on slope
		@on_stair = (@z<= 1 and one_of_system_tags_here?(StairsTags))		# Check if the player is on stair
		if movable?
			if @need_reset
				@need_reset = false			# Reset state if it's needed
				on_reset_state
			end
			if @need_sub_reset
				@need_sub_reset = false		# Reset sub state if it's needed
				on_reset_sub_state
			end
			Yuki::MapLinker.test_warp		# Check auto transfer to linked maps
		end
	end
	def update_counters
		super
		return if $DEBUG and Input::Keyboard.press?(Input::Keyboard::LControl)
		@wturn -= 1 					if @wturn > 0
		@encounter_count -= 1 			if @encounter_count > 0
		@sub_state_counter -= 1 		if @sub_state_counter > 0
		@sub_state_counter_2 -= 1 		if @sub_state_counter_2 > 0
		@bump_delay -= 1 				if @bump_delay > 0
		@state_freeze_count -= 1 		if @state_freeze_count > 0
	end
	def update_mouvements
		last_real_x = @real_x						# Store the last real coords for scrolling
		last_real_y = @real_y - @slope_height
		super
		update_scroll_map(last_real_x, last_real_y)
	end
	def check_premove
		return false if $game_temp.message_window_showing or 					# No move if there is a message displaying			
			($game_system.map_interpreter.running? and !@move_route_forcing) or	# or event running and not move route forced
			$game_temp.battle_calling
		return classic_moves_check if $DEBUG and 								# Do basic move if debug free mode
			Input::Keyboard.press?(Input::Keyboard::LControl)
		return false if @last_moving and !moving? and check_event_trigger_here([1,2])
		return false unless state_check_premove									# Check the state premove
		return super
	end
	def update_main
		state_update	# Update the state
		state_ext_update
	end
	def update_end
		super
		@step_anime = false if $game_system.map_interpreter.running?	# Correct step animation if event is running
		$game_map.need_refresh = true									# Refresh the game_map, important for the scripted condition
	end
	# Scroll the game map to follow the player
	# @param last_real_x [Integer]
	# @param last_real_y [Integer]
	def update_scroll_map(last_real_x, last_real_y)
		ry = @real_y - @slope_height
		rx = @real_x
		if rx < last_real_x and rx - $game_map.display_x < CENTER_X
			$game_map.scroll_left(last_real_x - rx)
		elsif rx > last_real_x and rx - $game_map.display_x > CENTER_X
			$game_map.scroll_right(rx - last_real_x)
		end
		if ry > last_real_y and ry - $game_map.display_y > CENTER_Y
			$game_map.scroll_down(ry - last_real_y)
		elsif ry < last_real_y and ry - $game_map.display_y < CENTER_Y
			$game_map.scroll_up(last_real_y - ry)
		end
	end
	# Check if the player just turn, and set the just turn counter
	# @return [Boolean]
	def just_turn_detect
		if @last_dir4==0 and (Input.trigger?(:UP) or  Input.trigger?(:DOWN) or	# If directionnal keys just trigger
							  Input.trigger?(:LEFT) or Input.trigger?(:RIGHT))
			@wturn = 10 - @move_speed											# set the just turn counter
		end
		return (@wturn > 0)														# Return true if remaining just turn time > 0
	end
	# Classic bump handeling
	def classic_bump
		if moving?								# No Bump if the player is moving
			@step_anime = false					# Restore current step anime
			@old_pattern=@pattern				# and pattern
			return
		end
		return if @bump_delay > 0				# Avoid 60 per seconds
		unless $game_temp.common_event_id != 0
			if @last_x == @x and @last_y == @y				# Bump if stucked and
				if @dir4 != 0								# Direction input
					Audio.se_play(BUMP_FILE)				# Play sound
					@bump_delay = 40 - 2*@move_speed		# Set the delay
					@step_anime = true						# Animation
				else
					@step_anime = false						# No directional input => restor current step anime
				end
			else
				@last_x = @x	# if Not stucked
				@last_y = @y	# update the last coords
			end
		end
	end
	# Check if there's an event trigger on the tile where the player stands
	# @param triggers [Array<Integer>] the list of triggers to check
	# @return [Boolean]
	def check_event_trigger_here(triggers)
		if $game_system.map_interpreter.running?
			return false
		end
		result = false
		x = @x
		y = @y
		z = @z
		for event in $game_map.events_list
			if event.contact?(x, y, z, @slope_height, @y) and triggers.include?(event.trigger)
				if !event.jumping? and event.over_trigger?
					event.start
					result = true
				end
			end
		end
		return result
	end
	# Check if there's an event trigger in front of the player
	# @param triggers [Array<Integer>] the list of triggers to check
	# @return [Boolean]
	def check_event_trigger_there(triggers)
		if $game_system.map_interpreter.running?
			return false
		end
		result = false
		d = @direction
		new_x = @front_x#@x + (d == 6 ? 1 : d == 4 ? -1 : 0)
		new_y = @front_y#@y + (d == 2 ? 1 : d == 8 ? -1 : 0)
		z = @z
		for event in $game_map.events_list
			if event.contact?(new_x, new_y, z, @slope_height, @y) and triggers.include?(event.trigger)
				if not event.jumping? and !event.over_trigger?
					event.start
					result = true
				end
			end
		end
		return result if result
		if $game_map.counter?(new_x, new_y)
			z = @z
			nnx = new_x + (d == 6 ? 1 : d == 4 ? -1 : 0)
			nny = new_y + (d == 2 ? 1 : d == 8 ? -1 : 0)
			for event in $game_map.events_list
				if event.contact?(nnx, nny, z, @slope_height, @y) and triggers.include?(event.trigger)
					if not event.jumping? and not event.over_trigger?
						event.start
						result = true
					end
				end
			end
		end
		return result if result	
		state_check_event_trigger_there
		follower_check_trigger
		return result
																	# Trigger common event in front of interactable tags
		# if ((@system_tag == TSea or @system_tag == TUnderWater))	
		# 	$game_temp.common_event_id = 29 						#>Event commun de pongée
		# elsif(@front_system_tag == HeadButt)
		# 	$game_temp.common_event_id = 20 						#> Event commun de headbutt
		# elsif($game_map.passable?(x, y, d, nil) and z <= 1 and !surfing?)
		# 	if(can_surf_here?)
		# 		$game_temp.common_event_id = 9  					#>Event commun de surf
		# 	elsif ($game_map.system_tag_here?(@front_x, @front_y, WaterFall))
		# 		$game_temp.common_event_id = 26 					#> Event commun de cascade
		# 	end
		# end
		# follower_check_trigger		# Check follower activation
		# return result
	end
	# Check if the player touch an event and start it if so
	# @param x [Integer] the x position to check
	# @param y [Integer] the y position to check
	# @return [Boolean]
	def check_event_trigger_touch(x, y)
		if $game_system.map_interpreter.running?
			return false
		end
		result = false
		z = @z
		for event in $game_map.events_list
			if event.contact?(x, y, z, @slope_height, @y) and [1,2].include?(event.trigger)
				if !event.jumping? and !event.over_trigger?
					event.start
					result = true
				end
			end
		end
		return result
	end
	RELATIVE_TELEPORT_RULE_PROC = Proc.new {|infos, rule_set, key|
		case key
		when :map, :map_id
			infos[0] = rule_set[key]
		when :ofx, :offset_x
			infos[1] += rule_set[key]
		when :ofy, :offset_y
			infos[2] += rule_set[key]
		when :x, :force_x
			infos[1] = rule_set[key]
		when :y, :force_y
			infos[2] = rule_set[key]
		when :route
			@cracked_route = rule_set[key]
		end
	}
	def apply_relative_teleport_rule(rule_set)
		infos = [$game_map.map_id, @x-Yuki::MapLinker.get_OffsetX, @y-Yuki::MapLinker.get_OffsetY]
		if rule_set.is_a?(Hash)
			for key in rule_set.keys
				RELATIVE_TELEPORT_RULE_PROC.call(infos, rule_set, key)
			end
		elsif rule_set.is_a?(Array)
			for rule_set_2 in rule_set
				rect = rule_set_2[:rect]
				next if (rect!=nil and
						(infos[1] < rect[0] or infos[2] < rect[1] or
						infos[1] > rect[2] or infos[2] > rect[3]))
				for key2 in rule_set_2.keys
					RELATIVE_TELEPORT_RULE_PROC.call(infos, rule_set_2, key2)
				end
				break
			end
		end
		$game_variables[26] = infos[0]
		$game_variables[27] = infos[1]
		$game_variables[28] = infos[2]
	end
end