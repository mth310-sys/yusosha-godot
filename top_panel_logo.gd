extends Node

const LOGO_URL := "https://mth310-sys.github.io/Chappy5/src/game/slot-pachiro/machines/pekachu/zelvolt_logo.jpg"

var _request: HTTPRequest
var _logo_rect: TextureRect

func _ready() -> void:
	call_deferred("_install_logo")

func _install_logo() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var top_panel := scene.get_node_or_null("TopPanel") as Control
	if top_panel == null:
		return

	_logo_rect = TextureRect.new()
	_logo_rect.name = "ZelvoltUpperPanelArtwork"
	_logo_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_logo_rect.offset_left = 8.0
	_logo_rect.offset_top = 8.0
	_logo_rect.offset_right = -8.0
	_logo_rect.offset_bottom = -8.0
	_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo_rect.z_index = 3
	top_panel.add_child(_logo_rect)

	_request = HTTPRequest.new()
	_request.name = "ZelvoltUpperPanelRequest"
	_request.request_completed.connect(_on_request_completed)
	scene.add_child(_request)
	var err := _request.request(LOGO_URL)
	if err != OK:
		_request.queue_free()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		var image := Image.new()
		if image.load_jpg_from_buffer(body) == OK:
			_logo_rect.texture = ImageTexture.create_from_image(image)
			_hide_text_logo()
	if is_instance_valid(_request):
		_request.queue_free()

func _hide_text_logo() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var title := scene.get_node_or_null("Center/VBox/Title") as CanvasItem
	var subtitle := scene.get_node_or_null("Center/VBox/Subtitle") as CanvasItem
	if title != null:
		title.visible = false
	if subtitle != null:
		subtitle.visible = false
