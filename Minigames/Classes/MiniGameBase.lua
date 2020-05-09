MiniGameBase = MiniGameBase or class()
function MiniGameBase:init(parent, object)
    self._parent = parent
    self:enter(object)
end

function MiniGameBase:enter(object) end

function MiniGameBase:make_hud(type, ...)
    self._hud = MiniGames:get(type).hud_class:new(...)
end

function MiniGameBase:destroy()
    self._hud:destroy(self._completed)
    self._hud = nil
end

function MiniGameBase:update(t, dt)
	if not self._hud then
		return false
    end

	if alive(self._target_unit) and self._target_unit:unit_data()._interaction_done then
        self:cb_leave()
        return false
    end

    self._hud:update(t, dt)

    return true
end

function MiniGameBase:say(event, no_sound_chance)
	if event then
		local player = managers.player:player_unit()
		if alive(player) and player:sound() then
			if type(event) == "table" then
				local rnd = math.random(1, #event+(no_sound_chance or 2))
				if event[rnd] then
					player:sound():say(event[rnd])
				end
			else
				player:sound():say(event)
			end
		end
	end
end