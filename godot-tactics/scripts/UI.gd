class_name UIPanel
extends TileMap
# This is the UI layer that simulates the Game Boy's window layer for UI.
#
# Merged with the old battle_menu.gd (class BattleMenu, a code-built Panel):
# both were a MAGIC/ATTACK/END-style panel toggled by SELECT, but only
# battle_menu.gd was ever actually wired into real combat
# (battle_manager.gd listened to its action_chosen signal). This file now
# owns both the tile-painted visuals AND the real combat wiring;
# battle_menu.gd and its scene node are gone.
#
# Slide-on/off-screen: menu_toggle (GB's SELECT button) slides this whole
# node — tiles and buttons together — on/off screen with a Tween, mirroring
# main.c's UI_ANIM_SHOWING/HIDING as a plain slide rather than GB's
# row-by-row Window reveal. This node self-registers menu_toggle so it
# doesn't depend on battle_manager.gd running first.
#
# opened/closed are emitted so battle_manager.gd can suppress grid input for
# exactly as long as this panel is visible or animating, and refresh stats
# on open — opened fires the instant SELECT is pressed (before the slide-in
# even finishes, so nothing leaks through mid-animation), closed only once
# fully hidden again.
#
# Button navigation is native Godot focus (see the focus_neighbor_top/bottom
# wiring on the buttons in main.tscn) rather than a hand-rolled index +
# pointer — arrow keys move focus along that chain, Enter/Space activates
# the focused button, GameboyTheme.tres supplies the pressed/focus styling.
# _slide_in() just grabs focus on the first button so keyboard nav works
# immediately without needing a prior Tab/click.
#
# menu_toggle is bound to Tab, and handled in _input() (not _unhandled_input)
# with get_viewport().set_input_as_handled() — Tab is also Godot's built-in
# focus-cycle key, and _input() fires before the engine's own GUI/focus
# handling gets a chance to consume it for that, so claiming it here first
# stops a focused button from swallowing it and silently breaking the panel's
# open/close. (Verified: a focused button stays focused after this consumes
# Tab, instead of cycling away as it would if this used _unhandled_input.)

# i want to separate the game code into separate classes

signal opened
signal closed
signal action_chosen(action: String)

const SLIDE_TIME := 0.35

## Tint flashed onto a button briefly when clicked, then eased back to
## Color.WHITE — a guaranteed-visible click reaction regardless of theme,
## since these buttons are flat = true and may not show much of a default
## pressed style otherwise.
const CLICK_FLASH_COLOR := Color(1, 1, 0.4, 1)
const CLICK_FLASH_TIME := 0.15

## Action string emitted per button, matched by index to _buttons/the scene's
## VBoxContainer order (Attack, Magic, End turn) — battle_manager.gd matches
## on these exact strings.
const ACTIONS := ["attack", "magic", "end"]

const GB_THEME := preload("res://GameboyTheme.tres")

var is_open: bool = false

var _shown_position: Vector2
var _hidden_position: Vector2
var _sliding: bool = false

@onready var _buttons: Array[Button] = [
	$VBoxContainer/Button,
	$VBoxContainer/Button2,
	$VBoxContainer/Button3,
]

# Sibling under WindowLayer (not a child of this node), reached directly
# rather than routed through battle_manager.gd, since all that's needed
# here is the button's own display text at the exact point it's pressed —
# routing it through the action_chosen("attack"/"magic"/"end") signal would
# either lose "Attack"/"Magic"/"End turn"'s exact wording (the action
# strings don't literally match, e.g. "end" vs "End turn") or need a second
# signal just to carry it.
@onready var _dialogue: DialogueUI = $"../Dialogue_UI"

# HP/ATK/DEF/MP labels are hand-placed in the scene now (WindowLayer/UI_Menu/
# VBoxContainer2), not built in code — VBoxContainer2 handles their layout
# (position/spacing) itself, same as VBoxContainer already does for the
# Attack/Magic/End turn buttons. Label4 is the MP slot despite its scene
# placeholder text also reading "HP" — that's just unset placeholder text,
# overwritten the same as the others the first time update_stats() runs.
@onready var _hp_label: Label = $VBoxContainer2/Label
@onready var _atk_label: Label = $VBoxContainer2/Label2
@onready var _def_label: Label = $VBoxContainer2/Label3
@onready var _mp_label: Label = $VBoxContainer2/Label4

@export var _message_label: Label

func _ready() -> void:
	# makes sure that the menu toggle button is in the action set
	# redundant code
	_ensure_menu_toggle_action()
	
	_match_camera_zoom()
	_build_message_label()

	_shown_position = position
	_hidden_position = _shown_position - Vector2(0, _panel_height() * scale.y)

	position = _hidden_position
	visible = false
	is_open = false

	for i in _buttons.size():
		_buttons[i].pressed.connect(_on_option_pressed.bind(i))

## The one label still built in code — flash_message()'s short "OUT OF
## RANGE"/"NOT ENOUGH MP" line has no scene-authored equivalent (only the
## HP/ATK/DEF/MP stats do), so this alone still needs it.
func _build_message_label() -> void:
	_message_label = Label.new()
	_message_label.theme = GB_THEME
	_message_label.add_theme_font_size_override("font_size", 6)
	_message_label.position = Vector2(8, 60)
	add_child(_message_label)

func update_stats(player: Unit) -> void:
	_hp_label.text = "HP  %d/%d" % [player.hp, player.max_hp]
	_atk_label.text = "ATK %d" % player.atk
	_def_label.text = "DEF %d" % player.def
	_mp_label.text = "MP  %d/%d" % [player.mp, player.max_mp]


## External callers (battle_manager.gd) close the panel explicitly after a
## successful action rather than this closing itself unconditionally on
## every press — a failed action (out of range, not enough MP) needs to
## leave the panel open so the player can pick something else.
func close() -> void:
	if is_open and not _sliding:
		_slide_out()

## Mirrors close() — lets battle_manager.gd open the panel programmatically
## (e.g. right after the player's move finishes) instead of only ever
## responding to a manual menu_toggle press.
func open() -> void:
	if not is_open and not _sliding:
		_slide_in()

func _on_option_pressed(index: int) -> void:
	if _sliding:
		return
	var button := _buttons[index]
	# note: this function was moved to dialogue class
	
	Dialogue.announce(button.text, _dialogue._announce_label, _dialogue,get_tree())
	_flash_button(button)
	action_chosen.emit(ACTIONS[index])

func _flash_button(button: Button) -> void:
	button.modulate = CLICK_FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(button, "modulate", Color.WHITE, CLICK_FLASH_TIME)

## WindowLayer is a CanvasLayer, which renders in raw screen pixels and
## ignores the main Camera2D's zoom — so without this, this panel's 8x8
## tiles render at native (tiny) size next to the zoomed-in game grid.
## Match whatever the active camera's zoom actually is instead of
## hardcoding a scale, so this doesn't go stale if the zoom ever changes.
func _match_camera_zoom() -> void:
	var camera := get_viewport().get_camera_2d()
	scale = camera.zoom if camera else Vector2(8, 8)

func _input(event: InputEvent) -> void:
	if _sliding:
		return
	if event.is_action_pressed("menu_toggle"):
		get_viewport().set_input_as_handled()
		if is_open:
			_slide_out()
		else:
			_slide_in()

func _slide_in() -> void:
	_sliding = true
	is_open = true
	visible = true
	opened.emit()
	var tween := create_tween()
	tween.tween_property(self, "position", _shown_position, SLIDE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_sliding = false
	_buttons[0].grab_focus()

func _slide_out() -> void:
	_sliding = true
	var tween := create_tween()
	tween.tween_property(self, "position", _hidden_position, SLIDE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	is_open = false
	_sliding = false
	closed.emit()

## Height (in pixels) of whatever's actually painted on this TileMap, so the
## slide distance always matches the panel's real size instead of a guessed
## constant — reads back however many rows you've drawn and how big each
## tile is, rather than assuming either.
func _panel_height() -> float:
	if tile_set == null:
		return 160.0  # fallback: one GB screen height (144px) rounded up
	var used_rect := get_used_rect()
	var height := used_rect.size.y * tile_set.tile_size.y
	return height if height > 0 else 160.0

## Bound to Tab — see the header comment for why _input() +
## set_input_as_handled() is what actually makes this safe alongside real
## button focus navigation, rather than picking a different key.
func _ensure_menu_toggle_action() -> void:
	if InputMap.has_action("menu_toggle"):
		return
	InputMap.add_action("menu_toggle")
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_TAB
	InputMap.action_add_event("menu_toggle", key_event)

# to do:
# (1) separate the ui class into dialogue class with static function pointers
class Dialogue:
	# bugs :
	# (1) the game's button select routes through another UI class
	
	func a() -> void:
		pass
	
	static func flash_message(text: String, _message_label : Label, tree: SceneTree) -> void:
		# bug 1: route all flash_message calls to announce
		print_debug("message debug: " + text)
		print_stack()
		_message_label.text = text
		await tree.create_timer(1.0).timeout
		if is_instance_valid(_message_label):
			_message_label.text = ""
		#pass
	
	
	## Short-lived status line (e.g. "MAX RANGE REACHED"): slides the panel up
	## from the bottom, holds for ANNOUNCE_TIME, then slides it away again —
	## unless dialogue_toggle has manually pinned it open, in which case the
	## auto-hide is skipped and it's left for the player to close themselves.
	## Not queued — a new announce() call while one is already showing just
	## replaces the text and keeps the panel open rather than waiting its turn,
	## since these are meant to be quick, low-stakes status blips, not a
	## message log. The original call's own delayed hide checks the text is
	## still its own before closing, so it can't cut off a newer message that
	## overwrote it.
	static func announce(text: String, _announce_label : Label, diagUI : DialogueUI, tree : SceneTree) -> void:
		_announce_label.text = text
		if not diagUI.is_open:
			await diagUI._slide_in()
		await tree.create_timer(diagUI.ANNOUNCE_TIME).timeout
		if diagUI._manual_open:
			return
		if is_instance_valid(_announce_label) and _announce_label.text == text:
			await diagUI._slide_out()

	

class UIAnimation:
	func a() -> void:
		pass
