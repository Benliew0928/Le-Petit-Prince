extends Control

## MapSystem — Interactive cosmic star-chart UI overlay.
## Features a planetary orrery view, glassmorphism inspection details, and dynamic POI navigation setting.

@onready var main_view: Control = $MainView
@onready var detail_view: Control = $DetailView
@onready var backdrop: Panel = $Backdrop

# Detail view components
@onready var planet_title: Label = $DetailView/Panel/PlanetTitle
@onready var planet_desc: Label = $DetailView/Panel/PlanetDesc
@onready var poi_grid: GridContainer = $DetailView/Panel/Scroll/PoiGrid

var active_planet_key: String = ""

# Planets database
var planets_db: Dictionary = {
	"b612": {
		"display_name": "B-612 (Home Planet)",
		"node_name": "PlanetB612",
		"description": "Your beautiful home asteroid. It features three volcanic vents (which must be swept regularly), rich garden plots for wheat farming, and a very proud, moody Rose.",
		"color": Color(0.45, 0.72, 0.38),
		"pois": [
			{"name": "🌹 The Rose", "node": "Rose"},
			{"name": "✈️ Golden Biplane", "node": "Airplane"},
			{"name": "🏡 Cozy House", "node": "HouseExterior"},
			{"name": "🌋 Volcano Vents", "node": "VolcanoClean"},
			{"name": "🌾 Wheat Garden", "node": "GardenPlot"},
			{"name": "🪣 Watering Can", "node": "WateringCan"},
			{"name": "🛠️ Weeding Shovel", "node": "Shovel"}
		]
	},
	"desert": {
		"display_name": "The Desert Asteroid",
		"node_name": "PlanetDesert",
		"description": "A quiet golden ocean of shifting sand dunes and deep geological rocks. A mysterious and wise Fox lives here near a cool Oasis, seeking a patient companion to tame him.",
		"color": Color(0.9, 0.75, 0.45),
		"pois": [
			{"name": "🦊 The Wise Fox", "node": "Fox"},
			{"name": "🌴 Fox Oasis", "node": "GeologicalLandmark"},
			{"name": "🪨 Ancient Dunes", "node": "Rock1"}
		]
	},
	"king": {
		"display_name": "The King's Asteroid",
		"node_name": "PlanetKing",
		"description": "A majestic royal domain covered in rich velvet colors. Inhabited by a lonely Monarch who rules over everything and commands subjects to sit, carry stars, and watch sunsets.",
		"color": Color(0.6, 0.35, 0.8),
		"pois": [
			{"name": "👑 The Monarch", "node": "King"},
			{"name": "🌟 Fallen Star", "node": "StarPickup"},
			{"name": "🌅 Sunset Peak", "node": "SunsetZone"}
		]
	},
	"lamplighter": {
		"display_name": "Lamplighter's Asteroid",
		"node_name": "PlanetLamplighter",
		"description": "A tiny, rapid-spinning sphere that completes a full day/night cycle every 8 seconds. A faithful Lamplighter tirelessly lights and extinguishes his single lantern at every sunrise and sunset.",
		"color": Color(0.38, 0.52, 0.65),
		"pois": [
			{"name": "💡 The Lamplighter", "node": "Lamplighter"},
			{"name": "🏮 Celestial Streetlamp", "node": "Streetlamp"}
		]
	},
	"geographer": {
		"display_name": "Geographer's Asteroid",
		"node_name": "PlanetGeographer",
		"description": "A scholarly world dedicated to cataloging the permanent structures of the universe. Inhabited by a wise writer of massive, heavy books waiting for explorers to report their findings.",
		"color": Color(0.25, 0.32, 0.52),
		"pois": [
			{"name": "📖 The Geographer", "node": "Geographer"},
			{"name": "✍️ Scholar Desk", "node": "Desk"},
			{"name": "📚 Book Stacks", "node": "BookStack"}
		]
	}
}


func _ready() -> void:
	# Hide UI by default, ensure transparency is active
	modulate.a = 0.0
	visible = false
	
	detail_view.visible = false
	main_view.visible = true
	
	# Connect buttons for the 5 planets in the Orrery
	for key in planets_db.keys():
		var btn_name = key.capitalize() if key != "b612" else "B612"
		var btn = main_view.get_node_or_null("Orrery/Planets/" + btn_name)
		if btn:
			btn.gui_input.connect(func(event): _on_planet_gui_input(event, key))
			btn.mouse_entered.connect(func(): _on_planet_hover(key, true))
			btn.mouse_exited.connect(func(): _on_planet_hover(key, false))
			
	# Connect close buttons
	var close_btn = main_view.get_node_or_null("Header/CloseButton")
	if close_btn:
		close_btn.pressed.connect(NavigationManager.toggle_map)
		
	var back_btn = detail_view.get_node_or_null("Panel/BackButton")
	if back_btn:
		back_btn.pressed.connect(_show_main_orrery)


func open_map() -> void:
	visible = true
	_show_main_orrery()
	queue_redraw()
	
	# Play opening animation
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).from(0.0)
	
	# Animate the solar system scaling up slightly
	var orrery = main_view.get_node_or_null("Orrery")
	if orrery:
		tween.parallel().tween_property(orrery, "scale", Vector2.ONE, 0.32).from(Vector2(0.9, 0.9))


func close_map() -> void:
	# Play closing animation
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func(): visible = false)


func _show_main_orrery() -> void:
	detail_view.visible = false
	main_view.visible = true
	main_view.modulate.a = 1.0
	queue_redraw()
	
	var subtitle = main_view.get_node_or_null("Header/Subtitle")
	if subtitle:
		subtitle.text = "🌟 Left-Click to Inspect Details  |  Right-Click to Set Waypoint 🌟"


func _on_planet_gui_input(event: InputEvent, key: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_set_planet_waypoint(key)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_inspect_planet(key)


func _on_planet_hover(key: String, hovered: bool) -> void:
	var btn_name = key.capitalize() if key != "b612" else "B612"
	var btn = main_view.get_node_or_null("Orrery/Planets/" + btn_name)
	if btn == null:
		return
		
	# Scale animation on hover
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	var target_scale = Vector2(1.12, 1.12) if hovered else Vector2.ONE
	tween.tween_property(btn, "scale", target_scale, 0.3)
	
	# Update active planetary subtitle on header
	var subtitle = main_view.get_node_or_null("Header/Subtitle")
	if subtitle:
		if hovered:
			var data = planets_db[key]
			subtitle.text = "🎯 Right-Click to travel to " + data["display_name"] + "  |  Left-Click to open logs"
		else:
			subtitle.text = "🌟 Left-Click to Inspect Details  |  Right-Click to Set Waypoint 🌟"


func _inspect_planet(key: String) -> void:
	active_planet_key = key
	var data = planets_db[key]
	
	# Fade out main view, fade in detail view
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(main_view, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		main_view.visible = false
		detail_view.visible = true
		detail_view.modulate.a = 0.0
		queue_redraw()
		
		# Set contents
		planet_title.text = data["display_name"]
		planet_title.modulate = data["color"]
		planet_desc.text = data["description"]
		
		# Re-populate grid of POIs
		_populate_pois(key)
	)
	tween.tween_property(detail_view, "modulate:a", 1.0, 0.2)
	
	# Animate the detail panel sliding in
	var panel = detail_view.get_node_or_null("Panel")
	if panel:
		tween.parallel().tween_property(panel, "position:y", (size.y - panel.size.y) * 0.5, 0.25).from(size.y)


func _populate_pois(planet_key: String) -> void:
	# Clear old children
	for child in poi_grid.get_children():
		child.queue_free()
		
	var data = planets_db[planet_key]
	
	for poi in data["pois"]:
		var btn = Button.new()
		btn.text = poi["name"]
		btn.custom_minimum_size = Vector2(170, 48)
		
		# Apply premium glassmorphic style to buttons
		btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		btn.add_theme_color_override("font_hover_color", data["color"])
		
		# Set text alignment and font size
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Listen to clicks
		btn.pressed.connect(func(): _set_poi_waypoint(planet_key, poi["node"], poi["name"]))
		
		# Hover animations
		btn.mouse_entered.connect(func():
			var t = create_tween().set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15)
		)
		btn.mouse_exited.connect(func():
			var t = create_tween().set_ease(Tween.EASE_OUT)
			t.tween_property(btn, "scale", Vector2.ONE, 0.15)
		)
		
		poi_grid.add_child(btn)


func _set_planet_waypoint(key: String) -> void:
	var data = planets_db[key]
	var world = get_tree().root.get_node_or_null("TestWorld")
	if world == null:
		return
		
	# Find node based on internal planet name in world scene
	var planet_node = world.get_node_or_null(data["node_name"])
	if planet_node:
		NavigationManager.set_navigation_target(planet_node, data["display_name"])


func _set_poi_waypoint(planet_key: String, poi_node_name: String, poi_display_name: String) -> void:
	var data = planets_db[planet_key]
	var target_node = NavigationManager.find_poi_node(data["node_name"], poi_node_name)
	
	if target_node:
		NavigationManager.set_navigation_target(target_node, poi_display_name)


func _draw() -> void:
	if not visible or not main_view.visible:
		return
		
	# Draw dynamic vector orbit lines centered on the screen Orrery center
	var center = size * 0.5
	var radii = [130.0, 200.0, 270.0, 340.0, 410.0]
	var color = Color(0.25, 0.35, 0.62, 0.28) # Beautiful soft space blue
	
	for r in radii:
		# Draw a sharp circular vector outline for the planetary orbit
		draw_arc(center, r, 0.0, TAU, 96, color, 1.4, true)
