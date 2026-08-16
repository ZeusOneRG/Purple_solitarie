extends Control

# Ruta hacia la escena del menú principal (asegúrate de que coincida con tu carpeta)
const MENU_PRINCIPAL_SCENE = "res://scenes/main_menu.tscn"

@onready var splash_timer: Timer = $SplashTimer

func _ready() -> void:
	# Conectamos el final del temporizador con nuestra función de cambio de escena
	splash_timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	# Pasados los 3 segundos, saltamos automáticamente al Menú Principal
	get_tree().change_scene_to_file(MENU_PRINCIPAL_SCENE)
