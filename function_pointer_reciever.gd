extends Area

signal pointer_pressed(p_at)
signal pointer_moved(p_at, p_from)
signal pointer_release(p_at)

func xform_vector(p_vector : Vector3) -> Vector3:
	return global_transform.xform_inv(p_vector)
	
func validate_pointer(p_normal : Vector3) -> bool:
	if xform_vector(p_normal).z > 0.0:
		return true
	else:
		return false
	
func on_pointer_pressed(p_position : Vector3) -> void:
	emit_signal("pointer_pressed", xform_vector(p_position))

func on_pointer_moved(p_position : Vector3, p_normal : Vector3) -> void:
	if validate_pointer(p_normal):
		emit_signal("pointer_moved", p_position)

func on_pointer_release(p_position : Vector3) -> void:
	emit_signal("pointer_release", xform_vector(p_position))
