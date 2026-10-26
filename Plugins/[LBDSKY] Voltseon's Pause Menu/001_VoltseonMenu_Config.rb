#-------------------------------------------------------------------------------
# Voltseon's Pause Menu
# Pause with style 😎
#-------------------------------------------------------------------------------
#
# Original Script by Yankas
# Updated compatablilty by Cony
# Edited and modified by Voltseon, Golisopod User and ENLS
#
# Made for people who dont want
# to have ugly pause menus
# so here's a really cool one!
# Version: 2.2
#
#
#-------------------------------------------------------------------------------
# Menu Options
#-------------------------------------------------------------------------------
# Main file path for the menu
MENU_FILE_PATH = "Graphics/Plugins/VPM/"

# An array of aLL the Menu Component Classes from 004_VoltseonMenu_Components
# that need to be loaded
MENU_COMPONENTS = [
  :VPM_SafariHud, :VPM_BugContestHud, :VPM_PokemonPartyHud, :VPM_DateAndTimeHud, :VPM_NewQuestHud
]

# The default theme for the menu screen
DEFAULT_MENU_THEME = 0

# Change Theme in the Options Menu
CHANGE_THEME_IN_OPTIONS = true

#-------------------------------------------------------------------------------
# Look and Feel
#-------------------------------------------------------------------------------
# Background options
BACKGROUND_TINT = Color.new(-30, -30, -30, 130) # Tone (Red, Green, Blue, Grey) applied to the background/map.

SHOW_MENU_NAMES = true # Whether or not the Menu option Names show on screen (true = show names)

# Icon options
ACTIVE_SCALE = 1.5

MENU_TEXTCOLOR = [
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248)
]

MENU_TEXTOUTLINE = [
  Color.new(64, 64, 64),
  Color.new(64, 64, 64),
  Color.new(68, 96, 0),
  Color.new(96, 18, 0),
  Color.new(0, 102, 137),
  Color.new(137, 0, 100),
  Color.new(38, 22, 91),
  Color.new(12, 37, 24),
  Color.new(0, 58, 76)
]

LOCATION_TEXTCOLOR = [
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248),
  Color.new(248, 248, 248)
]

LOCATION_TEXTOUTLINE = [
  Color.new(64, 64, 64),
  Color.new(64, 64, 64),
  Color.new(68, 96, 0),
  Color.new(96, 18, 0),
  Color.new(0, 102, 137),
  Color.new(137, 0, 100),
  Color.new(38, 22, 91),
  Color.new(12, 37, 24),
  Color.new(0, 58, 76)
]

# Sound Options
MENU_OPEN_SOUND   = "GUI menu open"
MENU_CLOSE_SOUND  = "GUI menu close"
MENU_CURSOR_SOUND = "GUI sel cursor"

# Arc layout for the icon bar
ICON_ARC_ENABLED = true
ICON_ARC_RISE    = 26      # How many pixels the centre icon is raised from the old baseline
ICON_ARC_CURVE   = 0.0060  # Steepness: higher = outer icons drop more
ICON_ARC_HIDE_MARGIN = 8   # Icons whose top edge is within this many px of the bottom get hidden
ICON_SCALE = 0.8   # 1.0 = original size, 0.8 = 20% smaller

# Revolver "chamber" behind each icon
CHAMBER_ENABLED  = true
CHAMBER_FILE     = "menu_chamber"  # PNG in MENU_FILE_PATH, or in "Theme N/" for per-theme versions
CHAMBER_SCALE    = 0.8             # Relative to the icon's own zoom (it also grows with the selected icon)
CHAMBER_X_OFFSET = 0
CHAMBER_Y_OFFSET = 0
CHAMBER_TILT     = 0.0             # Degrees of rotation per pixel from the centre (try 0.25 to follow the curve


ARROW_Y_OFFSET = 17
# Arc layout for the party icons
# Party arc: follows the ring of the menu background
PARTY_ARC_ENABLED   = true
PARTY_RING_CENTER_Y = 424   # 
PARTY_RING_RADIUS   = 154   # 
PARTY_RING_MARGIN   = 10    # was 8; gap between the ring edge and the bottom of the bars
PARTY_ARC_SPACING   = 70    # distance between neighbouring Pokémon along the arc (px)
PARTY_UNIT_HALF_W   = 18    # half the width of the HP bar, used to keep outer bars off the ring
PARTY_ARC_Y_OFFSET  = 0     # extra nudge: negative = up

# Height at which the name of the currently selected option is displayed
MENU_NAME_Y = 227   # Distance from the bottom of the screen to the entry name (bigger = higher)