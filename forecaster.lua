
addon.author        = 'mug0n'
addon.desc          = 'A weather forecast addon for Ashita'
addon.link          = 'https://github.com/mug0n/forecaster'
addon.name          = 'forecaster'
addon.version       = '2.0'

require 'common'
local Weather = require('weather');
local VanaUtils = require('vanautils');

----------------------------------------------------------------------------------------------------
--  Addon variables
----------------------------------------------------------------------------------------------------
local Forecaster = {}
Forecaster.hWnd = "__forecaster_main"

function Forecaster.printToChat(zoneID, zoneName, numDays)
    local weatherData = Weather.getData(zoneID)
    if weatherData == nil then
        print(string.format("[Forecaster]: no weather data found for zone: %s (%u).", zoneName, zoneID))
        return false
    end

    local baseTime = VanaUtils.getVanaEpoch()
    local vanaTime = VanaUtils.getVanaTime()

    print(string.format("=== %s - %u Day Forecast ===", zoneName, numDays))
    for i = 0, numDays - 1, 1 do
        local daysOffset = (i * 1440)
        local forecastDate, forecastDOTW = VanaUtils.getVanaDate(vanaTime + daysOffset)
        local forecast = Weather.getWeather(weatherData, Weather.getWeatherDay(baseTime + daysOffset))

        local flatten = {}
        for _, v in ipairs(forecast) do
            table.insert(flatten, Weather.effectValueToText(v.id))
            table.insert(flatten, v.chance)
        end

        print(string.format("%s %s: " .. string.rep("%s (%u%%) ", #forecast), forecastDate, forecastDOTW, table.unpack(flatten)))
    end
end


--[[
    event: command
    desc : Event called when the addon is processing a command.
--]]
ashita.events.register("command", "forecaster_command", function (e)
    -- parse the command arguments
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/forecast')) then
        return;
    end

    -- block propagation
    e.blocked = true;

    if (#args > 1 and args[2]:any('help', '?')) then
        print("Usage: /forecast <auto-translate zone name|zone id> <length>")
        return;
    end

    -- get optional command arguments, defaults to current zone and 3 day forecast
    local zone = args[2] or AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0)
    local numDays = args[3] or 3

    -- determine the zone, input could be auto-translate string or zone id
    local zoneID, zoneName = VanaUtils.getZoneFromInput(zone)
    if (zoneID == nil) then
        print(string.format("[Forecaster]: undefined zone: %s.", zone))
        return false
    end

    -- Print to chat window
    Forecaster.printToChat(zoneID, zoneName, numDays)
end);