class Game_Character
	attr_reader   :id					# [Integer] id the characater in the map
	attr_accessor :x					# [Integer] coord x of the character
	attr_accessor :y					# [Integer] coord y of the character
	attr_accessor :z					# [Integer] altitude of the character, used only with bridge
	attr_reader   :front_x				# [Integer] front coord x of the character
	attr_reader   :front_y				# [Integer] front coord y of the character
	attr_reader   :real_x				# [Integer] x * 128
	attr_reader   :real_y				# [Integer] y * 128
	attr_reader   :tile_id				# [Integer] id of used tile in the tileset
	attr_reader   :slope_height			# [Integer] y screen substract to original scrren y, when on slope
	attr_accessor :character_name		# [String] name of the image 
	attr_accessor :character_hue		# [Integer] HUE of the character sprite
	attr_accessor :opacity				# [Integer] 0-255 the opacity of the character
	attr_reader   :blend_type			# [Integer] blending mode
	attr_accessor :direction			# [Integer] direction of the character 2:Down, 4:Left, 6:Right, 8:Up
	attr_accessor :direction_fix
	attr_reader   :pattern				# [Integer] image in the line of the charset 0,1,2,3
	attr_reader   :move_route_forcing	# [Boolean] true if the character is currently following a force move route
	attr_accessor :animation_id			# [Integer] animation played on the character
	attr_accessor :transparent			# [Boolean] set the opacity to 0 
	attr_accessor :move_speed			# [Integer] the move speed of the character between 1 and 6 included
	attr_accessor :step_anime			# [Boolean] true if the character is animated when stopped
	attr_accessor :in_swamp				# [Integer] swamp depth indicator, nil if not in swamp
	attr_accessor :is_pokemon			# [Boolean] true if the character is a pokemon
	attr_accessor :use_particles		# [Boolean] true if the character use the particle system
	attr_accessor :no_shadow				# [Boolean] true if the character throw no shadow
	attr_accessor :always_on_bottom		# [Boolean] true if the character is always displayed under the others
	attr_reader :superposition_p1		# [Boolean] true if the charcater gain a superposition
	attr_reader :slope_height			# [Integer] height of the slope in real coords (128 = 1 tile)
	attr_reader :passability			# [Integer] flags of the passability of the character (may be temporary)
	attr_reader :passability_capacity	# [Integer] flags of the global passability of the character (manually changed)
	attr_reader :blank_depth			# [Integer] height of the rectangle hided from the bottom of the sprite
	attr_reader :system_tag				# [Integer] current system tag of the character
	attr_reader :front_system_tag		# [Integer] current front system tag of the character
	attr_accessor :float_height
	attr_reader :always_displayed
	
	# Initialize the Game_Character with default value, and refresh it
	def initialize
		@id = 0
		@x = 0
		@y = 0
		@z = 1
		@real_x = @target_real_x = 0
		@real_y = @target_real_y = 0
		@shadow_offset_y = 0
		set_coords(0,0)
		@old_slope = -1
		@current_slope = @slope_height = 0
		@tile_id = 0
		@character_name = nil.to_s
		@character_hue = 0
		@opacity = 255
		@blend_type = 0
		@direction = 2
		@pattern = 0
		@move_route_forcing = false
		@animation_id = 0
		@transparent = false
		@original_direction = 2
		@original_pattern = 0
		@move_type = 0
		@move_speed = 4
		@saved_speeds = {:default => 4}
		@restore_speed_at_move_end = []
		@move_frequency = 6
		@move_route = nil
		@move_route_index = 0
		@original_move_route = nil
		@original_move_route_index = 0
		@move_routes = []
		@walk_anime = true
		@step_anime = false
		@direction_fix = false
		@always_on_top = false
		@always_on_bottom = false
		@anime_count = 0
		@stop_count = 0
		@jump_count = 0
		@jump_peak = 0
		@jump_side = 0
		@float_count = 0
		@float_peak = 0
		@float_step = 0.5
		@float_height = 0
		@poking = false
		@wait_count = 0
		@locked = false
		@prelock_direction = 0
		@superposition_p1 = false
		@no_shadow = false
		@surfing = false 		# Variable indiquant si le chara est sur l'eau
		@sliding = false		# Variable indiquant si le chara slide
		@pattern_state = false 	# Indicateur de la direction du pattern
		@tags=[]				# List of all the tags	
		initialize_passability	# Character's assability abilities
		@state = :feet			# Current state
		@sub_state = :walk
		@particle_use_sound = false
		@anime_coef = 1
		@blank_depth = 0
		@use_particles = true
		@screen_x_offset = 0
		@screen_y_offset = 0
		@opacity_fading_counter = -1
		@screen_y_offset_fading_counter = -1
		@screen_x_offset_fading_counter = -1
		@always_displayed = false
		init_counters
	end
	
	# Initialize the counters
	def init_counters
		@animation_charset_counter = 0
	end
	
	# Add the given tag(s) to the character
	# @param tag [Symbol, Array] tag or tag list
	def add_tags(tags)
		if tags.is_a?(Symbol)
			@tags.push(tags) unless @tags.include?(tags)
		elsif tags.is_a?(Array)
			tags.each do |tag|
				@tags.push(tag) unless @tags.include?(tag)
			end
		end
	end
	alias add_tag add_tags
	# Remove the given tag(s) from the character
	# @param tag [Symbol, Array] tag or tag list
	def remove_tags(tags)
		if tags.is_a?(Symbol)
			@tags.delete(tags)
		elsif tags.is_a?(Array)
			tags.each do |tag|
				@tags.delete(tag)
			end
		end
	end
	alias remove_tag remove_tags
	# Check if the character has the tag(s). The complex tag list has to be formated :
	# 		[:OR, :tag1, :tag2, [:AND, :tag4, :tag6], [:AND, :tag3, :tag5]]
	# 		equal : tag1 or tag2 or (tag4 and tag6) or (tag3 and tag5)
	# @param tags [Symbol, Array] tag or list of tag to test.
	def has_tags?(tags)
		return @tags.include?(tags) if tags.is_a?(Symbol)
		return true if (tags.empty? or tags.size==1 and (tags[0]==:AND or tags[0]==:OR))
		operator=:AND
		result=true
		if tags[0]==:OR
			operator=:OR
			result=false
		end
		for tag in tags
			next if (tag==:AND or tag==:OR)
			return false if (operator==:AND and !has_tag?(tag))
			return true if (operator==:OR  and  has_tag?(tag))
		end
		return result
	end
	alias has_tag? has_tags?
	# Reset the list of tag to the global ones
	def clear_tags
		@tags = @globals[:tags].clone
	end
	# Add the given global tag(s) to the character
	# @param tag [Symbol, Array] tag or tag list
	def add_global_tags(tags)
		if tags.is_a?(Symbol)
			@globals[:tags].push(tags) unless @globals[:tags].include?(tags)
			@tags.push(tags) unless @tags.include?(tags)
		else
			tags.each do |tag|
				@globals[:tags].push(tag) unless @globals[:tags].include?(tag)
				@tags.push(tag) unless @tags.include?(tag)
			end
		end
		add_tags(tags)
	end
	alias add_global_tag add_global_tags
	# Remove the given global tag(s) from the character
	# @param tag [Symbol, Array] tag or tag list
	def remove_global_tags(tags)
		if tags.is_a?(Symbol)
			@globals[:tags].delete(tags)
			@tags.delete(tags)
		else
			tags.each do |tag|
				@globals[:tags].delete(tag)
				@tags.delete(tag)
			end
		end
	end
	alias remove_global_tag remove_global_tags
	
	#____________________________________________________________
	# >>> STATES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	0
	# Change the state of the character
	# @param new_state [Symbol] the new state
	def set_state(new_state)
		@state=new_state
	end
end	