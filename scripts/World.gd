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
        "summary": "Mira says the tea has a strange hum. Some rumors say it was brewed under moonlight."
    },
    {
        "title": "The Ledger to Bram",
        "item": "The Black Ledger",
        "recipient": "Bram",
        "kind": "valuable",
        "summary": "Bram wants the ledger before the town council notices the missing page."
    },
    {
        "title": "Gilda's Secret Ribbon",
        "item": "A Velvet Ribbon",
        "recipient": "Gilda",
        "kind": "cursed",
        "summary": "Gilda thinks the ribbon is harmless, but it whispers when the moon is high."
    }
]

var current_index: int = 0
var puzzle_solved: bool = false
var completed_deliveries: int = 0

func _ready() -> void:
    $Mira.npc_name = "Mira"
    $Bram.npc_name = "Bram"
    $Gilda.npc_name = "Gilda"
    $OldTobin.npc_name = "OldTobin"
    $Mira.dialogue = "A warm cup only if it is sealed. The town has been odd since the rain."
    $Bram.dialogue = "The blacksmith keeps whispering about a ledger with a missing page."
    $Gilda.dialogue = "I have an old ribbon with a strange glow. Do not let it touch the dark stone."
    $OldTobin.dialogue = "If you leave a cursed box on my porch, I will know. I always know."
    update_quest_ui()
    update_gate_state()

func _process(_delta: float) -> void:
    var near_npc = get_nearest_npc()
    var near_switch = player.global_position.distance_to(switch_node.global_position) < 70

    if not near_switch and near_npc != null and player.global_position.distance_to(near_npc.global_position) < 80:
        hint.text = "Press E to speak with %s" % near_npc.name
    elif near_switch:
        hint.text = "Press E to activate the rune switch"
    else:
        hint.text = "Explore the town and search for the next delivery"

    if player.global_position.x > 850 and not puzzle_solved:
        player.position.x = 820
        status.text = "A rune gate blocks the road. The switch is near the center square."

    if Input.is_action_just_pressed("interact"):
        if near_switch:
            activate_switch()
        elif near_npc != null and player.global_position.distance_to(near_npc.global_position) < 80:
            interact_with_npc(near_npc.name)

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
        status.text = "The gate has already opened. The road is yours."
        return

    puzzle_solved = true
    update_gate_state()
    status.text = "The rune switch hums to life. The gate opens slowly, revealing the northern road."

func update_gate_state() -> void:
    gate.visible = not puzzle_solved

func interact_with_npc(npc_name_text: String) -> void:
    var quest = quest_chain[current_index]
    var recipient = quest["recipient"]

    if npc_name_text == recipient:
        handle_delivery(quest)
        return

    if npc_name_text == "OldTobin":
        status.text = "Old Tobin leans close. \"Not that package. The real one is for %s.\"" % recipient
        return

    var speaker = get_node(npc_name_text)
    if speaker != null and speaker.has_method("get_dialogue"):
        status.text = speaker.get_dialogue()
    else:
        status.text = "%s mutters: \"The town is hungry for answers.\"" % npc_name_text

func handle_delivery(quest: Dictionary) -> void:
    var package_kind = quest["kind"]

    if package_kind == "cursed":
        status.text = "You hand over %s to %s. The package hisses, then falls silent. A cold pulse runs up your sleeve.\nThe curse is now in the town's story." % [quest["item"], quest["recipient"]]
    else:
        status.text = "You hand over %s to %s. The package is worth a fortune, and the town grows quiet with envy.\nA valuable clue slips into your pocket." % [quest["item"], quest["recipient"]]

    completed_deliveries += 1
    if current_index < quest_chain.size() - 1:
        current_index += 1
        update_quest_ui()
    else:
        current_index = quest_chain.size() - 1
        quest_title.text = "Town Saved"
        quest_text.text = "All deliveries are complete. The town breathes easier."
        hint.text = "You finished the courier run."
        status.text = "The final box settles in the square. The town remembers your name."

func update_quest_ui() -> void:
    var quest = quest_chain[current_index]
    quest_title.text = quest["title"]
    quest_text.text = "Bring %s to %s. %s" % [quest["item"], quest["recipient"], quest["summary"]]
