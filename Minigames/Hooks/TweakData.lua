local Inter = tweak_data.interaction

Inter.rww2_circles = {
    "ui/interact_lockpick_circle_1",
    "ui/interact_lockpick_circle_2",
    "ui/interact_lockpick_circle_3",
}

Inter.MINIGAME_CIRCLE_RADIUS_SMALL = 133
Inter.MINIGAME_CIRCLE_RADIUS_MEDIUM = 134
Inter.MINIGAME_CIRCLE_RADIUS_BIG = 270
Inter.MINIGAME_CIRCLE_RADIUS_BIGGER = 320
Inter.MINIGAME_CIRCLE_RADIUS_EVEN_BIGGER = 360
Inter.MINIGAME_CIRCLE_RADIUS_WHY = 400

Inter.RAIDWW2 = 1
Inter.RAIDWW2_MAX_CIRCLES = 6



if difficulty_index == 5 then
    difficulty_index = 4
elseif difficulty_index == 6 or difficulty_index == 7 then
    difficulty_index = 5
end

if MiniGames.Options:GetValue("ModifyLockPicks") then
    local lock_hard = Inter.pick_lock_hard
    lock_hard.failable = true
    lock_hard.number_of_circles = math.clamp(difficulty_index, 3, Inter.RAIDWW2_MAX_CIRCLES)
end

if MiniGames.Options:GetValue("ModifyPagers") then
    local pager = Inter.corpse_alarm_pager
    --pager.minigame_icon = "ui/interact_pager"
    pager.special_interaction = Inter.RAIDWW2
    pager.failable = true
    pager.uses_timer = true
    pager.grows_each_interaction = true

    pager.lap_add_seconds = 5
    pager.grows_each_interaction_max = math.clamp(difficulty_index, 3, Inter.RAIDWW2_MAX_CIRCLES)

    --With the increased difficulty, having 4 pagers doesn't make too much sense.
    tweak_data.player.alarm_pager.bluff_success_chance = {1,1,1,1,1,1,1,1,1,1}
end