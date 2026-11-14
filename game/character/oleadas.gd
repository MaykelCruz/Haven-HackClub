extends Node

const RONDA_MAX: int = 10

@export var escena_enemigo: PackedScene = preload("res://character/enemigo.tscn")
@export var jugador_path: NodePath = NodePath("../CharacterBody2D")
@export var hud_path: NodePath = NodePath("../HUD")

var ronda_actual: int = 0
var enemigos_vivos: int = 0
var esperando_ronda: bool = false

@onready var jugador: Node2D = get_node_or_null(jugador_path)
@onready var hud: Node = get_node_or_null(hud_path)


func _ready() -> void:
	await get_tree().process_frame
	iniciar_siguiente_ronda()


func iniciar_siguiente_ronda() -> void:
	if ronda_actual >= RONDA_MAX:
		if hud and hud.has_method("mostrar_victoria"):
			hud.mostrar_victoria()
		return

	ronda_actual += 1
	esperando_ronda = false
	var cantidad := 2 + ronda_actual
	enemigos_vivos = cantidad
	_actualizar_hud()

	for i in range(cantidad):
		_generar_enemigo(i)


func _generar_enemigo(indice: int) -> void:
	if not escena_enemigo or not is_instance_valid(jugador):
		return
	var enemigo := escena_enemigo.instantiate()
	var lado := -1.0 if (indice % 2 == 0) else 1.0
	var distancia := 450.0 + float(indice * 80)
	var jugador_x: float = jugador.get_slime_center().x if jugador.has_method("get_slime_center") else jugador.global_position.x
	var spawn_x := clampf(jugador_x + lado * distancia, -380.0, 1480.0)
	var en_techo := (indice % 3 == 1)
	var spawn_y := 60.0 if en_techo else 530.0

	enemigo.global_position = Vector2(spawn_x, spawn_y)
	enemigo.objetivo = jugador
	if enemigo.has_method("set"):
		enemigo.velocidad = 135.0 + float(ronda_actual * 12)
	enemigo.eliminado.connect(_on_enemigo_eliminado)
	get_parent().call_deferred("add_child", enemigo)


func _on_enemigo_eliminado() -> void:
	enemigos_vivos = maxi(0, enemigos_vivos - 1)
	_actualizar_hud()
	if enemigos_vivos == 0 and not esperando_ronda:
		esperando_ronda = true
		if ronda_actual >= RONDA_MAX:
			if hud and hud.has_method("mostrar_victoria"):
				hud.mostrar_victoria()
		else:
			await get_tree().create_timer(1.5).timeout
			if is_inside_tree():
				iniciar_siguiente_ronda()


func _actualizar_hud() -> void:
	if hud and hud.has_method("actualizar_ronda"):
		hud.actualizar_ronda(ronda_actual, RONDA_MAX, enemigos_vivos)
