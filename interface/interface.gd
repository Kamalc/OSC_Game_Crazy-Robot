extends Spatial

signal health_updated(value)
signal rupees_updated(count)

func _ready():
	var health_node = null
	health_node = get_parent().get_node("Health")
	get_node("Bars/LifeBar").initialize(health_node.max_health)

func _on_Health_health_changed(health):
	emit_signal("health_updated", health)

func _on_Purse_rupees_changed(count):
	emit_signal("rupees_updated", count)
