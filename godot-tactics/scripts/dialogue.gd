class_name DialogueUI
extends TileMap

#this is for the dialogue ui
# it prints out all system info to the UI
# it uses the gameboy system's constraints hardcoded into godot engine
#
# First real use: short one-line system announcements — currently just a
# movement-range-cap notice, but any other short status text can go through
# announce() the same way. No turn indicator here — end-turn is being wired
# to the UI buttons themselves (UI.gd's End turn button) instead of a
# separate text label.
#
# Show/hide mirrors UI.gd's slide (see that file, ## 5) — same
# Tween-between-two-positions approach — but this one enters from the
# BOTTOM of the screen instead of the top. Two ways to trigger it now:
# announce() auto-shows/hides around a message, and dialogue_toggle
# (bound to D, self-registered the same way UI.gd registers menu_toggle)
# opens/closes it manually like UI_Menu — on its own key, not Tab, so the
# two panels can be shown independently instead of always moving together.

const SLIDE_TIME := 0.35
const ANNOUNCE_TIME := 1.6

# Control/Label are direct children of THIS node (Dialogue_UI), since this
# script is attached to Dialogue_UI itself — not $WindowLayer/Dialogue_UI/...,
# which would look for a child of Dialogue_UI named "WindowLayer" and never
# resolve.
@onready var _announce_label: Label = $Control/Label

var is_open: bool = false
var _shown_position: Vector2
var _hidden_position: Vector2
var _sliding: bool = false

## True while a manual dialogue_toggle press is holding the panel open —
## announce()'s own auto-hide checks this so it can't slide the panel away
## out from under someone who explicitly opened it.
var _manual_open: bool = false

const BOTTOM_MARGIN := 8.0  # gap left between the panel and the true bottom edge when shown

func _ready() -> void:
	_ensure_dialogue_toggle_action()
	_match_camera_zoom()

	_shown_position = _compute_shown_position()
	_hidden_position = _shown_position + Vector2(0, _panel_height() * scale.y)

	position = _hidden_position
	visible = false

## The painted tiles start partway down this TileMap's own local space (row
## 13, not row 0 — get_used_rect().position.y), so simply reusing the node's
## raw scene position as "shown" left most of the panel below the real
## screen's bottom edge even at rest: verified directly, content spanned
## screen Y 599–791 against a 648-tall viewport, i.e. only the top ~50px
## was ever actually on screen. This instead anchors the painted content's
## bottom edge just above the real viewport's bottom edge (BOTTOM_MARGIN),
## computed from the actual viewport size rather than a guessed constant —
## self-corrects if the content is repainted or the window is resized.
func _compute_shown_position() -> Vector2:
	var viewport_height := get_viewport().get_visible_rect().size.y
	var used_rect := get_used_rect()
	var content_top_local := used_rect.position.y * (tile_set.tile_size.y if tile_set else 8)
	var content_bottom_target := viewport_height - BOTTOM_MARGIN
	var y := content_bottom_target - _panel_height() * scale.y - content_top_local * scale.y
	return Vector2(position.x, y)

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
func announce(text: String) -> void:
	_announce_label.text = text
	if not is_open:
		await _slide_in()
	await get_tree().create_timer(ANNOUNCE_TIME).timeout
	if _manual_open:
		return
	if is_instance_valid(_announce_label) and _announce_label.text == text:
		await _slide_out()

func _input(event: InputEvent) -> void:
	if _sliding:
		return
	if event.is_action_pressed("dialogue_toggle"):
		get_viewport().set_input_as_handled()
		_manual_open = not _manual_open
		if _manual_open:
			await _slide_in()
		elif is_open:
			await _slide_out()

func _slide_in() -> void:
	_sliding = true
	is_open = true
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "position", _shown_position, SLIDE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_sliding = false

func _slide_out() -> void:
	_sliding = true
	var tween := create_tween()
	tween.tween_property(self, "position", _hidden_position, SLIDE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	is_open = false
	_sliding = false

## Height (in pixels) of whatever's actually painted, so the slide distance
## always matches the panel's real size — same approach as UI.gd's
## _panel_height().
func _panel_height() -> float:
	if tile_set == null:
		return 32.0
	var used_rect := get_used_rect()
	var height := used_rect.size.y * tile_set.tile_size.y
	return height if height > 0 else 32.0

## Same CanvasLayer-ignores-camera-zoom issue as UI.gd (see that file) —
## WindowLayer renders in raw screen pixels, so without this the text would
## render at native size next to the zoomed-in game grid.
func _match_camera_zoom() -> void:
	var camera := get_viewport().get_camera_2d()
	scale = camera.zoom if camera else Vector2(8, 8)

## Deliberately its own action, not UI.gd's menu_toggle — a separate key so
## the battle panel and this status panel can be shown independently
## instead of always sliding together.
func _ensure_dialogue_toggle_action() -> void:
	if InputMap.has_action("dialogue_toggle"):
		return
	InputMap.add_action("dialogue_toggle")
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_D
	InputMap.action_add_event("dialogue_toggle", key_event)
