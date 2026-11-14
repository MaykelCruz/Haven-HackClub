extends Control

func _ready() -> void:
	# Buscamos el botón de forma automática y conectamos su señal "pressed" por código
	# (Cambia "$Button" por la ruta exacta si tu botón está dentro de otro contenedor, ej: "$CenterContainer/Button")
	var boton_jugar = $CenterContainer/Button # Ajusta esta ruta según tu árbol de nodos
	
	if boton_jugar:
		boton_jugar.pressed.connect(_on_jugar_pressed)

# Esta es la función que se ejecutará al hacer clic
func _on_jugar_pressed() -> void:
	# Cambia "res://Main.tscn" por la ruta de tu escena del nivel principal del juego
	get_tree().change_scene_to_file("res://character/mob.tscn")
