#===============================================================================
#
#===============================================================================
class MoveSelectionSprite < Sprite
    def refresh
        w = @movesel.width
        h = @movesel.height / 2
        self.x = 216
        self.y =  62 + (self.index * 60)
        self.y -= 8 if @fifthmove
        self.y += 20 if @fifthmove && self.index == Pokemon::MAX_MOVES   # Add a gap
        self.bitmap = @movesel.bitmap
        if self.preselected
          self.src_rect.set(0, h, w, h)
        else
          self.src_rect.set(0, 0, w, h)
        end
    end
end
#===============================================================================
#
#===============================================================================
class PokemonSummary_Scene
    MARK_WIDTH  = 16
    MARK_HEIGHT = 16
    # Colors used for messages in this scene
    RED_TEXT_BASE     = Color.new(224, 8, 8)
    RED_TEXT_SHADOW   = Color.new(248, 184, 112)
    BLACK_TEXT_BASE   = Color.new(0, 0, 0)
    BLACK_TEXT_SHADOW = Color.new(208, 208, 200)
    # Modular UI Scenes Settings
    MAX_PAGE_ICONS = 4
    PAGE_ICONS_POSITION = [214, 0]
    PAGE_ICON_SIZE = [40, 32]

    #-----------------------------------------------------------------------------
    # Used to draw the relevant page icons in the heading of each page.
    #-----------------------------------------------------------------------------
    def drawPageIcons
      setPages if !@page_list || @page_list.empty?
      iconPos    = 0
      imagepos   = []
      xpos, ypos = PAGE_ICONS_POSITION
      w, h       = PAGE_ICON_SIZE
      size       = MAX_PAGE_ICONS 
      range      = [@page_list.length, MAX_PAGE_ICONS]
      page       = @page_list.find_index(@page_id)
      endPage    = [size - 1, @page_list.length - (page / size).floor * size - 1].min
      pageZ      = page  % size
      for i in 0..endPage
        if (i == endPage)
          path = "Graphics/UI/Summary/page_icons_last"
          iconRectX = (pageZ == i) ? 0 : w
        else
          path = "Graphics/UI/Summary/page_icons"
          iconRectX = (pageZ == i) ? w : (pageZ > i) ? 0 : 2 * w
        end
        suffix = UIHandlers.get_info(:summary, @page_list[i], :suffix)
        imagepos.push([path, xpos + (iconPos * (w - 8)), ypos, iconRectX, 0, w, h])
        iconPos += 1
      end
      if PAGE_ICONS_SHOW_ARROWS
        path = "Graphics/UI/Summary/page_arrows"
        if (page / size).floor > 0
          imagepos.push([path, xpos - 6, ypos + 6, 0, 0, 12, 20])
        end
        if (endPage == size - 1) && (@page_list.length - ((page / size).floor + 1) * size > 0)
          imagepos.push([path, xpos + (iconPos * (w - 8)) + 2, ypos + 6, 14, 0, 12, 20])
        end
      end
      pbDrawImagePositions(@sprites["overlay"].bitmap, imagepos)
    end
    
    def pbStartScene(party, partyindex, inbattle = false)
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @party      = party
      @partyindex = partyindex
      @pokemon    = @party[@partyindex]
      @inbattle   = inbattle
      @page = 1				  
      @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      @markingbitmap = AnimatedBitmap.new("Graphics/UI/Summary/markings")																				
      @sprites = {}
      @sprites["background"] = IconSprite.new(0, 0, @viewport)
      @sprites["background"].z -= 2
      @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
      @sprites["movepresel"].visible     = false
      @sprites["movepresel"].preselected = true
      @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
      @sprites["movesel"].visible = false
      @sprites["movesel"].z -= 1
      @sprites["overlay_movedetail"] = IconSprite.new(0, 32, @viewport)
      @sprites["overlay_movedetail"].setBitmap("Graphics/UI/Summary/overlay_movedetail")
      @sprites["overlay_movedetail"].visible = false
      @sprites["pokemon"] = PokemonSprite.new(@viewport)
      @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
      @sprites["pokemon"].x = 106
      @sprites["pokemon"].y = 160
      @sprites["pokemon"].mirror = true
      @sprites["pokemon"].setPokemonBitmap(@pokemon)
      @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
      @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
      @sprites["pokeicon"].x       = 50
      @sprites["pokeicon"].y       = 82
      @sprites["pokeicon"].mirror = true
      @sprites["pokeicon"].visible = false
      @sprites["itemicon"] = ItemIconSprite.new(484 , 160, @pokemon.item_id, @viewport)
      @sprites["itemicon"].blankzero = true
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSystemFont(@sprites["overlay"].bitmap)
      @sprites["markingbg"] = Window_AdvancedTextPokemon.newWithSize("", Graphics.width - 132, Graphics.height - 288, 132, 288, @viewport)
      @sprites["markingbg"].visible = false
      @sprites["markingbg"].setSkin(MessageConfig.pbGetSystemFrame)
      @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @sprites["markingoverlay"].visible = false
      @sprites["markingoverlay"].z = @viewport.z + 1
      pbSetSystemFont(@sprites["markingoverlay"].bitmap)
      @sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
      @sprites["markingsel"].setBitmap("Graphics/UI/sel_arrow")
      @sprites["markingsel"].visible = false
      @sprites["markingsel"].z = @viewport.z + 1
      @sprites["markingbitmap_2"] = IconSprite.new(0, 0, @viewport)
      @sprites["markingbitmap_2"].setBitmap("Graphics/UI/Summary/markings_2")
      @sprites["markingbitmap_2"].visible = false						 
      @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
      @sprites["messagebox"].viewport       = @viewport
      @sprites["messagebox"].visible        = false
      @sprites["messagebox"].letterbyletter = true
      pbBottomLeftLines(@sprites["messagebox"], 2)
      @nationalDexList = [:NONE]
      GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
      drawPage(@page)
      pbFadeInAndShow(@sprites) { pbUpdate }
    end
  
    def pbStartForgetScene(party, partyindex, move_to_learn)
      @page_id = :page_moves
      @page_list = [:page_moves]
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @party      = party
      @partyindex = partyindex
      @pokemon    = @party[@partyindex]
      @page = 4
      @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      @sprites = {}
      @sprites["background"] = IconSprite.new(0, 0, @viewport)
      @sprites["background"].z -= 2
      @sprites["movesel"] = MoveSelectionSprite.new(@viewport, !move_to_learn.nil?)
      @sprites["movesel"].visible = false
      @sprites["movesel"].z -= 1
      @sprites["overlay_movedetail"] = IconSprite.new(0, 32, @viewport)
      @sprites["overlay_movedetail"].setBitmap("Graphics/UI/Summary/overlay_movedetail")
      @sprites["overlay_movedetail"].visible = false
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSystemFont(@sprites["overlay"].bitmap)
      @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
      @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
      @sprites["pokeicon"].x       = 50
      @sprites["pokeicon"].y       = 82
      @sprites["pokeicon"].mirror = true
      @sprites["movesel"].visible = true
      @sprites["movesel"].index   = 0
      new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
      drawSelectedMove(new_move, @pokemon.moves[0])
      pbFadeInAndShow(@sprites)
    end

    def drawMarkings(bitmap, x, y)
        mark_variants = @markingbitmap.bitmap.height / MARK_HEIGHT
        markings = @pokemon.markings
        markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
        (@markingbitmap.bitmap.width / MARK_WIDTH).times do |i|
          markrect.x = i * MARK_WIDTH
          markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
          bitmap.blt(x + (i * MARK_WIDTH), y, @markingbitmap.bitmap, markrect)
        end
    end

    def writePageInfo(page_info = "Options")
      overlay = @sprites["overlay"].bitmap
      # Write the page info
      textpos = [
      [_INTL("{1}", page_info), 430, 6, :left, Color.new(0, 0, 0), Color.new(208, 208, 200)]
      ]
      # Draw all text
      pbDrawTextPositions(overlay, textpos)
    end

    def drawPage(page)
      setPages # Gets the list of pages and current page ID.
      suffix = UIHandlers.get_info(:summary, @page_id, :suffix)
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_#{suffix}")
      @sprites["pokemon"].setPokemonBitmap(@pokemon)
      @sprites["pokeicon"].pokemon = @pokemon
      @sprites["itemicon"].item = @pokemon.item_id
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      base   = Color.new(248, 248, 248)
      shadow = Color.new(96, 96, 96)
      dexNumBase   = (@pokemon.shiny?) ? Color.new(232, 232, 168) : base
      dexNumShadow = (@pokemon.shiny?) ? Color.new(160, 160, 96) : shadow
      drawPageIcons # Draws the page icons.
      imagepos = []
      # Show the Poké Ball containing the Pokémon
      ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
      imagepos.push([ballimage, 12, 316])
      pagename = UIHandlers.get_info(:summary, @page_id, :name)
      textpos = [
        [pagename, 4, 6, :left, base, shadow],
        [@pokemon.name, 10, 264, :left, base, shadow],
      ]
      # Show the held item's name and icon
      if @page_id == :page_info || @page_id == :page_egg
        @sprites["itemicon"].y = @page_id == :page_info ? 160 : 80
        @sprites["itemicon"].visible = true
        nameYPos = @page_id == :page_info ? 152 : 72
        if @pokemon.hasItem?
          textpos.push([@pokemon.item.name, 222, nameYPos, :left, Color.new(0, 0, 0), Color.new(208, 208, 200)])
        else
          textpos.push([_INTL("None"), 222, nameYPos, :left, Color.new(0, 0, 0), Color.new(208, 208, 200)])
        end
      else
        @sprites["itemicon"].visible = false
      end
      # Writes the page info for all pages except skills page
      writePageInfo() if (@page_id != :page_skills)
      # Draws additional info for non-Egg Pokemon.
      if !@pokemon.egg?
        textpos.push([_INTL("/{1}", @pokemon.speciesName), 10, 292, :left, base, shadow])
        textpos.push([_INTL("Lv {1}", @pokemon.level.to_s), 82, 328, :left, base, shadow])
        status = -1
        if @pokemon.fainted?
          status = GameData::Status.count - 1
        elsif @pokemon.status != :NONE
          status = GameData::Status.get(@pokemon.status).icon_position
        elsif @pokemon.pokerusStage == 1
          status = GameData::Status.count
        end
        if status >= 0
          textpos.push(["Status", 4, 358, :left, base, shadow])
          imagepos.push(["Graphics/UI/Summary/overlay_status", 0, 352])
          imagepos.push(["Graphics/UI/statuses", 146, 360, 0, 16 * status, 44, 16])
        end
        # Write the Regional/National Dex number
        dexnum = 0
        dexnumshift = false
        if $player.pokedex.unlocked?(-1)   # National Dex is unlocked
          dexnum = @nationalDexList.index(@pokemon.species_data.species) || 0
          dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(-1)
        else
          ($player.pokedex.dexes_count - 1).times do |i|
            next if !$player.pokedex.unlocked?(i)
            num = pbGetRegionalNumber(i, @pokemon.species)
            break if num <= 0
            dexnum = num
            dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
            break
          end
        end
        if dexnum <= 0
          textpos.push(["No ???", 10, 40, :left, dexNumBase, dexNumShadow])
        else
          dexnum -= 1 if dexnumshift
          textpos.push([sprintf("No %03d", dexnum), 10, 40, :left, dexNumBase, dexNumShadow])
        end
        if @pokemon.pokerusStage == 2
          imagepos.push(["Graphics/UI/Summary/icon_pokerus", 159, 330])
        end
        textpos.push([_INTL("★"), 83, 42, :left, Color.new(232, 232, 168), Color.new(176, 176, 112)]) if @pokemon.shiny?
        # Write the gender symbol
        if @pokemon.male?
          textpos.push([_INTL("♂"), 200, 328, :right, Color.new(60, 206, 255), Color.new(0, 140, 149)])
        elsif @pokemon.female?
          textpos.push([_INTL("♀"), 200, 328, :right, Color.new(248, 184, 176), Color.new(208, 112, 104)])
        end
      end
      # Draws the page.
      pbDrawImagePositions(overlay, imagepos)
      pbDrawTextPositions(overlay, textpos)
      UIHandlers.call(:summary, @page_id, "layout", @pokemon, self)
      drawMarkings(overlay, 108, 42)
    end


    def drawPageOne
        overlay = @sprites["overlay"].bitmap
        base   = Color.new(248, 248, 248)
        shadow = Color.new(96, 96, 96)
        # If a Shadow Pokémon, draw the heart gauge area and bar
        if @pokemon.shadowPokemon?
          shadowfract = @pokemon.heart_gauge.to_f / @pokemon.max_gauge_size
          imagepos = [
            ["Graphics/UI/Summary/overlay_shadow", 216, 178],
            ["Graphics/UI/Summary/overlay_shadowbar", 240, 264, 0, 0, (shadowfract * 248).floor, -1]
          ]
          pbDrawImagePositions(overlay, imagepos)
        end
        # Write various bits of text
        textpos = [
          [_INTL("OT/"), 222, 72, :left, base, shadow],
          [_INTL("IDNo"), 390, 72, :left, base, shadow],
          [_INTL("Type/"), 222, 102, :left, Color.new(0, 0, 0), Color.new(208, 208, 200)],
        ]
        # Write Original Trainer's name and ID number
        if @pokemon.owner.name.empty?
          textpos.push([_INTL("RENTAL"), 258, 68, :left, base, shadow])
          textpos.push(["?????", 446, 68, :left, base, shadow])
        else
          ownerbase   = base
          ownershadow = shadow
          case @pokemon.owner.gender
          when 0
            ownerbase = Color.new(60, 206, 255)
            ownershadow = Color.new(0, 140, 149)
          when 1
            ownerbase = Color.new(248, 184, 176)
            ownershadow = Color.new(208, 112, 104)
          end
          textpos.push([@pokemon.owner.name, 258, 72, :left, ownerbase, ownershadow])
          textpos.push([sprintf("%05d", @pokemon.owner.public_id), 504, 72, :right,
                        base, shadow])
        end
        # Write Exp text OR heart gauge message (if a Shadow Pokémon)
        if @pokemon.shadowPokemon?
          black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
          heartmessage = [_INTL("The door to its heart is open! Undo the final lock!"),
                          _INTL("The door to its heart is almost fully open."),
                          _INTL("The door to its heart is nearly open."),
                          _INTL("The door to its heart is opening wider."),
                          _INTL("The door to its heart is opening up."),
                          _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
          memo = black_text_tag + heartmessage
          drawFormattedTextEx(overlay, 222, 202, 282, memo)
        else
          endexp = @pokemon.growth_rate.minimum_exp_for_level(@pokemon.level + 1)
          textpos.push([_INTL("Exp. Points"), 222, 202, :left, base, shadow])
          textpos.push([@pokemon.exp.to_s_formatted, 504, 202, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)])
          textpos.push([_INTL("To Next Lv."), 222, 234, :left, base, shadow])
          textpos.push([(endexp - @pokemon.exp).to_s_formatted, 504, 234, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)])
        end
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        # Draw Pokémon type(s)
        @pokemon.types.each_with_index do |type, i|
          type_number = GameData::Type.get(type).icon_position
          type_rect = Rect.new(0, type_number * 28, 64, 28)
          type_x = (@pokemon.types.length == 1) ? 286 : 286 + (80 * i)
          overlay.blt(type_x, 98, @typebitmap.bitmap, type_rect)
        end
        # Draw Exp bar
        if (@pokemon.level < GameData::GrowthRate.max_level) && (!@pokemon.shadowPokemon?)
          w = @pokemon.exp_fraction * 128
          w = ((w / 2).round) * 2
          pbDrawImagePositions(overlay,
                               [["Graphics/UI/Summary/overlay_exp", 368, 264, 0, 0, w, 6]])
        end
    end

    def drawPageOneEgg
      overlay = @sprites["overlay"].bitmap
      red_text_tag = shadowc3tag(RED_TEXT_BASE, RED_TEXT_SHADOW)
      black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
      base   = Color.new(248, 248, 248)
      shadow = Color.new(96, 96, 96)
      # Write Egg Watch blurb
      eggstate = _INTL("It looks like this Egg will take a long time to hatch.")
      eggstate = _INTL("What will hatch from this? It doesn't seem close to hatching.") if @pokemon.steps_to_hatch < 10_200
      eggstate = _INTL("It appears to move occasionally. It may be close to hatching.") if @pokemon.steps_to_hatch < 2550
      eggstate = _INTL("Sounds can be heard coming from inside! It will hatch soon!") if @pokemon.steps_to_hatch < 1275
      drawTextEx(overlay, 222, 122, 282, 3, eggstate, Color.new(0, 0, 0), Color.new(208, 208, 200))
      red_text_tag = shadowc3tag(RED_TEXT_BASE, RED_TEXT_SHADOW)
      black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
      memo = ""
      # Write date received
      if @pokemon.timeReceived
        date  = @pokemon.timeReceived.day
        month = pbGetMonthName(@pokemon.timeReceived.mon)
        year  = @pokemon.timeReceived.year
        memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
      end
      # Write map name egg was received on
      mapname = pbGetMapNameFromId(@pokemon.obtain_map)
      mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
      if mapname && mapname != ""
        mapname = red_text_tag + mapname + black_text_tag
        memo += black_text_tag + _INTL("A mysterious Pokémon Egg received from {1}.", mapname) + "\n"
      else
        memo += black_text_tag + _INTL("A mysterious Pokémon Egg.") + "\n"
      end
      # Draw all text
      drawFormattedTextEx(overlay, 222, 236, 282, memo)
    end
    
    def drawPageTwo
        overlay = @sprites["overlay"].bitmap
        red_text_tag = shadowc3tag(RED_TEXT_BASE, RED_TEXT_SHADOW)
        black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
        memo = ""
        # Write nature
        showNature = !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
        if showNature
          nature_name = red_text_tag + @pokemon.nature.name + black_text_tag
          memo += _INTL("{1} nature.", nature_name) + "\n"
        end
        # Write date received
        if @pokemon.timeReceived
          date  = @pokemon.timeReceived.day
          month = pbGetMonthName(@pokemon.timeReceived.mon)
          year  = @pokemon.timeReceived.year
          memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
        end
        # Write map name Pokémon was received on
        mapname = pbGetMapNameFromId(@pokemon.obtain_map)
        mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
        mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
        memo += red_text_tag + mapname + "\n"
        obtain_level = red_text_tag + @pokemon.obtain_level.to_s + black_text_tag
        # Write how Pokémon was obtained
        mettext = [
          _INTL("Met at Lv. {1}.", obtain_level),
          _INTL("Egg received."),
          _INTL("Traded at Lv. {1}.", obtain_level),
          "",
          _INTL("Had a fateful encounter at Lv. {1}.", obtain_level)
        ][@pokemon.obtain_method]
        memo += black_text_tag + mettext + "\n" if mettext && mettext != ""
        # If Pokémon was hatched, write when and where it hatched
        if @pokemon.obtain_method == 1
          if @pokemon.timeEggHatched
            date  = @pokemon.timeEggHatched.day
            month = pbGetMonthName(@pokemon.timeEggHatched.mon)
            year  = @pokemon.timeEggHatched.year
            memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
          end
          mapname = pbGetMapNameFromId(@pokemon.hatched_map)
          mapname = _INTL("Faraway place") if nil_or_empty?(mapname)
          memo += red_text_tag + mapname + "\n"
          memo += black_text_tag + _INTL("Egg hatched.") + "\n"
        else
          memo += "\n"   # Empty line
        end
        # Write characteristic
        if showNature
          best_stat = nil
          best_iv = 0
          stats_order = [:HP, :ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE]
          start_point = @pokemon.personalID % stats_order.length   # Tiebreaker
          stats_order.length.times do |i|
            stat = stats_order[(i + start_point) % stats_order.length]
            if !best_stat || @pokemon.iv[stat] > @pokemon.iv[best_stat]
              best_stat = stat
              best_iv = @pokemon.iv[best_stat]
            end
          end
          characteristics = {
            :HP              => [_INTL("Loves to eat."),
                                 _INTL("Takes plenty of siestas."),
                                 _INTL("Nods off a lot."),
                                 _INTL("Scatters things often."),
                                 _INTL("Likes to relax.")],
            :ATTACK          => [_INTL("Proud of its power."),
                                 _INTL("Likes to thrash about."),
                                 _INTL("A little quick tempered."),
                                 _INTL("Likes to fight."),
                                 _INTL("Quick tempered.")],
            :DEFENSE         => [_INTL("Sturdy body."),
                                 _INTL("Capable of taking hits."),
                                 _INTL("Highly persistent."),
                                 _INTL("Good endurance."),
                                 _INTL("Good perseverance.")],
            :SPECIAL_ATTACK  => [_INTL("Highly curious."),
                                 _INTL("Mischievous."),
                                 _INTL("Thoroughly cunning."),
                                 _INTL("Often lost in thought."),
                                 _INTL("Very finicky.")],
            :SPECIAL_DEFENSE => [_INTL("Strong willed."),
                                 _INTL("Somewhat vain."),
                                 _INTL("Strongly defiant."),
                                 _INTL("Hates to lose."),
                                 _INTL("Somewhat stubborn.")],
            :SPEED           => [_INTL("Likes to run."),
                                 _INTL("Alert to sounds."),
                                 _INTL("Impetuous and silly."),
                                 _INTL("Somewhat of a clown."),
                                 _INTL("Quick to flee.")]
          }
          memo += black_text_tag + characteristics[best_stat][best_iv % 5] + "\n"
        end
        # Write all text
        drawFormattedTextEx(overlay, 222, 74, 282, memo)
    end
    
    def drawPageThree
        overlay = @sprites["overlay"].bitmap
        base   = Color.new(248, 248, 248)
        shadow = Color.new(96, 96, 96)
        statX = 504
        if PluginManager.installed?("Enhanced Pokemon UI")
          statX -= Settings::SUMMARY_IV_RATINGS ? 18 : 0
          writePageInfo($game_switches[Settings::ENHANCED_STATS_SWITCH] ? "EV & IV" : "Options")
        else
          writePageInfo("Options")
        end
        # Determine which stats are boosted and lowered by the Pokémon's nature
        statshadows = {}
        GameData::Stat.each_main { |s| statshadows[s.id] = shadow }
        if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
            @pokemon.nature_for_stats.stat_changes.each do |change|
            statshadows[change[0]] = Color.new(208, 112, 104) if change[1] > 0
            statshadows[change[0]] = Color.new(0, 140, 149) if change[1] < 0
            end
        end
        # Write various bits of text
        textpos = [
            [_INTL("HP"), 290, 72, :center, base, statshadows[:HP]],
            [sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp), statX, 72, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)],
            [_INTL("Attack"), 290, 112, :center, base, statshadows[:ATTACK]],
            [@pokemon.attack.to_s, statX, 112, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)],
            [_INTL("Defense"), 290, 144, :center, base, statshadows[:DEFENSE]],
            [@pokemon.defense.to_s, statX, 144, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)],
            [_INTL("Sp. Atk"), 290, 176, :center, base, statshadows[:SPECIAL_ATTACK]],
            [@pokemon.spatk.to_s, statX, 176, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)],
            [_INTL("Sp. Def"), 290, 208, :center, base, statshadows[:SPECIAL_DEFENSE]],
            [@pokemon.spdef.to_s, statX, 208, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)],
            [_INTL("Speed"), 290, 240, :center, base, statshadows[:SPEED]],
            [@pokemon.speed.to_s, statX, 240, :right, Color.new(0, 0, 0), Color.new(208, 208, 200)]
        ]
        # Draw ability name and description
        ability = @pokemon.ability
        if ability
            textpos.push([ability.name, 222, 290, :left, base, shadow])
            drawTextEx(overlay, 222, 320, 282, 2, ability.description, Color.new(0, 0, 0), Color.new(208, 208, 200))
        end
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        # Draw HP bar
        if @pokemon.hp > 0
            w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
            w = 1 if w < 1
            w = ((w / 2).round) * 2
            hpzone = 0
            hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
            hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
            imagepos = [
            ["Graphics/UI/Summary/overlay_hp", 404, 98, 0, hpzone * 6, w, 6]
            ]
            pbDrawImagePositions(overlay, imagepos)
        end
    end
    
    def drawPageFour
        overlay = @sprites["overlay"].bitmap
        moveBase   = Color.new(248, 248, 248)
        moveShadow = Color.new(96, 96, 96)
        ppBase   = [Color.new(0, 0, 0),        # More than 1/2 of total PP
                    Color.new(214, 198, 0),    # 1/2 of total PP or less
                    Color.new(248, 136, 32),   # 1/4 of total PP or less
                    Color.new(255, 132, 0)]    # Zero PP
        ppShadow = [Color.new(208, 208, 200), # More than 1/2 of total PP
                    Color.new(255, 247, 140), # 1/2 of total PP or less
                    Color.new(247, 222, 156), # 1/4 of total PP or less
                    Color.new(255, 239, 115)] # Zero PP
        @sprites["pokemon"].visible  = true
        @sprites["pokeicon"].visible = false
        @sprites["overlay_movedetail"].visible = false
        textpos  = []
        imagepos = []
        # Write move names, types and PP amounts for each known move
        yPos = 70
        Pokemon::MAX_MOVES.times do |i|
          move = @pokemon.moves[i]
          if move
            type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
            imagepos.push([_INTL("Graphics/UI/types"), 248, yPos - 4, 0, type_number * 28, 64, 28])
            textpos.push([move.name, 320, yPos, :left, moveBase, moveShadow])
            if move.total_pp > 0
              ppfraction = 0
              if move.pp == 0
                ppfraction = 3
              elsif move.pp * 4 <= move.total_pp
                ppfraction = 2
              elsif move.pp * 2 <= move.total_pp
                ppfraction = 1
              end
              textpos.push([_INTL("PP"), 414, yPos + 30, :left, ppBase[ppfraction], ppShadow[ppfraction]])
              textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 504, yPos + 30, :right, 
                            ppBase[ppfraction], ppShadow[ppfraction]])
            end
          else
            textpos.push(["-", 320, yPos, :left, moveBase, moveShadow])
            textpos.push(["--", 448, yPos + 32, :left, Color.new(0, 0, 0), Color.new(208, 208, 200)])
          end
          yPos += 60
        end
        # Draw all text and images
        pbDrawTextPositions(overlay, textpos)
        pbDrawImagePositions(overlay, imagepos)
    end
    
    def drawPageFourSelecting(move_to_learn)
        @sprites["overlay_movedetail"].visible = true
        overlay = @sprites["overlay"].bitmap
        overlay.clear
        base   = Color.new(0, 0, 0)
        shadow = Color.new(208, 208, 200)
        moveBase   = Color.new(248, 248, 248)
        moveShadow = Color.new(96, 96, 96)
        ppBase   = [base,                      # More than 1/2 of total PP
                    Color.new(214, 198, 0),    # 1/2 of total PP or less
                    Color.new(248, 136, 32),   # 1/4 of total PP or less
                    Color.new(255, 132, 0)]    # Zero PP
        ppShadow = [shadow,                   # More than 1/2 of total PP
                    Color.new(255, 247, 140), # 1/2 of total PP or less
                    Color.new(247, 222, 156), # 1/4 of total PP or less
                    Color.new(255, 239, 115)] # Zero PP
        # Set background image
        if move_to_learn
          @sprites["background"].setBitmap("Graphics/UI/Summary/bg_learnmove")
        else
          @sprites["background"].setBitmap("Graphics/UI/Summary/bg_moves")
        end
        # Write various bits of text
        textpos = [
          [_INTL("Battle Moves"), 4, 6, :left, moveBase, moveShadow],
          [_INTL("Power"), 4, 142, :left, moveBase, moveShadow],
          [_INTL("Accuracy"), 4, 174, :left, moveBase, moveShadow]
        ]
        imagepos = []
        # Write move names, types and PP amounts for each known move
        yPos = 70
        yPos -= 8 if move_to_learn
        limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
        limit.times do |i|
          move = @pokemon.moves[i]
          if i == Pokemon::MAX_MOVES
            move = move_to_learn
            yPos += 20
          end
          if move
            type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
            imagepos.push([_INTL("Graphics/UI/types"), 248, yPos - 4, 0, type_number * 28, 64, 28])
            textpos.push([move.name, 320, yPos, :left, moveBase, moveShadow])
            if move.total_pp > 0
              ppfraction = 0
              if move.pp == 0
                ppfraction = 3
              elsif move.pp * 4 <= move.total_pp
                ppfraction = 2
              elsif move.pp * 2 <= move.total_pp
                ppfraction = 1
              end
              textpos.push([_INTL("PP"), 414, yPos + 30, :left, ppBase[ppfraction], ppShadow[ppfraction]])
              textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 504, yPos + 30, :right, 
                            ppBase[ppfraction], ppShadow[ppfraction]])
            end
          else
            textpos.push(["-", 320, yPos, :left, moveBase, moveShadow])
            textpos.push(["--", 448, yPos + 32, :left, Color.new(0, 0, 0), Color.new(208, 208, 200)])
          end
          yPos += 60
        end
        page_info = move_to_learn ? "Forget" : "Switch"
        textpos.push([page_info, 430, 6, :left, Color.new(0, 0, 0), Color.new(208, 208, 200)])	
        # Draw all text and images
        pbDrawTextPositions(overlay, textpos)
        pbDrawImagePositions(overlay, imagepos)
        # Draw Pokémon's type icon(s)
        @pokemon.types.each_with_index do |type, i|
          type_number = GameData::Type.get(type).icon_position
          type_rect = Rect.new(0, type_number * 28, 64, 28)
          type_y = (@pokemon.types.length == 1) ? 60 : 44 + (32 * i)
          overlay.blt(130, type_y, @typebitmap.bitmap, type_rect)
        end
        drawPageIcons if !move_to_learn
    end
    
    def drawSelectedMove(move_to_learn, selected_move)
        # Draw all of page four, except selected move's details
        drawPageFourSelecting(move_to_learn)
        # Set various values
        overlay = @sprites["overlay"].bitmap
        base   = Color.new(0, 0, 0)
        shadow = Color.new(208, 208, 200)
        @sprites["pokemon"].visible = false if @sprites["pokemon"]
        @sprites["pokeicon"].pokemon = @pokemon
        @sprites["pokeicon"].visible = true
        textpos = []
        # Write power and accuracy values for selected move
        case selected_move.display_damage(@pokemon)
        when 0 then textpos.push(["---", 234, 142, :right, base, shadow])   # Status move
        when 1 then textpos.push(["???", 234, 142, :right, base, shadow])   # Variable power move
        else        textpos.push([selected_move.display_damage(@pokemon).to_s, 234, 142, :right, base, shadow])
        end
        if selected_move.display_accuracy(@pokemon) == 0
          textpos.push(["---", 234, 174, :right, base, shadow])
        else
          textpos.push(["#{selected_move.display_accuracy(@pokemon)}%", 234, 174, :right, base, shadow])
        end
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        # Draw selected move's damage category icon
        imagepos = [["Graphics/UI/category", 70, 138, 0, selected_move.display_category(@pokemon) * 28, 64, 28]]
        pbDrawImagePositions(overlay, imagepos)
        # Draw selected move's description
        drawTextEx(overlay, 4, 222, 230, 5, selected_move.description, base, shadow)
    end

    def pbMarking(pokemon)
        @sprites["markingbg"].visible      = true
        @sprites["markingoverlay"].visible = true
        @sprites["markingsel"].visible     = true
        base   = Color.new(80, 80, 80)
        shadow = Color.new(160, 160, 168)
        ret = pokemon.markings.clone
        markings = pokemon.markings.clone
        mark_variants = @sprites["markingbitmap_2"].height / MARK_HEIGHT
        index = 0				  
        redraw = true
        markrect = Rect.new(0, 0, MARK_WIDTH, MARK_HEIGHT)
        loop do
          # Redraw the markings and text
          if redraw
            @sprites["markingoverlay"].bitmap.clear
            (@sprites["markingbitmap_2"].bitmap.width / MARK_WIDTH).times do |i|
              markrect.x = i * MARK_WIDTH
              markrect.y = [(markings[i] || 0), mark_variants - 1].min * MARK_HEIGHT
              @sprites["markingoverlay"].bitmap.blt((Graphics.width - 62) - (MARK_WIDTH / 2), 118 + (32 * i),
                                                      @sprites["markingbitmap_2"].bitmap, markrect)
            end
            textpos = [
              [_INTL("OK"), 412, 310, :left, base, shadow],
              [_INTL("Cancel"), 412, 342, :left, base, shadow]
            ]
            pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
            redraw = false
          end
          # Reposition the cursor
          @sprites["markingsel"].x = 396
          @sprites["markingsel"].y = 112 + (32 * index)
          Graphics.update
          Input.update
          pbUpdate
          if Input.trigger?(Input::BACK)
            pbPlayCloseMenuSE
            break
          elsif Input.trigger?(Input::USE)
            pbPlayDecisionSE
            case index
            when 6   # OK
                              
              ret = markings
              break
            when 7   # Cancel
              break
            else
              markings[index] = ((markings[index] || 0) + 1) % mark_variants
              redraw = true
            end
          elsif Input.trigger?(Input::ACTION)
            if index < 6 && markings[index] > 0
              pbPlayDecisionSE
              markings[index] = 0
              redraw = true
            end
          elsif Input.trigger?(Input::UP)
            index -= 1
            if index < 0
              index = 7
            end
            pbPlayCursorSE
          elsif Input.trigger?(Input::DOWN)
            index += 1
            if index > 7
              index = 0
            end
            pbPlayCursorSE
          end
              
        end
        @sprites["markingbg"].visible      = false
        @sprites["markingoverlay"].visible = false
        @sprites["markingsel"].visible     = false
        if pokemon.markings != ret
          pokemon.markings = ret
          return true
        end
        return false
    end
end