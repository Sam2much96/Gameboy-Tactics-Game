extends Control

# Mirrors src/titlescreen/titlescreen.c's run_titlescreen(): a 3-option
# START/CONTINUE/MULTIPLAYER menu navigated with the d-pad and confirmed
# with A, plus mouse clicks on the buttons (existing Godot behavior).
#
# The pointer sprite ($Control/Sprite2D) used to be driven from here, but
# it's now a TextureButton with its own mouse-follow script
# (title_screen_pointer.gd) — see that file. Keyboard-selected option
# feedback is now each Button's native focus outline instead of a hand icon
# tracking the selection.

@onready var _buttons: Array[Button] = [
	$Control/VBoxContainer/Button,
	$Control/VBoxContainer/Button2,
	$Control/VBoxContainer/Button3,
]

var _index: int = 0
var _busy: bool = false
var _fade: FadeOverlay

func _ready() -> void:
	_fade = FadeOverlay.new()
	add_child(_fade)

	for i in _buttons.size():
		_buttons[i].pressed.connect(_on_option_chosen.bind(i))

	_buttons[_index].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_up"):
		_index = max(_index - 1, 0)
		_buttons[_index].grab_focus()
	elif event.is_action_pressed("ui_down"):
		_index = min(_index + 1, _buttons.size() - 1)
		_buttons[_index].grab_focus()
	elif event.is_action_pressed("ui_accept"):
		_on_option_chosen(_index)

func _on_option_chosen(i: int) -> void:
	if _busy:
		return
	_index = i
	_buttons[i].grab_focus()

	if i == 2:
		# Multiplayer: GB's build only flashes the pointer here and stays on
		# the menu (src/multiplayer/ has no networking implemented anywhere)
		# — mirror that rather than pretending it works.
		return

	# START and CONTINUE currently behave identically: GB has no save/load
	# implemented yet either (main.c has an explicit `Future:` TODO to
	# distinguish them once a save system exists).
	_busy = true
	await _fade.fade_out()
	get_tree().change_scene_to_packed(load("res://main.tscn"))
