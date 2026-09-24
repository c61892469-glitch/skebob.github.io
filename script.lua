local cheats = {  
    "skebob.vip",  
    "patapim.h00k"  
}  
  
local other_cheats = {
    "onetap.com",
    "aimware.net",
    "gamesense.pub",
    "neverlose.cc",
    "iniuria.us",
    "fatality.win",
	"fanta.club",
	"primordial.dev",
	"getze.us",
	"fantasy.cat",
	"nemesis.technology",
	"mutiny.pw",
	"interwebz.cc"
}
  
local coders = {  
    "Kolo", "serge", "takedown", "Badster", "swissguy",  
    "LLama", "sharklaser", "polak", "esoteric", "Soufiw",  
    "philip", "Ducarii", "typedef", "reis"  
}  
  
local enable_chat = ui.new_checkbox("LUA", "B", "Trash talk spam")  
local last_say = 0  
local cooldown = 1  
local last_other = nil  
  
local phrases = {  
    -- Блок кодеров (6 фраз)  
    "%c? who is this? i know only %s dev",  
    "your beloved %c coded shit for you",  
    "%c's paste < %s",  
    "%c helped build %s",  
    "%s uid %d certified by %c",  
    "%c approved %s domination",  
	
    "%c couldn't handle %s",
    "%c watching %s dominate",
    "%c knows %s is better",
    "%c can't stop %s",
    "%s outclasses %c",
    "%c lost to %s tech",
    "%s makes %c look bad",
    "%c can't compete with %s",
    "%s > anything %c made",
    "%c diff vs %s diff",

    "%s breaks %c logic",
    "%c code fails vs %s",
    "%s reads %c like a book",
    "%c outdated vs %s",
    "%s smarter than %c code",
    "%c confused by %s",
    "%s bypasses %c brain",
    "%c can't predict %s",
    "%s ahead of %c",
    "%c stuck, %s evolving",

    "%s makes %c nervous",
    "%c watching and learning from %s",
    "%s too advanced for %c",
    "%c not ready for %s",
    "%s exposing %c",
    "%c can't keep up with %s",
    "%s one step ahead of %c",
    "%c lost control vs %s",
    "%s dominating %c",
    "%c vs %s = lost",

    "%s rewriting %c standards",
    "%c can't match %s quality",
    "%s better than %c ever expected",
    "%c surprised by %s",
    "%s making %c irrelevant",
    "%c can't understand %s",
    "%s breaking %c expectations",
    "%c behind, %s ahead",
    "%c sees %s and quits",

    -- Блок сравнения 
    "%s > %p",
    "%s makes %p look free",
    "%p can't handle %s",
    "%s breaks %p easily",
    "%p gets farmed by %s",
    "%s deletes %p users",
    "%p vs %s? youre already lost",
    "%s hard counters %p",
    "%p is nothing vs %s",
    "%s owns %p completely",

    "%p logic doesn't work on %s",
    "%s reads %p like open source",
    "%p code too weak for %s",
    "%s outsmarts %p",
    "%p predictable for %s",
    "%s solved %p already",
    "%p behavior known to %s",
    "%s adapts, %p stays dumb",
    "%p can't confuse %s",
    "%s already knows %p moves",

    "%s resolver > %p resolver",
    "%p desync useless vs %s",
    "%s config destroys %p",
    "%p can't hit %s",
    "%s hits, %p misses",
    "%p fails, %s connects",
    "%s sync > %p sync",
    "%p broken",
    "%s engine > %p engine",
    "%p not optimized like %s",

    "%p retired after %s release",
    "%s made %p irrelevant",
    "%p got replaced by %s",
    "%s ended %p career",
    "%p users switching to %s",
    "%s = upgrade from %p",
    "%p outdated, %s modern",
    "%s future, %p past",
    "%p belongs in museum, %s in game",
    "%s evolution, %p fossil",

    "%s diff > %p diff",
    "%s clears %p",
    "%p < %s",
    "%s gap %p",
    "%s wipes %p",
    "%p no match for %s",
    "%s too strong for %p",
    "%p can't compete with %s",
    "%p? nah, %s better",  
    "who needs %p when %s exists",  
  
    -- Основной блок (198)  
    "%s > gamesense.pub",  
    "my %s uid: %d",  
    "%s resolver is the best",  
    "%s > all",  
    "neverlose? nah, %s better",  
    "%s on top",  
    "im using %s rn",  
    "%s owns you",  
    "%s tap machine",  
    "%s never misses",  
  
    "%s private build",  
    "%s beta tester",  
    "%s dev version",  
    "%s crack? nah original",  
    "%s legit config",  
    "%s rage config loaded",  
    "%s lua > your cheat",  
    "%s prediction god",  
    "%s anti-aim breaker",  
    "%s best resolver in eu",  
  
    "%s making you cry",  
    "%s diff",  
    "%s gap",  
    "%s destroying lobby",  
    "%s carrying me",  
    "%s = free elo",  
    "%s full control",  
    "%s meta breaker",  
    "%s unstoppable",  
  
    "%s reading you like a book",  
    "%s iq check failed",  
    "%s outplaying you",  
    "%s better hvh cheat",  
    "%s never lose",  
    "%s pure skill (not really)",  
    "%s vs you = easy",  
    "%s 1v5 machine",  
    "%s clutch system",  
    "%s config too strong",  
  
    "%s sync perfect",  
    "%s resolver updated",  
    "%s new update hits hard",  
    "%s devs cooking",  
    "%s no spread exploit",  
    "%s perfect taps",  
    "%s one tap one kill",  
    "%s accuracy 100%",  
    "%s no chance for you",  
    "%s clean shots",  
  
    "%s anti-brain exploit",  
    "%s outclassed",  
    "skill issue detected",  
    "sit down",  
    "%s better player wins",  
    "%s too fast for you",  
    "%s read your moves",  
    "%s no luck needed",  
    "%s dominating",  
    "game over",  
  
    "%s uid leak: %d",  
    "%s build: private",  
    "%s version: dev",  
    "%s status: undetected",  
    "%s access: limited",  
    "%s invite only",  
    "%s internal use",  
    "%s top secret",  
    "%s alpha access",  
    "%s loaded successfully",  
  
    "%s hard carrying",  
    "%s wiping lobby",  
    "%s farming you",  
    "%s too smooth",  
    "%s aim > yours",  
    "%s diff too big",  
    "%s clean gameplay",  
    "%s no mistakes",  
    "%s perfect timing",  
    "%s fast reactions",  
  
    "%s resolver cracked",  
    "%s desync destroyed",  
    "aa useless against %s",  
    "%s reading desync",  
    "anti-aim? cute, %s better",  
    "%s breaking angles",  
    "%s hitting everything",  
    "%s no resolver needed",  
    "%s bruteforce works",  
    "%s adapting live",  
  
    "%s server domination",  
    "%s full wipe",  
    "%s free kills",  
    "%s target down",  
    "%s next?",  
    "%s easy reads",  
    "%s pressure too high",  
    "%s panic mode for you",  
    "%s tracking perfect",  
    "%s movement read",  
  
    "%s config carried",  
    "%s lua power",  
    "%s script diff",  
    "%s better setup",  
    "%s tuned perfectly",  
    "%s optimized build",  
    "%s no errors",  
    "%s stable hits",  
    "%s consistent taps",  
    "%s engine abuse",  
  
    "%s ghosting you",  
    "%s prefire king",  
    "%s wall knowledge",  
    "%s map control",  
    "%s angle master",  
    "%s peeking god",  
    "%s off-angle demon",  
    "%s timing abuse",  
    "%s reaction gap",  
    "%s prediction gap",  
  
    "%s still updating mid-game",  
    "%s live tweaking",  
    "%s dev watching rn",  
    "%s hotfix applied",  
    "%s patch working",  
    "%s build refreshed",  
    "%s new cfg loaded",  
    "%s runtime changes",  
    "%s adapting config",  
    "%s instant fix",  
  
    "%s not for public",  
    "%s too exclusive",  
    "%s access denied",  
    "%s invite only still",  
    "%s you can't get this",  
    "%s hidden features",  
    "%s locked functions",  
    "%s private modules",  
    "%s internal tools",  
    "%s dev privileges",  
  
    "%s skill amplification",  
    "%s aim assist++",  
    "%s humanized aim",  
    "%s legit looking",  
    "%s rage but clean",  
    "%s hybrid playstyle",  
    "%s smart targeting",  
    "%s priority system",  
    "%s auto adaptation",  
    "%s dynamic resolver",  
  
    "%s breaking your cfg",  
    "%s countering you",  
    "%s anti-you enabled",  
    "%s reading patterns",  
    "predictable enemy",  
    "too obvious",  
    "same mistake again",  
    "learn to play",  
    "try harder",  
    "not even close",  
  
    "%s kill confirmed",  
    "%s target eliminated",  
    "erased",  
    "deleted",  
    "removed",  
    "wiped",  
    "no survivors",  
    "%s full reset",  
    "next round same",  
    "repeat",  
  
    "%s peak performance",  
    "%s max settings",  
    "%s full power",  
    "%s limit reached",  
    "%s system stable",  
    "%s no overheating",  
    "%s optimal state",  
    "%s running smooth",  
    "%s everything synced",  
    "%s perfect run",  
  
    "%s is just built different",  
    "imagine not using %s in 2026",  
    "brain gap",  
    "%s defensive aa breaker",  
    "stop crying, get %s",  
    "your aa is %s food",  
	"%s never misses",  
	"patapimless",  
	"skebobless"
}  

local function get_random_cheat() return cheats[math.random(1, #cheats)] end  
local function get_random_other_cheat()  
    local pick  
    repeat pick = other_cheats[math.random(1, #other_cheats)] until pick ~= last_other  
    last_other = pick  
    return pick  
end  
local function get_random_coder() return coders[math.random(1, #coders)] end  
local function get_random_uid() return math.random(42, 67) end  
local function get_random_phrase() return phrases[math.random(1, #phrases)] end  
  
local function build_message()  
    local cheat, other, coder, uid = get_random_cheat(), get_random_other_cheat(), get_random_coder(), tostring(get_random_uid())  
    local phrase = get_random_phrase()  
    phrase = phrase:gsub("%%s", cheat):gsub("%%p", other):gsub("%%c", coder):gsub("%%d", uid)  
    return phrase  
end  
  
client.set_event_callback("player_death", function(e)  
    if not ui.get(enable_chat) then return end  
    local lp = entity.get_local_player()  
    local attacker, victim = client.userid_to_entindex(e.attacker), client.userid_to_entindex(e.userid)  
    if not attacker or not victim or attacker ~= lp or victim == lp then return end  
    local cur = globals.curtime()  
    if cur - last_say < cooldown then return end  
    client.exec("say " .. build_message())  
    last_say = cur  
end)  
