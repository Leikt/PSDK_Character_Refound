class Game_Character
	#______________________________________________
	# >>> ATTRIBUTES MISCS >>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Make the character looking to the player and lock it
	def lock
		return if @locked
		@prelock_direction = @direction
		turn_toward_player
		@locked = true
	end
	# is the character locked ?
	def lock?
		return @locked
	end
	# unlock the character
	def unlock
		return unless @locked
		@locked = false
		if !@direction_fix and @prelock_direction != 0
			@direction = @prelock_direction
		end
	end
	# Set the wait count of the game_character, force it to wait. Also change the wait count of the running interprepreter
	# @param value [Integer] the amount of frame to wait
	def set_wait_count(value)
		@wait_count = value
		if $game_system.map_interpreter.running?
			$game_system.map_interpreter.wait_count = value
		end
	end
	
	#______________________________________________
	# >>> UPDATE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Update the Game_Character
	def update
		update_start
		if check_premove
			update_main 
		end
		update_end
	end
	# First step of the update : counters, shortcuts, mouvements, pattern
	def update_start
		@last_moving = moving?
		update_counters
		update_position_shortcuts
		update_mouvements
		update_pattern
		update_opacity
		update_blank_depth
		update_screen_y_offset
		update_screen_x_offset
	end
	# Update the counters
	def update_counters
		@wait_count -= 1 if @wait_count > 0
		@animation_charset_counter -= 1 if @animation_charset_counter > 0 
	end
	# Update the opacity fading animation
	def update_opacity
		return if @opacity_fading_counter < 0
		@opacity=@faded_opacity+(@original_opacity-@faded_opacity)*(@opacity_fading_counter.to_f/@opacity_fading_duration.to_f)
		@opacity_fading_counter-=1
	end
	# Update the screen Y move animation
	def update_screen_y_offset
		return if @screen_y_offset_fading_counter < 0
		@screen_y_offset=@faded_screen_y_offset+(@original_screen_y_offset-@faded_screen_y_offset)*(@screen_y_offset_fading_counter.to_f/@screen_y_offset_fading_duration.to_f)
		@screen_y_offset_fading_counter-=1
		@blank_depth = @screen_y_offset.abs/2 if @screen_y_offset_blank
	end
	# Update the screen X move animation
	def update_screen_x_offset
		return if @screen_x_offset_fading_counter < 0
		@screen_x_offset=@faded_screen_x_offset+(@original_screen_x_offset-@faded_screen_x_offset)*(@screen_x_offset_fading_counter.to_f/@screen_x_offset_fading_duration.to_f)
		@screen_x_offset_fading_counter-=1
	end
	# Check the high priority actions
	# @return [Boolean] true if there is no high priority action
	def check_premove
		if	@wait_count > 0
			return false
		end
		if @move_route_forcing
			move_type_custom
			return false
		end
		return false if @starting or lock?
		return true
	end
	# Second step of update : mouvement and input
	def update_main
	end
	# Third and last step of update
	def update_end
	end
end