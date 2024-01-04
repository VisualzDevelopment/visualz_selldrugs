---@diagnostic disable: trailing-space
lib.callback.register("visualz_selldrugs:sellDrugs", function(source, networkId, drug, zone)
  local xPlayer = ESX.GetPlayerFromId(source)

  local entity = NetworkGetEntityFromNetworkId(networkId)

  if Entity(entity).state.hasSold then
    return { type = "error", description = "Du har allerede solgt til denne npc" }
  end

  Entity(entity).state:set("hasSold", true, true)

  if CheckDistance(entity, xPlayer) > 3.0 then
    return { type = "error", description = "Du er for langt væk" }
  end

  local drugInfo = Config.Drugs[drug]

  if not drugInfo then
    return { type = "error", description = "Køberen tager ikke imod denne type stof" }
  end

  if drugInfo.rejectChance then
    local chance = math.random(0, 100)

    if chance <= drugInfo.rejectChance then
      if drugInfo.policeChance then
        local policeChance = math.random(0, 100)
        if policeChance <= drugInfo.policeChance then
          CallPolice(xPlayer, zone, drug)
        end
      end
      return { type = "error", description = Config.Notify["RejectNotify"] }
    end
  end

  TriggerClientEvent("visualz_drugSystem:sellProgress", source, networkId)
  Wait(Config.SellDuration + 1000)

  if CheckDistance(entity, xPlayer) > 3.0 then
    return { type = "error", description = "Du gik for langt væk" }
  end

  local price
  if drugInfo.randomPrice then
    price = math.random(drugInfo.randomPrice.minPrice, drugInfo.randomPrice.maxPrice)
  else
    price = drugInfo.basePrice
  end

  local amount
  if drugInfo.randomAmount then
    amount = math.random(drugInfo.randomAmount.minAmount, drugInfo.randomAmount.maxAmount)
  else
    amount = drugInfo.baseAmount
  end

  local item = xPlayer.getInventoryItem(drug)
  if not item then
    return { type = "error", description = "Du har ikke noget stof at sælge" }
  end

  if item.count < amount then
    return { type = "error", description = "Personen ønsket mere end hvad du havde" }
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

  SendLog(Logs["SoldDrugs"], 2829617, "Solgt stoffer", discordMessage,
    "Visualz Development | Visualz.dk | " .. os.date("%d/%m/%Y %H:%M:%S"))
  exports["visualz_zones"]:AddPoints(xPlayer, zone, price * amount, drug)
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
      print(xPlayer.source)
      TriggerClientEvent("visualz_selldrugs:callPolice", xPlayer.source, coords)
    end
  end
  CustomAlert(xPlayer, zone, drug)
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
