class Game_Player
	# Check if the follower is activated
	def follower_check_trigger
		return unless @follower
		if(@follower.x == @front_x and @follower.y == @front_y)
			@follower.turn_toward_player
			$game_temp.common_event_id = 5 #> Appel Follower
		end
	end
end	