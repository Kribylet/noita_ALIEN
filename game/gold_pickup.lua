dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/ALIEN/scripts/alien_utils.lua")

local _item_pickup = _item_pickup or item_pickup

if (getAlienSetting("greed_gold_works") == "yes") then
    function item_pickup(entity_item, entity_who_picked, item_name)
        _item_pickup(entity_item, entity_who_picked, item_name)

        local player_entity = get_players()[1]
        if (player_entity ~= nil and entity_who_picked == player_entity) then

            local gold_value = GetGoldValue(entity_item)

            if (gold_value) then

                local extra_money_count = GameGetGameEffectCount( entity_who_picked, "EXTRA_MONEY" )
                if extra_money_count > 0 then
                    for i=1,extra_money_count do
                        gold_value = gold_value * 2
                    end
                end

                AddPlayerXP(gold_value)
                if (PlayerShouldLevelUp()) then
                    PerformLevelUp()
                end
            end
        end
    end
else
    function item_pickup(entity_item, entity_who_picked, item_name)
        _item_pickup(entity_item, entity_who_picked, item_name)

        local player_entity = get_players()[1]
        if (player_entity ~= nil and entity_who_picked == player_entity) then

            local gold_value = GetGoldValue(entity_item)

            if (gold_value) then
                AddPlayerXP(gold_value)
                if (PlayerShouldLevelUp()) then
                    PerformLevelUp()
                end
            end
        end
    end
end

