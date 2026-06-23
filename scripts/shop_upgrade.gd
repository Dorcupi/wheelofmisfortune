extends VBoxContainer
class_name ShopUpgrade

@export var title: String:
	set(new_value):
		title = new_value
		if title_label:
			title_label.text = new_value
@export var description: String:
	set(new_value):
		description = new_value
		if description_label:
			description_label.text = new_value
@export var price: float:
	set(new_value):
		price = new_value
		if buy_button:
			buy_button.text = "BUY - $%.2f" % new_value
@onready var title_label: Label = $Title
@onready var description_label: Label = $Description
@onready var buy_button: Button = $BuyButton
@onready var toggle_button: Button = $ToggleButton
@export var upgrade: Upgrade

var purchased: bool = false:
	set(new_value):
		purchased = new_value
		if purchased and buy_button:
			buy_button.visible = false
			toggle_button.visible = true
		elif not purchased and buy_button:
			buy_button.visible = true
			toggle_button.visible = false

var enabled: bool = false:
	set(new_value):
		enabled = new_value
		if enabled and toggle_button:
			toggle_button.text = "TURN OFF"
		elif not enabled and toggle_button:
			toggle_button.text = "TURN ON"

signal purchase_item(node, upgrade, price)
signal toggle_item(node, upgrade)

func _on_buy_button_pressed() -> void:
	purchase_item.emit(self, upgrade, price)

func _on_toggle_button_pressed() -> void:
	toggle_item.emit(self, upgrade)

func _ready() -> void:
	if title_label:
		title_label.text = title
	if description_label:
		description_label.text = description
	if buy_button:
		buy_button.text = "BUY - $%.2f" % price
		buy_button.visible = not purchased
	if toggle_button:
		if enabled:
			toggle_button.text = "TURN OFF"
		else:
			toggle_button.text = "TURN ON"
		toggle_button.visible = purchased
