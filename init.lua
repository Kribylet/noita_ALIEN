function OnWorldInitialized()
    EntityLoad("mods/ALIEN/ui/alienui.xml")
end

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
            _tags = "var_times_visited_temple",
            value_int = 0
        })
    end
end
ModLuaFileAppend("data/scripts/items/gold_pickup.lua", "mods/ALIEN/game/gold_pickup.lua")
ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/ALIEN/game/perk.lua")
local ShouldRemovePerkRerollItem = not ModIsEnabled("dead_isnt_dead")
if (ShouldRemovePerkRerollItem) then
    ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/ALIEN/game/temple_altar.lua")
    ModLuaFileAppend("data/scripts/biomes/temple_altar_right.lua", "mods/ALIEN/game/temple_altar_right.lua")
    ModLuaFileAppend("data/scripts/biomes/temple_altar_left.lua", "mods/ALIEN/game/temple_altar_left.lua")
    ModLuaFileAppend("data/scripts/biomes/temple_altar_right_snowcastle.lua", "mods/ALIEN/game/temple_altar_right_snowcastle.lua")
    ModLuaFileAppend("data/scripts/biomes/temple_altar_right_snowcave.lua", "mods/ALIEN/game/temple_altar_right_snowcave.lua")
    ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/ALIEN/game/boss_arena.lua")
end

--function OnPausedChanged(is_paused, is_inventory_pause)
--    local entity_ids = EntityGetWithTag("ALIEN_PERK_TAG")
--
--    for i, entity_id in pairs(entity_ids) do
--        local sprite_component = EntityGetFirstComponentIncludingDisabled(entity_id, "SpriteComponent")
--        EntitySetComponentIsEnabled(entity_id, sprite_component, not is_paused)
--        EntityRefreshSprite(entity_id, sprite_component)
--    end
--end
