-- Disable temple perk spawns
_perk_spawn_many = perk_spawn_many

function perk_spawn_many(x, y)
    EntityLoad("mods/ALIEN/items/level_up_item.xml", x+30, y)
end