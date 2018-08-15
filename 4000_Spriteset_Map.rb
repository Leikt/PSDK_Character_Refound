class Spriteset_Map
    def add_event(event)
        @character_sprites.push(Sprite_Character.new(@viewport1, event))
    end

    def delete_event(event)
        @character_sprites.select {|v| v.character == event}.each do |sprite|
            sprite.dispose
            @character_sprites.delete(sprite)
        end
    end
end
