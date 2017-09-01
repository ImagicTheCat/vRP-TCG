-- TCG cards in GTA V ? Why not ?

Proxy = module("vrp", "lib/Proxy")
Tunnel = module("vrp", "lib/Tunnel")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "vrp_tcg")
local cfg = module("vrp_tcg", "cfg/tcg")

-- API

-- define parametric card item

local function card_name(args)
  local name = "<span class=\"tcgcard_name\" data-name=\""..(args[2] or "").."\">"..(args[2] or "").."</span>"
  if args[3] == "s" then
    name = name.." S (TCG)"
  else
    name = name.." (TCG)"
  end

  return name
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

local css = [[
.div_vRPtcg_script{
  display: none;
}

.tcgcard{
  position: relative;
  width: 300px;
  height: 500px;
  background-image: url("nui://vrp_tcg/images/card_bgnormal.png");
}

.tcgcard.shiny{
  background-image: url("nui://vrp_tcg/images/card_bgshiny.png");
}

.tcgcard > .over{
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-image: url("nui://vrp_tcg/images/card_bgnormal_over.png");
  z-index: 1;
}

.tcgcard.shiny > .over{
  background-image: url("nui://vrp_tcg/images/card_bgshiny_over.png");
}

.tcgcard > .rank{
  position: absolute;
  left: 120px;
  top: 0;
  width: 60px;
  height: 60px;
  z-index: 3;
}

.tcgcard > .title{
  position: absolute;
  top: 37px;
  left: 4px;
  width: 250px;
  height: 46px;
  padding: 4px;
  z-index: 2;
  font-size: 1.4em;
  font-weight: bold;
  color: white;
}

.tcgcard > .desc{
  position: absolute;
  left: 17px;
  top: 325px;
  width: 268px;
  height: 150px;
  padding: 6px;
  font-style: italic;
  text-align: center;
  font-size: 0.9em;
  color: rgba(0,0,0,0.75);
}

.tcgcard > .picture{
  position: absolute;
  width: 270px;
  height: 230px;
  left: 16px;
  top: 84px;
}
]]

AddEventHandler("vRP:playerSpawn", function(user_id, player, first_spawn)
  vRPclient.setDiv(player, {"vRPtcg_script", css, ""})

  local repos_code = ""
  for k,v in pairs(cfg.repositories) do
    repos_code = repos_code.."addTCGRepository(\""..v.."\");\n"
  end

  vRPclient.divExecuteJS(player, {"vRPtcg_script", [[ $.getScript("nui://vrp_tcg/gui/tcgcard.js", function(){
    ]]..repos_code..[[
  }); ]]})
end)
