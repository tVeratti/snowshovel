extends Node


# https://github.com/binogure-studio/godot-uuid
class_name UUID


static func v4_short() -> String:
	return v4().split('-')[0]


static func v4() -> String:
	var b = _uuidbin()

	var low = '%02x%02x%02x%02x' % [b[0], b[1], b[2], b[3]]
	var mid = '%02x%02x' % [b[4], b[5]]
	var hi = '%02x%02x' % [b[6], b[7]]
	var clock = '%02x%02x' % [b[8], b[9]]
	var node = '%02x%02x%02x%02x%02x%02x' % [b[10], b[11], b[12], b[13], b[14], b[15]]

	return '%s-%s-%s-%s-%s' % [low, mid, hi, clock, node]


static func _uuidbin() -> Array:
	var b = _random_bytes(16)

	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return b


static func _random_bytes(n) -> Array:
	var r = []

	for _index in range(0, n):
		r.append(_get_random_int(256))

	return r


static func _get_random_int(max_value):
	randomize()
	return randi() % max_value
