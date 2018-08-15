module MapsNavigation
	module ABILITIES
		i = -1
		WALK			= 1 << (i+=1)
		TALL_GRASS		= 1 << (i+=1)
		WATERFALL		= 1 << (i+=1)
		RAPIDS			= 1 << (i+=1)
		SURF_TRANSITION	= 1 << (i+=1)
		BRIDGE			= 1 << (i+=1)
		SWAMP			= 1 << (i+=1)
		LEDGE			= 1 << (i+=1)
		THROUGH			= 1 << (i+=1)
		THROUGH_EVENTS	= 1 << (i+=1)
		STAIR			= 1 << (i+=1)
		SLOPE			= 1 << (i+=1)
		SLIDING_LEDGE	= 1 << (i+=1)
		CROSS_BIKE_STRAIGHT 	= 1 << (i+=1) 
		CROSS_BIKE_TURN_JUMP 	= 1 << (i+=1)
		CROSS_BIKE_SIDE_JUMP	= 1 << (i+=1)
		CROSS_BIKE_BUNNY_HOP	= 1 << (i+=1)
		CROSS_BIKE_BIG_BUNNY_HOP= 1 << (i+=1)
		SLIDING			= 1 << (i+=1)
		CRACKED_FLOOR	= 1 << (i+=1)
		GRASS			= 1 << (i+=1)
		UNDERWATER_ZONE = 1 << (i+=1)
		if true
			puts "---------------------------------------------"
			ABILITIES.constants(false).each do |cst|
				puts "#{cst.to_s.ljust(30)} => (#{(ABILITIES.const_get(cst).to_s+")").ljust(20)} 0x#{ABILITIES.const_get(cst).to_s(16).upcase}"
			end
			puts ">>> #{ABILITIES.constants(false).size}/30"
			puts "---------------------------------------------"
		end
	end

	# =================================
	# >>> Constants
	DIRECTORY = "Data/MapNavigation/"
	FILE_FORMAT = "MapNavigationData%03d.mapnav"
	FORCE_MAPS_ANALYZE = true
	DEBUG = true
	MAP_DEFAULT_GEN = []
	MAP_DEFAULT_GEN = [23]
	# MAP_DEFAULT_GEN = [11, 13, 14, 16, 17, 18, 19, 20, 23]
	# MAP_DEFAULT_GEN = :all
	
	# =================================
	# >>> Access
	
	@data = {}
	
	# Get the pathfinding map data from the map id 
	# @param map_id [Integer] the id of the map
	#	@return [Pathfinding::MapNavigationData] the data of the map
	def self.get(map_id)
		# pc "#{self} >>> get map data #{map_id}"
		unless @data.has_key?(map_id)
			load(map_id)
		end
		return @data[map_id]
	end
	
	# Delete the loaded map data
	# @param map_id [Integer] the id of the map
	def self.drop(map_id)
		# pc "#{self} >>> drop map data #{map_id}"
		@data.delete(map_id)
	end
	
	# Load the map data from the id
	# @param map_id [Integer] the id of the map
	def self.load(map_id)
		filename = "#{DIRECTORY}#{sprintf(FILE_FORMAT, map_id)}"
		begin
			@data[map_id] = load_data(filename)
			# @data[map_id].check_zero
			pc "#{self} >>> load map data : success"
		rescue Exception => e
			pcc "#{self} <<<WARNING>>> can't load map data : #{map_id}", 0x06
			pcc e.message, 0x06
		end
	end
	
	# Analyze all the maps of the game and create a file for each of them in Data/PathfindingMapsNavigation/*.pfmap
	def self.main_analyze(list = MAP_DEFAULT_GEN)
		return unless FORCE_MAPS_ANALYZE
		pc "#{self} >>> start analyzing maps..."
		ids = []
		Dir.mkdir(DIRECTORY) unless File.exists?(DIRECTORY)
		Dir.glob("Data/Map*.rxdata") do |map_file|
			id = map_file[8...11].to_i
			ids.push(id) if (list == :all or list.include?(id))
		end
		ids.uniq!
		ids.each do |map_id|
			s = ids.size
			i = ids.index(map_id)+1
			size = ((i.to_f / s.to_f) * 30.0).floor
			percent = ((i.to_f / s.to_f) * 100.0).floor
			pcc "#{self} >>> #{"Analyzing map #{map_id}".ljust(20)} [#{("#"*size).ljust(30, '-')}] (#{i}/#{s}) (#{percent}%)", 0x2
			filename = "#{DIRECTORY}#{sprintf(FILE_FORMAT, map_id)}"
			File.delete(filename) if File.exists?(filename)
			data = MapNavigationData.new(map_id)
			save_data(data, filename)
		end
		MapNavigationData.display_infos
	end
	
	# =================================
	# >>> MapNavigationData
	
	# Contain the pre analyzed passage data of the map and the algorithm of the analyze
	class MapNavigationData
		# =================================
		# >>> Constants
		include MapsNavigation::ABILITIES
		SystemTags = GameData::SystemTags
		
		DIRS = [2,4,6,8]
		# Compare the given abilities and the move requierment. Return the Integer, each bit match a abilities
		# @param abilities [Integer] Int32, the abilities' flags
		# @param x [Integer] the start x mouvement
		# @param y [Integer] the start y mouvement
		# @param z [Integer] the current character z
		# @param dir [Integer] the mouvement direction
		# @return [Integer] Int32 with flags of confirmed abilities for the mouvement
		def compare(abilities, x, y, z, dir)
			return 1 unless DIRS.include?(dir)
			return abilities & @data[dir/2][x, y, z]
		end
		
		def get_slope(x, y, z)
			return @slopes[x, y, z]
		end
		
		attr_reader :map_id
		def initialize(map_id)
			# pc "#{self} >>> creating map data #{map_id}"
			@map_id = map_id
			game_map = Game_Map.new
			game_map.setup(map_id, true)
			w, h = game_map.width, game_map.height
			# Initialize passages data
			data = @data = []
			for cmd_dir in 1..4
				t = Table32.new(w, h, 7)
				t.fill(0)
				data[cmd_dir] = t
				# pc data[cmd_dir][rand(w),rand(h), rand(7)]
			end
			# Initialize bridges data
			data_bridge = Table.new(w, h, BRIDGES.size)
			data_bridge.fill(0)
			# Initialize slope data
			data_slopes = @slopes = Table.new(w, h, 7)
			@slopes.fill(0)
			
			# Bridge scan
			countB=0
			totalB = w*h
			displayB=totalB/30
			print "\r#{"Bridge&Slopes scan".ljust(30)}[#{('#'*0).ljust(30, '-')}] (#{0}%)"
			for x in 0...w
				for y in 0...h
					calc_bridge(x, y, BRIDGES[0], data_bridge, game_map)
					calc_bridge(x, y, BRIDGES[1], data_bridge, game_map)
					calc_bridge(x, y, BRIDGES[2..5], data_bridge, game_map)
					calc_slope_heights(x, y, game_map, data_slopes)
					countB += 1
					if countB % displayB == 0
						percent = ((countB.to_f/totalB.to_f)*100).floor
						disp = (percent.to_f/100) * 30.0
						print "\r#{"Bridge&Slopes scan".ljust(30)}[#{('#'*disp).ljust(30, '-')}] (#{percent}%)"
					end
				end
			end
			calc_slope_heights_from_events(game_map, data_slopes)
			print "\r#{"Bridge&Slopes scan".ljust(30)}[#{('#'*30).ljust(30, '-')}] (#{100}%)"
			print "\n"
			
			# Passages scan
			count=0
			total = 4*w*h*7
			display=total/30
			print "\r#{"Passages scan".ljust(30)}[#{('#'*0).ljust(30, '-')}] (#{0}%)"
			for cmd_dir in 1..4
				for x in 0...w
					for y in 0...h
						for z in 0...7
							data[cmd_dir][x, y, z] = detect(x, y, z, cmd_dir*2, game_map, data_bridge, data_slopes)
							count += 1
							if count%display == 0
								percent = ((count.to_f/total.to_f)*100).floor
								disp = (percent.to_f/100) * 30.0
								print "\r#{"Passages scan".ljust(30)}[#{('#'*disp).ljust(30, '-')}] (#{percent}%)"
							end
						end
					end
				end
			end
			print "\r#{"Passages scan".ljust(30)}[#{('#'*30).ljust(30, '-')}] (#{100}%)"
			print "\n"
			make_some_test(data_bridge)
			@@tested_count += count
			pc "#{self} >>> map data #{map_id} created"
		end
		
		private
		
		# >>> Bridges detection
		BRIDGES = [
			SystemTags::BridgeRL,
			SystemTags::BridgeUD,
			SystemTags::AcroBike,
			SystemTags::AcroBikeRL,
			SystemTags::AcroBikeUD,
			SystemTags::AcroBikeBig
		]
		CROSS_BIKE_FLAGS = [CROSS_BIKE_SIDE_JUMP, CROSS_BIKE_TURN_JUMP, CROSS_BIKE_SIDE_JUMP, CROSS_BIKE_BUNNY_HOP, CROSS_BIKE_BIG_BUNNY_HOP]
		def calc_bridge(x, y, bridge_tag, data_bridge, game_map)
			tags = [bridge_tag].flatten
			return unless game_map.one_of_system_tags_here?(x, y, tags)
			for dir in 1..4
				bx = x + (dir == 2 ? -1 : (dir == 3 ? 1 : 0))
				by = y + (dir == 4 ? -1 : (dir == 1 ? 1 : 0))
				alt = SystemTags::ZTag.index(game_map.system_tag(bx, by))
				if alt != nil
					update_bridge_altitude(x, y, alt, tags, data_bridge, game_map)
				end
			end
		end
		def update_bridge_altitude(x, y, alt, tags, data_bridge, game_map)
			open = [[x, y]]
			closed = []
			while open.size > 0
				node = open.shift
				closed.push(node)
				x = node[0]
				y = node[1]
				index = nil
				for tag in tags
					if game_map.system_tag_here?(x, y, tag)
						index = BRIDGES.index(tag)
					end
				end
				data_bridge[x, y, index] = alt
				for dir in 1..4
					bx = x + (dir == 2 ? -1 : (dir == 3 ? 1 : 0))
					by = y + (dir == 4 ? -1 : (dir == 1 ? 1 : 0))
					if game_map.one_of_system_tags_here?(bx, by, tags) and !closed.include?([bx, by])
						index = nil
						for tag in tags
							if game_map.system_tag_here?(bx, by, tag)
								index = BRIDGES.index(tag)
							end
						end
						if data_bridge[bx, by, index] == 0
							open.push [bx, by]
						end
					end
				end
			end
		end
		
		# Slope detection
		def calc_slope_heights(x, y, game_map, data_slopes)
			if game_map.one_of_system_tags_here?(x, y, SystemTags::SlopesTags)
				update_slope_heights(x, y, game_map, data_slopes)
			elsif game_map.one_of_system_tags_here?(x, y, SystemTags::JumpTags)
				data_slopes[x, y, 1] = 48
			end
		end
		def update_slope_heights(x, y, game_map, data_slopes)
			tag = game_map.system_tag(x, y)
			start_x = end_x = x
			start_y = end_y = y
			dir = SystemTags::SlopesTags.index(game_map.system_tag(x, y))
			return unless dir
			dx = (dir == 0 ? -1 : (dir == 1 ? 1 : 0))
			dy = 0
			
			while (game_map.system_tag(start_x, start_y)==tag)
				start_x -= dx
				start_y -= dy
			end
			while (game_map.system_tag(end_x, end_y)==tag)
				end_x += dx
				end_y += dy
			end
			length = (start_x - end_x + start_y - end_y).abs - 1
			step = 128.0 / length.to_f
			for i in 1..length
				slope_x = start_x + i * dx
				slope_y = start_y + i * dy
				data_slopes[slope_x, slope_y, 1] = (step * i.to_f).round
			end
		end
		def calc_slope_heights_from_events(game_map, data_slopes)
			for event in game_map.events_list
				cmd = event.event.pages[0].list[0]
				if cmd.code == 108
					cmd_param = cmd.parameters[0].split(' ')
					if cmd_param[0] == "SLOPE"
						x = event.event.x
						y = event.event.y
						data_slopes[x, y, cmd_param[1].to_i] = cmd_param[2].to_i * 4
					end
				end
			end
		end
		
		
		# >>> Passages detection
		def detect(x, y, z, dir, game_map, data_bridge, data_slopes)
			# In the map
			if !game_map.valid?(x, y)
				return 0
			end
			map = game_map.data
			nx = x + (dir == 4 ? -1 : (dir == 6 ? 1 : 0))
			ny = y + (dir == 8 ? -1 : (dir == 2 ? 1 : 0))
			nnx = nx + (dir == 4 ? -1 : (dir == 6 ? 1 : 0))
			nny = ny + (dir == 8 ? -1 : (dir == 2 ? 1 : 0))
			tag = game_map.system_tag(x, y)
			front_tag = game_map.system_tag(nx, ny)
			front_front_z = (SystemTags::ZTag.index(game_map.system_tag(nnx, nny))==z)
			front_z = (SystemTags::ZTag.index(game_map.system_tag(nx, ny))==z)
			pos_z = (SystemTags::ZTag.index(game_map.system_tag(x, y))==z)
			front_surf = game_map.one_of_system_tags_here?(nx, ny, SystemTags::SurfTags)
			surf = game_map.one_of_system_tags_here?(x, y, SystemTags::SurfTags)

			# Flying and through
			res = THROUGH
			
			# Bridges
			if z > 1
				# Walk bridge
				front_bridge = (data_bridge[nx, ny, 0] == z or data_bridge[nx, ny, 1] == z)
				bridge = (data_bridge[x, y, 0] == z or data_bridge[x, y, 1] == z)
				if ((b = detect_bridge(bridge, front_bridge, front_z, BRIDGE, res)) > 0)
					return b
				end
				
				# Cross Bike bridges
				if (b=detect_cross_bridge(x, y, z, dir, nx, ny, nnx, nny, pos_z, front_z, front_front_z, data_bridge, res)) > 0
					return b
				end
			end
			
			# Map passability
			gm_passable_1 = game_map.passable?(x, y, dir)
			gm_passable_2 = game_map.passable?(nx, ny, 10 - dir)
			
			# Ledges
			if game_map.system_tag_here?(nx, ny, SystemTags::JumpTags[dir/2-1]) and 
					(!surf or (surf and game_map.one_of_system_tags_here?(nnx, nny, SystemTags::SurfTags)))
				if game_map_passable(game_map, map, nnx, nny, 10-dir)
					return res | LEDGE
				else
					return res
				end
			end
			
			# Stairs
			stair = game_map.one_of_system_tags_here?(x, y, SystemTags::StairsTags)
			front_stair = game_map.one_of_system_tags_here?(nx, ny, SystemTags::StairsTags)
			if (stair or front_stair) and !front_surf and !surf
				return detect_stair(gm_passable_1, gm_passable_2, x, y, z, dir, nx, ny, game_map, res)
			end
			
			# Slopes
			slope = game_map.one_of_system_tags_here?(x, y, SystemTags::SlopesTags)
			front_slope = game_map.one_of_system_tags_here?(nx, ny, SystemTags::SlopesTags)
			if slope or front_slope
				return detect_slope(slope, front_slope, gm_passable_1, gm_passable_2, x, y, z, dir, nx, ny, game_map, res, data_slopes)
			end
			
			# Slopes for speed bike test
			mach_bike = game_map.system_tag_here?(x, y, SystemTags::MachBike)
			front_mach_bike = game_map.system_tag_here?(nx, ny, SystemTags::MachBike)
			if mach_bike or front_mach_bike
				return detect_mach_bike(mach_bike, front_mach_bike, gm_passable_1, gm_passable_2, x, y, z, dir, nx, ny, game_map, res, data_slopes)
			end
			
			# Swamps
			swamp = game_map.one_of_system_tags_here?(x, y, SystemTags::SwampsTags)
			front_swamp = game_map.one_of_system_tags_here?(nx, ny, SystemTags::SwampsTags)
			if (swamp or front_swamp) and gm_passable_1 and gm_passable_2 and z <= 1
				return res | SWAMP
			end

			# Tall Grass
			tall_grass = game_map.system_tag_here?(x, y, SystemTags::TTallGrass)
			front_tall_grass = game_map.system_tag_here?(nx, ny, SystemTags::TTallGrass)
			if (tall_grass or front_tall_grass) and gm_passable_1 and gm_passable_2# and z <= 1
				return res | TALL_GRASS
			end

			# Underwater zone
			underwater_zone = game_map.system_tag_here?(x, y, SystemTags::TUnderWater)
			front_underwater_zone = game_map.system_tag_here?(nx, ny, SystemTags::TUnderWater)
			if gm_passable_1 and gm_passable_2 and (underwater_zone or front_underwater_zone)
				return res | UNDERWATER_ZONE
			end

			# Surf & Slide
			ice = game_map.one_of_system_tags_here?(x, y, SystemTags::AllSurfaceSlidingTags)
			front_ice = game_map.one_of_system_tags_here?(nx, ny, SystemTags::AllSurfaceSlidingTags)
			front_ramp = game_map.one_of_system_tags_here?(nx, ny, SystemTags::AllThrowerSlidingTags) 
			front_rapid = game_map.one_of_system_tags_here?(nx, ny, SystemTags::AllStreamSlidingTags)

			front_surf = game_map.one_of_system_tags_here?(nx, ny, SystemTags::SurfTags)
			surf = game_map.one_of_system_tags_here?(x, y, SystemTags::SurfTags)
			waterfall = game_map.system_tag_here?(x, y, SystemTags::WaterFall)
			front_waterfall = game_map.system_tag_here?(nx, ny, SystemTags::WaterFall)
			
			# Surfing
			sliding=(gm_passable_1 and gm_passable_2 and (ice or front_ice or front_rapid or front_ramp))
			sliding_value = res | SLIDING
			surfing_value=detect_surf(x, y, z, nx, ny, dir, game_map, gm_passable_1, gm_passable_2, surf, front_surf, waterfall, front_waterfall, res)
			surfing = (surfing_value != 0)

			if sliding and surfing and (!surf or !front_surf)
				return surfing_value
			end
			if sliding
				return sliding_value
			end
			if surfing
				return surfing_value
			end

			# Cracked Floor
			cracked_floor = game_map.one_of_system_tags_here?(x, y, SystemTags::CrackedFloorTags)
			front_cracked_floor = game_map.one_of_system_tags_here?(nx, ny, SystemTags::CrackedFloorTags)
			if (gm_passable_1 and gm_passable_2 and (cracked_floor or front_cracked_floor))
				return res | CRACKED_FLOOR
			end

			# Grass (Little)
			grass = game_map.system_tag_here?(x, y, SystemTags::TGrass)
			front_grass = game_map.system_tag_here?(nx, ny, SystemTags::TGrass)
			if gm_passable_1 and gm_passable_2 and front_grass
				return res | GRASS
			end
			
			# Walk test
			if gm_passable_1 and gm_passable_2
				return res | WALK
			end
			
			# Return the calculated result
			return res
		end
		
		def game_map_passable(game_map, map, x, y, d)
			bit   = (1 << (d/2 -1)) & 0x0F
			for i in [2, 1, 0]
				tile_id = map[x, y, i]
				if tile_id==nil
					return false
				elsif game_map.passages[tile_id] & bit != 0
					return false
				elsif game_map.passages[tile_id] & 0x0f == 0x0f
					return false
				elsif game_map.priorities[tile_id] == 0
					return true
				end
			end
		end
		
		def detect_bridge(bridge, front_bridge, front_z, flag, res)
			if !bridge and front_bridge 	# Entrance
				# pc "ENTER BRIDGE #{z}"
				return (res | flag)
			elsif bridge and front_bridge 	# Still on bridge
				# pc "STILL ON BRIDGE #{z}"
				return (res | flag)
			elsif bridge and front_z 		# Quit bridge
				# pc "QUIT BRIDGE #{z}"
				return (res | flag)
			elsif bridge and !front_bridge 	# Try to jump off the bridge
				return res
			else
				return -1
			end
		end
		
		def detect_stair(gm_passable_1, gm_passable_2, x, y, z, dir, nx, ny, game_map, res)
			stair = game_map.system_tag(x, y)
			has_stair = SystemTags::StairsTags.include?(stair)
			front_stair = game_map.system_tag(nx, ny)
			has_front_stair = SystemTags::StairsTags.include?(front_stair)
			return res unless has_stair or has_front_stair
			if dir==4 and has_stair and stair==SystemTags::StairsR
				return res | STAIR
			end
			if dir==6 and has_stair and stair==SystemTags::StairsL
				return res | STAIR
			end
			if gm_passable_1 and gm_passable_2
				return res | STAIR
			else
				return res
			end
		end
		
		def detect_slope(slope, front_slope, gm_passable_1, gm_passable_2, x, y, z, dir, nx, ny, game_map, res, data_slopes)
			# if slope
				# update_slope_heights(x, y, z, game_map, data_slopes)
			# end
			front_side_slope = (game_map.one_of_system_tags_here?(nx-1, ny, SystemTags::SlopesTags) or
								game_map.one_of_system_tags_here?(nx+1, ny, SystemTags::SlopesTags))
			if ((!slope and front_slope and gm_passable_2) or
					(slope and !front_slope and gm_passable_1 and (dir == 4 or dir == 6)) or 
					(slope and front_slope and front_side_slope))
				return res | SLOPE
			else
				return res
			end
		end
		
		def detect_mach_bike(mach_bike, front_mach_bike, gm_passable_1, gm_passable_2, x, y, z, dir, nx, ny, game_map, res, data_slopes)
			if mach_bike
				data_slopes[x, y, z] = -32 # 1/4 of max height
			end
			if dir == 8 or dir == 2
				return res | SLIDING_LEDGE
			else
				return res
			end
		end
		
		def detect_cross_bridge(x, y, z, dir, nx, ny, nnx, nny, pos_z, front_z, front_front_z, data_bridge, res)
			front_front_tag = false
			front_tag = false
			front_tag_axis = 0
			tag = false
			tag_axis = 0
			axis = ((dir == 4 or dir == 6) ? 1 : -1)
			for i in 2..5
				if !tag and data_bridge[x, y, i] == z
					tag = BRIDGES[i]
					tag_axis = (tag == SystemTags::AcroBikeRL ? 1 : (tag == SystemTags::AcroBikeUD ? -1 : 0))
				end
				if !front_tag and data_bridge[nx, ny, i] == z
					front_tag = BRIDGES[i]
					front_tag_axis = (front_tag == SystemTags::AcroBikeRL ? 1 : (front_tag == SystemTags::AcroBikeUD ? -1 : 0))
				end
				if !front_front_tag and data_bridge[nnx, nny, i] == z
					front_front_tag = BRIDGES[i]
				end
			end
			
			return -1 if (!tag and !front_tag)
			
			if (tag or pos_z) and front_tag==SystemTags::AcroBikeBig
				return res | CROSS_BIKE_BIG_BUNNY_HOP
			elsif tag == SystemTags::AcroBikeBig and (front_tag or front_z) and (front_front_tag or front_front_z)
				return res | CROSS_BIKE_BIG_BUNNY_HOP
			elsif tag == SystemTags::AcroBike and (front_tag or front_z)
				return res | CROSS_BIKE_BUNNY_HOP
			elsif (tag or pos_z) and front_tag==SystemTags::AcroBike
				return res | CROSS_BIKE_BUNNY_HOP
			elsif tag_axis == axis and (tag==front_tag or front_z)
				return res | CROSS_BIKE_STRAIGHT
			elsif pos_z and front_tag_axis==axis
				return res | CROSS_BIKE_STRAIGHT
			elsif tag_axis != axis and (tag == front_tag or front_z)
				return res | CROSS_BIKE_SIDE_JUMP
			elsif tag and front_tag and tag != front_tag
				return res | CROSS_BIKE_TURN_JUMP
			end
			return res
		end

		def detect_surf(x, y, z, nx, ny, dir, game_map, gm_passable_1, gm_passable_2, surf, front_surf, waterfall, front_waterfall, res)
			if (waterfall or front_waterfall)
				return res | WATERFALL
			elsif gm_passable_1 and gm_passable_2
				if (surf and !front_surf) or (!surf and front_surf)
					return res | SURF_TRANSITION
				elsif surf and front_surf
					return res | WALK
				end
			end
			return 0
		end
		
		# =================================
		# >>> Debug
		def self.display_infos
			pcc "#{@@tested_count.to_s.reverse.gsub(/(.{3})(?=.)/, '\1 \2').reverse} passages tested", 0x02
		end
		
		def make_some_test(data_bridge)
			return
			texts = ["BRIDGES", "DIR 2 (DOWN MOVES)", "DIR 4 (LEFT MOVES)", "DIR 6 (RIGHT MOVES)", "DIR 8 (UP MOVES)"]
			for d in 0..4
				first_line_complete = false
				first_line = "   "
				lines = []
				for y in 10..41
					line = sprintf("%02d ", y)
					up_line="   "
					for x in 10..35
						first_line += sprintf("%02d ", x) unless first_line_complete
						if d == 0
							part = "   "
							if data_bridge[x, y, 2] == 6
								part = " O "
							end
							if data_bridge[x, y, 3] == 6
								part = "---"
							end
							if data_bridge[x, y, 4] == 6
								part = " | "
							end
							if data_bridge[x, y, 5] == 6
								part = "<O>"
							end
							line += part
						else
							dir = d*2
							part = "   "
							res = compare(CROSS_BIKE_STRAIGHT | CROSS_BIKE_SIDE_JUMP | CROSS_BIKE_TURN_JUMP | CROSS_BIKE_BUNNY_HOP | CROSS_BIKE_BIG_BUNNY_HOP, x, y, 6, dir)
							if (res & CROSS_BIKE_BUNNY_HOP) > 0
								part = " B "
							end
							if (res & CROSS_BIKE_BIG_BUNNY_HOP) > 0
								part = "<B>"
							end
							if (res & CROSS_BIKE_TURN_JUMP) > 0
								part = " T "
							end
							if (res & CROSS_BIKE_SIDE_JUMP) > 0
								part = " J "
							end
							if (res & CROSS_BIKE_STRAIGHT) > 0
								part = " S "
							end
							if part != "   "
								up_line += " #{[' ', 'v', '<', '>', '^'][d]} "
							else
								up_line += "   "
							end
							line += part
						end
					end
					first_line_complete = true
					lines.push up_line
					lines.push line
				end
				lines.unshift first_line
				lines.unshift texts[d]
				pc lines.join("\n")
			end
		end
		
		
		@@tested_count = 0
	end
end