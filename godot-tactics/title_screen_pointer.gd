extends Sprite2D

## Mouse-following pointer, used both on the title screen and in-game
## (main.tscn's UI_Menu, via helpers/pointers.tscn).
##
## This used to extend TextureButton, relying on Godot's native
## texture_normal/texture_pressed swap for click feedback. The bug: a
## TextureButton is a Control, and Controls participate in mouse
## hit-testing regardless of mouse_filter tuning — since this pointer
## always sits exactly on top of the mouse (that's its whole job) and
## renders above the real UI buttons in z-order, it was intercepting clicks
## meant for whatever button was actually under the cursor, so those
## buttons never fired. A plain Sprite2D is not a Control at all, so it
## can never participate in Godot's GUI input routing or block a click —
## the fix is architectural, not a mouse_filter value. Click feedback is
## now done by hand: swap texture based on Input.is_mouse_button_pressed()
## every frame, instead of relying on native BaseButton press detection.
##
## Mirrors GB's UIPointer (src/UI/ui_pointer.c) flashing between its two
## frames on confirm (pointer_anim_select) — same two textures, same idea of
## a normal vs. "pressed" look — just driven by an actual mouse click
## instead of the A button, and continuously repositioned instead of
## snapping between fixed menu-row coordinates the way title_screen.gd's
## keyboard navigation does (see that file — it now gives keyboard-selected
## options a focus outline instead of moving this pointer, since this node
## is fully mouse-driven now).
##
## The OS mouse cursor is hidden while this node is actually visible on
## screen, and restored the moment it isn't — driven by is_visible_in_tree()
## rather than _ready()/_exit_tree(), because this script is reused in two
## places with very different visibility at load time:
##   - TItleScreen.tscn: visible immediately, so the cursor hides right away.
##   - main.tscn (WindowLayer/UI_Menu/Sprite2D, via helpers/pointers.tscn):
##     UI_Menu starts hidden (UI.gd) and only slides into view on
##     menu_toggle. Hiding the OS cursor unconditionally in _ready() here
##     would hide it for the whole game session — including regular grid
##     gameplay, where this pointer never renders to replace it — leaving
##     the player with no visible cursor at all. Gating on actual visibility
##     keeps this node's effect scoped to only when it's shown.

const TEXTURE_IDLE := preload("res://UI/hand_1.webp")
const TEXTURE_CLICKED := preload("res://UI/hand_2.webp")

## Offset from the raw mouse position to this sprite's origin, so the hand
## (and its texture) is centered under the cursor instead of having the
## cursor sit at its corner. Tune in the editor/inspector if the hand
## doesn't line up with the mouse.
@export var pointer_offset: Vector2 = Vector2(-24, -24)

func _ready() -> void:
	texture = TEXTURE_IDLE
	visibility_changed.connect(_update_mouse_mode)
	_update_mouse_mode()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	global_position = get_global_mouse_position() + pointer_offset
	texture = TEXTURE_CLICKED if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else TEXTURE_IDLE

func _update_mouse_mode() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if is_visible_in_tree() else Input.MOUSE_MODE_VISIBLE
