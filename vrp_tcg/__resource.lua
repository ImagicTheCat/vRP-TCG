
description "vRP TCG"
--ui_page "ui/index.html"

dependency "vrp"

server_script "@vrp/lib/utils.lua"
server_script "server.lua"

file "gui/tcgcard.js"
