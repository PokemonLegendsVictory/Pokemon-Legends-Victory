#===============================================================================
# [DBK] Dynamax compatibility for [SV] Summary Screen
#===============================================================================
if PluginManager.installed?("[DBK] Dynamax")
  class PokemonSummary_Scene
    alias dynamax_drawPage drawPage
    def drawPage(page)
      if !@sprites["dynamax_overlay"]
        @sprites["dynamax_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetSystemFont(@sprites["dynamax_overlay"].bitmap)
      else
        @sprites["dynamax_overlay"].bitmap.clear
      end
      dynamax_drawPage(page)
      if @pokemon.dynamax?
        @sprites["pokemon"].clear_dynamax_pattern
        @sprites["pokeicon"].clear_dynamax_pattern
        for i in 0..@num_icons do
          @sprites["pokeicon_#{i}"].clear_dynamax_pattern
        end
      end
      overlay = @sprites["overlay"].bitmap
      coords = @pokemon.shiny? ? [144, 42] : [176, 42]
      pbDisplayGmaxFactor(@pokemon, overlay, coords[0], coords[1])
    end
    
    alias dynamax_drawPageThree drawPageThree
    def drawPageThree
      eviv = PluginManager.installed?("[MUI] Enhanced Pokemon UI") && @statToggle
      if @pokemon.dynamax_able? && !$game_switches[Settings::NO_DYNAMAX] && !eviv
        imagepos = [[sprintf(Settings::DYNAMAX_GRAPHICS_PATH + "dynamax_meter"), 386, 342]]
        textpos = [[_INTL("Nivel Dynamax"), 222, 346, :left, Color.new(246, 198, 6), Color.new(74, 97, 103)]]
        overlay = @sprites["dynamax_overlay"].bitmap
        pbDrawImagePositions(overlay, imagepos)
        pbDrawTextPositions(overlay, textpos)
        dlevel = @pokemon.dynamax_lvl
        levels = AnimatedBitmap.new(_INTL(Settings::DYNAMAX_GRAPHICS_PATH + "dynamax_levels"))
        overlay.blt(390, 346, levels.bitmap, Rect.new(0, 0, dlevel * 8, 20))
      end
      dynamax_drawPageThree
    end
    
    alias dynamax_drawSelectedMove drawSelectedMove
    def drawSelectedMove(move_to_learn, selected_move)
      dynamax_drawSelectedMove(move_to_learn, selected_move)
      @sprites["pokeicon"].clear_dynamax_pattern
    end
  end
end