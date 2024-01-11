extends Node

@onready var arm = $Controls/Arm
@onready var default_scale = arm.scale
@onready var left_button = $Terminal/LeftButton
@onready var default_position = left_button.position.y
@onready var enter_button = $Terminal/EnterButton
@onready var right_button = $Terminal/RightButton
@onready var attack_button = $Terminal/AttackButton
@onready var attack_input = $Terminal/AttackButton/Attack
@onready var attack_button_hidden = $Terminal/AttackButtonHidden
@onready var r_label = $RightCell/RightLabel
@onready var c_label = $CenterCell/CenterLabel 
@onready var l_label = $LeftCell/LeftLabel
@onready var armed_label = $ArmedCell/ArmedLabel
@onready var center_cell = $CenterCell
@onready var armed_cell = $ArmedCell
@onready var dazed_timer = $Dazed
@onready var countdown = $Controls/Countdown
@onready var click_sound = $ClickSound
@onready var music = $Music
@onready var load_response = $LoadResponse
@onready var attack_sound = $AttackSound
@onready var dazed_sound = $DazedSound
@onready var lost_sound = $LostSound
@onready var win_sound = $WinSound
@onready var alarm_sound = $AlarmSound
@onready var monster = $Monster
@onready var laser = $Tip/Laser
@onready var shield = $ShieldSprite
@onready var popup = $Controls/Popup
@onready var popup_label = $Controls/Popup/PopupLabel

var main_scene = "res://scenes/main.tscn"

var rng = RandomNumberGenerator.new()
var shake_strength = 0
var random_strength = 30
var shake_fade = 5

var life = 10

var mvmt_area
var arm_press_scale = Vector2(.5, .5)
var btn_press_pos = 100

var tween_arm
var tween_btn
var tween_arming
var tween_attack
var tween_laser

enum States {DEFAULT, DAZED}
var state = States.DEFAULT

var arsenal_size = QuizData.arsenal.size()
var starting_index = 1

signal counterattack

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	randomize()
	QuizData.arsenal.shuffle()
	
	countdown.play("countdown")
	await countdown.animation_finished
	
	music.play()
	
	monster.get_node("AttackTimer").start()
	
	update_rail(starting_index)

func _process(_delta):
	update_arm()
	update_hidden_btns()
	update_shield(_delta)
	
	if Input.is_action_pressed("back"):
		get_tree().change_scene_to_file(main_scene)

func update_hidden_btns():
	if state == States.DAZED:
		attack_button_hidden.visible = true
		attack_input.visible = false
	else:
		attack_button_hidden.visible = false
		attack_input.visible = true
	
func update_rail(center_index):
	l_label.text = tr(QuizData.arsenal[(center_index - 1) % arsenal_size])
	c_label.text = tr(QuizData.arsenal[center_index % arsenal_size])
	r_label.text = tr(QuizData.arsenal[(center_index + 1) % arsenal_size])

func _on_left_gui_input(event):
	if event.is_action_pressed("mouse_click"):
		if state == States.DAZED:
			press_animation(btn_press_pos, right_button, arm_press_scale)
			starting_index += 1
			update_rail(starting_index)
		else:
			press_animation(btn_press_pos, left_button, arm_press_scale)
			starting_index -= 1
			update_rail(starting_index)

func _on_right_gui_input(event):
	if event.is_action_pressed("mouse_click"):
		if state == States.DAZED:
			press_animation(btn_press_pos, left_button, arm_press_scale)
			starting_index -= 1
			update_rail(starting_index)
		else:
			press_animation(btn_press_pos, right_button, arm_press_scale)
			starting_index += 1
			update_rail(starting_index)

func _on_enter_gui_input(event):
	if event.is_action_pressed("mouse_click"):
		press_animation(btn_press_pos, enter_button, arm_press_scale)

func _on_attack_gui_input(event):
	if event.is_action_pressed("mouse_click"):
		press_animation(btn_press_pos, attack_button, arm_press_scale)

func update_arm():
	mvmt_area = get_viewport().get_mouse_position()
	mvmt_area.x = clamp(mvmt_area.x, 120, 1800)
	mvmt_area.y = clamp(mvmt_area.y, 500, 1000)
	
	if state == States.DAZED:
		arm.position.x = - mvmt_area.x + 1920
		arm.position.y = - mvmt_area.y + 1690
	else:
		arm.position = mvmt_area

func update_shield(delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		shield.offset = Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))

func press_animation(btn_anim, button, arm_anim):
	click_sound.play()

	tween_arm = get_tree().create_tween()
	arm.scale = arm_anim
	tween_arm.tween_property(arm, "scale", default_scale, .1)

	tween_btn = get_tree().create_tween()
	button.position.y += btn_anim
	tween_btn.tween_property(button, "position", Vector2(button.position.x, default_position), .1)
	
	if button == enter_button:
		tween_arming = get_tree().create_tween()
		tween_arming.tween_property(center_cell, "value", 100, .1)
		tween_arming.tween_property(center_cell, "value", 0, .1)
		tween_arming.connect("finished", on_arming_finished)
		load_response.play()

	if button == attack_button:
		tween_attack = get_tree().create_tween()
		tween_attack.tween_property(armed_cell, "value", 100, .1)
		tween_attack.tween_property(armed_cell, "value", 0, .1)
		tween_attack.connect("finished", on_attack_finished)
		attack_sound.play()

func on_arming_finished():
	armed_label.text = c_label.text

func on_attack_finished():
	if c_label.text == tr(monster.attack.response):
		counterattack.emit()
		tween_laser = get_tree().create_tween()
		tween_laser.tween_property(laser, "value", 100, .05)
		tween_laser.tween_property(laser, "value", 0, .01)
	else:
		state = States.DAZED
		dazed_timer.start()
		dazed_sound.play()

func _on_dazed_timeout():
	state = States.DEFAULT

func _on_victory():
	music.stop()
	
	monster.queue_free()
	
	win_sound.play()
	show_popup("KEY_WIN")

func _on_monster_attack():
	shield_shake()
	life -= 1
	shield.frame += 1
	
	if life <= 0:
		music.stop()
		
		alarm_sound.play()
		lost_sound.play()
		
		show_popup("KEY_LOSE")
		monster.queue_free()

func show_popup(label_text):
	popup_label.text = tr(label_text)
	popup.visible = true
	
func shield_shake():
	shake_strength = random_strength

func _on_play_button_pressed():
	get_tree().reload_current_scene()
	
func _on_menu_button_pressed():
	get_tree().change_scene_to_file(main_scene)
