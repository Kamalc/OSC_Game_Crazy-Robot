tool
extends Control

var knownScenes = []
var knownScenesSaveFilePath = "res://addons/GhodBase.RunInstance/RunInstance_known_scenes.ini"

func _ready():
	randomize()
	loadKnownScenes()

# load scenes from last session
func loadKnownScenes():
	var instancesConfigFile = ConfigFile.new()
	instancesConfigFile.load(knownScenesSaveFilePath)
	knownScenes = instancesConfigFile.get_value("RunInstance", "knownScenes", knownScenes)
	
	for scene in knownScenes:
		var pidContainerInstance = preload("res://addons/GhodBase.RunInstance/PidContainer.tscn").instance()
		pidContainerInstance.pidId = -1
		pidContainerInstance.sceneName = scene["sceneName"]
		pidContainerInstance.options = scene["options"]
		pidContainerInstance.get_node("lblPid").text = scene["sceneName"]
		pidContainerInstance.newInstanceDocker = $"."
		pidContainerInstance.id = randi() % 2000000000
		
		add_child(pidContainerInstance)

func addKnownScene(options, sceneName, id):
	knownScenes.append({"options": options, "sceneName": sceneName, "id": id})
	saveKnownScenes()


func clearKnownScenes():
	var confirmationDialog = ConfirmationDialog.new()
	confirmationDialog.dialog_text = "Are you sure?"
	confirmationDialog.connect("confirmed", self, "_on_clearKnownScenes_confirmed")
	get_tree().root.add_child(confirmationDialog)
	confirmationDialog.popup_centered()

func _on_clearKnownScenes_confirmed():
	knownScenes.clear()
	saveKnownScenes()
	for child in get_children():
		if child is HBoxContainer:
			child.queue_free()

func saveKnownScenes():
	var instancesConfigFile = ConfigFile.new()
	instancesConfigFile.set_value("RunInstance", "knownScenes", knownScenes)
	instancesConfigFile.save(knownScenesSaveFilePath)

func removeKnownScene(id):
	for scene in knownScenes:
		if scene.id == id:
			knownScenes.erase(scene)
	saveKnownScenes()

func _on_Button_pressed():
	var SelectScene = preload("res://addons/GhodBase.RunInstance/SelectScene.tscn").instance()
	SelectScene.newInstanceDocker = $"."
	SelectScene.current_dir = ProjectSettings.globalize_path("res://")
	get_tree().root.add_child(SelectScene)
	SelectScene.popup()

func _on_Clear_pressed():
	clearKnownScenes()

func _on_RestartAll_pressed():
	for child in get_children():
		if child is HBoxContainer:
			child._on_btnReRun_pressed()
