extends NinePatchRect

var counter
func _ready():
	counter =0
func _on_robot_Kill_count(count):
	$Number.text = str(count)
	pass 


func _on_robot_Kill_increase_counter():
	counter+=1
	$Number.text = str(counter)
	pass 
