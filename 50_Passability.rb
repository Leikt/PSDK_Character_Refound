class Game_Character
									
	#============================
	# >>> PASSABILITY ATTRIBUTES
	0
	# Can the character can pass through everything ?
	# @return [Boolean] true if it can
	def through
		return (@passability & Passabilities::THROUGH > 0)
	end
	# Set the character passing through everythin or not
	# @param v [Boolean] true if it can
	def through=(v)
		if v
			set_through
		else
			reset_through
		end
	end
	# Set the character able to pass through everything
	def set_through
		@passability |= Passabilities::THROUGH
	end
	# Set the character with its normal collision
	def reset_through
		@passability &= ~Passabilities::THROUGH
	end
	# Can the character can pass through events ?
	# @return [Boolean] true if it can
	def through_events
		return (@passability & Passabilities::THROUGH_EVENTS > 0)
	end
	# Set the character able to pass through events
	def set_through_events
		@passability |= Passabilities::THROUGH_EVENTS
	end
	# Set the character with its normal collision
	def reset_through_events
		@passability &= ~Passabilities::THROUGH_EVENTS
	end
	# Character has the given passability ?
	# @param passability [Integer] the passability to test
	# @return [Boolean] true if the character has the passability
	def has_passabiity?(passability)
		return (@passability | passability > 0)
	end
	# Add the given passability to the character
	# @param passability [Integer] the passability
	def add_passability(passability)
		@passability |= (passability & @passability_capacity)
	end
	# Remove the given passability from the character
	# @param passability [Integer] the passability
	def remove_passability(passability)
		@passability &= ~passability
	end
	# Add the given ability of passability
	# @param passability [Integer]
	def add_passability_ability(passability)
		@passability_capacity |= passability
		add_passability(passability)
	end
	# Remove the capacity of passability of the character
	# @param passability [Integer]
	def remove_passability_ability(passability)
		remove_passability(passability)
		@passability_capacity &= ~passability
	end
	# Initialize the passability
	def initialize_passability
		@passability = 0
		@passability_capacity = 0xffff_ffff
	end
	
	# is the tile in front of the character passable ?
	# @param x [Integer] x position on the Map
	# @param y [Integer] y position on the Map
	# @param d [Integer] direction : 2, 4, 6, 8, 0. 0 = current position
	# @param skip_event [Boolean] if the function does not check events
	# @return [Boolean] if the front/current tile is passable
	def passable?(x, y, dir, skip_event=false)
		return (((res=can_move?(x, y, dir, skip_event)) == 0) ? special_move_check(x, y, dir, skip_event) : (res > 0))
	end
	# Test if the mouvement is possible
	# @param x [Integer] the coords of the start
	# @param y [Integer] the coords of the start
	# @param dir [Integer] direction of the movement
	# @param skip_event [Boolean, false] true if the event will not be tested
	# @return [Boolean] true mouvement can be done
	def can_move?(x, y, dir, skip_event = false, force_event_collision = false)
		nx = x + (dir == 4 ? -1 : (dir == 6 ? 1 : 0))
		ny = y + (dir == 8 ? -1 : (dir == 2 ? 1 : 0))
		unless (game_map=$game_map).valid?(nx, ny)
			return -1
		end
		return 1 if $DEBUG and Input::Keyboard.press?(Input::Keyboard::LControl)
		
		@map_data = map_data = game_map.passabilities.compare(@passability, x, y, @z, dir)
		if map_data == 0
			return -1
		end
		
		# Through
		if map_data & Passabilities::THROUGH > 0
			return 1
		end
		
		unless !force_event_collision and (skip_event or (@map_data & SPECIAL_EVENTS_CHECK > 0))
			res = check_events_collision(nx, ny, @z, dir, game_map)
			return res if res <= 0
		end 
		return ((map_data & SPECIAL_MOVE_PASSABILITIES) > 0 ? 0 : 1)
	end
	# Check if there is a collision with a event
	# @param nx [Integer] new x coordinate
	# @param ny [Integer] new y coordinate
	# @param z [Integer] new z coordinate
	# @param dir [Integer] tested direction
	# @param game_map [Game_Map] the current game_map
	# @return [Integer] -1 there is a collision, 1 ther is not
	def check_events_collision(nx, ny, z, dir, game_map)
		game_player = $game_player
		for event in game_map.events_list
			if event.contact?(nx, ny, z)
				unless (event.through or event.through_events)
					if self != game_player
						return -1
					end
					if event != self and event.tile_id >= 0
						if (passage=game_map.passages[event.tile_id]) & ((1 << (dir / 2 - 1)) & 0x0f) != 0
							return -1
						elsif passage & 0x0f == 0x0f
							return -1
						elsif game_map.priorities[event.tile_id] == 0
							return -1
						end
					end
					unless event.character_name.empty?
						return -1
					end
				end
			end
		end
		
		if game_player.contact?(nx, ny, z)
			unless (game_player.through or game_player.through_events)
				unless @character_name.empty?
					return -1
				end
			end
		end
		
		unless Yuki::FollowMe.is_player_follower?(self) or self==game_player
			Yuki::FollowMe.each_follower do |event|
				if event.contact?(nx, ny, z)
					return -1
				end
			end
		end
		return 1
	end
	# Check and apply the special move if there is one
	# @param x [Integer] the x coord
	# @param y [Integer] the y coord
	# @param dir [Integer] the tested dir
	# @param skip_event [Boolean, false] skip the event test
	# @return [Boolean] true if the normal mouvement can be done, false if not
	def special_move_check(x, y, dir, skip_event=false)
		map_data = @map_data
		# Ledge
		return jump_ledge(x, y, dir, skip_event) 	if (map_data & Passabilities::LEDGE > 0)
		# Slope
		return move_slope(dir) 						if (map_data & Passabilities::SLOPE > 0)
		# SlidingLedge
		return move_sliding_ledge(dir) 				if (map_data & Passabilities::SLIDING_LEDGE > 0)
		# Cross bike balance
		return cross_bike_straight(dir) 			if (map_data & Passabilities::CROSS_BIKE_STRAIGHT > 0)
		# Tall Grass
		return move_tall_grass(dir) 				if (map_data & Passabilities::TALL_GRASS > 0)
		# Swamp
		return move_swamp(dir) 						if (map_data & Passabilities::SWAMP > 0)
		# Sliding	
		return move_sliding(dir) 					if (map_data & Passabilities::SLIDING > 0)
		# Surf
		return move_surf_transition(dir)			if (map_data & Passabilities::SURF_TRANSITION > 0)
		# Waterfall
		return move_waterfall(dir)					if (map_data & Passabilities::WATERFALL > 0)
		# Stairs
		return move_stairs(dir) 					if (map_data & Passabilities::STAIR > 0)
		# Cracked floor
		return move_cracked_floor 					if (map_data & Passabilities::CRACKED_FLOOR > 0)
		# Grass
		return move_grass(dir)						if (map_data & Passabilities::GRASS > 0)
		# Unknown special move
		return false
	end
	# Jump over the ledge
	# @param x [Integer] the x coord
	# @param y [Integer] the y coord
	# @param dir [Integer] the tested dir
	# @param skip_event [Boolean] skip the event test
	# @return [Boolean] true if the normal mouvement can be done, false if not
	def jump_ledge(x, y, dir, skip_event)
		dx = (dir==4 ? -2 : (dir==6 ? 2 : 0))
		dy = (dir==8 ? -2 : (dir==2 ? 2 : 0))
		unless skip_event
			nnx = x + dx
			nny = y + dy
			return false if check_events_collision(nnx, nny, @z, dir, $game_map) < 0
		end
		route = MRB.new.disable_skippable
		route.set_skip_state_update(true)
		route.move_forward_direction_fixed(true) if @move_route_forcing # Prevent bug when not Player Control
		route.move_forward_direction_fixed(true)
			.play_se(RPG::AudioFile.new("jump", 100, 100))
			.jump(dx/2, dy/2, false, 8.5 + (dir == 2 ? 0.5 : 0))
			.particle_push(:dust, 1)
			.set_skip_state_update(false)
			.reset_sub_state
			.movement_process_end
			.check_cracked_floor(false, true)
			.check_sliding_tags
		force_move_route(route, :special_add, true, true)
		return false
	end
	# Check stair move
	# @param dir [Integer] the tested dir
	# @return [Boolean] true if the normal mouvement can be done, false if not
	def move_stairs(dir)
		front_stair_dir = StairsTags.index(@front_system_tag)		# Front tile stair dir : nil=no stairs, 0=stairD, 1=stairL, 2=stairR, 3=stairU
		stair_dir = StairsTags.index(@system_tag)					# Current tile stair dir : nil=no stairs, 0=stairD, 1=stairL, 2=stairR, 3=stairU
		case dir
		when 2
			return false if check_events_collision(@x, @y+1, @z, 2, $game_map) < 0
			if (front_stair_dir == 0 or front_stair_dir == 3)
				change_speed_for_this_move(:stair, -1)
				force_move_route(MRB.new.move_down(true, true).check_cracked_floor.check_sliding_tags, :special_add, @move_route_forcing, true)
				return false
			elsif stair_dir == 0
				force_move_route(MRB.new.move_down(true, true).check_cracked_floor.check_sliding_tags, :special_add, @move_route_forcing, true)
				return false
			end
		when 4
			if (stair_dir == 2)
				return false if check_events_collision(@x-1, @y+1, @z, 4, $game_map) < 0
				change_speed_for_this_move(:stair, -1)
				force_move_route(MRB.new.move_lower_left(true).check_cracked_floor(false, true).check_sliding_tags, :special_add, @move_route_forcing, true)
				return false
			end
			if (front_stair_dir == 1)
				return false if check_events_collision(@x-1, @y-1, @z, 4, $game_map) < 0
				change_speed_for_this_move(:stair, -1)
				force_move_route(MRB.new.move_upper_left(true).check_cracked_floor(false, true).check_sliding_tags, :special_add, @move_route_forcing, true)
				return false
			end
		when 6
			if (front_stair_dir == 2)
				return false if check_events_collision(@x+1, @y-1, @z, 6, $game_map) < 0
				change_speed_for_this_move(:stair, -1)
				force_move_route(MRB.new.move_upper_right(true).check_cracked_floor(false, true).check_sliding_tags, :special_add, @move_route_forcing, true)
				return false
			end
			if (stair_dir == 1)
				return false if check_events_collision(@x+1, @y+1, @z, 6, $game_map) < 0
				change_speed_for_this_move(:stair, -1)
				force_move_route(MRB.new.move_lower_right(true).check_cracked_floor(false, true).check_sliding_tags, :special_add, @move_route_forcing, true)
				return false
			end
		when 8
			return false if check_events_collision(@x, @y-1, @z, 8, $game_map) < 0
			if (front_stair_dir == 0 or stair_dir == 3)
				change_speed_for_this_move(:stair, -1)
				force_move_route(MRB.new.move_up(true, true).check_cracked_floor.check_sliding_tags, :special_add, @move_route_forcing, true)
				return false
			end
		end
		return true
	end
	# Check slope move. Use special event collision
	# @param dir [Integer] the tested dir
	# @return [Boolean] true if the normal mouvement can be done, false if not
	def move_slope(dir)
		if @system_tag == SlopeR and @front_system_tag != SlopeR and dir == 6
			return false if check_events_collision(@x+1, @y-1, @z, dir, $game_map) <= 0 
			set_coords(nil, @y-1)
			@old_slope = @current_slope = @slope_height = 0
			@real_y = @y * 128
			return true
		elsif @system_tag != SlopeR and @front_system_tag == SlopeR and dir == 4
			return false if check_events_collision(@x-1, @y+1, @z, dir, $game_map) <= 0
			set_coords(nil, @y+1)
			@current_slope = @old_slope = @slope_height = $game_map.passabilities.get_slope(@x-1, @y, @z)
			@real_y = @y * 128
			return true
		elsif @system_tag == SlopeL and @front_system_tag != SlopeL and dir == 4
			return false if check_events_collision(@x-1, @y-1, @z, dir, $game_map) <= 0 
			set_coords(nil, @y-1)
			@old_slope = @current_slope = @slope_height = 0
			@real_y = @y * 128
			return true
		elsif @system_tag != SlopeL and @front_system_tag == SlopeL and dir == 6
			return false if check_events_collision(@x+1, @y+1, @z, dir, $game_map) <= 0
			set_coords(nil, @y+1)
			@current_slope = @old_slope = @slope_height = $game_map.passabilities.get_slope(@x+1, @y, @z)
			@real_y = @y * 128
			return true
		end
		nx = @x + (dir == 4 ? -1 : dir == 6 ? 1 : 0)
		ny = @y + (dir == 8 ? -1 : dir == 2 ? 1 : 0)
		return check_events_collision(nx, ny, @z, dir, $game_map) > 0
	end
	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def move_sliding_ledge(dir)
		if sliding? or system_tag_here?(MachBike)
			return true
		end
		case dir
		when 8
			set_sliding_route(SLIDING_LEDGE_BLOCK_ROUTE)
		when 2
			set_sliding_route(SLIDING_LEDGE_GO_DOWN_ROUTE)
		end
		return false
	end
end