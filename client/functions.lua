-- Animation when police is called
function CallPoliceAnimation(entity)
  local dict = "cellphone@"
  lib.requestAnimDict(dict)

  TaskPlayAnim(entity, dict, "cellphone_text_to_call", 3.0, -1, -1, 50, 0, false, false, false)
  local phoneProp = CreateObject("prop_amb_phone", 1.0, 1.0, 1.0, true, true, false)
  local bone = GetPedBoneIndex(entity, 28422)
  AttachEntityToEntity(phoneProp, entity, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 2, true)

  Wait(4000)

  TaskPlayAnim(entity, dict, "cellphone_text_out", 3.0, -1, -1, 50, 0, false, false, false)

  Wait(1000)

  DeleteEntity(phoneProp)
end
