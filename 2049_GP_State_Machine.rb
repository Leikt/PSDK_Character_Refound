class Game_Player
	# Test if the player is on speed or cross bike
	# @return [Boolean]
	def is_on_bike?
		return (@state==:cross_bike or @state==:speed_bike)
	end

	# Automated state method creation, it use a lot of case @state. It's purely not necessary but it's faster at dev new state
	# @author Leikt
	def self.auto_state_method(method_name, before_case, state_methode_pattern, after_case, case_value = "@state")
		text =  "def #{method_name}\n"
		text += "" + before_case + "\n"
		text += "case #{case_value}\n"
		for c in CHARA_BY_STATE.keys
			text += "when :#{c}; #{state_methode_pattern.gsub("STATE", c.to_s)}\n"
		end
		text += "end\n"
		text += after_case + "\n"
		text += "end"
		module_eval(text)
	end
auto_state_method('state_leavable?', 
"if moving? or jump_type_moving? or sliding?
	return false
end",
"return is_STATE_state_leavable?",
"")
auto_state_method('on_reset_state', "", "STATE_reset", "")
auto_state_method('on_reset_sub_state', "", "STATE_sub_reset", "")
auto_state_method('on_state_leave(old_state)', "", "on_STATE_state_leave", "", "old_state")
auto_state_method('on_state_enter(new_state)', "", "on_STATE_state_enter", "", "new_state")
auto_state_method('state_check_premove', 
"return true if $DEBUG and Input::Keyboard.press?(Input::Keyboard::LControl)
return true unless updatable?
if (@state_at_move_end or @sub_state_at_move_end) and movable?
set_states(new_state: @state_at_move_end, new_sub_state: @sub_state_at_move_end)
@state_at_move_end = @sub_state_at_move_end = nil
end", 
"return STATE_premove", 
"return true")
auto_state_method('state_update', 
"return true if $DEBUG and Input::Keyboard.press?(Input::Keyboard::LControl)
return true unless updatable?", 
"return STATE_update", 
"return true")
auto_state_method('state_postmove_update', 
"return true if $DEBUG and Input::Keyboard.press?(Input::Keyboard::LControl)
return true unless updatable?", 
"STATE_postmove", 
"")
auto_state_method('on_sub_state_leave(old_sub_state)', 
"#pc \"leave \#{old_sub_state}\"", 
"on_STATE_sub_state_leave(old_sub_state)", 
"")
auto_state_method('on_sub_state_enter(new_sub_state)', 
"#pc \"enter \#{new_sub_state}\"", 
"on_STATE_sub_state_enter(new_sub_state)", 
"")
auto_state_method('state_ext_update','','STATE_ext_update','')
auto_state_method('on_state_ext_leave(old_ext)','','on_STATE_state_ext_leave(old_ext)','')
auto_state_method('on_state_ext_enter(new_ext)','','on_STATE_state_ext_enter(new_ext)','')
auto_state_method('state_slide_end', "",
"return unless STATE_slide_end",
"movement_process_end(false)")
auto_state_method('move_sliding_ledge(dir)', 
"if sliding? or system_tag_here?(MachBike)
	return true
end",
"return STATE_sliding_ledge(dir)",
"return false")
auto_state_method('move_sliding(dir)',
"if sliding?
	return true
end",
"return STATE_sliding(dir)",
"return false")
auto_state_method('move_surf_transition(dir)',
"if sliding?
	end_slide_route
	return false
end",
"return STATE_surf_transition(dir)",
"return false")
auto_state_method('move_cracked_floor(front = true, force_tilemap_refresh = false)',
'',
'return STATE_cracked_floor(front, force_tilemap_refresh)',
'return false')
auto_state_method('state_check_event_trigger_there',
'',
'return STATE_check_event_trigger_there',
'')
auto_state_method('move_grass(dir)',
"",
"return STATE_grass(dir)",
"return false")
auto_state_method('check_state_coherence','','check_STATE_coherence', '')
auto_state_method('move_tall_grass(dir)', '', 'return STATE_tall_grass(dir)', '')
auto_state_method('move_swamp(dir)', '', 'return STATE_swamp(dir)', '')
end