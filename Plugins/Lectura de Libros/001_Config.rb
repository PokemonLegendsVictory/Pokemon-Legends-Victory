#===============================================================================
# Sistema de Lectura de Libros - Configuración
# Creado por Nyaruko
#===============================================================================

module BookConfig
  #-----------------------------------------------------------------------------
  # Rutas de recursos
  #-----------------------------------------------------------------------------
  GRAPHICS_FOLDER = "Graphics/Plugins/Lectura libros"
  
  # Nombre base de las imágenes de animación (0.png a 10.png)
  def self.book_sprite_path(frame)
    File.join(GRAPHICS_FOLDER, frame.to_s)
  end
  
  #-----------------------------------------------------------------------------
  # Configuración de viewport y posicionamiento
  #-----------------------------------------------------------------------------
  PAGE_VIEWPORT_X      = 116
  PAGE_VIEWPORT_Y      = 58
  PAGE_VIEWPORT_WIDTH  = 256
  PAGE_VIEWPORT_HEIGHT = 286
  MAIN_VIEWPORT_Z      = 99998
  PAGE_VIEWPORT_Z      = 99999
  
  #-----------------------------------------------------------------------------
  # Configuración de animación
  #-----------------------------------------------------------------------------
  # Frames de espera entre cada imagen de animación (compatible con v21)
  ANIMATION_FRAME_DELAY = 2
  
  # Número total de frames de animación del libro (0 a 10)
  ANIMATION_FRAMES = 10
  
  #-----------------------------------------------------------------------------
  # Configuración de texto
  #-----------------------------------------------------------------------------
  TEXT_OFFSET_X    = 0
  TEXT_OFFSET_Y    = 10
  TEXT_WIDTH       = 256
  TEXT_HEIGHT      = 10
  TEXT_COLOR       = Color.new(40, 40, 40)
  TEXT_SHADOW      = Color.new(120, 120, 120)
  
  # Límite de caracteres por página (referencia)
  MAX_CHARS_PER_PAGE = 165
end

#===============================================================================
# Definición de libros
# Cada libro es un array donde el primer elemento es el título
# y los siguientes son las páginas
#===============================================================================

LIBRO0 = [
  _INTL("LIBRO DE EJEMPLO"),
  _INTL("Página 1"),
  _INTL("Página 2"),
  _INTL("Página 3"),
  _INTL("Página 4"),
  _INTL("Página 5"),
]

LIBRO1 = [
  _INTL("LIBRO DE EJEMPLO 2"),
  _INTL("Página 1"),
  _INTL("Página 2"),
  _INTL("Página 3"),
  _INTL("Página 4"),
  _INTL("Página 5"),
]

# Lista maestra de libros - añadir nuevos libros aquí
LIBROS = [LIBRO0, LIBRO1]
