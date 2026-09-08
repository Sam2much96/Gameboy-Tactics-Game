class_name FadeOverlay
extends CanvasLayer

# Reusable fade transition. GB's fadeout()/fadein() (src/main.c) step BGP_REG
# through a ramp that ends on 0xFF — an all-white palette — so this fades to
# WHITE, not black, to match.

var _rect: ColorRect

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(1, 1, 1, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

func snap_opaque() -> void:
	_rect.color = Color(1, 1, 1, 1)

func snap_transparent() -> void:
	_rect.color = Color(1, 1, 1, 0)

func fade_out(duration: float = 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 1.0, duration)
	await tween.finished

func fade_in(duration: float = 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", 0.0, duration)
	await tween.finished
