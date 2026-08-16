extends Control

signal doble_click_detectado(carta_nodo)

var palo: String = "clubs"
var valor: String = "A"
var color: String = "black"
var boca_arriba: bool = false

@onready var visual: TextureRect = $Visual
var dorso_textura = preload("res://assets/cards/back_dark.png")

func _ready() -> void:
	custom_minimum_size = Vector2(121, 170)
	size = Vector2(121, 170)
	
	if visual:
		visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		visual.stretch_mode = TextureRect.STRETCH_SCALE
		visual.custom_minimum_size = Vector2(121, 170)
		visual.size = Vector2(121, 170)
		visual.position = Vector2.ZERO
		
	actualizar_aspecto()

func configurar_carta(nuevo_palo: String, nuevo_valor: String) -> void:
	palo = nuevo_palo
	valor = nuevo_valor
	color = "red" if (palo == "hearts" or palo == "diamonds") else "black"
	actualizar_aspecto()

func actualizar_aspecto() -> void:
	if visual == null: return
	if boca_arriba:
		var ruta_frente = "res://assets/cards/" + palo + "_" + valor + ".png"
		if ResourceLoader.exists(ruta_frente):
			visual.texture = load(ruta_frente)
	else:
		visual.texture = dorso_textura

func voltear(mostrar_frente: bool) -> void:
	boca_arriba = mostrar_frente
	actualizar_aspecto()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.double_click:
			if boca_arriba:
				doble_click_detectado.emit(self)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not boca_arriba: return null
	
	var contenedor_padre = get_parent()
	if contenedor_padre == null: return null
	
	var paquete_cartas: Array = []
	
	if contenedor_padre.name == "Discard_zone":
		paquete_cartas.append(self)
	else:
		# SOLUCIÓN CRÍTICA: Obtenemos los hermanos y los ordenamos por su altura física real en pantalla
		var hermanos = contenedor_padre.get_children()
		hermanos.sort_custom(func(a, b): return a.position.y < b.position.y)
		
		var mi_indice = hermanos.find(self)
		if mi_indice != -1:
			for i in range(mi_indice, hermanos.size()):
				paquete_cartas.append(hermanos[i])
			
		if contenedor_padre.has_method("palo_assigned") and paquete_cartas.size() > 1:
			return null
	
	var c_preview = Control.new()
	
	for i in range(paquete_cartas.size()):
		var carta_original = paquete_cartas[i]
		var preview_individual = TextureRect.new()
		preview_individual.texture = carta_original.visual.texture
		preview_individual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_individual.stretch_mode = TextureRect.STRETCH_SCALE
		preview_individual.custom_minimum_size = Vector2(121, 170)
		preview_individual.size = Vector2(121, 170)
		
		preview_individual.position = Vector2(-121.0 / 2.0, (-170.0 / 2.0) + (i * 30))
		c_preview.add_child(preview_individual)
		
	set_drag_preview(c_preview)
	return paquete_cartas

func _obtener_contenedor_padre() -> Node:
	var actual = get_parent()
	while actual != null:
		if actual.has_method("_can_drop_data") and actual != get_tree().current_scene and actual.name != "Tablero":
			return actual
		actual = actual.get_parent()
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var contenedor = _obtener_contenedor_padre()
	if contenedor != null:
		return contenedor._can_drop_data(at_position, data)
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var contenedor = _obtener_contenedor_padre()
	if contenedor != null:
		contenedor._drop_data(at_position, data)
