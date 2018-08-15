class Game_Player
	# Dictionnary of the character name suffix depending of the states and sub states
	# Exemple : a character image will be used by the cross bike in wheeling if it end by "_cycle_wheel"
	# !!! Be careful modifying this !!!
	CHARA_BY_STATE[:dummy] = {
		:default_state => '_default_appearence'
	}
	# List of the particle can't be emitted by the current state
	PARTICLE_VETO[:dummy] = []
	# Reset the state
	# @author Leikt
	def dummy_reset
		set_sub_state(:default_state)
	end
	
	# Reset the sub state
	# @author Leikt
	def dummy_sub_reset
	end
	
	# Test if the state is leavable
	# @return [Boolean]
	# @author Leikt
	def is_dummy_state_leavable?
		return true
	end
	
	# Do actions when the machine leave the state
	# @author Leikt
	def on_dummy_state_leave
	end
	
	# Do actions when the machine enter the state
	# @author Leikt
	def on_dummy_state_enter
		set_sub_state(:default_state)
	end
	
	# Do actions before every mouvements including forced move route, or waiting
	# @return [Boolean] true if the normal mouvement can be done, false if not
	# @author Leikt 
	def dummy_premove
		return true
	end
	
	# Do actions right before normal mouvement (Input from player).
	# @return [Boolean] true if the Input mouvement can be done, false if not
	# @author Leikt
	def dummy_update
		case @sub_state
		when :default_state
		end
		classic_moves_check						# Do classic mouvement
		return true
	end
	
	# Do actions right after all the moves
	# @return [Boolean]
	# @author Leikt
	def dummy_postmove
		return true
	end
	
	# Do the sub state's leaving actions
	# @param old_sub_state [Symbol] name of the leaving sub state
	# @author Leikt
	def on_dummy_sub_state_leave(old_sub_state)
		case old_sub_state
		when :default_state
		end
	end
	
	# Do the sub state's entering actions
	# @param new_sub_state [Symbol] name of the entering sub state
	# @author Leikt
	def on_dummy_sub_state_enter(new_sub_state)
		case new_sub_state
		when :default_state
		end
	end
	
	# Do the action at the end of sliding
	# @return [Boolean] false if the movement process end is skipped
	# @author Leikt
	def dummy_slide_end
		set_sub_state(:default_state)
		return true
	end
	
	# Do move for the sliding ledge tag, passable only with speed_bike and max speed_bike
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def dummy_sliding_ledge(dir)
		case @sub_state
		when :default_state
		end
		return false
	end
	
	# Do move for the sliding passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def dummy_sliding(dir)
		return false
	end

	# Do move for the surf transition passage
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def dummy_surf_transition(dir)
		return false
	end

	# Do move for the cracked floor transition
	# @param dir [Integer] the direction of the character
	# @return [Boolean] true if the normal mouvement can be done
	# @author Leikt
	def dummy_cracked_floor(dir)
		return false
	end

	# Check the action to do when A is pressed and no event is triggered
	def dummy_check_event_trigger_there
	end
end