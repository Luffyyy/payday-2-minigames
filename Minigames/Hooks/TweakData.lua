if not Global.game_settings then
    return
end

local Inter = tweak_data.interaction
local difficulty = Global.game_settings and Global.game_settings.difficulty or "normal"
local difficulty_index = tweak_data:difficulty_to_index(difficulty)

MiniGames.types = MiniGames.Types or {}
MiniGames.types.Raid = {
    sounds = {
        start = {"g92", "g10", "a01x_any", "g72", "p29"},
        success = {"g28", "v46", "p17"},
        halfway = {"t02x_sin"},
        fail = {"g60", "g29"},
        complete = {"v46", "v07"},
    },
    class = HUDRaidWW2MiniGame,
    circles = {
        "ui/interact_lockpick_circle_1",
        "ui/interact_lockpick_circle_2",
        "ui/interact_lockpick_circle_3",
    },
    circle_radius = {
        133,
        134,
        270,
        320,
        360,
        400,
    },
    difficulty = {
        0.9,
        0.93,
        0.94,
        0.95,
        0.96,
        0.97
    },
    speed = {
		160,
		180,
        190,
        220,
        300,
        400
    },
    failed_cooldown = 1,
    completed_delay = 0.5,
    num_of_circles = difficulty_index < 7 and 2 or 3,
    direction = {1, -1, 1, -1, 1, -1},
    max_circles = 6
}

function MiniGames:get(type)
    return self.types[type]
end

Inter.RAIDWW2 = 1

if difficulty_index == 5 then
    difficulty_index = 4
elseif difficulty_index == 6 or difficulty_index == 7 then
    difficulty_index = 5
end

local raid = MiniGames:get("Raid")

if MiniGames.Options:GetValue("ModifyLockPicks") then
    local lock_hard = Inter.pick_lock_hard
    lock_hard.failable = true
    lock_hard.number_of_circles = math.clamp(difficulty_index, 3, raid.max_circles)
end

if MiniGames.Options:GetValue("ModifyPagers") then
    local pager = Inter.corpse_alarm_pager
    pager.minigame_icon = "ui/interact_pager"
    pager.special_interaction = Inter.RAIDWW2
    pager.failable = Global.game_settings.one_down
    pager.uses_timer = 5
    pager.grows_each_interaction = true
    pager.sounds = {fail = raid.sounds.fail}

    pager.lap_add_seconds = 2
    pager.grows_each_interaction_max = math.clamp(difficulty_index, 3, 5)

    --With the increased difficulty, having 4 pagers doesn't make too much sense.
    tweak_data.player.alarm_pager.bluff_success_chance = {1,1,1,1,1,1,1,1,1,1}
end