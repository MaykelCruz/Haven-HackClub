extends Area2D

signal eliminado

@export var velocidad: float = 150.0

var objetivo: Node2D
var tiempo: float = 0.0
var base_y: float = 0.0
var vivo: bool = true


func _ready() -> void:
	add_to_group("enemigos")
	base_y = global_position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not vivo or not is_instance_valid(objetivo):
		return
	tiempo += delta
	var pos_obj: Vector2 = objetivo.get_slime_center() if objetivo.has_method("get_slime_center") else objetivo.global_position
	var dir_x := signf(pos_obj.x - global_position.x)
	global_position.x += dir_x * velocidad * delta
	global_position.y = base_y + sin(tiempo * 5.0) * 10.0


func _on_body_entered(body: Node) -> void:
	if not vivo:
		return
	if body.has_method("recibir_golpe"):
		var pos_body: Vector2 = body.get_slime_center() if body.has_method("get_slime_center") else body.global_position
		var empujon := signf(global_position.x - pos_body.x)
		if empujon == 0.0:
			empujon = 1.0
		body.recibir_golpe()
		global_position.x += empujon * 90.0


func morir() -> void:
	if not vivo:
		return
	vivo = false
	emit_signal("eliminado")
	queue_free()
