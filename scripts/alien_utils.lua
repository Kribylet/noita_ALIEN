dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once( "data/scripts/perks/perk_list.lua" )
dofile_once( "data/scripts/perks/perk.lua" )

-- LUA Utilities

function ArrayHasValue( array, value)
    for _,item in ipairs(array) do
        if (item == value) then do return true end end
    end
    return false
end

function ArrayCount( array )
    count = 0
    for _,_ in ipairs(array) do
        count = count + 1
    end
    return count
end

-- Define ALIEN levelling utilities

function GetPlayerLevel()
    return ComponentGetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_level"), "value_int")
end

function GetPlayerXP()
    return ComponentGetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_xp"), "value_int")
end

function SetPlayerLevel(new_value)
    ComponentSetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_level"), "value_int", new_value)
end

function SetPlayerXP(new_value)
    ComponentSetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_xp"), "value_int", new_value)
end

function AddPlayerXP(value)
    local player_xp = EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_xp")

    local new_value = ComponentGetValue2(player_xp, "value_int") + value

    ComponentSetValue2(player_xp, "value_int", new_value)
end

function GetGoldValue(entity_item)
    local components = EntityGetComponent( entity_item, "VariableStorageComponent" )

    if ( components ~= nil ) then
        for _,comp_id in pairs(components) do 
            local var_name = ComponentGetValue( comp_id, "name" )
            if( var_name == "gold_value") then
                do return ComponentGetValueInt( comp_id, "value_int" ) end
            end
        end
    end
    return nil
end

function GetLevelUpCostAt(level)

    local player_entity = get_players()[1]

    local levelupCostComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", "var_level_cost_"..level)

    if (levelupCostComponent ~= nil) then
        return ComponentGetValue2(levelupCostComponent, "value_int")
    else
        local maxBaseLevelComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", "var_max_base_level")
        local highLevelCostGrowthComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", "var_high_level_cost_growth")

        levelupCostComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", "var_max_base_level_cost")
        local levelXPCost = ComponentGetValue2(levelupCostComponent, "value_int")
        local levelsAboveMaxBaseLevel = level - ComponentGetValue2(maxBaseLevelComponent, "value_int")
        local costGrowth = ComponentGetValue2(highLevelCostGrowthComponent, "value_int")

        levelXPCost = levelXPCost + levelsAboveMaxBaseLevel * costGrowth
        return levelXPCost
    end
end

function GetLevelUpCost()
    local level = GetPlayerLevel()
    return GetLevelUpCostAt(level)
end
function SetLevelUpCost(level, newLevelUpCost)
    local player_entity = get_players()[1]

    local levelupCostComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", "var_level_cost_"..level)

    if (levelupCostComponent ~= nil) then
        EntityRemoveComponent( player_entity, levelupCostComponent)
    end

    EntityAddComponent( player_entity, "VariableStorageComponent",
    {
        _tags = "var_level_cost_"..level,
        value_int = newLevelUpCost,
    } )
end

-- function GetLevelUpCost()

--     local current_level = GetPlayerLevel()

--     local highest_manual_level_cost = #level_up_costs

--     if (current_level <= highest_manual_level_cost) then
--         return level_up_costs[math.min(current_level, #level_up_costs)]
--     else
--         return level_up_costs[highest_manual_level_cost] + high_level_cost_growth*(current_level - highest_manual_level_cost);
--     end
-- end

-- Define UI specific utilities

function InventoryIsOpen()
    local iGui = EntityGetFirstComponent(get_players()[1], "InventoryGuiComponent")

    return (iGui ~= nil and ComponentGetValue2(iGui, "mActive") ~= nil and ComponentGetValueBool(iGui, "mActive"))
end

-- Define Perk utilities
ALIEN_PERK_TAG = "ALIEN_PERK_TAG"
ALIEN_PERK_REROLL_TAG = "ALIEN_PERK_REROLL_TAG"

function StoreAvailablePerkID( perk_id )
    local player_entity = get_players()[1]

    if (player_entity == nil) then do return nil end end

    EntityAddComponent( player_entity, "VariableStorageComponent",
    {
        _tags = ALIEN_PERK_TAG,
        value_string = perk_id,
    } )
end

function RemoveAllAvailablePerks()

    local player_entity = get_players()[1]

    if (player_entity == nil) then do return false end end

    local components = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_PERK_TAG )

    if (components == nil or #components == 0) then do return false end end

    for _, comp in pairs(components) do
        EntityRemoveComponent( player_entity, comp )
    end

    RemovePerkRerollCost()

    return true
end

function RemoveAvailablePerkID( perk_id )

    local player_entity = get_players()[1]

    if (player_entity == nil) then do return false end end

    local components = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_PERK_TAG )

    local matchedComponent = nil

    if ( components ~= nil ) then
        for _,comp in pairs(components) do 
            local cur_perk_id = ComponentGetValue( comp, "value_string" )
            if( cur_perk_id == perk_id) then
                matchedComponent = comp
            end
        end
    end

    if (matchedComponent == nil) then do return false end end

    EntityRemoveComponent( player_entity, matchedComponent )
    
    return true
end

function StorePerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then do return nil end end

    local perk_reroll_count = tonumber( GlobalsGetValue( "TEMPLE_PERK_REROLL_COUNT", "0" ) )
    local cost = 200 * math.pow( 2, perk_reroll_count )

    EntityAddComponent( player_entity, "VariableStorageComponent",
    {
        _tags = ALIEN_PERK_REROLL_TAG,
        value_int = cost,
    } )
end

function StoreGivenPerkRerollCost(cost)
    local player_entity = get_players()[1]

    if (player_entity == nil) then do return nil end end

    EntityAddComponent( player_entity, "VariableStorageComponent",
    {
        _tags = ALIEN_PERK_REROLL_TAG,
        value_int = cost,
    } )
end

function UpdatePerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then do return false end end

    local rerollComponent = EntityGetFirstComponent( player_entity, "VariableStorageComponent", ALIEN_PERK_REROLL_TAG )

    if (rerollComponent == nil) then do return false end end

    local perk_reroll_count = tonumber( GlobalsGetValue( "TEMPLE_PERK_REROLL_COUNT", "0" ) )
    local cost = 200 * math.pow( 2, perk_reroll_count )

    ComponentSetValue2( rerollComponent, "value_int", cost)
end

function GetPerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then do return nil end end

    local rerollComponent = EntityGetFirstComponent( player_entity, "VariableStorageComponent", ALIEN_PERK_REROLL_TAG )

    if (rerollComponent == nil) then do return nil end end

    return ComponentGetValue2( rerollComponent, "value_int" )
end

function RemovePerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then do return false end end

    local rerollComponent = EntityGetFirstComponent( player_entity, "VariableStorageComponent", ALIEN_PERK_REROLL_TAG )

    if (rerollComponent == nil) then do return false end end

    EntityRemoveComponent( player_entity, rerollComponent)

    return true
end

function GetCurrentBiomeName()
    local player_entity = get_players()[1]
    local x, y = EntityGetTransform( player_entity )
    local biomeName = BiomeMapGetName( x, y )
    if (biomeName == "_EMPTY_") then 
        biomeName = "surface" 
    else
        biomeName = GameTextGet(biomeName)
    end
    return biomeName
end

local ALIEN_STORED_IN_BIOME_TAG = "ALIEN_STORED_IN_BIOME_TAG"
local ALIEN_STORED_PERK_TAG = "ALIEN_STORED_PERK_TAG"
local ALIEN_STORED_REROLL_COST_TAG = "ALIEN_STORED_REROLL_COST_TAG"

function StorePerkSetPerk(player_entity, perk_id, num)
    EntityAddComponent( player_entity, "VariableStorageComponent",
    {
        _tags = ALIEN_STORED_PERK_TAG..num,
        value_string = perk_id,
    } )
end

function StorePerkSetRerollCost(player_entity, cost, num)
    EntityAddComponent( player_entity, "VariableStorageComponent",
    {
        _tags = ALIEN_STORED_REROLL_COST_TAG..num,
        value_int = cost,
    } )
end

function StorePerkSetBiome(player_entity, biomeName, num)
    EntityAddComponent( player_entity, "VariableStorageComponent",
    {
        _tags = ALIEN_STORED_IN_BIOME_TAG..num,
        value_string = biomeName,
    } )
end

function GetStoredPerkSet(i)
    local player_entity = get_players()[1]
    local perkComponents = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_STORED_PERK_TAG..i)

    if (perkComponents == nil) then do return nil end end

    local perkIDList = {}
    for _, perkComponent in pairs(perkComponents) do
        table.insert(perkIDList, ComponentGetValue(perkComponent, "value_string"))
    end
    return perkIDList
end

function GetStoredRerollCost(i)
    local player_entity = get_players()[1]
    local storedRerollComponent = EntityGetFirstComponent( player_entity, "VariableStorageComponent", ALIEN_STORED_REROLL_COST_TAG..i)
    
    if (storedRerollComponent == nil) then do return nil end end

    return ComponentGetValue2(storedRerollComponent, "value_int")
end

function GetStoredBiome(i)
    local player_entity = get_players()[1]
    local storedBiomeComponent = EntityGetFirstComponent( player_entity, "VariableStorageComponent", ALIEN_STORED_IN_BIOME_TAG..i)
    
    if (storedBiomeComponent == nil) then do return nil end end
    
    return ComponentGetValue(storedBiomeComponent, "value_string")
end

local doRemovePerkSet = function(player_entity, i)
    local perkComponents = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_STORED_PERK_TAG..i)
    local rerollCostComponents = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_STORED_REROLL_COST_TAG..i)
    local biomeComponents = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_STORED_IN_BIOME_TAG..i)

    for _,comp in pairs(perkComponents) do
        EntityRemoveComponent( player_entity, comp )
    end

    for _,comp in pairs(rerollCostComponents) do
        EntityRemoveComponent( player_entity, comp )
    end

    for _,comp in pairs(biomeComponents) do
        EntityRemoveComponent( player_entity, comp )
    end
end


function RemoveStoredPerkSet(i)
    if (not ArrayHasValue(GetStoredPerkSetIndices(), i)) then do return false end end

    local player_entity = get_players()[1]

    doRemovePerkSet(player_entity, i)

    return true
end

function GetStoredPerkSetNum()
    return ArrayCount(GetStoredPerkSetIndices())
end

local PerkStorageLimit = 6

function GetStoredPerkSetIndices()
    local indices = {}

    for i=1, PerkStorageLimit do
        if (GetStoredPerkSet(i) ~= nil and #GetStoredPerkSet(i) > 0 and
            GetStoredRerollCost(i) ~= nil and GetStoredBiome(i) ~= nil) then

            table.insert(indices, i)
        end
    end

    return indices
end

function GetNextFreePerkSetIndex()
    local usedIndices = GetStoredPerkSetIndices()

    if (#usedIndices == 0) then do return 1 end end

    for i=1,PerkStorageLimit do
        if (not ArrayHasValue(usedIndices, i)) then do return i end end
    end

    return nil
end

function StorePerkSet()
    if (GetAvailablePerkNum() == 0) then do return false end end

    if (GetStoredPerkSetNum() >= PerkStorageLimit) then
        GamePrint("Cannot store any more perk sets!")
        do return false end
    end

    local biomeName = GetCurrentBiomeName()

    local perkIDList = GetAvailablePerkIDs()
    local rerollCost = GetPerkRerollCost()

    local player_entity = get_players()[1]

    local nextFreePerkSetIndex = GetNextFreePerkSetIndex()

    for _, perk_id in pairs(perkIDList) do
        StorePerkSetPerk(player_entity, perk_id, nextFreePerkSetIndex)
    end

    StorePerkSetRerollCost(player_entity, rerollCost, nextFreePerkSetIndex)
    StorePerkSetBiome(player_entity, biomeName, nextFreePerkSetIndex)

    RemoveAllAvailablePerks()

    if (PlayerShouldLevelUp()) then PerformLevelUp() end
end

function ApplyStoredPerkSet( perk_id_list, reroll_cost)
    -- Apply the stored perk set
    for _, perk_id in pairs(perk_id_list) do
        StoreAvailablePerkID(perk_id)
    end

    StoreGivenPerkRerollCost(reroll_cost)
end

function SwitchToPerkSet(i)
    if (not ArrayHasValue(GetStoredPerkSetIndices(), i)) then do return false end end

    local current_perk_id_list = GetAvailablePerkIDs()
    local current_perk_reroll_cost = GetPerkRerollCost()
    local current_biome = GetCurrentBiomeName()

    -- Download the stored perkset

    local stored_perk_id_list = GetStoredPerkSet(i)
    local stored_perk_reroll_cost = GetStoredRerollCost(i)
    -- local stored_biome = GetStoredBiome(i) not needed

    local player_entity = get_players()[1]

    RemoveStoredPerkSet(i)

    -- Store the current set in the old index


    for _, perk_id in pairs(current_perk_id_list) do
        StorePerkSetPerk(player_entity, perk_id, i)
    end

    StorePerkSetRerollCost(player_entity, current_perk_reroll_cost, i)
    StorePerkSetBiome(player_entity, current_biome, i)

    RemoveAllAvailablePerks()

    -- Apply the stored perk set
    ApplyStoredPerkSet(stored_perk_id_list, stored_perk_reroll_cost)

    return true
end

function LoadStoredPerkSet(i)
    if (not ArrayHasValue(GetStoredPerkSetIndices(), i)) then do return false end end

    local storedBiome = GetStoredBiome(i)

    if (storedBiome ~= GetCurrentBiomeName()) then
        GamePrint("This perk set was stored in the "..storedBiome.." biome.")
        GamePrint("You have to go there to load this perk set.")
        do return false end
    end

    if (GetAvailablePerkNum() ~= 0) then
        do return SwitchToPerkSet(i) end
    end

    local stored_perk_id_list = GetStoredPerkSet(i)
    local stored_perk_reroll_cost = GetStoredRerollCost(i)

    RemoveStoredPerkSet(i)

    ApplyStoredPerkSet(stored_perk_id_list, stored_perk_reroll_cost)

    return true
end


function GetPerkDataById ( perk_id )
    local perk_data = get_perk_with_id( perk_list, perk_id )
	if ( perk_data == nil ) then
		GamePrint( "ALIEN mod: GetPerkDataById( perk_id ) called with'" .. perk_id .. "' - no perk with such id exists." )
		return
    end
    return perk_data
end

function AddPerkToPlayer( perk_data )

	local player_entity = get_players()[1]

	local perk_name = perk_data.ui_name
	local perk_desc = perk_data.ui_description

	-- load perk for entity_who_picked -----------------------------------

	local flag_name = get_perk_picked_flag_name( perk_data.id ) 
	GameAddFlagRun( flag_name )
	AddFlagPersistent( string.lower( flag_name ) )

	-- add game effect
	if perk_data.game_effect ~= nil then
		local game_effect_comp = GetGameEffectLoadTo( player_entity, perk_data.game_effect, true )
		if game_effect_comp ~= nil then
			ComponentSetValue( game_effect_comp, "frames", "-1" )
		end
	end

	if perk_data.func ~= nil then
		perk_data.func( "entity_item_DUMMY_NEVER_USED", player_entity, "item_name_DUMMY_NEVER_USED" )
	end

	-- add ui icon etc
	local entity_ui = EntityCreateNew( "" )
	EntityAddComponent( entity_ui, "UIIconComponent", 
	{ 
		name = perk_data.ui_name,
		description = perk_data.ui_description,
		icon_sprite_file = perk_data.ui_icon
	})
	EntityAddChild( player_entity, entity_ui )

	GamePrintImportant( GameTextGet( "$log_pickedup_perk", GameTextGetTranslatedOrNot( perk_name ) ), perk_desc )
end

-- Utility from perk.lua
local get_perk_flag_name = function( perk_id )
	return "PERK_" .. perk_id
end

function GeneratePerkList(perk_count)

    -- All available perks should have been removed already

    local perks = perk_get_spawn_order()

    for i=1,perk_count do
        local next_perk_index = tonumber( GlobalsGetValue( "TEMPLE_NEXT_PERK_INDEX", "1" ) )
		local perk_id = perks[next_perk_index]
		
		next_perk_index = next_perk_index + 1
		if next_perk_index > #perks then
			next_perk_index = 1
		end
		GlobalsSetValue( "TEMPLE_NEXT_PERK_INDEX", tostring(next_perk_index) )

        GameAddFlagRun( get_perk_flag_name(perk_id) )

        StoreAvailablePerkID(perk_id)
    end

    StorePerkRerollCost()
end

function PlayerShouldLevelUp()
    return GetAvailablePerkNum() == 0 and GetLevelUpCost() <= GetPlayerXP()
end

local doPerformLevelUp = function()
    local perk_count = tonumber( GlobalsGetValue( "TEMPLE_PERK_COUNT", "3" ) )
    GeneratePerkList(perk_count)

    local player_level = GetPlayerLevel()

    player_level = player_level + 1

    SetPlayerXP(GetPlayerXP() - GetLevelUpCost())

    SetPlayerLevel(player_level)

    return player_level
end

function PerformLevelUp()

    local player_level = doPerformLevelUp()

    GamePrintImportant("Level Up!", "You're now level "..player_level.."!")

end

function PerformCostlyLevelUp()
    -- local current_level = doPerformLevelUp()
    local current_level = GetPlayerLevel()

    local nextLevelUpCost = GetLevelUpCostAt(current_level) + GetLevelUpCostAt(current_level + 1)
    SetLevelUpCost(current_level + 1, nextLevelUpCost)
    SetLevelUpCost(current_level, 0)

    if (PlayerShouldLevelUp()) then doPerformLevelUp() end

    GamePrintImportant("Divine Level Up!", "But you carry your inexperience with you.")
end

function GetAvailablePerkIDs()

    local player_entity = get_players()[1]
    local components = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_PERK_TAG )

    if (components == nil or #components == 0) then
        do return {} end
    end

    local perkIDList = {}

    for _,comp in pairs(components) do
        local perk_id = ComponentGetValue(comp, "value_string" )
        table.insert(perkIDList, perk_id)
    end

    return perkIDList
end

function GetAvailablePerks()


    local perkIDList = GetAvailablePerkIDs()
    local perkDataList = {}

    for _,perk_id in pairs(perkIDList) do
        local perk_data = get_perk_with_id( perk_list, perk_id )
        table.insert(perkDataList, perk_data)
    end

    return perkDataList
end

function GetAvailablePerkNum()

    player_entity = get_players()[1]
    local components = EntityGetComponent( player_entity, "VariableStorageComponent", ALIEN_PERK_TAG )

    if (components == nil or #components == 0) then do return 0 end end

    return #components
end

local shouldKillPerks = function( player_entity )
    local kill_other_perks = true

	local components = EntityGetComponent( player_entity, "VariableStorageComponent" )
	
	if ( components ~= nil ) then
		for key,comp_id in pairs(components) do 
			local var_name = ComponentGetValue( comp_id, "name" )
			if( var_name == "perk_dont_remove_others") then
				if( ComponentGetValueBool( comp_id, "value_bool" ) ) then
					kill_other_perks = false
				end
			end
		end
    end
    return kill_other_perks
end

local performPerkRemoval = function( perk_id )
    local player_entity = get_players()[1]

    local kill_other_perks = shouldKillPerks(player_entity)

    local x, y = EntityGetTransform(player_entity)

    if kill_other_perks then
		local perk_destroy_chance = tonumber( GlobalsGetValue( "TEMPLE_PERK_DESTROY_CHANCE", "100" ) )
        SetRandomSeed( GameGetFrameNum() * GetAvailablePerkNum() , (x + y) * GetAvailablePerkNum())

		if( Random( 1, 100 ) <= perk_destroy_chance ) then
            RemoveAllAvailablePerks()
        else
            RemoveAvailablePerkID(perk_id)
		end
    end
end

function SelectPerk(perk_data)
    AddPerkToPlayer(perk_data)

    performPerkRemoval(perk_data.id)

    if (PlayerShouldLevelUp()) then PerformLevelUp() end
end

function RerollPerkList()
    local available_perks = GetAvailablePerkNum()
    if (available_perks == 0) then do return false end end

    local player_entity = get_players()[1]
    local money = 0

    edit_component( player_entity, "WalletComponent", function(comp,vars)
		money = ComponentGetValueInt( comp, "money")
    end)

    local rerollCost = GetPerkRerollCost()

    if (money < rerollCost) then
        GamePrint("Can't afford to reroll perks..")
        do return false end
    end

	money = money - rerollCost

	edit_component( player_entity, "WalletComponent", function(comp,vars)
		vars.money = money
	end)

    local perk_reroll_count = tonumber( GlobalsGetValue( "TEMPLE_PERK_REROLL_COUNT", "0" ) )
	perk_reroll_count = perk_reroll_count + 1
	GlobalsSetValue( "TEMPLE_PERK_REROLL_COUNT", tostring( perk_reroll_count ) )

    RemoveAllAvailablePerks()
    GeneratePerkList(available_perks)
end

function DiscardPerks()
    RemoveAllAvailablePerks()
    if (PlayerShouldLevelUp()) then PerformLevelUp() end
end