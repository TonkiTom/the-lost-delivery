extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var quest_title: Label = $CanvasLayer/QuestTitle
@onready var quest_text: Label = $CanvasLayer/QuestText
@onready var hint: Label = $CanvasLayer/Hint
@onready var status: Label = $CanvasLayer/Status
@onready var gate: Polygon2D = $Gate
@onready var switch_node: Polygon2D = $RuneSwitch

var quest_chain: Array = [
	{
		"title": "Moon Tea for Mira",
		"item": "Moon Tea",
		"recipient": "Mira",
		"kind": "cursed",
		"summary": "Mira says the tea hums at midnight. Someone is trying to curse the streetlight district."
	},
	{
		"title": "The Ledger for Bram",
		"item": "Black Ledger",
		"recipient": "Bram",
		"kind": "valuable",
		"summary": "Bram needs the ledger before the council finds the missing gold page."
	},
	{
		"title": "The Ribbon for Gilda",
		"item": "Moon Ribbon",
		"recipient": "Gilda",
		"kind": "cursed",
		"summary": "Gilda swears the ribbon whispers when the fog gets thick."
	}
]

var current_index: int = 0
var puzzle_solved: bool = false
var hidden_key_found: bool = false
var staircase_unlocked: bool = false
var portal_activated: bool = false
var inventory_panel: CanvasLayer
var inventory_label: Label
var weather_label: Label
var prompt: String = ""

func _ready() -> void:
	$Mira.npc_name = "Mira"
	$Bram.npc_name = "Bram"
	$Gilda.npc_name = "Gilda"
	$OldTobin.npc_name = "OldTobin"
	$Mira.dialogue = "This tea was brewed beneath the north moon. The town is warmer when the rain falls."
	$Bram.dialogue = "If you hear footsteps in the alley, don't answer. It's the ledger talking."
	$Gilda.dialogue = "The ribbon glows if the fog is thick. Keep it from the old stone stairs."
	$OldTobin.dialogue = "If you find a bronze key under the elder's bench, don't leave it behind."
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	WeatherManager.weather_changed.connect(_on_weather_changed)
	WeatherManager.set_weather("rain")
	build_inventory_ui()
	update_quest_ui()
	update_gate_state()
	update_weather_ui()
	update_inventory_ui()
	show_status("The town is soaked in rain. A hidden trail is waiting behind the square.")

func _process(_delta: float) -> void:
	var near_npc = get_nearest_npc()
	var near_switch = player.global_position.distance_to(switch_node.global_position) < 70
	var near_key = player.global_position.distance_to(Vector2(360, 520)) < 45
	var near_stair = player.global_position.distance_to(Vector2(990, 200)) < 65
	var near_portal = player.global_position.distance_to(Vector2(1090, 500)) < 60

	if near_npc != null and player.global_position.distance_to(near_npc.global_position) < 80:
		prompt = "Press E to talk to %s" % near_npc.name
	elif near_switch:
		prompt = "Press E to activate the rune switch"
	elif near_key and not hidden_key_found:
		prompt = "Press E to take the hidden bronze key"
	elif near_stair and staircase_unlocked:
		prompt = "Press E to descend the hidden staircase"
	elif near_portal and portal_activated:
		prompt = "Press E to enter the moon portal"
	else:
		prompt = "Explore the town, collect clues, and unlock the hidden routes"
	
	hint.text = prompt

	if player.global_position.x > 850 and not puzzle_solved:
		player.position.x = 820
		show_status("The rune gate is sealed. Find the switch near the center of town.")

	if Input.is_action_just_pressed("interact"):
		if near_switch:
			activate_switch()
		elif near_npc != null and player.global_position.distance_to(near_npc.global_position) < 80:
			interact_with_npc(near_npc.name)
		elif near_key and not hidden_key_found:
			collect_hidden_key()
		elif near_stair and staircase_unlocked:
			travel_to_hidden_stair()
		elif near_portal and portal_activated:
			travel_to_portal()

	if Input.is_action_just_pressed("jump"):
		if player.position.y > 400 and not staircase_unlocked and hidden_key_found:
			unlock_staircase()

	if Input.is_action_just_pressed("inventory"):
		InventoryManager.toggle_inventory()
		update_inventory_ui()

func build_inventory_ui() -> void:
	inventory_panel = CanvasLayer.new()
	inventory_panel.layer = 5
	add_child(inventory_panel)

	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.85)
	bg.size = Vector2(300, 360)
	bg.position = Vector2(940, 160)
	inventory_panel.add_child(bg)

	var title = Label.new()
	title.text = "Inventory"
	title.position = Vector2(945, 170)
	title.add_theme_font_size_override("font_size", 22)
	inventory_panel.add_child(title)

	inventory_label = Label.new()
	inventory_label.position = Vector2(945, 210)
	inventory_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.custom_minimum_size = Vector2(270, 200)
	inventory_panel.add_child(inventory_label)

	weather_label = Label.new()
	weather_label.position = Vector2(945, 470)
	weather_label.text = "Weather: Rain"
	inventory_panel.add_child(weather_label)

	inventory_panel.visible = false

func update_inventory_ui() -> void:
	if InventoryManager.inventory_open:
		inventory_panel.visible = true
	else:
		inventory_panel.visible = false
		return

	var lines: Array = []
	for item in InventoryManager.get_items():
		lines.append("- %s x%s" % [item, InventoryManager.inventory[item]])
	if lines.is_empty():
		lines.append("- empty")
	inventory_label.text = "\n".join(lines)
	weather_label.text = "Weather: %s" % WeatherManager.get_weather().capitalize()

func _on_inventory_changed() -> void:
	update_inventory_ui()

func _on_weather_changed(weather_name: String) -> void:
	update_weather_ui()
	update_inventory_ui()

func update_weather_ui() -> void:
	weather_label.text = "Weather: %s" % WeatherManager.get_weather().capitalize()

func get_nearest_npc() -> Node2D:
	var npc_nodes: Array = [$Mira, $Bram, $Gilda, $OldTobin]
	var nearest: Node2D = null
	var nearest_distance: float = INF
	for npc in npc_nodes:
		var dist = player.global_position.distance_to(npc.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
			nearest = npc
	if nearest_distance > 90:
		return null
	return nearest

func activate_switch() -> void:
	if puzzle_solved:
		show_status("The gate has already opened. The road is yours.")
		return
	puzzle_solved = true
	update_gate_state()
	show_status("The rune switch erupts with light. The road to the north opens.")
	if not hidden_key_found:
		show_status("A secret bronze key glints under the elder's bench. It may lead to a hidden staircase.")

func update_gate_state() -> void:
	gate.visible = not puzzle_solved

func interact_with_npc(npc_name_text: String) -> void:
	var quest = quest_chain[current_index]
	var recipient = quest["recipient"]
	if npc_name_text == recipient:
		handle_delivery(quest)
		return
	if npc_name_text == "OldTobin":
		show_status("Old Tobin whispers: 'Not that package. The real one is for %s.'" % recipient)
		return
	var speaker = get_node(npc_name_text)
	if speaker != null and speaker.has_method("get_dialogue"):
		show_status(speaker.get_dialogue())
	else:
		show_status("%s mutters: 'The town is hungry for answers.'" % npc_name_text)

func handle_delivery(quest: Dictionary) -> void:
	var item_name = quest["item"]
	if quest["kind"] == "cursed":
		show_status("You hand over %s to %s. The package cracks with a low hiss and leaves a cold stain on your hand." % [item_name, quest["recipient"]])
	else:
		show_status("You hand over %s to %s. The town gasps as a hidden gold page slips from the package." % [item_name, quest["recipient"]])
	InventoryManager.add_item(item_name, 1)
	if current_index < quest_chain.size() - 1:
		current_index += 1
		update_quest_ui()
	else:
		current_index = quest_chain.size() - 1
		quest_title.text = "Town Saved"
		quest_text.text = "All deliveries are finished. The hidden roads are now open to you."
		staircase_unlocked = true
		portal_activated = true
		show_status("The final delivery echoes through the town. A staircase appears behind the smithy, and a moon portal glows near the north exit.")

func update_quest_ui() -> void:
	var quest = quest_chain[current_index]
	quest_title.text = quest["title"]
	quest_text.text = "Bring %s to %s. %s" % [quest["item"], quest["recipient"], quest["summary"]]

func collect_hidden_key() -> void:
	if hidden_key_found:
		show_status("The hidden key is already in your pack.")
		return
	hidden_key_found = true
	InventoryManager.add_item("Bronze Key", 1)
	show_status("You take the bronze key. A staircase shimmers behind the old stone wall. You can now jump to reveal it.")
	staircase_unlocked = true

func unlock_staircase() -> void:
	if not hidden_key_found:
		show_status("The stair is hidden beneath the mud. You need the bronze key to reveal it.")
		return
	staircase_unlocked = true
	show_status("The old stair rises from the ground with a metallic groan. A portal hums beyond it.")
	portal_activated = true

func travel_to_hidden_stair() -> void:
	if not staircase_unlocked:
		show_status("The stairs are still sealed by silence.")
		return
	player.position = Vector2(1000, 170)
	show_status("You descend the hidden staircase into a moonlit cellar. The air smells of old rain and forgotten debts.")

func travel_to_portal() -> void:
	if not portal_activated:
		show_status("The moon portal is still asleep.")
		return
	player.position = Vector2(1120, 500)
	show_status("The moon portal pulls you through. The town fades behind you, and a new route opens in the dark.")

func show_status(text: String) -> void:
	status.text = text
