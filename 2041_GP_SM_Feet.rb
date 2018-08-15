
class Game_Character
	# Dictionnary of the character name suffix depending of the states and sub states
	# Exemple : a character image will be used by the cross bike in wheeling if it end by "_cycle_wheel"
	# !!! Be careful modifying this !!!
	CHARA_BY_STATE[:feet] = {:walk => '_walk', :run => '_run', :deep_swamp => '_deep_swamp_sinking',
							:swamp_walk => '_swamp', :swamp_run => '_swamp_run', :swamp_sinking => '_swamp_sinking',
							:deep_swamp_sinking => '_deep_swamp_sinking', :swamp_out => '_swamp_sinking', 
							:sliding => '_walk', :sliding_ledge => '_walk', :tall_grass => '_walk'}
							
	SWAMP_ANIMATION_DURATION = 30
	SWAMP_ANIMATION_COOLDOWN = 5
	SWAMP_RESWAMP_DELAY = 120
	SWAMP_RUN_COUNT = 5
	
	# Reset the state
	# @author Leikt
	def feet_reset
		set_sub_state(:walk)
	end
	
	# Reset the sub state
	# @author Leikt
	def feet_sub_reset
	end
	
	# Test if the state is leavable
	# @return [Boolean]
	# @author Leikt
	def is_feet_state_leavable?
		return (@sub_state==:walk or @sub_state==:run)
	end
	
	# Do actions when the machine leave the state
	# @author Leikt
	def on_feet_state_leave
	end
	
	# Do actions when the machine enter the state
	# @author Leikt
	def on_feet_state_enter
		set_sub_state(:walk)
	end
	
	# Do actions before every mouvements including forced move route, or waiting
	# @return [Boolean] true if the normal mouvement can be done, false if not
	# @author Leikt 
	def feet_premove
		check_feet_coherence
		case @sub_state
		when :tall_grass
			if !system_tag_here?(TTallGrass)
				set_sub_state(:walk)
			end
		when :swamp_walk
			if !one_of_system_tags_here?(SwampsTags)
				set_sub_state(:walk)
			end
		when :swamp_run
			if !one_of_system_tags_here?(SwampsTags)
				set_sub_state(:run)
			end
		when :sliding
			if @z<=1 and system_tag_here?(Hole)
				end_slide_route
				feet_cracked_floor(false, true)
				return false
			end
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
	def feet_update
		case @sub_state
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WALK
		when :walk
			if @dir4 != 0 and movable?
				if just_turn_detect									# Turn if the player input direction less than 10 fps
					@direction = @dir4
					return false									# The character can't move (it's just turning)
				else
					course_state = feet_state_running				# Calcul if the player is running
					if course_state > 0
						set_sub_state(:run)							# Player running : set the running sub state
					end
				end
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RUN
		when :run
			course_state = feet_state_running					# Check if the player still running
			if course_state < 0
				set_sub_state(:walk)							# Player not running : start walking
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TALL GRASS
		when :tall_grass
			if @dir4 != 0 and movable?
				if just_turn_detect									# Turn if the player input direction less than 10 fps
					@direction = @dir4
					return false
				end
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SWAMP & DEEP SWAMP
		when :deep_swamp
			if @dir4 != 0 and movable?
				if just_turn_detect									# Turn if the player input direction less than 10 fps
					if @direction != @dir4
						@swamp_move_count -= 1
						if @swamp_move_count <= 0
							@skip_state_update = true
							animate_from_charset([@dir4/2 -1], SWAMP_ANIMATION_DURATION, 
							force_wait: true,
							end_command: [
								MRB.command(MRB::SET_SUB_STATE, :swamp_walk),
								MRB.command(MRB::RESET_CHARA_PATTERN),
								MRB.command(MRB::WAIT, SWAMP_ANIMATION_COOLDOWN),
								MRB.command(MRB::SET_SKIP_STATE_UPDATE, false)
							])
						end
					end
					@direction = @dir4
					return false
				end
			end
			return false
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SWAMP WALK
		when :swamp_walk
			if @sub_state_counter <= 0 and system_tag_here?(DeepSwamp)
				set_sub_state(:deep_swamp_sinking)
			elsif @dir4 != 0 and movable? and just_turn_detect
				# if just_turn_detect									# Turn if the player input direction less than 10 fps
					@direction = @dir4
					return false
				# end
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> SWAMP RUN
		when :swamp_run
			if movable?
				@swamp_run_count -= 1
				if @swamp_run_count <= 0
					set_sub_state(:swamp_sinking)
					front_deep = $game_map.system_tag_here?(@front_x, @front_y, DeepSwamp)
					deep = system_tag_here?(DeepSwamp)
					front_border = $game_map.system_tag_here?(@front_x, @front_y, SwampBorder)
					border = system_tag_here?(SwampBorder)
					move_forward if front_deep and deep or front_border and border or border and front_deep
					return false
				end
			end
			course_state = feet_state_running						# Check if the player still running
			if course_state < 0
				set_sub_state(:swamp_sinking)						# Player not running : start walking
			end
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> BLOCKER STATE
		when :swamp_sinking, :deep_swamp_sinking, :swamp_out, :sliding, :sliding_ledge
			return false
		end
		classic_moves_check
		return true													# Classic mouvement always possible
	end
	
	# Do actions right after all the moves
	# @return [Boolean]
	# @author Leikt
	def feet_postmove
		return true
	end
	
	# Do the sub state's leaving actions
	# @param old_sub_state [Symbol] name of the leaving sub state
	# @author Leikt
	def on_feet_sub_state_leave(old_sub_state)
		case old_sub_state
		when :walk, :swamp_walk
			remove_passability(Passabilities::TALL_GRASS)
		when :run
			remove_passability(Passabilities::TALL_GRASS)
			$game_switches[::Yuki::Sw::EV_Run] = false	# Retro compatibility switch
			restore_speed(:run)							# Delete the speed modification from running
		when :tall_grass
			@no_shadow = !$game_switches[Yuki::Sw::CharaShadow]
			@blank_depth = 0
			remove_passability(Passabilities::TALL_GRASS)
		when :swamp_walk
			remove_passability(Passabilities::TALL_GRASS)
			@step_anime = false
			@swamp_move_count = nil
		when :swamp_run
			$game_switches[::Yuki::Sw::EV_Run] = false	# Retro compatibility switch
			restore_speed(:swamp_run)					# Delete the speed modification from running
		when :sliding, :sliding_ledge
			restore_speed(:sliding)
			add_passability(Passabilities::STAIR)
			add_passability(Passabilities::SLIDING_LEDGE)
			@walk_anime = true
		end
	end
	
	# Do the sub state's entering actions
	# @param new_sub_state [Symbol] name of the entering sub state
	# @author Leikt
	def on_feet_sub_state_enter(new_sub_state)
		case new_sub_state
		when :default
			set_sub_state(:walk)
		when :walk
			add_passability(Passabilities::TALL_GRASS)
		when :run
			add_passability(Passabilities::TALL_GRASS)
			$game_switches[::Yuki::Sw::EV_Run] = true		# Retro compatibility switch
			change_speed(:run, 1)						# Increase the speed (we are running here !)
		when :tall_grass
			set_blank(:move_end, 16, true)
			add_passability(Passabilities::TALL_GRASS)
		when :deep_swamp
			@swamp_move_count = rand(2)+4
		when :swamp_sinking
			end_command = (system_tag_here?(DeepSwamp) ? 
				[MRB.command(MRB::SET_SUB_STATE, :deep_swamp_sinking),
				MRB.command(MRB::WAIT, SWAMP_ANIMATION_COOLDOWN)] :
				MRB.command(MRB::SET_SUB_STATE, :swamp_walk)
				)
			@step_anime = false
			update_appearence(3)
			animate_from_charset([@direction/2 - 1], SWAMP_ANIMATION_DURATION, 
			reversed: true,
			end_command: end_command
			)
		when :deep_swamp_sinking
			@step_anime = false
			update_appearence(3)
			animate_from_charset([@direction/2 -1], SWAMP_ANIMATION_DURATION, 
			reversed: true,
			end_command: [
				MRB.command(MRB::SET_SUB_STATE, :deep_swamp),
				MRB.command(MRB::WAIT, SWAMP_ANIMATION_COOLDOWN)
				]
			)
		when :swamp_out
			@step_anime = false
			update_appearence(3)
			animate_from_charset([@direction/2 -1], SWAMP_ANIMATION_DURATION, 
			reversed: true,
			end_command: [
				MRB.command(MRB::SET_SUB_STATE, :walk),
				MRB.command(MRB::WAIT, SWAMP_ANIMATION_COOLDOWN),
				MRB.command(MRB::MOVE_FORWARD)
				]
			)
		when :swamp_walk
			add_passability(Passabilities::TALL_GRASS)
			@sub_state_counter = SWAMP_RESWAMP_DELAY
		when :swamp_run
			@swamp_run_count = SWAMP_RUN_COUNT
			$game_switches[::Yuki::Sw::EV_Run] = true		# Retro compatibility switch
			change_speed(:swamp_run, 1)						# Increase the speed (we are running here !)
		when :sliding
			change_speed(:sliding, 1)
			@sliding_spin = false 
			@walk_anime = false
			remove_passability(Passabilities::STAIR)
			remove_passability(Passabilities::SLIDING_LEDGE)
		when :sliding_ledge
			@walk_anime = false
			@sliding_route = SLIDING_LEDGE_GO_DOWN_ROUTE
		end
	end

	def feet_ext_update
		classic_state_ext_update
	end

	def on_feet_state_ext_leave(old_ext)
		classic_on_state_ext_leave(old_ext)
	end

	def on_feet_state_ext_enter(new_ext)
		classic_on_state_ext_enter(new_ext)
	end
	
	# Test if the player is running or not
	# @return [Integer] -1 : walking, 0 :still_running/walking, 1 : start_running
	# @author Leikt
	def feet_state_running
		return 0 unless movable?
		case @sub_state
		when :walk										# if the player is walking
			if ($game_switches[::Yuki::Sw::EV_CanRun] and # and the player has the sport shoes
					@dir4 != 0 and						# and Player is pressing a direction
					@pressed_B							# and Player is pressing the run button 
					)						
				return 1								# Return start running
			end
		
		when :run, :swamp_run						# if the player is running
			if (@dir4 == 0 or						# or the player isn't pressing a direction
					!@pressed_B or					# or the player isn't pressing the run button
					$game_system.map_interpreter.	# or an event is triggered
						running?)
				return -1							# Return stop running
			end
		end
		return 0									# Return 'change nothing'
	end
	
	# Do move for the tall grass passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def feet_tall_grass(dir)
		case @sub_state
		when :walk, :deep_swamp, :swamp_walk, :run
			set_sub_state(:tall_grass)
			return true
		when :tall_grass
			return true
		end
		return false
	end

	def feet_grass(dir)
		return classic_move_grass(dir)
	end
	
	# Do move for the swamp passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def feet_swamp(dir)
		case @sub_state
		when :walk, :tall_grass
			nx = @x + (dir == 4 ? -1 : dir == 6 ? 1 : 0)
			ny = @y + (dir == 8 ? -1 : dir == 2 ? 1 : 0)
			if $game_map.one_of_system_tags_here?(nx, ny, SwampsTags)
				set_states_at_move_end(new_sub_state: :swamp_sinking)
			end
		when :run
			set_sub_state(:swamp_run)
		when :swamp_walk
			nx = @x + (dir == 4 ? -1 : dir == 6 ? 1 : 0)
			ny = @y + (dir == 8 ? -1 : dir == 2 ? 1 : 0)
			if $game_map.system_tag_here?(nx, ny, DeepSwamp)
				set_sub_state(:deep_swamp_sinking)
			elsif !$game_map.system_tag_here?(nx, ny, SwampBorder)
				set_sub_state(:swamp_out)
				return false
			end
		end
		return true
	end
	
	# Do the action at the end of sliding
	# @return [Boolean] false if the movement process end is skipped
	# @author Leikt
	def feet_slide_end
		set_sub_state(:walk)
		return true
	end

	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def feet_sliding_ledge(dir)
		dir @direction_fixed if sliding?
		case dir
		when 8
			set_sliding_route(SLIDING_LEDGE_BLOCK_ROUTE)
			return false
		when 2
			set_sub_state(:sliding_ledge)
			return true
		end
		return false
	end
	# Do move for the sliding passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def feet_sliding(dir)
		@direction_fixed = dir
		set_sub_state(:sliding)
		return true
	end
	# Do move for the surf transition passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def feet_surf_transition(dir)
		unless $game_switches[::Yuki::Sw::NoSurfContact]
			$game_temp.common_event_id=9
		end
		return false
	end
	# Do move for the cracked floor transition
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def feet_cracked_floor(front = true, force_tilemap_refresh = false)
		return classic_cracked_floor(front, force_tilemap_refresh)
	end
	# Check the action to do when A is pressed and no event is triggered
	def feet_check_event_trigger_there
		if $game_map.system_tag_here?(@front_x, @front_y, HeadButt)
			$game_temp.common_event_id = 20	#> Common event for headbutt
		elsif $game_map.passable?(@x, @y, @direction, nil) and @z <= 1 and can_surf_here?
			$game_temp.common_event_id = 9  #> Common event for surfing
		end
	end

	def check_feet_coherence
		case @sub_state
		when :walk, :run
			if @z<=1
				if one_of_system_tags_here?(SwampsTags)
					feet_swamp(@direction)
				elsif system_tag_here?(TTallGrass)
					feet_tall_grass(@direction)
				elsif @state_ext != :grass and system_tag_here?(TGrass) 
					set_state_ext(:grass)
				end
			end
		when :swamp_walk, :swamp_run, :deep_swamp, :swamp_sinking, :deep_swamp_sinking
			if @z<=1
				if @state_ext != :grass and system_tag_here?(TGrass) 
				set_state_ext(:grass)
				end
			end
		end
	end
end