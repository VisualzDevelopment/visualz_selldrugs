local object = {}
local closestPed = nil
local currentDrug = nil
local textUiLabel =

    RegisterNetEvent("visualz_drugSystem:sellProgress", function(networkId)
      local entity = NetworkGetEntityFromNetworkId(networkId)
      lib.requestAnimDict(Config.Animation.Accept.dict)

      ClearPedTasksImmediately(entity)
      ClearPedTasksImmediately(cache.ped)

      TaskTurnPedToFaceEntity(cache.ped, entity, 1000)
      TaskTurnPedToFaceEntity(entity, cache.ped, 1000)

      Wait(1000)

      AttachDrugs(cache.ped, false)
      AttachMoney(entity, true)

      TaskPlayAnim(cache.ped, Config.Animation.Accept.dict, Config.Animation.Accept.clip, 8.0, -8.0, Config.SellDuration,
        0, 0, false, false, false)
      TaskPlayAnim(entity, Config.Animation.Accept.dict, Config.Animation.Accept.clip, 8.0, -8.0, Config.SellDuration, 0,
        0, false, false, false)

      Wait(Config.SellDuration / 2)

      AttachMoney(cache.ped, false)
      AttachDrugs(entity, true)

      Wait(Config.SellDuration / 2)

      DeleteProp(cache.ped)
      DeleteProp(entity)
    end)

--#
--# Util Functions
--#

AlertPoliceBlips = function(coords)
  local transT = 250
  local zone = GetZone(coords)
  local Blip = AddBlipForCoord(coords.x, coords.y, coords.z)

  lib.notify({
    id = 'visualz_selldrugs:callPolice',
    icon = Config.SellIcon,
    description = 'En Person prøvede at sælge stoffer i ' .. zone
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
      description = "Du har ikke noget stof at sælge"
    })
    return
  end

  local networkId = NetworkGetNetworkIdFromEntity(ped)
  local sellResponse = lib.callback.await("visualz_selldrugs:sellDrugs", false, networkId, currentDrug, zone)

  lib.notify({
    type = sellResponse.type,
    description = sellResponse.description
  })
  SetPedConfigFlag(ped, 128, true)
  SetPedConfigFlag(ped, 183, true)
  SetPedFleeAttributes(ped, 15, true)
end

function AttachDrugs(entity, isNpc)
  DeleteProp(entity)
  object[entity] = CreateObject(
    GetHashKey(isNpc and Config.Animation.Accept.npc.drugProp or Config.Animation.Accept.player.drugProp), 0, 0, 0, true,
    true, true)
  local coord = isNpc and Config.Animation.Accept.npc.drugPos or Config.Animation.Accept.player.drugPos
  local rot = isNpc and Config.Animation.Accept.npc.drugRot or Config.Animation.Accept.player.drugRot
  AttachEntityToEntity(object[entity], entity,
    isNpc and Config.Animation.Accept.npc.propIndex or Config.Animation.Accept.player.propIndex, coord.x, coord.y,
    coord.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
end

function AttachMoney(entity, isNpc)
  DeleteProp(entity)
  object[entity] = CreateObject(
    GetHashKey(isNpc and Config.Animation.Accept.npc.moneyProp or Config.Animation.Accept.player.moneyProp), 0, 0, 0,
    true,
    true, true)
  local coord = isNpc and Config.Animation.Accept.npc.moneyPos or Config.Animation.Accept.player.moneyPos
  local rot = isNpc and Config.Animation.Accept.npc.moneyRot or Config.Animation.Accept.player.moneyRot
  AttachEntityToEntity(object[entity], entity,
    isNpc and Config.Animation.Accept.npc.propIndex or Config.Animation.Accept.player.propIndex, coord.x, coord.y,
    coord.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
end

function DeleteProp(entity)
  if object[entity] and DoesEntityExist(object[entity]) then
    DeleteEntity(object[entity])
  end
end

local keybind = lib.addKeybind({
  name = 'visualz_selldrug',
  description = 'Sell drug',
  defaultKey = 'E',
  onPressed = function(self)
    if not closestPed then
      return
    end

    if Entity(closestPed).state.hasSold then
      return
    end

    SellToPed(closestPed)
  end,
})

function HideTextUiIfNeeded()
  local isOpen, text = lib.isTextUIOpen()
  if isOpen and text == keybind.currentKey .. " - Sell drugs" then
    lib.hideTextUI()
  end
end

function IsDrugTableEmpty(drugs)
  local amount = 0
  for k, v in pairs(drugs) do
    amount = amount + tonumber(v)
  end
  if amount <= 0 then
    return true
  end
  return false
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
          do break end
        end

        local amountOfDrug = exports.ox_inventory:Search("count", currentDrug, false)
        if type(amountOfDrug) == "number" and amountOfDrug <= 0 then
          lib.notify({
            type = "info",
            description = "Du har ikke mere " .. Config.Drugs[currentDrug].label .. " at sælge"
          })
          currentDrug = nil
          do break end
        end

        local coords = GetEntityCoords(cache.ped)
        local ped = lib.getClosestPed(coords, 2.0)

        if not ped then
          closestPed = nil
          HideTextUiIfNeeded()
          do break end
        end

        if not IsPedAbleToSell(ped) then
          closestPed = nil
          HideTextUiIfNeeded()
          do break end
        end

        if Entity(ped).state.hasSold then
          closestPed = nil
          HideTextUiIfNeeded()
          do break end
        end

        closestPed = ped
        if not lib.isTextUIOpen() then
          lib.showTextUI(keybind.currentKey .. " - Sell drugs", {
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
    label = "Sell to npc",
    icon = "fas fa-dollar-sign",
    distance = 2.0,
    canInteract = function(entity)
      if not currentDrug then
        return false
      end

      local amountOfDrug = exports.ox_inventory:Search("count", currentDrug, false)
      if type(amountOfDrug) == "number" and amountOfDrug <= 0 then
        return false
      end

      if not IsPedAbleToSell(entity) then
        return false
      end

      if Entity(entity).state.hasSold then
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
      description = "Stof salg er blevet slået fra"
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
  StofMenu()
end)

lib.addKeybind({
  name = 'Visualz_sellsystem:openMenu',
  description = 'Åben stof menu',
  defaultKey = Config.OpenStofMenu,
  onPressed = function(self)
    StofMenu()
  end,
})

function StofMenu()
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
          description = "Vælg " .. Config.Drugs[k].label .. " som stof",
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
      description = "Vælg " .. Config.Drugs[drugs[1]].label .. " som stof",
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
