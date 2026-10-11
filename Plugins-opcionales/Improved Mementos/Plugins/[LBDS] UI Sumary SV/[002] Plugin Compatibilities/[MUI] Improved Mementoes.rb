#===============================================================================
# [MUI] Improved Mementos compatibility for [SV] Summary Screen
#===============================================================================
if PluginManager.installed?("[MUI] Improved Mementos")
  #===============================================================================
  # Summary handler.
  #===============================================================================
  # Rewrites the Ribbons page handler.
  #-------------------------------------------------------------------------------
  UIHandlers.add(:summary, :page_ribbons, {
    "name"      => "Mementos",
    "suffix"    => "mementos",
    "order"     => 50,
    "layout"    => proc { |pkmn, scene| scene.drawPageMementos }
  })


  #===============================================================================
  # Selection sprite.
  #===============================================================================
  # Tweaks the selection sprite used for highlighting mementos in the Summary.
  #-------------------------------------------------------------------------------
  class RibbonSelectionSprite < MoveSelectionSprite
    def refresh
      w = @movesel.width
      h = @movesel.height / 3
      style = 0
      self.x = 12 + ((self.index % 6) * 82)
      self.y = 48 + ((self.index / 6).floor * 82)
      self.bitmap = @movesel.bitmap
      if self.preselected
        self.src_rect.set(w * style, h * 2, w, h)
      elsif self.showActive
        self.src_rect.set(w * style, 0, w, h)
      else
        self.src_rect.set(w * style, h, w, h)
      end
    end
  end

  #===============================================================================
  # Summary UI.
  #===============================================================================
  # Changes and additions to add the Mementos page in the Summary.
  #-------------------------------------------------------------------------------
  class PokemonSummary_Scene
    alias memento_pbStartScene pbStartScene
    def pbStartScene(party, partyindex, inbattle = false, page = 1, allow_learn_moves = true)
      memento_pbStartScene(party, partyindex, inbattle)
      @sprites["uparrow"].x = (Graphics.width / 2) - 14
      @sprites["uparrow"].y = 30
      @sprites["downarrow"].x = (Graphics.width / 2) - 14
      @sprites["downarrow"].y = 184
      @sprites["mementosel"] = RibbonSelectionSprite.new(@viewport)
      @sprites["mementosel"].showActive = true
      @sprites["mementosel"].visible = false
      @sprites["mementos"] = MementoSprite.new(GameData::Ribbon::DATA.first[0], 0, @viewport)
      @sprites["mementos"].visible = false
    end
    
    #-----------------------------------------------------------------------------
    # Draws the Mementos page.
    #-----------------------------------------------------------------------------
    def drawPageMementos
      overlay = @sprites["overlay"].bitmap
      ylwBase   = Color.new(246, 198, 6)
      ylwShadow = Color.new(74, 97, 103) 
      whtBase   = Color.new(248, 248, 248)
      whtShadow = Color.new(74, 112, 175)
      @sprites["uparrow"].visible   = false
      @sprites["downarrow"].visible = false
      path  = Settings::MEMENTOS_GRAPHICS_PATH
      idnum = type = name = title = "---"
      memento_data = GameData::Ribbon.try_get(@pokemon.memento)
      xpos = 218
      ypos = 32
      imagepos = []
      if memento_data
        title_data = memento_data.title_upcase(@pokemon)
        icon  = memento_data.icon_position
        idnum = (icon + 1).to_s
        rank  = @pokemon.getMementoRank(@pokemon.memento)
        name  = memento_data.name
        title = _INTL("'{1}'", title_data) if !nil_or_empty?(title_data)
        type  = (memento_data.is_ribbon?) ? "Cinta" : "Marca"
        typeX = (memento_data.is_ribbon?) ? 179 : 184
        imagepos.push([path + "mementos", xpos + 12, ypos + 14, 78 * (icon % 8), 78 * (icon / 8).floor, 78, 78],
                      [path + "memento_icon", xpos + typeX, ypos + 7, (memento_data.is_ribbon?) ? 0 : 28, 0, 28, 28])
        if rank < 5
          rank.times do |i| 
            offset = (rank == 1) ? 44 : (rank == 2) ? 35 : (rank == 3) ? 26 : 17
            imagepos.push([path + "memento_rank", xpos + 182 + offset + (18 * i), ypos + 77])
          end
        else
          imagepos.push([path + "memento_rank", xpos + 246, ypos + 77])
        end
      end
      pbDrawImagePositions(overlay, imagepos)
      textpos = [
        [_INTL("Tipo"),            xpos + 100, ypos + 12,  0, ylwBase, ylwShadow],
        [_INTL("ID"),          xpos + 100, ypos + 44,  0, ylwBase, ylwShadow],
        [_INTL("#{idnum}"),         xpos + 234, ypos + 44,  2, whtBase, whtShadow],
        [_INTL("Rango"),            xpos + 100, ypos + 76,  0, ylwBase, ylwShadow],
        [_INTL("Nombre"),            xpos + 8, ypos + 122, 0, ylwBase, ylwShadow],
        [_INTL("#{name}"),          xpos + 8, ypos + 156, 0, whtBase, whtShadow],
        [_INTL("Título Concedido"), xpos + 8, ypos + 202, 0, ylwBase, ylwShadow],
        [_INTL("#{title}"),         xpos + 8, ypos + 236, 0, whtBase, whtShadow]
      ]
      drawButton(overlay, xpos + 68, ypos + 268, "Ver") 
      if memento_data
        typeX = (memento_data.is_ribbon?) ? 204 : 214
        textpos.push([_INTL("#{type}"), xpos + typeX, ypos + 12, 0, whtBase, whtShadow])
        textpos.push([_INTL("#{rank}"), xpos + 240, ypos + 76, 1, whtBase, whtShadow]) if rank > 4
      else
        textpos.push([_INTL("#{type}"), xpos + 232, ypos + 12, 2, whtBase, whtShadow])
      end
      pbDrawTextPositions(overlay, textpos)
    end
    
    #-----------------------------------------------------------------------------
    # Draws the mementos display window to scroll through.
    #-----------------------------------------------------------------------------
    def drawSelectedRibbon(filter, index, page, maxpage)
      base   = Color.new(248, 248, 248)
      shadow = Color.new(74, 112, 175)
      nameBase   = Color.new(246, 198, 6)
      nameShadow = Color.new(74, 97, 103)
      for i in 0..@num_icons do
        @sprites["pokeicon_#{i}"].visible = false
      end
      path = Settings::MEMENTOS_GRAPHICS_PATH
      page_size = MementoSprite::PAGE_SIZE
      idxList = (page * page_size) + index
      memento_data = GameData::Ribbon.try_get(filter[idxList])
      overlay = @sprites["overlay"].bitmap
      activesel = @sprites["mementosel"]
      if filter.include?(@pokemon.memento)
        activeidx = filter.index(@pokemon.memento)
        activesel.index = activeidx - page_size * page
        activesel.activePage = (activeidx / page_size).floor
      end
      activesel.visible = activesel.activePage == page
      preselect = @sprites["ribbonpresel"]
      preselect.visible = preselect.activePage == page
      @sprites["ribbonsel"].index = index
      @sprites["ribbonsel"].activePage = page
      @sprites["uparrow"].visible = page > 0
      @sprites["uparrow"].z = @sprites["mementos"].z + 1
      @sprites["downarrow"].visible = page < maxpage
      @sprites["downarrow"].z = @sprites["mementos"].z + 1
      @sprites["mementos"].setMementos(filter, page) if !filter.empty?
      imagepos = [[path + "overlay", 0, 0]]
      imagepos.push([path + "memento_active", 36, 226]) if memento_data && memento_data.id == @pokemon.memento
      imagepos.push([path + "memento_icon", 8, 8, (memento_data.is_ribbon?) ? 0 : 28, 0, 28, 28]) if memento_data
      rank = (memento_data) ? @pokemon.getMementoRank(memento_data.id) : 0
      if rank < 5
        rank.times do |i| 
          offset = (rank == 1) ? 44 : (rank == 2) ? 35 : (rank == 3) ? 26 : 17
          imagepos.push([path + "memento_rank", 416 + offset + (18 * i), 226])
        end
      else
        imagepos.push([path + "memento_rank", 480, 226])
      end
      pbDrawImagePositions(overlay, imagepos)
      name  = (memento_data) ? memento_data.name : "---"
      desc  = (memento_data) ? memento_data.description : ""
      count = (memento_data) ? "#{idxList + 1}/#{filter.length}" : ""
      title_data = (memento_data) ? memento_data.title_upcase(@pokemon) : ""
      title = (!nil_or_empty?(title_data)) ? _INTL("'{1}'", title_data) : "---"
      textpos = [
        [_INTL("#{count}"), 210, 12, 1, nameBase, nameShadow],
        [name, Graphics.width / 2, 224, 2, nameBase, nameShadow],
        [_INTL("Title Conferred"), 12, 258, 0, nameBase, nameShadow],
        [title, 346, 260, 2, base, shadow]
      ]
      if memento_data
        case @mementoFilter
        when :ribbon   then header = "Cinta"
        when :mark     then header = "Marca"
        when :contest  then header = "Concurso"
        when :league   then header = "Liga"
        when :frontier then header = "Frontera"
        when :memorial then header = "Memoria"
        when :gift     then header = "Especial"
        else                header = "Memento"
        end
        textpos.push([_INTL("#{header}"), 40, 12, 0, nameBase, nameShadow])
        textpos.push([_INTL("#{rank}"), 476, 224, 1, nameBase, nameShadow]) if rank > 4
      end
      pbDrawTextPositions(overlay, textpos)
      drawTextEx(overlay, 12, 290, 494, 3, desc, base, shadow)
    end
    
    #-----------------------------------------------------------------------------
    # The controls while viewing all of a Pokemon's mementos.
    #-----------------------------------------------------------------------------
    def pbRibbonSelection
      @mementoFilter = (Settings::COLLAPSE_RANKED_MEMENTOS) ? :rank : nil
      filter    = pbFilteredMementos
      page      = 0
      index     = 0
      row_size  = MementoSprite::ROW_SIZE
      page_size = MementoSprite::PAGE_SIZE
      maxpage   = ((filter.length - 1) / page_size).floor
      @sprites["ribbonsel"].index = 0
      @sprites["ribbonsel"].visible = true
      @sprites["ribbonpresel"].index = 0
      @sprites["ribbonpresel"].activePage = -1
      @sprites["mementosel"].index = 0
      @sprites["mementosel"].activePage = -1
      switching = false
      if filter.include?(@pokemon.memento)
        idxList = filter.index(@pokemon.memento)
        page = (idxList / page_size).floor
        index = idxList - page_size * page
      end
      drawSelectedRibbon(filter, index, page, maxpage)
      loop do
        Graphics.update
        Input.update
        pbUpdate
        count = 0
        dorefresh = false
        #-------------------------------------------------------------------------
        if Input.repeat?(Input::UP)
          if index >= row_size
            index -= row_size
            dorefresh = true
          else
            if page > 0
              page -= 1
              index += row_size
              dorefresh = true
            elsif maxpage > 0
              page = maxpage
              count = @sprites["mementos"].getPageSize(filter, page) - 1
              if index + row_size <= count
                index += row_size
              elsif index > count
                index = count
              end
              dorefresh = true
            end
          end
        #-------------------------------------------------------------------------
        elsif Input.repeat?(Input::DOWN)
          if index < row_size
            count = @sprites["mementos"].getPageSize(filter, page) - 1
            if count < index + row_size
              if page == maxpage && maxpage > 0
                page = 0
                index -= row_size if index >= row_size
                dorefresh = true
              end
            else
              index += row_size
              dorefresh = true
            end
          else
            if page < maxpage
              page += 1
              count = @sprites["mementos"].getPageSize(filter, page) - 1
              index -= row_size
              index = count if index > count
              dorefresh = true
            elsif maxpage > 0
              page = 0
              index -= row_size if index >= row_size
              dorefresh = true
            end
          end
        #-------------------------------------------------------------------------
        elsif Input.repeat?(Input::LEFT)
          if index > 0
            index -= 1
            dorefresh = true
          else
            if page > 0
              page -= 1
              count = @sprites["mementos"].getPageSize(filter, page) - 1
              index = count
              dorefresh = true
            else
              page = maxpage
              count = @sprites["mementos"].getPageSize(filter, page) - 1
              next if count == 0 && page == 0
              index = count
              dorefresh = true
            end
          end
        #-------------------------------------------------------------------------
        elsif Input.repeat?(Input::RIGHT)
          count = @sprites["mementos"].getPageSize(filter, page) - 1
          next if count == 0 && page == 0
          if index < count
            index += 1
            dorefresh = true
          else
            if page < maxpage
              page += 1
              index = 0
              dorefresh = true
            else
              page = 0
              index = 0
              dorefresh = true
            end
          end
        #-------------------------------------------------------------------------
        elsif Input.repeat?(Input::JUMPUP)
          if page > 0
            page -= 1
            index = 0
            dorefresh = true
          end
        #-------------------------------------------------------------------------
        elsif Input.repeat?(Input::JUMPDOWN)
          if page < maxpage
            page += 1
            index = 0
            dorefresh = true
          end
        #-------------------------------------------------------------------------
        elsif Input.trigger?(Input::ACTION)
          if filter.include?(@pokemon.memento)
            oldpg, oldidx = page, index
            idxList = filter.index(@pokemon.memento)
            page = (idxList / page_size).floor
            index = idxList - page_size * page
            dorefresh = (page != oldpg || index != oldidx)
          end
        #-------------------------------------------------------------------------
        elsif Input.trigger?(Input::USE)
          if switching
            memento = @sprites["ribbonpresel"].getMemento(filter)
            oldidx = filter.index(memento)
            newidx = (page * page_size) + index
            @pokemon.ribbons[oldidx] = @pokemon.ribbons[newidx]
            @pokemon.ribbons[newidx] = memento
            @sprites["ribbonpresel"].activePage = -1
            @sprites["ribbonpresel"].visible = false
            switching = false
            dorefresh = true
          else
            memento = @sprites["ribbonsel"].getMemento(filter, page)
            option = pbMementoOptions(memento)
            case option
            when :endscreen then break
            when :switching then switching = true
            when :dorefresh then dorefresh = true; page = index = 0
            end
          end
        #-------------------------------------------------------------------------
        elsif Input.trigger?(Input::BACK)
          (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
          break if !switching
          @sprites["ribbonpresel"].activePage = -1
          @sprites["ribbonpresel"].visible = false
          switching = false
        end
        #-------------------------------------------------------------------------
        if dorefresh && !filter.empty?
          pbPlayCursorSE
          filter = pbFilteredMementos
          maxpage = ((filter.length - 1) / page_size).floor
          drawSelectedRibbon(filter, index, page, maxpage)
        end
      end
      @sprites["mementosel"].activePage = -1
      @sprites["mementosel"].visible = false
      @sprites["ribbonsel"].visible = false
      @sprites["mementos"].visible = false
    end
  end
end