extends Spatial
class_name CanvasPlane, "icon_canvas_plane.svg"
tool

const function_pointer_receiver_const = preload("function_pointer_receiver.gd")

export(float, 0.0, 1.0) var canvas_anchor_x : float = 0.0 setget set_canvas_anchor_x
export(float, 0.0, 1.0) var canvas_anchor_y : float = 0.0 setget set_canvas_anchor_y

# Defaults to 16:9
export(float) var canvas_width : float = 1920 setget set_canvas_width
export(float) var canvas_height : float = 1080 setget set_canvas_height

export(float) var canvas_scale : float = 0.01 setget set_canvas_scale

export(bool) var interactable : bool = false setget set_interactable
export(bool) var translucent : bool = false setget set_translucent

export(int, LAYERS_2D_PHYSICS) var collision_mask : int = 0
export(int, LAYERS_3D_PHYSICS) var collision_layer : int = 0

# Render
var spatial_root : Spatial = null
var mesh : Mesh = null
var mesh_instance : MeshInstance = null
var material : Material = null
var viewport : Viewport = null
var control_root : Control = null

# Collision
var pointer_receiver : function_pointer_receiver_const = null
var collision_shape : CollisionShape = null

# Interaction
var previous_mouse_position : Vector2 = Vector2()
var mouse_mask : int = 0

func get_spatial_origin_to_canvas_position(p_origin : Vector3) -> Vector2:
	var transform_scale : Vector2 = Vector2(global_transform.basis.get_scale().x, global_transform.basis.get_scale().y)
	
	var inverse_transform : Vector2 = (Vector2(1.0, 1.0) / transform_scale)
	var point : Vector2 = Vector2(p_origin.x, p_origin.y) * inverse_transform * inverse_transform
	
	var ratio : Vector2 = Vector2(0.5, 0.5) + (point / canvas_scale) / ((Vector2(canvas_width, canvas_height) * canvas_scale) * 0.5)
	ratio.y = 1.0 - ratio.y # Flip the Y-axis
	
	var canvas_position : Vector2 = ratio * Vector2(canvas_width, canvas_height)
	
	print(canvas_position)
	
	return canvas_position

func _update() -> void:
	var canvas_width_offset : float = (canvas_width * 0.5 * 0.5) - (canvas_width * 0.5 * canvas_anchor_x)
	var canvas_height_offset : float = -(canvas_height * 0.5 * 0.5) + (canvas_height * 0.5 * canvas_anchor_y)
	
	if mesh:
		mesh.set_size((Vector2(canvas_width, canvas_height) * 0.5))
		
	if mesh_instance:
		mesh_instance.set_translation(Vector3(canvas_width_offset, canvas_height_offset, 0))
		
	if pointer_receiver:
		pointer_receiver.set_translation(Vector3(canvas_width_offset, canvas_height_offset, 0))
		if collision_shape:
			if collision_shape.is_inside_tree():
				collision_shape.get_parent().remove_child(collision_shape)
			
			if interactable:
				var box_shape = BoxShape.new()
				box_shape.set_extents(Vector3(canvas_width * 0.5 * 0.5, canvas_height * 0.5 * 0.5, 0.0))
				collision_shape.set_shape(box_shape)
				
				pointer_receiver.add_child(collision_shape)
			else:
				collision_shape.set_shape(null)
		
	if spatial_root:
		spatial_root.set_scale(Vector3(canvas_scale, canvas_scale, canvas_scale))

func get_control_root() -> Control:
	return control_root
	
func get_control_viewport() -> Viewport:
	return viewport

func set_canvas_anchor_x(p_anchor : float) -> void:
	canvas_anchor_x = p_anchor
	set_process(true)
	
func set_canvas_anchor_y(p_anchor : float) -> void:
	canvas_anchor_y = p_anchor
	set_process(true)

func set_canvas_width(p_width : float) -> void:
	canvas_width = p_width
	set_process(true)

func set_canvas_height(p_height : float) -> void:
	canvas_height = p_height
	set_process(true)
	
func set_canvas_scale(p_scale : float) -> void:
	canvas_scale = p_scale
	set_process(true)
	
func set_interactable(p_interactable : bool) -> void:
	interactable = p_interactable
	set_process(true)
	
func set_translucent(p_translucent : bool) -> void:
	translucent = p_translucent
	if material:
		material.flags_transparent = translucent
	
func _set_mesh_material(p_material : Material) -> void:
	if mesh:
		if mesh is PrimitiveMesh:
			mesh.set_material(p_material)
		else:
			mesh.surface_set_material(0, p_material)
			
func on_pointer_pressed(p_position : Vector3) -> void:
	var position_2d : Vector2 = get_spatial_origin_to_canvas_position(p_position)
	
	# Let's mimic a mouse
	mouse_mask = 1
	var event : InputEventMouseButton = InputEventMouseButton.new()
	event.set_button_index(1)
	event.set_pressed(true)
	event.set_position(position_2d)
	event.set_global_position(position_2d)
	event.set_button_mask(mouse_mask)
	
	#get_tree().set_input_as_handled()
	viewport.input(event)
	previous_mouse_position = position_2d
	
func on_pointer_release(p_position : Vector3) -> void:
	var position_2d : Vector2 = get_spatial_origin_to_canvas_position(p_position)

	# Let's mimic a mouse
	mouse_mask = 0
	var event : InputEventMouseButton = InputEventMouseButton.new()
	event.set_button_index(1)
	event.set_pressed(false)
	event.set_position(position_2d)
	event.set_global_position(position_2d)
	event.set_button_mask(mouse_mask)
	
	#get_tree().set_input_as_handled()
	viewport.input(event)
	previous_mouse_position = position_2d

"""
func on_pointer_moved(p_position : Vector3) -> void:
	# Disabled temporarily because virtual mouse movement events buggy
	var position_2d : Vector2 = get_spatial_origin_to_canvas_position(p_position)
	
	if position_2d != previous_mouse_position:
		var event : InputEventMouseMotion = InputEventMouseMotion.new()
		event.set_position(position_2d)
		event.set_global_position(position_2d)
		event.set_relative(position_2d - previous_mouse_position) # should this be scaled/warped?
		event.set_button_mask(mouse_mask)
		
		#get_tree().set_input_as_handled()
		viewport.input(event)
		previous_mouse_position = position_2d"""

func _process(p_delta : float) -> void:
	if p_delta > 0.0:
		_update()
		set_process(false)

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
	
	# Collision
	pointer_receiver = function_pointer_receiver_const.new()
	pointer_receiver.set_name("PointerReceiver")
	
	if pointer_receiver.connect("pointer_pressed", self, "on_pointer_pressed") != OK:
		printerr("pointer_pressed could not be connected!")
	if pointer_receiver.connect("pointer_release", self, "on_pointer_release") != OK:
		printerr("pointer_release could not be connected!")
	#if pointer_receiver.connect("pointer_moved", self, "on_pointer_moved") != OK:
	#	printerr("pointer_moved could not be connected!")
	
	pointer_receiver.collision_mask = collision_mask
	pointer_receiver.collision_layer = collision_layer
	spatial_root.add_child(pointer_receiver)
	
	collision_shape = CollisionShape.new()
	collision_shape.set_name("CollisionShape")
	pointer_receiver.add_child(collision_shape)
	
	viewport = Viewport.new()
	viewport.size = Vector2(canvas_width, canvas_height)
	viewport.hdr = false
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.keep_3d_linear = true
	viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
	viewport.audio_listener_enable_2d = false
	viewport.audio_listener_enable_3d = false
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	viewport.set_name("Viewport")
	spatial_root.add_child(viewport)
	
	control_root = Control.new()
	control_root.set_name("ControlRoot")
	control_root.set_anchors_preset(Control.PRESET_WIDE)
	viewport.add_child(control_root)
	
	# Generate the unique material
	material = SpatialMaterial.new()
	material.flags_unshaded = true
	material.flags_transparent = translucent
	material.flags_albedo_tex_force_srgb = true
	
	# Texture
	var flags : int = 0
	var texture : Texture = viewport.get_texture()
	flags |= Texture.FLAG_FILTER
	flags |= Texture.FLAG_MIPMAPS
	texture.set_flags(flags)
	if not Engine.is_editor_hint():
		material.albedo_texture = texture
	
	_update()
	_set_mesh_material(material)
	
	if not Engine.is_editor_hint():
		for child in get_children():
			if child.owner != null:
				child.get_parent().remove_child(child)
				control_root.add_child(child)
