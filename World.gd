extends Spatial

export var speed = 2
export var cameraSpeed = 1
var pos = Vector2.ZERO
var vpos = Vector2.ZERO
var cameraPos = Vector2.ZERO
var characterOrigin
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var rItem = load("res://Item.tscn")
var rBush1 = load("res://Bush1.tscn")
var rTreeBig1 = load("res://TreeBig1.tscn")
var rTreeBig2 = load("res://TreeBig2.tscn")
var rTreeSmall1 = load("res://TreeSmall1.tscn")

var items = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$Camera.make_current()
	$Character.playing = true
	characterOrigin = $Character.transform.origin
	
#	items.append({
#		"vpos": Vector2(0,0),
#		"instance": rItem.instance()
#	})
#	add_child(items[0].instance)

	randomize()
	
	for i in range(40):
		var item = {
			"vpos": Vector2(randf()*4-2,randf()*4-2),
			"instance": rTreeBig1.instance() if rand_range(0,1) > 0.5 else rTreeBig2.instance()
		}
		add_child(item.instance)
		items.append(item)
	
	for i in range(40):
		var item = {
			"vpos": Vector2(randf()*4-2,randf()*4-2),
			"instance": rTreeSmall1.instance()
		}
		add_child(item.instance)
		items.append(item)
	
	for i in range(80):
		var item = {
			"vpos": Vector2(randf()*4-2,randf()*4-2),
			"instance": rBush1.instance()
		}
		add_child(item.instance)
		items.append(item)

func _physics_process(delta):
	var move = false
	var dir = Vector2.ZERO
	if Input.is_action_pressed("left"):
		move = true
		dir += Vector2.LEFT
	if Input.is_action_pressed("right"):
		move = true
		dir += Vector2.RIGHT
	if Input.is_action_pressed("up"):
		move = true
		dir += Vector2.UP
	if Input.is_action_pressed("down"):
		move = true
		dir += Vector2.DOWN
	
	pos += dir.normalized()*speed*delta
	
	if move:
		$Character.animation = "run"
	else:
		$Character.animation = "idle"
	
	cameraPos += (pos - cameraPos)*cameraSpeed*delta
	vpos = cameraPos
	vpos.x /= PI*4
	vpos.y /= 8
	
	var cpos = cameraPos - pos
	cpos.x /= PI*4
	cpos.y /= 8
	var z = sqrt(1 - pow(cpos.x, 2) - pow(cpos.y, 2))
	
	$Character.transform.origin.x = cpos.x
	$Character.transform.origin.z = cpos.y
	$Character.transform.origin.y = characterOrigin.y * z
	
	var shown = false
	
	for item in items:
		var p = item.vpos - vpos
		z = 16 - pow(p.x, 2) - pow(p.y, 2)
		if z <= 0:
			item.instance.hide()
			pass
		else:
			z = sqrt(z)
			item.instance.show()
			item.instance.transform.origin.x = -p.x
			item.instance.transform.origin.z = -p.y
			item.instance.transform.origin.y = z - 4
			
			var d = cpos.distance_to(item.vpos)
			if d < 0.1:
				if not shown:
					shown = true
					prints("collide", item) #pos = item.vpos + (cpos - item.vpos).normalized()*0.22
	
	$Globe.get_surface_material(0).set_shader_param("offset", -cameraPos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
