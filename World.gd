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

var cur_cvpos = Vector2.ZERO
var cur_vpos = Vector2.ZERO
var camera_zoom = 0
var target_camera_zoom = 0
var camera_basis
const CAMERA_ZOOM_IN = 0.5
const CAMERA_ZOOM_OUT = 1.5

var rBerries = {
	"berry1": load("res://assets/berry1.png"),
	"berry2": load("res://assets/berry2.png"),
	"berry3": load("res://assets/berry3.png"),
	"berry4": load("res://assets/berry4.png"),
	"berry5": load("res://assets/berry5.png"),
	"berry6": load("res://assets/berry6.png"),
}
var berryTypes = rBerries.keys()
var rItems = {
	"Berry": load("res://Berry.tscn"),
	"Item": load("res://Item.tscn"),
	"Bush1": load("res://Bush1.tscn"),
	"TreeBig1": load("res://TreeBig1.tscn"),
	"TreeBig2": load("res://TreeBig2.tscn"),
	"TreeSmall1": load("res://TreeSmall1.tscn")
}
var itemBuffer = {}
var loadedTrees = 0

var is_explore_key = false
var is_explore = false
var is_pickup_key = false
var is_pickup = false
var is_select_key = false

var cur_berry = -1
var cur_pickups = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$Camera.make_current()
	$Character.playing = true
	characterOrigin = $Character.transform.origin
	
	camera_zoom = CAMERA_ZOOM_OUT
	target_camera_zoom = camera_zoom
	camera_basis = $Camera.transform.basis.z.normalized()
	$Camera.transform.origin = camera_basis*camera_zoom

	# shuffle randomizer
	randomize()
	
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

func _input(event):
	if event.is_action_pressed("explore"):
		if not is_explore_key:
			is_explore_key = true
			if is_explore:
				unexplore()
			else:
				explore()
	elif is_explore_key:
		is_explore_key = false
	
	if event.is_action_pressed("select"):
		if not is_select_key:
			is_select_key = true
			if is_explore:
				select(cur_berry + 1)
	elif is_select_key:
		is_select_key = false
	
	if event.is_action_pressed("pickup"):
		if not is_pickup_key:
			is_pickup_key = true
			if is_explore:
				pickup()
	elif is_pickup_key:
		is_pickup_key = false

func _physics_process(delta):
	if not is_explore:
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
			if dir.x > 0:
				$Character.scale.x = -abs($Character.scale.x)
			elif dir.x < 0:
				$Character.scale.x = abs($Character.scale.x)
			$Character.animation = "run"
		else:
			$Character.animation = "idle"
	
	camera_zoom = camera_zoom + (target_camera_zoom - camera_zoom)*delta*5
	$Camera.transform.origin = camera_basis*camera_zoom
	
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
			
			for berry in map[j][i].berries:
				if berry.berries == 0:
					continue
				
				var p = berry.vpos - Vector3(vpos.x, 0, vpos.y)
				
				if p.length() > 1.2:
					if berry.has("instance"):
						if berry.has("instances"):
							for b in berry.instances:
								assert(b.get_parent() == berry.instance, "Berry should be in the cluster")
								berry.instance.remove_child(b)
								freeItem("Berry", b)
							freeItem("Spatial", berry.instance)
							assert(berry.instance.get_child_count() == 0, "Spatial should have no children")
							berry.erase("instance")
							berry.erase("instances")
				else:
					if not berry.has("instance"):
						berry.instance = getItem("Spatial")
						berry.instances = []
						for _k in range(berry.berries):
							var b = getItem("Berry", berry.instance)
							b.setTexture(rBerries[berry.type])
							b.transform.origin = Vector3(randf()*0.02-0.01, randf()*0.01-0.005, 0)
							berry.instances.append(b)
					
					var z = 16 - pow(p.x, 2) - pow(p.z, 2)
					if z <= 0:
						# hide
						berry.instance.transform.origin.y = -10
					else:
						z = sqrt(z)
						berry.instance.transform.origin.x = -p.x
						berry.instance.transform.origin.y = p.y + z - 4
						berry.instance.transform.origin.z = -p.z
	
	# highlight
	if is_explore and len(cur_pickups) > 0:
		var berry = cur_pickups[cur_berry]
		
		$Highlight.transform.origin = berry.instance.transform.origin + camera_basis*0.1
	
	var z = sqrt(1 - pow(cpos.x, 2) - pow(cpos.y, 2))
	$Character.transform.origin.x = cpos.x
	$Character.transform.origin.z = cpos.y
	$Character.transform.origin.y = characterOrigin.y * z
	
	cur_cvpos = cvpos
	cur_vpos = vpos
	
	#$Character.get_node("Shadow").visible = hit
	#$Debug.text = "dist: "+str(dist)
	
	$Globe.get_surface_material(0).set_shader_param("offset", -cameraPos)

func explore():
	if is_explore:
		return
	var pickups = []
	for i in range(3):
		for j in range(3):
			for berry in map[j][i].berries:
				if berry.berries == 0:
					continue
				
				var p = berry.vpos - Vector3(cur_cvpos.x, 0, cur_cvpos.y)
				
				if p.length() < 0.08:
					pickups.append(berry)
	
	is_explore = true

	cur_pickups = pickups
	
	$Highlight.show()
	
	select(0)
	
	target_camera_zoom = CAMERA_ZOOM_IN

func unexplore():
	if not is_explore:
		return
	
	is_explore = false
	target_camera_zoom = CAMERA_ZOOM_OUT
	$Highlight.hide()

func select(index):
	if len(cur_pickups) == 0:
		$Highlight.hide()
		return
	
	cur_berry = index % len(cur_pickups)
	
	$Highlight.show()

func pickup():
	if cur_berry == -1 or len(cur_pickups) == 0:
		return
	
	var berry = cur_pickups[cur_berry]
	var b = berry.instances.pop_back()
	berry.berries -= 1
	
	# eat
	#b.scale.x = b.scale.x*2
	add_child(b)
	b.free()
	#freeItem("Berry", b)
	#b.transform.origin.y = 0.1
	#b.hide()
	print("ate berry")
	
	if berry.berries == 0:
		cur_pickups.remove(cur_berry)
		cur_berry = -1
		
		if len(cur_pickups) == 0:
			unexplore()
		else:
			select(0)

func loadSegment(ox, oy):
	currentTile += Vector2(ox, oy)
	
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
				map[j][i].berries = map[j2][i2].berries
				map[j2][i2].items = []
				map[j2][i2].erase("berries")

#########################################################################################################
# level generation
#########################################################################################################

func loadTile(m):
	var x = m.x
	var y = m.y
	
	var tile = getTile(x, y)
	var r = RandomNumberGenerator.new()
	r.seed = tile.seed
	
	assert(len(m.items) == 0, "Items list should be empty")
	
	var generateBerries = false
	if not m.has("berries"):
		if not tile.has("berries"):
			generateBerries = true
			tile.berries = []
		m.berries = tile.berries
	
	var ox = x*tileSize
	var oy = y*tileSize
	
	for _i in range(30):
		var item = {
			"vpos": Vector2(ox + r.randf()*tileSize-tileSize2, oy + r.randf()*tileSize-tileSize2),
			"type": "TreeBig1" if r.randf_range(0,1) > 0.5 else "TreeBig2",
			"collide": 0.06
		}
		item.instance = getItem(item.type)
		m.items.append(item)

	for _i in range(40):
		var item = {
			"vpos": Vector2(ox + r.randf()*tileSize-tileSize2, oy + r.randf()*tileSize-tileSize2),
			"type": "TreeSmall1",
			"collide": 0.04
		}
		item.instance = getItem(item.type)
		m.items.append(item)

	for _i in range(80):
		var item = {
			"vpos": Vector2(ox + r.randf()*tileSize-tileSize2, oy + r.randf()*tileSize-tileSize2),
			"type": "Bush1"
		}
		item.instance = getItem(item.type)
		m.items.append(item)
		
		if r.randf() > 0.3:
			var type = berryTypes[r.randi_range(0, len(berryTypes)-1)]

			var b = ({
				"vpos": Vector3(item.vpos.x + r.randf()*0.06-0.03, 0.005 + r.randf()*0.03, item.vpos.y + 0.001),
				"type": type,
				"berries": r.randi_range(1,4),
			})
			
			if generateBerries:
				tile.berries.append(b)

func unloadTile(m):
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

func getItem(name, parent = self):
	if not itemBuffer.has(name):
		itemBuffer[name] = []
	if len(itemBuffer[name]) > 0:
		var item = itemBuffer[name].pop_back()
		if not item.get_parent() == parent:
			parent.add_child(item)
		item.show()
		return item
	var item
	if name == "Spatial":
		item = Spatial.new()
	else:
		item = rItems[name].instance()
	parent.add_child(item)
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
