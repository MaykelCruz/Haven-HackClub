extends CanvasLayer

const VIDA_MAXIMA: int = 3

@export_group("Preview")
@export var mostrar_poderes_en_preview: bool = true

@export_group("Texturas de Vida")
@export var tex_vida_llena: Texture2D
@export var tex_vida_vacia: Texture2D

@export_group("Texturas de Poderes")
@export var tex_bloqueado: Texture2D
@export var tex_pulso: Texture2D
@export var tex_dash: Texture2D
@export var tex_conduccion: Texture2D

@export_group("Texturas de Audio")
@export var tex_audio_on: Texture2D
@export var tex_audio_off: Texture2D

@onready var vidas_nodos: Array[TextureRect] = [
	$MarginContainer/TopBar/LeftCluster/LeftSection/BarraVida/Vida1,
	$MarginContainer/TopBar/LeftCluster/LeftSection/BarraVida/Vida2,
	$MarginContainer/TopBar/LeftCluster/LeftSection/BarraVida/Vida3,
]
@onready var slot_pulso: TextureRect = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Pulso/SlotPulso
@onready var slot_dash: TextureRect = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Dash/SlotDash
@onready var slot_conduccion: TextureRect = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Conduccion/SlotConduccion
@onready var label_muertes: Label = $MarginContainer/TopBar/RightSection/DeathCounter/Content/LabelMuertes
@onready var btn_reiniciar: TextureButton = $MarginContainer/TopBar/RightSection/QuickButtons/BtnReiniciar
@onready var btn_pausa: TextureButton = $MarginContainer/TopBar/RightSection/QuickButtons/BtnPausa
@onready var btn_audio: TextureButton = $MarginContainer/TopBar/RightSection/QuickButtons/BtnAudio

var vida_actual: int = VIDA_MAXIMA
var muertes: int = 0
var silenciado: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Evita que los botones roben el foco de la barra espaciadora (Space)
	btn_reiniciar.focus_mode = Control.FOCUS_NONE
	btn_pausa.focus_mode = Control.FOCUS_NONE
	btn_audio.focus_mode = Control.FOCUS_NONE
	actualizar_vida(vida_actual)
	actualizar_muertes(muertes)
	if mostrar_poderes_en_preview:
		desbloquear_poder("pulso")
		desbloquear_poder("dash")
		desbloquear_poder("conduccion")
	else:
		bloquear_todo()


func actualizar_vida(cantidad: int) -> void:
	vida_actual = clampi(cantidad, 0, VIDA_MAXIMA)
	for i in range(vidas_nodos.size()):
		vidas_nodos[i].texture = tex_vida_llena if i < vida_actual else tex_vida_vacia


func recibir_golpe() -> void:
	actualizar_vida(vida_actual - 1)
	if vida_actual <= 0:
		sumar_muerte()
		actualizar_vida(VIDA_MAXIMA)


func actualizar_muertes(cantidad: int) -> void:
	muertes = cantidad
	label_muertes.text = "x %02d" % muertes


func sumar_muerte() -> void:
	actualizar_muertes(muertes + 1)


func bloquear_todo() -> void:
	slot_pulso.texture = tex_bloqueado
	slot_dash.texture = tex_bloqueado
	slot_conduccion.texture = tex_bloqueado


func desbloquear_poder(nombre: String) -> void:
	match nombre:
		"pulso":
			slot_pulso.texture = tex_pulso
		"dash":
			slot_dash.texture = tex_dash
		"conduccion":
			slot_conduccion.texture = tex_conduccion


func _on_btn_reiniciar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_btn_pausa_pressed() -> void:
	get_tree().paused = not get_tree().paused


func _on_btn_audio_pressed() -> void:
	silenciado = not silenciado
	AudioServer.set_bus_mute(0, silenciado)
	btn_audio.texture_normal = tex_audio_off if silenciado else tex_audio_on
