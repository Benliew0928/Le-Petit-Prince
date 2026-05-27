extends Node
class_name GeographyQuest

## GeographyQuest — Static helper class to manage the Geographer's planet-survey quest.

static var is_quest_active: bool = false
static var recorded_surveys: Dictionary = {
	"b612": false,
	"desert": false,
	"king": false,
	"lamplighter": false
}

static func get_recorded_count() -> int:
	var count: int = 0
	for key in recorded_surveys:
		if recorded_surveys[key]:
			count += 1
	return count

static func is_complete() -> bool:
	return get_recorded_count() == 4
