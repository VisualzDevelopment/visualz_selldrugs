Config = Config or {}

Config.System = "textui"         -- textui or target
Config.SellIcon = 'fas fa-pills' -- The icon to show in the textui or target
Config.SellDuration = 2000       -- How long it takes to sell drugs (in milliseconds)
Config.SellKeybind = 'E'         -- The keybind to sell drugs (only used if Config.System is set to textui)
Config.OpenStofMenu = ''         -- The keybind to open the stof menu (Leave blank to disable standard keybind)

Config.Notify = {
  ["AcceptNotify"] = function(drug, amount, price)
    return string.format("Du solgte %sx %s for %s", amount, Config.Drugs[drug].label, price)
  end,
  ["RejectNotify"] = "Personen ønsket ikke at købe noget",
}

Config.AlertBlips = true -- Show area blips on map when police is alerted

Config.Animation = {
  ["Accept"] = {
    dict = "mp_common",
    clip = "givetake1_a",
    ["npc"] = {
      propIndex = 60,

      drugProp = "prop_drug_package_02",
      drugPos = vector3(0, 0, 0),
      drugRot = vector3(0, 0, 0),

      moneyProp = "prop_cash_pile_01",
      moneyPos = vector3(0, 0, 0),
      moneyRot = vector3(0, 0, 0),
    },
    ["player"] = {
      propIndex = 71,

      drugProp = "prop_drug_package_02",
      drugPos = vector3(0.14702343872079, 0.067910678467267, -0.073813124405079),
      drugRot = vector3(5.5336386051933, 46.407417848835, -58.073611938984),

      moneyProp = "prop_cash_pile_01",
      moneyPos = vector3(0.16290343953619, 0.023659114789237, -0.041769811948384),
      moneyRot = vector3(-0.34276769547101, -45.256817898793, 61.42852180304),
    },
  },
  ["Reject"] = {
    drugProp = "prop_drug_package_02",
    moneyProp = "prop_cash_pile_01",
    dict = "mp_common",
    clip = "givetake1_a",
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
