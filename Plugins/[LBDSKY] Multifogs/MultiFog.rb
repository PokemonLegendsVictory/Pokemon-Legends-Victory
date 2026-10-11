#===============================================================================
# Multifogs 2.1 (adaptado a Essentials v21)
# Por JessWishes | Jinta
#===============================================================================

#-------------------------------------------------------------------------------
# Constantes
#-------------------------------------------------------------------------------

# Hacer que el o los gráficos de fog se mantengan estáticos en el mapa
JSS_MFOGS_NOPLANE = false

# Carpeta donde se guardan los gráficos de fogs
JSS_MFOGS_DIR = File.join("Graphics", "Fogs")

#-------------------------------------------------------------------------------
# Eliminar todos los gráficos actuales
#-------------------------------------------------------------------------------
def jess_fogs_disposeAll
  return unless $scene.is_a?(Scene_Map)
  spriteset = $scene.spriteset
  return if !spriteset || spriteset.j_fog.empty?
  spriteset.j_fog.each_with_index do |_fog, i|
    if spriteset.j_fog_bmp[i]
      spriteset.j_fog_bmp[i].dispose
      spriteset.j_fog_bmp[i] = nil
    end
    spriteset.j_fog[i] = nil
  end
  spriteset.j_fog.clear
  spriteset.j_fog_bmp.clear
end

#-------------------------------------------------------------------------------
# Crear un nuevo gráfico de fog
#-------------------------------------------------------------------------------
def jess_fogs(id=0, nombre="", hue=0, opacity=255, blend=0, zoom=1.0, sx=0, sy=0, stf=true)
  return unless $scene.is_a?(Scene_Map)
  spriteset = $scene.spriteset
  spriteset.j_fog = [] if !spriteset.j_fog
  spriteset.j_fog[id] = [nombre, hue, opacity, blend, zoom, sx, sy, stf]
end

#-------------------------------------------------------------------------------
# Spriteset_Map
#-------------------------------------------------------------------------------
class Spriteset_Map
  attr_accessor :j_fog
  attr_accessor :j_fog_bmp

  alias jess_initialize initialize
  def initialize(map=nil)
    jess_initialize(map)
    @j_fog = []
    @j_fog_bmp = []
  end

  alias jess_update update
  def update
    jess_update
    vista = @viewport1
    @j_fog     ||= []
    @j_fog_bmp ||= []

    return if @j_fog.empty?
    @j_fog.each_with_index do |fog, fg|
      next if fog.nil?

      if fog[0] == ""
        @j_fog_bmp[fg]&.dispose
        @j_fog_bmp[fg] = nil
        next
      end

      # Crear si no existe
      if !@j_fog_bmp[fg]
        @j_fog_bmp[fg] = Plane.new(vista)
        @j_fog_bmp[fg].z = 3000
        bmp = Bitmap.new(File.join(JSS_MFOGS_DIR, fog[0]))
        bmp.hue_change(fog[1])
        @j_fog_bmp[fg].bitmap     = bmp
        @j_fog_bmp[fg].opacity    = fog[2]
        @j_fog_bmp[fg].blend_type = fog[3]
        @j_fog_bmp[fg].zoom_x     = fog[4]
        @j_fog_bmp[fg].zoom_y     = fog[4]
        # Guardamos offset inicial para movimiento
        @fog_ox ||= []
        @fog_oy ||= []
        @fog_ox[fg] = 0
        @fog_oy[fg] = 0
      end

      # --- Movimiento continuo ---
      @fog_ox[fg] += fog[5] if fog[5] != 0
      @fog_oy[fg] += fog[6] if fog[6] != 0

      if !JSS_MFOGS_NOPLANE
        if fog[7] # Seguir jugador
          @j_fog_bmp[fg].ox = @map.display_x / 4 + @fog_ox[fg]
          @j_fog_bmp[fg].oy = @map.display_y / 4 + @fog_oy[fg]
        else      # Estático
          @j_fog_bmp[fg].ox = @fog_ox[fg]
          @j_fog_bmp[fg].oy = @fog_oy[fg]
        end
      end
    end
  end

  alias jess_dispose dispose
  def dispose
    jess_dispose
    if @j_fog_bmp
      @j_fog_bmp.each { |fog| fog.dispose if fog }
    end
  end
end