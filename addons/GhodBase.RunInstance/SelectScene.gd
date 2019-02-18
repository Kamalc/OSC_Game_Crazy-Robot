tool
extends FileDialog

var newInstanceDocker

func _on_SelectScene_file_selected(path):
	var OptionsDialog = preload("res://addons/GhodBase.RunInstance/OptionsDialog.tscn").instance()
	OptionsDialog.newInstanceDocker = $"."
	OptionsDialog.find_node("txtPath").text = current_dir
	OptionsDialog.current_path = current_path
	OptionsDialog.newInstanceDocker = newInstanceDocker
	get_tree().root.add_child(OptionsDialog)
	OptionsDialog.popup()
