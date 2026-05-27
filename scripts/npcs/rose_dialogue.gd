extends RefCounted
class_name RoseDialogue

## All of Rose's dialogue lines, organized by whim × escalation × bond tier.
## Rose is vain, dramatic, and demanding — she expresses love through complaints.
## Faithful to Antoine de Saint-Exupéry's novel.


# ── Whim Dialogue ──
# Keys: whim type → escalation stage → array of lines

const WHIM_LINES := {
	"water": {
		"hint": [
			"My petals feel rather... dry today. Not that you'd notice such things.",
			"Is it my imagination, or has someone neglected their ONE simple duty?",
			"I have very particular hydration needs. But I suppose that's too complex for you.",
		],
		"demand": [
			"I require water. Now. I shouldn't have to ask.",
			"Water me this instant! A flower of MY caliber should not have to BEG.",
			"Are you deaf, or merely indifferent? WATER. NOW.",
		],
		"outburst": [
			"I am WITHERING! Right before your eyes! And you just STAND there!",
			"This is UNACCEPTABLE! Look at my petals — they're practically CRISP!",
			"Oh, I see. You WANT me to wilt. That's your plan, isn't it? How CRUEL.",
		],
		"silence": [
			"...",
		],
	},
	"dome": {
		"hint": [
			"There's a draft. I can feel it. Can't YOU feel it? Of course not.",
			"I'm quite sure I mentioned how delicate I am. The cold, you know.",
			"A civilized person would have noticed the dome was missing by now.",
		],
		"demand": [
			"Put the dome back this INSTANT! Are you trying to KILL me?",
			"The glass dome! NOW! I shall catch my death of cold!",
			"Do you have ANY idea how fragile I am? The dome! WHERE IS IT?",
		],
		"outburst": [
			"I am FREEZING! My petals will fall off one by one and it will be YOUR fault!",
			"*dramatic fake cough* You see?! I'm already ill! The dome! IMMEDIATELY!",
			"Fine! FINE! I'll just freeze. That's FINE. Don't mind ME.",
		],
		"silence": [
			"...",
		],
	},
	"baobab": {
		"hint": [
			"I think I see something growing over there. Something... unwelcome.",
			"Those little green sprouts? They're not flowers. Not even CLOSE.",
			"Is that... a baobab? On MY planet? How utterly revolting.",
		],
		"demand": [
			"Those DREADFUL baobab sprouts are back. Deal with them. At once.",
			"Pull those weeds OUT! They'll crack the entire planet if you let them grow!",
			"If you cared about me — about THIS PLANET — you'd deal with those trees.",
		],
		"outburst": [
			"The baobabs will DESTROY everything! This planet will SPLIT IN TWO!",
			"I can feel their roots ALREADY! They're suffocating me! DO SOMETHING!",
			"When this planet crumbles, just remember — I TOLD you about the baobabs!",
		],
		"silence": [
			"...",
		],
	},
	"caterpillar": {
		"hint": [
			"I thought I saw something crawling. Something with far too many legs.",
			"You don't happen to know anything about caterpillars, do you? ...Just asking.",
			"Two or three butterflies would be lovely. But first there are the CATERPILLARS.",
		],
		"demand": [
			"There are caterpillars! I am quite certain! You must do something!",
			"I refuse to be eaten alive by insects! Check the leaves! ALL of them!",
			"What if they're the ugly kind? Not the butterfly kind? CHECK!",
		],
		"outburst": [
			"CATERPILLARS! EVERYWHERE! I can practically FEEL them crawling!",
			"This is a NIGHTMARE! A beautiful flower like me, devoured by WORMS!",
			"I have only four thorns to defend myself! FOUR! And they're useless against caterpillars!",
		],
		"silence": [
			"...",
		],
	},
	"wind": {
		"hint": [
			"Is that a breeze? I detest breezes. They're so... common.",
			"My petals are extremely sensitive to drafts. Just so you know.",
			"A screen would be nice. Not that anyone ever thinks of MY comfort.",
		],
		"demand": [
			"This wind is BARBARIC! Any civilized person would have thought of a screen!",
			"Do something about this draft! I didn't choose to grow HERE, you know!",
			"I need protection from this wind! Am I not worth a simple screen?!",
		],
		"outburst": [
			"The WIND! It's DESTROYING my carefully arranged petals!",
			"I spent ALL MORNING arranging myself and now THIS! Unbelievable!",
			"Oh, just let the wind take me! You clearly don't CARE!",
		],
		"silence": [
			"...",
		],
	},
	"attention": {
		"hint": [
			"You're staring into space again. How fascinating that must be.",
			"I'm here, you know. Right HERE. In case you'd forgotten.",
			"I suppose sunsets are more interesting than I am. How humbling.",
		],
		"demand": [
			"Look at me when I'm speaking to you! Is that so much to ask?",
			"You never look at me properly. Not REALLY. You just... glance.",
			"I am the only flower on this planet and you can't even be bothered to NOTICE me!",
		],
		"outburst": [
			"FINE! Ignore me! See if I care! I was perfectly fine before you came along!",
			"I don't NEED your attention! I am magnificent ALL BY MYSELF!",
			"You know, on other planets, flowers are CHERISHED! ADORED! But here? Nothing!",
		],
		"silence": [
			"...",
		],
	},
}


# ── Fulfillment Dialogue ──
# What Rose says when a whim is fulfilled. Keys: whim → bond level ("low" or "high")

const FULFILLMENT_LINES := {
	"water": {
		"low": [
			"Finally. I was beginning to think you were completely useless.",
			"About time. Any longer and I would have dried up ENTIRELY.",
			"Hmph. The water is slightly too warm. But I suppose it will do.",
		],
		"high": [
			"...That was... acceptable. Don't look so pleased with yourself.",
			"I... Thank you. But the temperature was all wrong, naturally.",
			"...You remembered. Well. It's about time you learned SOMETHING.",
		],
	},
	"dome": {
		"low": [
			"FINALLY. I thought I would freeze to death while you dawdled.",
			"The dome. Yes. Where it SHOULD have been all along.",
		],
		"high": [
			"...Thank you. I was... it was getting quite cold.",
			"...You came quickly this time. Not that I was worried.",
		],
	},
	"baobab": {
		"low": [
			"Good. Those dreadful things are gone. For now.",
			"Was that so difficult? Honestly.",
		],
		"high": [
			"...You're getting better at that. Not GOOD. But better.",
			"...Thank you for protecting the planet. OUR planet.",
		],
	},
	"caterpillar": {
		"low": [
			"Well? Did you find any? ...You didn't even LOOK, did you?",
			"I suppose I'll just have to trust your inspection. Reluctantly.",
		],
		"high": [
			"...You checked everywhere? ...That's... rather thorough of you.",
			"If butterflies DO come, I suppose that would be... acceptable.",
		],
	},
	"wind": {
		"low": [
			"The wind has stopped? No thanks to you, I'm sure.",
			"I arranged my own petals back, thank you very much.",
		],
		"high": [
			"...The breeze isn't so bad today. Perhaps.",
			"...You stood between me and the wind. I noticed.",
		],
	},
	"attention": {
		"low": [
			"Oh, NOW you look at me. How convenient.",
			"Don't think a single glance makes up for hours of neglect.",
		],
		"high": [
			"...You're looking at me. Really looking. ...Stop it.",
			"...I suppose... it IS nice to be noticed. Occasionally.",
		],
	},
}


# ── Silence Break Lines ──
# When Rose is in silent treatment and the player interacts

const SILENCE_BREAK_LINES := [
	"...You came back.",
	"...I thought you had forgotten about me entirely.",
	"...Don't look at me like that. I'm not speaking to you.",
	"...Fine. FINE. What do you want?",
	"...I was NOT crying. Flowers don't cry. It was the dew.",
]


# ── Vulnerability Lines ──
# Rare moments at high bond when Rose's mask slips

const VULNERABILITY_LINES := [
	"You know... on some planets, flowers have thorns and no one cares for them at all.",
	"I was being rather impossible, wasn't I? ...Don't answer that.",
	"If you ever... left... I suppose I would manage. I've always managed.",
	"It's just... I have only four thorns to defend myself against the whole world.",
	"I ought not to have listened to her words. One must never listen to flowers. One must look at them and breathe in their fragrance.",
	"...I should have judged her by her actions, not her words. She cast her fragrance and her radiance over me.",
	"...You're the only one who's ever bothered with the watering can. Did you know that?",
	"Sometimes... when you're on the other side of the planet... I watch the sunset alone. It's not the same.",
]


# ── Helper Functions ──

static func get_whim_line(whim: String, stage_index: int, _bond_level: int) -> Dictionary:
	var stage_key: String
	match stage_index:
		0: stage_key = "hint"
		1: stage_key = "demand"
		2: stage_key = "outburst"
		3: stage_key = "silence"
		_: stage_key = "hint"

	if not WHIM_LINES.has(whim):
		whim = "attention"

	var lines: Array = WHIM_LINES[whim][stage_key]
	var line: String = lines[randi() % lines.size()]
	return {"speaker": "Rose", "text": line}


static func get_fulfillment_line(whim: String, bond_level: int) -> Dictionary:
	if not FULFILLMENT_LINES.has(whim):
		whim = "attention"

	var bond_key := "low" if bond_level < 50 else "high"
	var lines: Array = FULFILLMENT_LINES[whim][bond_key]
	var line: String = lines[randi() % lines.size()]
	return {"speaker": "Rose", "text": line}


static func get_silence_break() -> Dictionary:
	var line: String = SILENCE_BREAK_LINES[randi() % SILENCE_BREAK_LINES.size()]
	return {"speaker": "Rose", "text": line}


static func get_vulnerability_line() -> Dictionary:
	var line: String = VULNERABILITY_LINES[randi() % VULNERABILITY_LINES.size()]
	return {"speaker": "Rose", "text": line}
