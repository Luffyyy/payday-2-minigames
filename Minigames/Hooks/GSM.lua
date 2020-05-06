MiniGameInteraction = MiniGameInteraction or class(IngamePlayerBaseState)
MiniGameInteraction.FAILED_COOLDOWN = 1
MiniGameInteraction.COMPLETED_DELAY = 0.5
MiniGameInteraction.LOCKPICK_DOF_DIST = 3

function MiniGameInteraction:init(game_state_machine)
	MiniGameInteraction.super.init(self, "ingame_special_interaction", game_state_machine)
	self._current_stage = 1
end

function MiniGameInteraction:_setup_controller()
	managers.menu:get_controller():disable()

	self._controller = managers.controller:create_controller("ingame_special_interaction", managers.controller:get_default_wrapper_index(), false)
	self._leave_cb = callback(self, self, "cb_leave")
	self._interact_cb = callback(self, self, "cb_interact")

	self._controller:add_trigger("jump", self._leave_cb)
	self._controller:add_trigger("interact", self._interact_cb)
	self._controller:set_enabled(true)
end

function MiniGameInteraction:_clear_controller()
	local menu_controller = managers.menu:get_controller()

	if menu_controller then
		menu_controller:enable()
	end

	if self._controller then
		self._controller:remove_trigger("jump", self._leave_cb)
		self._controller:remove_trigger("interact", self._interact_cb)
		self._controller:set_enabled(false)
		self._controller:destroy()

		self._controller = nil
	end
end

function MiniGameInteraction:set_controller_enabled(enabled)
	if self._controller then
		self._controller:set_enabled(enabled)
	end
end

function MiniGameInteraction:cb_leave()
	if self._completed then
		return
	end

    if self._target_unit:interaction() then
        local player = managers.player:player_unit()
        if player then
            local movement = player:movement():current_state()
            if movement._interupt_action_interact then
                movement._interact_expire_t = 0
                movement:interupt_interact()
            end
        end
    end
    game_state_machine:change_state_by_name(self._old_state)
end

function MiniGameInteraction:cb_interact()
	if self._cooldown > 0 or self._completed then
		return
	end

	self:_check_stage_complete()
	self:_check_all_complete()
end

function MiniGameInteraction:on_destroyed()
end

function MiniGameInteraction:update(t, dt)
	if not self._hud then
		return
	end

	self._hud:update(t, dt)

    if self._fail_t then
        if self._fail_t > t then
            self._hud:set_timer(self._fail_t-t)
        else
            self._hud:set_timer(0)
            self:_check_stage_complete(true)
            self:_check_all_complete()
            self._fail_t = nil
        end
    end

	if self._cooldown > 0 then
		self._cooldown = self._cooldown - dt

		if self._cooldown <= 0 then
			self._cooldown = 0

			if self._invalid_stage then
				self._hud:set_bar_valid(self._invalid_stage, true)

				self._invalid_stage = nil
                if self._tweak_data.failable then
                    self:cb_leave()
                    return
                end

				if self._tweak_data.sounds then
					self:_play_sound(self._tweak_data.sounds.circles[self._current_stage].mechanics)
				end
			end
		end
	end

	if self._completed then
		self._end_t = self._end_t - dt

		if self._end_t <= 0 then
			self._end_t = 0

			if self._target_unit:interaction() then
				local player = managers.player:player_unit()
				if player then
					local movement = player:movement():current_state()
					if movement._interupt_action_interact then
						movement._interact_expire_t = 0
						movement:_end_action_interact(t)
					end
				end
			end
            game_state_machine:change_state_by_name(self._old_state)
		end
	end

	if alive(self._target_unit) and self._target_unit:unit_data()._interaction_done then
		self._completed_by_other = true

		game_state_machine:change_state_by_name(self._old_state)
	end
end

function MiniGameInteraction:update_player_stamina(t, dt)
	local player = managers.player:player_unit()

	if player and player:movement() then
		player:movement():update_stamina(t, dt, true)
	end
end

function MiniGameInteraction:_player_damage(info)
end

function MiniGameInteraction:at_enter(old_state, interact_object)
	local player = managers.player:player_unit()

	if player then
		player:movement():current_state():interrupt_all_actions()
		--player:camera():play_redirect(PlayerStandard.IDS_UNEQUIP)
		player:base():set_enabled(true)
		player:character_damage():add_listener("MiniGameInteraction", {"hurt", "death"}, callback(self, self, "_player_damage"))
		managers.dialog:queue_dialog("player_gen_picking_lock", {
			skip_idle_check = true,
			instigator = managers.player:local_player()
		})
		SoundDevice:set_rtpc("stamina", 100)
	end

	self._sound_source = self._sound_source or SoundDevice:create_source("ingame_special_interaction")

	self._sound_source:set_position(player:position())

	self._target_unit = interact_object
	self._tweak_data = tweak_data.interaction[interact_object:interaction().tweak_data]
    self._tweak_data.number_of_circles = self._tweak_data.number_of_circles or 2

	self._tweak_data.circle_radius = self._tweak_data.circle_radius or {
		tweak_data.interaction.MINIGAME_CIRCLE_RADIUS_SMALL,
		tweak_data.interaction.MINIGAME_CIRCLE_RADIUS_MEDIUM,
		tweak_data.interaction.MINIGAME_CIRCLE_RADIUS_BIG,
		tweak_data.interaction.MINIGAME_CIRCLE_RADIUS_BIGGER,
		tweak_data.interaction.MINIGAME_CIRCLE_RADIUS_EVEN_BIGGER,
		tweak_data.interaction.MINIGAME_CIRCLE_RADIUS_WHY,
	}
	self._tweak_data.circle_difficulty = self._tweak_data.circle_difficulty or {
		0.9,
        0.93,
        0.96,
        0.97,
        0.98,
        0.98,
	}
	self._tweak_data.circle_rotation_speed = self._tweak_data.circle_rotation_speed or {
		160,
		180,
        190,
        220,
        300,
        400
	}
	self._tweak_data.circle_rotation_direction = self._tweak_data.circle_rotation_direction or {1, -1, 1, -1, 1, -1}

    if self._tweak_data.uses_timer then
        self._fail_t = TimerManager:game():time() + self._tweak_data.timer
    end

	self._cooldown = 0.1
	self._completed = false
	self._old_state = old_state:name()

	managers.hud:remove_interact()
	player:camera():set_shaker_parameter("headbob", "amplitude", 0)

	self._hud = HUDRaidWW2MiniGame:new(self._tweak_data) -- managers.hud:create_special_interaction(managers.hud:script(PlayerBase.INGAME_HUD_SAFERECT), params)
	--managers.environment_controller:set_vignette(1)
	self:_setup_controller()

	if self._tweak_data.sounds then
	--	self:_play_sound(self._tweak_data.sounds.circles[1].mechanics)
	end

	managers.hud:show(PlayerBase.PLAYER_INFO_HUD)
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	--managers.network:session():send_to_peers("enter_lockpicking_state")
end

function MiniGameInteraction:at_exit()
	self._sound_source:stop()

	if self._completed then
		--self:_play_sound(self._tweak_data.sounds.success)
		managers.dialog:queue_dialog("player_gen_lock_picked", {
			skip_idle_check = true,
			instigator = managers.player:local_player()
		})
	end

	--managers.environment_controller:set_vignette(0)
	self:_clear_controller()

	local player = managers.player:player_unit()

	if player then
		player:base():set_enabled(true)
		player:base():set_visible(true)

		player:base().skip_update_one_frame = true

		--player:camera():play_redirect(PlayerStandard.IDS_EQUIP)
		player:character_damage():remove_listener("MiniGameInteraction")
	end

	self._hud:hide(self._completed)

	if not self._completed and not self._completed_by_other and alive(self._target_unit) and self._target_unit:interaction() and self._target_unit:interaction():active() then
		--managers.hud:show_interact()
	end

    if self._tweak_data.grows_each_interaction then
        self._tweak_data.number_of_circles = math.min(self._tweak_data.number_of_circles + 1, self._tweak_data.grows_each_interaction_max, tweak_data.interaction.RAIDWW2_MAX_CIRCLES)
    end

	self._hud = nil

	managers.hud:hide(PlayerBase.PLAYER_INFO_HUD)
	managers.hud:hide(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	--managers.network:session():send_to_peers("exit_lockpicking_state")
end

function MiniGameInteraction:_check_stage_complete(fail)
	local current_stage_data, current_stage = nil

	for stage, stage_data in pairs(self._hud:circles()) do
		if not stage_data.completed then
			current_stage = stage
			current_stage_data = stage_data

			break
		end
	end

	if not current_stage then
		return
	end

	self._current_stage = current_stage
	local circle_difficulty = self._tweak_data.circle_difficulty[current_stage]
	local diff_degrees = 360 * (1 - circle_difficulty) - 3
	local circle = current_stage_data.circle._circle
	local current_rot = circle:rotation()

    if not fail and current_rot < diff_degrees then
        if self._tweak_data.uses_timer and self._tweak_data.lap_add_seconds then
            self._fail_t = math.min(self._fail_t+self._tweak_data.lap_add_seconds, TimerManager:game():time()+self._tweak_data.timer+self._tweak_data.lap_add_seconds)
        end

		self._hud:complete_stage(current_stage)

		if self._tweak_data.sounds then
			self:_play_sound(self._tweak_data.sounds.circles[current_stage].lock)

			if self._tweak_data.sounds.circles[current_stage + 1] then
				self:_play_sound(self._tweak_data.sounds.circles[current_stage + 1].mechanics, true)
			end
		end
    else
		self._hud:set_bar_valid(current_stage, false)
		circle:set_rotation(math.random() * 360)

		self._cooldown = MiniGameInteraction.FAILED_COOLDOWN
		self._invalid_stage = current_stage

		if self._tweak_data.sounds then
			self:_play_sound(self._tweak_data.sounds.failed)
			managers.dialog:queue_dialog("player_gen_lockpick_fail", {
				skip_idle_check = true,
				instigator = managers.player:local_player()
			})
		end
	end
end

function MiniGameInteraction:_check_all_complete(t, dt)
	local completed = true

	for stage, stage_data in pairs(self._hud:circles()) do
		completed = completed and stage_data.completed
	end

	self._completed = completed

	if completed then
		if self._tweak_data.sounds then
			self:_play_sound(self._tweak_data.sounds.last_circle)
		end

		self._end_t = MiniGameInteraction.COMPLETED_DELAY
	end
end

function MiniGameInteraction:_play_sound(event, no_stop)
	if event then
		if not no_stop then
			self._sound_source:stop()
		end

		self._sound_source:post_event(event)
	end
end

--I hate this class with the bane of my existence
Hooks:PostHook(GameStateMachine, "init", "MiniGamesGameStateInit", function(self)
    Gamemode.STATES.ingame_special_interaction = 'ingame_special_interaction'

    local ingame_special_interaction = MiniGameInteraction:new(self)
    local ingame_special_interaction_func = callback(nil, ingame_special_interaction, "default_transition")
    for _, state in pairs(self._states) do
        self:add_transition(state, ingame_special_interaction, callback(nil, state, "default_transition"))
        self:add_transition(ingame_special_interaction, state, ingame_special_interaction_func)
    end
end)