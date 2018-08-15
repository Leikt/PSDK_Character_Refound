class Game_Character
	# List of system tags that use particles when on floor
	FLOOR_PARTICLE_SYSTEM_TAGS = [TGrass, TTallGrass, TSand, TPond, TSnow]
	# List of system tags that use particle when on bridge
	BRIDGE_PARTICLE_SYSTEM_TAGS = []
	# Push a particle to the particle stack if possible
	# @author Nuri Yuri
	def particle_push
		return unless @use_particles
		if @z <= 1
			case $game_map.get_filtered_system_tags(@x, @y, FLOOR_PARTICLE_SYSTEM_TAGS).first
			when TGrass
				Yuki::Particles.add_particle(self,:grass,@particle_use_sound)
			when TTallGrass
				Yuki::Particles.add_particle(self,:tall_grass,@particle_use_sound)
			when TSand
				if is_on_bike?
					# Todo
				else
					particle = [:sand_d, :sand_l, :sand_r, :sand_u][@direction / 2 - 1]
					Yuki::Particles.add_particle(self,particle,@particle_use_sound)
				end
			when TPond
				Yuki::Particles.add_particle(self,:pond,@particle_use_sound)
			when TSnow
				if is_on_bike?
					# Todo
				else
					particle = [:snow_d, :snow_l, :snow_r, :snow_u][@direction / 2 - 1]
					Yuki::Particles.add_particle(self,particle,@particle_use_sound)
				end
			end
		else
			# There is no bridge system tags for now
			# case $game_map.get_filtered_system_tags(@x, @y, BRIDGE_PARTICLE_SYSTEM_TAGS).last
			# end
		end
	end
	# Push a specific particle to the particle stack if possible
	# @param tag [Symbol] the type of particle to push
	# @param set [Integer, nil] the number of the particle set
	# @author Leikt
	def force_particle_push(tag, set = nil)
		return if PARTICLE_VETO[@state].include?(tag)
		Yuki::Particles.add_particle(self, tag, @particle_use_sound, set)
	end
	# Play animation from the charset
	# @param lines [Array<Integer>] Oredered list of number from 0 to 3 included, where 0 is the top line and the 3 the bottom line
	# @param duration [Integer] Duration in number of frames. 30=1s
	# @param reversed [Boolean, false] True if the line must be played reversally
	# @param repeated [Boolean, false] True if the animation must be looped
	# @param force_wait [Boolean, false] True if the animation force the character stay immobile
	# @param end_command [RPG::MoveCommand, nil] the command to execute at the end of the animation
	def animate_from_charset(lines, duration, reversed: false, repeated: false, end_command: nil, force_wait: false)
		animation = []								# Initialize the frames list
		for dir in lines
			for patt in [0,1,2,3]
				animation.push ((((dir+1)*2)<<2) | patt)	# A frame is 0bdddpp with ddd the direction, pp the pattern
			end
		end
		animation.reverse! if reversed				# Inverse the frames if animation reversed
		@animation_charset = animation
		@animation_charset_delay = (duration.to_f / animation.size.to_f).round	# Delay between two frames 
		@animation_charset_counter = 0				# Counter of frame 
		@animation_charset_repeated = repeated
		@animation_charset_end_command = end_command
		@animation_charset_index = 0
		@animation_charset_force_wait = force_wait
		a = @animation_charset.shift				# Initialize the appearence
		@direction = a >> 2
		@pattern = a & 0b11
		@was_direction_fix = @direction_fix
		@direction_fix = true
		if force_wait
			set_wait_count(@animation_charset_delay * @animation_charset.size)
			# set_wait_count(100000)
		end
	end
end

