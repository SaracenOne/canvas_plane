extends Spatial
tool

const function_pointer_reciever_const = preload("function_pointer_reciever.gd")

export(float, 0.0, 1.0) var canvas_anchor_x = 0.0 setget set_canvas_anchor_x
export(float, 0.0, 1.0) var canvas_anchor_y = 0.0 setget set_canvas_anchor_y

# Defaults to 16:9
export(float) var canvas_width = 1920 setget set_canvas_width
export(float) var canvas_height = 1080 setget set_canvas_height

export(float) var canvas_scale = 0.01 setget set_canvas_scale

export(bool) var interactable = false setget set_interactable

# Render
var spatial_root = null
var mesh = null
var mesh_instance = null
var material = null
var viewport = null
var control_root = null

# Collision
var pointer_reciever = null
var collision_shape = null

# Interaction
var previous_mouse_position = Vector2()
var mouse_mask = 0

func get_spatial_origin_to_canvas_position(p_origin):
	var transform_scale = Vector2(global_transform.basis.get_scale().x, global_transform.basis.get_scale().y)
	
	var inverse_transform = (Vector2(1.0, 1.0) / transform_scale)
	var point = Vector2(p_origin.x, p_origin.y) * inverse_transform * inverse_transform
	
	var ratio = Vector2(0.5, 0.5) + (point / canvas_scale) / ((Vector2(canvas_width, canvas_height) * canvas_scale) * 0.5)
	ratio.y = 1.0 - ratio.y # Flip the Y-axis
	
	var canvas_position = ratio * Vector2(canvas_width, canvas_height)
	
	return canvas_position

func _update():
	var canvas_width_offset = (canvas_width * 0.5 * 0.5) - (canvas_width * 0.5 * canvas_anchor_x)
	var canvas_height_offset = -(canvas_height * 0.5 * 0.5) + (canvas_height * 0.5 * canvas_anchor_y)
	
	if mesh:
		mesh.set_size((Vector2(canvas_width, canvas_height) * 0.5))
		
	if mesh_instance:
		mesh_instance.set_translation(Vector3(canvas_width_offset, canvas_height_offset, 0))
		
	if pointer_reciever:
		pointer_reciever.set_translation(Vector3(canvas_width_offset, canvas_height_offset, 0))
		if collision_shape:
			if collision_shape.is_inside_tree():
				collision_shape.get_parent().remove_child(collision_shape)
			
			if interactable:
				var box_shape = BoxShape.new()
				box_shape.set_extents(Vector3(canvas_width * 0.5 * 0.5, canvas_height * 0.5 * 0.5, 0.0))
				collision_shape.set_shape(box_shape)
				
				pointer_reciever.add_child(collision_shape)
			else:
				collision_shape.set_shape(null)
		
	if spatial_root:
		spatial_root.set_scale(Vector3(canvas_scale, canvas_scale, canvas_scale))

func get_control_root():
	return control_root

func set_canvas_anchor_x(p_anchor):
	canvas_anchor_x = p_anchor
	set_process(true)
	
func set_canvas_anchor_y(p_anchor):
	canvas_anchor_y = p_anchor
	set_process(true)

func set_canvas_width(p_width):
	canvas_width = p_width
	set_process(true)

func set_canvas_height(p_height):
	canvas_height = p_height
	set_process(true)
	
func set_canvas_scale(p_scale):
	canvas_scale = p_scale
	set_process(true)
	
func set_interactable(p_interactable):
	interactable = p_interactable
	set_process(true)
	
func _set_mesh_material(p_material):
	if mesh:
		if mesh is PrimitiveMesh:
			mesh.set_material(p_material)
		else:
			mesh.surface_set_material(0, p_material)
			
func on_pointer_pressed(p_position):
	var position_2d = get_spatial_origin_to_canvas_position(p_position)
	
	# Let's mimic a mouse
	mouse_mask = 1
	var event = InputEventMouseButton.new()
	event.set_button_index(1)
	event.set_pressed(true)
	event.set_position(position_2d)
	event.set_global_position(position_2d)
	event.set_button_mask(mouse_mask)
	
	get_tree().set_input_as_handled(false)
	viewport.input(event)
	previous_mouse_position = position_2d
	
func on_pointer_release(p_position):
	var position_2d = get_spatial_origin_to_canvas_position(p_position)

	# Let's mimic a mouse
	mouse_mask = 0
	var event = InputEventMouseButton.new()
	event.set_button_index(1)
	event.set_pressed(false)
	event.set_position(position_2d)
	event.set_global_position(position_2d)
	event.set_button_mask(mouse_mask)
	
	get_tree().set_input_as_handled(false)
	viewport.input(event)
	previous_mouse_position = position_2d

func on_pointer_moved(p_position):
	var position_2d = get_spatial_origin_to_canvas_position(p_position)
	
	if position_2d != previous_mouse_position:
		var event = InputEventMouseMotion.new()
		event.set_position(position_2d)
		event.set_global_position(position_2d)
		event.set_relative(position_2d - previous_mouse_position) # should this be scaled/warped?
		event.set_button_mask(mouse_mask)
		
		get_tree().set_input_as_handled(false)
		viewport.input(event)
		previous_mouse_position = position_2d

func _process(p_delta):
	_update()
	set_process(false)

func _ready():
	spatial_root = Spatial.new()
	spatial_root.set_name("SpatialRoot")
	add_child(spatial_root)
	
	mesh = PlaneMesh.new()
	
	mesh_instance = MeshInstance.new()
	mesh_instance.set_mesh(mesh)
	mesh_instance.rotate_x(deg2rad(-90))
	mesh_instance.set_scale(Vector3(-1.0, -1.0, -1.0))
	mesh_instance.set_name("MeshInstance")
	mesh_instance.set_skeleton_path(NodePath())
	spatial_root.add_child(mesh_instance)
	
	# Collision
	pointer_reciever = function_pointer_reciever_const.new()
	pointer_reciever.set_name("PointerReciever")
	pointer_reciever.connect("pointer_moved", self, "on_pointer_moved")
	spatial_root.add_child(pointer_reciever)
	
	collision_shape = CollisionShape.new()
	collision_shape.set_name("CollisionShape")
	pointer_reciever.add_child(collision_shape)
	
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
	material.flags_transparent = true
	material.flags_albedo_tex_force_srgb = true
	
	# Texture
	var flags = 0
	var texture = viewport.get_texture()
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
				var name = child.get_name()
				child.get_parent().remove_child(child)
				control_root.add_child(child)