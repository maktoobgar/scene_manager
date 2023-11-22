extends Control

var t = Timer.new()
var count = 0

func _ready():
	self.add_child(t)
	t.timeout.connect(_on_timeout)
	t.start(1)

func _on_timeout():
	count += 1
	if count == 1:
		SceneManager.load_percent_changed.emit(80 + randi_range(0, 9))
	elif count == 2:
		SceneManager.load_percent_changed.emit(90 + randi_range(0, 9))
	if count == 3:
		SceneManager.load_percent_changed.emit(100)
		SceneManager.load_finished.emit()
		t.timeout.disconnect(_on_timeout)
	t.start(count + 1)
