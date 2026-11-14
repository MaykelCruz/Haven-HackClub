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
@onready var cd_pulso_overlay: ColorRect = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Pulso/SlotPulso/CooldownOverlay
@onready var cd_pulso_label: Label = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Pulso/SlotPulso/CooldownOverlay/LabelCD
@onready var cd_dash_overlay: ColorRect = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Dash/SlotDash/CooldownOverlay
@onready var cd_dash_label: Label = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Dash/SlotDash/CooldownOverlay/LabelCD
@onready var cd_conduccion_overlay: ColorRect = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Conduccion/SlotConduccion/CooldownOverlay
@onready var cd_conduccion_label: Label = $MarginContainer/TopBar/LeftCluster/LeftSection/PowersRow/Conduccion/SlotConduccion/CooldownOverlay/LabelCD
@onready var label_muertes: Label = $MarginContainer/TopBar/RightSection/DeathCounter/Content/LabelMuertes
@onready var btn_reiniciar: TextureButton = $MarginContainer/TopBar/RightSection/QuickButtons/BtnReiniciar
@onready var btn_pausa: TextureButton = $MarginContainer/TopBar/RightSection/QuickButtons/BtnPausa
@onready var btn_audio: TextureButton = $MarginContainer/TopBar/RightSection/QuickButtons/BtnAudio
@onready var menu_pausa: ColorRect = $MenuPausa
@onready var menu_muerte: ColorRect = $MenuMuerte
@onready var label_ronda_muerte: Label = $MenuMuerte/PanelMuerte/MarginContainer/VBoxContainer/SubtituloMuerte
@onready var btn_reintentar_muerte: Button = $MenuMuerte/PanelMuerte/MarginContainer/VBoxContainer/BtnReintentarMuerte
@onready var label_ronda: Label = $MarginContainer/TopBar/RondaBadge/LabelRonda
@onready var btn_continuar: Button = $MenuPausa/PanelPausa/MarginContainer/VBoxContainer/BtnContinuar
@onready var btn_reiniciar_pausa: Button = $MenuPausa/PanelPausa/MarginContainer/VBoxContainer/BtnReiniciarPausa
@onready var btn_audio_pausa: Button = $MenuPausa/PanelPausa/MarginContainer/VBoxContainer/BtnAudioPausa

var vida_actual: int = VIDA_MAXIMA
var ronda_actual: int = 1
var muertes: int = 0
var silenciado: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Evita que los botones roben el foco de la barra espaciadora (Space)
	for btn in [btn_reiniciar, btn_pausa, btn_audio, btn_continuar, btn_reiniciar_pausa, btn_audio_pausa, btn_reintentar_muerte]:
		btn.focus_mode = Control.FOCUS_NONE
	menu_pausa.visible = false
	menu_muerte.visible = false
	actualizar_vida(vida_actual)
	actualizar_muertes(muertes)
	if mostrar_poderes_en_preview:
		desbloquear_poder("pulso")
		desbloquear_poder("dash")
		desbloquear_poder("conduccion")
	else:
		bloquear_todo()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not menu_muerte.visible:
		alternar_pausa()
		get_viewport().set_input_as_handled()


func alternar_pausa() -> void:
	var pausado := not get_tree().paused
	get_tree().paused = pausado
	menu_pausa.visible = pausado


func actualizar_vida(cantidad: int) -> void:
	vida_actual = clampi(cantidad, 0, VIDA_MAXIMA)
	for i in range(vidas_nodos.size()):
		vidas_nodos[i].texture = tex_vida_llena if i < vida_actual else tex_vida_vacia


func curar_vida(cantidad: int = 1) -> void:
	actualizar_vida(vida_actual + cantidad)


func actualizar_cooldowns(cd_q: float, cd_e: float, cd_shift: float) -> void:
	_aplicar_cd(cd_pulso_overlay, cd_pulso_label, cd_q)
	_aplicar_cd(cd_dash_overlay, cd_dash_label, cd_e)
	_aplicar_cd(cd_conduccion_overlay, cd_conduccion_label, cd_shift)


func _aplicar_cd(overlay: ColorRect, lbl: Label, restante: float) -> void:
	if restante > 0.05:
		overlay.visible = true
		lbl.text = "%.1f" % restante
	else:
		overlay.visible = false


func recibir_golpe() -> void:
	actualizar_vida(vida_actual - 1)
	if vida_actual <= 0:
		sumar_muerte()
		mostrar_pantalla_muerte()


func mostrar_pantalla_muerte() -> void:
	label_ronda_muerte.text = "Ronda alcanzada: %d / 10" % ronda_actual
	menu_pausa.visible = false
	menu_muerte.visible = true
	get_tree().paused = true


func actualizar_muertes(cantidad: int) -> void:
	muertes = cantidad
	label_muertes.text = "x %02d" % muertes


func sumar_muerte() -> void:
	actualizar_muertes(muertes + 1)


func actualizar_ronda(ronda: int, total: int, enemigos: int) -> void:
	ronda_actual = ronda
	label_ronda.text = "RONDA %d/%d  |  %d" % [ronda, total, enemigos]


func mostrar_victoria() -> void:
	label_ronda.text = "¡SOBREVIVISTE! 10/10"


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
	menu_pausa.visible = false
	menu_muerte.visible = false
	get_tree().reload_current_scene()


func _on_btn_pausa_pressed() -> void:
	alternar_pausa()


func _on_btn_continuar_pressed() -> void:
	if get_tree().paused:
		alternar_pausa()


func _on_btn_audio_pressed() -> void:
	silenciado = not silenciado
	AudioServer.set_bus_mute(0, silenciado)
	btn_audio.texture_normal = tex_audio_off if silenciado else tex_audio_on
	btn_audio_pausa.text = "Audio: OFF" if silenciado else "Audio: ON"
