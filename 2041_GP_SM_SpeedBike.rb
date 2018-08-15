class Game_Player
	# Dictionnary of the character name suffix depending of the states and sub states
	# Exemple : a character image will be used by the cross bike in wheeling if it end by "_cycle_wheel"
	# !!! Be careful modifying this !!!
	CHARA_BY_STATE[:speed_bike] = {:stopped => '_cycle_stop', :turn => '_cycle_roll', :acceleration => '_cycle_roll', 
						:max_speed => '_cycle_roll' ,:deceleration => '_cycle_roll', :sliding_ledge => '_cycle_roll',
						:sliding => '_cycle_roll'}
						
	
	# Activate the speed bike
	# @author Leikt
	def speed_bike_on
		return false if @state == :speed_bike
		if state_leavable? and 								# Check if the current state is leavable
				(@state==:feet or @state==:cross_bike)		# Player can ride the speed bike only from feet state or cross_bike
			unless $game_switches[::Yuki::Sw::EV_AccroBike]
				$game_switches[::Yuki::Sw::FM_WasEnabled] = 
					$game_switches[::Yuki::Sw::FM_Enabled]
				$game_system.bgm_memorize
				$game_system.bgs_memorize
			end
			$game_switches[::Yuki::Sw::EV_AccroBike] = false
			$game_switches[::Yuki::Sw::EV_Bicycle] = true
			set_state(:speed_bike)
			return true
		end
		return false
	end
	
	# Stop riding the speed bike
	# @author Leikt
	def speed_bike_off
		return false if @state != :speed_bike or !state_leavable?
		$game_switches[::Yuki::Sw::FM_Enabled] = 
			$game_switches[::Yuki::Sw::FM_WasEnabled]
		$game_switches[::Yuki::Sw::EV_Bicycle] = false
		$game_system.bgm_restore
		$game_system.bgs_restore
		set_state(:feet)
		return true
	end
	
	# Do the state's leaving actions
	# @param old_state [Symbol] name of the leaving state
	# @author Leikt
	def on_speed_bike_state_leave
		restore_speed(:speed_bike)			# Delete the speed change for the speed bike
	end
	
	# Do the state's entering actions
	# @param new_state [Symbol] name of the new state
	# @author Leikt
	def on_speed_bike_state_enter
		set_sub_state(:stopped)				# By default the player is stopped
		change_speed(:speed_bike, -6)		# Speed bike speed is by default the minimum, it will be setted by another speed
	end
	
	# Reset the state
	# @author Leikt
	def speed_bike_reset
		set_sub_state(:stopped)
	end
	
	# Reset the sub state
	# @author Leikt
	def speed_bike_sub_reset
	end
	
	# Test if the current state is leavable. Speed bike only leavable when stopped
	# @return [Boolean]
	# @author Leikt
	def is_speed_bike_state_leavable?
		return (@sub_state == :stopped or @sub_state == :roll)
	end
	
	# Do actions before every mouvements including forced move route, or waiting
	# @return [Boolean] true if the normal mouvement can be done, false if not
	# @author Leikt
	def speed_bike_premove
		check_speed_bike_coherence
		case @sub_state
		when :deceleration						# During deceleration
			if @dir4 != 0						# Restart acceleration if the player press a direction
				set_sub_state(:acceleration)
			end
			if @z<=1 and one_of_system_tags_here?(SwampsTags)
				cross_bike_off
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
		return true								# Normal move is always possible
	end

	# Do actions right before normal mouvement (Input from player).
	# @return [Boolean] true if the Input mouvement can be done, false if not
	# @author Leikt
	def speed_bike_update
		case @sub_state
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STOPPED
		when :stopped
			if just_turn_detect					# If the player press a direction less than 10 frames
				if @dir4 != 0					# Make the player turn on himself
					@direction = @dir4
					set_sub_state(:turn)
					return false				# Block mouvement (just turn)
				end
			elsif @dir4 != 0					# Not turning, it's moving
				set_sub_state(:acceleration)	# Start acceleration
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TURN
		when :turn
			if just_turn_detect					# If the player press a direction less than 10 frames
				if @dir4 == 0					# And  no input direction
					set_sub_state(:stopped)		# Restore the stopped state
				end
				return false					# Block the mouvement (just turn)
			elsif @dir4 != 0					# Direction pressed => start acceleration
				set_sub_state(:acceleration)
			else
				set_sub_state(:stopped)			# In all other cases : stopped
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ACCELERATION
		when :acceleration
			if @dir4 == 0							# No direction pressed ?
				if movable? 						# Before the input move, it's true every end of move : equivalent to wait the end of transition between two tile
					if @speed_bike_acc <= 0.5		# Speed near to 0
						set_sub_state(:stopped)		# Directly stopped and block the mouvement
						return false
					else
						set_sub_state(:deceleration)# Else start deceleration
					end
				end
			else									# There is a direction pressed
				@speed_bike_acc_move_count += 1		# The speed increase every 10 frame pressing a directional key
				if @speed_bike_acc_move_count >= 10
					@speed_bike_acc_move_count = 0
					@speed_bike_acc += 0.5
					if @speed_bike_acc >= 5			# 5 is the max speed
						set_sub_state(:max_speed)
					else
						change_speed(:speed_bike_acc, # Update the speed, make the change visible
									@speed_bike_acc)
					end
				end
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MAX SPEED
		when :max_speed
			if @dir4 == 0
				set_sub_state(:deceleration)	# Decelerate if there no more directional key pressed
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DECELERATION
		when :deceleration
			if @speed_bike_acc <= 0.5
				set_sub_state(:stopped)			# Stop if the speed has decreased enought
				return false
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SLIDING LEDGE UP
		when :sliding, :sliding_ledge
			return false
		end
		classic_moves_check
		return true
	end
	
	# Do actions right after all the moves
	# @return [Boolean]
	# @author Leikt
	def speed_bike_postmove
		case @sub_state
		when :acceleration, :max_speed, :deceleration			# During moving sub states
			if movable?											# If not moving
				if @bump_delay <= 0 and 
						@speed_bike_acc > 1
					Audio.se_play(BUMP_FILE) 					# Play bump sound because you can't pass through walls ^^
				end
				set_sub_state(:stopped)							# And stop the mouvement
				check_cracked_floor_here
			end
		end
	end
	
	# Do the sub state's leaving actions
	# @param old_sub_state [Symbol] name of the leaving sub state
	# @author Leikt
	def on_speed_bike_sub_state_leave(old_sub_state)
		case old_sub_state
		when :acceleration; 	
			restore_speed(:speed_bike_acc)
		when :max_speed; 	
			restore_speed(:speed_bike_acc)	
			remove_tag(:speed_bike_max)
		when :deceleration
			restore_speed(:speed_bike_acc)
			force_move_route(MRB.new)		# Reset the forced move and enable the player controls
		when :sliding_ledge
			restore_speed(:speed_bike_acc)
		when :sliding
			restore_speed(:sliding)
			add_passability(Passabilities::STAIR)
			@walk_anime = true
		end
	end
	
	# Do the sub state's entering actions
	# @param new_sub_state [Symbol] name of the new sub state
	# @author Leikt
	def on_speed_bike_sub_state_enter(new_sub_state)
		case new_sub_state
		when :default
			set_sub_state(:stopped)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> STOPPED
		when :stopped
			@speed_bike_acc = 0.5							# Reset the speed for the next start
			force_move_route(MRB.new)
			# change_speed(:speed_bike_acc, 0.5)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ACCELERATION
		when :acceleration
			change_speed(:speed_bike_acc, @speed_bike_acc)	# Set the speed where it was before
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MAX SPEED
		when :max_speed
			@speed_bike_acc = 5								# Max speed is 5
			change_speed(:speed_bike_acc, 5)				# Update the speed modifier
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DECELERATION
		when :deceleration
			change_speed(:speed_bike_acc, @speed_bike_acc)	# Update the speed
			spd = @speed_bike_acc = @speed_bike_acc.floor	# Use a Integer speed for calculation
			if spd <= 1										# Case of the just begin mouvement (from stopped)	
				force_move_route(MRB.new
					.change_speed(:speed_bike_acc, spd)
					.set_instance_variable(:@speed_bike_acc, @speed_bike_acc - 1)
					)
			elsif spd > 1												# Case of the normal deceleration
				route = MRB.new
				while (spd > 0.5)										# Calculation of the route until stopped
					route.change_speed(:speed_bike_acc, spd)
					(spd-1).times do |i|								# One step by speed value (speed = 5 then 4 step to decrease)
						route.move_forward
					end
					route.set_instance_variable(:@speed_bike_acc, spd - 1)
					spd -= 1
				end
				force_move_route(route)
			end
		when :sliding
			change_speed(:sliding, [@speed_bike_acc, 3].max)
			@walk_anime = false
			remove_passability(Passabilities::STAIR)
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SLIDING LEDGE
		when :sliding_ledge
			case @direction
			when 8
				change_speed(:speed_bike_acc, 5)
				@sliding_route = SLIDING_LEDGE_GO_UP_ROUTE
			when 2
				change_speed(:speed_bike_acc, 3)
				@sliding_route = SLIDING_LEDGE_GO_DOWN_ROUTE
			end
		end
	end
	
	def speed_bike_ext_update
		classic_state_ext_update
	end

	def on_speed_bike_state_ext_leave(old_ext)
		classic_on_state_ext_leave(old_ext)
	end

	def on_speed_bike_state_ext_enter(new_ext)
		classic_on_state_ext_enter(new_ext)
	end

	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def speed_bike_sliding_ledge(dir)
		dir @direction_fixed if sliding?
		case dir
		when 8
			if has_tag?(:speed_bike_max_speed)
				set_sub_state(:sliding_ledge)
			else
				set_sliding_route(SLIDING_LEDGE_BLOCK_BIKE_ROUTE)
			end
		when 2
			set_sub_state(:sliding_ledge)
		end
	end
	
	# Do actions at the end of slide
	# @return [Boolean] false if not update the mouvement process end
	# @author Leikt
	def speed_bike_slide_end
		if @dir4 != 0
			if @speed_bike_acc >= 5
				set_sub_state(:max_speed)
			else
				set_sub_state(:acceleration)
			end
		else
			set_sub_state(:deceleration)
		end
		return true
	end

	def speed_bike_sliding(dir)
		@direction_fixed = dir
		set_sub_state(:sliding)
		return true
	end

	def speed_bike_surf_transition(dir)
		return false if @sub_state == :deceleration
		unless $game_switches[::Yuki::Sw::NoSurfContact]
			$game_temp.common_event_id = 9
		end
		return false
	end
	
	# Do move for the cracked floor transition
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def speed_bike_cracked_floor(front = true, force_tilemap_refresh = false)
		x = (front ? @front_x : @x)
		y = (front ? @front_y : @y)
		case $game_map.get_filtered_system_tags(x, y, CrackedFloorTags)[0]
		when CrackedSoil, WillCrackSoil
			$game_map.increase_tagged_tile_id(x, y, CrackedFloorTags)
			$scene.spriteset.init_tilemap if force_tilemap_refresh
			new_tags = $game_map.get_filtered_system_tags(x, y, CrackedFloorTags)
			if new_tags.empty?
				$game_temp.common_event_id = 34
			elsif new_tags[0] == Hole and @sub_state != :max_speed
				$game_temp.common_event_id = 8
			end
		when Hole
			$game_temp.common_event_id = 8
		end
		return true
	end

	def check_cracked_floor_here
		if $game_map.get_filtered_system_tags(@x, @y, CrackedFloorTags)[0] == Hole
			$game_temp.common_event_id = 8
		end
	end
	# Check the action to do when A is pressed and no event is triggered
	def speed_bike_check_event_trigger_there
		if $game_map.passable?(@x, @y, @direction, nil) and @z <= 1 and can_surf_here?
			$game_temp.common_event_id = 9  #> Common event for surfing
		end
	end
	
	def speed_bike_grass(dir)
		return classic_move_grass(dir)
	end

	def check_speed_bike_coherence
		case @sub_state
		when :stopped, :acceleration, :deceleration, :max_speed, :sliding, :sliding_ledge
			if one_of_system_tags_here?(SwampsTags)
				speed_bike_off
			elsif @state_ext != :grass and system_tag_here?(TGrass) 
				set_state_ext(:grass)
			end
		end
	end
	
	def speed_bike_tall_grass(dir)
		return false
	end
	def speed_bike_swamp(dir)
		return false
	end
end