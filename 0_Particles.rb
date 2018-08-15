module Yuki
    module Particles
        # Particles data
        # Hash {sym_particle_name => [data_type_1, data_type_2, ...]}
        Data=Hash.new

        Data[:grass]=Array.new
        Data[:grass][0]= { 
            :sound_files=>["Audio/particles/grass01_a","Audio/particles/grass01_b"],
            :enter  =>{:max_counter=>1, :loop=>false, :data=>[{:sound=>[40]}]},
            :stay   =>{:max_counter=>1, :loop=>false, :data=>[]},
            :leave  =>{:max_counter=>32, :loop=>false, :data=>[{:file=>"herbe", :rect=>[0,32,16,16], :zoom=>1, :position=>:center_pos}, [nil]*4, {:rect=>[0,0,16,16]}, [nil]*4, {:rect=>[0,16,16,16]}, [nil]*4, {:rect=>[0,32,16,16]}, [nil]*4, {:rect=>[0,48,16,16]}].flatten(1)}
        }
        Data[:grass][1]= { 
            :sound_files=>["Audio/particles/grass01_a","Audio/particles/grass01_b"],
            :enter  =>{:max_counter=>1, :loop=>false, :data=>[{:sound=>[40]}]},
            :stay   =>{:max_counter=>1, :loop=>false, :data=>[]},
            :leave  =>{:max_counter=>32, :loop=>false, :data=>[{:file=>"herbe_old", :rect=>[0,32,16,16], :zoom=>1, :position=>:center_pos}, [nil]*4, {:rect=>[0,0,16,16]}, [nil]*4, {:rect=>[0,16,16,16]}, [nil]*4, {:rect=>[0,32,16,16]}, [nil]*4, {:rect=>[0,48,16,16]}].flatten(1)}
        }
        Data[:grass][2]= { 
            :sound_files=>["Audio/particles/grass01_a","Audio/particles/grass01_b"],
            :enter  =>{:max_counter=>1, :loop=>false, :data=>[{:sound=>[40]}]},
            :stay   =>{:max_counter=>1, :loop=>false, :data=>[]},
            :leave  =>{:max_counter=>32, :loop=>false, :data=>[{:file=>"herbehg", :rect=>[0,32,16,16], :zoom=>1, :position=>:center_pos}, [nil]*4, {:rect=>[0,0,16,16]}, [nil]*4, {:rect=>[0,16,16,16]}, [nil]*4, {:rect=>[0,32,16,16]}, [nil]*4, {:rect=>[0,48,16,16]}].flatten(1)}
        }

        Data[:tall_grass]=Array.new
        Data[:tall_grass][0]={
            :sound_files=>["Audio/particles/grass01_a","Audio/particles/grass01_b"],
            :enter  =>{:max_counter=>01, :loop=>false, :data=>[{:sound=>[40]}]},
            :stay   =>{:max_counter=>01, :loop=>false, :data=>[]},
            :leave  =>{:max_counter=>01, :loop=>false, :data=>[]}
        }

        Data[:dust]=Array.new
        Data[:dust][0]={
            :sound_files=>["Audio/particles/jump"],
            :enter  =>{:max_counter=>20, :loop=>false, :data=>[{:file=>"dust", :rect=>[0,0,16,8], :zoom=>1, :position=>:center_pos, :add_z=>2}, [nil]*5, {:rect=>[16,0,16,8], :sound=>[40]},
                        [nil]*5, {:rect=>[32,0,16,8]}, [nil]*5, {:rect=>[48,0,1,1]}].flatten(1)},
            :stay   =>{:max_counter=>01, :loop=>false, :data=>[]},
            :leave  =>{:max_counter=>01, :loop=>false, :data=>[]},
        }
        Data[:dust][1]={
            :enter  =>{:max_counter=>20, :loop=>false, :data=>[{:file=>"dust", :rect=>[0,0,16,8], :zoom=>1, :position=>:center_pos, :add_z=>2}, [nil]*5, {:rect=>[16,0,16,8]},
                        [nil]*5, {:rect=>[32,0,16,8]}, [nil]*5, {:rect=>[48,0,1,1]}].flatten(1)},
            :stay   =>{:max_counter=>01, :loop=>false, :data=>[]},
            :leave  =>{:max_counter=>01, :loop=>false, :data=>[]},
        }

        TRACK_OPACITY_FADING = [[nil]*17, {:opacity=>115},[nil]*17, {:opacity=>100},[nil]*17, {:opacity=>85},[nil]*17, {:opacity=>70},[nil]*17, {:opacity=>55},[nil]*17, {:opacity=>40},[nil]*17, {:opacity=>25},[nil]*17, {:opacity=>10},[nil]*17, {:opacity=>0}].flatten(1)
        Data[:sand_d]=Array.new
        Data[:sand_d][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>180, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[0, 0, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>125}, TRACK_OPACITY_FADING].flatten(1)}
        }
        Data[:sand_l]=Array.new
        Data[:sand_l][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>180, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[16, 0, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>125}, TRACK_OPACITY_FADING].flatten(1)}
        }
        Data[:sand_r]=Array.new
        Data[:sand_r][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>180, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[32, 0, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>125}, TRACK_OPACITY_FADING].flatten(1)}
        }
        Data[:sand_u]=Array.new
        Data[:sand_u][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>180, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[48, 0, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>125}, TRACK_OPACITY_FADING].flatten(1)}
        }

        
        DELAY = [nil]*8
        Data[:pond]=Array.new
        Data[:pond][0]={
            :enter  => {:max_counter=>01, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>01, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>8*8+4, :loop=>false, :data=>[{:file=>"surf_print", :rect=>[0,0,16,16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>255}, 
                    DELAY, {:rect=>[16,0,16,16]}, DELAY, {:rect=>[32,0,16,16]}, DELAY, {:rect=>[48,0,16,16]}, DELAY, {:rect=>[64,0,16,16]}, DELAY, {:rect=>[80,0,16,16]}, DELAY, {:rect=>[96,0,16,16]}
                    ].flatten(1)}
        }

        TRACK_SNOW_OPACITY_FADING = [[nil]*9, {:opacity=>240},[nil]*9, {:opacity=>225},[nil]*9, {:opacity=>210},[nil]*9, {:opacity=>195},[nil]*9, {:opacity=>180},[nil]*9, 
                                {:opacity=>165},[nil]*9, {:opacity=>150},[nil]*9, {:opacity=>135},[nil]*9, {:opacity=>120},[nil]*9, {:opacity=>105},[nil]*9, {:opacity=>90},
                                [nil]*9, {:opacity=>75},[nil]*9, {:opacity=>60},[nil]*9, {:opacity=>45},[nil]*9, {:opacity=>30},[nil]*9, {:opacity=>15},[nil]*9, {:opacity=>0}
                                ].flatten(1)
        Data[:snow_d]=Array.new
        Data[:snow_d][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>181, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[0, 16, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>250}, TRACK_SNOW_OPACITY_FADING].flatten(1)}
        }
        Data[:snow_l]=Array.new
        Data[:snow_l][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>180, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[16, 16, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>125}, TRACK_SNOW_OPACITY_FADING].flatten(1)}
        }
        Data[:snow_r]=Array.new
        Data[:snow_r][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>181, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[32, 16, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>250}, TRACK_SNOW_OPACITY_FADING].flatten(1)}
        }
        Data[:snow_u]=Array.new
        Data[:snow_u][0]={
            :enter  => {:max_counter=>001, :loop=>false, :data=>[]},
            :stay   => {:max_counter=>001, :loop=>false, :data=>[]},
            :leave  => {:max_counter=>180, :loop=>false, :data=>[{:file=>"floor_print", :rect=>[48, 16, 16, 16], :zoom=>1, :add_z=>0, :position=>:center_pos, :opacity=>125}, TRACK_SNOW_OPACITY_FADING].flatten(1)}
        }

        WAITING_DELAY = 60
        Data[:waiting_1]=Array.new
        Data[:waiting_1][0]={
            :enter  =>{:max_counter=>WAITING_DELAY,:loop=>false,:data => 
                [{:file=>"emotions2",:rect=>[0,0,16,16],:zoom=>1,:position=>:center_pos, :oy_offset => 25, :add_z=>2}]},
            :stay   =>{:max_counter=>2, :loop=>false, :data=>[{:state => :leave}]},
            :leave  =>{:max_counter=>1, :loop=>false, :data=>[]}
        }

        Data[:waiting_2]=Array.new
        Data[:waiting_2][0]={
            :enter  =>{:max_counter=>WAITING_DELAY,:loop=>false,:data => 
                [{:file=>"emotions2",:rect=>[16,0,16,16],:zoom=>1,:position=>:center_pos, :oy_offset => 25, :add_z=>2}]},
            :stay   =>{:max_counter=>2, :loop=>false, :data=>[{:state => :leave}]},
            :leave  =>{:max_counter=>1, :loop=>false, :data=>[]}
        }

        Data[:waiting_3]=Array.new
        Data[:waiting_3][0]={
            :enter  =>{:max_counter=>WAITING_DELAY,:loop=>false,:data => 
                [{:file=>"emotions2",:rect=>[32,0,16,16],:zoom=>1,:position=>:center_pos, :oy_offset => 25, :add_z=>2}]},
            :stay   =>{:max_counter=>2, :loop=>false, :data=>[{:state => :leave}]},
            :leave  =>{:max_counter=>1, :loop=>false, :data=>[]}
        }

        Data[:exclamation] = Array.new
        Data[:exclamation][0]={
            :enter=>{:max_counter=>36,:data => 
            [{:file=>"emotions",:rect=>[0,0,16,16],:zoom=>1,:position=>:center_pos, :add_z => 2, :oy_offset => 0},
            nil,{:oy_offset => 2},
            nil,{:oy_offset => 4},
            nil,{:oy_offset => 8},
            nil,{:oy_offset => 12},
            nil,{:oy_offset => 16, :add_z => 64},
            nil,{:oy_offset => 20},
            nil,{:oy_offset => 24},
            nil,{:oy_offset => 20}],
            :loop=>false},
            :stay=>{:max_counter=>2,:data=>[{:state => :leave}], :loop=>false},
            :leave =>{:max_counter=>1, :loop=>false, :data=>[]}}
        Data[:exclamation][1]={
            :sound_files=>["Audio/particles/exclamation"],
            :enter  =>{:max_counter=>120,:loop=>false,:data => 
                [{:file=>"emotions",:rect=>[0,16,16,16],:zoom=>1,:position=>:center_pos, :add_z => 64, :oy_offset => 25, :sound=>[100]}, [nil]*4, {:rect=>[16,16,16,16]}, [nil]*10, {:rect=>[0,16,16,16]}, 
                    [nil]*15, {:rect=>[16,16,16,16]}, [nil]*10, {:rect=>[0,16,16,16]}, [nil]*15, {:rect=>[16,16,16,16]}, [nil]*8, {:rect=>[0,16,16,16]}, [nil]*15, {:rect=>[16,16,16,16]}, 
                    [nil]*8, {:rect=>[0,16,16,16]}].flatten(1)},
            :stay   =>{:max_counter=>2, :loop=>false, :data=>[{:state => :leave}]},
            :leave  =>{:max_counter=>1, :loop=>false, :data=>[]}
        }

        counter = 0
        bubble_timer = 90
        bubble_route = []
        while counter < bubble_timer
            counter+=1
            if counter%4==0
                part = {:oy_offset=>[:add, 2]}# (25+2*(counter/4))}
                rad = (Math::PI * ((3.0 * counter).to_f/(bubble_timer)))
                part[:ox_offset]=[:add_sign_rand, (Math.sin(rad)*1.0).round]
                if counter > 40
                    opacity = 255.0 * (1.0 - (counter-40).to_f/(bubble_timer-40))
                    part[:opacity]=opacity.round
                end
                bubble_route.push(part)
            else
                bubble_route.push(nil)
            end
        end
        Data[:bubble] = Array.new
        Data[:bubble][0] = {
            :enter  =>{:max_counter=>bubble_timer,:loop=>false,:data=>[{:file=>"bulles", :rect=>[[0,0,4,4], [4,0,4,4]], :zoom=>1, :position=>:throw_position, :oy_offset=>25, :opacity=>255, :ox_offset=>[:range, -1,12], :add_z=>64}, bubble_route].flatten(1)},
            :stay   =>{:max_counter=>1, :loop=>false, :data=>[{:state=>:leave}]},
            :leave  =>{:max_counter=>1, :loop=>false, :data=>[]}
        }
        Data[:bubble][1] = {
            :enter  =>{:max_counter=>bubble_timer,:loop=>false,:data=>[{:file=>"bulles", :rect=>[[0,0,4,4], [4,0,4,4]], :zoom=>1, :position=>:throw_position, :ox_offset=>[:range, -3,18], :opacity=>255, :add_z=>64}, bubble_route].flatten(1)},
            :stay   =>{:max_counter=>1, :loop=>false, :data=>[{:state=>:leave}]},
            :leave  =>{:max_counter=>1, :loop=>false, :data=>[]}
        }

        Data[:splash_water] = Array.new
        Data[:splash_water][0] = {
            :sound_files=>["Audio/particles/diving"],
            :enter  =>{:max_counter=>(1+15*5), :loop=>false,:data=>[{:file=>"eclaboussures", :rect=>[0,0,40,7], :zoom=>1, :position=>:center_pos, :add_z=>32, :ox_offset=>-11, :sound=>[150]},
                        [[nil]*4, {:rect=>[40,0,40,7]}, [nil]*4, {:rect=>[80,0,40,7]}, [nil]*4, {:rect=>[0,0,40,7]}].flatten(1)*5].flatten(1)},
            :stay   =>{:max_counter=>1, :loop=>false,:data=>[{:state=>:leave}]},
            :leave  =>{:max_counter=>1, :loop=>false,:data=>[]}
        }
            
        emotion_str = '
        Data[:£1]=Array.new
        Data[:£1][0]={
            :enter=>{:max_counter=>60,:data =>[{:file=>"emotions",:rect=>[£3,£2,16,16],:zoom=>1,:position=>:center_pos, :oy_offset => 10},
                nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
                {:rect=>[£4,£2,16,16]}],:loop => false},
            :stay => Data[:exclamation][0][:stay],
            :leave =>{:max_counter=>1, :loop=>false, :data=>[]}
        }'
        module_eval(emotion_str.gsub('£1', 'poison').gsub('£2', '0').gsub('£3','32').gsub('£4','48'))
        module_eval(emotion_str.gsub('£1', 'exclamation2').gsub!('£2', '16').gsub!('£3','0').gsub!('£4','16'))
        module_eval(emotion_str.gsub('£1', 'interrogation').gsub!('£2', '32').gsub!('£3','0').gsub!('£4','16'))
        module_eval(emotion_str.gsub('£1', 'music').gsub!('£2', '16').gsub!('£3','32').gsub!('£4','48'))
        module_eval(emotion_str.gsub('£1', 'love').gsub!('£2', '32').gsub!('£3','32').gsub!('£4','48'))
        module_eval(emotion_str.gsub('£1', 'joy').gsub!('£2', '0').gsub!('£3','64').gsub!('£4','80'))
        module_eval(emotion_str.gsub('£1', 'sad').gsub!('£2', '16').gsub!('£3','64').gsub!('£4','80'))
        module_eval(emotion_str.gsub('£1', 'happy').gsub!('£2', '32').gsub!('£3','64').gsub!('£4','80'))
        module_eval(emotion_str.gsub('£1', 'angry').gsub!('£2', '0').gsub!('£3','96').gsub!('£4','112'))
        module_eval(emotion_str.gsub('£1', 'sulk').gsub!('£2', '16').gsub!('£3','96').gsub!('£4','112'))
        module_eval(emotion_str.gsub('£1', 'nocomment').gsub!('£2', '32').gsub!('£3','96').gsub!('£4','112'))
            
    end
end