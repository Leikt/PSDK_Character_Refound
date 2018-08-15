class Game_Map
	# <Optimisation> alter solution to events.values
	attr_reader :events_list
	# [MapNavigation] navigation data of the map
	attr_reader :passabilities
	# Change the navigation data
	# @param pass [MapsNavigation::MapNavigation] new datas
	def set_passabilities(pass)
		@passabilities = pass
	end
	# Test if one the the given system tags are here
	# @param x [Integer] tested x
	# @param y [Integer] tested y
	# @param arr [Array<Integer>] tested tags list
	# @return [Boolean]
	# @author Leikt
	def one_of_system_tags_here?(x, y, arr)
		for tag in arr
			return true if system_tag_here?(x, y, tag)
		end
		return false
	end
	# Get all the system tags at given coords
	# @param x [Integer] x coord
	# @param y [Integer] y coord
	# @return [Array<Integer>] tag list
	# @author Leikt
	def get_system_tags(x, y)
		res = []
		if @map_id != 0
			tiles = self.data
			2.downto(0) do |i|
				tile_id = tiles[x, y, i]
				next unless tile_id
				tag_id = @system_tags[tile_id]
				res.push tag_id if (tag_id and tag_id > 0)
			end
		end
		return res
	end
	# Get all the system tags at given coords if they are in the filter
	# @param x [Integer] x coord
	# @param y [Integer] y coord
	# @param filter [Array<Integer>] the filter
	# @return [Array<Integer>] tag list
	# @author Leikt
	def get_filtered_system_tags(x, y, filter)
		res = []
		if @map_id != 0
			tiles = self.data
			2.downto(0) do |i|
				tile_id = tiles[x, y, i]
				next unless tile_id
				tag_id = @system_tags[tile_id]
				res.push tag_id if (tag_id and tag_id > 0 and filter.include?(tag_id))
			end
		end
		return res
	end
	# Dynamicly add event to the map
	# @param event [Game_Event] event to add
	# @author Leikt
	def add_event(event)
		@events_to_add.push event
		@need_refresh = true
	end
	# Effectivly add the events to map
	# @author Leikt
	def add_events
		return if @events_to_add.empty?
		id = 0
		until @events_to_add.empty?
			0 while @events.has_key?(id+=1)
			event = @events_to_add.pop
			@events[id] = event
			event.id = id
			$scene.spriteset.add_event(event)
		end
		@events_list = @events.values
	end
	# Dynamicly delete events from the map
	# @param event [Game_Event] event to delete
	# @author Leikt
	def delete_event(event)
		@events.delete_if {|k, v| event==v}
		@events_list = @events.values
		$scene.spriteset.delete_event(event)
	end
	def increase_tagged_tile_id(x, y, tags)
		tiles = self.data
		2.downto(0) do |z|
			tile_id = tiles[x, y, z]
			next unless tile_id
			tag_id = @system_tags[tile_id]
			if tags.include?(tag_id)
				tiles[x, y, z] = (tiles[x, y, z] + 1)
			end
		end
	end
end