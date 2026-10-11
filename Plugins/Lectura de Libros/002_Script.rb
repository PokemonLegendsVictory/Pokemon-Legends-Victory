#===============================================================================
# Sistema de Lectura de Libros
# Creado por Nyaruko
# Refactorizado para Pokémon Essentials v21+
#===============================================================================
# Instrucciones:
# 1. Crear constantes de libros en Config.rb (ej: LIBRO0, LIBRO1)
# 2. Cada libro es un array: [título, página1, página2, ...]
# 3. Límite recomendado: 165 caracteres por página
# 4. Añadir la constante a la lista LIBROS en Config.rb
# 5. Para mostrar un libro: BookScene.new.pbBook(índice)
#    Ejemplo: BookScene.new.pbBook(0) para el primer libro
#===============================================================================

class BookScene
  #-----------------------------------------------------------------------------
  # Inicializa y muestra el libro especificado
  #-----------------------------------------------------------------------------
  def pbBook(id)
    return unless id >= 0 && id < LIBROS.length
    
    initialize_viewports
    initialize_sprites
    load_book(id)
    
    main_loop
  ensure
    dispose_resources
  end
  
  private
  
  #-----------------------------------------------------------------------------
  # Inicialización de viewports
  #-----------------------------------------------------------------------------
  def initialize_viewports
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = BookConfig::MAIN_VIEWPORT_Z
    
    @page_viewport = Viewport.new(
      BookConfig::PAGE_VIEWPORT_X,
      BookConfig::PAGE_VIEWPORT_Y,
      BookConfig::PAGE_VIEWPORT_WIDTH,
      BookConfig::PAGE_VIEWPORT_HEIGHT
    )
    @page_viewport.z = BookConfig::PAGE_VIEWPORT_Z
    
    @page_bitmap = BitmapSprite.new(
      BookConfig::PAGE_VIEWPORT_WIDTH,
      BookConfig::PAGE_VIEWPORT_HEIGHT,
      @page_viewport
    )
  end
  
  #-----------------------------------------------------------------------------
  # Inicialización de sprites
  #-----------------------------------------------------------------------------
  def initialize_sprites
    @sprites = {}
    @sprites["libro"] = IconSprite.new(0, 0, @viewport)
    set_book_frame(0)
  end
  
  #-----------------------------------------------------------------------------
  # Carga los datos del libro
  #-----------------------------------------------------------------------------
  def load_book(id)
    @libro = LIBROS[id]
    @page = 0
    @max_pages = @libro.length - 1
  end
  
  #-----------------------------------------------------------------------------
  # Bucle principal de la escena
  #-----------------------------------------------------------------------------
  def main_loop
    loop do
      render_text
      Graphics.update
      Input.update
      
      break if handle_input
    end
  end
  
  #-----------------------------------------------------------------------------
  # Gestiona la entrada del usuario
  # Retorna true si se debe salir del bucle
  #-----------------------------------------------------------------------------
  def handle_input
    if Input.trigger?(Input::BACK)
      handle_exit
      return true
    elsif Input.trigger?(Input::RIGHT) && can_go_next?
      turn_page_forward
    elsif Input.trigger?(Input::LEFT) && can_go_back?
      turn_page_backward
    end
    false
  end
  
  #-----------------------------------------------------------------------------
  # Comprobaciones de navegación
  #-----------------------------------------------------------------------------
  def can_go_next?
    @page < @max_pages
  end
  
  def can_go_back?
    @page > 0
  end
  
  #-----------------------------------------------------------------------------
  # Gestiona la salida de la escena
  #-----------------------------------------------------------------------------
  def handle_exit
    pbSEPlay("select")
    pbFadeOutAndHide(@sprites) { pbUpdateSpriteHash(@sprites) }
  end
  
  #-----------------------------------------------------------------------------
  # Animación de pasar página hacia adelante
  #-----------------------------------------------------------------------------
  def turn_page_forward
    @page_viewport.visible = false
    pbSEPlay("select")
    
    animate_page_turn(1..BookConfig::ANIMATION_FRAMES)
    set_book_frame(0)
    
    @page += 1
    @page_viewport.visible = true
  end
  
  #-----------------------------------------------------------------------------
  # Animación de pasar página hacia atrás
  #-----------------------------------------------------------------------------
  def turn_page_backward
    @page_viewport.visible = false
    pbSEPlay("select")
    
    animate_page_turn(BookConfig::ANIMATION_FRAMES.downto(1))
    set_book_frame(0)
    
    @page -= 1
    @page_viewport.visible = true
  end
  
  #-----------------------------------------------------------------------------
  # Ejecuta la animación de pasar página
  #-----------------------------------------------------------------------------
  def animate_page_turn(frame_range)
    frame_range.each do |frame|
      wait_frames(BookConfig::ANIMATION_FRAME_DELAY)
      set_book_frame(frame)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Establece el frame actual del sprite del libro
  #-----------------------------------------------------------------------------
  def set_book_frame(frame)
    @sprites["libro"].setBitmap(BookConfig.book_sprite_path(frame))
  end
  
  #-----------------------------------------------------------------------------
  # Sistema de espera compatible con v21 (basado en frames)
  #-----------------------------------------------------------------------------
  def wait_frames(frames)
    frames.times do
      Graphics.update
    end
  end
  
  #-----------------------------------------------------------------------------
  # Renderiza el texto de la página actual
  #-----------------------------------------------------------------------------
  def render_text
    pbSetSystemFont(@page_bitmap.bitmap)
    @page_bitmap.bitmap.clear
    
    drawTextEx(
      @page_bitmap.bitmap,
      BookConfig::TEXT_OFFSET_X,
      BookConfig::TEXT_OFFSET_Y,
      BookConfig::TEXT_WIDTH,
      BookConfig::TEXT_HEIGHT,
      @libro[@page],
      BookConfig::TEXT_COLOR,
      BookConfig::TEXT_SHADOW
    )
  end
  
  #-----------------------------------------------------------------------------
  # Libera los recursos utilizados
  #-----------------------------------------------------------------------------
  def dispose_resources
    @viewport&.dispose
    @page_viewport&.dispose
    @page_bitmap&.dispose
    pbDisposeSpriteHash(@sprites) if @sprites
  end
end  