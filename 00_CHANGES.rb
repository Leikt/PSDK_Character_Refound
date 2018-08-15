=begin
Changelog
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>> CHANGEMENT EN DEHORS DE GAME_CHARCATER >>>
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


______________________________________________
>>> PFM::Environment >>>>>>>>>>>>>>>>>>>>>>>>>
    # Can the player fish ?
    # @return [Boolean]
    def can_fish?
      gp = $game_player
      return (
        gp.z <= 1 and
        gp.can_move?(gp.x, gp.y, gp.direction)>=0 and 
        $game_map.one_of_system_tags_here?(gp.front_x, gp.front_y, SurfTags)
      )
    end

______________________________________________
>>> PFM::ItemDescriptor >>>>>>>>>>>>>>>>>>>>>>>>>
		22 => proc {st = $game_player.front_system_tag
                st == TPond or st == TSea},
    23 => proc {st = $game_player.front_system_tag
                st == TPond or st == TSea},
    24 => proc {st = $game_player.front_system_tag
								st == TPond or st == TSea},
> DEVIENT
    22 => proc {$pokemon_party.env.can_fish?},
    23 => proc {$pokemon_party.env.can_fish?},
    24 => proc {$pokemon_party.env.can_fish?},

______________________________________________
>>> Yuki::Sw >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# false => Character's shadow are visible during the jump, true => they are not 
NO_SHADOW_DURING_JUMP = 29

______________________________________________
>>> Yuki::Var >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Set the next transition tone change for TJN
TJN_Tone_Duration = 33

______________________________________________
>>> Game_Map >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
attr_reader :passabilities

def initialize
  # Normal
  @events_to_add = []
end

# > Optimisation (1000% sur map chargée d'event)
remplacement de tous les @events.values, @events.each_value, $game_map.events.values par @events_list (sauf le @events_list = @events.values)

______________________________________________
>>> Spriteset_Map >>>>>>>>>>>>>>>>>>>>>>>>>>>>
def init_player
    @character_sprites.delete(@game_player_sprite)
    # Normal
end

dans l'update
  sprite.update if ((e.x - x).abs <= 13 and (e.y - y).abs <= 13)
devient
  sprite.update if(((e.x - x).abs <= 13 and (e.y - y).abs <= 13) or e.always_displayed)

def setup(map_id)
    unless analyze
      MapsNavigation.drop(@map_id)
      @passabilities = MapsNavigation.get(map_id)
    end
	# (...) Setup normal
	@events_list = @events.values
end

def refresh
  add_events
  # normal
end

______________________________________________
>>> Sprite_Character >>>>>>>>>>>>>>>>>>>>>>>>>
	a = character.instance_variable_get(:@event)
	if(a and a.name.index(Sup_Tag)==0)
	  @add_z = 2
	elsif($game_switches[::Yuki::Sw::CharaShadow])
	  @add_z = 0
	  if(!a or a.name.index(Shadow_Tag)!=0)
		init_shadow
	  end
	else
	  @add_z = 0
	end
>>> DEVIENT
	if character.superposition_p1
	  @add_z = 2
	elsif($game_switches[::Yuki::Sw::CharaShadow])
	  @add_z = 0
	  unless character.no_shadow
		init_shadow
	  end
	else
	  @add_z = 0
  end

  
  Modification du pseudo anti-lag => la fonctionnalité Always displayed
    # Pseudo anti-lag
    if @character.always_displayed
      self.visible =true
    else
      _x -= self.ox
      _y -= self.oy
      rc = self.viewport.rect
      if _x > rc.width or _y > rc.height or (_x + self.width) < 0 or (_y + self.height) < 0
        @shadow.visible = false if @shadow
        return self.visible = false
      else
        self.visible = true
      end
    end

>>>>>>> UPDATE_SHADOW
	def update_shadow
> AJOUTER APRES
	if @character.no_shadow
		@shadow.visible = false
		return
	end
	
>>>>>>>> UPDATE
    self.z = (@character.screen_z(@ch) + @add_z)# / @zoom
>>> DEVIENT
		self.z = (@character.screen_z + @add_z)# / @zoom ::: Le paramètre height de screen_z étant ignoré
		

		self.src_rect.set(@character.pattern * @cw, (@character.direction - 2) / 2 * @ch, 
			@cw, @ch)
>>> DEVIENT
		self.src_rect.set(@character.pattern * @cw, (@character.direction - 2) / 2 * @ch, 
			@cw, @ch-@character.blank_depth)
	
			à la fin juste avant l'update_bush_depth :
			
    @blank_depth = @character.blank_depth
    update_blank_depth if @blank_depth > 0
    
    Avant le update_shadow
    >>> init_shadow unless (@shadow or @character.no_shadow)
		
		ajouter la fonction
  def update_blank_depth
    self.src_rect.height = (@ch-@character.blank_depth)
  end

---------------
	@shadow.visible = !@character.jumping? #> Ajout saut
>>> DEVIENT
	 @shadow.visible = !(@character.no_shadow or 
        (@character.jump_type_moving? and $game_switches[Yuki::Sw::NO_SHADOW_DURING_JUMP]))

______________________________________________
>>> Pokemon_Party >>>>>>>>>>>>>>>>>>>>>>>>>>
Fin expend_global_variables
      #>Patch 2018-07-29
			@particle_selection=Hash.new(0) unless @particle_selection
	
init, avant expend_global_variable
			@particle_selection = Hash.new(0)
			
à la fin de init
      MapsNavigation.main_analyze

______________________________________________
>>> Yuki::Particles >>>>>>>>>>>>>>>>>>>>>>>>>>
Remplacement de la définition des data
	Data=Array.new
    Data[0]=Hash.new
    Data[0][1]={#,:oy_offset=>-2
    :sound_files=>["Audio/particles/grass01_a","Audio/particles/grass01_b"],
    :enter=>{:max_counter=>16,:data=>[nil,nil,nil,nil,{:file=>"Herbe",:rect=>[0,0,16,16],:zoom=>1,:position=>:center_pos, :sound=>[40]},nil,nil,nil,{:rect=>[0,16,16,16]},nil,nil,nil,{:rect=>[0,32,16,16]},nil,nil,nil,{:rect=>[0,48,16,16]}],:loop=>false},
    :stay =>{:max_counter=>1,:data=>[{:file=>"Herbe",:zoom=>1,:position=>:center_pos,:rect=>[0,48,16,16]}],:loop=>false},
    :leave=>{:max_counter=>1,:data=>[],:loop=>false}}
    Data[0][2]={
    :enter=>{:max_counter=>8,:data=>[nil,nil,nil,{:file=>"HauteHerbe",:zoom=>1,:position=>:center_pos}],:loop=>false},
    :stay =>{:max_counter=>1,:data=>[{:file=>"HauteHerbe",:zoom=>1,:position=>:center_pos}],:loop=>false},
    :leave=>{:max_counter=>1,:data=>[],:loop=>false}}
		Data[0][:dust] = {
    :sound_files => ["Audio/particles/jump"],
		:enter=>{:max_counter=>20,:data => 
    [
      {:file=>"dust",:rect=>[0,0,16,8],:zoom=>1,:position=>:center_pos, :add_z => 8},
      nil, nil, nil, nil, nil,{:rect=>[16, 0, 16, 8], :sound=>[40]},
      nil, nil, nil, nil, nil,{:rect=>[32, 0, 16, 8]},
      nil, nil, nil, nil, nil,{:state=>:leave}
    ],
		:loop=>false},
		:leave =>Data[0][2][:leave]}

Fonction add_particles (ajout de use_sound)
    # Add a particle to the stack
    # @param character [Game_Character] the character on which the particle displays
    # @param tag [Integer] the index of the particle in the particle data
    def add_particle(character,tag, use_sound = false, set = nil)
      return unless @stack
      if $game_variables[Var::PAR_DatID] != 0
        pcc "Using the variable #{Var::PAR_DatID} is deprecated, use select_set instead", 0x3
      end
      if a=Data[tag]
        if a=a[(set ? set : $pokemon_party.particle_selection[tag])]
          @stack.push(Particle_Object.new(character,a,@on_teleportation, use_sound)) if character.character_name and character.character_name.size>0
        end
      end
    end

		Fonction de selection du set
    def select_set(tag, key)
      $pokemon_party.particle_selection[tag] = key
    end

Initialize de ParticleObject
>>> Initialization de la variable de classe pour varier les sons produits 
    @@sound_counter = 0
	def initialize(character,data,on_tp=false, use_sound=false)
>>> après les coordonnées
     @slope_height = character.slope_height
>>> à la fin de l'intialize
	if use_sound and (@sound_files = data[:sound_files])
		@sound_count = @sound_files.size
    end
>>> execute_action après la partie file
	if @sound_files and d=action[:sound]
		@@sound_counter = (@@sound_counter + 1) % @sound_count
		if (sf = @sound_files[@@sound_counter])
			Audio.se_play(d.fetch(2, sf), d.fetch(0,100), d.fetch(1,100)-5 + rand(10))
		end
	end
	
>>> update_sprite_position (ajout de la slope au calcul)
	@sprite.y=((@y*128 - @slope_height - $game_map.display_y + 3) / 4 + 32)

Ajout de Ox_offset
dans l'initialize
			@ox_off=0

dans execute_action
après la même condition pour oy
      if d=action[:ox_offset]
        @ox_off=d
      end

update sprite position
				@sprite.ox=@ox * @zoom + @ox_off
				et
        @sprite.ox=@ox+@ox_off

______________________________________________
>>> GamePlay::Load >>>>>>>>>>>>>>>>>>>>>>>>>>>
fin de load_game
      MapsNavigation.main_analyze
______________________________________________
>>> Interpreter >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  attr_accessor :wait_count
  # Return the started event
  # @return [Game_Event]
  def this
		return $game_map.events[@event_id]
  end

______________________________________________
>>> Yuki::TJN >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    def get_tone_transition_duration
      if @forced
          if $game_variables[Yuki::Var::TJN_Tone_Duration].positive?
            return $game_variables[Yuki::Var::TJN_Tone_Duration]
          else
            return 0
          end
        end
        return 20
    end

    Ligne 70 :
  Remplacer par
      t=get_tone_transition_duration
      @forced=false
      $game_variables[33] = 0

______________________________________________
>>> Game_SelfVariables >>>>>>>>>>>>>>>>>>>>>>>
Intégration des ids changés par le MapLinker
def get_local_variable(*args)
    event = $game_map.events[@event_id]
    return unless event
    event = event.event
    mid = (event.original_map || $game_map.map_id)
    eid = (event.original_id || @event_id)
    if args.first.is_a?(Symbol) # [var_loc, operation, value]
      return $game_self_variables.do([mid, eid, args.first], args[1], args[2])
    elsif args[1].is_a?(Integer)# [map_id, event_id, var_loc, operation, value]
      return $game_self_variables.do([args.first, args[1], args[2]], args[3], args[4])
    else # [event_id, var_loc, operation, value]
      return $game_self_variables.do([mid, args.first, args[1]], args[2], args[3])
    end
    $game_map.need_refresh = true
    return nil
  end
  def set_local_variable(value, id_var, id_event = nil, id_map = nil)
    event = $game_map.events[@event_id]
    return unless event
    event = event.event
    mid = (event.original_map || $game_map.map_id) unless id_map
    eid = (event.original_id || @event_id) unless id_event
    key = [mid, eid, id_var]
    $game_self_variables[key] = value
  end

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>> EVENT COMMUNS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
2 	> Apparence héros
8   > Trou
9   > Entrée surf
10  > Sortie surf
11 	> Bicyclette
33	> Velo Cross
22  > Canne
23  > Super Canne
24  > Mega Canne


>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>> CREDITS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
> Zeus81
Images & sons des particules


>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>> FICHIERS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
system_tag modifié
particles => dust.png
particles => floor_print.png
particles => surf_print.png
particles => emotion2.png
particles => Audio/particles/
son SE => fall.wav
son SE => waterfall
son SE => jump
son SE => dringdring
son SE => watersound001
son Particle => waterfall


=end