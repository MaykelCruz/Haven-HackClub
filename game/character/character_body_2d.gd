extends CharacterBody2D

const SPEED = 360.0
const DASH_SPEED = 920.0
const DASH_DURATION = 0.18

const COOLDOWN_PULSO = 8.0
const COOLDOWN_DASH = 4.5
const COOLDOWN_DESCARGA = 6.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity_direction = 1
var facing_dir: float = 1.0

var invulnerable_timer: float = 0.0
var dash_timer: float = 0.0
var cd_pulso: float = 0.0
var cd_dash: float = 0.0
var cd_descarga: float = 0.0

# Configuracion visual del slime (animacion squash & stretch)
@onready var collision_node: CollisionShape2D = $CollisionShape2D
@onready var slime_visual: Sprite2D = $CollisionShape2D/SorrySlime
@onready var hud: Node = get_node_or_null("../HUD")

var slime_tween: Tween
var slime_state: String = "idle"
var slime_base_scale: Vector2
var slime_base_position: Vector2
var slime_half_height: float
var slime_factor: Vector2 = Vector2.ONE


func _ready() -> void:
	setup_slime_animation()


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


func slime_jump_animation() -> void:
	stop_slime_animation()
	slime_state = "air"
	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_BACK)
	slime_tween.set_ease(Tween.EASE_OUT)
	slime_tween.tween_method(_set_slime_factor, slime_factor, Vector2(0.88, 1.16), 0.12)
	slime_tween.tween_method(_set_slime_factor, Vector2(0.88, 1.16), Vector2(0.96, 1.06), 0.12)


func slime_fall_animation() -> void:
	stop_slime_animation()
	slime_state = "fall"
	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_SINE)
	slime_tween.set_ease(Tween.EASE_OUT)
	slime_tween.tween_method(_set_slime_factor, slime_factor, Vector2(0.94, 1.10), 0.18)


func slime_land_animation() -> void:
	stop_slime_animation()
	slime_state = "landing"
	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_BACK)
	slime_tween.set_ease(Tween.EASE_OUT)
	slime_tween.tween_method(_set_slime_factor, slime_factor, Vector2(1.20, 0.78), 0.09)
	slime_tween.tween_method(_set_slime_factor, Vector2(1.20, 0.78), Vector2(0.92, 1.08), 0.12)
	slime_tween.tween_method(_set_slime_factor, Vector2(0.92, 1.08), Vector2.ONE, 0.12)
	slime_tween.tween_callback(func():
		slime_state = "idle"
	)


func slime_walk_animation() -> void:
	if slime_state == "walk":
		return
	stop_slime_animation()
	slime_state = "walk"
	_set_slime_factor(Vector2.ONE)
	slime_tween = create_tween().set_loops()
	slime_tween.set_trans(Tween.TRANS_SINE)
	slime_tween.set_ease(Tween.EASE_IN_OUT)
	slime_tween.tween_method(_set_slime_factor, Vector2.ONE, Vector2(1.06, 0.96), 0.16)
	slime_tween.tween_method(_set_slime_factor, Vector2(1.06, 0.96), Vector2.ONE, 0.16)


func slime_idle_animation() -> void:
	if slime_state == "idle":
		return
	stop_slime_animation()
	slime_state = "idle"
	slime_tween = create_tween()
	slime_tween.set_trans(Tween.TRANS_SINE)
	slime_tween.set_ease(Tween.EASE_OUT)
	slime_tween.tween_method(_set_slime_factor, slime_factor, Vector2.ONE, 0.16)


func _physics_process(delta: float) -> void:
	invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	cd_pulso = maxf(0.0, cd_pulso - delta)
	cd_dash = maxf(0.0, cd_dash - delta)
	cd_descarga = maxf(0.0, cd_descarga - delta)
	if hud and hud.has_method("actualizar_cooldowns"):
		hud.actualizar_cooldowns(cd_pulso, cd_dash, cd_descarga)

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = Vector2(facing_dir * DASH_SPEED, 0.0)
		_destruir_enemigos_cerca(90.0)
		move_and_slide()
		return

	var was_on_floor := is_on_floor()

	if not is_on_floor():
		velocity.y += gravity * gravity_direction * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		gravity_direction *= -1
		up_direction = Vector2(0, -gravity_direction)
		slime_visual.flip_v = gravity_direction < 0
		slime_jump_animation()

	var direction := Input.get_axis("move_A", "move_D")
	if direction != 0.0:
		facing_dir = signf(direction)
		slime_visual.flip_h = facing_dir < 0
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if not was_on_floor and is_on_floor():
		slime_land_animation()
	elif is_on_floor() and slime_state != "landing":
		if absf(velocity.x) > 20.0:
			slime_walk_animation()
		else:
			slime_idle_animation()
	elif not is_on_floor() and velocity.y * gravity_direction > 40.0:
		if slime_state != "fall":
			slime_fall_animation()


func get_slime_center() -> Vector2:
	return collision_node.global_position if is_instance_valid(collision_node) else global_position


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				if cd_pulso <= 0.0:
					_usar_pulso()
			KEY_E:
				if cd_dash <= 0.0:
					_usar_dash()
			KEY_SHIFT:
				if cd_descarga <= 0.0:
					_usar_descarga()


func _usar_pulso() -> void:
	cd_pulso = COOLDOWN_PULSO
	if hud and hud.has_method("curar_vida"):
		hud.curar_vida(1)
	_destruir_enemigos_cerca(260.0)
	_mostrar_efecto_rect(Vector2(-180, -180), Vector2(360, 360), Color(0.36, 0.88, 0.90, 0.50), 0.22)


func _usar_dash() -> void:
	cd_dash = COOLDOWN_DASH
	dash_timer = DASH_DURATION
	var offset_x := -100.0 if facing_dir > 0 else 20.0
	_mostrar_efecto_rect(Vector2(offset_x, -36), Vector2(90, 72), Color(0.29, 0.43, 0.96, 0.65), 0.20)


func _usar_descarga() -> void:
	cd_descarga = COOLDOWN_DESCARGA
	var alcance := 440.0
	var centro := get_slime_center()
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if not is_instance_valid(enemigo):
			continue
		var dx: float = (enemigo.global_position.x - centro.x) * facing_dir
		var dy: float = absf(enemigo.global_position.y - centro.y)
		if dx >= -30.0 and dx <= alcance and dy <= 140.0:
			if enemigo.has_method("morir"):
				enemigo.morir()
	var offset_x := 0.0 if facing_dir > 0 else -alcance
	_mostrar_efecto_rect(Vector2(offset_x, -40), Vector2(alcance, 80), Color(0.62, 0.30, 0.87, 0.65), 0.25)


func _destruir_enemigos_cerca(radio: float) -> void:
	var centro := get_slime_center()
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if is_instance_valid(enemigo) and enemigo.global_position.distance_to(centro) <= radio:
			if enemigo.has_method("morir"):
				enemigo.morir()


func _mostrar_efecto_rect(offset: Vector2, tam: Vector2, color: Color, duracion: float) -> void:
	var fx := ColorRect.new()
	fx.color = color
	fx.position = get_slime_center() + offset
	fx.size = tam
	fx.z_index = 10
	get_parent().add_child(fx)
	var tw := create_tween()
	tw.tween_property(fx, "modulate:a", 0.0, duracion)
	tw.tween_callback(fx.queue_free)


func recibir_golpe() -> void:
	if invulnerable_timer > 0.0:
		return
	invulnerable_timer = 1.0
	if hud and hud.has_method("recibir_golpe"):
		hud.recibir_golpe()
	var tw := create_tween()
	tw.tween_property(slime_visual, "modulate", Color(1.0, 0.35, 0.35, 0.6), 0.1)
	tw.tween_property(slime_visual, "modulate", Color.WHITE, 0.15)
