module GameData
	module SystemTags
		# SystemTag where there is a slope to the left
		SlopeL = gen 7, 3
		# SystemTag where there is a slope to the right
		SlopeR = gen 7, 4
		# SystemTag where the bunny hop is required and jump over 2 case instead of one
		AcroBikeBig = gen 7, 5
		# Sliding tag where the Game_Character slide on it with spining
		SpinIce = gen 4, 7
		# Sliding tag where the Game_Character slide on it without spining until came obstacle
		RocketRampL = gen 0, 6
		# Sliding tag where the Game_Character slide on it without spining until came obstacle
		RocketRampD = gen 1, 6
		# Sliding tag where the Game_Character slide on it without spining until came obstacle
		RocketRampU = gen 2, 6
		# Sliding tag where the Game_Character slide on it without spining until came obstacle
		RocketRampR = gen 3, 6
		# Sliding tag where the Game_Character slide on it with spining until came obstacle
		SpinRocketRampL = gen 4, 6
		# Sliding tag where the Game_Character slide on it with spining until came obstacle
		SpinRocketRampD = gen 5, 6
		# Sliding tag where the Game_Character slide on it with spining until came obstacle
		SpinRocketRampU = gen 6, 6
		# Sliding tag where the Game_Character slide on it with spining until came obstacle
		SpinRocketRampR = gen 7, 6
		# Sliding tag where the Game_Character slide on it with spining until there is no sliding tag or obstacle
		SpinRapidsL = gen 0, 7
		# Sliding tag where the Game_Character slide on it with spining until there is no sliding tag or obstacle
		SpinRapidsD = gen 1, 7
		# Sliding tag where the Game_Character slide on it with spining until there is no sliding tag or obstacle
		SpinRapidsU = gen 2, 7
		# Sliding tag where the Game_Character slide on it with spining until there is no sliding tag or obstacle
		SpinRapidsR = gen 3, 7
		# Soil, floor will crack when walk on it but not detected by counter
		WillCrackSoil = gen 1, 2

		# All the jump tag (ledges) /!\ Don't touch the order /!\
		JumpTags = [JumpD, JumpL, JumpR, JumpU]
		# All the surf tags
		SurfTags = [TPond, TSea]
		# All the system tags requiring cross bike
		CrossBikeBalanceTags = [AcroBikeRL, AcroBikeUD]
		# All the system tags requiring bunny hop
		CrossBikeBunnyHopTags = [AcroBike, AcroBikeBig]
		# All the stairs /!\ Don't touch the order /!\
		StairsTags = [StairsD, StairsL, StairsR, StairsU]
		# All the slopes tags
		SlopesTags = [SlopeL, SlopeR]
		# All the swamp tags
		SwampsTags = [SwampBorder, DeepSwamp]
		# All the sliding ram tags, no spinning
		ThrowerSlidingTags 	= [RocketRampD, RocketRampL, RocketRampR, RocketRampU]
		# All the sliding surface tags, no spinning
		SurfaceSlidingTags 	= [TIce]
		# All the sliding stream tags, no spinning
		StreamSlidingTags 	= [RapidsD, RapidsL, RapidsR, RapidsU]
		# All the sliding ramp tags, with spinning
		SpinThrowerSlidingTags = [SpinRocketRampD, SpinRocketRampL, SpinRocketRampR, SpinRocketRampU]
		# All the sliding surface tags, with spinning
		SpinSurfaceSlidingTags 	= [SpinIce]
		# All the sliding stream tags, with spinning
		SpinStreamSlidingTags 	= [SpinRapidsD, SpinRapidsL, SpinRapidsR, SpinRapidsU]
		# All the sliding surface tags
		AllSurfaceSlidingTags = SurfaceSlidingTags + SpinSurfaceSlidingTags
		# All the sliding stream tags
		AllStreamSlidingTags = StreamSlidingTags + SpinStreamSlidingTags
		# All the sliding ramp tags
		AllThrowerSlidingTags = ThrowerSlidingTags + SpinThrowerSlidingTags
		# All the spinning sliding tags
		AllSpinSlidingTags = SpinThrowerSlidingTags + SpinSurfaceSlidingTags + SpinStreamSlidingTags
		# All the sliding tags
		AllSlidingTags = AllSpinSlidingTags + ThrowerSlidingTags + SurfaceSlidingTags + StreamSlidingTags
		# All the cracked floor tags
		CrackedFloorTags = [WillCrackSoil, CrackedSoil, Hole]
	end
end