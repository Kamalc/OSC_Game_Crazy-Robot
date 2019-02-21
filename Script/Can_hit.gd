extends Node

var Health =100

func _ready():
	pass # Replace with function body.


func hit(var x,var name):
	rpc('_synced_hit',x,name)

remotesync func _synced_hit(x,name):
	x=6*x
	Health-=x
	if Health<=0:
		#get_tree().get_root().get_node("World").find_node(name).do_kill()
		get_parent().get_parent().queue_free()
