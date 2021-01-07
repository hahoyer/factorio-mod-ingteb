local oldGlobal = global
oldGlobal.Index = 1
global = {Players = {}}
global.Players[1] = oldGlobal
game.print("[ingteb] migration 0.3.3")
