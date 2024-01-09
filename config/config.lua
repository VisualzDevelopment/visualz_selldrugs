Config = {}

Config.System = "textui" -- textui or target

-- Target label (only used if Config.System is set to target)
Config.Target = function()
  return string.format("Sælg stof")
end

-- TextUI label (only used if Config.System is set to textui)
Config.TextUI = function(keybind)
  return string.format(keybind .. " - Sælg stof")
end

Config.SellDistance = 1.5        -- How close you need to be to sell drugs (in meters)
Config.SellIcon = 'fas fa-pills' -- The icon to show in the textui or target
Config.SellDuration = 2000       -- How long it takes to sell drugs (in milliseconds) (There is a buffer of 1250 milliseconds)
Config.SellKeybind = 'E'         -- The keybind to sell drugs (only used if Config.System is set to textui)
Config.SellCooldown = 2.5        -- How long the cooldown is between each sell (in seconds)

Config.OpenStofMenu = ''         -- The keybind to open the stof menu (Leave blank to disable standard keybind)

Config.AlertBlips = true         -- Show area blips on map when police is alerted

Config.Animation = {
  ["Accepted"] = {
    enabled = true,
    dict = "mp_common",
    clip = "givetake1_a",

    ["npc"] = {
      enabled = true,
      propIndex = 60,

      firstProp = "prop_drug_package_02",
      firstPos = vector3(0, 0, 0),
      firstRot = vector3(0, 0, 0),

      secondProp = "prop_cash_pile_01",
      secondPos = vector3(0, 0, 0),
      secondRot = vector3(0, 0, 0),
    },
    ["player"] = {
      enabled = true,
      propIndex = 71,

      firstProp = "prop_drug_package_02",
      firstPos = vector3(0.14702343872079, 0.067910678467267, -0.073813124405079),
      firstRot = vector3(5.5336386051933, 46.407417848835, -58.073611938984),

      secondProp = "prop_cash_pile_01",
      secondPos = vector3(0.16290343953619, 0.023659114789237, -0.041769811948384),
      secondRot = vector3(-0.34276769547101, -45.256817898793, 61.42852180304),
    },
  },
  ["Rejected"] = {
    enabled = false,
    dict = "mp_common",
    clip = "givetake1_a",

    ["npc"] = {
      enabled = false,
      propIndex = 60,

      firstProp = "",
      firstPos = vector3(0, 0, 0),
      firstRot = vector3(0, 0, 0),

      secondProp = "",
      secondPos = vector3(0, 0, 0),
      secondRot = vector3(0, 0, 0),
    },
    ["player"] = {
      enabled = false,
      propIndex = 60,

      firstProp = "",
      firstPos = vector3(0, 0, 0),
      firstRot = vector3(0, 0, 0),

      secondProp = "",
      secondPos = vector3(0, 0, 0),
      secondRot = vector3(0, 0, 0),
    },
  },
}

Config.Drugs = {
  ["burger"] = {
    label = 'Weed',
    icon = 'fas fa-cannabis',
    rejectChance = 100,
    policeChance = 100,

    basePrice = 100,
    randomPrice = {
      enabled = true,
      minPrice = 100,
      maxPrice = 200,
    },

    baseAmount = 1,
    randomAmount = {
      enabled = true,
      minAmount = 1,
      maxAmount = 5,
    },
  },
  ["water"] = {
    label = 'Coke',
    icon = 'fas fa-cannabis',
    rejectChance = 20,
    policeChance = 20,

    basePrice = 100,
    ["randomPrice"] = {
      enabled = true,
      minPrice = 100,
      maxPrice = 200,
    },

    baseAmount = 1,
    ["randomAmount"] = {
      enabled = true,
      minAmount = 1,
      maxAmount = 5,
    },
  },
}

Config.Notify = {
  ["GeneralError"] = function()
    return string.format("Der skete en fejl")
  end,
  ["AcceptNotify"] = function(drug, amount, price)
    return string.format("Du solgte %sx %s for %s", amount, Config.Drugs[drug].label, price)
  end,
  ["RejectNotify"] = function(drug)
    return string.format("Personen ønsket ikke at købe noget")
  end,
  ["Cooldown"] = function(seconds)
    return string.format("Du skal vente %s sekunder før du kan sælge igen", seconds)
  end,
  ["NotAbleToSell"] = function()
    return string.format("Du kan ikke sælge til denne person")
  end,
  ["AlreadySoldToThisNPC"] = function()
    return string.format("Du har allerede solgt til denne person")
  end,
  ["TooFarAwayToSell"] = function()
    return string.format("Du er gået for langt væk fra personen")
  end,
  ["NotValidDrugType"] = function(drug)
    return string.format("Denne type stof findes ikke")
  end,
  ["DontHaveDrug"] = function(drug)
    return string.format("Du har ikke %s på dig", Config.Drugs[drug].label)
  end,
  ["BuyerWantedMoreThanYouHave"] = function(drug, wantedAmoubt, currentAmount)
    return string.format("Personen ønsket %s %s, du har kun %s", wantedAmoubt, drug, currentAmount)
  end,
  ["CallPolice"] = function(zone)
    return string.format("Opkald om stof salg i %s", zone)
  end,
  ["RanOutOfDrugs"] = function(drug)
    return string.format("Du løb tør for %s", Config.Drugs[drug].label)
  end,
  ["DrugSaleTurnedOff"] = function()
    return string.format("Du har slået stof salg fra")
  end
}
