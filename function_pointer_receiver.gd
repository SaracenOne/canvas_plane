extends Area

const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

signal pointer_pressed(p_at)
signal pointer_moved(p_at, p_from)
signal pointer_release(p_at)

func untransform_position(p_vector : Vector3) -> Vector3:
	return global_transform.xform_inv(p_vector)
	
func untransform_normal(p_normal : Vector3) -> Vector3:
	var basis : Basis = Basis(global_transform.basis.get_rotation_quat())
	return math_funcs_const.transform_directon_vector(p_normal, basis.inverse())
	
func validate_pointer(p_normal : Vector3) -> bool:
	var basis : Basis = Basis(global_transform.basis.get_rotation_quat())
	var transform_normal : Vector3 = untransform_normal(p_normal)
	if transform_normal.z > 0.0:
		return true
	else:
		return false
	
func on_pointer_pressed(p_position : Vector3) -> void:
	emit_signal("pointer_pressed", untransform_position(p_position))

func on_pointer_moved(p_position : Vector3, p_normal : Vector3) -> void:
	if validate_pointer(p_normal):
		emit_signal("pointer_moved", p_position)

func on_pointer_release(p_position : Vector3) -> void:
	emit_signal("pointer_release", untransform_position(p_position))
