--[[ RUT

    Made by seasonal(unknownsea)

]]

local time = require("timer")
local http = require("coro-http")
local json = require("json")

local rut = {
    API = {
        clientsettingscdn = "https://clientsettingscdn.roblox.com/v2/client-version/",
        deployHistory = "https://s3.amazonaws.com/setup.roblox.com/DeployHistory.txt"
    },

    Events = {},
    Functions = {}
}



--<< Functions >>--

rut.Functions.split = function(input, separator)
    if not separator then separator = "%s" end

    local out = {}
    for str in string.gmatch(input, "([^" .. separator .. "]+)") do
        table.insert(out, str)
    end

    return out
end

rut.Functions.Get = function(endpoint)
    assert(type(endpoint) == "string" or endpoint ~= "", "Invalid endpoint: must be a non-empty string.")

    local response, body = http.request("GET", endpoint)
    assert(response, "No response received from HTTP request.")
    assert(response.statusCode ~= 404, "Status 404!")

    return body or "No body content returned."
end



--<< Events >>--

function rut.Events:OnUpdate(interval, players, callback)
    assert(type(interval) == "number", "Expected number for interval, got " .. type(interval))
    assert(type(players) == "table", "Expected table for players, got " .. type(players))
    assert(type(callback) == "function", "Expected function for callback, got " .. type(callback))

    coroutine.wrap(function()
        while true do
            local file = io.open("db.json", "r"); local db = file and json.decode(file:read("*all")) or {}; if file then file:close() end

            for _, v in pairs(players) do
                local last_checked_version = db[tostring(v)] or nil; local newest = json.decode(rut.Functions.Get(rut.API.clientsettingscdn..tostring(v)))
                local unix_timestamp = os.time(); local current_time = os.date("%Y-%m-%d %H:%M:%S", unix_timestamp)

                if last_checked_version ~= newest.clientVersionUpload then
                    db[tostring(v)] = newest.clientVersionUpload
                    file = io.open("db.json", "w"); if file then file:write(json.encode(db)) file:close() end
                    callback(newest.clientVersionUpload, tostring(v), unix_timestamp, current_time, newest)
                end
                time.sleep(500)
            end

            time.sleep(tonumber(interval) * 1000)
        end
    end)()
end

function rut.Events:OnFutureUpdate(interval, callback)
    assert(type(interval) == "number", "Expected number for interval, got " .. type(interval))
    assert(type(callback) == "function", "Expected function for callback, got " .. type(callback))

    coroutine.wrap(function()
        while true do
            local entries = rut.Functions.split(rut.Functions.Get(rut.API.deployHistory), "\r\n"); local last_entry = entries[#entries]
            local file = io.open("DeployHistory.txt", "r"); local current_deployment = file and file:read("*all") or {}; if file then file:close() end
            local unix_timestamp = os.time(); local current_time = os.date("%Y-%m-%d %H:%M:%S", unix_timestamp)

            if current_deployment ~= tostring(last_entry) then
                file = io.open("DeployHistory.txt", "w"); if file then file:write(last_entry) file:close() end
                callback(last_entry, unix_timestamp, current_time)
            end

            time.sleep(500); time.sleep(tonumber(interval) * 1000)
        end
    end)()
end

return rut
