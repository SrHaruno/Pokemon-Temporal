#===============================================================================
# This file contains changes to [005] Summary.rb of Enhanced Pokemon UI
#===============================================================================
if PluginManager.installed?("Enhanced Pokemon UI")
    #===============================================================================
    # Summary UI edits.
    #===============================================================================
    class PokemonSummary_Scene

        #-----------------------------------------------------------------------------
        # Aliased to add shiny leaf display.
        #-----------------------------------------------------------------------------
        alias enhanced_drawPage drawPage
        def drawPage(page)
            enhanced_drawPage(page)
            return if !Settings::SUMMARY_SHINY_LEAF
            overlay = @sprites["overlay"].bitmap
            coords = [188, 264]
            pbDisplayShinyLeaf(@pokemon, overlay, coords[0], coords[1], true)
        end

        #-----------------------------------------------------------------------------
        # Aliased to add happiness meter display.
        #-----------------------------------------------------------------------------
        alias enhanced_drawPageTwo drawPageTwo
        def drawPageTwo
            enhanced_drawPageTwo
            return if (!Settings::SUMMARY_HAPPINESS_METER  && !Settings::SUMMARY_SHINY_LEAF)
            overlay = @sprites["overlay"].bitmap
            pbDrawImagePositions(overlay, 
                                [["Graphics/UI/Summary/Enhanced Pokemon UI/overlay_happiness", 216, 322]])
            coords = [314, 343]
            pbDisplayHappiness(@pokemon, overlay, coords[0], coords[1])
        end
        
        #-----------------------------------------------------------------------------
        # Aliased to add IV rankings display.
        #-----------------------------------------------------------------------------
        alias enhanced_drawPageThree drawPageThree
        def drawPageThree
            (@statToggle) ? drawEnhancedStats : enhanced_drawPageThree
            return if !Settings::SUMMARY_IV_RATINGS
            overlay = @sprites["overlay"].bitmap
            coords = [489, 74]
            pbDisplayIVRating(@pokemon, overlay, coords[0], coords[1], false, 8)
        end
        
        def pbDisplayIVRating(*args)
            return if args.length == 0
            pbDisplayIVRatings(*args)
        end
    
        #-----------------------------------------------------------------------------
        # Aliased to add Legacy data display.
        #-----------------------------------------------------------------------------
        alias enhanced_pbStartScene pbStartScene
        def pbStartScene(*args)
            if Settings::SUMMARY_LEGACY_DATA
                UIHandlers.edit_hash(:summary, :page_memo, "options", 
                [:item, :nickname, :pokedex, _INTL("View Legacy"), :mark]
                )
            end
            @statToggle = false
            enhanced_pbStartScene(*args)
            @sprites["legacy_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
            pbSetSystemFont(@sprites["legacy_overlay"].bitmap)
            @sprites["legacyicon"] = PokemonIconSprite.new(@pokemon, @viewport)
            @sprites["legacyicon"].setOffset(PictureOrigin::CENTER)
            @sprites["legacyicon"].visible = false
        end
        
        #-----------------------------------------------------------------------------
        # Legacy data menu.
        #-----------------------------------------------------------------------------
        TOTAL_LEGACY_PAGES = 3
        
        def pbLegacyMenu 
            base = Color.new(0, 0, 0)
            shadow = Color.new(208, 208, 200)
            base2   = Color.new(248, 248, 248)
            shadow2 = Color.new(96, 96, 96)
            path = Settings::POKEMON_UI_GRAPHICS_PATH
            legacy_overlay = @sprites["legacy_overlay"].bitmap
            legacy_overlay.clear
            ypos = 62
            index = 0
            @sprites["legacyicon"].x = 64
            @sprites["legacyicon"].y = ypos + 64
            @sprites["legacyicon"].pokemon = @pokemon
            @sprites["legacyicon"].visible = true
            @sprites["legacyicon"].mirror  = true
            data = @pokemon.legacy_data
            dorefresh = true
            loop do
                Graphics.update
                Input.update
                pbUpdate
                textpos = []
                imagepos = []
                if Input.trigger?(Input::BACK)
                break
                elsif Input.trigger?(Input::UP) && index > 0
                index -= 1
                pbPlayCursorSE
                dorefresh = true
                elsif Input.trigger?(Input::DOWN) && index < TOTAL_LEGACY_PAGES - 1
                index += 1
                pbPlayCursorSE
                dorefresh = true
                end
                if dorefresh
                case index
                when 0  # General
                    name = _INTL("General")
                    hour = data[:party_time].to_i / 60 / 60
                    min  = data[:party_time].to_i / 60 % 60
                    addltext = [
                    [_INTL("Total time in party:"),    "#{hour} hrs #{min} min"],
                    [_INTL("Items consumed:"),         data[:item_count]],
                    [_INTL("Moves learned:"),          data[:move_count]],
                    [_INTL("Eggs produced:"),          data[:egg_count]],
                    [_INTL("Number of times traded:"), data[:trade_count]]
                    ]
                when 1  # Battle History
                    name = _INTL("Battle History")
                    addltext = [
                    [_INTL("Opponents defeated:"),        data[:defeated_count]],
                    [_INTL("Number of times fainted:"),   data[:fainted_count]],
                    [_INTL("Supereffective hits dealt:"), data[:supereff_count]],
                    [_INTL("Critical hits dealt:"),       data[:critical_count]],
                    [_INTL("Total number of retreats:"),  data[:retreat_count]]
                    ]
                when 2  # Team History
                    name = _INTL("Team History")
                    addltext = [
                    [_INTL("Trainer battle victories:"),        data[:trainer_count]],
                    [_INTL("Gym Leader battle victories:"),     data[:leader_count]],
                    [_INTL("Wild legendary battle victories:"), data[:legend_count]],
                    [_INTL("Total Hall of Fame inductions:"),   data[:champion_count]],
                    [_INTL("Total draws or losses:"),           data[:loss_count]]
                    ]
                end
                textpos.push([_INTL("{1}'s Legacy", @pokemon.name), 295, ypos + 38, :center, base2, shadow2],
                            [name, Graphics.width / 2, ypos + 90, :center, base, shadow])
                addltext.each_with_index do |txt, i|
                    textY = ypos + 134 + (i * 32)
                    textpos.push([txt[0], 34, textY, :left, base, shadow])
                    textpos.push([_INTL("{1}", txt[1]), Graphics.width - 34, textY, :right, base, shadow])
                end
                imagepos.push([path + "bg_legacy", 0, ypos])
                if index > 0
                    imagepos.push([path + "arrows_legacy", 118, ypos + 84, 0, 0, 32, 32])
                end
                if index < TOTAL_LEGACY_PAGES - 1
                    imagepos.push([path + "arrows_legacy", 362, ypos + 84, 32, 0, 32, 32])
                end
                legacy_overlay.clear
                pbDrawImagePositions(legacy_overlay, imagepos)
                pbDrawTextPositions(legacy_overlay, textpos)
                dorefresh = false
                end
            end
            legacy_overlay.clear
            @sprites["legacyicon"].visible = false
        end
        
        #-----------------------------------------------------------------------------
        # Enhanced stats display.
        #-----------------------------------------------------------------------------
        def drawEnhancedStats
            overlay = @sprites["overlay"].bitmap
            base   = Color.new(248, 248, 248)
            shadow = Color.new(96, 96, 96)
            base2 = Color.new(0, 0, 0)
            shadow2 = Color.new(208, 208, 200)
            index = 0
            ev_total = 0
            iv_total = 0
            textpos = []
            writePageInfo("Stats")
            GameData::Stat.each_main do |s|
                xpos, align = 290, :center
                case s.id
                when :HP then ypos = 72
                else ypos = 80 + (32 * index)
                end
                name = (s.id == :SPECIAL_ATTACK) ? "Sp. Atk" : (s.id == :SPECIAL_DEFENSE) ? "Sp. Def" : s.name
                statshadow = shadow
                if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
                    @pokemon.nature_for_stats.stat_changes.each do |change|
                        next if s.id != change[0]
                        if change[1] > 0
                            statshadow = Color.new(208, 112, 104)
                        elsif change[1] < 0
                            statshadow = Color.new(0, 140, 149)
                        end
                    end
                end
                statX = Settings::SUMMARY_IV_RATINGS ? 486 : 504
                textpos.push(
                [_INTL("{1}", name), xpos, ypos, align, base, statshadow],
                [_INTL("|"), statX - 32, ypos, :right, base2, shadow2],
                [@pokemon.ev[s.id].to_s, statX - 48, ypos, :right, base2, shadow2],
                [@pokemon.iv[s.id].to_s, statX, ypos, :right, base2, shadow2]
                )
                ev_total += @pokemon.ev[s.id]
                iv_total += @pokemon.iv[s.id]
                index += 1
            end
            imagepos = [
            ["Graphics/UI/Summary/Enhanced Pokemon UI/overlay_enhancedStat", 216, 266]
            ]
            if @pokemon.hp > 0
                w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
                w = 1 if w < 1
                w = ((w / 2).round) * 2
                hpzone = 0
                hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
                hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
                imagepos.push(["Graphics/UI/Summary/overlay_hp", 404, 98, 0, hpzone * 6, w, 6])
                pbDrawImagePositions(overlay, imagepos)
            end
            hiddenpower = pbHiddenPower(@pokemon)
            type_number = GameData::Type.get(hiddenpower[0]).icon_position
            type_rect = Rect.new(0, type_number * 28, 64, 28)
            overlay.blt(422, 286, @typebitmap.bitmap, type_rect)
            textpos.push(
                [_INTL("Hidden Power Type/"), 222, 290, :left, base, shadow],
                [_INTL("EV/IV Total"), 222, 320, :left, base, shadow],
                [sprintf("%d  |  %d", ev_total, iv_total), 504, 320, :right, base2, shadow2],
                [_INTL("EV's Remaining:"), 222, 352, :left, base, shadow],
                [sprintf("%d/%d", Pokemon::EV_LIMIT - ev_total, Pokemon::EV_LIMIT), 504, 352, :right, base2, shadow2],
            )
            pbDrawTextPositions(overlay, textpos)
        end
    end
end