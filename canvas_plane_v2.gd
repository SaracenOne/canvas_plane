extends Spatial
class_name CanvasPlaneV2, "icon_canvas_plane.svg"
tool

const canvas_utils_const = preload("canvas_utils.gd")
const function_pointer_receiver_const = preload("function_pointer_receiver.gd")

var _is_dirty: bool = true

export (Vector2) var canvas_anchor: Vector2 = Vector2(0.5, 0.5) setget set_canvas_anchor

export (bool) var interactable: bool = false setget set_interactable
export (bool) var translucent: bool = false setget set_translucent

export (int, LAYERS_2D_PHYSICS) var collision_mask: int = 0
export (int, LAYERS_3D_PHYSICS) var collision_layer: int = 0

var tree_changed: bool = true
var original_canvas_rid: RID = RID()

# Render
var canvas_size: Vector2 = Vector2()
var spatial_root: Spatial = null
var mesh: Mesh = null
var mesh_instance: MeshInstance = null
var material: Material = null
var viewport: Viewport = null
var control_root: Control = null

# Collision
var pointer_receiver: function_pointer_receiver_const = null
var collision_shape: CollisionShape = null

# Interaction
var previous_mouse_position: Vector2 = Vector2()
var mouse_mask: int = 0

"""
func get_spatial_origin_to_canvas_position(p_origin: Vector3) -> Vector2:
	var transform_scale: Vector2 = Vector2(
		global_transform.basis.get_scale().x, global_transform.basis.get_scale().y
	)

	var inverse_transform: Vector2 = Vector2(1.0, 1.0) / transform_scale
	var point: Vector2 = Vector2(p_origin.x, p_origin.y) * inverse_transform * inverse_transform

	var ratio: Vector2 = (
		Vector2(0.5, 0.5)
		+ (point / canvas_scale) / ((Vector2(canvas_width, canvas_height) * canvas_scale) * 0.5)
	)
	ratio.y = 1.0 - ratio.y  # Flip the Y-axis

	var canvas_position: Vector2 = ratio * Vector2(canvas_width, canvas_height)

	return canvas_position
"""

func _update() -> void:
	print("_update")
	_update_control_root()
	
	var scaled_canvas_size: Vector2 = canvas_size * canvas_utils_const.UI_PIXELS_TO_METER
	
	var canvas_offset: Vector2 = Vector2((
		(scaled_canvas_size.x * 0.5)
		- (scaled_canvas_size.x * canvas_anchor.x)
	),(
		-(scaled_canvas_size.y * 0.5)
		+ (scaled_canvas_size.y * canvas_anchor.y)
	))

	if mesh:
		mesh.set_size(scaled_canvas_size)

	if mesh_instance:
		mesh_instance.set_translation(Vector3(canvas_offset.x, canvas_offset.y, 0))
				
	clear_dirty_flag()


func get_control_root() -> Control:
	return control_root


func get_control_viewport() -> Viewport:
	return viewport


func set_canvas_anchor(p_anchor: Vector2) -> void:
	canvas_anchor = p_anchor
	set_dirty_flag()


func set_interactable(p_interactable: bool) -> void:
	interactable = p_interactable
	set_dirty_flag()


func set_translucent(p_translucent: bool) -> void:
	translucent = p_translucent
	if material:
		material.flags_transparent = translucent


func _setup_canvas_item() -> void:
	if control_root.is_connected("resized", self, "_resized") == false:
		control_root.connect("resized", self, "_resized")
	original_canvas_rid = control_root.get_canvas()
	VisualServer.canvas_item_set_parent(control_root.get_canvas_item(), viewport.find_world_2d().get_canvas())


func _set_mesh_material(p_material: Material) -> void:
	if mesh:
		if mesh is PrimitiveMesh:
			mesh.set_material(p_material)
		else:
			mesh.surface_set_material(0, p_material)


func _find_control_root() -> void:
	if tree_changed:
		var new_control_root: Control = canvas_utils_const.find_child_control(self)
		if new_control_root != control_root:
			
			# Clear up the old control root
			if control_root:
				if control_root.is_connected("resized", self, "_resized"):
					control_root.disconnect("resized", self, "_resized")
					VisualServer.canvas_item_set_parent(control_root.get_canvas_item(), original_canvas_rid)
			
			# Assign the new control rool and give 
			control_root = new_control_root
			if control_root:
				_setup_canvas_item()
		
		tree_changed = false

func _update_control_root() -> void:
	if Engine.is_editor_hint():
		_find_control_root()
		
	if control_root:
		canvas_size = control_root.rect_size
	else:
		canvas_size = Vector2()
	
	print("canvas_size: " + str(canvas_size))
	viewport.size = canvas_size


func set_dirty_flag() -> void:
	#print("set_dirty_flag")
	if _is_dirty == false:
		_is_dirty = true
		call_deferred("_update")
			
func clear_dirty_flag() -> void:
	#print("clear_dirty_flag")
	_is_dirty = false


func _tree_changed() -> void:
	#print("_tree_changed")
	tree_changed = true
	set_dirty_flag()


func _resized() -> void:
	#print("_resized")
	set_dirty_flag()


func _exit_tree():
	if Engine.is_editor_hint():
		if get_tree().is_connected("tree_changed", self, "_tree_changed"):
			get_tree().disconnect("tree_changed", self, "_tree_changed")
		if control_root:
			if control_root.is_connected("resized", self, "_resized"):
				control_root.disconnect("resized", self, "_resized")

func _enter_tree():
	if control_root and viewport:
		call_deferred("_setup_canvas_item")

func _ready() -> void:
	spatial_root = Spatial.new()
	spatial_root.set_name("SpatialRoot")
	add_child(spatial_root)

	mesh = PlaneMesh.new()

	mesh_instance = MeshInstance.new()
	mesh_instance.set_mesh(mesh)
	mesh_instance.rotate_x(deg2rad(-90))
	mesh_instance.set_scale(Vector3(1.0, -1.0, 1.0))
	mesh_instance.set_name("MeshInstance")
	mesh_instance.set_skeleton_path(NodePath())
	
	spatial_root.add_child(mesh_instance)
	mesh_instance.set_owner(spatial_root)
	spatial_root.set_owner(self)

	# Collision
	pointer_receiver = function_pointer_receiver_const.new()
	pointer_receiver.set_name("PointerReceiver")

	if pointer_receiver.connect("pointer_pressed", self, "on_pointer_pressed") != OK:
		printerr("pointer_pressed could not be connected!")
	if pointer_receiver.connect("pointer_release", self, "on_pointer_release") != OK:
		printerr("pointer_release could not be connected!")

	pointer_receiver.collision_mask = collision_mask
	pointer_receiver.collision_layer = collision_layer
	spatial_root.add_child(pointer_receiver)

	collision_shape = CollisionShape.new()
	collision_shape.set_name("CollisionShape")
	pointer_receiver.add_child(collision_shape)

	viewport = Viewport.new()
	viewport.size = Vector2(0, 0)
	viewport.hdr = false
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.keep_3d_linear = true
	viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
	viewport.audio_listener_enable_2d = false
	viewport.audio_listener_enable_3d = false
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	viewport.set_name("Viewport")
	if Engine.is_editor_hint():
		VisualServer.viewport_attach_canvas(get_viewport().get_viewport_rid(), viewport.find_world_2d().get_canvas())
	else:
		_find_control_root()
	
	spatial_root.add_child(viewport)

	# Generate the unique material
	material = SpatialMaterial.new()
	material.flags_unshaded = true
	material.flags_transparent = translucent
	material.flags_albedo_tex_force_srgb = true
	
	_update()
	_set_mesh_material(material)
	
	# Texture
	var texture: ViewportTexture = viewport.get_texture()
	var flags: int = Texture.FLAGS_DEFAULT
	texture.set_flags(flags)
	material.albedo_texture = texture

	if Engine.is_editor_hint():
		if get_tree().connect("tree_changed", self, "_tree_changed") != OK:
			printerr("Could not connect tree_changed")
