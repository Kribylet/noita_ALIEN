dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once( "mods/ALIEN/scripts/alien_utils.lua")

local _item_pickup = _item_pickup or item_pickup

function item_pickup( entity_item, entity_who_picked, item_name )
	_item_pickup(entity_item, entity_who_picked, item_name)

	local player_entity = get_players()[1]
	if( player_entity ~= nil and entity_who_picked == player_entity) then

		local gold_value = GetGoldValue(entity_item)

		if (gold_value) then
			AddPlayerXP(gold_value)
			if (PlayerShouldLevelUp()) then
				PerformLevelUp()
			end
		end
	end
end