class Game_Character
	include GameData::SystemTags
	# Shortcut to MapsNavigation::ABILITIES module
	# @type [Module]
	Passabilities = MapsNavigation::ABILITIES			# All the passabilities for the Passability system
	# Passabilities which trigger special moves
	# @type [Integer]
	SPECIAL_MOVE_PASSABILITIES = Passabilities::STAIR | Passabilities::LEDGE | Passabilities::SURF_TRANSITION |
		Passabilities::WATERFALL | Passabilities::SLOPE | Passabilities::SLIDING_LEDGE |
		Passabilities::CROSS_BIKE_STRAIGHT | Passabilities::TALL_GRASS | Passabilities::SWAMP |
		Passabilities::SLIDING | Passabilities::SURF_TRANSITION | Passabilities::WATERFALL | Passabilities::CRACKED_FLOOR |
		Passabilities::GRASS
	SPECIAL_EVENTS_CHECK = Passabilities::STAIR | Passabilities::SLOPE
	# Character's image matching the state {:state => {:sub_state=>'_character'}}
	# @type [Hash<Symbol, Hash<Symbol, String>>]
	CHARA_BY_STATE = Hash.new
	# Character's particle veto matching the state {:state => [list of un-emittable particles]}
	PARTICLE_VETO = Hash.new([])
	# <Cross bike> Delay before switching from wheeling to bunny hop
	# @type [Integer]
	CROSS_BIKE_BUNNY_HOP_DELAY = 30
	# <Cross bike> Duration in frames of the transition from stop / wheeling to wheeling / stop
	# @type [Integer]
	CROSS_BIKE_WHEELING_TRANSITION_DURATION = 25
	# 4 time the x position of the Game_Player sprite
	# @type [Integer]
	CENTER_X = (320 - 16) * 4
	# 4 time the y position of the Game_Player sprite
	# @type [Integer]
	CENTER_Y = (240 - 16) * 4
	# Name of the bump sound when the player hit a wall
	# @type [String]
	BUMP_FILE = "Audio/SE/bump"
	WATERFALL_AUDIO_FILE="Audio/particles/waterfall"
	DIVING_AUDIO_FILE="Audio/particles/waterfall"
	# Character name of the surf dummy
	SURF_DUMMY = "dummy_surf"
	# Route when the sliding ledge can't be climbed
	# @type [RPG::MoveRoute]
	SLIDING_LEDGE_BLOCK_ROUTE = MRB.new
							.change_speed_for_one_move(:sliding_ledge, -1)
							.move_up
							.move_down
							.wait(5)
							.check_slide_end_here(MachBike)
							# .change_speed_for_one_move(:sliding_ledge, 1.5)
	# <Speed Biker> Route when the sliding ledge can't be climbed
	# @type [RPG::MoveRoute]
	SLIDING_LEDGE_BLOCK_BIKE_ROUTE = MRB.new
							.change_speed_for_one_move(:sliding_ledge, 1)
							.move_up
							.change_speed_for_one_move(:sliding_ledge, 1.5)
							.move_down
							.wait(5)
							.set_sub_state(:stopped)
							.check_slide_end_here(MachBike)
	# Sliding route when the Game_Character go down the sliding ledge
	# @type [RPG::MoveRoute]
	SLIDING_LEDGE_GO_DOWN_ROUTE = MRB.new.move_down
	# <Speed Bike> Sliding route when the Game_Character go up the sliding ledge
	# @type [RPG::MoveRoute]
	SLIDING_LEDGE_GO_UP_ROUTE = MRB.new.move_up
	# Sliding route for classic straight sliding
	# @type [RPG::MoveRoute]
	SLIDE_STRAIGHT_ROUTE = MRB.new.move_forward_direction_fixed
	# Sliding route for classic spin sliding
	# @type [RPG::MoveRoute]
	SLIDE_SPIN_ROUTE = MRB.new
						.disable_direction_fix
						.turn_left_90
						.enable_direction_fix
						.move_forward_direction_fixed
	# <Cracked Floor> Fall through floor route
	CRACKED_FLOOR_FALL_ROUTE = MRB.new
						.wait_move_completion
						.reset_state
						.fade_opacity(0,20)
						.wait(15)
						.play_se(RPG::AudioFile.new("fall", 100, 100))
						.wait(5)
						.transfer_player(26,27,28,:var)
						.wait(1)
						.fade_screen_y_offset(-224, 0, 20)
						.fade_opacity(255, 10)
						.wait(10)
						.check_cracked_floor(false, true)
						.particle_push(:dust)
						.check_sliding_tags
	# <Diving> route from surface to under
	DIVING_DOWN_FROM_SURFACE = MRB.new
						.particle_push(:splash_water)
						.fade_screen_y_offset(0,64,90,true)
						.wait(50)
						.transfer_player(26,27,28,:var)
						.wait(1)
						.change_blank_depth(0)
						.change_opacity(0)
						.fade_screen_y_offset(-128,0,60)
						.fade_opacity(255,20)
						.wait(35)
						.set_sub_state(:stopped)
						.check_sliding_tags
	# <Diving> route from under to deeper under
	DIVING_DOWN_FROM_UNDER = MRB.new
						.fade_screen_y_offset(0,48,90)
						.fade_opacity(0,30)
						.wait(50)
						.transfer_player(26,27,28,:var)
						.wait(1)
						.fade_opacity(255,30)
						.fade_screen_y_offset(-128,0,60)
						.wait(35)
						.set_sub_state(:stopped)
						.check_sliding_tags
	# <Diving> route from under to surface
	DIVING_UP_TO_SURFACE = MRB.new
						.fade_screen_y_offset(0,-128,90)
						.fade_opacity(0,60)
						.wait(50)
						.transfer_player(26,27,28,:var)
						.wait(1)
						.change_opacity(255)
						.particle_push(:splash_water)
						.fade_screen_y_offset(48,0,90,true)
						.wait(46)
						.set_states(:surf, :stopped)
						.check_sliding_tags
	# <Diving> route from deeper under to under
	DIVING_UP_TO_UNDER = MRB.new
						.fade_screen_y_offset(0,-128,90)
						.fade_opacity(0,60)
						.wait(50)
						.transfer_player(26,27,28,:var)
						.wait(1)
						.fade_opacity(255,30)
						.fade_screen_y_offset(16,0,60)
						.wait(35)
						.set_sub_state(:stopped)
						.check_sliding_tags
	# Sound when diving cracked floor
	DIVING_CRACKED_FLOOR_SOUND = RPG::AudioFile.new("watersound001", 100, 100)
	# <Diving + Cracked Hole> route to make the player fall through the ground in diving mode
	DIVING_CRACKED_FLOOR_FALL_ROUTE = MRB.new
						.wait_move_completion
						.reset_state
						.play_se(DIVING_CRACKED_FLOOR_SOUND)
						.multiple_move(2, :particle_push, :bubble, 1)
						.turn_left_90.wait(3).multiple_move(2, :particle_push, :bubble, 1)
						.turn_left_90.wait(3).multiple_move(2, :particle_push, :bubble, 1)
						.fade_opacity(0,25)
						.turn_left_90.wait(3)
						.play_se(DIVING_CRACKED_FLOOR_SOUND)
						.multiple_move(2, :particle_push, :bubble, 1)
						.turn_left_90.wait(3).multiple_move(2, :particle_push, :bubble, 1)
						.turn_left_90.wait(3).multiple_move(2, :particle_push, :bubble, 1)
						.turn_left_90.wait(3).multiple_move(2, :particle_push, :bubble, 1)
						.turn_left_90.wait(3).multiple_move(2, :particle_push, :bubble, 1)
						.turn_left_90.wait(8)
						.play_se(DIVING_CRACKED_FLOOR_SOUND)
						.script("@underwater_level+=1")
						.transfer_player(26,27,28,:var)
						.fade_screen_y_offset(-224, 0, 20)
						.fade_opacity(255, 10)
						.wait(1).turn_left_90
						.wait(1).turn_left_90
						.wait(1)
						.play_se(DIVING_CRACKED_FLOOR_SOUND)
						.turn_left_90.wait(1)
						.turn_left_90.wait(1)
						.turn_left_90.wait(1)
						.turn_left_90.wait(1)
						.turn_left_90.wait(1)
						.turn_left_90.wait(1)
						.turn_left_90.wait(2)
						.turn_left_90.wait(2)
						.turn_left_90.wait(3)
						.turn_left_90.wait(3)
						.turn_left_90.wait(4)
						.check_cracked_floor(false, true)
						.check_sliding_tags
	# <Diving + Cracked Floor> Fall from the top of the screen in screen mode
end