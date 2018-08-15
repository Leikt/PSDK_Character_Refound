class Game_Player
	# Dictionnary of the character name suffix depending of the states and sub states
	# Exemple : a character image will be used by the cross bike in wheeling if it end by "_cycle_wheel"
	# !!! Be careful modifying this !!!
	CHARA_BY_STATE[:diving] = {
		:stopped => '_surf', :down_from_surface=>'_surf', :up_to_surface=>'_surf', :up_to_under=>'_surf', :down_from_under=>'_surf'
	}
	# List of the particle can't be emitted by the current state
	PARTICLE_VETO[:diving] = [:dust]
	# Test if the player is currently underwater
	def is_underwater?(lvl=1)
		return @underwater_level >= lvl
	end

	def diving_go_down
		if @underwater_level == 0
			set_states(new_state: :diving, new_sub_state: :down_from_surface)
		else
			set_sub_state(:down_from_under)
		end
		@underwater_level += 1
	end

	def diving_go_up
		if @underwater_level == 1
			set_states(new_state: :diving, new_sub_state: :up_to_surface)
		else
			set_sub_state(:up_to_under)
		end
		@underwater_level -= 1
	end

	# Reset the state
	# @author Leikt
	def diving_reset
	end
	
	# Reset the sub state
	# @author Leikt
	def diving_sub_reset
	end
	
	# Test if the state is leavable
	# @return [Boolean]
	# @author Leikt
	def is_diving_state_leavable?
		return true
	end
	
	# Do actions when the machine leave the state
	# @author Leikt
	def on_diving_state_leave
		@no_shadow = !$game_switches[Yuki::Sw::CharaShadow]
		@cracked_route = CRACKED_FLOOR_FALL_ROUTE
		remove_passability(Passabilities::TALL_GRASS)
	end
	
	# Do actions when the machine enter the state
	# @author Leikt
	def on_diving_state_enter
		@no_shadow = true
		@cracked_route = DIVING_CRACKED_FLOOR_FALL_ROUTE
		add_passability(Passabilities::TALL_GRASS)
	end
	
	# Do actions before every mouvements including forced move route, or waiting
	# @return [Boolean] true if the normal mouvement can be done, false if not
	# @author Leikt 
	def diving_premove
		case @sub_state
		when :tall_grass
			if !system_tag_here?(TTallGrass)
				set_sub_state(:move)
			end
			push_bubbles
		when :stopped, :move, :down_from_under, :up_to_under
			push_bubbles
		when :sliding
			push_bubbles
			return classic_sliding_premove
		end
		return true
	end
	
	# Do actions right before normal mouvement (Input from player).
	# @return [Boolean] true if the Input mouvement can be done, false if not
	# @author Leikt
	def diving_update
		case @sub_state
		when :stopped
			if @dir4 != 0 and movable?
				if just_turn_detect
					@direction = @dir4
					return false
				else
					set_sub_state(:move)
				end
			end
		when :move
			if @dir4 == 0 and movable?
				set_sub_state(:stopped)
			end
		when :down_from_surface, :up_to_surface, :down_from_under, :up_to_under, :sliding
			return false
		when :tall_grass
			if @dir4 != 0 and movable?
				if just_turn_detect
					@direction = @dir4
					return false
				end
			end
		end
		classic_moves_check						# Do classic mouvement
		return true
	end
	
	# Do actions right after all the moves
	# @return [Boolean]
	# @author Leikt
	def diving_postmove
		return true
	end
	
	# Do the sub state's leaving actions
	# @param old_sub_state [Symbol] name of the leaving sub state
	# @author Leikt
	def on_diving_sub_state_leave(old_sub_state)
		case old_sub_state
		when :down_from_surface, :up_to_surface
			@screen_y_offset = 0
			@screen_y_offset_fading_counter = -1
			@blank_depth = 0
		when :sliding
			restore_speed(:sliding)
			add_passability(Passabilities::STAIR)
			@display_surf_dummy = false
		when :tall_grass
			@blank_depth = 0
		end
	end
	
	# Do the sub state's entering actions
	# @param new_sub_state [Symbol] name of the entering sub state
	# @author Leikt
	def on_diving_sub_state_enter(new_sub_state)
		case new_sub_state
		when :down_from_surface
			@diving_route = DIVING_DOWN_FROM_SURFACE
			@diving_tp_index = 0
			@sub_state_counter = 40
			$game_temp.common_event_id = 35
		when :up_to_surface
			@diving_route = DIVING_UP_TO_SURFACE
			@diving_tp_index = 1
			@sub_state_counter = 20
			$game_temp.common_event_id = 35
		when :down_from_under
			@diving_route = DIVING_DOWN_FROM_UNDER
			@diving_tp_index = 0
			@sub_state_counter = 20
			$game_temp.common_event_id = 35
		when :up_to_under
			@diving_route = DIVING_UP_TO_UNDER
			@diving_tp_index = 1
			@sub_state_counter = 20
			$game_temp.common_event_id = 35
		when :sliding
			change_speed(:sliding, 1)
			remove_passability(Passabilities::STAIR)
		when :tall_grass
			set_blank(:move_end, 16, true)
		end
	end
	

	def diving_ext_update
		classic_state_ext_update
	end

	def on_diving_state_ext_leave(old_ext)
		classic_on_state_ext_leave(old_ext)
	end

	def on_diving_state_ext_enter(new_ext)
		classic_on_state_ext_enter(new_ext)
	end
	
	# Do the action at the end of sliding
	# @return [Boolean] false if the movement process end is skipped
	# @author Leikt
	def diving_slide_end
		set_sub_state(:stopped)
		return true
	end
	
	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def diving_sliding_ledge(dir)
		return false
	end
	
	# Do move for the sliding passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def diving_sliding(dir)
		@direction_fixed = dir
		set_sub_state(:sliding)
		return true
	end

	# Do move for the surf transition passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def diving_surf_transition(dir)
		return false
	end

	# Do move for the cracked floor transition
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def diving_cracked_floor(front = true, force_tilemap_refresh = false)
		return classic_cracked_floor(front, force_tilemap_refresh)
	end

	# Check the action to do when A is pressed and no event is triggered
	def diving_check_event_trigger_there
		if system_tag_here?(TUnderWater)
			$game_temp.common_event_id = 29 #> Common event for diving
		end
	end

	# Push the particle bubbles and set the timer before next one
	def push_bubbles
		if @sub_state_counter <= 0
			a=rand(100)
			@sub_state_counter =  10 + (a>90 ? 0 : a>70 ? 10 : a>50 ? 20 : 40)
			force_particle_push(:bubble)
		end
	end

	def diving_grass(dir)
		return true
	end
	# Do move for the tall grass passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def diving_tall_grass(dir)
		case @sub_state
		when :move, :stopped
			set_sub_state(:tall_grass)
			return true
		when :tall_grass
			return true
		end
		return false
	end
	
	def check_diving_coherence
		case @sub_state
		when :stopped, :move
			if @z<=1
				if system_tag_here?(TTallGrass)
					feet_tall_grass(@direction)
				elsif @state_ext != :grass and system_tag_here?(TGrass) 
					set_state_ext(:grass)
				end
			end
		end
	end
	def diving_swamp(dir)
		return false
	end
end