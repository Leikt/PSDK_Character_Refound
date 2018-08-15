class Game_Player
	# Adjust the map display according to the given position
	# @param x [Integer] the x position on the MAP
	# @param y [Integer] the y position on the MAP
	def center(x, y)
		unless Game_Map::CenterPlayer
			max_x = ((gm=$game_map).width - 20) * 128
			max_y = (gm.height - 15) * 128
			gm.display_x = [0, [x * 128 - CENTER_X, max_x].min].max
			gm.display_y = [0, [y * 128 - CENTER_Y, max_y].min].max
		else
			$game_map.display_x = x * 128 - CENTER_X
			$game_map.display_y = y * 128 - CENTER_Y
		end
	end
	# Refresh the player graphics
	def refresh
		if $game_party.actors.size == 0
		  @character_name = nil.to_s
		  @character_hue = 0
		  return
		end
		actor = $game_party.actors[0]
		@character_name = actor.character_name
		@character_hue = actor.character_hue
		@opacity = 255
		@blend_type = 0
	end
	# Launch the player update appearence
	def update_appearence(forced_pattern = 0)
		return if @appearence_updated
		@appearence_updated = true
		actor = $game_party.actors[0]
		return unless actor
		
		new_chara = actor.character_name
		new_hue = actor.character_hue
		new_battler = actor.battler_name
		new_battler_hue = actor.battler_hue
		
		charset_base = actor.charset_base
		unless charset_base
			charset_base = actor.charset_base = "Hero_01_RED"
		end
		suffix = get_chara_by_state
		if suffix
			new_chara = charset_base + ($game_switches[1] ? '_F' : '_M') + suffix
		end
		
		actor.set_graphic(new_chara, new_hue, new_battler, new_battler_hue)
		@character_name = new_chara
		# refresh
		@pattern=forced_pattern
		return true
	end
	# Get the character suffix from the hash
	# @return [String] the suffix
	# @author Leikt
	def get_chara_by_state
		return @character_name CHARA_BY_STATE[@state][@sub_state]
	end

	def set_appearence_set(charset_base)
		actor = $game_party.actors[0]
		return unless actor
		actor.charset_base = charset_base
		@appearence_updated = false
		update_appearence
	end
end	