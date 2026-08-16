extends TextureButton

# El color base (normal) y el color brillante (cuando el mouse está encima)
@export var normal_color: Color = Color(1, 1, 1, 1)
@export var hover_color: Color = Color(1.5, 1.2, 1.8, 1) # Valores > 1.0 para HDR/Glow si usas WorldEnvironment

func _ready() -> void:
	# Inicializamos el color del botón
	modulate = normal_color
	
	# Conectamos las señales nativas del botón para detectar el mouse de forma limpia
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	# Transición suave hacia el brillo en 0.15 segundos
	var tween = create_tween()
	tween.tween_property(self, "modulate", hover_color, 0.15).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	# Transición suave de vuelta al color original
	var tween = create_tween()
	tween.tween_property(self, "modulate", normal_color, 0.15).set_trans(Tween.TRANS_SINE)
