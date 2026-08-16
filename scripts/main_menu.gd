extends Control

# Ruta a la escena de tu juego/tablero
const TABLERO_SCENE = "res://scenes/tablero.tscn"

# Apuntamos exactamente a los nombres de tu árbol de nodos
@onready var btn_nuevo_juego: TextureButton = $TextureRect/VBoxContainer/TextureButton1
@onready var btn_salir: TextureButton = $TextureRect/VBoxContainer/TextureButton3


func _ready() -> void:
	# Conectamos las señales por código de forma limpia y segura
	btn_nuevo_juego.pressed.connect(_on_nuevo_juego_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)

func _on_nuevo_juego_pressed() -> void:
	# Cambia a la escena del tablero
	get_tree().change_scene_to_file(TABLERO_SCENE)

func _on_salir_pressed() -> void:
	# Cierra el juego por completo
	get_tree().quit()
