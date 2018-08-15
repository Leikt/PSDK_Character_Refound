class Game_Character
	#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	#>>>>>> GENERAL >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	# General method for states managing
	0

	# Change the state of the player.
	# @param new_state [Symbol] the name of the state
	# @return [Boolean]
	# @author Leikt
	def set_state(new_state)
		return set_states(new_state: new_state)
	end
	
	# Change the sub state of the player
	# @param new_sub_state [Symbol] name of the new sub state
	# @return [Boolean]
	# @author Leikt
	def set_sub_state(new_sub_state)
		return set_states(new_sub_state: new_sub_state)
	end

	def set_state_ext(new_ext)
		return set_states(new_ext: new_ext)
	end
	
	def set_states(new_state: @state, new_sub_state: @sub_state, new_ext: @state_ext)
		return if @state == new_state and 				# The states can't change if it's the sames
					 @sub_state == new_sub_state and
					 @state_ext == new_ext
		@appearence_updated = false						# Reset the appearence (update appearence can appear once in frame)
		remove_tag("#{@state}_#{@sub_state}".to_sym)	# Remove the old tag
		if @state != new_state
			on_sub_state_leave(@sub_state)				# Do old sub state's leaving actions
			on_state_leave(@state)						# Do leaving actions of the old state
			@state = new_state
			@sub_state = new_sub_state
			on_state_enter(@state)						# Do the enter actions of the new state
			on_sub_state_enter(@sub_state)				# Do new sub state's entering actions
		elsif @sub_state != new_sub_state
			on_sub_state_leave(@sub_state)				# Do old sub state's leaving actions
			@sub_state = new_sub_state
			on_sub_state_enter(@sub_state)				# Do new sub state's entering actions
		else
			on_state_ext_leave(@state_ext)				# Do old extension's leaving actions
			@state_ext = new_ext
			on_state_ext_enter(@state_ext)
		end
		add_tag("#{@state}_#{@sub_state}".to_sym)		# Add the new tag
		update_appearence						
		$game_map.need_refresh = true					# Refresh the map, will trigger the scripted conditions of the events
	end
	
	# Stop the update of the state for a limited frames count
	# @param amount [Integer, 1] the count of frame to freeze_state
	# @author Leikt
	def freeze_state(amount = 1)
		@state_freeze_count = amount
	end
	
	def update_appearance(forced_pattern = 0)
	end
	
	# Throw the bup sound if the conditions are filled
	# @author Leikt
	def state_handle_bump
		unless surfing?
			classic_bump
		end
	end
	
	# Test if the state is updatable or not
	# @return [Boolean]
	# @author Leikt
	def updatable?
		return (!@skip_state_update and @state_freeze_count <= 0)
	end
	
	# Shortcut for the classic moves
	# @author Leikt
	def classic_moves_check
		if movable?
			if @triggered_A
				return if check_event_trigger_here([0]) or check_event_trigger_there([0,1,2])
			end
			case @dir4
			when 2; move_down
			when 4; move_left
			when 6; move_right
			when 8; move_up
			end
			state_handle_bump
			state_postmove_update
		end
	end

	# Shortcut for the classic slide behavior
	# @author Leikt
	def classic_sliding_premove
		if movable?
			if one_of_system_tags_here?(SurfaceSlidingTags)
				@sliding_route = SLIDE_STRAIGHT_ROUTE
				@direction = @direction_fixed
				@sliding_throwed = false
			elsif one_of_system_tags_here?(SpinSurfaceSlidingTags)
				@sliding_route = SLIDE_SPIN_ROUTE
				@sliding_throwed = false
			elsif one_of_system_tags_here?(StreamSlidingTags)
				@sliding_route = SLIDE_STRAIGHT_ROUTE
				tag=$game_map.get_filtered_system_tags(@x, @y, StreamSlidingTags)[0]
				dir = StreamSlidingTags.index(tag)
				@direction = @direction_fixed = (dir % 4 + 1) * 2
				@sliding_throwed = false
			elsif one_of_system_tags_here?(SpinStreamSlidingTags)
				@sliding_route = SLIDE_SPIN_ROUTE
				tag=$game_map.get_filtered_system_tags(@x, @y, SpinStreamSlidingTags)[0]
				dir = SpinStreamSlidingTags.index(tag)
				@direction_fixed = (dir % 4 + 1) * 2
				@sliding_throwed = false
			elsif one_of_system_tags_here?(ThrowerSlidingTags)
				@sliding_route = SLIDE_STRAIGHT_ROUTE
				tag=$game_map.get_filtered_system_tags(@x, @y, ThrowerSlidingTags)[0]
				dir = ThrowerSlidingTags.index(tag)
				@direction = @direction_fixed = (dir % 4 + 1) * 2
				@sliding_throwed = true
			elsif one_of_system_tags_here?(SpinThrowerSlidingTags)
				@sliding_route = SLIDE_SPIN_ROUTE
				tag=$game_map.get_filtered_system_tags(@x, @y, SpinThrowerSlidingTags)[0]
				dir = SpinThrowerSlidingTags.index(tag)
				@direction_fixed = (dir % 4 + 1) * 2
				@sliding_throwed = true
			elsif !@sliding_throwed
				end_slide_route
				return false
			end
			if can_move?(@x, @y, @direction_fixed) < 0
				end_slide_route
				return false
			end
			if @move_route != @sliding_route
				set_sliding_route(@sliding_route, false)
			end
		end
		return true
	end

	def set_sliding_param(direction, spin, throwed)
		set_sub_state(:sliding)
		@direction_fixed = direction
		if spin
			@sliding_route = SLIDE_SPIN_ROUTE
		else
			@sliding_route = SLIDE_STRAIGHT_ROUTE
			@direction = direction
		end
		@sliding_throwed = throwed
	end

	def check_sliding_tags
		if one_of_system_tags_here?(AllSlidingTags)
			if one_of_system_tags_here?(AllSurfaceSlidingTags)
				return false
			else
				if one_of_system_tags_here?(StreamSlidingTags)
					dir = StreamSlidingTags.index($game_map.get_filtered_system_tags(@x, @y, StreamSlidingTags)[0])
					@direction_fixed = (dir % 4 + 1) * 2
				elsif one_of_system_tags_here?(SpinStreamSlidingTags)
					dir = SpinStreamSlidingTags.index($game_map.get_filtered_system_tags(@x, @y, SpinStreamSlidingTags)[0])
					@direction_fixed = (dir % 4 + 1) * 2
				elsif one_of_system_tags_here?(ThrowerSlidingTags)
					dir = ThrowerSlidingTags.index($game_map.get_filtered_system_tags(@x, @y, ThrowerSlidingTags)[0])
					@direction_fixed = (dir % 4 + 1) * 2
				elsif one_of_system_tags_here?(SpinThrowerSlidingTags)
					dir = SpinThrowerSlidingTags.index($game_map.get_filtered_system_tags(@x, @y, SpinThrowerSlidingTags)[0])
					@direction_fixed = (dir % 4 + 1) * 2
				else 
					return false
				end
				set_sub_state(:sliding)
				return true
			end
		end
		return false
	end

	def classic_cracked_floor(front, force_tilemap_refresh)
		x = (front ? @front_x : @x)
		y = (front ? @front_y : @y)
		case $game_map.get_filtered_system_tags(x, y, CrackedFloorTags)[0]
		when CrackedSoil, WillCrackSoil
			$game_map.increase_tagged_tile_id(x, y, CrackedFloorTags)
			$scene.spriteset.init_tilemap if force_tilemap_refresh
			new_tags = $game_map.get_filtered_system_tags(x, y, CrackedFloorTags)
			if new_tags.empty?
				$game_temp.common_event_id = 34
			elsif new_tags[0] == Hole
				$game_temp.common_event_id = 8
			end
		when Hole
			$game_temp.common_event_id = 8
		end
		return true
	end

	def classic_state_ext_update
		case @state_ext
		when :grass
			if !system_tag_here?(TGrass)
				set_state_ext(nil)
			end
		end
	end

	def classic_on_state_ext_leave(old_ext)
		case old_ext
		when :grass
			@blank_depth = 0
			@no_shadow = !$game_switches[Yuki::Sw::CharaShadow]
		end
	end

	def classic_on_state_ext_enter(new_ext)
		case new_ext
		when :grass
			set_blank(:move_end, 6, true)
		end
	end
	
	# Will reset the state at the next frame's beginning
	# @author Leikt
	def reset_state
		@need_reset = true
	end
	
	# Will reset the sub state at the next frame's begining
	# @author Leikt
	def reset_sub_state
		@need_sub_reset = true
	end
	
	def set_states_at_move_end(new_state: @state, new_sub_state: @sub_state)
		@state_at_move_end = new_state
		@sub_state_at_move_end = new_sub_state
	end
	
	def classic_move_grass(dir)
		if @state_ext != :grass
			set_state_ext(:grass)
		end
		return true
	end

	#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	#>>>>>> DEFAULT STATE METHODS >>>>>>>>>>>>>>>>>>>>>>>
	#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	# Redefined methods in the child classes
	0

	# Check if the state is leavable
	# @return [Boolean]
	def state_leavable?
		return false
	end
	# Reset the state
	def on_reset_state
	end
	# Reset the sub state
	def on_reset_sub_state
	end
	# Do action when the state is leaved
	# @param old_state [Symbol] name of the leaving state
	def on_state_leave(old_state)
	end
	# Do action on the state enter
	# @param new_state [Symbol] name of the new state
	def on_state_enter(new_state)
	end
	# Do action when the sub state is leaved
	# @param old_sub_state [Symbol] name of the leaving sub_state
	def on_sub_state_leave(old_sub_state)
	end
	# Do action when the sub state start
	# @param new_sub_state [Symbol] name of the new sub state
	def on_sub_state_enter(new_sub_state)
	end
	# Do action when the extension leave
	def on_state_ext_leave(old_ext)
	end
	# Do action when the extension enter
	def on_state_ext_enter(new_ext)
	end
	# Premove check, test if the route forcing, and many things are allowed by the state or not
	# @return [Boolean]
	def state_check_premove
		return true
	end
	# Update the current state
	# @return [Boolean]
	def state_update
		return true
	end
	# Do after move actions
	# @return [Boolean]
	def state_postmove_update
		return true
	end
	# Update the state ext
	def state_ext_update
	end
	# Finish the sliding route
	def state_slide_end
	end
	# Check the state coherence : grass sprite, swamp, ...
	def check_state_coherence
	end
	# Check if there is sliding tag under the character, and do the move if
	# @return [Boolean]
	def check_sliding_tags
		return true
	end
	# Handle sliding ledge mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def move_sliding_ledge(dir)
		return true
	end
	# Handle the sliding mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def move_sliding(dir)
		return true
	end
	# Handle the surf transition mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def move_surf_transition(dir)
		return true
	end
	# Handle the cracked floor mouvement
	# @param front [Boolean] true if the character is moving (by default : true)
	# @param force_tilemap_refresh [Boolean] true if the tilemap need to be refreshed (by default : false)
	# @return [Boolean]
	def move_cracked_floor(front = true, force_tilemap_refresh = false)
		return true
	end
	# Handle the grass mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def move_grass(dir)
		return true
	end
	# Handle the tall grass mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def move_tall_grass(dir)
		return true
	end
	# Handle the swamp mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def move_swamp(dir)
		return true
	end
	# Handle the cross bike straight mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def cross_bike_straight(dir)
		return true
	end
	# Handle the waterfall mouvement
	# @param dir [Integer] the direction of the mouvement
	# @return [Boolean]
	def move_waterfall(dir)
		return true
	end
	
end