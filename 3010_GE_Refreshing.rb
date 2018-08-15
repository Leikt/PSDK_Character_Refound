class Game_Event < Game_Character
	# Refresh the event : check if an other page is valid and if so, refresh the graphics and command list
	def refresh
		new_page = nil
		unless @erased
			for page in @event.pages.reverse
				c = page.condition
				gs = $game_switches
				next if c.switch1_valid and gs[c.switch1_id] == false
				next if c.switch2_valid and gs[c.switch2_id] == false
				next if c.variable_valid and gs[c.variable_id] < c.variable_value
				next if c.self_switch_valid and $game_self_switches[[@original_map, @original_id, c.self_switch_ch]] != true
				next if !check_scripted_conditions(@event.pages.index(page))
				new_page = page
				break
			end
		end
		return if (new_page==@page)
		@page = new_page
		clear_tags
		clear_starting
		if (new_page==nil)
			@tile_id = 0
			@character_name = nil.to_s
			@character_hue = 0
			@move_type = 0
			@move_routes = []
			@through = true
			@trigger = nil
			@list = nil
			@interpreter = nil
			return
		end
		@tile_id = new_page.graphic.tile_id
		if @autocharset
			@character_name = @event.pages[0].graphic.character_name
			@character_hue = @event.pages[0].graphic.character_hue
		else
			@character_name = new_page.graphic.character_name
			@character_hue = new_page.graphic.character_hue
		end
		if @original_direction != new_page.graphic.direction
			@direction = @page.graphic.direction
			@original_direction = @direction
			@prelock_direction = 0
		end
		if @original_pattern != new_page.graphic.pattern
			@pattern = new_page.graphic.pattern
			@original_pattern = @pattern
		end
		@opacity = new_page.graphic.opacity
		@blend_type = new_page.graphic.blend_type
		@move_type = new_page.move_type
		@move_speed = new_page.move_speed
		@move_frequency = new_page.move_frequency
		@move_route = new_page.move_route
		@move_routes = [[@move_route, 0]]
		@move_route_index = 0
		@move_route_forcing = false
		@walk_anime = new_page.walk_anime
		@step_anime = new_page.step_anime
		@direction_fix = new_page.direction_fix
		self.through= new_page.through
		@always_on_top = new_page.always_on_top
		@trigger = new_page.trigger
		@list = new_page.list
		@interpreter = nil
		if @trigger == 4
			@interpreter = Interpreter.new
		end
		@no_shadow = @globals[:no_shadow]
		@use_particles = @globals[:use_particles]
		@use_state_machine = @globals[:use_state_machine]
		@float_peak = @globals[:float_peak]
		@float_step = @globals[:float_step]
		@screen_y_offset = @globals[:screen_y_offset]
		@always_displayed = @globals[:always_displayed]
		scan_page_comment_command(new_page)
		check_event_trigger_auto
	end
	
	#__________________________________________
	# >>> SCRIPTED CONDITIONS >>>>>>>>>>>>>>>>>
	0
	# Add a scripted condition to the given page
	# @param page_id [Integer] The index of the page
	# @param command [String] script to eval
	def add_scripted_condition(page_id, command)
		@pages_conditions[page_id] = [] unless @pages_conditions[page_id]
		@pages_conditions[page_id].push command
	end
	# Check the validity of the page's scripted conditions
	# @param page_id [Integer] page id
	#	@return [Boolean] the result
	def check_scripted_conditions(page_id)
		return true unless @pages_conditions[page_id]
		interpreter = Interpreter.new
		interpreter.setup([], self.id)
		@pages_conditions[page_id].each do |cdt|
			return true if interpreter.eval_script(cdt)==true#(eval(cdt)==true)
		end
		return false
	end
	
	#__________________________________________
	# >>> COMMENT COMMANDS >>>>>>>>>>>>>>>>>>>>
	0
	# Scan the global comment command
	def scan_global_comment_commands
		for page_id in 0...@event.pages.size
			page = @event.pages[page_id]
			i = 0
			while (i < page.list.size)
				if (page.list[i].code == 108)
					lines=[page.list[i].parameters[0]]
					i+=1
					while (i < page.list.size and page.list[i].code == 408)
						lines.push page.list[i].parameters[0]
						i+=1
					end
					interpret_global_comment_command(lines, page_id)
					i-=1
				end
				i+=1
			end
			page_id += 1
		end
	end
	# Interprete the global comment command
	# @param lines [String[]] lines of the command
	# @param page_id [Integer] id of the page
	def interpret_global_comment_command(lines, page_id)
		function = lines[0].split(' ')
		lines = lines[1..-1]
		index = 0
		case function[index]
		when "GLOBAL"
			case function[index+=1]
			when "TAGS"
				add_global_tags(eval("["+lines.join+"]"))
			when "INVISIBLE"
				@objetInvisible = true
			when "AUTOCHARSET"
				@autocharset=true
			when "SURFING"
				@surfing = true
				@globals[:no_shadow] = true
			when "NO_SHADOW"
				@no_shadow = @globals[:no_shadow] = true
			when "SUPERPOSITION_SUP"
				@superposition_p1 = true
			when "ALWAYS_ON_BOTTOM"
				@always_on_bottom = true
			when "NO_PARTICLES"
				@use_particles = @globals[:use_particles] = false
			when "UNDERWATER"
				@use_particles = @globals[:use_particles] = false
				@no_shadow = @globals[:no_shadow] = true
				@surfing = true
				@always_on_bottom = true
				remove_passability_ability(Passabilities::SURF_TRANSITION | Passabilities::WATERFALL)
				set_through_events
			when "PASSABILITY"
				p = Passabilities
				case function[index+=1]
				when "RESET"
					initialize_passability
				when "SET"
					@passability_capacity = @passability = eval(lines.join)
				when "ADD"
					add_passability_ability(eval(lines.join))
				when "REMOVE"
					remove_passability_ability(eval(lines.join))
				end
			when "ENABLE_STATE_MACHINE", "ESM"
				@use_state_machine = @globals[:use_state_machine] = true
			when "DISABLE_STATE_MACHINE", "DSM"
				@use_state_machine = @globals[:use_state_machine] = false
			when "FLOATING"
				v=eval('[' + lines.join + ']')
				@float_peak = @globals[:float_peak] = v[0]
				@float_step = @globals[:float_step] = v[1]
			when "SCREEN_Y_OFFSET", "SYO"
				@screen_y_offset = @globals[:screen_y_offset] = eval(lines.join)
			when "ALWAYS_DISPLAYED"
				@always_displayed = @globals[:always_displayed] = true
			end
		when "PAGE"
			case function[index+=1]
			when "CONDITION"
				add_scripted_condition(page_id, lines.join("\n"))
			end
		end
	end
	# Scan the given page and apply the comment command
	# @param page [RPG::Event::Page] the page to scan
	def scan_page_comment_command(page)
		@temp_move_route = nil
		i = 0
		while (i < page.list.size)
			if (page.list[i].code == 108)
				lines=[page.list[i].parameters[0]]
				i+=1
				while (i < page.list.size and page.list[i].code == 408)
					lines.push page.list[i].parameters[0]
					i+=1
				end
				i-=1
				interpret_comment_command(lines)
			end
			i+=1
		end
		if @temp_move_route != nil
			@move_route=@temp_move_route
			@move_routes[0]=@move_route
			@move_type=3
		end
	end
	# Interprete the global comment command
	# @param lines [String[]] lines of the command
	def interpret_comment_command(lines)
		function = lines[0].split(' ')
		lines = lines[1..-1]
		index = 0
		case function[index]
		when "TAGS"
			add_tags(eval("["+lines.join()+"]"))
		when "NO_SHADOW"
			@no_shadow = true
		when "SHADOW"
			@no_shadow = false
		when "NO_PARTICLES"
			@use_particles = false
		when "USE_PARTICLES"
			@use_particles = true
		when "MOVE_ROUTE"
			@temp_move_route = MRB.new unless @temp_move_route
			eval('@temp_move_route'+lines.join())
		when "THROUGH_EVENTS"
			set_through_events
		when "PASSABILITY"
			p = Passabilities
			case function[index+=1]
			when "RESET"
				initialize_passability
			when "SET"
				@passability_capacity = @passability = eval(lines.join)
			when "ADD"
				add_passability_ability(eval(lines.join))
			when "REMOVE"
				remove_passability_ability(eval(lines.join))
			end
		when "ENABLE_STATE_MACHINE", "ESM"
			@use_state_machine = true
		when "DISABLE_STATE_MACHINE", "DSM"
			@use_state_machine = false
		when "FLOATING"
			v=eval('[' + lines.join + ']')
			@float_peak = v[0]
			@float_step = v[1]
		when "SCREEN_Y_OFFSET", "SYO"
			@screen_y_offset = eval(lines.join)
		when "ALWAYS_DISPLAYED"
			@always_displayed = true
		end
	end

	def is_on_bike?
		return false
	end
end