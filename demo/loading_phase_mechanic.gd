extends Control

var t = Timer.new()
var count = 0

func _ready():
	self.add_child(t)
	t.timeout.connect(_on_timeout)
	t.start(1)

func _on_timeout():
	if count == 2:
		SceneManager.load_percent_changed.emit(130)
		SceneManager.load_finished.emit()
		t.timeout.disconnect(_on_timeout)
	else:
		count += 1
		SceneManager.load_percent_changed.emit(100 + (count * 10) + randi_range(0, 9))
		t.start(count + 1)
