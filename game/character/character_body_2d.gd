
extends CharacterBody2D

const SPEED = 360.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity_direction = 1

# =====================================
# CONFIGURACION VISUAL DEL SLIME
# =====================================

@onready var slime_visual: Sprite2D = $CollisionShape2D/SorrySlime

var slime_tween: Tween
var slime_state: String = "idle"

var slime_base_scale: Vector2
var slime_base_position: Vector2
var slime_half_height: float
var slime_factor: Vector2 = Vector2.ONE


func _ready() -> void:
	setup_slime_animation()


# =====================================
# CONFIGURACION DE LA ANIMACION
# =====================================

func setup_slime_animation() -> void:
	slime_base_scale = slime_visual.scale
	slime_base_position = slime_visual.position

	slime_half_height = (
		slime_visual.texture.get_size().y
		* slime_base_scale.y
		* 0.5
	)

	slime_visual.flip_v = false
	_set_slime_factor(Vector2.ONE)


func _set_slime_factor(factor: Vector2) -> void:
	slime_factor = factor

	# Escala visual sin modificar las colisiones.
	slime_visual.scale = slime_base_scale * factor

	# Conserva el contacto con el suelo o el techo.
	slime_visual.position.y = (
		slime_base_position.y
		+ gravity_direction * slime_half_height * (1.0 - factor.y)
	)


func stop_slime_animation() -> void:
	if slime_tween and slime_tween.is_running():
		slime_tween.kill()


# =====================================
# ESTIRAMIENTO AL INVERTIR LA GRAVEDAD
# =====================================

func slime_jump_animation() -> void:
	stop_slime_animation()

	slime_state = "air"

	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_BACK)
	slime_tween.set_ease(Tween.EASE_OUT)

	slime_tween.tween_method(
		_set_slime_factor,
		slime_factor,
		Vector2(0.88, 1.16),
		0.12
	)

	slime_tween.tween_method(
		_set_slime_factor,
		Vector2(0.88, 1.16),
		Vector2(0.96, 1.06),
		0.12
	)


# =====================================
# ESTIRAMIENTO AL CAER
# =====================================

func slime_fall_animation() -> void:
	stop_slime_animation()

	slime_state = "fall"

	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_SINE)
	slime_tween.set_ease(Tween.EASE_OUT)

	slime_tween.tween_method(
		_set_slime_factor,
		slime_factor,
		Vector2(0.94, 1.10),
		0.18
	)


# =====================================
# APLASTAMIENTO AL ATERRIZAR
# =====================================

func slime_land_animation() -> void:
	stop_slime_animation()

	slime_state = "landing"

	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_BACK)
	slime_tween.set_ease(Tween.EASE_OUT)

	slime_tween.tween_method(
		_set_slime_factor,
		slime_factor,
		Vector2(1.20, 0.78),
		0.09
	)

	slime_tween.tween_method(
		_set_slime_factor,
		Vector2(1.20, 0.78),
		Vector2(0.92, 1.08),
		0.12
	)

	slime_tween.tween_method(
		_set_slime_factor,
		Vector2(0.92, 1.08),
		Vector2.ONE,
		0.12
	)

	slime_tween.tween_callback(func():
		slime_state = "idle"
	)


# =====================================
# DEFORMACION AL CAMINAR
# =====================================

func slime_walk_animation() -> void:
	if slime_state == "walk":
		return

	stop_slime_animation()

	slime_state = "walk"
	_set_slime_factor(Vector2.ONE)

	slime_tween = create_tween().set_loops()
	slime_tween.set_trans(Tween.TRANS_SINE)
	slime_tween.set_ease(Tween.EASE_IN_OUT)

	slime_tween.tween_method(
		_set_slime_factor,
		Vector2.ONE,
		Vector2(1.06, 0.96),
		0.16
	)

	slime_tween.tween_method(
		_set_slime_factor,
		Vector2(1.06, 0.96),
		Vector2.ONE,
		0.16
	)


# =====================================
# RECUPERAR FORMA NORMAL
# =====================================

func slime_idle_animation() -> void:
	if slime_state == "idle":
		return

	stop_slime_animation()

	slime_state = "idle"

	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_SINE)
	slime_tween.set_ease(Tween.EASE_OUT)

	slime_tween.tween_method(
		_set_slime_factor,
		slime_factor,
		Vector2.ONE,
		0.16
	)


# =====================================
# MOVIMIENTO PRINCIPAL
# =====================================

func _physics_process(delta: float) -> void:

	var was_on_floor = is_on_floor()

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * gravity_direction * delta

	# Inversion de gravedad
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():

		gravity_direction *= -1

		up_direction = Vector2(0, -gravity_direction)

		# Voltear el sprite sin alterar su escala.
		slime_visual.flip_v = gravity_direction < 0

		# Activar animacion de estiramiento.
		slime_jump_animation()

	# Movimiento horizontal A y D
	var direction := Input.get_axis("move_A", "move_D")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Aplicar movimiento
	move_and_slide()

	# =================================
	# DETECCION DE ATERRIZAJE
	# =================================

	if not was_on_floor and is_on_floor():

		slime_land_animation()

	# =================================
	# ANIMACIONES EN EL SUELO
	# =================================

	elif is_on_floor() and slime_state != "landing":

		if abs(velocity.x) > 20:
			slime_walk_animation()
		else:
			slime_idle_animation()

	# =================================
	# ANIMACION DE CAIDA
	# =================================

	elif not is_on_floor() and velocity.y * gravity_direction > 40:

		if slime_state != "fall":
			slime_fall_animation()
