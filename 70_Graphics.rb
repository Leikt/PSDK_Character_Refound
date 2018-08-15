class Game_Character
	# Update the pattern displayed of the character
	def update_pattern
		if @animation_charset
			if @animation_charset_counter <= 0
				a = @animation_charset[@animation_charset_index]
				@direction = a >> 2
				@pattern = a & 0b11
				@animation_charset_counter = @animation_charset_delay
				@animation_charset_index += 1
				if @animation_charset_index >= @animation_charset.size
					if @animation_charset_repeated
						@animation_charset_index = 0
						if @animation_charset_force_wait
							set_wait_count(@animation_charset_delay * @animation_charset.size)
						end
					else
						@animation_charset = nil
						@original_pattern = @pattern
						@direction_fix = @was_direction_fix
						if @animation_charset_end_command
							route = MRB.new
							if @animation_charset_end_command.is_a?(Array)
								@animation_charset_end_command.each do |cmd|
									route.add_command(cmd)
								end
							else
								route.add_command(@animation_charset_end_command)
							end
							force_move_route(route)
						end
					end
				end
			end
			return
		end
		if @anime_count > (18 - @move_speed * 2) * @anime_coef
			if (!@step_anime and @stop_count > 0)
				@pattern = @original_pattern
				@pattern_state = false
			else
				if @is_pokemon
					@pattern = (@pattern + 1) % 4
				else
					if @step_anime
						@pattern = (@pattern + 1) % 4
					else
						@pattern = (@pattern + (@pattern_state ? -1 : 1)) % 4
					end
					@pattern_state = true if @pattern == 3
					@pattern_state = false if @pattern <= 1
				end
			end
			@anime_count = 0
		end
	end
	def update_blank_depth
		return if @blank_depth_change_moment == nil
		case @blank_depth_change_moment
		when :move_end
			if movable?
				@no_shadow = @blank_depth_no_shadow
				@blank_depth = @blank_depth_change_value
				@blank_depth_change_moment = @blank_depth_change_value = @blank_depth_no_shadow = nil
			end
		end
	end
	# Return the x position of the sprite on the screen
	# @return [Integer]
	def screen_x
		return (@real_x - $game_map.display_x + 5) / 4 + 16 + @screen_x_offset
	end
	# Return the y position of the sprite on the screen
	# @return [Integer]
	def screen_y
		y = (@real_y - $game_map.display_y + 5 - @slope_height - @float_height) / 4 + 32 + @screen_y_offset
		if @jump_count >= @jump_peak
			n = @jump_count - @jump_peak
		else
			n = @jump_peak - @jump_count
		end
		return (y - (@jump_peak * @jump_peak - n * n) / 2)
	end
	# Return the z superiority of the sprite of the character
	# @param height [Integer] (ignored) height of a frame of the character
	# @return [Integer]
	def screen_z(height = 0)
		if @always_on_top
			return 999
		end
		if @always_on_bottom
			return ((@real_y - $game_map.display_y + 3) / 4 + 31)
		end
		z = (@real_y - $game_map.display_y + 3) / 4 + 32 * @z
		if @tile_id > 0
			return z + $game_map.priorities[@tile_id] * 32
		else
			return z + 31
		end
	end
	# Return the x position of the shadow of the character on the screen
	# @return [Integer]
	def shadow_screen_x
		return (@real_x - $game_map.display_x + 5) / 8 + 8
	end
	# Return the y position of the shadow of the character on the screen
	# @return [Integer]
	def shadow_screen_y
		return (@real_y - @slope_height - $game_map.display_y + 5) / 8 + 17
	end
	# bush_depth of the sprite of the character
	# @return [Integer]
	def bush_depth
		if @tile_id > 0 or @always_on_top
			return 0
		end
		return 12 if @in_swamp #> Ajout des marais
		if @jump_count == 0 and $game_map.bush?(@x, @y)
			return 12
		else
			return 0
		end
	end
	# Fade the opacity from the current to the targetted in duration frames
	# @param new_opacity [Integer] the new opacity
	# @param duration [Integer] frames count before the new opacity
	# @author Leikt
	def fade_opacity(new_opacity, duration)
		@original_opacity=@opacity
		@faded_opacity=new_opacity
		@opacity_fading_counter=duration
		@opacity_fading_duration=duration
	end
	# Fade the screen y offset progressivly to the wanted value
	# @param from [Integer, nil] the initial screen_y_offset, by default the current value of @screen_y_offset
	# @param to [Integer] the final value of screen_y_offset
	# @param duration [Integer] the duration in frames of the animation
	# @author Leikt
	def fade_screen_y_offset(from, to, duration, blank_v = false)
		@original_screen_y_offset = (from ? from : @screen_y_offset)
		@faded_screen_y_offset = to
		@screen_y_offset_fading_counter = duration
		@screen_y_offset_fading_duration = duration
		@screen_y_offset_blank = blank_v
	end
	# Fade the screen x offset progressivly to the wanted value
	# @param from [Integer, nil] the initial screen_x_offset, by default the current value of @screen_x_offset
	# @param to [Integer] the final value of screen_x_offset
	# @param duration [Integer] the duration in frames of the animation
	# @author Leikt
	def fade_screen_x_offset(from, to, duration)
		@original_screen_x_offset = (from ? from : @screen_x_offset)
		@faded_screen_x_offset = to
		@screen_x_offset_fading_counter = duration
		@screen_x_offset_fading_duration = duration
	end
	# Change the graphics of the character
	# @param c_name [String] new character
	# @param c_hue [Integer] new hue
	# @param dir [Integer] new direction
	# @param patt [Integer] new pattern
	# @author Leikt
	def change_graphics(c_name, c_hue, dir, patt)
		@tile_id = 0
		@character_name = c_name
		@character_hue = c_hue
		if (@original_direction != dir)
			@direction = dir
			@original_direction = @direction
			@prelock_direction = 0
		end
		if (@original_pattern != patt)
			@pattern = patt
			@original_pattern = @pattern
		end
	end
	# Make the character poke (lateral movement)
	# @param peak [Integer] the size of the poke in pixels
	# @param start_duraction [Integer] the duration of the animation in frame, or if end_duration != nil the duration of the first part
	# @param end_duration [Integer, nil] the duration of the last part of the animation (by default : half the start_duration)
	def poke(peak, start_duration, end_duration=nil)
		unless end_duration
			end_duration = (start_duration / 2)
			start_duration /= 2
		end
		route = MRB.new.set_poking(true)
		case @direction
		when 2
			route.fade_screen_y_offset(nil, peak, start_duration)
				.wait(start_duration)
				.fade_screen_y_offset(nil, 0, end_duration)
		when 4
			route.fade_screen_x_offset(nil, -peak, start_duration)
				.wait(start_duration)
				.fade_screen_x_offset(nil, 0, end_duration)
		when 6
			route.fade_screen_x_offset(nil, peak, start_duration)
				.wait(start_duration)
				.fade_screen_x_offset(nil, 0, end_duration)
		when 8
			route.fade_screen_y_offset(nil, -peak, start_duration)
				.wait(start_duration)
				.fade_screen_y_offset(nil, 0, end_duration)
		end
		route.wait(end_duration)
			.set_poking(false)
		self.force_move_route(route, :special_add)
	end

	def set_blank(moment, value, no_shad = @no_shadow)
		if moment == :now
			@blank_depth = value
			@no_shadow = no_shad
		else
			@blank_depth_change_moment = moment
			@blank_depth_change_value = value
			@blank_depth_no_shadow = no_shad
		end
	end
end	