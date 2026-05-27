extends Node

## KingDialogue — All dialogue for the King, organized by puzzle state.
##
## The King speaks in royal decrees and commands.
## 3 puzzle stages + farewell. No gates — progression-based.

class_name KingDialogue


# ── Greeting (first meeting) ──

static var greeting: Array = [
	{"speaker": "King", "text": "Ah! A subject approaches!"},
	{"speaker": "King", "text": "I am the King. All that you see obeys me."},
	{"speaker": "King", "text": "The stars, the planets, even the sunset — all mine to command."},
	{"speaker": "King", "text": "Now then. Let us begin with a simple decree..."},
]


# ── Order 1: Sit ──

static var order_sit: Array = [
	{"speaker": "King", "text": "I order you to sit before your King!"},
	{"speaker": "King", "text": "Press C to sit. A good subject knows when to rest in the royal presence."},
]

static var sit_success: Array = [
	{"speaker": "King", "text": "Excellent! You obey well."},
	{"speaker": "King", "text": "It is important to give orders that can be obeyed."},
	{"speaker": "King", "text": "Now... I have revealed a fallen star on my planet. Fetch it for me!"},
]


# ── Order 2: Bring the star ──

static var order_star: Array = [
	{"speaker": "King", "text": "I order you to bring me that fallen star."},
	{"speaker": "King", "text": "It appeared by my royal decree. Find it on my planet and bring it to me."},
]

static var star_success: Array = [
	{"speaker": "King", "text": "Magnificent! A star, brought to me by royal command!"},
	{"speaker": "King", "text": "You see? The universe bends to my will."},
	{"speaker": "King", "text": "Now for my grandest decree... go to the glowing circle on my planet."},
]


# ── Order 3: Sunset ──

static var order_sunset: Array = [
	{"speaker": "King", "text": "For my final and grandest decree..."},
	{"speaker": "King", "text": "I order the sun to set!"},
	{"speaker": "King", "text": "Go stand on the glowing circle and witness my power over the heavens."},
	{"speaker": "King", "text": "...I shall give the order at the right moment, of course."},
]

static var sunset_success: Array = [
	{"speaker": "King", "text": "You see?! The sun has obeyed!"},
	{"speaker": "King", "text": "I gave the order at precisely the right time. That is the secret."},
]

static var sunset_reminder: Array = [
	{"speaker": "King", "text": "Go stand on the glowing circle. The sunset awaits my command."},
	{"speaker": "King", "text": "You must be patient. Even a King must wait for the right moment."},
]


# ── Farewell (all puzzles complete) ──

static var farewell: Array = [
	{"speaker": "King", "text": "You have obeyed all my decrees. Most impressive."},
	{"speaker": "King", "text": "I hereby appoint you... Ambassador!"},
	{"speaker": "King", "text": "Go forth and represent my kingdom among the stars."},
	{"speaker": "King", "text": "I order you to travel well."},
	{"speaker": "King", "text": "...That is an order you can certainly obey."},
]


# ── Repeat visit after completion ──

static var post_complete: Array = [
	{"speaker": "King", "text": "Ah, my Ambassador returns! How are my other planets?"},
	{"speaker": "King", "text": "I trust everything is in order. As I have ordered it."},
]

static var post_complete_alt: Array = [
	{"speaker": "King", "text": "Remember: a good King only gives orders that can be obeyed."},
	{"speaker": "King", "text": "That is the most important thing I can teach you."},
]


## Get a random post-complete line set.
static func get_post_complete() -> Array:
	if randf() < 0.5:
		return post_complete
	return post_complete_alt
