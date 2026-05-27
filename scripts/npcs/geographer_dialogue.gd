extends Node
class_name GeographerDialogue

## GeographerDialogue — Static arrays containing the Geographer's dialogues and narrative cues.

# ── Greeting & Quest Start ──
static var greeting: Array = [
	{"speaker": "Geographer", "text": "Ah! Look! An explorer! An explorer has arrived!"},
	{"speaker": "Prince", "text": "Hello, sir. What is that huge book you are writing in?"},
	{"speaker": "Geographer", "text": "I am a Geographer. I write down the geography of the stars and planets! It is the most important profession in the cosmos."},
	{"speaker": "Prince", "text": "How interesting! Does your planet have oceans, mountains, or volcanoes?"},
	{"speaker": "Geographer", "text": "Alas, I have absolutely no idea! I do not leave my desk. A geographer is far too important to go wandering about!"},
	{"speaker": "Geographer", "text": "But you! You are a traveler! You have a golden biplane! Will you be my explorer?"},
	{"speaker": "Geographer", "text": "Fly to the other planets: B-612, the Desert, the King's planet, and the Lamplighter's planet."},
	{"speaker": "Geographer", "text": "Find the glowing Memory Anchors on each planet, record their geological features, and bring the surveys back to me!"}
]

# ── Quest In Progress (Less than 4 surveys) ──
static var quest_reminder: Array = [
	{"speaker": "Geographer", "text": "How goes your exploration, my brave explorer?"},
	{"speaker": "Geographer", "text": "You must record surveys from four planets: B-612, the Desert, the King's planet, and the Lamplighter's planet."},
	{"speaker": "Geographer", "text": "Come back once you have found the glowing Memory Anchor on each of them! (Surveys recorded: {count}/4)"}
]

# ── Quest Complete Climax ──
static var quest_success: Array = [
	{"speaker": "Geographer", "text": "Wonderful! Magnificent! You have returned with the geographical records!"},
	{"speaker": "Geographer", "text": "Let us record these facts in my eternal ledger..."},
	{"speaker": "Geographer", "text": "On B-612: Two active volcanoes, one extinct. A tidy home! And... wait, a flower?"},
	{"speaker": "Geographer", "text": "We do not record flowers, for they are ephemeral."},
	{"speaker": "Prince", "text": "Ephemeral? What does 'ephemeral' mean?"},
	{"speaker": "Geographer", "text": "It means: 'which is threatened by speedy disappearance'."},
	{"speaker": "Prince", "text": "My flower is ephemeral! And she has only four thorns to defend herself against the world!"},
	{"speaker": "Prince", "text": "And I have left her all alone on my planet..."}
]

# ── Farewell (sending the Prince to Earth) ──
static var farewell: Array = [
	{"speaker": "Geographer", "text": "Do not worry, young Prince. To recognize your love is the beginning of wisdom."},
	{"speaker": "Geographer", "text": "Where should you go now? I advise you to visit the planet Earth. It has a high reputation..."},
	{"speaker": "Geographer", "text": "Return to your golden plane when you are ready. Your great cosmic journey has taught you what truly matters!"},
	{"speaker": "Narrator", "text": "You have completed the Geographer's Quest! You now understand the value of your beloved Rose."}
]

# ── Repeated Visit Post-Quest ──
static var post_complete: Array = [
	{"speaker": "Geographer", "text": "Ah, my great explorer! The books I write are eternal, but the explorer's memories are even more precious."},
	{"speaker": "Geographer", "text": "Fly safe, little Prince. The planet Earth awaits you!"}
]
