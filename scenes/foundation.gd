extends Control

var palo_assigned: String = ""

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data == null or not (data is Array) or data.is_empty(): 
		return false
		
	if data.size() > 1:
		return false
		
	# CORRECCIÓN DE RAÍZ: Sacamos la carta real usando [0]
	var carta_arrastrada = data[0]
	if not carta_arrastrada.has_method("configurar_carta"):
		return false
	
	var cartas_en_base: Array = []
	for hijo in get_children():
		if hijo.has_method("configurar_carta"):
			cartas_en_base.append(hijo)
	
	if cartas_en_base.is_empty():
		return carta_arrastrada.valor == "A"
	
	var ultima_carta = cartas_en_base[-1]
	
	var mismo_palo = carta_arrastrada.palo == ultima_carta.palo
	var orden_ascendente = _obtener_valor_numerico(carta_arrastrada.valor) == _obtener_valor_numerico(ultima_carta.valor) + 1
	
	return mismo_palo and orden_ascendente

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var paquete_cartas = data as Array
	if paquete_cartas.is_empty(): return
	
	# CORRECCIÓN DE RAÍZ: Sacamos la carta real usando [0]
	var carta_arrastrada = paquete_cartas[0]
	var columna_origen = carta_arrastrada.get_parent()
	
	if columna_origen == self: 
		return
	
	var cartas_reales_cuenta = 0
	for hijo in get_children():
		if hijo.has_method("configurar_carta"):
			cartas_reales_cuenta += 1
	
	if cartas_reales_cuenta == 0:
		palo_assigned = carta_arrastrada.palo
	
	var tablero = null
	if columna_origen != null and columna_origen.name == "Discard_zone":
		tablero = columna_origen.get_parent().get_parent().get_parent().get_parent()
		if tablero != null and "pozo_descarte" in tablero:
			tablero.pozo_descarte.erase(carta_arrastrada)
	
	if carta_arrastrada.get_parent() != null:
		carta_arrastrada.get_parent().remove_child(carta_arrastrada)
		
	add_child(carta_arrastrada)
	carta_arrastrada.position = Vector2.ZERO
	move_child(carta_arrastrada, -1)
	
	if columna_origen != null and columna_origen.get_child_count() > 0:
		var ultima_origen = columna_origen.get_children()[-1]
		if not ultima_origen.boca_arriba:
			ultima_origen.voltear(true)
			
		if columna_origen.has_method("reacomodar_cartas"):
			columna_origen.reacomodar_cartas()
			
	if tablero == null:
		tablero = get_parent().get_parent().get_parent().get_parent()
		
	if tablero != null and tablero.has_method("verificar_estado_juego"):
		tablero.verificar_estado_juego()

func _obtener_valor_numerico(val: String) -> int:
	match val:
		"A": return 1
		"J": return 11
		"Q": return 12
		"K": return 13
		_: return val.to_int()
