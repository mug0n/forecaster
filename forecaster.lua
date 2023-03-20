addon.author        = "mug0n"
addon.desc          = "A weather forecast addon for Ashita v4"
addon.link          = "https://github.com/mug0n/forecaster"
addon.name          = "forecaster"
addon.version       = "2.0"


require("common")
local Weather = require("weather")
local VanaUtils = require("vanautils")
local imgui = require("imgui")

function imgui.TextAlignRight(text)
    local x, _ = imgui.CalcTextSize(text)
    local cursorPosX = imgui.GetCursorPosX()
    imgui.SetCursorPosX(math.max(cursorPosX, cursorPosX + imgui.GetContentRegionAvail() - x))
    imgui.Text(text)
end


-- Addon variables
local Forecaster = {}
Forecaster.hWnd = "Forecaster"
Forecaster.maxWidth = 320
Forecaster.defaultLength = 3


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
    local args = e.command:args()
    if (#args == 0 or not args[1]:any("/forecast")) then
        return
    end

    -- block propagation
    e.blocked = true

    if (#args > 1 and args[2]:any("help", "?")) then
        print("Usage: /forecast <auto-translate zone name|zone id> <length>")
        return
    end

    -- get optional command arguments, defaults to current zone and 3 day forecast
    local zone = args[2] or AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0)
    local numDays = args[3] or Forecaster.defaultLength

    -- determine the zone, input could be auto-translate string or zone id
    local zoneID, zoneName = VanaUtils.getZoneByInput(zone)
    if (zoneID == nil) then
        print(string.format("[Forecaster]: undefined zone: %s.", zone))
        return false
    end

    -- Print to chat window
    Forecaster.printToChat(zoneID, zoneName, numDays)
end)


--[[
    event: command
    desc : Event called when the addon is processing a command.
--]]
ashita.events.register("d3d_present", "forecaster_present", function ()
    -- get current zone information
    local zoneID, zoneName = VanaUtils.getZoneByID(AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0))

    -- get weather data
    local weatherData = Weather.getData(zoneID)
    if weatherData == nil then
        return
    end

    local baseTime = VanaUtils.getVanaEpoch()
    local vanaTime = VanaUtils.getVanaTime()

    -- init imgui
    imgui.SetNextWindowBgAlpha(0.8)
    imgui.SetNextWindowSize({ Forecaster.maxWidth, -1, }, ImGuiCond_Always)

    if (imgui.Begin(Forecaster.hWnd, true,
        bit.bor(
            ImGuiWindowFlags_NoDecoration,
            ImGuiWindowFlags_AlwaysAutoResize,
            ImGuiWindowFlags_NoFocusOnAppearing,
            ImGuiWindowFlags_NoNav ))
    ) then
        -- caption text
        imgui.Text("[")
        imgui.SameLine()
        imgui.TextColored({ 0.462, 0.647, 0.756, 1.0 }, addon.name)
        imgui.SameLine()
        imgui.Text("]")
        imgui.SameLine()
        imgui.TextAlignRight(zoneName)

        -- 2 columns, forecast for today and tomorrow
        local columnWidth = imgui.GetWindowWidth() / 2 - imgui.GetStyle().FramePadding.x
        imgui.Columns(2)
        imgui.Separator()

        for k, v in pairs({ "Today", "Tomorrow" }) do
            local daysOffset = ((k - 1) * 1440)
            local _, forecastDOTW = VanaUtils.getVanaDate(vanaTime + daysOffset)
            local forecast = Weather.getWeather(weatherData, Weather.getWeatherDay(baseTime + daysOffset))

            -- header which consist of the day indicator and day of the week
            imgui.SetColumnWidth(-1, columnWidth)
            imgui.Text(v)
            imgui.SameLine()
            imgui.TextAlignRight(forecastDOTW)

            -- forecast rows
            for fk, fv in ipairs(forecast) do
                imgui.Text(Weather.effectValueToText(fv.id))
                imgui.SameLine()
                imgui.TextAlignRight(string.format("%d", fv.chance) .. "%%")
            end

            imgui.NextColumn()
        end
    end

    imgui.End()
end)