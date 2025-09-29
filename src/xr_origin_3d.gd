extends XROrigin3D

@export var player: Player
@export var position_offset: Vector3
@export var revolver_table_mockup: ClickableArea3D
@export var revolver_speed: float = 1.0
@export var state_machine: StateMachine
@export var world_scale_override: float = 4.8

@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var right_hand: XRController3D = $RightHand
@onready var left_hand: XRController3D = $LeftHand
@onready var right_hand_area: Area3D = $RightHand/Area3D
@onready var left_hand_area: Area3D = $LeftHand/Area3D

var xr_interface: XRInterface
var non_xr_camera: Camera3D
var hand: XRController3D
var hand_anchor: Node3D
var grab_revolver_right_ready: bool = false
var grab_revolver_left_ready: bool = false
var revolver_grabbed: bool = false

func _ready() -> void:
	# world_scale sometimes is 1.0 for some reason...
	world_scale = world_scale_override
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		if player is Player:
			non_xr_camera = player.camera
			XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, false);
		if xr_interface is OpenXRInterface:
			xr_interface.pose_recentered.connect(reset_camera)

func reset_camera() -> void:
	global_rotation.y -= xr_camera.global_rotation.y
	global_position = non_xr_camera.global_position
	global_position += position_offset - xr_camera.position

func _on_right_hand_area_entered(area: Area3D) -> void:
	if area is RevolverTableMockup:
		if not revolver_grabbed:
			if not grab_revolver_left_ready:
				area.emit_signal("mouse_entered")
			grab_revolver_right_ready = true
	elif area is Patron:
		if revolver_grabbed:
			area.interact_area_3d.emit_signal("mouse_entered")

func _on_right_hand_area_exited(area: Area3D) -> void:
	if area is RevolverTableMockup:
		if not revolver_grabbed:
			if not grab_revolver_left_ready:
				area.emit_signal("mouse_exited")
			grab_revolver_right_ready = false
	elif area is Patron:
		if revolver_grabbed:
			area.interact_area_3d.emit_signal("mouse_exited")

func _on_left_hand_area_entered(area: Area3D) -> void:
	if area is RevolverTableMockup:
		if not revolver_grabbed:
			if not grab_revolver_right_ready:
				area.emit_signal("mouse_entered")
			grab_revolver_left_ready = true
	elif area is Patron:
		if revolver_grabbed:
			area.interact_area_3d.emit_signal("mouse_entered")

func _on_left_hand_area_exited(area: Area3D) -> void:
	if area is RevolverTableMockup:
		if not revolver_grabbed:
			if not grab_revolver_right_ready:
				area.emit_signal("mouse_exited")
			grab_revolver_left_ready = false
	elif area is Patron:
		if revolver_grabbed:
			area.interact_area_3d.emit_signal("mouse_exited")

func _process(delta: float) -> void:
	if revolver_grabbed:
		player.revolver.global_position = lerp(player.revolver.global_position, hand_anchor.global_position, delta * revolver_speed)
		player.revolver.global_rotation.x = lerp_angle(player.revolver.global_rotation.x, hand_anchor.global_rotation.x, delta * revolver_speed)
		player.revolver.global_rotation.y = lerp_angle(player.revolver.global_rotation.y, hand_anchor.global_rotation.y, delta * revolver_speed)
		player.revolver.global_rotation.z = lerp_angle(player.revolver.global_rotation.z, hand_anchor.global_rotation.z, delta * revolver_speed)

func _grab_revolver(grabbing_hand: XRController3D):
	revolver_table_mockup.emit_signal("clicked")
	grab_revolver_right_ready = false
	grab_revolver_left_ready = false
	revolver_grabbed = true
	hand = grabbing_hand
	hand_anchor = hand.get_node("Area3D")
	var geometry: Node3D = grabbing_hand.get_node("Area3D/CSGBox3D")
	if geometry != null:
		geometry.visible = false

func _on_right_hand_button_pressed(_name: String) -> void:
	match _name:
		"grip_click":
			if grab_revolver_right_ready:
				_grab_revolver(right_hand)
				right_hand_area.monitorable = false
				right_hand_area.monitoring = false
		"ax_button":
			if hand == right_hand:
				player.revolver_interact_area.emit_signal("clicked")


func _on_left_hand_button_pressed(_name: String) -> void:
	match _name:
		"grip_click":
			if grab_revolver_left_ready:
				_grab_revolver(left_hand)
				left_hand_area.monitorable = false
				left_hand_area.monitoring = false
		"ax_button":
			if hand == left_hand:
				player.revolver_interact_area.emit_signal("clicked")
