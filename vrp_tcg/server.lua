-- TCG cards in GTA V ? Why not ?

Proxy = module("vrp", "lib/Proxy")
Tunnel = module("vrp", "lib/Tunnel")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "vrp_tcg")
local cfg = module("vrp_tcg", "cfg/tcg")

-- API

-- define parametric card item

local function card_name(args)
  return "<span class=\"tcgcard_name\" data-name=\""..(args[2] or "").."\"></span> (TCGcard)"
end

local function card_description(args)
  local out = "<div class=\"tcgcard\" data-name=\""..(args[2] or "").."\""
  if args[3] == "s" then -- shiny
    out = out.." data-shiny=\"1\""
  end

  out = out.."></div>"
  return out
end

local function card_choices(args)
  return {}
end

local function card_weight(args)
  return 0
end

vRP.defInventoryItem({"tcgcard", card_name, card_description, card_choices, card_weight})

-- load JS script on first spawn

AddEventHandler("vRP:playerSpawn", function(user_id, player, first_spawn)
  vRPclient.setDiv(player, {"vRPtcg_script", ".div_vRPtcg_script{ display: none; }", ""})

  local repos_code = ""
  for k,v in pairs(cfg.repositories) do
    repos_code = repos_code.."addTCGRepository(\""..v.."\");\n"
  end

  vRPclient.divExecuteJS(player, {"vRPtcg_script", [[ $.getScript("nui://vrp_tcg/gui/tcgcard.js", function(){
    ]]..repos_code..[[
  }); ]]})
end)
