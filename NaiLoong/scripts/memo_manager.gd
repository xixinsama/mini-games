extends Node
## MemoManager - Memo CRUD with JSON file persistence

const MEMO_PATH = "user://memos.json"

signal memo_updated()
signal reminder_due(memo: Dictionary)

var memos: Array = []

func _ready() -> void:
	_load_memos()

func _load_memos() -> void:
	var file = FileAccess.open(MEMO_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		var error = json.parse(text)
		if error == OK:
			var data = json.get_data()
			if data and data.has("memos"):
				memos = data["memos"]
				print("Loaded %d memos" % memos.size())
		else:
			push_error("Failed to parse memos.json: " + json.get_error_message())
			memos = []
	else:
		print("No memos file found, starting fresh")
		memos = []

func _save_memos() -> void:
	var data = {"memos": memos}
	var file = FileAccess.open(MEMO_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "	"))
		file.close()
		print("Memos saved")
	else:
		push_error("Failed to save memos: " + str(FileAccess.get_open_error()))

func clear_all_memos() -> void:
	memos.clear()
	_save_memos()
	memo_updated.emit()

func add_memo(content: String, deadline: String = "") -> Dictionary:
	var memo = {
		"id": str(Time.get_unix_time_from_system()) + "_" + str(randi()),
		"content": content,
		"deadline": deadline,
		"created_at": Time.get_datetime_string_from_system(),
		"pinned": false,
		"reminded": false
	}
	memos.append(memo)
	_save_memos()
	memo_updated.emit()
	return memo

func update_memo(id: String, fields: Dictionary) -> void:
	for i in range(memos.size()):
		if memos[i]["id"] == id:
			for key in fields:
				memos[i][key] = fields[key]
			_save_memos()
			memo_updated.emit()
			return

func delete_memo(id: String) -> void:
	for i in range(memos.size() - 1, -1, -1):
		if memos[i]["id"] == id:
			memos.remove_at(i)
			_save_memos()
			memo_updated.emit()
			return

func get_all_memos() -> Array:
	return memos.duplicate()

func get_expired_reminders() -> Array:
	var expired = []
	var now = Time.get_datetime_string_from_system()
	for memo in memos:
		if memo.get("reminded", false):
			continue
		if memo.has("deadline") and memo["deadline"] is String and not memo["deadline"].is_empty():
			if memo["deadline"] <= now:
				memo["reminded"] = true
				_save_memos()
				expired.append(memo)
				reminder_due.emit(memo)
	return expired
