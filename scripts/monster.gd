extends Node

@onready var attack_label = $AttackLabel
@onready var animation = $Animation
@onready var healthbar = $HealthBar

var attacks
var attack

signal victory
signal monster_attack

func _ready():
	randomize()
	QuizData.attacks.shuffle()
	attacks = QuizData.attacks
	attack = attacks.pick_random()

	animation.play("idle")

func _process(_delta):
	attack_label.text = tr(attack.attack)

func _on_attack_timer_timeout():
	monster_attack.emit();
	animation.play("attack")
	await animation.animation_finished
	animation.play("idle")

func _on_counterattack():
	healthbar.value -= 1
	if healthbar.value <= 0:
		victory.emit()
	animation.play("damaged")
	await animation.animation_finished
	animation.play("idle")
	attack = attacks.pick_random()
