class Game_Event < Game_Character
    def passable?(x, y, dir, skip_event=false)
        if @use_state_machine
            return super
        else
            return (can_move?(x, y, dir, skip_event, true) >= 0)
        end
    end
end