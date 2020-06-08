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

Hooks:PostHook(PlayerStandard, "_start_action_interact", "RaidMinigameCheckInteraction", function(self, t, input, timer, object)
	if alive(object) then
		local name = object:interaction().tweak_data
		local tweak = tweak_data.interaction[name]
		if name ~= "open_door_with_keys" then -- Crashes & is not really lockpicking in the same sense.
			if tweak and ((tweak.is_lockpicking and RaidMinigame.Options:GetValue("ModifyLockpicks")) or tweak.special_interaction == "raid") then
				game_state_machine:change_state_by_name("ingame_special_interaction", {object = object, type = tweak.special_interaction or "raid"})
				self._interact_expire_t = nil
				managers.hud:hide_interaction_bar()
				object:interaction():_post_event(self._unit, "sound_interupt")
			end
		end
	end
end)