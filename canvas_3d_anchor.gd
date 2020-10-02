extends Spatial
class_name Canvas3DAnchor
tool

const canvas_utils_const = preload("canvas_utils.gd")
const spatial_canvas_const = preload("canvas_plane_v2.gd")

export(NodePath) var canvas_item_node_path: NodePath = NodePath() setget set_canvas_item_node_path
export(Vector2) var offset_ratio: Vector2 = Vector2(0.5, 0.5)
export(float) var z_offset: float = 0.0

var canvas_item: CanvasItem = null
var spatial_canvas: spatial_canvas_const = null

func set_canvas_item_node_path(p_nodepath: NodePath) -> void:
	canvas_item_node_path = p_nodepath

	
func update_transform() -> void:
	if ! spatial_canvas:
		return
	
	var node: Node = get_node_or_null(canvas_item_node_path)
	if node is CanvasItem:
		canvas_item = node
		var ci_gt: Transform2D = canvas_item.get_global_transform()
		var ci_gi_3d: Transform = Transform(ci_gt)
		
		var canvas_size: Vector2 = spatial_canvas.canvas_size
		
		var origin: Vector2 =\
		Vector2(ci_gt.origin.x, 1.0 - ci_gt.origin.y)\
		- Vector2(canvas_size.x, 1.0 - canvas_size.y)  * spatial_canvas.offset_ratio
		
		transform = Transform().translated(\
		Vector3(origin.x, origin.y, 0.0) *  canvas_utils_const.UI_PIXELS_TO_METER)\
		* Transform(ci_gi_3d.basis.inverse(), Vector3())
		
		if canvas_item is Control:
			var ci_size: Vector2 = canvas_item.get_size()
			var rect_offset = Vector2(ci_size.x, ci_size.y) *\
			Vector2(offset_ratio.x, -offset_ratio.y)
			
			transform = transform.translated(Vector3(\
			rect_offset.x * canvas_utils_const.UI_PIXELS_TO_METER,\
			rect_offset.y * canvas_utils_const.UI_PIXELS_TO_METER,
			z_offset * 0.1))
			

func _process(_delta):
	update_transform()

func _ready():
	var parent: Node = get_parent()
	if parent is spatial_canvas_const:
		spatial_canvas = parent
