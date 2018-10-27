local Luang = module("vrp", "lib/Luang")
local lang = vRP.lang

-- TCG cards in GTA V ? Why not ?
local TCG = class("TCG", vRP.Extension)

-- STATIC

-- 1 => 1/100, 50 => 1/2, 160 => 1/1
-- return true on success
function TCG.chance(percent)
  return math.random(1,100) <= percent
end

-- PRIVATE METHODS

local function define_items(self)
  -- define parametric card item ( tcgcard|idname[|s] )

  local function i_card_name(args)
    local card = self.cards[args[2]]
    local name
    if card then
      name = card.name
    else
      name = "["..args[2].."]"
    end

    if args[3] == "s" then
      name = name.." S (TCG)"
    else
      name = name.." (TCG)"
    end

    return name
  end

  local function i_card_description(args)
    local out = "<div class=\"tcgcard\" data-name=\""..(args[2] or "").."\""
    if args[3] == "s" then -- shiny
      out = out.." data-shiny=\"1\""
    end

    out = out.."></div>"
    local card = self.cards[args[2]]
    if card then
      out = out.."<br />"..(self.lang.rank[parseInt(card.rank)])()
      if args[3] == "s" then -- shiny
        out = out.." (S)"
      end
    end

    return out
  end

  vRP.EXT.Inventory:defineItem("tcgcard", i_card_name, i_card_description, nil, 0)

  -- define parametric booster ( tcgbooster|rank|ncards )

  local function i_booster_name(args)
    return self.lang.booster.title({(self.lang.rank[parseInt(args[2])])(), args[3]})
  end

  local function i_booster_description(args)
    return self.lang.booster.description({(self.lang.rank[parseInt(args[2])])(), args[3]})
  end

  local function m_booster_open(menu)
    local user = menu.user
    local fullid = menu.data.fullid
    local citem = vRP.EXT.Inventory:computeItem(fullid)

    if user:tryTakeItem(fullid, 1, nil, true) then
      local rank = parseInt(citem.args[2])
      local ncards = parseInt(citem.args[3])

      local list = self:openBooster(rank, ncards)

      for _, card in pairs(list) do
        local cfullid = "tcgcard|"..card[1]
        if card[2] then
          cfullid = cfullid.."|s"
        end

        user:tryGiveItem(cfullid,1)
      end
    end
  end

  local function i_booster_menu(args, menu)
    menu:addOption(self.lang.booster.open.title(), m_booster_open, self.lang.booster.open.description())
  end

  vRP.EXT.Inventory:defineItem("tcgbooster", i_booster_name, i_booster_description, i_booster_menu, 0)
end

-- METHODS

function TCG:__construct()
  vRP.Extension.__construct(self)

  self.cfg = module("vrp_tcg", "cfg/tcg") 

  -- load lang
  self.luang = Luang()
  self.luang:loadLocale(vRP.cfg.lang, module("vrp_tcg", "cfg/lang/"..vRP.cfg.lang))
  self.lang = self.luang.lang[vRP.cfg.lang]

  define_items(self)

  self.cards_by_rank = {} -- map of rank => list of card id
  self.cards = {} -- map of cards (id => card)

  -- load cards from repositories
  for _,repo in pairs(self.cfg.repositories) do
    PerformHttpRequest(repo.."cards.txt", function(code, text, headers)
      if code == 200 then
        local count = 0
        for id in text:gmatch("([^\n]*)\n?") do
          if string.len(id) > 0 then
            PerformHttpRequest(repo.."cards/"..id..".json", function(code, data, headers)
              if code == 200 then
                local card = json.decode(data or "{}")
                if card then
                  -- register card
                  self.cards[id] = card

                  -- register by rank
                  local rank = card.rank or 0
                  local rank_list = self.cards_by_rank[rank]
                  if not rank_list then
                    rank_list = {}
                    self.cards_by_rank[rank] = rank_list
                  end

                  table.insert(rank_list, id)
                  count = count+1
                else
                  self:log("couldn't load card "..id..", error = bad json")
                end
              else
                self:log("couldn't load card "..id..", error = "..code)
              end
            end, 'GET', json.encode({}), { ["Content-Type"] = 'application/json' })
          end
        end

        self:log("load repository "..repo)
      else
        self:log("couldn't load repository "..repo..", error = "..code)
      end
    end, 'GET', json.encode({}), { ["Content-Type"] = 'text/plain' })
  end
end

-- pick a random card idname by rank
-- return nil if no cards has been found
function TCG:pickCard(rank)
  local list = self.cards_by_rank[rank] or {}
  if #list > 0 then
    return list[math.random(1,#list)]
  end
end

-- open a booster card for a specific rank
-- return {card_id, shiny_flag} or nil if no cards exist
function TCG:openBoosterCard(rank)
  local card = nil
  -- special rank+1
  if rank < 4 and TCG.chance(4) then
    card = self:pickCard(rank+1)
  end

  -- rank -> 0
  local rank_chance = 20
  while not card and rank >= 0 do
    if TCG.chance(rank_chance) then
      card = self:pickCard(rank)
    end

    rank_chance = rank_chance*2
    rank = rank-1
  end

  -- rank = 0
  if not card then
    card = self:pickCard(0)
  end

  if card then
    return {card, TCG.chance(1)}
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
-- return list of {card_id, shiny_flag}
function TCG:openBooster(rank, ncards)
  local list = {}
  for i=1,ncards do
    table.insert(list, self:openBoosterCard(rank))
  end

  return list
end

-- EVENT
TCG.event = {}

-- load JS script on first spawn

local tcg_css = [[
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

function TCG.event:playerSpawn(user, first_spawn)
  if first_spawn then
    -- set TCG additional CSS
    vRP.EXT.GUI.remote._setDiv(user.source, "vRPtcg_script", tcg_css, "")

    -- load TCG script
    local repos_code = ""
    for _,repo in pairs(self.cfg.repositories) do
      repos_code = repos_code.."addTCGRepository(\""..repo.."\");\n"
    end

    vRP.EXT.GUI.remote._divExecuteJS(user.source, "vRPtcg_script", [[ $.getScript("nui://vrp_tcg/gui/tcgcard.js", function(){
      ]]..repos_code..[[
    }); ]])
  end
end

vRP:registerExtension(TCG)
