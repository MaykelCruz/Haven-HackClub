extends Camera2D

## Velocidad de seguimiento horizontal. Valores mayores hacen que la cámara reaccione más rápido.
@export_range(1.0, 20.0, 0.5) var follow_speed: float = 8.0
## Normalmente se deja en ".." porque esta cámara es hija del personaje.
@export var target_path: NodePath = NodePath("..")

var target: Node2D
var fixed_y: float
var horizontal_offset: float


func _ready() -> void:
	enabled = true
	position_smoothing_enabled = false
	target = get_node_or_null(target_path) as Node2D
	fixed_y = global_position.y

	if target:
		horizontal_offset = global_position.x - target.global_position.x
	else:
		push_warning("Camera2D: no se encontró el personaje en target_path.")


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	var desired_x := target.global_position.x + horizontal_offset
	var blend := 1.0 - exp(-follow_speed * delta)

	# Solo cambia X. Y conserva la altura inicial aunque el personaje suba al techo.
	global_position = Vector2(
		lerpf(global_position.x, desired_x, blend),
		fixed_y
	)
