extends Control




var text = ""
var tfont: Font
var sz = 100
var anchor = Vector2.ZERO
var lean = -0.2
var col = Color.WHITE


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if tfont == null:
		return
	var w = tfont.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(lean, 1), anchor - position))
	draw_string(tfont, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
