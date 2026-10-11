#===============================================================================
#
#===============================================================================
class UI::MoveReminderCursor < IconSprite
  attr_accessor :top_index

  CURSOR_WIDTH     = 248
  CURSOR_HEIGHT    = 72
  CURSOR_THICKNESS = 0

  def initialize(viewport = nil)
    super(0, 0, viewport)
    setBitmap(File.join('Graphics', 'UI', 'Move Reminder', 'cursor'))
    self.src_rect = Rect.new(0, 0, CURSOR_WIDTH, CURSOR_HEIGHT)
    self.z = 1600
    @bg_sprite = IconSprite.new(x, y, viewport)
    @bg_sprite.setBitmap(File.join('Graphics', 'UI', 'Move Reminder', 'cursor'))
    @bg_sprite.src_rect = Rect.new(0, CURSOR_HEIGHT, CURSOR_WIDTH, CURSOR_HEIGHT)
    @top_index = 0
    self.index = 0
  end

  def dispose
    @bg_sprite.dispose
    @bg_sprite = nil
    super
  end

  def index=(value)
    @index = value
    refresh_position
  end

  def visible=(value)
    super
    @bg_sprite.visible = value
  end

  def refresh_position
    return if @index.negative?

    self.x = UI::MoveReminderVisuals::MOVE_LIST_X + 5
    self.y = UI::MoveReminderVisuals::MOVE_LIST_Y - CURSOR_THICKNESS
    self.y += (@index - @top_index) * UI::MoveReminderVisuals::MOVE_LIST_SPACING
    @bg_sprite.x = self.x
    @bg_sprite.y = self.y
  end
end

#===============================================================================
#
#===============================================================================
class UI::MoveReminderVisuals < UI::BaseVisuals
  attr_reader :index

  GRAPHICS_FOLDER   = 'Move Reminder/' # Subfolder in Graphics/UI
  TEXT_COLOR_THEMES = { # These color themes are added to @sprites[:overlay]
    default: [Color.new(248, 248, 248), Color.new(0, 0, 0)], # Base and shadow color
    white: [Color.new(248, 248, 248), Color.new(74, 112, 175)],
    blue: [Color.new(108, 168, 216), Color.new(32, 88, 165)],
    black: [Color.new(64, 64, 64), Color.new(162, 162, 162)],
    header: [Color.new(88, 88, 80), Color.new(168, 184, 184)]
  }
  MOVE_LIST_X       = 2
  MOVE_LIST_Y       = 70
  MOVE_LIST_SPACING = 64 # Y distance between top of two adjacent move areas
  VISIBLE_MOVES     = 4
  TYPE_ICONS_X      = 396
  TYPE_ICONS_Y      = 50
  TYPE_ICONS_SPACING = 6
  POKEMON_ICON_X      = 314
  POKEMON_ICON_Y      = 70
  HEADER_X           = 16
  HEADER_Y           = 38
  BUTTON_UP_WIDTH    = 20
  BUTTON_DOWN_WIDTH  = 20
  BUTTON_UP_HEIGHT   = 20
  BUTTON_DOWN_HEIGHT = 20
  BUTTON_UP_X        = 228
  BUTTON_DOWN_X      = 228
  BUTTON_UP_Y        = 36
  BUTTON_DOWN_Y      = Settings::SCREEN_HEIGHT - 52

  #-----------------------------------------------------------------------------


  def draw_header
    draw_text(_INTL('¿Enseñar movimiento?'), HEADER_X, HEADER_Y, theme: :white)
  end

  def draw_move_in_list(move, x, y)
    move_data = GameData::Move.get(move[0])

    # Draw move type icon
    type_number = GameData::Type.get(move_data.display_type(@pokemon)).icon_position
    draw_image(@bitmaps[:types], x + 8, y + 1,
                0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE)

    # Draw move name
    move_name = move_data.name
    move_name = crop_text(move_name, 230)
    draw_text(move_name, x + 76, y + 6, theme: :white)

    # Draw move learn level or TM/HM
    if move && move.length > 1 && move[1]
      tm_hm = if move[1] == :TM
                _INTL('MT')
              else
                move[1] == :HM ? _INTL('MO') : move[1]
              end
      draw_text(tm_hm, x + LEVEL_OR_TM_X_OFFSET, y + LEVEL_OR_TM_Y_OFFSET)
    end

    # Draw PP text
    return unless move_data.total_pp.positive?

    draw_text(_INTL('PP'), x + 140, y + 34, theme: :white)
    draw_text(format('%d/%d', move_data.total_pp, move_data.total_pp), x + 240, y + 34, align: :right, theme: :white)
  end

  def draw_move_properties
    move = @moves[@index]
    return unless move

    move_data = GameData::Move.get(move[0])
    # Power
    draw_text(_INTL('POTENCIA'), 278, 105, theme: :black)
    power_text = move_data.display_power(@pokemon)
    power_text = '---' if power_text.zero? # Status move
    power_text = '???' if power_text == 1 # Variable power move
    draw_text(power_text, 480, 105, align: :right, theme: :black)
    # Accuracy
    draw_text(_INTL('PRECISIÓN'), 278, 135, theme: :black)
    accuracy = move_data.display_accuracy(@pokemon)
    if accuracy.zero?
      draw_text('---', 480, 140, align: :right, theme: :black)
    else
      draw_text(accuracy, 480, 135, align: :right, theme: :black)
      draw_text('%', 480, 135, theme: :black)
    end

    # Draw move category
    draw_text(_INTL('CATEGORÍA'), 278, 165, theme: :black)
    draw_image("#{UI_FOLDER}category", 434, 160,
               0, move_data.display_category(@pokemon) * GameData::Move::CATEGORY_ICON_SIZE[1], *GameData::Move::CATEGORY_ICON_SIZE)

    # Description
    draw_paragraph_text(move_data.description, 275, 200, 235, 5, theme: :black)
  end

end
