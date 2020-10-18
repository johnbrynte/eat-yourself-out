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

var items = []

var tileSize = 2
var tileSize2 = tileSize / 2.0
var map = [
	[0,0,0],
	[0,0,0],
	[0,0,0]
]
var mapTiles = {}
var currentTile = Vector2.ZERO
var mapRandom = RandomNumberGenerator.new()

var rItems = {
	"Item": load("res://Item.tscn"),
	"Bush1": load("res://Bush1.tscn"),
	"TreeBig1": load("res://TreeBig1.tscn"),
	"TreeBig2": load("res://TreeBig2.tscn"),
	"TreeSmall1": load("res://TreeSmall1.tscn")
}
var itemBuffer = {}
var loadedTrees = 0

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
	
	# addTile(0,0)
	for i in range(3):
		for j in range(3):
			var x = i-1.0
			var y = j-1.0
			map[j][i] = {
				"x": x,
				"y": y,
				"items": [],
			}	
			loadTile(map[j][i])
	
#	for i in range(40):
#		var item = {
#			"vpos": Vector2(randf()*4-2,randf()*4-2),
#			"instance": rTreeBig1.instance() if rand_range(0,1) > 0.5 else rTreeBig2.instance()
#		}
#		add_child(item.instance)
#		items.append(item)
#
#	for i in range(40):
#		var item = {
#			"vpos": Vector2(randf()*4-2,randf()*4-2),
#			"instance": rTreeSmall1.instance()
#		}
#		add_child(item.instance)
#		items.append(item)
#
#	for i in range(80):
#		var item = {
#			"vpos": Vector2(randf()*4-2,randf()*4-2),
#			"instance": rBush1.instance()
#		}
#		add_child(item.instance)
#		items.append(item)

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
	
	var newTile = vpos - (currentTile*tileSize)
	#$Debug.text = str(len(itemBuffer["TreeBig1"]))+" / "+str(loadedTrees) # str(newTile.length())
	
	if newTile.x > tileSize2:
		loadSegment(1, 0)
	elif newTile.x < -tileSize2:
		loadSegment(-1, 0)
	elif newTile.y > tileSize2:
		loadSegment(0, 1)
	elif newTile.y < -tileSize2:
		loadSegment(0, -1)
		
	var cvpos = vpos - cpos
	
	#var hit = false
	
	for i in range(3):
		for j in range(3):
			for item in map[j][i].items:
				var p = item.vpos - vpos
				var z = 16 - pow(p.x, 2) - pow(p.y, 2)
				if z <= 0:
					# hide
					item.instance.transform.origin.y = -10
				else:
					z = sqrt(z)
					item.instance.transform.origin.x = -p.x
					item.instance.transform.origin.z = -p.y
					item.instance.transform.origin.y = z - 4
					
					if item.has("collide"):
						var d = cvpos.distance_to(item.vpos)
						if d < item.collide:
							var pushback = (item.vpos + (cvpos - item.vpos).normalized()*item.collide) - cvpos
							cpos += pushback
							cvpos += pushback
							pushback.x *= PI*4
							pushback.y *= 8
							pos += pushback
	
	var z = sqrt(1 - pow(cpos.x, 2) - pow(cpos.y, 2))
	$Character.transform.origin.x = cpos.x
	$Character.transform.origin.z = cpos.y
	$Character.transform.origin.y = characterOrigin.y * z
	
	#$Character.get_node("Shadow").visible = hit
	#$Debug.text = "dist: "+str(dist)
	
	$Globe.get_surface_material(0).set_shader_param("offset", -cameraPos)

func loadSegment(ox, oy):
	currentTile += Vector2(ox, oy)
	
	var tilesunload = []
	var tilesload = []
	
	for _i in range(3):
		var i = 2-_i if ox < 0 else _i
		for _j in range(3):
			var j = 2-_j if oy < 0 else _j
			
			var x = map[j][i].x
			var y = map[j][i].y
			var i1 = i - ox
			var j1 = j - oy
			var i2 = i + ox
			var j2 = j + oy
			
			if i1-1 < -1 or i1-1 > 1 or j1-1 < -1 or j1-1 > 1:
				unloadTile(map[j][i])
			
			map[j][i].x = x+ox
			map[j][i].y = y+oy
			
			if i2-1 < -1 or i2-1 > 1 or j2-1 < -1 or j2-1 > 1:
				loadTile(map[j][i])
			else:
				map[j][i].items = map[j2][i2].items
				map[j2][i2].items = []

func loadTile(m):
	var x = m.x
	var y = m.y
	
	var tile = getTile(x, y)
	var r = RandomNumberGenerator.new()
	r.seed = tile.seed
	
	assert(len(m.items) == 0, "Items list should be empty")
	
	var ox = x*tileSize
	var oy = y*tileSize
	
	for i in range(20):
		var item = {
			"vpos": Vector2(ox + r.randf()*tileSize-tileSize2, oy + r.randf()*tileSize-tileSize2),
			"type": "TreeBig1" if r.randf_range(0,1) > 0.5 else "TreeBig2",
			"collide": 0.06
		}
		item.instance = getItem(item.type)
		m.items.append(item)

	for i in range(20):
		var item = {
			"vpos": Vector2(ox + r.randf()*tileSize-tileSize2, oy + r.randf()*tileSize-tileSize2),
			"type": "TreeSmall1",
			"collide": 0.04
		}
		item.instance = getItem(item.type)
		m.items.append(item)

	for i in range(80):
		var item = {
			"vpos": Vector2(ox + r.randf()*tileSize-tileSize2, oy + r.randf()*tileSize-tileSize2),
			"type": "Bush1"
		}
		item.instance = getItem(item.type)
		m.items.append(item)

func unloadTile(m):
	var x = m.x
	var y = m.y
	prints("unload",x,y)
	var tile = getTile(x, y)
	
	for item in m.items:
		freeItem(item.type, item.instance)
	
	m.items = []

func addTile(x, y):
	var tile = {
		"x": x,
		"y": y,
		"seed": mapRandom.randi(),
	}
	mapTiles[getTileKey(x, y)] = tile

func getTile(x, y):
	var key = getTileKey(x, y)
	if not mapTiles.has(key):
		addTile(x, y)
	return mapTiles[key]

func getTileKey(x, y):
	return str(x)+","+str(y)

func getItem(name):
	if not itemBuffer.has(name):
		itemBuffer[name] = []
	if len(itemBuffer[name]) > 0:
		var item = itemBuffer[name].pop_back()
		item.show()
		return item
	var item = rItems[name].instance()
	add_child(item)
	item.show()
	if name == "TreeBig1":
		loadedTrees += 1
	return item

func freeItem(name, item):
	if not itemBuffer.has(name):
		itemBuffer[name] = []
	item.hide()
	itemBuffer[name].push_back(item)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
