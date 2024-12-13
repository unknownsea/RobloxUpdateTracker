local rut = require("./rut.lua")

rut.Events.OnUpdate(2.5, {"WindowsPlayer", "MacPlayer"}, function(version, player, unix, current_time, body)
    print(version.." | "..player.." | "..unix.." | "..current_time.." | "..tostring(body))
end)

rut.Events.OnFutureUpdate(2.5, function(version, unix, current_time)
	print(version.." | "..unix.." | "..current_time)
end)