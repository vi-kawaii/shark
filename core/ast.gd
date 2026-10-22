class BlockDef:
	var name: String
	var parent: String = ""
	var props: Dictionary = {}
	var line: int = 0

class Command:
	var obj: String
	var key: String
	var op: String = "?"
	var operand: Variant = null
	var line: int = 0
