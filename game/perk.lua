-- Disable temple perk spawns
_perk_spawn_many = perk_spawn_many

function perk_spawn_many(x, y, dont_remove_others_, ignore_these_)
    if (dont_remove_others_ and ModIsEnabled("nightmare")) then
        EntityLoad("mods/ALIEN/items/nightmare_item.xml", x+30, y)
    else
        EntityLoad("mods/ALIEN/items/level_up_item.xml", x+30, y)
    end
end