
description "vRP TCG"
--ui_page "ui/index.html"

dependency "vrp"

server_script "@vrp/lib/utils.lua"
server_script "server.lua"

files {
  "gui/tcgcard.js",
  "images/card_bgnormal.png",
  "images/card_bgnormal_over.png",
  "images/card_bgshiny.png",
  "images/card_bgshiny_over.png",
  "images/rank_0.png",
  "images/rank_1.png",
  "images/rank_2.png",
  "images/rank_3.png",
  "images/rank_4.png"
}
