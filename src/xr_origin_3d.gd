extends XROrigin3D

@export var non_xr_player: Node3D
@export var position_offset: Vector3
@export var revolver_table_mockup: ClickableArea3D
@export var revolver: Revolver
@export var revolver_speed: float = 1.0
@export var intro_state: IntroState

@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var right_hand: XRController3D = $RightHand
@onready var left_hand: XRController3D = $LeftHand

var xr_interface: XRInterface
var non_xr_camera: Camera3D
var hand: XRController3D
var hand_anchor: Node3D
var grab_revolver_right_ready: bool = false
var grab_revolver_left_ready: bool = false
var revolver_grabbed: bool = false

func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		if non_xr_player is Player:
			non_xr_camera = non_xr_player.camera
			XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, false);
			global_position = non_xr_camera.global_position
			global_position += position_offset
			#call_deferred("reset_camera")
			get_tree().create_timer(1.0).timeout.connect(reset_camera)

func reset_camera() -> void:
	position -= xr_camera.position
	rotation.y -= xr_camera.rotation.y

func _on_right_hand_area_entered(area: Area3D) -> void:
	if area == revolver_table_mockup:
		if not revolver_grabbed:
			grab_revolver_right_ready = true

func _on_right_hand_area_exited(area: Area3D) -> void:
	if area == revolver_table_mockup:
		if not revolver_grabbed:
			grab_revolver_right_ready = false

func _on_left_hand_area_entered(area: Area3D) -> void:
	if area == revolver_table_mockup:
		if not revolver_grabbed:
			grab_revolver_left_ready = true

func _on_left_hand_area_exited(area: Area3D) -> void:
	if area == revolver_table_mockup:
		if not revolver_grabbed:
			grab_revolver_left_ready = false

func _process(delta: float) -> void:
	if revolver_grabbed:
		revolver.global_position = lerp(revolver.global_position, hand_anchor.global_position, delta * revolver_speed)
		revolver.global_rotation.x = lerp_angle(revolver.global_rotation.x, hand_anchor.global_rotation.x, delta * revolver_speed)
		revolver.global_rotation.y = lerp_angle(revolver.global_rotation.y, hand_anchor.global_rotation.y, delta * revolver_speed)
		revolver.global_rotation.z = lerp_angle(revolver.global_rotation.z, hand_anchor.global_rotation.z, delta * revolver_speed)

func _grab_revolver(grabbing_hand: XRController3D):
	intro_state._on_revolver_clicked()
	grab_revolver_right_ready = false
	grab_revolver_left_ready = false
	revolver_grabbed = true
	revolver.visible = true
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


func _on_left_hand_button_pressed(_name: String) -> void:
	match _name:
		"grip_click":
			if grab_revolver_left_ready:
				_grab_revolver(left_hand)
