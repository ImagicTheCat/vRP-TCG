-- TCG cards in GTA V ? Why not ?

local Proxy = module("vrp", "lib/Proxy")
local Tunnel = module("vrp", "lib/Tunnel")
local Luang = module("vrp", "lib/Luang")
local cfg = module("vrp_tcg", "cfg/tcg")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "vrp_tcg")

local Lang = Luang()
Lang:loadLocale(cfg.lang, module("vrp_tcg", "cfg/lang/"..cfg.lang) or {})
local lang = Lang.lang[cfg.lang]

-- 1 => 1/100, 50 => 1/2, 160 => 1/1
-- return true on success
function chance(percent)
  return math.random(1,100) <= percent
end

local cards_byrank = {} -- map of rank => list of card idnames
local cards = {} -- map of cards (idname => card)

-- pick a random card idname by rank
-- return nil if no cards has been found
function pick_card(rank)
  local list = cards_byrank[rank] or {}
  if #list > 0 then
    return list[math.random(1,#list)]
  end
end

-- "open" a booster of n-cards
-- the rank define the level of the booster (0-4)
-- a booster of rank n:
--- will have 4% chance to give a card of rank n+1 per card
--- will have 20% chance to give a card of rank n per card
--- will have 40% chance to give a card of rank n-1 per card
--- will have 80% chance to give a card of rank n-2 per card
--- will have percent*2 chance to give a card of rank n-... per card
--- each card have 1% chance of being shiny
-- return list of {card_idname, shiny_flag}
function open_booster(rank, ncards)
  local list = {}
  for i=1,ncards do
    table.insert(list, open_booster_card(rank))
  end

  return list
end

-- open a booster card for a specific rank
-- return {card_idname, shiny_flag} or nil if no cards exist
function open_booster_card(rank)
  local card = nil
  -- special rank+1
  if rank < 4 and chance(4) then
    card = pick_card(rank+1)
  end

  -- rank -> 0
  local rank_chance = 20
  while not card and rank >= 0 do
    if chance(rank_chance) then
      card = pick_card(rank)
    end

    rank_chance = rank_chance*2
    rank = rank-1
  end

  -- rank = 0
  if not card then
    card = pick_card(0)
  end

  if card then
    return {card, chance(1)}
  end
end

function open_user_booster(user_id, rank, ncards)
  local list = open_booster(rank, ncards)

  for k,v in pairs(list) do
    local idname = "tcgcard|"..v[1]
    if v[2] then
      idname = idname.."|s"
    end
    vRP.giveInventoryItem(user_id,idname,1,true)
  end
end

-- load cards from repositories
for k,v in pairs(cfg.repositories) do
  PerformHttpRequest(v.."cards.txt", function(code, text, headers)
    if code == 200 then
      for idname in text:gmatch("([^\n]*)\n?") do
        if string.len(idname) > 0 then
          PerformHttpRequest(v.."cards/"..idname..".json", function(code, data, headers)
            if code == 200 then
              local card = json.decode(data or "{}")
              if card then
                -- register card
                cards[idname] = card

                -- register by rank
                local rank = card.rank or 0
                local rank_list = cards_byrank[rank]
                if not rank_list then
                  rank_list = {}
                  cards_byrank[rank] = rank_list
                end

                table.insert(rank_list, idname)
              else
                print("[vRP-TCG] couldn't load card "..idname..", error = bad json")
              end
            else
              print("[vRP-TCG] couldn't load card "..idname..", error = "..code)
            end
          end, 'GET', json.encode({}), { ["Content-Type"] = 'application/json' })
        end
      end
    else
      print("[vRPtcg] Couldn't load repository "..v..", error = "..code)
    end
  end, 'GET', json.encode({}), { ["Content-Type"] = 'text/plain' })
end

-- API

-- define parametric card item ( tcgcard|idname[|s] )

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
  local card = cards[args[2] or ""]
  if card then
    out = out.."<br />"..(lang.rank[parseInt(card.rank)])()
    if args[3] == "s" then -- shiny
      out = out.." (S)"
    end
  end

  return out
end

local function card_choices(args)
  return {}
end

local function card_weight(args)
  return 0
end

vRP.defInventoryItem("tcgcard", card_name, card_description, card_choices, card_weight)

-- define parametric booster ( tcgbooster|rank|ncards )

local function booster_name(args)
  return lang.booster.title({(lang.rank[parseInt(args[2])])(), args[3] or 5})
end

local function booster_description(args)
  return lang.booster.description({(lang.rank[parseInt(args[2])])(), args[3] or 5})
end

local function booster_choices(args)
  return {
    [lang.booster.open.title()] = {function(player, choice)
      local user_id = vRP.getUserId(player)
      if user_id then
        if vRP.tryGetInventoryItem(user_id, table.concat(args, "|"), 1, false) then
          open_user_booster(user_id, parseInt(args[2]), parseInt(args[3]))
          vRP.closeMenu(player)
        end
      end
    end, lang.booster.open.description()}
  }
end

local function booster_weight(args)
  return 0
end

vRP.defInventoryItem({"tcgbooster", booster_name, booster_description, booster_choices, booster_weight})

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

.tcgcard > .attack{
  position: absolute;
  left: 0;
  bottom: 0;
  width: 60px;
  height: 60px;
  z-index: 3;
  background-image: url("nui://vrp_tcg/images/attack.png");
  text-align: center;
  text-shadow: 0px 0px 15px rgb(255,0,0), 0px 0px 5px rgb(255,0,0);
  color: white;
  font-weight: bold;
  font-size: 1.4em;
  line-height: 60px;
}

.tcgcard > .defense{
  position: absolute;
  right: 0;
  bottom: 0;
  width: 60px;
  height: 60px;
  z-index: 3;
  background-image: url("nui://vrp_tcg/images/defense.png");
  text-align: center;
  text-shadow: 0px 0px 15px rgb(0,125,255), 0px 0px 5px rgb(0,125,255);
  color: white;
  font-weight: bold;
  font-size: 1.4em;
  line-height: 60px;

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
  async(function()
    vRPclient.setDiv(player, "vRPtcg_script", css, "")

    local repos_code = ""
    for k,v in pairs(cfg.repositories) do
      repos_code = repos_code.."addTCGRepository(\""..v.."\");\n"
    end

    vRPclient.divExecuteJS(player, "vRPtcg_script", [[ $.getScript("nui://vrp_tcg/gui/tcgcard.js", function(){
      ]]..repos_code..[[
    }); ]])
  end, true)
end)
