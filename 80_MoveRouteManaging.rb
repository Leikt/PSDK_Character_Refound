class Game_Character
	# <DEBUG> display current route status
	# @param premsg [String, ""] the message to display before the list
	def disp_routes(premsg = "")
		pc "#{premsg} => #{@move_routes.map {|m| m="ROUTE" if m != nil}}"
	end
	# Force the character to adopt a move route and save the original one
	# @param move_route [RPG::MoveRoute] the forced move route
	# @param mode [Symbol, :normal] the forcing mod : normal, special_add (stack the move route), special_overwrite (stop the special route, and start the new one)
	# @param priority [Boolean, false] true if the route has to start now
	# @author Leikt
	def force_move_route(move_route, mode = :normal, priority = false, replace=false)
		old_forcing = @move_route_forcing
		index = @move_routes.index {|m| m != nil and m[0] == @move_route}
		if index
			@move_routes[index][1] = (@move_route_index + ((priority and replace) ? 1 : 0))
		end
		case mode
		when :normal
			@move_routes[1] = [move_route, 0]
		when :special_add
			id = [2, @move_routes.size].max
			@move_routes[id] = [move_route, 0]
		when :special_overwrite
			@move_routes = @move_routes[0...2]
			@move_routes[2] = [move_route, 0]
		else
			pcc "ERROR #{mode} is not valid as force move mode", 0x1
			system("pause")
		end
		mr = @move_routes.select {|m| m != nil}.last
		@move_route = mr[0]
		@move_route_index = mr[1]
		@prelock_direction = 0
		@wait_count = 0
		@move_route_forcing = true
		move_type_custom if (!old_forcing or priority)
	end
	# Pause the forced route
	# @param force_stop [Boolean, false] false : the character can move, true : it can'target
	def pause_route(force_stop=false)
		if @move_route_forcing and !@paused_route						# Can pause route only if there is no other paused route
			# pc "route paused (force_stop=#{force_stop})"				
			@paused_index=@move_route_index								# Store the route index
			@paused_route=@move_route									# Store the route
			if force_stop
				force_move_route(MRB.new.wait(1).enable_repeat)			# Disable charcater mouvement
			else
				force_move_route(MRB::EMPTY_ROUTE)								# Enable character mouvement
			end
		end
	end
	# Resume the paused route, need to be called after pause_route.
	def resume_route
		if @paused_route										# Can't resume pause route if there isn't one	
			force_move_route(@paused_route, @paused_index)		# Restore the paused route with the paused index
			@paused_route=nil									# Reset paused route values
			@paused_index=0
		end
	end
	# Cut the followed route and return the result. Use it only on moving road or if you know what you are doing.
	# @param length [Integer] number of movement to do before stopping
	# @param commands [Array<RPG::MoveCommand>, RPG::MoveCommand, nil] the commands to do at the stop
	#	@return [RPG::MoveRoute] the cutted move route or nil if the character isn't move route forced
	def cut_route(length, commands=nil)
		if @move_route_forcing												# Can cut only force routes
			move_route=@move_route.clone
			index=@move_route_index											# Search index
			counter=0														# Move command counter
			end_index=move_route.list.size									# Maximum valid index
			while index < end_index and counter < length
				if (MRB.is_move_command?(move_route.list[index].code))
					counter += 1											# Count a move command
				end
				index += 1													# Increase the route index
			end
			new_list = move_route.list[@move_route_index...index]			# Get the new commands list
			if commands.is_a?(Array)
				new_list.push commands
				new_list.flatten!
			elsif commands.is_a?(RPG::MoveCommand)
				new_list.push commands
			end
			if new_list.last.code != 0										# Check if the end of the list is truncate
				new_list.push MRB::EMPTY_COMMAND
			end
			@move_route_index = 0											# Setup the new route
			move_route.list = new_list
			move_route.repeat = false
			force_move_route(move_route)
			return move_route
		else
			return nil
		end
	end
end