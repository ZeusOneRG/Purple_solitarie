extends Control

var escena_carta = preload("res://scenes/card.tscn")
var mazo: Array = []
var pozo_descarte: Array = []

@onready var game_columns: HBoxContainer = $MarginContainer/Main_Layout/Game_Columns
@onready var hand_container: TextureButton = $MarginContainer/Main_Layout/Top_Bar/Deck_Container/Hand_Container
@onready var discard_zone: Control = $MarginContainer/Main_Layout/Top_Bar/Deck_Container/Discard_zone
@onready var foundation_container: HBoxContainer = $MarginContainer/Main_Layout/Top_Bar/Foundation_Container

func _ready() -> void:
	randomize() 
	
	hand_container.pressed.connect(_on_mazo_click)
	
	crear_mazo_completo()
	mezclar_mazo()
	repartir_solitario()
	actualizar_vista_mazo()

func crear_mazo_completo() -> void:
	var palos = ["clubs", "diamonds", "hearts", "spades"]
	var valores = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
	
	for palo in palos:
		for valor in valores:
			var nueva_carta = escena_carta.instantiate()
			add_child(nueva_carta)
			nueva_carta.configurar_carta(palo, valor)
			nueva_carta.doble_click_detectado.connect(_on_carta_doble_click)
			mazo.append(nueva_carta)

func mezclar_mazo() -> void:
	mazo.shuffle()

func repartir_solitario() -> void:
	var columnas = game_columns.get_children()
	
	for i in range(7):
		var columna_actual = columnas[i]
		var cantidad_cartas = i + 1
		
		for j in range(cantidad_cartas):
			if mazo.is_empty(): break
			var carta = mazo.pop_back()
			
			carta.get_parent().remove_child(carta)
			columna_actual.add_child(carta)
			
			if j == cantidad_cartas - 1:
				carta.voltear(true)
			else:
				carta.voltear(false)
		
		if columna_actual.has_method("reacomodar_cartas"):
			columna_actual.reacomodar_cartas()
				
	for carta in mazo:
		carta.visible = false

func _on_mazo_click() -> void:
	if mazo.is_empty():
		var cartas_restantes_en_descarte = discard_zone.get_children()
		if cartas_restantes_en_descarte.is_empty(): 
			pozo_descarte.clear()
			verificar_estado_juego()
			return 
		
		mazo.clear()
		pozo_descarte.clear()
		
		for i in range(cartas_restantes_en_descarte.size() - 1, -1, -1):
			var carta_reciclada = cartas_restantes_en_descarte[i]
			
			if carta_reciclada.get_parent() != null:
				carta_reciclada.get_parent().remove_child(carta_reciclada)
				
			add_child(carta_reciclada)
			carta_reciclada.visible = false
			carta_reciclada.voltear(false)
			mazo.append(carta_reciclada)
			
		actualizar_vista_mazo()
		verificar_estado_juego()
		return

	var carta_robada = mazo.pop_back()
	pozo_descarte.append(carta_robada)
	
	carta_robada.get_parent().remove_child(carta_robada)
	discard_zone.add_child(carta_robada)
	
	carta_robada.visible = true
	carta_robada.voltear(true)
	carta_robada.position = Vector2.ZERO
	discard_zone.move_child(carta_robada, -1)
	
	actualizar_vista_mazo()
	verificar_estado_juego()

func actualizar_vista_mazo() -> void:
	if mazo.is_empty():
		hand_container.modulate.a = 0.2 
	else:
		hand_container.modulate.a = 1.0

func _on_carta_doble_click(carta: Node) -> void:
	var origen = carta.get_parent()
	if origen == null: return
	
	if origen.get_child_count() > 0 and origen.get_children()[-1] != carta:
		return 
		
	var fundaciones = foundation_container.get_children()
	for fundacion in fundaciones:
		if fundacion._can_drop_data(Vector2.ZERO, [carta]):
			if origen.name == "Discard_zone":
				pozo_descarte.erase(carta)
			fundacion._drop_data(Vector2.ZERO, [carta])
			break

# AUDITORÍA DE ESTADO DE JUEGO PREDICTIVA
func verificar_estado_juego() -> void:
	# 1. VERIFICAR VICTORIA
	var total_cartas_fundaciones = 0
	for fundacion in foundation_container.get_children():
		for hijo in fundacion.get_children():
			if hijo.has_method("configurar_carta"):
				total_cartas_fundaciones += 1
				
	if total_cartas_fundaciones == 52:
		print("¡FELICITACIONES! GANASTE EL JUEGO.")
		return

	# 2. VERIFICAR DERROTA PREDICTIVA (Analiza absolutamente todas las cartas disponibles)
	var cartas_candidatas: Array = []
	
	# Evaluamos TODAS las cartas que quedan dentro del mazo oculto
	for carta_oculta in mazo:
		if carta_oculta.has_method("configurar_carta"):
			cartas_candidatas.append(carta_oculta)
			
	# Evaluamos TODAS las cartas que están en el pozo de descarte físico
	for carta_descarte in discard_zone.get_children():
		if carta_descarte.has_method("configurar_carta"):
			cartas_candidatas.append(carta_descarte)
			
	# Evaluamos la última carta física descubierta de cada columna del tablero
	for columna in game_columns.get_children():
		var hijos = columna.get_children()
		hijos.sort_custom(func(a, b): return a.position.y < b.position.y)
		if not hijos.is_empty():
			var ultima_carta = hijos[-1]
			if ultima_carta.has_method("configurar_carta") and ultima_carta.boca_arriba:
				cartas_candidatas.append(ultima_carta)
				
	# Simulamos si existe al menos UN movimiento legal en toda la mesa
	var movimientos_posibles = 0
	var columnas_tablero = game_columns.get_children()
	var fundaciones_tablero = foundation_container.get_children()
	
	for carta in cartas_candidatas:
		for columna in columnas_tablero:
			# Si la carta ya está en esa columna, no cuenta como movimiento nuevo
			if carta.get_parent() == columna: continue
			if columna._can_drop_data(Vector2.ZERO, [carta]):
				movimientos_posibles += 1
				break
		if movimientos_posibles > 0: break
		
		for fundacion in fundaciones_tablero:
			if carta.get_parent() == fundacion: continue
			if fundacion._can_drop_data(Vector2.ZERO, [carta]):
				movimientos_posibles += 1
				break
		if movimientos_posibles > 0: break
				
	# Si tras revisar todo el mazo y el tablero no hay NI UNA jugada útil, el juego está trancado
	if movimientos_posibles == 0:
		print("JUEGO TERMINADO: No quedan movimientos útiles en todo el mazo ni el tablero. PERDISTE.")

func _obtener_valor_numerico(_val: String) -> int:
	return -1
