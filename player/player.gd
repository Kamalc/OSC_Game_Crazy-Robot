extends KinematicBody


puppet var aiming = false
puppet var jump_pressed = false
const CAMERA_ROTATION_SPEED = 0.001
const GRAVITY = Vector3(0,-9.8, 0)
const DIRECTION_INTERPOLATE_SPEED = 1

const MOTION_INTERPOLATE_SPEED = 10
const ROTATION_INTERPOLATE_SPEED = 10
puppet var motion = Vector2()
puppet var puppet_pos = Vector3()
const CAMERA_X_ROT_MIN = -40
const CAMERA_X_ROT_MAX = 30

puppet var camera_x_rot = 0.0

var velocity = Vector3()

var orientation = Transform()

var airborne_time = 100
const MIN_AIRBORNE_TIME = 0.1

const JUMP_SPEED = 5

var root_motion = Transform()

enum ANIMATION_STATE{STRAFE=0,WALK=1,JUMP_UP=2,JUMP_DOWN=3}
puppet var current_animation = ANIMATION_STATE.STRAFE

func _input(event):
	if event is InputEventMouseMotion:
		$camera_base.rotate_y( -event.relative.x * CAMERA_ROTATION_SPEED )
		$camera_base.orthonormalize() # after relative transforms, camera needs to be renormalized
		camera_x_rot = clamp(camera_x_rot + event.relative.y * CAMERA_ROTATION_SPEED,deg2rad(CAMERA_X_ROT_MIN), deg2rad(CAMERA_X_ROT_MAX) )
		rset('camera_x_rot',camera_x_rot)
		$camera_base/camera_rot.rotation.x =  camera_x_rot

func _ready():
	#pre initialize orientation transform	
	orientation=$"Scene Root".global_transform
	orientation.origin = Vector3()
	if is_network_master():
		$camera_base/camera_rot/Camera.current = true
		set_process_input(true)
	else:
		$camera_base/camera_rot/Camera.current = false
		set_process_input(false)
	
func _physics_process(delta):
	if is_network_master():
		var motion_target = Vector2( 	Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
										Input.get_action_strength("move_forward") - Input.get_action_strength("move_back") )
		motion = motion.linear_interpolate(motion_target, MOTION_INTERPOLATE_SPEED * delta)
		rset("motion",motion)
		rset_unreliable('puppet_pos',transform.origin)
		var current_aim = Input.is_action_pressed("aim")
		if (aiming != current_aim):
				aiming = current_aim
				if (aiming):
					$camera_base/animation.play("shoot")
				else:
					$camera_base/animation.play("far")
		rset('aiming',aiming)
	else:
		transform.origin = puppet_pos
		$camera_base/camera_rot.rotation.x =  camera_x_rot
	var cam_z = - $camera_base/camera_rot/Camera.global_transform.basis.z			
	var cam_x = $camera_base/camera_rot/Camera.global_transform.basis.x
	
	cam_z.y=0
	cam_z = cam_z.normalized()
	cam_x.y=0
	cam_x = cam_x.normalized()
	
	
	
	# jump/air logic
	airborne_time += delta
	if (is_on_floor()):
		if (airborne_time>0.5):
			$sfx/land.play()
		airborne_time = 0
		
	var on_air = airborne_time > MIN_AIRBORNE_TIME
	if is_network_master():
		jump_pressed = Input.is_action_just_pressed("jump")
		rset('jump_pressed',jump_pressed)
	if (not on_air and jump_pressed):
		velocity.y = JUMP_SPEED
		on_air = true
		$animation_tree["parameters/state/current"]=2
		$sfx/jump.play()							


	if (on_air):
		if (velocity.y > 0):
			$animation_tree["parameters/state/current"]=2
		else:
			$animation_tree["parameters/state/current"]=3
	
	elif(aiming):
		
		# change state to strafe
		$animation_tree["parameters/state/current"]=0

		#change aim according to camera rotation
				
		if (camera_x_rot >= 0): # aim up		
			$animation_tree["parameters/aim/add_amount"]=-camera_x_rot / deg2rad(CAMERA_X_ROT_MAX)
		else: # aim down
			$animation_tree["parameters/aim/add_amount"] = camera_x_rot / deg2rad(CAMERA_X_ROT_MIN)
					
		# convert orientation to quaternions for interpolating rotation
		var q_from = Quat(orientation.basis)
		var q_to = Quat( $camera_base.global_transform.basis )	
		# interpolate current rotation with desired one
		orientation.basis = Basis(q_from.slerp(q_to,delta*ROTATION_INTERPOLATE_SPEED))
			

		$animation_tree["parameters/strafe/blend_position"]=motion


		# get root motion transform
		root_motion = $animation_tree.get_root_motion_transform()

		if (Input.is_action_just_pressed('shoot')) and is_network_master():
			var shoot_from = $"Scene Root/Robot_Skeleton/Skeleton/gun_bone/shoot_from".global_transform.origin
			var cam = $camera_base/camera_rot/Camera
			var ch_pos = $crosshair.rect_position + $crosshair.rect_size * 0.5
			var ray_from = cam.project_ray_origin(ch_pos)
			var ray_dir = cam.project_ray_normal(ch_pos)
			var shoot_target
			var col = get_world().direct_space_state.intersect_ray( ray_from, ray_from + ray_dir * 1000, [self] )
			if (col.empty()):
				shoot_target = ray_from + ray_dir * 1000
			else:
				shoot_target = col.position
			var shoot_dir = (shoot_target - shoot_from).normalized()
			
			rpc('shoot',shoot_from,shoot_dir)
			
	else: 		
		# convert orientation to quaternions for interpolating rotation
		
		var target = - cam_x * motion.x -  cam_z * motion.y
		if (target.length() > 0.001):
			var q_from = Quat(orientation.basis)
			var q_to = Quat(Transform().looking_at(target,Vector3(0,1,0)).basis)
	
			# interpolate current rotation with desired one
			orientation.basis = Basis(q_from.slerp(q_to,delta*ROTATION_INTERPOLATE_SPEED))
		
		#aim to zero (no aiming while walking
		
		$animation_tree["parameters/aim/add_amount"]=0
		# change state to walk
		$animation_tree["parameters/state/current"]=1
		# blend position for walk speed based on motion
		$animation_tree["parameters/walk/blend_position"]=Vector2(motion.length(),0 ) 
		
		# get root motion transform
		root_motion = $animation_tree.get_root_motion_transform()		

	
	# apply root motion to orientation
	orientation *= root_motion
	
	var h_velocity = orientation.origin / delta
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z		
	velocity += GRAVITY * delta
	velocity = move_and_slide(velocity,-GRAVITY.normalized())

	orientation.origin = Vector3() #clear accumulated root motion displacement (was applied to speed)
	orientation = orientation.orthonormalized() # orthonormalize orientation
	
	$"Scene Root".global_transform.basis = orientation.basis



func init(name, new_position, is_slave):
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	transform.origin = new_position


remotesync func shoot(shoot_from,shoot_dir):
	var bullet = preload("res://player/bullet.tscn").instance()
	get_parent().add_child(bullet)
	bullet.global_transform.origin = shoot_from
	bullet.direction = shoot_dir 
	bullet.add_collision_exception_with(self)
	$sfx/shoot.play()