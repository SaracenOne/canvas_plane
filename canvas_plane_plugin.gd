extends EditorPlugin
tool

var editor_interface = null

func get_name(): 
	return "CanvasPlane"

func _enter_tree():
	editor_interface = get_editor_interface()
	
	add_custom_type("CanvasPlane", "Spatial", preload("canvas_plane.gd"), preload("icon_canvas_plane.svg"))

func _exit_tree():
	remove_custom_type("CanvasPlane")