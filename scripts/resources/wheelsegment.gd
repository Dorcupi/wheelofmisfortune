extends Resource
class_name WheelSegment
## A segment of the wheel which adds a random effect to the total amount of money.

@export var texture: Texture2D
## The texture of the wheel segment.
@export var static_add_modifier: float = 0
## A modifier to add (or subtract with negatives) onto the final return.
@export var static_multiply_modifier: float = 1
## A modifier to multiply (or divide with fractions) onto the final return.
@export var rarity: int = 1
## How rare/powerful is the wheel segment.

func add_modifier(old_score: float) -> float:
	var new_score: float = old_score
	new_score += static_add_modifier
	new_score = new_score * static_multiply_modifier
	return new_score

func generate_message() -> String:
	var add_string: String = ""
	var multiply_string: String = ""
	var final_string: String = ""
	if static_add_modifier != 0:
		add_string = "%+.2f" % static_add_modifier
	if static_multiply_modifier != 1:
		if -1 < static_multiply_modifier and static_multiply_modifier < 1 and static_multiply_modifier != 0:
			var division_number: float = 1 / static_multiply_modifier
			multiply_string = "/%.2f" % division_number
		else:
			multiply_string = "*%.2f" % static_multiply_modifier
	if add_string == "" and multiply_string == "":
		final_string = "+0"
	else:
		if add_string != "" and multiply_string != "":
			final_string = add_string + " " + multiply_string
		elif add_string != "" and multiply_string == "":
			final_string = add_string
		else:
			final_string = multiply_string
	return final_string

func generate_update(old_score: float) -> ScoreUpdate:
	var updated_score: ScoreUpdate = ScoreUpdate.new()
	var new_score: float = add_modifier(old_score)
	var message: String = generate_message()
	var is_benefitial: bool = false
	var benefitial_determiner: float = new_score - old_score
	if benefitial_determiner >= 0:
		is_benefitial = true
	updated_score.new_score = new_score
	updated_score.message = message
	updated_score.is_benefitial = is_benefitial
	return updated_score
