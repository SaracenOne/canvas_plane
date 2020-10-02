tool

const UI_PIXELS_TO_METER = 1.0 / 1024

static func find_child_control(p_root: Node) -> Control:
	assert(p_root)
	var control_node: Control = null
	for child in p_root.get_children():
		if child is Control:
			control_node = child
			break
			
	return control_node

static func get_physcially_scaled_size_from_control(p_control: Control) -> Vector2:
	return Vector2(p_control.get_size().x * UI_PIXELS_TO_METER, p_control.get_size().y * UI_PIXELS_TO_METER)
