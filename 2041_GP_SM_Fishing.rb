class Game_Player
	# Dictionnary of the character name suffix depending of the states and sub states
	# Exemple : a character image will be used by the cross bike in wheeling if it end by "_cycle_wheel"
	# !!! Be careful modifying this !!!
	CHARA_BY_STATE[:fishing] = {
		:start => '_fish', :waiting => '_fish', :bite => '_fish', :finish => '_fish',
		:surf_start => '_surf_fish', :surf_waiting => '_surf_fish', :surf_bite => '_surf_fish', :surf_finish => '_surf_fish'

	}
	FISHING_SURF_Y_OFFSET = 0
	FISHING_FLOOR_Y_OFFSET = 8
	FISHING_TRANSITION_DURATION = 25
	FISHING_WAITING_DELAY = 60
	FISHING_WAITING_MIN = 4
	FISHING_WAITING_RND = 5
	FISHING_BITE_DELAY = 120

	def fishing?
		return @state==:fishing
	end

	def enter_fishing(type)
		if @state==:speed_bike
			speed_bike_off
		elsif @state==:cross_bike
			cross_bike_off
		end
		@fishing_rod_type = type
		@was_surfing = surfing?
		set_state(:fishing)
	end

	# Reset the state
	# @author Leikt
	def fishing_reset
		set_sub_state(@was_surfing ? :surf_start : :start)
	end
	
	# Reset the sub state
	# @author Leikt
	def fishing_sub_reset
	end
	
	# Test if the state is leavable
	# @return [Boolean]
	# @author Leikt
	def is_fishing_state_leavable?
		return true
	end
	
	# Do actions when the machine leave the state
	# @author Leikt
	def on_fishing_state_leave
		@screen_y_offset = 0
		@no_shadow = @current_no_shadow
	end
	
	# Do actions when the machine enter the state
	# @author Leikt
	def on_fishing_state_enter
		if @was_surfing
			@screen_y_offset = FISHING_SURF_Y_OFFSET
			if system_tag_here?(TSea)
				@float_peak=SURF_FLOATING_PEAK
				@float_step=SURF_FLOATING_STEP
			else
				@float_peak=SURF_FLOATING_PEAK_POND
				@float_step=SURF_FLOATING_STEP_POND
			end
			@current_no_shadow = @no_shadow
			@no_shadow = true
		else
			@screen_y_offset = FISHING_FLOOR_Y_OFFSET
		end
		set_sub_state(@was_surfing ? :surf_start : :start)
	end
	
	# Do actions before every mouvements including forced move route, or waiting
	# @return [Boolean] true if the normal mouvement can be done, false if not
	# @author Leikt 
	def fishing_premove
		case @sub_state
		when :start, :finish, :surf_start, :surf_finish
			return false
		end
		return true
	end
	
	# Do actions for the fishing state
	# @return [Boolean] true if the Input mouvement can be done, false if not
	# @author Leikt
	def fishing_update
		case @sub_state
		when :waiting, :surf_waiting
			if @pressed_B or @pressed_A
				@fishing_end = :cancel
				set_sub_state(@was_surfing ? :surf_finish : :finish)
			end
			if @sub_state_counter <= 0
				@fishing_counter += 1
				if @fishing_counter == @fishing_bite_count
					set_sub_state(@was_surfing ? :surf_bite : :bite)
				elsif (@fishing_counter % 4 > 0 and @fishing_counter > @fishing_counter_end)
					set_sub_state(@was_surfing ? :surf_finish : :finish)
					return
				else
					@sub_state_counter = FISHING_WAITING_DELAY
					case (@fishing_counter%3)
					when 0;	force_particle_push(:waiting_1)
					when 1;	force_particle_push(:waiting_2)
					when 2;	force_particle_push(:waiting_3)
					end
				end
			end
		when :bite, :surf_bite
			if @sub_state_counter % 25 == 0
				@pattern = 2
			elsif @sub_state_counter % 15 == 0
				@pattern = 3
			end
			if @pressed_A
				@fishing_end = :battle
				set_sub_state(@was_surfing ? :surf_finish : :finish)
			end
			if @sub_state_counter <= 0
				@fishing_end = :too_late
				set_sub_state(@was_surfing ? :surf_finish : :finish)
			end
		end
		return false
	end
	
	# Do actions right after all the moves
	# @return [Boolean]
	# @author Leikt
	def fishing_postmove
		return true
	end
	
	# Do the sub state's leaving actions
	# @param old_sub_state [Symbol] name of the leaving sub state
	# @author Leikt
	def on_fishing_sub_state_leave(old_sub_state)
		case old_sub_state
		when :finish, :surf_finish
			@direction_fix = false
			case @fishing_end
			when :cancel
				$scene.display_message('\t[39,9]')
			when :unlucky
				$scene.display_message('\t[39,12]')
			when :nothing
				$scene.display_message('\t[39,11]')
			when :too_late
				$scene.display_message('\t[39,10]')
			when :battle
				$wild_battle.any_fish?(@fishing_rod_type, true)
				$game_temp.common_event_id = 1
			end
		end
	end
	
	# Do the sub state's entering actions
	# @param new_sub_state [Symbol] name of the entering sub state
	# @author Leikt
	def on_fishing_sub_state_enter(new_sub_state)
		case new_sub_state
		when :start, :surf_start
			animate_from_charset([@direction/2 - 1], FISHING_TRANSITION_DURATION, 
					end_command: MRB.command(MRB::SET_SUB_STATE, @was_surfing ? :surf_waiting : :waiting))
		when :waiting, :surf_waiting
			if $wild_battle.any_fish?(@fishing_rod_type)
				if $wild_battle.check_fishing_chances(@fishing_rod_type)
					@fishing_bite_count = (FISHING_WAITING_MIN + rand(FISHING_WAITING_RND))
				else
					@fishing_bite_count = -1
					@fishing_end = :unlucky
				end
			else
				@fishing_bite_count = -1
				@fishing_end = :nothing
			end
			if (@fishing_bite_count > 0)
				@fishing_counter_end = @fishing_bite_count+1
			else 
				@fishing_counter_end = (FISHING_WAITING_MIN + rand(FISHING_WAITING_RND))
			end
			@sub_state_counter = FISHING_WAITING_DELAY
			@fishing_counter = -1
			update_appearence(3)
		when :finish
			update_appearence(3)																	# Force the start pattern to wheeling appearence
			animate_from_charset([@direction/2 - 1], FISHING_TRANSITION_DURATION, reversed: true, 
					end_command: MRB.command(MRB::SET_STATE, :feet))
		when :surf_finish
			update_appearence(3)																	# Force the start pattern to wheeling appearence
			animate_from_charset([@direction/2 - 1], FISHING_TRANSITION_DURATION, reversed: true, 
					end_command: MRB.command(MRB::SET_STATES, :surf, :stopped))
		when :bite, :surf_bite
			update_appearence(3)
			@sub_state_counter = FISHING_BITE_DELAY
			force_particle_push(:exclamation, 1)
		end
	end
	

	def fishing_ext_update
		classic_state_ext_update
	end

	def on_fishing_state_ext_leave(old_ext)
		classic_on_state_ext_leave(old_ext)
	end

	def on_fishing_state_ext_enter(new_ext)
		classic_on_state_ext_enter(new_ext)
	end

	# Do the action at the end of sliding
	# @return [Boolean] false if the movement process end is skipped
	# @author Leikt
	def fishing_slide_end
		set_sub_state(@was_surfing ? :surf_waiting : :waiting)
		return true
	end
	
	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def fishing_sliding_ledge(dir)
		return false
	end
	
	# Do move for the sliding passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def fishing_sliding(dir)
		return false
	end

	# Do move for the surf transition passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def fishing_surf_transition(dir)
		return false
	end

	# Do move for the cracked floor transition
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def fishing_cracked_floor(front = true, force_tilemap_refresh = false)
		return classic_cracked_floor(front, force_tilemap_refresh)
	end
	
	def fishing_grass(dir)
		return classic_move_grass(dir)
	end

	def fishing_tall_grass(dir)
		return false
	end
	def fishing_swamp(dir)
		return false
	end
end