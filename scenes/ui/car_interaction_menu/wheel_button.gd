extends Control

@export var wheel_name : String
@export var wheel_preview : TextureRect
@export var price : int
@export var buy_button : Button

signal purchased_wheel(wheel_name : String, price : int)

func set_wheel(_name : String, _price : int):
	wheel_name = _name
	price = _price
	buy_button.text = str("$%d" % price)
	wheel_preview.texture = load("res://cars/wheels/"+wheel_name+"/"+wheel_name+".png")

func _on_buy_button_pressed():
	purchased_wheel.emit(wheel_name, price)
