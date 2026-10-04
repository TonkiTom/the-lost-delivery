extends CharacterBody2D

@export var speed: float = 210.0
@export var jump_force: float = 350.0
@export var gravity: float = 900.0

var on_ground: bool = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_force
			on_ground = false

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity.x = input.x * speed
	velocity.y = clamp(velocity.y, -700, 700)
	move_and_slide()
	
	if is_on_floor():
		on_ground = true
	else:
		on_ground = false

func get_anim_direction() -> float:
	return sign(velocity.x)
