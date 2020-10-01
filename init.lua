function OnPlayerSpawned(player_entity) -- This runs when player entity has been created

    if (not EntityGetComponent(player_entity, "VariableStorageComponent", "var_player_level")) then
        EntityAddComponent(player_entity, "VariableStorageComponent", {
            _tags = "var_player_level",
            value_int = 1
        })

        EntityAddComponent(player_entity, "VariableStorageComponent", {
            _tags = "var_player_xp",
            value_int = 0
        })

        local level_up_costs = {400, 800, 1200, 1600, 2200, 3000, 4000}
        local high_level_cost_growth = 1000

        for i = 1, (#level_up_costs - 1) do
            EntityAddComponent(player_entity, "VariableStorageComponent", {
                _tags = "var_level_cost_" .. i,
                value_int = level_up_costs[i]
            })
        end

        EntityAddComponent(player_entity, "VariableStorageComponent", {
            _tags = "var_max_base_level",
            value_int = #level_up_costs
        })

        EntityAddComponent(player_entity, "VariableStorageComponent", {
            _tags = "var_max_base_level_cost",
            value_int = level_up_costs[#level_up_costs]
        })

        EntityAddComponent(player_entity, "VariableStorageComponent", {
            _tags = "var_high_level_cost_growth",
            value_int = high_level_cost_growth
        })

        EntityAddComponent(player_entity, "VariableStorageComponent", {
            _tags = "var_times_visited_temple",
            value_int = 0
        })
    end

    EntityLoad("mods/ALIEN/ui/alienui.xml")
end
ModLuaFileAppend("data/scripts/items/gold_pickup.lua", "mods/ALIEN/game/gold_pickup.lua")
ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/ALIEN/game/perk.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/ALIEN/game/temple_altar.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar_right.lua", "mods/ALIEN/game/temple_altar_right.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar_left.lua", "mods/ALIEN/game/temple_altar_left.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar_right_snowcastle.lua", "mods/ALIEN/game/temple_altar_right_snowcastle.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar_right_snowcave.lua", "mods/ALIEN/game/temple_altar_right_snowcave.lua")
ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/ALIEN/game/boss_arena.lua")
