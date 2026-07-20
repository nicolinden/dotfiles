-- Persoonlijke systeemacties. Deze toetsen gebruiken Ctrl + Option + Command
-- zodat ze niet botsen met de Alt/Option-sneltoetsen van AeroSpace.
local modifiers = { "ctrl", "alt", "cmd" }

local function confirm(title, message, action_label, action)
  local choice = hs.dialog.blockAlert(title, message, "Annuleer", action_label, "critical")
  if choice == action_label then
    action()
  end
end

local function toggle_wifi()
  local details = hs.wifi.interfaceDetails()
  if not details then
    hs.alert.show("Geen wifi-interface gevonden")
    return
  end

  local enabled = not details.power
  local success, error_message = hs.wifi.setPower(enabled)
  if success then
    hs.alert.show(enabled and "Wifi aan" or "Wifi uit")
  else
    hs.alert.show("Wifi wijzigen mislukt" .. (error_message and (": " .. error_message) or ""))
  end
end

hs.hotkey.bind(modifiers, "L", "Vergrendel scherm", hs.caffeinate.lockScreen)
hs.hotkey.bind(modifiers, "S", "Slaapstand", hs.caffeinate.systemSleep)
hs.hotkey.bind(modifiers, "W", "Wifi wisselen", toggle_wifi)

hs.hotkey.bind(modifiers, "R", "Herstart Mac", function()
  confirm("Mac herstarten?", "Niet-opgeslagen werk kan verloren gaan.", "Herstart", hs.caffeinate.restartSystem)
end)

hs.hotkey.bind(modifiers, "Q", "Log uit", function()
  confirm("Uitloggen?", "Niet-opgeslagen werk kan verloren gaan.", "Log uit", hs.caffeinate.logOut)
end)
