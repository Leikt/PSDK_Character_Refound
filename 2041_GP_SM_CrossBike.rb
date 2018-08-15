class Game_Player
	# Dictionnary of the character name suffix depending of the states and sub states
	# Exemple : a character image will be used by the cross bike in wheeling if it end by "_cycle_wheel"
	# !!! Be careful modifying this !!!
	CHARA_BY_STATE[:cross_bike] = {:stopped => '_cycle_stop', :turn => '_cycle_roll', :roll => '_cycle_roll', 
						:side_jump => '_cycle_roll', :balanced_stopped => '_cycle_roll', :balanced_roll => '_cycle_roll',
						:roll_to_wheel => '_cycle_roll_to_wheel',	:wheel_to_roll => '_cycle_roll_to_wheel',
						:wheeling => '_cycle_wheel', :bunny_hop => '_cycle_wheel',
						:wheeling_balanced => '_cycle_wheel',
						:sliding => '_cycle_roll', :sliding_ledge => '_cycle_roll'}
	
	# Activate the cross bike
	# @author Leikt
	def cross_bike_on
		return false if @state == :cross_bike
		if state_leavable? and 									# Check if the current state is leavable
				(@state == :feet or @state == :speed_bike)		# Can trigger on the cross bike only from feet or speed_bike
			unless $game_switches[::Yuki::Sw::EV_Bicycle]
				$game_switches[::Yuki::Sw::FM_WasEnabled] = 
					$game_switches[::Yuki::Sw::FM_Enabled]
				$game_system.bgm_memorize
				$game_system.bgs_memorize
			end
			$game_switches[::Yuki::Sw::EV_Bicycle] = false
			$game_switches[::Yuki::Sw::EV_AccroBike] = true
			set_state(:cross_bike)
			return true
		end
		return false
	end
	
	# Stop riding the cross bike
	# @author Leikt
	def cross_bike_off
		return false if @state!= :cross_bike
		if state_leavable? and @state==:cross_bike				# Check if the speed_bike is leavable
			$game_switches[::Yuki::Sw::FM_Enabled] = 
				$game_switches[::Yuki::Sw::FM_WasEnabled]
			$game_switches[::Yuki::Sw::EV_AccroBike] = false
			$game_system.bgm_restore
			$game_system.bgs_restore
			set_state(:feet)
			return true
		end
		return false
	end

	
	# Test if the current state is leavable. Cross bike only leavable when stopped
	# @return [Boolean]
	# @author Leikt
	def is_cross_bike_state_leavable?
		return (@sub_state == :stopped or @sub_state == :roll)
	end
	
	# Reset the state
	# @author Leikt
	def cross_bike_reset
		set_sub_state(:stopped)									# By default the player is stopped
	end
	
	# Reset the sub state
	# @author Leikt
	def cross_bike_sub_reset
		case @sub_state
		when :wheeling, :wheeling_balanced
			@sub_state_counter = CROSS_BIKE_BUNNY_HOP_DELAY
		end
	end
	
	# Do the state's leaving actions
	# @param old_state [Symbol] name of the leaving state
	# @author Leikt
	def on_cross_bike_state_leave
		add_passability(Passabilities::STAIR) 	# Restore the ability to climb stairs
	end
	
	# Do the state's entering actions
	# @param new_state [Symbol] name of the new state
	# @author Leikt
	def on_cross_bike_state_enter
		set_sub_state(:stopped)					# By default the player is stopped
	end
	
	# Do actions before every mouvements including forced move route, or waiting
	# @return [Boolean] true if the normal mouvement can be done, false if not
	# @author Leikt
	def cross_bike_premove
		case @sub_state
		when :wheeling, :wheeling_balanced				# During any type of wheeling
			if !movable?
				@sub_state_counter = CROSS_BIKE_BUNNY_HOP_DELAY		# Reset the bunny hop counter if the player has moved
			end
		when :sliding
			return classic_sliding_premove
		when :sliding_ledge
			if movable?
				if !system_tag_here?(MachBike)
					end_slide_route
					return false
				end
				if @move_route != @sliding_route
					set_sliding_route(@sliding_route, false)
				end
			end
		end
		return true
	end
	
	# Do actions right before normal mouvement (Input from player).
	# @return [Boolean] true if the Input mouvement can be done, false if not
	# @author Leikt
	def cross_bike_update
		case @sub_state
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STOPPED
		when :stopped
			if just_turn_detect						# Detect dir key pressed for 10 frames
				if @dir4 != 0
					if @pressed_B and
							@direction != @dir4 and 
							@direction != 10-@dir4 and
							!@on_stair and !@on_slope
						set_sub_state(:side_jump)
					else
						@direction = @dir4
						set_sub_state(:turn)
					end
					return false
				end
			elsif @dir4 != 0						# The delay for just turn passed
				set_sub_state(:roll)				# Start the mouvement
			elsif @pressed_B and !@on_stair					# No move, but B press
				set_sub_state(:roll_to_wheel)		# Make the player do a wheeling
				return false
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TURN
		when :turn
			if just_turn_detect
				if @dir4 == 0
					set_sub_state(:stopped)
				end
				return false
			elsif @dir4 != 0
				set_sub_state(:roll)
			else
				set_sub_state(:stopped)
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ROLL
		when :roll
			if movable?
				if @dir4 == 0
					set_sub_state(:stopped)
					return false
				elsif @pressed_B and !@on_stair
					set_sub_state(:roll_to_wheel)
					return false					# No move during transition from Roll to Wheeling
				end
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BALANCED STOPPED
		when :balanced_stopped
			if just_turn_detect						# Detect dir key pressed for 10 frames
				if @dir4 != 0
					if @pressed_B
						add_passability(Passabilities::CROSS_BIKE_SIDE_JUMP | Passabilities::CROSS_BIKE_TURN_JUMP)
						res = can_move?(@x, @y, @dir4)
						remove_passability(Passabilities::CROSS_BIKE_SIDE_JUMP | Passabilities::CROSS_BIKE_TURN_JUMP)
						if (res >= 0 and @map_data & Passabilities::CROSS_BIKE_SIDE_JUMP > 0)
							set_sub_state(:side_jump)
						elsif (res >= 0 and @map_data & Passabilities::CROSS_BIKE_TURN_JUMP > 0)
							set_sub_state(:turn_jump)
						end
					elsif @direction == @dir4 or @direction == 10-@dir4
						@direction = @dir4
					end
					return false
				end
			elsif @direction == @dir4 or @direction == 10-@dir4						# The delay for just turn passed
				set_sub_state(:balanced_roll)				# Start the mouvement
			elsif @pressed_B					# No move, but B press
				set_sub_state(:roll_to_wheel)		# Make the player do a wheeling
				return false
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BALANCED ROLL
		when :balanced_roll
			if !cross_bike_check_balanced_tags_here
				set_sub_state(:roll)
			elsif movable?
				if @dir4 == 0
					set_sub_state(:balanced_stopped)
					return false
				elsif @pressed_B
					set_sub_state(:roll_to_wheel)
					return false
				elsif @direction == @dir4 or @direction == 10-@dir4
					@direction = @dir4
				end
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ROLL TO WHEEL
		when :roll_to_wheel
			return false					# No move during transition from Roll to Wheeling
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WHEEL TO ROLL
		when :wheel_to_roll
			return false					# No move during transition from Roll to Wheeling
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WHEELING
		when :wheeling
			if !@pressed_B
				set_sub_state(:wheel_to_roll)
				return false					# No move during transition from Roll to Wheeling
			elsif @sub_state_counter <= 0 and !one_of_system_tags_here?(SlopesTags)
				set_sub_state(:bunny_hop) 
				return false
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WHEELING BALANCED
		when :wheeling_balanced
			if !@pressed_B
				set_sub_state(:wheel_to_roll)
				return false
			elsif movable? 
				if @sub_state_counter <= 0
					set_sub_state(:bunny_hop) 
					return false
				elsif @dir4 != 0
					if @direction == @dir4 or @direction == 10-@dir4
						@direction = @dir4
					end
				end
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BUNNY HOP
		when :bunny_hop
			if movable?
				if @pressed_B or (one_of_system_tags_here?(CrossBikeBunnyHopTags))
					dx = @dir4==4 ? -1 : @dir4==6 ? 1 : 0
					dy = @dir4==8 ? -1 : @dir4==2 ? 1 : 0
					can_move = can_move?(@x, @y, @dir4)
					if @dir4 != 0 and (can_move < 0 or (can_move==0 and @map_data & (
							Passabilities::CROSS_BIKE_BUNNY_HOP | Passabilities::CROSS_BIKE_BIG_BUNNY_HOP |
							Passabilities::CROSS_BIKE_STRAIGHT) == 0))
						dx=dy=0
					end
					if @map_data & Passabilities::CROSS_BIKE_BIG_BUNNY_HOP > 0
						dx*=2
						dy*=2
					end
					force_move_route(MRB.new
							.set_skip_state_update(true)
							.jump(dx, dy, false, 8)
							.particle_push(:dust)
							.set_skip_state_update(false)
							.movement_process_end
							)
				else
					new_sub_state = (cross_bike_check_balanced_tags_here(@x, @y) ? :wheeling_balanced : :wheeling)
					set_sub_state(new_sub_state)
				end
			end
			return false
		when :sliding, :sliding_ledge
			return false
		end
		classic_moves_check
		return true
	end
	
	# Do actions right after all the moves
	# @return [Boolean]
	# @author Leikt
	def cross_bike_postmove
		case @sub_state
		when :wheeling_balanced
			if !cross_bike_check_balanced_tags_here
				set_sub_state(:wheeling)
			end
		end
	end
	
	# Do the sub state's leaving actions
	# @param old_sub_state [Symbol] name of the leaving sub state
	# @author Leikt
	def on_cross_bike_sub_state_leave(old_sub_state)
		# pc "leaving #{old_sub_state}"
		case old_sub_state
		when :roll
			remove_passability(Passabilities::STAIR)
			remove_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			restore_speed(:cross_bike)
			
		when :balanced_stopped
			remove_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			@direction_fix = false
			
		when :balanced_roll
			remove_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			@direction_fix = false
			
		when :side_jump
			remove_passability(Passabilities::CROSS_BIKE_SIDE_JUMP)
			
		when :turn_jump
			remove_passability(Passabilities::CROSS_BIKE_TURN_JUMP)
			
		when :wheeling
			remove_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			
		when :wheeling_balanced
			remove_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			@direction_fix = false
			
		when :bunny_hop
			remove_passability(Passabilities::CROSS_BIKE_BUNNY_HOP)
			remove_passability(Passabilities::CROSS_BIKE_BIG_BUNNY_HOP)
			remove_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			tag_dir = system_tag_here?(AcroBikeRL) ? [4, 6][rand(2)] : (system_tag_here?(AcroBikeUD) ? [2, 8][rand(2)] : 0)
			if tag_dir != 0 and @direction != tag_dir and @direction != 10 - tag_dir
				@direction = tag_dir
			end
			
		when :sliding
			restore_speed(:sliding)
			add_passability(Passabilities::STAIR)
			@walk_anime = true
		
		when :sliding_ledge
			restore_speed(:sliding)
		end
	end
	
	# Do the sub state's entering actions
	# @param new_sub_state [Symbol] name of the new sub state
	# @author Leikt
	def on_cross_bike_sub_state_enter(new_sub_state)
		# pc "enter #{new_sub_state}"
		case new_sub_state
		when :default
			set_sub_state(:stopped)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ROLL
		when :roll
			add_passability(Passabilities::STAIR)
			add_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			change_speed(:cross_bike, 1)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BALANCED STOPPED
		when :balanced_stopped
			add_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			@direction_fix = true
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BALANCED ROLL
		when :balanced_roll
			add_passability(Passabilities::CROSS_BIKE_STRAIGHT)
			@direction_fix = true
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SIDE JUMP
		when :side_jump
			add_passability(Passabilities::CROSS_BIKE_SIDE_JUMP)
			dx = @dir4==4 ? -1 : @dir4==6 ? 1 : 0
			dy = @dir4==8 ? -1 : @dir4==2 ? 1 : 0
			if (can_move?(@x, @y, @dir4) <= 0)
				dx=dy=0
			end
			new_sub_state = (cross_bike_check_balanced_tags_here(@x+dx, @y+dy) ? :balanced_stopped : :stopped)
			force_move_route(MRB.new
				.set_skip_state_update(true)
				.enable_direction_fix
				.jump(dx, dy, false, 8)
				.particle_push(:dust)
				.disable_direction_fix
				.set_skip_state_update(false)
				.set_sub_state(new_sub_state)
				.movement_process_end
				)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TURN JUMP
		when :turn_jump
			add_passability(Passabilities::CROSS_BIKE_TURN_JUMP)
			dx = @dir4==4 ? -1 : @dir4==6 ? 1 : 0
			dy = @dir4==8 ? -1 : @dir4==2 ? 1 : 0
			route = MRB.new
			route.set_skip_state_update(true)
					.disable_direction_fix
			if (can_move?(@x, @y, @dir4) <= 0)
				dx=dy=0
			else
				if @dir4 == @direction or @dir4 == 10-@direction
					route.turn_right_or_left_90
				else
					route.turn_toward_dir(@dir4)
				end
			end
			new_sub_state = (cross_bike_check_balanced_tags_here(@x+dx, @y+dy) ? :balanced_stopped : :stopped)
			route.enable_direction_fix
				.jump(dx,dy, false, 8)
				.particle_push(:dust)
				.disable_direction_fix
				.set_skip_state_update(false)
				.set_sub_state(new_sub_state)
				.movement_process_end
			force_move_route(route)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ROLL TO WHEEL
		when :roll_to_wheel
			new_sub_state = (cross_bike_check_balanced_tags_here(@x, @y) ? :wheeling_balanced : :wheeling)
			animate_from_charset([@direction/2 - 1], CROSS_BIKE_WHEELING_TRANSITION_DURATION, 
					end_command: MRB.command(MRB::SET_SUB_STATE, new_sub_state))
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WHEEL TO ROLL
		when :wheel_to_roll
			new_sub_state = (cross_bike_check_balanced_tags_here(@x, @y) ? :balanced_roll : :roll)
			update_appearence(3)																	# Force the start pattern to wheeling appearence
			animate_from_charset([@direction/2 - 1], CROSS_BIKE_WHEELING_TRANSITION_DURATION, reversed: true, 
					end_command: MRB.command(MRB::SET_SUB_STATE, new_sub_state))
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WHEELING
		when :wheeling
			@sub_state_counter = CROSS_BIKE_BUNNY_HOP_DELAY
			add_passability(Passabilities::CROSS_BIKE_STRAIGHT)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WHEELING BALANCED
		when :wheeling_balanced
			@sub_state_counter = CROSS_BIKE_BUNNY_HOP_DELAY
			@direction_fix = true
			add_passability(Passabilities::CROSS_BIKE_STRAIGHT)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BUNNY HOP
		when :bunny_hop
			add_passability(Passabilities::CROSS_BIKE_BUNNY_HOP)
			add_passability(Passabilities::CROSS_BIKE_BIG_BUNNY_HOP)
			add_passability(Passabilities::CROSS_BIKE_STRAIGHT)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SLIDING
		when :sliding
			change_speed(:sliding, 1)
			@sliding_spin = false 
			@walk_anime = false
			remove_passability(Passabilities::STAIR)
		when :sliding_ledge
			@sliding_route = SLIDING_LEDGE_GO_DOWN_ROUTE
			change_speed(:sliding, 1)
		end
	end
	
	def cross_bike_ext_update
		classic_state_ext_update
		case @state_ext
		when :grass
			if @sub_state == :bunny_hop
				@blank_depth = 0
				@no_shadow = !$game_switches[Yuki::Sw::CharaShadow]
			elsif @sub_state == :wheel_to_roll
				@blank_depth = 6
				@no_shadow = true
			end
		end
	end

	def on_cross_bike_state_ext_leave(old_ext)
		classic_on_state_ext_leave(old_ext)
	end

	def on_cross_bike_state_ext_enter(new_ext)
		classic_on_state_ext_enter(new_ext)
	end
	
	# Do actions when the player is riding a cross bike bridge straight
	# @param dir [Integer] the direction of the mouvement (ignored)
	# @return [Boolean] tru if the mouvement is possible, false if not
	# @author Leikt
	def cross_bike_straight(dir)
		case @sub_state
		when :roll
			set_sub_state(:balanced_roll)
			return true
		when :balanced_roll
			return true
		when :wheeling
			set_sub_state(:wheeling_balanced)
			return true
		when :wheeling_balanced
			return true
		end
		return false
	end
	# Check if there is a there is the balanced cross bike tags here
	# @param x [Integer, @x] the coordinate x to check
	# @param y [Integer, @y] the coordinate y to check
	# @return [Boolean] true if there is balanced tags here
	def cross_bike_check_balanced_tags_here(x=@x, y=@y)
		return $game_map.one_of_system_tags_here?(x, y, CrossBikeBalanceTags)
	end
	
	# Do the action at the end of sliding
	# @return [Boolean] false if the movement process end is skipped
	# @author Leikt
	def cross_bike_slide_end
		if @dir4 != 0
			set_sub_state(:roll)
		else
			set_sub_state(:stopped)
		end
		return true
	end
	
	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def cross_bike_sliding_ledge(dir)
		dir @direction_fixed if sliding?
		set_sub_state(:roll)
		case dir
		when 8
			set_sliding_route(SLIDING_LEDGE_BLOCK_ROUTE)
		when 2
			set_sub_state(:sliding_ledge)
		end
	end
	
	def cross_bike_sliding(dir)
		@direction_fixed = dir
		set_sub_state(:sliding)
		return true
	end

	def cross_bike_surf_transition(dir)
		set_sub_state(:stopped)
		unless $game_switches[::Yuki::Sw::NoSurfContact]
			$game_temp.common_event_id = 9
		end
		return false
	end

	# Do move for the cracked floor transition
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def cross_bike_cracked_floor(front = true, force_tilemap_refresh = false)
		return classic_cracked_floor(front, force_tilemap_refresh)
	end

	# Check the action to do when A is pressed and no event is triggered
	def cross_bike_check_event_trigger_there
		if $game_map.passable?(@x, @y, @direction, nil) and @z <= 1 and can_surf_here?
			$game_temp.common_event_id = 9  #> Common event for surfing
		end
	end
	
	def cross_bike_grass(dir)
		return classic_move_grass(dir)
	end

	def cross_bike_tall_grass(dir)
		return false
	end
	def cross_bike_swamp(dir)
		return false
	end
end