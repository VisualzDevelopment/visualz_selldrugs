-- Server side function
function SellDrugEvent(source, drug, price, amount, zone)
  local xPlayer = ESX.GetPlayerFromId(source)
  exports["visualz_zones"]:AddPoints(xPlayer, zone, price * amount, drug)
end

-- Server side function
function CustomAlert(source, zone, drug)
  -- Lav din egene alert her

  -- local xPlayer = ESX.GetPlayerFromId(source)
  -- local message = "Der er en der sælger stoffer i " .. zone .. "!"
  -- exports['visualz_opkaldsliste']:AddCall(nil, message, "police", xPlayer.getCoords(true))
end
