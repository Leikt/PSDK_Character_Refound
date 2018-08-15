class Game_Player
	# Dictionnary of the character name suffix depending of the states and sub states
	# Exemple : a character image will be used by the cross bike in wheeling if it end by "_cycle_wheel"
	# !!! Be careful modifying this !!!
	CHARA_BY_STATE[:surf] = {
		# :stopped => '_surf', :move => '_surf', :get_out => '_walk', :get_in => '_walk',
		# :waterfall => '_surf', :sliding => '_surf'
		:stopped => '_surf', :move => '_surf', :get_out => '_walk', :get_in => '_walk',
		:waterfall => '_surf', :sliding => '_surf'
	}
	# List of the particle can't be emitted by the current state
	PARTICLE_VETO[:surf] = [:dust]

	SURF_FLOATING_PEAK = 20
	SURF_FLOATING_PEAK_POND = 10
	SURF_FLOATING_STEP = 0.25
	SURF_FLOATING_STEP_POND = 0.10

	SURF_DUMMY_EVENT = RPG::Event.new(-10,-10)
	SURF_DUMMY_EVENT.pages[0].graphic.character_name = SURF_DUMMY
	SURF_DUMMY_EVENT.pages[0].through = true

	def can_surf_here?
		return (@z<=1 and !@surfing and $game_map.one_of_system_tags_here?(@front_x, @front_y, SurfTags) and @slope_height == 0)
	end

	def enter_surf
		return false if @state == :surf or !state_leavable?
		$game_switches[::Yuki::Sw::FM_WasEnabled] = $game_switches[::Yuki::Sw::FM_Enabled]
		$game_switches[::Yuki::Sw::FM_Enabled] = false
		$game_system.bgm_memorize
		$game_system.bgs_memorize
		set_states(new_state: :surf, new_sub_state: :get_in)
		return true
	end

	def leave_surf
		return false if @state != :surf or !state_leavable?
		$game_switches[::Yuki::Sw::FM_Enabled] = $game_switches[::Yuki::Sw::FM_WasEnabled]
		$game_variables[43] = $game_variables[43]-1
		$game_system.bgm_restore
		$game_system.bgs_restore
		set_sub_state(:get_out)
		# set_states(new_state: :feet, new_sub_state: :walk)
		return true
	end

	def enter_waterfall
		move_forward(true)
		Audio.se_play(WATERFALL_AUDIO_FILE, 150)
		set_sub_state(:waterfall)
	end

	# Reset the state
	# @author Leikt
	def surf_reset
		set_sub_state(:stopped)
	end
	
	# Reset the sub state
	# @author Leikt
	def surf_sub_reset
	end
	
	# Test if the state is leavable
	# @return [Boolean]
	# @author Leikt
	def is_surf_state_leavable?
		return (@sub_state==:stopped or @sub_state==:move)
	end
	
	# Do actions when the machine leave the state
	# @author Leikt
	def on_surf_state_leave
		@surfing = false
		@float_peak=0
		@float_height=0
		@no_shadow = !$game_switches[Yuki::Sw::CharaShadow]
		$scene.spriteset.init_player
	end
	
	# Do actions when the machine enter the state
	# @author Leikt
	def on_surf_state_enter
		@surfing = true
		$game_temp.common_event_id=9
	end
	
	# Do actions before every mouvements including forced move route, or waiting
	# @return [Boolean] true if the normal mouvement can be done, false if not
	# @author Leikt 
	def surf_premove
		case @sub_state
		when :waterfall
			if movable?
				if !system_tag_here?(WaterFall)
					end_slide_route
					return false
				end
				if @move_route != @sliding_route
					set_sliding_route(@sliding_route, false)
				end
			end
			if Audio.was_sound_previously_playing?(WATERFALL_AUDIO_FILE, WATERFALL_AUDIO_FILE, nil, nil)
				Audio.se_play(WATERFALL_AUDIO_FILE, 150)
			end
		when :move
			if movable?
				if system_tag_here?(TSea)
					if @float_peak != SURF_FLOATING_PEAK
						@float_peak=SURF_FLOATING_PEAK
						@float_step=SURF_FLOATING_STEP
					end
				elsif @float_peak != SURF_FLOATING_PEAK_POND
					@float_peak=SURF_FLOATING_PEAK_POND
					@float_step=SURF_FLOATING_STEP_POND
				end
			end
		when :sliding
			return classic_sliding_premove
		end
		return true
	end
	
	# Do actions right before normal mouvement (Input from player).
	# @return [Boolean] true if the Input mouvement can be done, false if not
	# @author Leikt
	def surf_update
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
			if movable? and @dir4 == 0
				set_sub_state(:stopped)
			end
		when :get_in, :get_out, :waterfall, :sliding
			return false
		end
		classic_moves_check						# Do classic mouvement
		return true
	end
	
	# Do actions right after all the moves
	# @return [Boolean]
	# @author Leikt
	def surf_postmove
		return true
	end
	
	# Do the sub state's leaving actions
	# @param old_sub_state [Symbol] name of the leaving sub state
	# @author Leikt
	def on_surf_sub_state_leave(old_sub_state)
		case old_sub_state
		when :stopped
			@anime_coef = 1
		when :move
			restore_speed(:surf)
			@anime_coef = 1
		when :waterfall
			restore_speed(:waterfall)
		when :sliding
			restore_speed(:sliding)
			add_passability(Passabilities::STAIR)
		when :get_in
			$game_map.delete_event(@surf_dummy)
			@surf_dummy = nil
			@no_shadow = true
		when :get_out
			@surf_dummy = nil
		end
	end
	
	# Do the sub state's entering actions
	# @param new_sub_state [Symbol] name of the entering sub state
	# @author Leikt
	def on_surf_sub_state_enter(new_sub_state)
		case new_sub_state
		when :default
			set_sub_state(:stopped)
		when :stopped
			@anime_coef = 2
		when :move
			change_speed(:surf, 1)
			@anime_coef = 2
		when :get_in
			dx = @direction == 4 ? -1 : @direction == 6 ? 1 : 0
			dy = @direction == 8 ? -1 : @direction == 2 ? 1 : 0
			if (@direction==4 and system_tag_here?(StairsR)) or
					(@direction==6 and system_tag_here?(StairsL))
				dy+=1
			end
			create_surf_dummy
			# @surf_dummy.moveto(@x + dx, @y + dy)
			@surf_dummy.opacity = 0
			@surf_dummy.fade_opacity(255,15)
			@surf_dummy.jump(dx, dy, false, 7, true)
			route = MRB.new
			route.set_skip_state_update(true)
				.wait(15)
				.enable_direction_fix
				.jump(dx, dy, false, 8.5, true)
				.disable_direction_fix
				.set_sub_state(:stopped)
				.set_skip_state_update(false)
				.check_sliding_tags
				.check_state_coherence
			force_move_route(route, :special_add, true)
			@blank_depth = 0
		when :get_out
			dx = @direction == 4 ? -1 : @direction == 6 ? 1 : 0
			dy = @direction == 8 ? -1 : @direction == 2 ? 1 : 0
			if (@direction==4 and $game_map.system_tag_here?(@front_x, @front_y, StairsL)) or
					(@direction==6 and $game_map.system_tag_here?(@front_x, @front_y, StairsR))
				dy-=1
			end
			create_surf_dummy
			@surf_dummy.force_move_route(MRB.new.wait(5).fade_opacity(0,15).wait(15).delete_this_event)
			route = MRB.new
			route.set_skip_state_update(true)
				.enable_direction_fix
				.jump(dx, dy, false, 8.5, true)
				.disable_direction_fix
				.set_skip_state_update(false)
				.set_states(:feet, :walk)
				.check_cracked_floor(false, true)
				.check_sliding_tags
				.check_state_coherence
			force_move_route(route, :special_add, true)
		when :waterfall
			change_speed(:waterfall, -1)
			if @direction == 8
				@sliding_route = MRB.new.move_up
			else
				@sliding_route = MRB.new.move_down
			end
		when :sliding
			change_speed(:sliding, 1)
			remove_passability(Passabilities::STAIR)
		end
	end
	
	def surf_ext_update
		classic_state_ext_update
	end

	def on_surf_state_ext_leave(old_ext)
		classic_on_state_ext_leave(old_ext)
	end

	def on_surf_state_ext_enter(new_ext)
		classic_on_state_ext_enter(new_ext)
	end
	
	# Do the action at the end of sliding
	# @return [Boolean] false if the movement process end is skipped
	# @author Leikt
	def surf_slide_end
		set_sub_state(:stopped)
		return true
	end
	
	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def surf_sliding_ledge(dir)
		return false
	end

	def surf_sliding(dir)
		@direction_fixed = dir
		set_sub_state(:sliding)
		return true
	end

	def surf_surf_transition(dir)
		$game_temp.common_event_id = 10
		return false
	end

	def move_waterfall(dir)
		if sliding? or system_tag_here?(WaterFall)
			return true
		end
		# set_sub_state(:waterfall)
		$game_temp.common_event_id = 26
		return false
	end

	def create_surf_dummy
		@surf_dummy = Game_Event.new($game_map.map_id, SURF_DUMMY_EVENT)
		@surf_dummy.direction = @direction
		@surf_dummy.z = 0
		@surf_dummy.always_on_bottom = true
		@surf_dummy.no_shadow = true
		@surf_dummy.direction_fix = true
		@surf_dummy.moveto(@x, @y)
		$game_map.add_event(@surf_dummy)
	end
	
	# Do move for the cracked floor transition
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def surf_cracked_floor(front = true, force_tilemap_refresh = false)
		return classic_cracked_floor(front, force_tilemap_refresh)
	end

	# Check the action to do when A is pressed and no event is triggered
	def surf_check_event_trigger_there
		if system_tag_here?(TUnderWater)
			$game_temp.common_event_id = 29 #> Common event for diving
		elsif $game_map.passable?(@x, @y, @direction, nil) and @z <= 1
			if $game_map.system_tag_here?(@front_x, @front_y, WaterFall)
				$game_temp.common_event_id = 26 					#> Common event for waterfall
			end
		end
	end

	def surf_grass(dir)
		return classic_move_grass(dir)
	end

	def check_surf_coherence
	end
	
	def surf_tall_grass(dir)
		return false
	end
	def surf_swamp(dir)
		return false
	end
end