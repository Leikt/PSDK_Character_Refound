class Game_Character
	#________________________________________________
	# >>> TESTERS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# is the character moving ?
	# @return [Boolean]
	def moving?
		(@real_x != @target_real_x or @real_y != @target_real_y)
	end
	# is the character jumping ?
	# @return [Boolean]
	def jumping?
		(@jump_count > 0)
	end
	# is the character poking ?
	# @return [Boolean]
	def poking?
		@poking
	end
	# is the charcater in jumping type mouvement ?
	#	@return [Boolean]
	def jump_type_moving?
		return jumping?
	end
	# is the character surfing ?
	#	@return [Boolean]
	def surfing?
		return @surfing
	end
	# is the character sliding
	def sliding?
		return @sliding
	end
	# Start surfing
	def set_surfing
		@surfing = true
	end
	# Stop surfing
	def reset_surfing
		@surfing = false
	end
	# Get the current system tag
	# @return [Integer] the system tag
	def system_tag
		return @system_tag
	end
	# Get the current terrain tag
	# @return [Integer] the terrain tag
	def terrain_tag
		return $game_map.terrain_tag(@x, @y)
	end
	# Change the speed for the next move
	# @param key [Symbol] the name of the change
	# @param amount [Integer, 1] the value of modification (can be negative to slow the speed)
	def change_speed_for_this_move(key, amount=1)
		change_speed(key, amount)
		@restore_speed_at_move_end.push key
	end
	# Change the speed
	# @param key [Symbol] the name of the change
	# @param amount [Integer, 1] the value of modification (can be negative to slow the speed)
	def change_speed(key, amount=1)
		@move_speed -= @saved_speeds.fetch(key, 0)
		nspeed = @move_speed + amount
		if nspeed <= 0
			amount += 1 - nspeed
		elsif nspeed > 6
			amount = 6 - @move_speed
		end
		@move_speed += amount
		@saved_speeds[key] = amount
	end
	# Restore the speed for the given key
	# @param key [Symbol] the name of change
	def restore_speed(key)#, amount=1)
		@move_speed -= @saved_speeds.fetch(key, 0)
		@saved_speeds[key] = 0
	end
	# Check if it's possible to have contact interaction with this Game_Character at certain coordinates
	# @param x [Integer] x position
	# @param y [Integer] y position
	# @param z [Integer] z position
	# @return [Boolean]
	# @author Nuri Yuri
	def contact?(x, y, z, slope_height=0, caller_y=nil)
		(@x == x and @y == y and (@z - z).abs <= 1 and (!caller_y or @slope_height==slope_height or ((@slope_height + (caller_y > @y ? 40*4 : 0) - slope_height).abs  < 16*4)))
	end
	
	#________________________________________________
	# >>> MODIFIERS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Set coordinates and update the shortcuts
	# @param new_x [Integer] the new x coordinate
	# @param new_y [Integer] the new y coordinate
	# @param up_shortcuts [Boolean, false] true if the shortcuts have to be updated
	def set_coords(new_x, new_y, up_shortcuts = false)
		if new_x
			@x = new_x
			@target_real_x = new_x * 128
		end
		if new_y
			@y = new_y
			@target_real_y = new_y * 128
		end
		if up_shortcuts
			update_position_shortcuts
		end
	end
	# Update numbers of shorcuts avoiding to call $game_map functions repeatedly
	def update_position_shortcuts
		dir = @direction_fixed ? @direction_fixed : @direction
		@front_x = @x + (dir == 4 ? -1 : (dir == 6 ? 1 : 0)) 
		@front_y = @y + (dir == 8 ? -1 : (dir == 2 ? 1 : 0))
		@system_tag = $game_map.system_tag(@x, @y)
		@front_system_tag = $game_map.system_tag(@front_x, @front_y)
		@system_tags = $game_map.get_system_tags(@x, @y)
	end
	# Test if the Game_Character is on a specific systemTag
	# @param tag [Integer] the tag to search
	# @return [Boolean] true if there is the tag
	def system_tag_here?(tag)
		return @system_tags.include?(tag)
	end
	# Test if the Game_Character is on specifics systemTags
	# @param tags [Array<Integer>] the tags to search
	# @return [Boolean] true if there is one of the givent tags
	def one_of_system_tags_here?(tags)
		@system_tags.each do |t|
			return true if tags.include?(t)
		end
		return false
	end
	# Adjust the character position
	def straighten
		if @walk_anime or @step_anime
			@pattern = 0
			@pattern_state = false
		end
		@anime_count = 0
		@prelock_direction = 0
	end
	# Warps the character on the Map to specific coordinates.
	# Adjust the z position of the character.
	# @param x [Integer] new x position of the character
	# @param y [Integer] new y position of the character
	# @param skip_z [Boolean, false] true if the character has z by default (or the older value)
	def moveto(x, y, skip_z = false)
		set_coords(x % $game_map.width, y % $game_map.height, true)
		@real_x = @x * 128
		@real_y = @y * 128
		@prelock_direction = 0
		follower_moveto(x, y)
		if skip_z and !$scene.is_a?(Scene_Map)
			@z = 1 unless @z
			return
		end
		if ((st=@system_tag)==BridgeRL or st==BridgeUD)
			@z = $game_map.priorities[$game_map.get_tile(@x, @y,)].to_i + 1
		elsif (ZTag.include?(st))
			@z = ZTag.index(st)
		else
			@z = 1
		end
		particle_push
	end
	# Change the sliding route, set the result of sliding? to true and start the sliding route
	# @param route [RPG::MoveRoute] the route of sliding
	# @param skip_update [Boolean, true] true if the update will be skipped
	def set_sliding_route(route, skip_update = true)
		@sliding = true
		@skip_state_update = skip_update
		force_move_route(route, :special_overwrite)
	end
	# Stop sliding
	def end_slide_route
		@direction = @direction_fixed if @direction_fixed
		@direction_fix = false
		@direction_fixed = nil
		@sliding_spin = false
		@sliding_route = nil
		@sliding = false
		@skip_state_update = false
		state_slide_end
	end
	# Update the running mouvements of the character
	def update_mouvements
		if jumping?
			update_jump
		elsif moving?
			update_move
		else
			update_stop
		end
	end
	# Update the jump animation
	def update_jump
		@jump_count -= 0.5
		last_real_y = @real_y
		@real_x = ((@real_x * @jump_count + @x * 128) / (@jump_count + 1)).round >> 2 << 2
		@real_y = ((@real_y * @jump_count + @y * 128) / (@jump_count + 1)).round >> 2 << 2
		@shadow_offset_y = ((@real_y - last_real_y) >> 2) << 2
		@pattern = 0 if @jump_count<=0
		update_slope_jump
	end
	# Update the poke animation
	def update_poke
	end
	# Update the move animation
	def update_move
		distance = 2 ** self.move_speed
		ny = @y * 128						# Little optimization
		nx = @x * 128
		@real_y = [@real_y + distance, ny].min 		if ny > @real_y
		@real_x = [@real_x - distance, nx].max 		if nx < @real_x
		@real_x = [@real_x + distance, nx].min 		if nx > @real_x
		@real_y = [@real_y - distance, ny].max 		if ny < @real_y
		if @walk_anime
			@anime_count += 1.5
		elsif @step_anime
			@anime_count += 1
		end
		@shadow_offset_y = 0 if @shadow_offset_y!=0
		update_slope(nx, ny)
		if @real_x == nx and @real_y == ny and !@restore_speed_at_move_end.empty?
			for key in @restore_speed_at_move_end
				restore_speed(key)
			end
		end
	end
	# Update the value of slope_height
	# @param nx [Integer] the new x coordinate
	# @param ny [Integer] the new y coordinate
	def update_slope(nx, ny)
		if through
			@slope_height = 0
		elsif @float_peak > 0
			update_float
		elsif (@current_slope != @old_slope)
			delta_slope = (@current_slope - @old_slope).to_f
			delta_pos = (128 - (nx - @real_x).abs - (ny - @real_y).abs).to_f
			@slope_height = (@old_slope.to_f + (delta_slope * (delta_pos / 128.0))).round
			@slope_height = ((@slope_height >> 2) << 2)
		end
	end
	# Update the floating animation
	def update_float
		@float_count += @float_step
		@float_count = @float_step if @float_count >= @float_peak
		@float_height = (Math.sin(Math::PI * 2 * @float_count / @float_peak) * @float_peak).round
	end
	# Update the slope during jump animation
	def update_slope_jump
		if through
			@slope_height = 0
		else
			delta_slope = (@current_slope - @old_slope).to_f
			coef_jump = 1.0-(@jump_count.to_f / (2*@jump_peak).to_f)
			@slope_height = (@old_slope.to_f + (delta_slope * coef_jump)).round
			@slope_height = ((@slope_height >> 2) << 2)
		end
	end
	# Update the stop animation
	def update_stop
		if @float_peak > 0
			update_float
		elsif @old_slope != @current_slope
			@old_slope = @current_slope
			@current_slope = @slope_height = $game_map.passabilities.get_slope(@x, @y, @z)
		end
		if @step_anime
			@anime_count += 1
		elsif @pattern != @original_pattern
			@anime_count += 1.5
		end
		@stop_count += 1
	end
	# Calculate the distance to the given coords
	# @param *args [Objects]
	# @return [Integer] the distance
	def distance(*args)
		x, y = convert_coords(*args)
		return ((@x - x).abs + (@y - y).abs)
	end
	def front_tile_event
		xf = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
		yf = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
		$game_map.events_list do |event|
		  return event if event.x == xf and event.y == yf
		end
		return nil
	end
	def has_front_system_tag?(tag)
		return $game_map.system_tag_here?(@front_x, @front_y, tag)
	end
end