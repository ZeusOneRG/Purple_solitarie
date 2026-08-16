extends Control

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data == null or not (data is Array) or data.is_empty(): 
		return false
		
	# CORRECCIÓN DE RAÍZ: Sacamos la primera carta del arreglo usando [0]
	var primera_carta_arrastrada = data[0]
	if not primera_carta_arrastrada.has_method("configurar_carta"):
		return false
	
	var cartas_en_columna = get_children()
	
	if cartas_en_columna.is_empty():
		return primera_carta_arrastrada.valor == "K"
		
	cartas_en_columna.sort_custom(func(a, b): return a.position.y < b.position.y)
	var ultima_carta = cartas_en_columna[-1]
	
	if not ultima_carta.boca_arriba: 
		return false
	
	var colores_alternos = ultima_carta.color != primera_carta_arrastrada.color
	var orden_correcto = _obtener_valor_numerico(ultima_carta.valor) == _obtener_valor_numerico(primera_carta_arrastrada.valor) + 1
	
	return colores_alternos and orden_correcto

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var paquete_cartas = data as Array
	if paquete_cartas.is_empty(): return
	
	var primera_carta = paquete_cartas[0] # Usamos la primera carta para chequear el origen
	var columna_origen = primera_carta.get_parent()
	if columna_origen == self: return
	
	var tablero = null
	if columna_origen != null and columna_origen.name == "Discard_zone":
		tablero = columna_origen.get_parent().get_parent().get_parent().get_parent()
		if tablero != null and "pozo_descarte" in tablero:
			tablero.pozo_descarte.erase(primera_carta)
	
	var cartas_a_mover = paquete_cartas.duplicate()
	
	for carta in cartas_a_mover:
		if carta.get_parent() != null:
			carta.get_parent().remove_child(carta)
		add_child(carta)
	
	reacomodar_cartas()
	
	if columna_origen != null and columna_origen.get_child_count() > 0:
		var ultima_origen = columna_origen.get_children()[-1]
		if not ultima_origen.boca_arriba:
			ultima_origen.voltear(true)
			
		if columna_origen.has_method("reacomodar_cartas"):
			columna_origen.reacomodar_cartas()
			
	if tablero == null:
		tablero = get_parent().get_parent().get_parent()
		
	if tablero != null and tablero.has_method("verificar_estado_juego"):
		tablero.verificar_estado_juego()

func reacomodar_cartas() -> void:
	var todas_las_cartas = get_children()
	var cantidad = todas_las_cartas.size()
	if cantidad == 0: return
	
	var separacion_dinamica = 30.0
	if cantidad > 6:
		separacion_dinamica = max(14.0, 30.0 - ((cantidad - 6) * 2.0))
	
	for i in range(cantidad):
		todas_las_cartas[i].position = Vector2(0, i * separacion_dinamica)

func _obtener_valor_numerico(val: String) -> int:
	match val:
		"A": return 1
		"J": return 11
		"Q": return 12
		"K": return 13
		_: return val.to_int()
