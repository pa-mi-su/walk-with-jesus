class_name JourneyCollectible
extends Area2D

signal collected(collectible: JourneyCollectible, kind: String, strength_restore: float)

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: PointLight2D = $Glow

var kind := "bread"
var display_name := "Bread"
var strength_restore := 18.0
var texture_path := ""
var _base_y := 0.0
var _elapsed := 0.0
var _collected := false


func _ready() -> void:
	add_to_group("journey_collectibles")
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path) as Texture2D
	_base_y = sprite.position.y
	body_entered.connect(_on_body_entered)


func configure(data: Dictionary) -> void:
	kind = str(data.get("kind", "bread"))
	display_name = str(data.get("display_name", kind.capitalize()))
	strength_restore = float(data.get("strength_restore", 18.0))
	texture_path = str(data.get("texture_path", ""))
	position = data.get("position", Vector2.ZERO)


func collect() -> void:
	if _collected:
		return
	_collected = true
	set_deferred("monitoring", false)
	collected.emit(self, kind, strength_restore)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.35, 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	sprite.position.y = _base_y + sin(_elapsed * 3.2) * 4.0
	glow.energy = 0.72 + sin(_elapsed * 3.2) * 0.12


func _on_body_entered(body: Node) -> void:
	if body is TravelerPlayer:
		collect()
