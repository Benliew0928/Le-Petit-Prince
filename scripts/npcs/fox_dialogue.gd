extends Node

## FoxDialogue — All dialogue for the Fox, organized by bond stage.
##
## Stage 0: Stranger — Fox says nothing, just watches.
## Stage 1: Curious — Short, wary observations.
## Stage 2: Familiar — Recognizes the routine, hints at bond.
## Stage 3: Friend — Speaks of responsibility and taming.
## Stage 4: Tamed — The famous farewell speech.

class_name FoxDialogue


# ── Stage-based approach lines (when fox first notices player sitting) ──

static var approach_lines: Dictionary = {
	0: [
		{"speaker": "???", "text": "..."},
		{"speaker": "???", "text": "(The creature watches you from afar, ears twitching.)"},
	],
	1: [
		{"speaker": "Fox", "text": "What are you? You don't smell like anything from here."},
		{"speaker": "Fox", "text": "Why do you just... sit there?"},
		{"speaker": "Fox", "text": "You are strange. But at least you are quiet."},
	],
	2: [
		{"speaker": "Fox", "text": "Oh, it's you again. You came at the same time..."},
		{"speaker": "Fox", "text": "I like that you come at the same hour. I can prepare my heart."},
		{"speaker": "Fox", "text": "If you come at four, I shall begin to be happy at three."},
	],
	3: [
		{"speaker": "Fox", "text": "You are becoming responsible, you know. For what you have tamed."},
		{"speaker": "Fox", "text": "My life is monotonous. But if you tame me, it will be as if the sun came to shine on my life."},
		{"speaker": "Fox", "text": "I shall know the sound of a step that will be different from all the others."},
	],
	4: [
		{"speaker": "Fox", "text": "Go and look again at the roses. You will understand that yours is unique in all the world."},
	],
}


# ── Flee reactions (when player gets too close too fast) ──

static var flee_lines: Array = [
	{"speaker": "", "text": "(The fox darts away in a flash of russet fur.)"},
	{"speaker": "", "text": "(Too close! The fox vanishes behind the rocks.)"},
	{"speaker": "", "text": "(The fox bolts. You moved too quickly.)"},
	{"speaker": "", "text": "(A blur of orange — the fox is gone.)"},
]


# ── Patience progress lines (shown while sitting) ──

static var patience_lines: Dictionary = {
	0: [
		{"speaker": "", "text": "(The fox watches you from the distance, unmoving.)"},
	],
	1: [
		{"speaker": "", "text": "(The fox tilts its head, curious.)"},
		{"speaker": "", "text": "(It takes a cautious step forward... then stops.)"},
	],
	2: [
		{"speaker": "", "text": "(The fox sits down a few paces away.)"},
		{"speaker": "", "text": "(It seems more relaxed today.)"},
	],
	3: [
		{"speaker": "", "text": "(The fox approaches and sits beside you.)"},
		{"speaker": "", "text": "(You can feel its warmth nearby.)"},
	],
}


# ── Taming complete — the farewell speech ──

static var farewell_speech: Array = [
	{"speaker": "Fox", "text": "And now here is my secret, a very simple secret:"},
	{"speaker": "Fox", "text": "It is only with the heart that one can see rightly;"},
	{"speaker": "Fox", "text": "what is essential is invisible to the eye."},
	{"speaker": "Fox", "text": "..."},
	{"speaker": "Fox", "text": "It is the time you have wasted for your rose that makes your rose so important."},
	{"speaker": "Fox", "text": "You become responsible, forever, for what you have tamed."},
	{"speaker": "Fox", "text": "You are responsible for your rose..."},
]


# ── Tamed idle lines (after taming, random chat) ──

static var tamed_lines: Array = [
	{"speaker": "Fox", "text": "The wheat fields mean nothing to me. But you have golden hair..."},
	{"speaker": "Fox", "text": "So the wheat fields will remind me of you. And I shall love the sound of the wind in the wheat."},
	{"speaker": "Fox", "text": "One only understands the things that one tames."},
	{"speaker": "Fox", "text": "Words are the source of misunderstandings."},
	{"speaker": "Fox", "text": "What makes the desert beautiful is that somewhere it hides a well."},
]


## Get a random approach line for the current stage.
static func get_approach_line(stage: int) -> Dictionary:
	var lines: Array = approach_lines.get(stage, approach_lines[0])
	return lines[randi() % lines.size()]


## Get a random flee reaction.
static func get_flee_line() -> Dictionary:
	return flee_lines[randi() % flee_lines.size()]


## Get a patience progress line for the current stage.
static func get_patience_line(stage: int) -> Dictionary:
	var lines: Array = patience_lines.get(stage, patience_lines[0])
	return lines[randi() % lines.size()]


## Get a random tamed idle line.
static func get_tamed_line() -> Dictionary:
	return tamed_lines[randi() % tamed_lines.size()]
