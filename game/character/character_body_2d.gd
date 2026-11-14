extends CharacterBody2D

const SPEED = 360.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity_direction = 1

# Apuntamos exactamente al nodo que se ve en tu imagen
@onready var visual_node = $CollisionShape2D/SorrySlime

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * gravity_direction * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		gravity_direction *= -1
		up_direction = Vector2(0, -gravity_direction)
		
		# Invierte la escala vertical de tu personaje (SorrySlime)
		visual_node.scale.y *= -1

	var direction := Input.get_axis("move_A", "move_D")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
