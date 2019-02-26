extends Node

var health =100

func _ready():
	pass # Replace with function body.


func hit(damage,name):
	rpc('_synced_hit',damage,name)

remotesync func _synced_hit(damage,name):
	health-=int(damage)
	if health<=0:
		#get_tree().get_root().get_node("World").find_node(name).do_kill()
		get_parent().get_parent().queue_free()
