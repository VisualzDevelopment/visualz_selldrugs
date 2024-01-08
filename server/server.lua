---@diagnostic disable: trailing-space
lib.callback.register("visualz_selldrugs:sellDrugs", function(source, networkId, drug, zone)
  local xPlayer = ESX.GetPlayerFromId(source)

  local entity = NetworkGetEntityFromNetworkId(networkId)

  if not DoesEntityExist(entity) then
    return { type = "error", description = Config.Notify["GeneralError"]() }
  end

  if not GetEntityType(entity) == 1 then
    return { type = "error", description = Config.Notify["NotAbleToSell"]() }
  end

  if Entity(entity).state.hasSold then
    return { type = "error", description = Config.Notify["AlreadySoldToThisNPC"]() }
  end

  Entity(entity).state:set("hasSold", true, true)

  if CheckDistance(entity, xPlayer) > 3.0 then
    return { type = "error", description = Config.Notify["TooFarAwayToSell"]() }
  end

  local drugInfo = Config.Drugs[drug]

  if not drugInfo then
    return { type = "error", description = Config.Notify["NotValidDrugType"](drug) }
  end

  if drugInfo.rejectChance then
    local chance = math.random(0, 100)

    if chance <= drugInfo.rejectChance then
      if drugInfo.policeChance then
        local policeChance = math.random(0, 100)
        if policeChance <= drugInfo.policeChance then
          TriggerClientEvent("visualz_selldrugs:callPoliceAnimation", source, networkId)
          CallPolice(xPlayer, zone, drug)
        else
          TriggerClientEvent("visualz_selldrugs:animation", source, networkId, "Reject")
        end
      end
      return { type = "error", description = Config.Notify["RejectNotify"](drug) }
    end
  end

  TriggerClientEvent("visualz_selldrugs:animation", source, networkId, "Accept")
  Wait(Config.SellDuration + 1000)

  if CheckDistance(entity, xPlayer) > 3.0 then
    return { type = "error", description = Config.Notify["TooFarAwayToSell"]() }
  end

  local price
  if drugInfo.randomPrice.enabled then
    price = math.random(drugInfo.randomPrice.minPrice, drugInfo.randomPrice.maxPrice)
  else
    price = drugInfo.basePrice
  end

  local amount
  if drugInfo.randomAmount.enabled then
    amount = math.random(drugInfo.randomAmount.minAmount, drugInfo.randomAmount.maxAmount)
  else
    amount = drugInfo.baseAmount
  end

  local item = xPlayer.getInventoryItem(drug)
  if not item then
    return { type = "error", description = Config.Notify["DontHaveDrug"](drug) }
  end

  if item.count < amount then
    return { type = "error", description = Config.Notify["BuyerWantedMoreThanYouHave"](drug, amount, item.count) }
  end

  xPlayer.removeInventoryItem(drug, amount)
  xPlayer.addAccountMoney("black_money", price * amount)

  local discordMessage =
      "**Spillerens navn:** " .. xPlayer.getName() .. "\n" ..
      "**Spillerens job navn:** " .. xPlayer.job.label .. "\n\n" ..
      "**Spillerens coords:** " .. xPlayer.getCoords(true) .. "\n" ..
      "**NPC coords:** " .. GetEntityCoords(entity) .. "\n" ..
      "**Distance mellem spiller og npc:** " .. ESX.Math.Round(CheckDistance(entity, xPlayer), 4) .. "\n\n" ..
      "**Network id:** " .. networkId .. "\n\n" ..

      "**Stof:** " .. drug .. "\n" ..
      "**Mængde:** " .. amount .. "\n" ..
      "**Pris:** " .. price .. "\n" ..
      "**Zone:** " .. zone .. "\n\n" ..
      "**Spillerens identifier:** " .. xPlayer.identifier .. "\n"

  SendLog(Logs["SoldDrugs"], 2829617, "Solgt stoffer", discordMessage, "Visualz Development | Visualz.dk | " .. os.date("%d/%m/%Y %H:%M:%S"))

  SellDrugEvent(source, drug, price, amount, zone)

  return { type = "info", description = Config.Notify["AcceptNotify"](drug, amount, price * amount) }
end)

function CheckDistance(ped, xPlayer)
  local pedCoords = GetEntityCoords(ped)
  local playerCoords = xPlayer.getCoords(true)

  return #(pedCoords - playerCoords)
end

function CallPolice(xPlayer, zone, drug)
  local coords = xPlayer.getCoords(true)
  if Config.AlertBlips then
    local xPlayers = ESX.GetExtendedPlayers('job', 'police')

    for _, xPlayer in pairs(xPlayers) do
      TriggerClientEvent("visualz_selldrugs:callPolice", xPlayer.source, coords)
    end
  end
  CustomAlert(xPlayer.source, zone, drug)
end

function SendLog(WebHook, color, title, message, footer)
  local embedMsg = {
    {
      ["color"] = color,
      ["title"] = title,
      ["description"] = "" .. message .. "",
      ["footer"] = {
        ["text"] = footer,
      },
    }
  }
  PerformHttpRequest(WebHook, function(err, text, headers) end, 'POST',
    json.encode({
      username = Config.whName,
      avatar_url = Config.whLogo,
      embeds = embedMsg
    }),
    { ['Content-Type'] = 'application/json' })
end
