extends Area

signal pointer_pressed(p_at)
signal pointer_moved(p_at, p_from)
signal pointer_release(p_at)

func xform_vector(p_vector):
	return global_transform.xform_inv(p_vector)
	
func on_pointer_pressed(p_position):
	emit_signal("pointer_pressed", xform_vector(p_position))

func on_pointer_moved(p_position, p_normal):
	if xform_vector(p_normal).z > 0.0:
		emit_signal("pointer_moved", xform_vector(p_position))
		return true
		
	return false

func on_pointer_release(p_position):
	emit_signal("pointer_release", xform_vector(p_position))
