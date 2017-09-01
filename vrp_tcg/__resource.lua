
description "vRP TCG"
--ui_page "ui/index.html"

dependency "vrp"

server_script "@vrp/lib/utils.lua"
server_script "server.lua"

files {
  "gui/tcgcard.js",
  "images/card_bgnormal.png",
  "images/card_bgnormal_over.png",
}
