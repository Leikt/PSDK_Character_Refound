class Game_Event	
	EVENT_STATES = [:feet]
	
	def state_slide_end
		force_move_route(MRB.new)
		movement_process_end(false)
	end
	
	# Automated state method creation, it use a lot of case @state. It's purely not necessary but it's faster at dev new state
	# @author Leikt
	def self.auto_state_method(method_name, before_case, state_methode_pattern, after_case, case_value = "@state")
		text =  "def #{method_name}\n"
		text += "" + before_case + "\n"
		text += "case #{case_value}\n"
		for c in EVENT_STATES
			text += "when :#{c}; #{state_methode_pattern.gsub("STATE", c.to_s)}\n"
		end
		text += "end\n"
		text += after_case + "\n"
		text += "end"
		module_eval(text)
	end
end