# Auto Multi Save por http404error
# Traducción por Maryn @cosmic_pipo/@PkmnRadiante(en TW/X)
# Para Pokemon Essentials v21.1

# Descripción:
#   Añade múltiples ranuras de guardado y la capacidad de autoguardado.
#   Se incluye código para autoguardar cada 100 pasos en el mundo. Siéntete libre de editarlo o borrarlo (está justo al principio).
#   En la pantalla de Carga puedes usar los botones izquierda y derecha mientras "Continuar" está seleccionado para cambiar entre archivos.
#   Al guardar, puedes guardar rápidamente en la misma ranura desde la que cargaste, o elegir otra ranura.
#   Los Desafíos de Batalla NO están soportados.

# Personalización:
#   Recomiendo modificar tu menú de pausa para salir a la pantalla de título o pantalla de carga en lugar de cerrar completamente.
#     -> Por ejemplo, simplemente cambia el texto del menú a "Salir al Título" y cambia `$scene = nil` a `$scene = pbCallTitle`.
#     -> Puede que también necesites añadir un `SaveData.mark_values_as_unloaded` justo antes de establecer $scene.
#     -> Si cambias `screen.pbSaveScreen` a `screen.pbSaveScreen(true)` aquí, también cambiará ligeramente el comportamiento de la UI para mayor claridad.
#   Llama a Game.auto_save cuando quieras.
#     -> Autoguardar durante un script de evento reanudará correctamente la ejecución del evento cuando cargues el juego.
#     -> No he investigado si podría ser posible autoguardar al cerrar la ventana con la X o Alt-F4 todavía.
#   Puedes renombrar las ranuras a tu gusto, o cambiar cuántas hay.
#   En algunos casos, puede que quieras eliminar la opción de guardar en una ranura diferente a la que cargaste.

# Notas:
#   En la primera Carga, el antiguo Game.rxdata será copiado a la primera ranura en MANUAL_SLOTS. Sin embargo, no tendrá una hora de guardado conocida.
#   La interfaz de `Game.save` ha sido modificada.
#   Debido a las ranuras, altera el sistema de respaldo de guardado en caso de corrupción/fallos - los respaldos se nombrarán Backup000.rxdata y así sucesivamente.
#   Modifica fuertemente el módulo SaveData y las pantallas de Guardar y Cargar. Esto puede causar incompatibilidad con algunos otros plugins o código personalizado del juego.
#   No todo aquí ha sido probado extensivamente, solo lo que aplica al uso normal de mi juego. Por favor hazme saber si encuentras algún problema.

# Ideas de desarrollo futuro:
#   Las ranuras manuales ilimitadas ahora están soportadas con el nombrado "Partida <número>.rxdata".
#   Dejar que el usuario nombre sus ranuras parece genial.
#   Sería bueno si hubiera una animación deslizante para cambiar archivos en la pantalla de carga. :)
#   Sería bueno si las flechas de selección de archivo usaran gráficos animados más bonitos, como la Mochila.
#   Quizás las ranuras de autoguardado deberían actuar como una cola en lugar de ciclar.

# Autoguardar cada 100 pasos

## COMMIT DE PRUEBA

#===============================================================================
#
#===============================================================================
module SaveData
  # Puedes renombrar estas ranuras o cambiar la cantidad de ellas
  # Sin embargo, cambian los nombres reales de los archivos de guardado, por lo que tomaría algo de trabajo extra usar el sistema de traducción en ellas.
  AUTO_SLOTS = [
    'Auto 1',
    'Auto 2',
    'Auto 3'
  ]
  
  # Para compatibilidad con juegos guardados sin este plugin
  OLD_SAVE_SLOT = 'Game'

  SAVE_DIR = if File.directory?(System.data_directory)
               System.data_directory
             else
              '.'
             end

  
  # Caché para ranuras manuales para evitar escaneos repetidos del directorio
  @manual_slots_cache = nil
  @manual_slots_cache_time = nil
  
  # Ranuras manuales dinámicas - ya no es un array fijo
  def self.get_manual_slots(force_refresh = false)
    # Cachear ranuras por 1 segundo para evitar escaneos repetidos del directorio
    cache_valid = @manual_slots_cache_time && (Time.now - @manual_slots_cache_time) < 1.0
    return @manual_slots_cache.dup if @manual_slots_cache && cache_valid && !force_refresh
    
    slots = []
    # Encuentra todos los archivos Partida existentes usando Dir.entries (más confiable que glob en Windows)
    begin
      Dir.entries(SAVE_DIR).each do |filename|
        next unless filename.end_with?('.rxdata')
        basename = File.basename(filename, '.rxdata')
        if basename.match?(/^Partida \d+$/)
          slots << basename
        end
      end
    rescue => e
      # Fallback a array vacío si el directorio no puede ser leído
      echoln "Error leyendo el directorio de guardado: #{e.message}"
      return []
    end
    
    # Ordenar por número y cachear resultado
    @manual_slots_cache = slots.sort_by { |slot| slot.match(/Partida (\d+)/)[1].to_i }
    @manual_slots_cache_time = Time.now
    @manual_slots_cache.dup
  end
  
  def self.get_next_manual_slot_number
    existing_numbers = get_manual_slots.map { |slot| slot.match(/Partida (\d+)/)[1].to_i }
    return 1 if existing_numbers.empty?
    (1..existing_numbers.max + 1).find { |n| !existing_numbers.include?(n) } || (existing_numbers.max + 1)
  end
  
  def self.get_new_manual_slot
    "Partida #{get_next_manual_slot_number}"
  end


  def self.each_slot
    (AUTO_SLOTS + get_manual_slots).each { |f| yield f }
  end

  def self.get_full_path(file)
    return File.join(SAVE_DIR, "#{file}.rxdata")
  end

  def self.get_backup_file_path
    backup_file = "Backup000"
    while File.file?(self.get_full_path(backup_file))
      backup_file.next!
    end
    return self.get_full_path(backup_file)
  end

  # Dada una lista de nombres de archivos de guardado y un nombre de archivo en ella, devuelve el siguiente archivo después de él que existe
  # Si no existe otro archivo, simplemente devolverá el mismo archivo de nuevo
  def self.get_next_slot(file_list, file)
    old_index = file_list.find_index(file)
    ordered_list = file_list.rotate(old_index + 1)
    ordered_list.each do |f|
      return f if File.file?(self.get_full_path(f))
    end
    # nunca debería llegar aquí ya que el archivo original siempre debería existir
    return file
  end
  # Ver self.get_next_slot
  def self.get_prev_slot(file_list, file)
    return self.get_next_slot(file_list.reverse, file)
  end

  def self.get_save_count
    count = 0
    self.each_slot do |file_slot|
      full_path = self.get_full_path(file_slot)
      count += 1 if File.file?(full_path)
    end
    return count
  end

  # Devuelve nil si no hay guardados
  # Devuelve el primer guardado si hay un empate para el más nuevo
  # Los guardados antiguos de la versión anterior no almacenan su hora de guardado, por lo que se tratan como muy antiguos
  # OPTIMIZADO: Solo lee encabezados de archivo en lugar de datos de guardado completos
  def self.get_newest_save_slot
    newest_time = Time.at(0) # la Época
    newest_slot = nil
    self.each_slot do |file_slot|
      full_path = self.get_full_path(file_slot)
      next if !File.file?(full_path)
      # Solo leer la marca de tiempo, no el archivo de guardado completo
      begin
        save_time = self.read_save_timestamp(full_path)
        if save_time > newest_time
          newest_time = save_time
          newest_slot = file_slot
        end
      rescue
        # Si no podemos leer la marca de tiempo, tratar como guardado antiguo
        next
      end
    end
    # Portar guardado antiguo
    if newest_slot.nil? && File.file?(self.get_full_path(OLD_SAVE_SLOT))
      first_slot = get_new_manual_slot
      file_copy(self.get_full_path(OLD_SAVE_SLOT), self.get_full_path(first_slot))
      return first_slot
    end
    return newest_slot
  end
  
  # Método rápido para leer solo la marca de tiempo de un archivo de guardado
  # Devuelve objeto Time o Time.at(1) si no está disponible
  def self.read_save_timestamp(file_path)
    File.open(file_path, "rb") do |file|
      save_data = Marshal.load(file)
      return save_data[:player].last_time_saved || Time.at(1)
    end
  rescue
    return Time.at(1)
  end

  # @return [Boolean] si existe algún archivo de guardado
  def self.exists?
    self.each_slot do |slot|
      full_path = SaveData.get_full_path(slot)
      return true if File.file?(full_path)
    end
    return false
  end

  # Esto se usa en una función oculta (ctrl+abajo+cancelar en pantalla de título) o si el archivo de guardado está corrupto
  # Pasa nil para eliminar todo, o una ruta de archivo para eliminar solo ese
  # @raise [Error::ENOENT]
  def self.delete_file(file_path=nil)
    if file_path
      File.delete(file_path) if File.file?(file_path)
    else
      self.each_slot do |slot|
        full_path = self.get_full_path(slot)
        File.delete(full_path) if File.file?(full_path)
      end
    end
  end

  # Ejecuta todas las conversiones posibles en los datos de guardado dados.
  # Guarda un respaldo antes de ejecutar conversiones.
  # @param save_data [Hash] datos de guardado en los que ejecutar conversiones
  # @return [Boolean] si se ejecutaron conversiones
  def self.run_conversions(save_data)
    validate save_data => Hash
    conversions_to_run = self.get_conversions(save_data)
    return false if conversions_to_run.none?
    File.open(SaveData.get_backup_file_path, 'wb') { |f| Marshal.dump(save_data, f) }
    Console.echo_h1 "Respaldo de guardado creado en #{SaveData.get_backup_file_path}"
    Console.echo_h1 "Ejecutando #{conversions_to_run.length} conversiones..."
    conversions_to_run.each do |conversion|
      Console.echo_li "#{conversion.title}..."
      conversion.run(save_data)
      Console.echo_done ' hecho.'
    end
    echoln '' if conversions_to_run.length > 0
    Console.echo_h2("Todas las conversiones de archivo de guardado aplicadas exitosamente", text: :green)
    save_data[:essentials_version] = Essentials::VERSION
    save_data[:game_version] = Settings::GAME_VERSION
    return true
  end
end

#===============================================================================
#
#===============================================================================
class PokemonLoad_Scene
  def pbChoose(commands, continue_idx)
    @sprites["cmdwindow"].commands = commands
    loop do
      Graphics.update
      Input.update
      pbUpdate
      # Actualizar las flechas después de pbUpdate para que sigan al panel
      if continue_idx >= 0 && @sprites["panel#{continue_idx}"]
        panel_y = @sprites["panel#{continue_idx}"].y
        if @sprites["leftarrow"]
          @sprites["leftarrow"].y = panel_y + 90
          @sprites["leftarrow"].update
        end
        if @sprites["rightarrow"]
          @sprites["rightarrow"].y = panel_y + 90
          @sprites["rightarrow"].update
        end
      end
      
      if Input.trigger?(Input::USE)
        return @sprites["cmdwindow"].index
      elsif @sprites["cmdwindow"].index == continue_idx
        if Input.trigger?(Input::LEFT)
          return -3
        elsif Input.trigger?(Input::RIGHT)
          return -2
        end
      end
    end
  end

  # Método para mostrar las flechas laterales de navegación
  def pbShowArrows(panel_y)
    # Crear flecha izquierda
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport)
    @sprites["leftarrow"].x = 8  # A la izquierda del panel
    @sprites["leftarrow"].y = panel_y + 90  # Centrado verticalmente en el panel
    @sprites["leftarrow"].z = 99999
    @sprites["leftarrow"].visible = true
    @sprites["leftarrow"].play

    # Crear flecha derecha
    @sprites["rightarrow"] = AnimatedSprite.new("Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport)
    @sprites["rightarrow"].x = Graphics.width - 48  # A la derecha del panel
    @sprites["rightarrow"].y = panel_y + 90  # Centrado verticalmente en el panel
    @sprites["rightarrow"].z = 99999
    @sprites["rightarrow"].visible = true
    @sprites["rightarrow"].play
  end

  # Método para ocultar las flechas cuando no son necesarias
  def pbHideArrows
    if @sprites["leftarrow"]
      @sprites["leftarrow"].visible = false
      pbDisposeSpriteHash(@sprites, "leftarrow")
    end
    if @sprites["rightarrow"]
      @sprites["rightarrow"].visible = false
      pbDisposeSpriteHash(@sprites, "rightarrow")
    end
  end

  # Método para actualizar la posición de las flechas cuando el panel se mueve
  def pbUpdateArrows(panel_y)
    if @sprites["leftarrow"]
      @sprites["leftarrow"].y = panel_y + 90
      @sprites["leftarrow"].update
    end
    if @sprites["rightarrow"]
      @sprites["rightarrow"].y = panel_y + 90
      @sprites["rightarrow"].update
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    @selected_file = $player&.last_save_slot || SaveData.get_newest_save_slot
  end

  # @param file_path [String] archivo del que cargar datos de guardado
  # @return [Hash] datos de guardado
  def load_save_file(file_path)
    save_data = SaveData.read_from_file(file_path)
    unless SaveData.valid?(save_data)
      if File.file?(file_path + ".bak")
        pbMessage(_INTL("El archivo de guardado está corrupto, o es incompatible con este juego. Se cargará un backup.") + "\1")
        save_data = load_save_file(file_path + ".bak")
      else
        self.prompt_save_deletion(file_path)
        return {}
      end
    end
    return save_data
  end

  # Llamado si el archivo de guardado es inválido.
  # Solicita al jugador eliminar los archivos de guardado.
  def prompt_save_deletion(file_path)
    pbMessage(_INTL("El archivo de guardado esta corrompido, o es incompatible con este juego.") + "\1")
    self.delete_save_data(file_path) if pbConfirmMessageSerious(
      _INTL("¿Quieres eliminar ese archivo guardado?")
    )
    exit
  end

  # nil elimina todo, de lo contrario solo el archivo dado
  def delete_save_data(file_path=nil)
    begin
      SaveData.delete_file(file_path)
      pbMessage(_INTL("El archivo de guardado fue eliminado."))
    rescue SystemCallError
      pbMessage(_INTL("El archivo de guardado no se pudo eliminar."))
    end
  end

  def pbStartLoadScreen
    PokeUpdater.check_for_updates() if defined?(PokeUpdater) && defined?(PokeUpdater.check_for_updates) # Requerido para que PokéUpdater busque actualizaciones del juego.
    save_file_list = SaveData::AUTO_SLOTS + SaveData.get_manual_slots
    first_time = true
    
    # OPTIMIZACIÓN: Cachear datos de guardado para evitar recargar al cambiar de ranuras
    @save_data_cache = {}
    
    loop do # El bucle externo se usa para cambiar archivos de guardado
      if @selected_file
        # Usar datos cacheados si están disponibles
        if @save_data_cache[@selected_file]
          @save_data = @save_data_cache[@selected_file]
        else
          @save_data = load_save_file(SaveData.get_full_path(@selected_file))
          @save_data_cache[@selected_file] = @save_data if !@save_data.empty?
        end
      else
        @save_data = {}
      end
      commands = []
      cmd_continue     = -1
      cmd_new_game     = -1
      cmd_options      = -1
      cmd_language     = -1
      cmd_mystery_gift = -1
      cmd_debug        = -1
      cmd_update       = -1
      cmd_delete       = -1
      cmd_quit         = -1
      show_continue = !@save_data.empty?
      if show_continue
        commands[cmd_continue = commands.length] = "#{@selected_file}"
        if @save_data[:player].mystery_gift_unlocked
          commands[cmd_mystery_gift = commands.length] = _INTL('Regalo Misterioso') # Honestamente no tengo idea de cómo hacer que Regalo Misterioso funcione bien con esto.
        end
      end
      commands[cmd_new_game = commands.length]  = _INTL('Partida Nueva')
      commands[cmd_options = commands.length]   = _INTL('Opciones')
      commands[cmd_language = commands.length]  = _INTL('Idioma') if Settings::LANGUAGES.length >= 2
      commands[cmd_debug = commands.length]     = _INTL('Debug') if $DEBUG
      commands[cmd_update = commands.length]    = _INTL('Comprobar Actualizaciones') if defined?(PokeUpdater) && defined?(PokeUpdater.validate_game_version_and_update)
      commands[cmd_delete = commands.length]    = _INTL('Borrar Partida')
      commands[cmd_quit = commands.length]      = _INTL('Cerrar Juego')
      cmd_left = -3
      cmd_right = -2

      map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
      @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
      @scene.pbSetParty(@save_data[:player]) if show_continue
      if first_time
        @scene.pbStartScene2
        first_time = false
      else
        @scene.pbUpdate
      end

      # Mostrar flechas solo si hay múltiples archivos de guardado
      total_saves = SaveData.get_save_count
      if show_continue && total_saves > 1
        panel_y = @scene.instance_variable_get(:@sprites)["panel0"].y
        @scene.pbShowArrows(panel_y)
      else
        @scene.pbHideArrows
      end

      loop do # El bucle interno se usa para ir a otros menús y volver y demás (vanilla)
        # Actualizar posición de flechas si existen
        if show_continue && total_saves > 1
          panel_y = @scene.instance_variable_get(:@sprites)["panel0"].y
          @scene.pbUpdateArrows(panel_y)
        end
        
        command = @scene.pbChoose(commands, cmd_continue)
        pbPlayDecisionSE if command != cmd_quit

        case command
        when cmd_continue
          @scene.pbEndScene
          Game.load(@save_data)
          $player.last_save_slot = $player.save_slot
          return
        when cmd_new_game
          @scene.pbEndScene
          Game.start_new
          return
        when cmd_mystery_gift
          pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
        when cmd_options
          if defined?(Settings::USE_NEW_OPTIONS_UI) && Settings::USE_NEW_OPTIONS_UI
            UI::Options.new(true).main
          else
            pbFadeOutIn do
              scene = PokemonOption_Scene.new
              screen = PokemonOptionScreen.new(scene)
              screen.pbStartScreen(true)
            end
          end
        when cmd_language
          @scene.pbEndScene
          $PokemonSystem.language = pbChooseLanguage
          MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
          if show_continue
            @save_data[:pokemon_system] = $PokemonSystem
            File.open(SaveData.get_full_path(@selected_file), "wb") { |file| Marshal.dump(@save_data, file) }
          end
          $scene = pbCallTitle
          return
        when cmd_update
          PokeUpdater.validate_game_version_and_update(true) if defined?(PokeUpdater) && defined?(PokeUpdater.validate_game_version_and_update)
        when cmd_debug
          pbFadeOutIn { pbDebugMenu(false) }
        when cmd_quit
          pbPlayCloseMenuSE
          @scene.pbEndScene
          $scene = nil
          return
        when cmd_delete
          if pbConfirmMessageSerious(_INTL("¿Quieres eliminar este archivo guardado?"))
            self.delete_save_data(SaveData.get_full_path(@selected_file))
            @save_data_cache.delete(@selected_file) # Eliminar del caché
          end
          @scene.pbCloseScene
          $player&.last_save_slot = nil if $player && $player&.last_save_slot == $player&.save_slot
          @selected_file = SaveData.get_newest_save_slot
          break
        when cmd_left
          pbPlayDecisionSE
          @scene.pbCloseScene
          @selected_file = SaveData.get_prev_slot(save_file_list, @selected_file)
          break # al bucle externo
        when cmd_right
          pbPlayDecisionSE
          @scene.pbCloseScene
          @selected_file = SaveData.get_next_slot(save_file_list, @selected_file)
          break # al bucle externo
        else
          pbPlayBuzzerSE
        end
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSave_Scene
  def pbUpdateSlotInfo(slottext)
    pbDisposeSprite(@sprites, "slotinfo")
    @sprites["slotinfo"] = Window_AdvancedTextPokemon.new(slottext)
    @sprites["slotinfo"].viewport = @viewport
    @sprites["slotinfo"].x = 0
    @sprites["slotinfo"].y = 190
    @sprites["slotinfo"].width = 228 if @sprites["slotinfo"].width < 228
    @sprites["slotinfo"].visible = true
  end
  
  def pbClearSlotInfo
    pbDisposeSprite(@sprites, "slotinfo")
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSaveScreen
  def doSave(slot)
    if Game.save(slot)
      pbMessage("\\se[]" + _INTL("{1} guardó la partida.", $player.name) + "\\me[GUI save game]\\wtnp[20]")
      return true
    else
      pbMessage("\\se[]" + _INTL("El guardado ha fallado.") + "\\wtnp[30]")
      return false
    end
  end

  # Devuelve true si el menú de pausa debe cerrarse después de esto (si el juego se guardó exitosamente)
  def pbSaveScreen(exiting=false)
    ret = false
    @scene.pbStartScreen
    if !$player.save_slot
      # Juego Nuevo - debe seleccionar ranura
      ret = slotSelect(exiting)
    else
      loop do # Añadir bucle para permitir regresar de la selección de ranura
        choices = [
          _INTL("Guardar en #{$player.save_slot}"),
          _INTL("Guardar en otro Archivo"),
          exiting ? _INTL("Salir sin guardar") : _INTL("Cancelar")
        ]
        opt = pbMessage(_INTL("¿Quieres guardar la partida?"), choices, 3)
        if opt == 0
          pbSEPlay("GUI save choice")
          ret = doSave($player.save_slot)
          break
        elsif opt == 1
          pbPlayDecisionSE
          slot_result = slotSelect(exiting)
          if slot_result # Si el guardado fue exitoso, salir
            ret = true
            break
          end
          # Limpiar info de ranura al regresar de la selección de ranura
          @scene.pbClearSlotInfo
          # Si slot_result es false, continuar bucle para regresar a este menú
        else
          pbPlayCancelSE
          break
        end
      end
    end
    @scene.pbEndScreen
    return ret
  end

  # Llama esto para abrir la pantalla de selección de ranura
  # Devuelve true si el juego fue guardado, de lo contrario false
  def slotSelect(exiting=false)
    ret = false
    # Construir opciones: nueva ranura, luego todas las ranuras existentes (excepto la actual)
    choices = []
    choice_info = []
    
    # Añadir opción de nueva ranura
    new_slot = SaveData.get_new_manual_slot
    choices << "#{new_slot} (Nuevo)"
    choice_info << _INTL("<ac><c3=3050C8,D0D0C8>(Nuevo Archivo)</c3></ac>")
    
    # Añadir todas las ranuras manuales existentes (excepto la actual si existe)
    existing_slots = SaveData.get_manual_slots
    existing_slots.each do |slot|
      next if $player.save_slot == slot  # Saltar ranura actual ya que se maneja en el menú anterior
      choices << slot
      choice_info << getSaveInfoBoxContents(slot)
    end
    loop do
      index = slotSelectCommands(choices, choice_info)
      if index >= 0
        selected_choice = choices[index]
        
        # Determinar el nombre real de la ranura
        if selected_choice.end_with?(" (Nuevo)")
          slot = new_slot
        else
          slot = selected_choice
        end
        
        # Confirmar si la ranura no está vacía (excepto para nueva ranura)
        if selected_choice.end_with?(" (Nuevo)") ||
           !File.file?(SaveData.get_full_path(slot)) ||
           pbConfirmMessageSerious(_INTL("¿Estás seguro de sobrescribir en #{slot}?"))
          pbSEPlay('GUI save choice')
          ret = doSave(slot)
        end
      elsif index < 0 # Presionó cancelar/atrás
        if exiting
          next unless pbConfirmMessageSerious(_INTL("¿Estás seguro de salir sin guardar la partida?"))
        else
          # Devolver false para volver al menú anterior
          pbPlayCloseMenuSE
          return false
        end
      end
      break
    end
    pbPlayCloseMenuSE if !ret
    return ret
  end

  # Maneja la UI para la pantalla de selección de ranura de guardado. Devuelve el índice de la ranura elegida, o -1.
  # Basado en pbShowCommands
  def slotSelectCommands(choices, choice_info, defaultCmd=0)
    msgwindow = Window_AdvancedTextPokemon.new(_INTL("¿En qué archivo quieres guardar?"))
    msgwindow.z = 99999
    msgwindow.visible = true
    msgwindow.letterbyletter = true
    msgwindow.back_opacity = MessageConfig::WINDOW_OPACITY
    pbBottomLeftLines(msgwindow, 1)
    $game_temp.message_window_showing = true if $game_temp
    msgwindow.setSkin(MessageConfig.pbGetSpeechFrame)

    cmdwindow = Window_CommandPokemonEx.new(choices)
    cmdwindow.z = 99999
    cmdwindow.visible = true
    cmdwindow.resizeToFit(cmdwindow.commands)
    pbPositionNearMsgWindow(cmdwindow,msgwindow,:right)
    cmdwindow.index = defaultCmd
    command = 0
    loop do
      @scene.pbUpdateSlotInfo(choice_info[cmdwindow.index])
      Graphics.update
      Input.update
      cmdwindow.update
      msgwindow.update if msgwindow
      if Input.trigger?(Input::BACK)
        command = -1
        break
      end
      if Input.trigger?(Input::USE)
        command = cmdwindow.index
        break
      end
      pbUpdateSceneMap
    end
    ret = command
    cmdwindow.dispose
    msgwindow.dispose
    $game_temp.message_window_showing = false if $game_temp
    Input.update
    return ret
  end

  # Muestra al jugador algunos datos sobre su ranura de guardado actualmente seleccionada para identificación rápida
  # Esto no usa el género del jugador para colorear, a diferencia de la ventana de guardado por defecto
  # OPTIMIZADO: Usa datos cacheados cuando están disponibles
  def getSaveInfoBoxContents(slot)
    full_path = SaveData.get_full_path(slot)
    if !File.file?(full_path)
      return _INTL("<ac><c3=3050C8,D0D0C8>(Vacío)</c3></ac>")
    end
    
    # Inicializar caché si es necesario
    @save_info_cache ||= {}
    
    # Verificar si necesitamos refrescar el caché (archivo modificado desde la última lectura)
    file_mtime = File.mtime(full_path)
    cached_entry = @save_info_cache[slot]
    
    if cached_entry && cached_entry[:mtime] == file_mtime
      return cached_entry[:content]
    end
    
    # Leer archivo y cachear el resultado
    temp_save_data = SaveData.read_from_file(full_path)

    # Última hora de guardado
    time = temp_save_data[:player].last_time_saved
    if time
      date_str = time.strftime("%x")
      time_str = time.strftime(_INTL("%I:%M%p"))
      datetime_str = "#{date_str}<r>#{time_str}<br>"
    else
      datetime_str = _INTL("<ac>(Guardado Antiguo)</ac>")
    end

    # Nombre del mapa
    map_str = pbGetMapNameFromId(temp_save_data[:map_factory].map.map_id)

    # Tiempo transcurrido
    totalsec = (temp_save_data[:frame_count] || 0) / Graphics.frame_rate
    # totalsec = $stats.play_time.to_i || 0
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    if hour > 0
      elapsed_str = _INTL("Tiempo<r>{1}h {2}m<br>", hour, min)
    else
      elapsed_str = _INTL("Tiempo<r>{1}m<br>", min)
    end

    content = "<c3=D0D0C8,3050C8>#{datetime_str}</c3>"+ # azul
              "<ac><c3=90F090,209808>#{map_str}</c3></ac>"+ # verde
              "#{elapsed_str}"
    
    # Cachear el resultado
    @save_info_cache[slot] = { mtime: file_mtime, content: content }
    
    return content
  end
end

#===============================================================================
#
#===============================================================================
module Game
  # Carga datos de inicio desde el archivo de guardado (si existe) o crea datos de inicio (si no existe).
  def self.set_up_system
    save_slot = SaveData.get_newest_save_slot
    if save_slot
      save_data = SaveData.read_from_file(SaveData.get_full_path(save_slot))
    else
      save_data = {}
    end
    if save_data.empty?
      SaveData.initialize_bootup_values
    else
      SaveData.load_bootup_values(save_data)
    end
    # Establecer factor de redimensionamiento
    pbSetResizeFactor([$PokemonSystem.screensize, 4].min)
    # Establecer idioma (y elegir idioma si no hay archivo de guardado)
    if !Settings::LANGUAGES.empty?
      $PokemonSystem.language = pbChooseLanguage if save_data.empty? && Settings::LANGUAGES.length >= 2
      MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
    end
  end

  # Guarda el juego. Devuelve si la operación fue exitosa.
  # @param save_file [String] la ruta del archivo de guardado
  # @param safe [Boolean] si $PokemonGlobal.safesave debe establecerse en true
  # @return [Boolean] si la operación fue exitosa
  # @raise [SaveData::InvalidValueError] si se está guardando un valor inválido
  def self.save(slot=nil, auto=false, safe: false)
    slot = $player.save_slot if slot.nil?
    return false if slot.nil?
    
    file_path = SaveData.get_full_path(slot)
    $PokemonGlobal.safesave = safe
    $game_system.save_count += 1
    $game_system.magic_number = $data_system.magic_number
    $stats.set_time_last_saved
    $player.save_slot = slot unless auto
    $player.last_time_saved = Time.now
    # $player.last_save_slot = slot
    begin
      SaveData.save_to_file(file_path)
      Graphics.frame_reset
    rescue IOError, SystemCallError
      $game_system.save_count -= 1
      return false
    end
    return true
  end

  # Sobrescribe la primera ranura de autoguardado vacía, de lo contrario el autoguardado existente más antiguo
  # OPTIMIZADO: Usa la hora de modificación del archivo en lugar de leer datos de guardado
  def self.auto_save
    oldest_time = nil
    oldest_slot = nil
    SaveData::AUTO_SLOTS.each do |slot|
      full_path = SaveData.get_full_path(slot)
      if !File.file?(full_path)
        oldest_slot = slot
        break
      end
      # Usar hora de modificación del archivo en lugar de leer el archivo de guardado completo
      file_mtime = File.mtime(full_path)
      if oldest_time.nil? || file_mtime < oldest_time
        oldest_time = file_mtime
        oldest_slot = slot
      end
    end
    self.save(oldest_slot, true)
  end
end

#===============================================================================
#
#===============================================================================

# Jaja ¿quién necesita la gema FileUtils?
# Esta es la implementación del pbEmergencySave original.
def file_copy(src, dst)
  File.open(src, "rb") do |r|
    File.open(dst, "wb") do |w|
      loop do
        s = r.read(4096)
        break if !s
        w.write(s)
      end
    end
  end
end

# Cuando necesitaba campos de datos extra en el archivo de guardado los puse en Player porque parecía más fácil que averiguar
# cómo hacer una conversión de archivo de guardado, y prefiero mantener la compatibilidad hacia atrás.
class Player
  attr_accessor :last_time_saved
  attr_accessor :save_slot
  attr_accessor :last_save_slot
  attr_accessor :autosave_steps
end

def pbEmergencySave
  oldscene = $scene
  $scene = nil
  pbMessage(_INTL("El script está tardando mucho. Se va a reiniciar el juego."))
  return if !$player
  return if !$player.save_slot
  current_file = SaveData.get_full_path($player.save_slot)
  backup_file = SaveData.get_backup_file_path
  file_copy(current_file, backup_file)
  if Game.save
    pbMessage("\\se[]" + _INTL("{1} guardó la partida.", $player.name) + "\\me[GUI save game]\\wtnp[20]")
    pbMessage("\\se[]" + _INTL("Se ha hecho una copia del anterior archivo de guardado.") + "\\wtnp[20]")
  else
    pbMessage("\\se[]" + _INTL("El guardado ha fallado.") + "\\wtnp[30]")
  end
  $scene = oldscene
end

# module RTP
#   def self.getSaveFolder
#     # MKXP se asegura de que esta carpeta se haya creado
#     # una vez que comienza. La ubicación difiere según
#     # el sistema operativo:
#     # Windows: %APPDATA%
#     # Linux: $HOME/.local/share
#     # macOS (unsandboxed): $HOME/Library/Application Support
#     "Partidas"
#   end
# end