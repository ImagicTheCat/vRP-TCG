
local cfg = {}

-- TCG repositories (load cards)
--- it is recommended to create your own repository on your own http server using any set of cards you want to prevents cards from "disappearing" if the main server shutdown
--- a repository is a directory URL ending with "/" (containing a specific TCG structure and files)
cfg.repositories = {
  "http://localhost/fivem/tcg/base/" -- local test repository
}

return cfg
