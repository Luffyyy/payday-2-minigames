function PlayerStandard:interrupt_all_actions()
	local t = TimerManager:game():time()

	self:_interupt_action_reload(t)
	self:_interupt_action_steelsight(t)
	self:_interupt_action_running(t)
	self:_interupt_action_charging_weapon(t)
	self:_interupt_action_interact(t)
	self:_interupt_action_ladder(t)
	self:_interupt_action_melee(t)
	self:_interupt_action_throw_grenade(t)
	self:_interupt_action_throw_projectile(t)
	self:_interupt_action_use_item(t)
	self:_interupt_action_cash_inspect(t)
end

Hooks:PostHook(PlayerStandard, "_start_action_interact", "MiniGamesCheckInteraction", function(self, t, input, timer, interact_object)
	if alive(interact_object) then
        local tweak = tweak_data.interaction[interact_object:interaction().tweak_data]
		if tweak and ((tweak.is_lockpicking and MiniGames.Options:GetValue("ModifyLockPicks")) or tweak.special_interaction == tweak_data.interaction.RAIDWW2) then
			game_state_machine:change_state_by_name("ingame_special_interaction", interact_object)
			self._interact_expire_t = nil
			managers.hud:hide_interaction_bar()
			interact_object:interaction():_post_event(self._unit, "sound_interupt")
		end
	end
end)