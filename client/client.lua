local object = {}
local lastKeybind = nil
local currentDrug = nil

RegisterNetEvent("visualz_selldrugs:animation", function(networkId, type)
  if not NetworkDoesNetworkIdExist(networkId) then
    return
  end

  local config = Config.Animation[type]
  if not config.enabled then
    return
  end

  local entity = NetworkGetEntityFromNetworkId(networkId)
  lib.requestAnimDict(config.dict)

  ClearPedTasksImmediately(entity)
  ClearPedTasksImmediately(cache.ped)

  TaskTurnPedToFaceEntity(cache.ped, entity, 1000)
  TaskTurnPedToFaceEntity(entity, cache.ped, 1000)

  Wait(1000)

  if config["npc"].enabled then
    AttachProp(entity, true, type, "second")
    TaskPlayAnim(entity, config.dict, config.clip, 8.0, 8.0, Config.SellDuration / 2, 14, 0, false, false, false)
  end

  if config["player"].enabled then
    AttachProp(cache.ped, false, type, "first")
    TaskPlayAnim(cache.ped, config.dict, config.clip, 8.0, 8.0, Config.SellDuration / 2, 14, 0, false, false, false)
  end

  Wait(Config.SellDuration / 2)

  DeleteProp(cache.ped)
  DeleteProp(entity)

  if config["npc"].enabled then
    AttachProp(entity, true, type, "first")
  end

  if config["player"].enabled then
    AttachProp(cache.ped, false, type, "second")
  end

  Wait(Config.SellDuration / 2 + 250)

  DeleteProp(cache.ped)
  DeleteProp(entity)

  if config["npc"].enabled then
    ClearPedTasks(entity)
  end

  if config["player"].enabled then
    ClearPedTasks(cache.ped)
  end
end)

RegisterCommand('visualz_fixprop', function()
  for k, v in pairs(GetGamePool('CObject')) do
    if IsEntityAttachedToEntity(PlayerPedId(), v) then
      SetEntityAsMissionEntity(v, true, true)
      DeleteObject(v)
      DeleteEntity(v)
    end
  end
end)

AlertPoliceBlips = function(coords)
  local transT = 250
  local zone = GetZone(coords)
  local Blip = AddBlipForCoord(coords.x, coords.y, coords.z)

  lib.notify({
    id = 'visualz_selldrugs:callPolice',
    icon = Config.SellIcon,
    description = Config.Notify["CallPolice"](zone)
  })

  SetBlipSprite(Blip, 161)
  SetBlipHighDetail(Blip, true)
  SetBlipScale(Blip, 1.0)
  SetBlipColour(Blip, 1)
  SetBlipAlpha(Blip, transT)
  SetBlipAsShortRange(Blip, true)

  while transT ~= 0 do
    Wait(25 * 4)
    transT = transT - 1
    SetBlipAlpha(Blip, transT)
    if transT == 0 then
      SetBlipSprite(Blip, 2)
      return
    end
  end
end

function SellToPed(ped)
  local amountOfDrug = exports.ox_inventory:Search("count", currentDrug, false)
  local coords = GetEntityCoords(ped)
  local zone = GetZone(coords)

  if type(amountOfDrug) == "number" and amountOfDrug <= 0 then
    currentDrug = nil
    lib.notify({
      type = "error",
      description = Config.Notify["DontHaveDrug"](currentDrug)
    })
    return
  end

  local networkId = NetworkGetNetworkIdFromEntity(ped)
  local sellResponse = lib.callback.await("visualz_selldrugs:sellDrugs", false, networkId, currentDrug, zone)
  if sellResponse == nil then
    lib.notify({
      type = "error",
      description = "Der skete en fejl, tjek din server konsol for fejlmeddelelser"
    })
    SetPedConfigFlag(ped, 128, true)
    SetPedConfigFlag(ped, 183, true)
    SetPedFleeAttributes(ped, 15, true)
    return
  end

  lib.notify({
    type = sellResponse.type,
    description = sellResponse.description
  })

  SetPedConfigFlag(ped, 128, true)
  SetPedConfigFlag(ped, 183, true)
  SetPedFleeAttributes(ped, 15, true)
end

function AttachProp(entity, isNpc, type, firstOrSecond)
  local config = Config.Animation[type]
  local prop = isNpc and config["npc"][firstOrSecond .. "Prop"] or config["player"][firstOrSecond .. "Prop"]
  local pos = isNpc and config["npc"][firstOrSecond .. "Pos"] or config["player"][firstOrSecond .. "Pos"]
  local rot = isNpc and config["npc"][firstOrSecond .. "Rot"] or config["player"][firstOrSecond .. "Rot"]

  DeleteProp(entity)
  object[entity] = CreateObject(GetHashKey(prop), 1, 1, 1, true, true, true)
  AttachEntityToEntity(object[entity], entity, isNpc and config["npc"].propIndex or config["player"].propIndex, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
end

function DeleteProp(entity)
  if object[entity] and DoesEntityExist(object[entity]) then
    DeleteEntity(object[entity])
  end
end

local keybind = lib.addKeybind({
  name = 'visualz_selldrug',
  description = 'Sælg stof keybind',
  defaultKey = Config.SellKeybind,
  onPressed = function(self)
    local coords = GetEntityCoords(cache.ped)
    local ped = lib.getClosestPed(coords, Config.SellDistance)

    if not ped or not IsPedAbleToSell(ped) or Entity(ped).state.hasSold then
      return
    end

    SellToPed(ped)
  end,
})

function HideTextUiIfNeeded()
  local isOpen, text = lib.isTextUIOpen()
  if isOpen and text == Config.TextUI(keybind.currentKey) then
    lib.hideTextUI()
  end
end

if Config.System == "textui" then
  if lib.isTextUIOpen() then
    lib.hideTextUI()
  end
  CreateThread(function()
    while true do
      repeat
        Wait(300)

        if not currentDrug then
          Wait(600)
          do break end
        end

        local amountOfDrug = exports.ox_inventory:Search("count", currentDrug, false)
        if type(amountOfDrug) == "number" and amountOfDrug <= 0 then
          lib.notify({
            type = "info",
            description = Config.Notify["RanOutOfDrugs"](currentDrug)
          })
          currentDrug = nil
          do break end
        end

        local coords = GetEntityCoords(cache.ped)
        local ped = lib.getClosestPed(coords, Config.SellDistance)

        if not ped or not IsPedAbleToSell(ped) or Entity(ped).state.hasSold then
          HideTextUiIfNeeded()
          do break end
        end

        if lastKeybind ~= keybind.currentKey then
          if lib.isTextUIOpen() then
            lib.hideTextUI()
          end
          lastKeybind = keybind.currentKey
        end

        if not lib.isTextUIOpen() then
          lib.showTextUI(Config.TextUI(keybind.currentKey), {
            icon = Config.SellIcon,
            position = 'left-center',
          })
        end
      until true
    end
  end)
else
  if lib.isTextUIOpen() then
    lib.hideTextUI()
  end
  exports.ox_target:addGlobalPed({
    label = Config.Target(),
    icon = "fas fa-dollar-sign",
    distance = Config.SellDistance,
    canInteract = function(entity)
      if not currentDrug then
        return false
      end

      local amountOfDrug = exports.ox_inventory:Search("count", currentDrug, false)
      if type(amountOfDrug) == "number" and amountOfDrug <= 0 then
        return false
      end

      if not IsPedAbleToSell(entity) or Entity(entity).state.hasSold then
        return false
      end

      return true
    end,
    onSelect = function(data)
      SellToPed(data.entity)
    end
  })
end

function PickDrug(drug)
  if drug == nil then
    currentDrug = nil
    lib.notify({
      type = "error",
      description = Config.Notify["DrugSaleTurnedOff"]()
    })
    return
  end

  currentDrug = drug
  lib.notify({
    type = "info",
    description = "Du har valgt " .. Config.Drugs[drug].label .. " som stof"
  })
end

RegisterCommand("stof", function()
  DrugMenu()
end)

lib.addKeybind({
  name = 'Visualz_sellsystem:openMenu',
  defaultKey = Config.OpenDrugMenu,
  description = 'Åben stof menu',
  onPressed = function(self)
    DrugMenu()
  end,
})

function DrugMenu()
  local options = {}

  local drugs = {}
  for k, v in pairs(Config.Drugs) do
    table.insert(drugs, k)
  end

  local items = exports.ox_inventory:Search("count", drugs, false)


  if type(items) == "table" and TableLength(items) > 0 and not IsDrugTableEmpty(items) then
    table.insert(options, {
      title = "Stop salg",
      description = "Slår stof salg fra",
      icon = "fas fa-ban",
      onSelect = function()
        PickDrug(nil)
      end
    })
    for k, v in pairs(items) do
      if v > 0 then
        table.insert(options, {
          title = Config.Drugs[k].label .. " (" .. v .. ")",
          icon = Config.Drugs[k].icon,
          onSelect = function()
            PickDrug(k)
          end
        })
      end
    end
  elseif type(items) == "number" and items > 0 then
    table.insert(options, {
      title = "Intet stof",
      description = "Slår stof salg fra",
      icon = "fas fa-ban",
      onSelect = function()
        PickDrug(nil)
      end
    })
    table.insert(options, {
      title = Config.Drugs[drugs[1]].label .. " (" .. items .. ")",
      icon = Config.Drugs[drugs[1]].icon,
      onSelect = function()
        PickDrug(drugs[1])
      end
    })
  else
    table.insert(options, {
      description = "Ingen stoffer fundet",
      readOnly = true
    })
  end

  lib.registerContext({
    id = "visualz_selldrugs:sellDrugs",
    title = "Vælg et stof",
    options = options,
  })

  lib.showContext("visualz_selldrugs:sellDrugs")
end

RegisterNetEvent("visualz_selldrugs:callPolice", function(coords)
  AlertPoliceBlips(coords)
end)

RegisterNetEvent("visualz_selldrugs:callPoliceAnimation", function(networkId)
  if not NetworkDoesNetworkIdExist(networkId) then
    return
  end

  local entity = NetworkGetEntityFromNetworkId(networkId)

  if not DoesEntityExist(entity) then
    return
  end

  CallPoliceAnimation(entity)
end)
