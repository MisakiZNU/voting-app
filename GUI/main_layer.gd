extends Control

@onready var rows_input = $InputForBuild/HBoxContainer2/RowsInput
@onready var colums_input = $InputForBuild/HBoxContainer/ColumsInput
@onready var matrix_container = $ScrollContainer/GridContainer
@onready var res_popup = $Task1PopUp
@onready var order_popup = $Task3PopUp

var is_matrix_exist: bool = false
#for task 3
var candidate_order_buttons: Array = []

func validate_matrix_input() -> bool:
	var rows = int(rows_input.text)
	var cols = int(colums_input.text)
	var idx = 0
	
	for i in range(rows + 2):
		for j in range(cols):
			var child = matrix_container.get_child(idx)
			
			if child is LineEdit:
				var text = child.text.strip_edges()
				
				if i == 1:
					if text == "" or not text.is_valid_int():
						res_popup.dialog_text = "❌ Помилка: У другому рядку повинні бути тільки цілі числа !"
						res_popup.popup_centered()
						return false
				elif (i > 1):
					if text == "" or not text.is_valid_identifier():
						res_popup.dialog_text = "❌ Помилка:  У наступних рядках має бути лише 1 символ !"
						res_popup.popup_centered()
						return false
			idx = idx + 1
	return true
	
	
func _on_generate_table_pressed() -> void:
	
	if is_matrix_exist:
		res_popup.dialog_text = "Помилка: Щоб створити нову матрицю, видаліть попередню!"
		return
		
	var rows = int(rows_input.text) + 1
	var cols = int(colums_input.text)
	
	if rows < 2 or cols <= 1:
		return
		 
	matrix_container.columns = cols
	
	for i in rows+1:
		for j in cols:
			if i == 0:
				var label = Label.new()
				label.text = str(j+1)
				matrix_container.add_child(label)
			else:
				var input = LineEdit.new()
				input.placeholder_text = "%d,%d" % [i, j]
				
				if i == 1:
					input.placeholder_text = "num"
				else: 
					input.placeholder_text = "char"
				
				matrix_container.add_child(input)
	is_matrix_exist = true

func general_voting(target_a,target_b) -> Dictionary:
	var vote_dict = {
		target_a: 0,
		target_b: 0
	}
	var rows = int(rows_input.text)
	var cols = int(colums_input.text)
	var inputs = matrix_container.get_children()
	var n = 0
	for j in range(cols):
		var index_a := -1
		var index_b := -1

		for i in range(rows):
			var index = (i + 2) * cols + j
			var candidate = inputs[index].text.strip_edges()
			if candidate == target_a and index_a == -1:
				index_a = i
			elif candidate == target_b and index_b == -1:
				index_b = i
		
		var winner := ""
		if index_a != -1 and (index_b == -1 or index_a < index_b):
			winner = target_a
		elif index_b != -1 and (index_a == -1 or index_b < index_a):
			winner = target_b
		
		if winner != "":
			var weight_index = cols * 1 + j
			var votes = int(inputs[weight_index].text.strip_edges())
			vote_dict[winner] += votes
	return vote_dict

func get_vote_dict_from_inputs() -> Dictionary:
	var vote_dict = {}
	var cols = int(colums_input.text)
	
	var inputs = matrix_container.get_children()
	
	if inputs.is_empty():
		return vote_dict
		
	for j in range(cols):
		var num_node_index = cols * 1 + j
		var char_node_index = cols * 2 + j
	
		var num_node = inputs[num_node_index]
		var char_node = inputs[char_node_index]
		
		var value_text = num_node.text.strip_edges()
		var char_text =  char_node.text.strip_edges()
		var votes = int(value_text)
		
		if vote_dict.has(char_text):
			vote_dict[char_text] += votes
		else:
			vote_dict[char_text] = votes
		
	return vote_dict
	
func _on_relative_majority_rule_button_pressed() -> void:
	if not validate_matrix_input():
		return
	
	var vote_dict = get_vote_dict_from_inputs()
	
	if vote_dict.is_empty():
		res_popup.dialog_text = "Помилка: Створіть нову матрицю голосування"
		res_popup.popup_centered()
		return
		
	var max_votes = -1
	var winners = []
	
	for key in vote_dict:
		if vote_dict[key] > max_votes:
			max_votes = vote_dict[key]
			winners = [key]
		elif vote_dict[key] == max_votes:
			winners.append(key)
	
	var result_text = "Результати голосування:\n\n"
	for key in vote_dict:
		result_text += "%s → %d голосів\n" % [key, vote_dict[key]]
	
	if winners.size() == 1:
		result_text += "\n🏆 Переможець: %s" % winners[0]
	else:
		result_text += "\n🤝 Нічия між: '%s'" % ", ".join(winners)
	
	res_popup.dialog_text = result_text
	res_popup.popup_centered()

func _on_relative_majority_rule_with_elimination_button_pressed() -> void:
	if not validate_matrix_input():
		return
		
	var vote_dict = get_vote_dict_from_inputs()
		
	var sorted_candidates = vote_dict.keys()
	sorted_candidates.sort_custom(func(a, b): return vote_dict[a] > vote_dict[b])
		
	var winner = sorted_candidates[0] if sorted_candidates.size() > 0 else ""
	var runner_up = sorted_candidates[1] if sorted_candidates.size() > 1 else ""
	
	var result_text = "Результати голосування першого туру:\n\n"
	for key in vote_dict:
		result_text += "%s → %d голосів\n" % [key, vote_dict[key]]
	result_text += "\n🏆 Переможець першого туру: %s\n" % winner
	result_text += "🥈 Друге місце: %s\n" % runner_up
	
	var second_tour = general_voting(winner,runner_up)
	var second_tour_winner = second_tour.keys().max()
	
	var second_tour_winner_votes = second_tour[second_tour_winner]
	var second_tour_loser = winner if second_tour_winner == runner_up else runner_up
	var second_tour_loser_votes = second_tour[second_tour_loser]
	
	result_text += "\n🏆 Переможець другого туру: %s\n" % second_tour_winner
	result_text += "\n %s виборців вважає, що кандидат '%s' краще за '%s', а %s виборців підтримують '%s'." % [
	second_tour_winner_votes, second_tour_winner, second_tour_loser, second_tour_loser_votes, second_tour_loser]
	res_popup.dialog_text = result_text
	res_popup.popup_centered()

func _on_sequential_exclusion_voting_button_pressed() -> void:
	if not validate_matrix_input():
		return
		
	var rows = int(rows_input.text)
	var cols = int(colums_input.text)

	var inputs = matrix_container.get_children()
	var candidates_set:= {}
	var n = 0
	for i in range(rows):
		for j in range(cols):
			var index = cols * 2 + n
			n = n + 1
			var text = inputs[index].text.strip_edges()
			if text != "":
				candidates_set[text] = true
	
	var unique_candidates := candidates_set.keys()
	create_order_selection(unique_candidates)

func create_order_selection(candidates: Array) -> void:
	for child in order_popup.get_children():
		order_popup.remove_child(child)
		child.queue_free()
		
	var order_container = HBoxContainer.new()
	
	candidate_order_buttons.clear()
	
	for i in range(candidates.size()):
		var option = OptionButton.new()
		for candidate in candidates:
			option.add_item(candidate)
		order_container.add_child(option)
		candidate_order_buttons.append(option)
		
		order_popup.add_child(order_container)
		order_popup.popup_centered()

func _on_delete_table_button_pressed() -> void:
	for child in matrix_container.get_children():
		child.queue_free()
		candidate_order_buttons.clear()
	is_matrix_exist = false

func _on_condorcet_voting_rule_button_pressed() -> void:
	if not validate_matrix_input():
		return
	
	var rows = int(rows_input.text)
	var cols = int(colums_input.text)
	var inputs = matrix_container.get_children()
	var result_text = "Порівняння кандидатів:\n\n"
	var candidates_set := {}
	var n = 0
	
	for i in range(rows):
		for j in range(cols):
			var index = cols * 2 + n
			n += 1
			var text = inputs[index].text.strip_edges()
			if text != "":
				candidates_set[text] = true
	var candidates := candidates_set.keys()
	
	for candidate in candidates:
		var won_all = true
		for opponent in candidates:
			if opponent == candidate:
				continue
			var result = general_voting(candidate, opponent)
			var votes_cand = result.get(candidate, 0)
			var votes_opp = result.get(opponent, 0)
			if votes_cand > votes_opp:
				result_text += "✅ %s перемагає %s (%d : %d)\n" % [candidate, opponent, votes_cand, votes_opp]
			elif votes_opp > votes_cand:
				result_text += "❌ %s програє %s (%d : %d)\n" % [candidate, opponent, votes_cand, votes_opp]
				won_all = false
				break
			else:
				result_text += "⚖️ %s та %s — нічия (%d : %d)\n" % [candidate, opponent, votes_cand, votes_opp]
				won_all = false
				break
		if won_all:
			result_text += "\n👑 %s перемагає всіх суперників — переможець за правилом Кондорсе!\n" % candidate
			res_popup.dialog_text = result_text
			res_popup.popup_centered()
			return
	result_text = "\n❌ Жоден кандидат не переміг усіх — немає переможця за правилом Кондорсе"
	res_popup.dialog_text = result_text
	res_popup.popup_centered()
	
func _on_board_voting_rule_button_pressed() -> void:
	if not validate_matrix_input():
		return
	var result_text = "Розрахунок вагових голосів:\n\n"
	
	var vote_dict = {}
	var vote_steps = {}
	var rows = int(rows_input.text)
	var cols = int(colums_input.text)
	var n = 0 
	
	var inputs = matrix_container.get_children()
	for i in range(rows):
		for j in range(cols):
			var num_node_index = cols * 1 + j
			var char_node_index = cols * 2 + n
			n = n + 1
			var num_node = inputs[num_node_index]
			var char_node = inputs[char_node_index]
		
			var value_text = num_node.text.strip_edges()
			var char_text = char_node.text.strip_edges()
			var votes = int(value_text)
			
			var position_coefficient = (rows - 1 -  i)
			var weighted_votes = votes * position_coefficient
			if vote_dict.has(char_text):
				vote_dict[char_text] += weighted_votes
				vote_steps[char_text].append("%d×%d" % [votes, position_coefficient])
			else:
				vote_dict[char_text] = weighted_votes
				vote_steps[char_text] = ["%d×%d" % [votes, position_coefficient]]
				
	result_text += "📊 Розподіл балів за місцем:\n"
	for i in range(rows):
		var coef = rows - 1 - i
		result_text += "Місце %d → %d балів\n" % [i + 1, coef]
	result_text += "\n"
	for key in vote_dict:
		var formula = String(" + ").join(vote_steps[key])
		var total = vote_dict[key]
		result_text += "👤 %s: %s = %d балів\n" % [key, formula, total]	
	var max_votes = -1
	var winner = ""
	for key in vote_dict:
		if vote_dict[key] > max_votes:
			max_votes = vote_dict[key]
			winner = key
	result_text += "\n🏆 Переможець: %s з %d балами" % [winner, max_votes]
	res_popup.dialog_text = result_text
	res_popup.popup_centered()
	
func _on_task_3_pop_up_confirmed() -> void:
	var order: Array = []
	for btn in candidate_order_buttons:
		if btn.selected == -1:
			res_popup.dialog_text = "Всі позиції мають бути зайняті"
			res_popup.popup_centered()
			return
		var name = btn.get_item_text(btn.selected)
		if name in order:
			res_popup.dialog_text = "⚠️ Кожен кандидат має бути лише один раз!"
			res_popup.popup_centered()
			return
		order.append(name)
		
	var current_winner = order[0]
	var result_text = "📊 Порівняння кандидатів:\n\n"
	
	for i in range(1, order.size()):
		var next_candidate = order[i]
		var result = general_voting(current_winner, next_candidate)
		var votes_for_current = result[current_winner]
		var votes_for_next = result[next_candidate]
		var total_votes = votes_for_current + votes_for_next
		
		if votes_for_current > votes_for_next:
			result_text += "%d з %d виборців вважають, що кандидат %s кращий за %s\n" % [votes_for_current, total_votes, current_winner, next_candidate]
		elif votes_for_next > votes_for_current:
			result_text += "%d з %d виборців вважають, що кандидат %s кращий за %s\n" % [votes_for_next, total_votes, next_candidate, current_winner]
		else:
			result_text += "⚖️ Нічия між %s та %s (%d з %d)\n" % [current_winner, next_candidate, votes_for_current, total_votes]
		
		if votes_for_current >= votes_for_next:
			current_winner = current_winner
		else:
			current_winner = next_candidate
		
	result_text += "\n🎯 Переможець методом послідовного винятку: %s" % current_winner
	
	res_popup.dialog_text = result_text
	res_popup.popup_centered()


func _on_copland_rule_button_pressed() -> void:
	if not validate_matrix_input():
		return
	
	var rows = int(rows_input.text)
	var cols = int(colums_input.text)
	var inputs = matrix_container.get_children()
	var result_text = "Результати за правилом Копленда:\n\n"
	var name_row_index = cols * 2
	var candidates := []
	
	for i in range(rows):
		for j in range(cols):
			var name = inputs[name_row_index].text.strip_edges()
			name_row_index += 1
			if name != "" and not candidates.has(name):
				candidates.append(name)
			print(name_row_index)
		
	var scores := {}
	for name in candidates:
		scores[name] = 0

	for i in range(candidates.size()):
		for j in range(i + 1, candidates.size()):
			var a = candidates[i]
			var b = candidates[j]

			var result := general_voting(a, b)

			var votes_a : int = result.get(a, 0)
			var votes_b : int = result.get(b, 0)

			if votes_a > votes_b:
				scores[a] += 1
				scores[b] -= 1
				result_text += "%s проти %s → %s перемагає (%d проти %d) → +1 бал %s, -1 бал %s\n" % [a, b, a, votes_a, votes_b, a, b]
			elif votes_b > votes_a:
				scores[b] += 1
				scores[a] -= 1
				result_text += "%s проти %s → %s перемагає (%d проти %d) → +1 бал %s, -1 бал %s\n" % [a, b, b, votes_b, votes_a, b, a]
			else:
				result_text += "%s проти %s → Нічия (%d : %d) → Без змін\n" % [a, b, votes_a, votes_b]
				
	var winner = ""
	var max_score = -99999
	
	for cand in scores:
		result_text += "%s → %d балів\n" % [cand, scores[cand]]
		if scores[cand] > max_score:
			max_score = scores[cand]
			winner = cand
			
	result_text += "\n🏆 Переможець: %s" % winner
	
	res_popup.dialog_text = result_text
	res_popup.popup_centered()
