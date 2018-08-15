class Game_Event < Game_Character
	# DEPRECIATE > Tag inside an event that put it in the surfing state
	SurfNTag = "surf_"
	# DEPRECIATE > If named like this, this event is an invisible object
	InvisibleTag = "OBJ_INVISIBLE"
	# DEPRECIATE > Tag that sets the event in an invisible state (not triggerd unless in front of it)
	InvisibleTag2 = "invisible_"
	# DEPRECIATE > Tag that tells the event to always take the character_name of the first page when page change
	AutoCharsetTag = "$"
	# DEPRECIATE > Tag that telles the event to don't display shadow under the sprite
	NoShadowTag = "§"
	# Tag that add 1 to the superiority of the Sprite_Character
	SupTag = "¤"

	attr_accessor :id
	attr_reader :trigger
	attr_reader :starting
	attr_reader :list
	attr_reader :event
	attr_reader :objetInvisible
	attr_reader :erased

	def initialize(map_id, event)
		super()
		@map_id = map_id
		@event = event
		@id = @event.id
		@original_map = event.original_map || map_id
		@original_id = event.original_id || @id
		@starting = false
		@erased = false
		@surfing = @autocharset = @objetInvisible = false
		@globals= Hash.new(0)
		@globals[:use_particles] = @globals[:use_state_machine] = true
		@globals[:no_shadow] = false
		@globals[:tags] = []
		@globals[:always_displayed] = false
		@no_shadow = false
		@use_particles = true
		@use_state_machine = true
		check_name_tags
		@pages_conditions = []
		scan_global_comment_commands
		moveto(@event.x, @event.y)
		refresh
	end
	def initialize_passability
		super
		# add_passability(Passabilities::WALK)
		# add_passability(Passabilities::LEDGE)
		# add_passability(Passabilities::STAIR)
		# add_passability(Passabilities::BRIDGE)
		# add_passability(Passabilities::SLOPE)
		# add_passability(Passabilities::SLIDING_LEDGE)
		# add_passability(Passabilities::SLIDING)
		# add_passability(Passabilities::GRASS)
		# add_passability(Passabilities::TALL_GRASS)
		
		add_passability(Passabilities::WALK)
		add_passability(Passabilities::LEDGE)
		add_passability(Passabilities::STAIR)
		add_passability(Passabilities::BRIDGE)
		add_passability(Passabilities::SLOPE)
		add_passability(Passabilities::SLIDING_LEDGE)
		add_passability(Passabilities::SWAMP)
		add_passability(Passabilities::SLIDING)
		add_passability(Passabilities::GRASS)
		add_passability(Passabilities::TALL_GRASS)
		add_passability(Passabilities::SURF_TRANSITION)
		add_passability(Passabilities::WATERFALL)
		add_passability(Passabilities::CRACKED_FLOOR)
		add_passability(Passabilities::UNDERWATER_ZONE)
	end
	# DEPRECIATE > Check if the name contains tags for the event
	def check_name_tags
		if @event.name.include?(SurfNTag)
			@surfing = true
			add_tag(:surfing)
			pcc "Using \"#{SurfNTag}\" in the name of the event is deprecated. Use the comment command \"GLOBAL SURFING\" instead.", 0x03
		end
		if @event.name.include?(InvisibleTag) or @event.name.include?(InvisibleTag2)
			@objetInvisible = true
			pcc "Using \"#{InvisibleTag}\" or \"#{InvisibleTag2}\" in the name of the event is deprecated. Use the comment command \"GLOBAL INVISIBLE\" instead.", 0x03
		end
		if @event.name.include?(AutoCharsetTag)
			@autocharset = true
			pcc "Using \"#{AutoCharsetTag}\" in the name of the event is deprecated. Use the comment command \"GLOBAL AUTO_CHARSET\" instead.", 0x03
		end
		if @event.name[0] == NoShadowTag
			@no_shadow = true
			pcc "Using \"#{NoShadowTag}\" in the name of the event is deprecated. Use the comment command \"GLOBAL NO_SHADOW\" instead.", 0x03
		end
		if @event.name[0] == SupTag
			@superposition_p1 = true
			pcc "Using \"#{NoShadowTag}\" in the name of the event is deprecated. Use the comment command \"GLOBAL SUPERPOSITION_SUP\" instead.", 0x03
		end
	end
	# Start the event if possible
	def start
		@starting = true if (@list.size > 1)
	end
	# Sets @starting to false allowing the event to move with its default move route
	def clear_starting
		@starting = false
	end
	# Tells if the Event can start
	# @return [Boolean]
	def over_trigger?
		return false if ((!(@character_name.empty? and @tile_id == 0) and !self.through and !self.through_events) or @objetInvisible)
		return $game_map.passable?(@x, @y, 0)
	end
	# Remove the event from the map
	def erase
		@erased = true
		# @x = @y = -10
		set_coords(-10, -10)
		@opacity = 0
		$game_map.event_erased = true
		refresh
	end
	def disable_state_machine
		@use_state_machine = false
	end
	def enable_state_machine
		@use_state_machine = true
	end
	# Check if the event touch the player and start it if so
	# @param x [Integer] the x position to check
	# @param y [Integer] the y position to check
	def check_event_trigger_touch(x, y)
		if $game_system.map_interpreter.running?
			return
		end
		if @trigger == 2 and x == $game_player.x and y == $game_player.y
			if !jump_type_moving? and !over_trigger?
				start
			end
		end
	end
	# Check if the event starts automaticaly and start if so
	def check_event_trigger_auto
		if @trigger == 2 and @x == $game_player.x and @y == $game_player.y and !$game_temp.player_transferring
			if !jump_type_moving? and over_trigger?
				start
			end
		end
		if @trigger == 3
			start
		end
	end
	# Update the Game_Character and its internal Interpreter
	def check_premove
		return false unless state_check_premove	
		return super
	end
	def update_main
		state_update	# Update the state
		state_ext_update
		check_event_trigger_auto
		if @interpreter != nil
			unless @interpreter.running?
				@interpreter.setup(@list, @event.id)
			end
			@interpreter.update
		end
		if @stop_count > (40 - @move_frequency * 2) * (6 - @move_frequency)
			case @move_type
			when 1;	move_type_random
			when 2;	move_type_toward_player
			when 3; move_type_custom
			end
		end
	end
	def set_wait_count(value)
		super
		if @interpreter != nil
			@interpreter.wait_count = value
		end
	end
end