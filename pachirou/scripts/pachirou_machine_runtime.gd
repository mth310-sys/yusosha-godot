extends Node3D
class_name PachirouMachineRuntime

enum MachineState { IDLE, ACTIVE }

var machines: Dictionary = {}

func _ready() -> void:
	call_deferred("_register_machines")

func _register_machines() -> void:
	await get_tree().process_frame
	var world := get_parent().get_node_or_null("World") as Node3D
	if world == null: return
	_collect_machines(world)

func _collect_machines(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D:
			var item := child as Node3D
			if item.has_meta("grid_cell"):
				machines[item.get_instance_id()] = {
					"root": item,
					"state": MachineState.IDLE,
					"customer": null
				}
				item.set_meta("machine_state",MachineState.IDLE)
			_collect_machines(item)

func activate_machine(machine: Node3D,customer: Node) -> bool:
	var id: int = machine.get_instance_id()
	if not machines.has(id): return false
	var data: Dictionary = machines[id]
	if data["state"] == MachineState.ACTIVE and data["customer"] != customer: return false
	data["state"] = MachineState.ACTIVE
	data["customer"] = customer
	machines[id] = data
	machine.set_meta("machine_state",MachineState.ACTIVE)
	machine.set_meta("active_customer",customer)
	return true

func deactivate_machine(machine: Node3D,customer: Node) -> void:
	var id: int = machine.get_instance_id()
	if not machines.has(id): return
	var data: Dictionary = machines[id]
	if data["customer"] != customer: return
	data["state"] = MachineState.IDLE
	data["customer"] = null
	machines[id] = data
	machine.set_meta("machine_state",MachineState.IDLE)
	machine.remove_meta("active_customer")

func is_active(machine: Node3D) -> bool:
	var id: int = machine.get_instance_id()
	if not machines.has(id): return false
	return machines[id]["state"] == MachineState.ACTIVE
