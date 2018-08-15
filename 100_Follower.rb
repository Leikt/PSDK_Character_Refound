class Game_Character
	# Move the follower to the given coords
	# @param x [Integer]
	# @param y [Integer]
	def follower_moveto(x, y)
		return unless @follower
		for dir in 0..3
			nx = x + (dir == 1 ? -1 : dir == 2 ? 1 : 0)
			ny = y + (dir == 3 ? -1 : dir == 0 ? 1 : 0)
			if can_move(nx, ny, 10-(dir*2))
				@follower.moveto(nx, ny)
				@follower.direction = @direction
				return
			end
		end
		@follower.moveto(x, y)
		@follower.direction = @direction
	end
	# Warp the follower to the event it follows
	# @author Nuri Yuri
	def move_follower_to_character
		return unless @follower
		return if $game_variables[::Yuki::Var::FM_Sel_Foll]>0 #>Pour la mise en scène
		# @follower.x = @x
		# @follower.y = @y
		for dir in 1..4
			nx = @x + (dir == 2 ? -1 : dir == 3 ? 1 : 0)
			ny = @y + (dir == 4 ? -1 : dir == 1 ? 1 : 0)
			if can_move(nx, ny, 10-(dir*2))
				@follower.x = nx
				@follower.y = ny
				break
			end
		end
		@follower.x = @x
		@follower.y = @y
	end
	# Define the follower of the event
	# @param follower [Game_Character, Game_Event] the follower
	# @author Nuri Yuri
	def set_follower(follower)
		@follower = follower
	end
	 # Remove the memorized moves of the follower
	# @author Nuri Yuri
	def reset_follower_move
		if @memorized_move
			@memorized_move_arg = @memorized_move = nil
		end
		@follower.reset_follower_move if @follower
	end
	def follower_jump(dx, dy)
		return unless @follower
		follower_move
		@memorized_move = :jump
		@memorized_move_arg = [dx, dy]
	end
	# Move a follower
	# @author Nuri Yuri
	def follower_move
		return unless @follower
		return if $game_variables[::Yuki::Var::FM_Sel_Foll]>0 #>Pour la mise en scène
		if @memorized_move
			@memorized_move_arg ? @follower.send(@memorized_move,*@memorized_move_arg) : @follower.send(@memorized_move)
			@memorized_move_arg=nil
			@memorized_move=nil
			return
			#elsif @follower.sliding? and @follower.system_tag != TIce
			#  return
		end
		dx=@x-@follower.x
		dy=@y-@follower.y
		d==@direction
		d2=@follower.direction
		case d
		when 2 #bas
			if dx<0
				@follower.move_left
			elsif dx>0
				@follower.move_right
			elsif dy>1
				@follower.move_down
			elsif dy==0# and d2==8
				@follower.move_up
			end
		when 4 #gauche
			if dy<0
				@follower.move_up
			elsif dy>0
				@follower.move_down
			elsif dx<-1
				@follower.move_left
			elsif dx==0# and d2==6
				@follower.move_right
			end
		when 6 #droite
			if dy<0
				@follower.move_up
			elsif dy>0
				@follower.move_down
			elsif dx>1
				@follower.move_right
			elsif dx==0# and d2==4
				@follower.move_left
			end
		when 8  #haut
			if dx<0
				@follower.move_left
			elsif dx>0
				@follower.move_right
			elsif dy<-1
				@follower.move_up
			elsif dy==0# and d2==2
				@follower.move_down
			end
		end
	end
	def follower_move_lower_left
		return unless @follower
		@memorized_move=:move_lower_left if $game_variables[Yuki::Var::FM_Sel_Foll]==0
		@follower.direction = @direction
	end
	def follower_move_lower_right
		return unless @follower
        @memorized_move=:move_lower_right if $game_variables[Yuki::Var::FM_Sel_Foll]==0
        @follower.direction = @direction
	end
	def follower_move_upper_left
		return unless @follower
        @memorized_move = :move_upper_left if $game_variables[Yuki::Var::FM_Sel_Foll]==0
        @follower.direction = @direction
	end
	def follower_move_upper_right
		return unless @follower
        @memorized_move = :move_upper_right if $game_variables[Yuki::Var::FM_Sel_Foll]==0
        @follower.direction = @direction
	end
	def follower_set_next_move(meth, *args)
		return unless @follower
		@memorized_move = meth
		@memorized_move_arg = args
	end
end