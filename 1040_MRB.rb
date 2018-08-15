# Move Route Builder
# This class help to create move route.
# Exemple : MRB.new.turn_down.move_down.jump(0,1).wait(10)
class MRB < RPG::MoveRoute
	MOVE_DOWN				= 1
	MOVE_LEFT				= 2
	MOVE_RIGHT				= 3
	MOVE_UP					= 4
	MOVE_LOWER_LEFT			= 5
	MOVE_LOWER_RIGHT		= 6
	MOVE_UPPER_LEFT			= 7
	MOVE_UPPER_RIGHT		= 8
	MOVE_RANDOM				= 9
	MOVE_TOWARD_PLAYER		= 10
	MOVE_AWAY_PLAYER		= 11
	MOVE_FORWARD			= 12
	MOVE_BACKWARD			= 13
	JUMP					= 14
	WAIT 					= 15
	TURN_DOWN				= 16
	TURN_LEFT				= 17
	TURN_RIGHT				= 18
	TURN_UP					= 19
	TURN_RIGHT_90			= 20
	TURN_LEFT_90			= 21
	TURN_180				= 22
	TURN_RIGHT_OR_LEFT_90	= 23
	TURN_RANDOM				= 24
	TURN_TOWARD_PLAYER		= 25
	TURN_AWAY_PLAYER		= 26
	ENABLE_SCWITCH			= 27
	DISABLE_SWITCH			= 28
	SET_MOVE_SPEED			= 29
	SET_MOVE_FREQUENCY		= 30
	ENABLE_WALK_ANIM		= 31
	DISABLE_WALK_ANIM		= 32
	ENABLE_STEP_ANIM		= 33
	DISABLE_STEP_ANIM		= 34
	ENABLE_DIRECTION_FIX	= 35
	DISABLE_DIRECTION_FIX	= 36
	ENABLE_THROUGH			= 37
	DISABLE_THROUGH			= 38
	ENABLE_ALWAYS_ON_TOP	= 39
	DISABLE_ALWAYS_ON_TOP	= 40
	CHANGE_GRAPHIC			= 41
	CHANGE_OPACITY			= 42
	CHANGE_BLENDING			= 43
	PLAY_SE					= 44
	SCRIPT					= 45
	MOVE_TOWARD_TAG			= 100
	MOVE_AWAY_TAG			= 101
	MOVE_FORWARD_DIRECTION_FIXED = 102
	FORCE_MOVE_ROUTE		= 103
	WAIT_MOVE_COMPLETION	= 104
	TURN_TOWARD_TAG			= 200
	TURN_AWAY_TAG			= 201
	TURN_TOWARD_DIR			= 202
	FADE_OPACITY			= 300
	CHANGE_SPEED_FOR_ONE_MOVE = 301
	SET_SKIP_STATE_UPDATE	= 302
	CHECK_SLIDE_END_HERE	= 303
	CHECK_SLIDE_END_THERE	= 304
	DISABLE_ROUTE_REPEAT	= 305
	PARTICLE_PUSH			= 306
	RESET_CHARA_PATTERN		= 307
	CHANGE_SPEED			= 308
	SET_INSTANCE_VARIABLE	= 309
	SET_STATE				= 310
	SET_SUB_STATE			= 311
	MOVEMENT_PROCESS_END	= 312
	RESET_SUB_STATE			= 313
	SET_STATES				= 314
	CHECK_SLIDING_TAGS		= 315
	DELETE_THIS_EVENT		= 316
	CALL_COMMON_EVENT		= 317
	FADE_SCREEN_Y_OFFSET	= 318
	RESET_STATE				= 319
	FADE_SCREEN_X_OFFSET	= 320
	POKE					= 321
	SET_POKING				= 322
	CHECK_CRACKED_FLOOR		= 323
	CHANGE_BLANK_DEPTH		= 324
	TRANSFER_PLAYER			= 325
	CHANGE_SCREEN_TONE		= 326
	SET_VARIABLE			= 327
	CHECK_STATE_COHERENCE	= 328
	
	EMPTY_COMMAND=RPG::MoveCommand.new
	
	# Initialize the move route : no repeat, skippable and empty command list
	def initialize
		@repeat = false
		@skippable = true
		@list = [RPG::MoveCommand.new]
	end
	# Make the move route repeated, by default it's non
	# @return [MoveRouteBuilder] itself
	def enable_repeat; @repeat = true; return self; end
	# Make the move route not repeated, by default it's non
	# @return [MoveRouteBuilder] itself
	def disable_repeat; @repeat = false; return self;end
	# Make the move route skippable, by default, it's skippable
	#	@return [MoveRouteBuilder] itself
	def enable_skippable; @skippable = true; return self;end
	# Make the move route non skippable, by default, it's skippable
	#	@return [MoveRouteBuilder] itself
	def disable_skippable; @skippable = false; return self;end
	# Add command to the route (at the end of the list)
	# @param code [Integer] code of the command
	# @overload parameters parameters of the command
	# @return [MRB] itself
	def add(code, *parameters)
		@list.insert(-2, RPG::MoveCommand.new(code, parameters))
		return self
	end
	# Add the given command to the route (at the end of the lise)
	# @param command [RPG::MoveCommand] the command to add
	#	@return [MRB] itself
	def add_command(command)
		@list.insert(-2, command)
		return self
	end
	# Allow the creation of multiple command in one
	# @param count [Integer] count of exact commands
	# @param args [*Object] parameters of the commands
	# @return [MRB] itself
	def multiple_move(count, cst, *args)
		count.times do |i|
			self.send(cst, *args)
		end
		return self
	end
	# Create a Move command
	# @param code [Integer] code of the command
	# @param parameters [Object] parameters of the command
	# @return [RPG::MoveCommand]
	def self.command(code, *parameters)
		return RPG::MoveCommand.new(code, parameters)
	end
	# Test if the given code match a move command (not turn neather misc)
	# @param code [Integer] the command code
	# @return [Boolean] true if the code matchs a move command
	def self.is_move_command?(code)
		return (code < 15 or (code >= 100 and code < 200))
	end
	# Auto creation of methods
	MRB.constants(false).each do |cst|
		module_eval("def #{cst.downcase}(*args);return add(#{cst}, *args);end")
	end
end