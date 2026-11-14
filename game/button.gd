extends Control

# Esta función se ejecuta automáticamente al hacer clic en el botón Jugar
func _on_button_pressed() -> void:
	# Cambia "res://main.tscn" por la ruta exacta de tu escena principal del nivel
	get_tree().change_scene_to_file("res://main.tscn")
