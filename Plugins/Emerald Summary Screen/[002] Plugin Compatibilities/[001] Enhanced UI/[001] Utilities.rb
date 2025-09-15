#===============================================================================
# This file contains changes to [001] Utilities.rb of Enhanced Pokemon UI
#===============================================================================
if PluginManager.installed?("Enhanced Pokemon UI")
    def pbDisplayIVRatings(pokemon, overlay, xpos, ypos, horizontal = false, ydif = 12)
        return if !pokemon
        imagepos = []
        path  = Settings::POKEMON_UI_GRAPHICS_PATH
        style = (Settings::IV_DISPLAY_STYLE == 0) ? 0 : 16
        maxIV = Pokemon::IV_STAT_LIMIT
        offset_x = (horizontal) ? 16 : 0
        offset_y = (horizontal) ? 0  : 32
        i = 0
        GameData::Stat.each_main do |s|
            stat = pokemon.iv[s.id]
            case stat
            when maxIV     then icon = 5  # 31 IV
            when maxIV - 1 then icon = 4  # 30 IV
            when 0         then icon = 0  #  0 IV
            else
            if stat > (maxIV - (maxIV / 4).floor)
                icon = 3 # 25-29 IV
            elsif stat > (maxIV - (maxIV / 2).floor)
                icon = 2 # 16-24 IV
            else
                icon = 1 #  1-15 IV
            end
            end
            imagepos.push([
            path + "iv_ratings", xpos + (i * offset_x), ypos + (i * offset_y), icon * 16, style, 16, 16
            ])
            if s.id == :HP && !horizontal
                ypos += ydif
            end
            i += 1
        end
        pbDrawImagePositions(overlay, imagepos)
    end
end