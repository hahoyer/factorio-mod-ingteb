#Provides an ingame technology browser.
It is a help system. 
All places where a Game object is referenced are listed with this object. 
For example, for an item, all recipes that process it and that create it are displayed. If it is an assembly machine, all recipes that this machine can process are also displayed, and so on. 
This is the general principle of this mod. 
The displayed icons also show dynamic information. For example, a recipe shows whether it has already been researched and if so, how much handcrafting is possible for the player with the available inventory.
Also, you can trigger certain actions directly from the help system. 
- Research
- Handcrafting
- Pipette
There is a reminder panel with optional automatic research and (hand-)crafting.
There is also a history.

It is a tribute to the help system of Evospace. I hope factorio players will like it a lot as well.
The "remidor panel" is inspired by the one from Satisfactory. 

###todo: *(please feel free to rate)*
- provide information on recipe-combinations
- involve achievements
- machine-column for labs
- Improve recipe-column-layout in case of huge amount of recipes
- Keep tab-selection for huge presentator after refresh
- Reminder task helpers for complex recipes. For instance "(recursively) add a task for all ingredients"
- Reminder tasks for Recipes
- Reminder tasks for Technologies
- Ping for objects ("Where the hell are there some more iron plates lying around?")
- present multiple items_to_place_this of entity-prototypes
- present limitations for modules
- Reminder panel grouping
- Reminder panel priorities
- Reminder panel load/save
- Show steam-processors
- Show energy consumption/production as tooltip on arrow-sprites in recipe lines
- Reminder: remove researches
- Reminder: indicator for available/not available workers
- Presentator: tooltips for tab-group icons
- Present research-status in tooltip of recipes and technologies 
- ... *more suggestions?*

###todo(or probably not): *(please feel free to complain)*
- multiplayer *(See no way do this. Help welcome)*  
- copy recipe *(See no way do this. Help welcome)*
- Several filter options
  => by mod *(See no way do this. Help welcome)*

###known issue:
- Presentator: if there are only UsefulLinks, they are not presented
- Multiplayer: Desync issue when loading a save file where reminder panel is open *(help welcome!)*
- When using a research queue handler like the one from sonaxaton, ingteb-research may behave strange. (As a workaround, you can temporarily use the replacement mod [Improved Research Queue with interface](https://mods.factorio.com/mod/sonaxaton-research-queue-with-interface) instead of [Improved Research Queue](https://mods.factorio.com/mod/sonaxaton-research-queue).)

**Note: This mod is under development. Please be so kind and use the "Discussion" tab to give feedback - especially if you encounter bugs.** Many thanks in advance

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G2G4BH6WX)
