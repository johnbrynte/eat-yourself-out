extends Spatial

export var texture : Texture
export var stats : Dictionary

func _ready():
	$BerrySprite.texture = texture

func setTexture(t):
	texture = t
	$BerrySprite.texture = texture
