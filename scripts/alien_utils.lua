dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk_list.lua")
dofile_once("data/scripts/perks/perk.lua")

-- SetRandomSeed once

SetRandomSeed(41515166, 12310915)

-- LUA Utilities

-- simple utility function to return the player entity By Coxas (Noita Discord)
function getPlayerEntity()
    local players = EntityGetWithTag("player_unit")
    if #players == 0 then return end

    return players[1]
end

function ArrayHasValue(array, value)
    for _, item in ipairs(array) do
        if (item == value) then
            do
                return true
            end
        end
    end

    return false
end

function ArrayCount(array)
    local count = 0
    for _, _ in ipairs(array) do
        count = count + 1
    end

    return count
end


-- Mod settings stuff

function getAlienSetting(setting_id)
    return ModSettingGet("ALIEN." .. setting_id)
end

cached_settings = {}

function getAlienSettingCache(setting_id)
    if (cached_settings[setting_id] == nil) then
        cached_settings[setting_id] = ModSettingGet("ALIEN." .. setting_id)
    end
    return cached_settings[setting_id]
end

-- Define ALIEN levelling utilities

function GetPlayerLevel()

    return ComponentGetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_level"),
               "value_int")
end

function GetPlayerXP()

    return ComponentGetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_xp"),
               "value_int")
end

function SetPlayerLevel(new_value)

    ComponentSetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_level"),
        "value_int", new_value)
end

function SetPlayerXP(new_value)

    ComponentSetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_xp"),
        "value_int", new_value)
end

function SetTimesVisitedTemple(new_value)

    ComponentSetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_times_visited_temple"),
        "value_int", new_value)
end

function GetTimesVisitedTemple()

    return ComponentGetValue2(EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_times_visited_temple"),
               "value_int")
end

function AddPlayerXP(value)

    local player_xp = EntityGetFirstComponent(get_players()[1], "VariableStorageComponent", "var_player_xp")

    local new_value = ComponentGetValue2(player_xp, "value_int") + value

    ComponentSetValue2(player_xp, "value_int", new_value)
end

function GetGoldValue(entity_item)

    local components = EntityGetComponent(entity_item, "VariableStorageComponent")

    if (components ~= nil) then
        for _, comp_id in pairs(components) do
            local var_name = ComponentGetValue(comp_id, "name")
            if (var_name == "gold_value") then
                do
                    return ComponentGetValueInt(comp_id, "value_int")
                end
            end
        end
    end
    return nil
end

local levelCostTag = "var_level_cost_"

function GetLevelCostTag(i)
    return levelCostTag .. i
end

function GetLevelUpCostAt(level)

    local player_entity = get_players()[1]

    local levelupCostComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", GetLevelCostTag(level))

    local xp_cost_scaling = tonumber(getAlienSetting("xp_cost_scaling"))

    local levelXPCost = 0

    if (levelupCostComponent ~= nil) then
        levelXPCost = ComponentGetValue2(levelupCostComponent, "value_int")
    else
        local maxBaseLevelComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent",
                                          "var_max_base_level")

        levelupCostComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent",
                                   "var_max_base_level_cost")
        levelXPCost = ComponentGetValue2(levelupCostComponent, "value_int")
        local levelsAboveMaxBaseLevel = level - ComponentGetValue2(maxBaseLevelComponent, "value_int")

        local high_level_growth_mode = getAlienSetting("high_level_growth_mode")

        if (high_level_growth_mode == "linear") then
            local linear_level_cost_growth = tonumber(getAlienSetting("linear_level_cost_growth"))
            if (linear_level_cost_growth == nil) then
                linear_level_cost_growth = 1000
            end
            levelXPCost = levelXPCost + levelsAboveMaxBaseLevel * linear_level_cost_growth
        elseif (high_level_growth_mode == "doubles") then
            for i=1, levelsAboveMaxBaseLevel do
                levelXPCost = levelXPCost * 2
            end
        elseif (high_level_growth_mode == "triples") then
            for i=1, levelsAboveMaxBaseLevel do
                levelXPCost = levelXPCost * 3
            end
        end
    end

    return levelXPCost * xp_cost_scaling
end

function RemoveStoredLevelUpCost(level)
    local player_entity = get_players()[1]

    local levelupCostComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", GetLevelCostTag(level))

    if (levelupCostComponent ~= nil) then
        EntityRemoveComponent(player_entity, levelupCostComponent)
    end
end

function GetLevelUpCost()

    local level = GetPlayerLevel()
    return GetLevelUpCostAt(level)
end

function SetLevelUpCost(level, newLevelUpCost)

    RemoveStoredLevelUpCost(level)

    local player_entity = get_players()[1]

    EntityAddComponent(player_entity, "VariableStorageComponent", {
        _tags = GetLevelCostTag(level),
        value_int = newLevelUpCost
    })
end

-- Define UI specific utilities

function GetPerkDescription(perk_data)
    local perk_desc = GameTextGetTranslatedOrNot(perk_data.ui_description)
    if perk_data.id == "EXTRA_PERK" then
        if perk_desc == "From now on you will find an extra perk in every Holy Mountain." then
            perk_desc = "From now on, you will get offered an extra perk when you level up."
        else
            perk_desc = perk_desc.." (Level Up!)"
        end
    end
    return perk_desc
end

function string_split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function sentence_split(inputstr, max_line_length, sep)
    if sep == nil then
        sep = "%s"
    end
    local words = string_split(inputstr, sep)

    local sentences = {}
    local sentence = ""

    for _, word in ipairs(words) do
        if string.len(sentence) + string.len(word) > max_line_length then
            table.insert(sentences, sentence)
            sentence = ""
        end
        if sentence == "" then sentence = word else sentence = sentence.." "..word end
    end

    if sentence ~= "" then table.insert(sentences, sentence) end

    return sentences
end

function ALIEN_xor(a, b)
    if a ~= b then return true else return false end
end

local perk_button_x_anchor = 300
local perk_button_y_anchor = 44
local perk_button_y_walk = 16

function GetPerkButtonX()
    return perk_button_x_anchor
end

function GetPerkButtonY(i)
    return perk_button_y_anchor + perk_button_y_walk * i
end

local ui_parent = nil

function GetUIParent()

    if (ui_parent == nil) then
        local o = EntityLoad("mods/ALIEN/UI/perkicon.xml", 15,15)
        ui_parent =  EntityGetParent(o)
        EntityKill(o)
    end

    return ui_parent
end

local perk_icon_entities = {}

function GetPerkIconEntityIDs()
    return perk_icon_entities
end


function GetPerkIconName(perk_id)
    return perk_id.."ALIEN_PERK_ICON"
end

function InventoryIsOpen()
    local iGui = EntityGetFirstComponent(get_players()[1], "InventoryGuiComponent")

    return (iGui ~= nil and ComponentGetValue2(iGui, "mActive") ~= nil and ComponentGetValueBool(iGui, "mActive"))
end

-- Define Perk utilities
ALIEN_PERK_TAG = "ALIEN_PERK_TAG"
ALIEN_PERK_REROLL_TAG = "ALIEN_PERK_REROLL_TAG"

function StoreAvailablePerkID(perk_id)

    local player_entity = get_players()[1]

    if (player_entity == nil) then
        do
            return nil
        end
    end

    EntityAddComponent(player_entity, "VariableStorageComponent", {
        _tags = ALIEN_PERK_TAG,
        value_string = perk_id
    })
end

function RemoveAllAvailablePerks()

    local player_entity = get_players()[1]

    if (player_entity == nil) then
        do
            return false
        end
    end

    local components = EntityGetComponent(player_entity, "VariableStorageComponent", ALIEN_PERK_TAG)

    if (components ~= nil and #components ~= 0) then
        for _, comp in pairs(components) do
            EntityRemoveComponent(player_entity, comp)
        end
    end

    RemovePerkRerollCost()

    return true
end

function RemoveAvailablePerkID(index)

    local player_entity = get_players()[1]

    if (player_entity == nil) then
        return false
    end

    local components = EntityGetComponent(player_entity, "VariableStorageComponent", ALIEN_PERK_TAG)

    EntityRemoveComponent(player_entity, components[index])

    return true
end

function StorePerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then
        do
            return nil
        end
    end

    local perk_reroll_count = tonumber(GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT", "0"))
    local cost = 200 * math.pow(2, perk_reroll_count)

    EntityAddComponent(player_entity, "VariableStorageComponent", {
        _tags = ALIEN_PERK_REROLL_TAG,
        value_int = cost
    })
end

function StoreGivenPerkRerollCost(cost)
    local player_entity = get_players()[1]

    if (player_entity == nil) then
        do
            return nil
        end
    end

    EntityAddComponent(player_entity, "VariableStorageComponent", {
        _tags = ALIEN_PERK_REROLL_TAG,
        value_int = cost
    })
end

function UpdatePerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then
        do
            return false
        end
    end

    local rerollComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", ALIEN_PERK_REROLL_TAG)

    if (rerollComponent == nil) then
        do
            return false
        end
    end

    local perk_reroll_count = tonumber(GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT", "0"))
    local cost = 200 * math.pow(2, perk_reroll_count)

    ComponentSetValue2(rerollComponent, "value_int", cost)
end

function GetPerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then
        do
            return nil
        end
    end

    local rerollComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", ALIEN_PERK_REROLL_TAG)

    if (rerollComponent == nil) then
        do
            return nil
        end
    end

    return ComponentGetValue2(rerollComponent, "value_int")
end

function RemovePerkRerollCost()
    local player_entity = get_players()[1]

    if (player_entity == nil) then
        do
            return false
        end
    end

    local rerollComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent", ALIEN_PERK_REROLL_TAG)

    if (rerollComponent == nil) then
        do
            return false
        end
    end

    EntityRemoveComponent(player_entity, rerollComponent)

    return true
end

function GetCurrentBiomeName()
    local player_entity = get_players()[1]
    local x, y = EntityGetTransform(player_entity)
    local biomeName = BiomeMapGetName(x, y)
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
    EntityAddComponent(player_entity, "VariableStorageComponent", {
        _tags = ALIEN_STORED_PERK_TAG .. num,
        value_string = perk_id
    })
end

function StorePerkSetRerollCost(player_entity, cost, num)
    EntityAddComponent(player_entity, "VariableStorageComponent", {
        _tags = ALIEN_STORED_REROLL_COST_TAG .. num,
        value_int = cost
    })
end

function StorePerkSetBiome(player_entity, biomeName, num)
    EntityAddComponent(player_entity, "VariableStorageComponent", {
        _tags = ALIEN_STORED_IN_BIOME_TAG .. num,
        value_string = biomeName
    })
end

function GetStoredPerkSet(i)
    local player_entity = get_players()[1]
    local perkComponents = EntityGetComponent(player_entity, "VariableStorageComponent", ALIEN_STORED_PERK_TAG .. i)

    if (perkComponents == nil) then
        do
            return nil
        end 
    end

    local perkIDList = {}
    for _, perkComponent in pairs(perkComponents) do
        table.insert(perkIDList, ComponentGetValue(perkComponent, "value_string"))
    end
    return perkIDList
end

function GetStoredRerollCost(i)
    local player_entity = get_players()[1]
    local storedRerollComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent",
                                      ALIEN_STORED_REROLL_COST_TAG .. i)

    if (storedRerollComponent == nil) then
        do
            return nil
        end
    end

    return ComponentGetValue2(storedRerollComponent, "value_int")
end

function GetStoredBiome(i)
    local player_entity = get_players()[1]
    local storedBiomeComponent = EntityGetFirstComponent(player_entity, "VariableStorageComponent",
                                     ALIEN_STORED_IN_BIOME_TAG .. i)

    if (storedBiomeComponent == nil) then
        do
            return nil
        end
    end

    return ComponentGetValue(storedBiomeComponent, "value_string")
end

local doRemovePerkSet = function(player_entity, i)

    local perkComponents = EntityGetComponent(player_entity, "VariableStorageComponent", ALIEN_STORED_PERK_TAG .. i)
    local rerollCostComponents = EntityGetComponent(player_entity, "VariableStorageComponent",
                                     ALIEN_STORED_REROLL_COST_TAG .. i)
    local biomeComponents =
        EntityGetComponent(player_entity, "VariableStorageComponent", ALIEN_STORED_IN_BIOME_TAG .. i)

    for _, comp in pairs(perkComponents) do
        EntityRemoveComponent(player_entity, comp)
    end

    for _, comp in pairs(rerollCostComponents) do
        EntityRemoveComponent(player_entity, comp)
    end

    for _, comp in pairs(biomeComponents) do
        EntityRemoveComponent(player_entity, comp)
    end
end

function RemoveStoredPerkSet(i)

    if (not ArrayHasValue(GetStoredPerkSetIndices(), i)) then
        do
            return false
        end
    end

    local player_entity = get_players()[1]

    doRemovePerkSet(player_entity, i)

    return true
end

local PerkStorageLimit = 6

function GetStoredPerkSetNum()

    local count = 0
    for i = 1, PerkStorageLimit do
        local storedPerkSet = GetStoredPerkSet(i)
        if (storedPerkSet) then count = count + 1 end
    end

    return count
end

function GetStoredPerkSetIndices()

    local indices = {}

    for i = 1, PerkStorageLimit do
        local storedPerkSet = GetStoredPerkSet(i)
        if (storedPerkSet ~= nil and #storedPerkSet > 0 and GetStoredRerollCost(i) ~= nil and GetStoredBiome(i) ~= nil) then

            table.insert(indices, i)
        end
    end

    return indices
end

function GetNextFreePerkSetIndex()

    local usedIndices = GetStoredPerkSetIndices()

    if (#usedIndices == 0) then
        do
            return 1
        end
    end

    for i = 1, PerkStorageLimit do
        if (not ArrayHasValue(usedIndices, i)) then
            do
                return i
            end
        end
    end

    return nil
end

local doStorePerkSet = function(player_entity, perkIDList, rerollCost, biomeName, perkStoreIndex)
    for _, perk_id in pairs(perkIDList) do
        StorePerkSetPerk(player_entity, perk_id, perkStoreIndex)
    end

    StorePerkSetRerollCost(player_entity, rerollCost, perkStoreIndex)
    StorePerkSetBiome(player_entity, biomeName, perkStoreIndex)
end

function StorePerkSet()

    if (GetAvailablePerkNum() == 0) then
        do
            return false
        end
    end

    if (GetStoredPerkSetNum() >= PerkStorageLimit) then
        GamePrint("Cannot store any more perk sets!")
        do
            return false
        end
    end

    local biomeName = GetCurrentBiomeName()

    local perkIDList = GetAvailablePerkIDs()
    local rerollCost = GetPerkRerollCost()

    local player_entity = get_players()[1]

    local nextFreePerkSetIndex = GetNextFreePerkSetIndex()

    doStorePerkSet(player_entity, perkIDList, rerollCost, biomeName, nextFreePerkSetIndex)

    RemoveAllAvailablePerks()

    if (PlayerShouldLevelUp()) then
        PerformLevelUp()
    end

end

function ApplyStoredPerkSet(perk_id_list, reroll_cost)

    -- Apply the stored perk set
    for _, perk_id in pairs(perk_id_list) do
        StoreAvailablePerkID(perk_id)
    end

    StoreGivenPerkRerollCost(reroll_cost)
end

function SwitchToPerkSet(i)

    if (not ArrayHasValue(GetStoredPerkSetIndices(), i)) then
        do
            return false
        end
    end

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

    doStorePerkSet(player_entity, current_perk_id_list, current_perk_reroll_cost, current_biome, i)

    RemoveAllAvailablePerks()

    -- Apply the stored perk set
    ApplyStoredPerkSet(stored_perk_id_list, stored_perk_reroll_cost)

    return true
end

function LoadStoredPerkSet(i)

    if (not ArrayHasValue(GetStoredPerkSetIndices(), i)) then
        do
            return false
        end
    end

    local storedBiome = GetStoredBiome(i)
    local perk_storage = getAlienSetting("perk_storage")

    if (perk_storage == "biome" and storedBiome ~= GetCurrentBiomeName()) then
        GamePrint("This perk set was stored in the " .. storedBiome .. " biome.")
        GamePrint("You have to go there to load this perk set.")
        do
            return false
        end
    end

    if (GetAvailablePerkNum() ~= 0) then
        do
            return SwitchToPerkSet(i)
        end
    end

    local stored_perk_id_list = GetStoredPerkSet(i)
    local stored_perk_reroll_cost = GetStoredRerollCost(i)

    RemoveStoredPerkSet(i)

    ApplyStoredPerkSet(stored_perk_id_list, stored_perk_reroll_cost)

    return true
end

function GetPerkDataById(perk_id)

    local perk_data = get_perk_with_id(perk_list, perk_id)
    if (perk_data == nil) then
        GamePrint("ALIEN mod: GetPerkDataById( perk_id ) called with'" .. perk_id .. "' - no perk with such id exists.")
        return
    end
    return perk_data
end

function AddPerkToPlayer(perk_data)
	-- fetch perk info ---------------------------------------------------

    local player_entity = getPlayerEntity()
    local pos_x, pos_y = EntityGetTransform( player_entity )

	local perk_id = perk_data.id

	-- Get perk's flag name

	local flag_name = get_perk_picked_flag_name( perk_id )

	-- update how many times the perk has been picked up this run -----------------

	local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )
	pickup_count = pickup_count + 1
	GlobalsSetValue( flag_name .. "_PICKUP_COUNT", tostring( pickup_count ) )

	-- load perk for player_entity -----------------------------------
	local add_progress_flags = not GameHasFlagRun( "no_progress_flags_perk" )

	if add_progress_flags then
		local flag_name_persistent = string.lower( flag_name )
		if ( not HasFlagPersistent( flag_name_persistent ) ) then
			GameAddFlagRun( "new_" .. flag_name_persistent )
		end
		AddFlagPersistent( flag_name_persistent )
	end
	GameAddFlagRun( flag_name )

	local no_remove = perk_data.do_not_remove or false

	-- add a game effect or two
	if perk_data.game_effect ~= nil then
		local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( player_entity, perk_data.game_effect, true )
		if game_effect_comp ~= nil then
			ComponentSetValue( game_effect_comp, "frames", "-1" )

			if ( no_remove == false ) then
				ComponentAddTag( game_effect_comp, "perk_component" )
				EntityAddTag( game_effect_entity, "perk_entity" )
			end
		end
	end

	if perk_data.game_effect2 ~= nil then
		local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( player_entity, perk_data.game_effect2, true )
		if game_effect_comp ~= nil then
			ComponentSetValue( game_effect_comp, "frames", "-1" )

			if ( no_remove == false ) then
				ComponentAddTag( game_effect_comp, "perk_component" )
				EntityAddTag( game_effect_entity, "perk_entity" )
			end
		end
	end

	-- particle effect only applied once
	if perk_data.particle_effect ~= nil and ( pickup_count <= 1 ) then
		local particle_id = EntityLoad( "data/entities/particles/perks/" .. perk_data.particle_effect .. ".xml" )

		if ( no_remove == false ) then
			EntityAddTag( particle_id, "perk_entity" )
		end

		EntityAddChild( player_entity, particle_id )
	end

	-- certain other perks may be marked as picked-up
	if perk_data.remove_other_perks ~= nil then
		for _,v in ipairs( perk_data.remove_other_perks ) do
			local f = get_perk_picked_flag_name( v )
			GameAddFlagRun( f )
		end
	end

	if perk_data.func ~= nil then
        -- Spawn a dummy perk item for use in the perk function
        perk_entity_id = perk_spawn( pos_x + Random(-1, 1), pos_y, perk_id, true)

		perk_data.func( perk_entity_id, player_entity, perk_data.ui_name, pickup_count )

        EntityKill(perk_entity_id)
	end

	local perk_name = GameTextGetTranslatedOrNot( perk_data.ui_name )
	local perk_desc = GameTextGetTranslatedOrNot( perk_data.ui_description )

	-- add ui icon etc
	local entity_ui = EntityCreateNew( "" )
	EntityAddComponent( entity_ui, "UIIconComponent",
	{
		name = perk_data.ui_name,
		description = perk_data.ui_description,
		icon_sprite_file = perk_data.ui_icon
	})

	if ( no_remove == false ) then
		EntityAddTag( entity_ui, "perk_entity" )
	end

	EntityAddChild( player_entity, entity_ui )

	-- cosmetic fx -------------------------------------------------------
    local enemies_killed = tonumber( StatsBiomeGetValue("enemies_killed") )

    if( enemies_killed ~= 0 ) then
        EntityLoad( "data/entities/particles/image_emitters/perk_effect.xml", pos_x, pos_y )
    else
        EntityLoad( "data/entities/particles/image_emitters/perk_effect_pacifist.xml", pos_x, pos_y )
    end

    GamePrintImportant( GameTextGet( "$log_pickedup_perk", perk_name), perk_desc )
end

local function shuffle_table( t )
	assert( t, "shuffle_table() expected a table, got nil" )
	local iterations = #t
	local j

	for i = iterations, 2, -1 do
		j = Random(1,i)
		t[i], t[j] = t[j], t[i]
	end
end

-- this generates global perk spawn order for current world seed
-- This function should not call setRandomSeed; that resets the distribution generation so that
-- the same sequence of numbers are generated for everything after it
--
-- With the original implementation, Perk Lottery always gave the same success/fail sequences
-- during perk selection, because the original perk selection method relied on resetting the seed
-- again based on the unique x,y positions of the perk entities, which can't be done for ALIEN
local fixed_perk_get_spawn_order = function()
	-- this function should return the same list in the same order no matter when or where during a run it is called.
	-- the expection is that some of the elements in the list can be set to "" to indicate that they're used

	-- 1) Create a Deck from all the perks, add multiple of stackable
	-- 2) Shuffle the Deck
	-- 3) Remove duplicate perks that are too close to each other

	-- NON DETERMISTIC THINGS ARE ALLOWED TO HAPPEN
	-- 4) Go through the perk list and "" the perks we've picked up

	local ignore_these = ignore_these_ or {}

	local MIN_DISTANCE_BETWEEN_DUPLICATE_PERKS = 4
	local DEFAULT_MAX_STACKABLE_PERK_COUNT = 128

	--SetRandomSeed( 1, 2 )

	-- 1) Create a Deck from all the perks, add multiple of stackable
	-- create the perk pool
	-- local perk_pool = {}
	local perk_deck = {}
	local stackable_distances = {}
	local stackable_count = {}			-- -1 = NON_STACKABLE otherwise the result is how many times can be stacked

	-- function create_perk_pool
	for _,perk_data in ipairs(perk_list) do
		if ( ( table_contains( ignore_these, perk_data.id ) == false ) and ( perk_data.not_in_default_perk_pool == nil or perk_data.not_in_default_perk_pool == false ) ) then
			local perk_name = perk_data.id
			local how_many_times = 1
			stackable_distances[ perk_name ] = -1
			stackable_count[ perk_name ] = -1

			if( ( perk_data.stackable ~= nil ) and ( perk_data.stackable == true ) ) then
				local max_perks = Random( 1, 2 )
				-- TODO( Petri ): We need a new variable that indicates how many times they can appear in the pool
				if( perk_data.max_in_perk_pool ~= nil ) then
					max_perks = Random( 1, perk_data.max_in_perk_pool )
				end

				if( perk_data.stackable_maximum ~= nil ) then
					stackable_count[ perk_name ] = perk_data.stackable_maximum
				else
					stackable_count[ perk_name ] = DEFAULT_MAX_STACKABLE_PERK_COUNT
				end

				if( ( perk_data.stackable_is_rare ~= nil ) and ( perk_data.stackable_is_rare == true ) ) then
					max_perks = 1
				end

				stackable_distances[ perk_name ] = perk_data.stackable_how_often_reappears or MIN_DISTANCE_BETWEEN_DUPLICATE_PERKS

				how_many_times = Random( 1, max_perks )
			end

			for j=1,how_many_times do
				table.insert( perk_deck, perk_name )
			end
		end
	end

	-- 2) Shuffle the Deck
	shuffle_table( perk_deck )

	-- 3) Remove duplicate perks that are too close to each other
	-- we need to do this in reverse, since otherwise table.remove might cause the iterator to bug out
	for i=#perk_deck,1,-1 do

		local perk = perk_deck[i]
		if( stackable_distances[ perk ] ~= -1 ) then

			local min_distance = stackable_distances[ perk ]
			local remove_me = false

			--  ensure stackable perks are not spawned too close to each other
			for ri=i-min_distance,i-1 do
				if ri >= 1 and perk_deck[ri] == perk then
					remove_me = true
					break
				end
			end

			if( remove_me ) then table.remove( perk_deck, i ) end
		end
	end

	-- NON DETERMINISTIC THINGS ARE ALLOWED TO HAPPEN
	-- 4) Go through the perk list and "" the perks we've picked up
	-- remove non-stackable perks already collected from the list
	for i,perk_name in pairs( perk_deck ) do
		local flag_name = get_perk_picked_flag_name( perk_name )
		local pickup_count = tonumber( GlobalsGetValue( flag_name .. "_PICKUP_COUNT", "0" ) )

		-- GameHasFlagRun( flag_name ) - this is if its ever been spawned
		-- has been picked up
		if( ( pickup_count > 0 ) ) then
			local stack_count = stackable_count[ perk_name ] or -1
			-- print( perk_name .. ": " .. tostring( stack_count ) )
			if( ( stack_count == -1 ) or ( pickup_count >= stack_count ) ) then
				perk_deck[i] = ""
			end
		end
	end

	-- DEBUG
	if( false ) then
		for i,perk in ipairs(perk_deck) do
			print(  tostring( i ) .. ": " .. perk )
		end
	end

	return perk_deck
end

function GeneratePerkList(perk_count, skip_list)

    -- All available perks should have been removed already

    skip_list = skip_list or {}

    local perks = perk_get_spawn_order(skip_list)
    --local perks = fixed_perk_get_spawn_order()

	local next_perk_index = tonumber( GlobalsGetValue( "TEMPLE_NEXT_PERK_INDEX", "1" ) )
	local perk_id = perks[next_perk_index]

    for _ = 1, perk_count do
        while( perk_id == nil or perk_id == "" ) do
            -- if we over flow
            perks[next_perk_index] = "LEGGY_FEET"
            next_perk_index = next_perk_index + 1
            if next_perk_index > #perks then
                next_perk_index = 1
            end
            perk_id = perks[next_perk_index]

	    end

        next_perk_index = next_perk_index + 1
        if next_perk_index > #perks then
            next_perk_index = 1
        end
        GlobalsSetValue( "TEMPLE_NEXT_PERK_INDEX", tostring(next_perk_index) )

        StoreAvailablePerkID(perk_id)
        perk_id = perks[next_perk_index]
    end

    StorePerkRerollCost()
end

function PlayerShouldLevelUp()
    return GetAvailablePerkNum() == 0 and GetLevelUpCost() <= GetPlayerXP()
end

local doPerformLevelUp = function()
    local perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3"))
    GeneratePerkList(perk_count)

    local old_player_level = GetPlayerLevel()

    SetPlayerXP(GetPlayerXP() - GetLevelUpCost())

    SetPlayerLevel(old_player_level + 1)

    RemoveStoredLevelUpCost(old_player_level) -- Clean up unused VariableStorageComponent to reduce tag usage

    return old_player_level + 1
end

function RenderLevelUpAnimation()

    local player_entity = get_players()[1]

    local x,y = EntityGetTransform(player_entity)

    EntityLoad("mods/ALIEN/image_emitters/level_up_effect.xml", x, y)
end

function PerformLevelUp()

    local player_level = doPerformLevelUp()

    RenderLevelUpAnimation()

    GamePrintImportant("Level Up!", "You're now level " .. player_level .. "!")

end

local doTabletLevelUp = function()
    local current_level = GetPlayerLevel()

    local temple_levels_cost = getAlienSetting("temple_levels_cost")

    if (temple_levels_cost == "full") then
        local nextLevelUpCost = GetLevelUpCostAt(current_level) + GetLevelUpCostAt(current_level + 1)
        SetLevelUpCost(current_level + 1, nextLevelUpCost / tonumber(getAlienSetting("xp_cost_scaling")))
    elseif (temple_levels_cost == "lose_xp") then
        SetPlayerXP(0)
    -- elseif (temple_levels_free == "keep_xp") then
        -- pass
    end

    SetLevelUpCost(current_level, 0)

    if (PlayerShouldLevelUp()) then
        PerformLevelUp()
    end
end

function PerformDivineTabletEffect()

    local timesVisitedTemple = GetTimesVisitedTemple()

    local temple_gives_level = getAlienSetting("temple_gives_level")

    timesVisitedTemple = timesVisitedTemple + 1
    if (temple_gives_level == "always" or (temple_gives_level == "if_behind" and GetPlayerLevel() < (timesVisitedTemple + 1))) then
        GamePrintImportant("Divine Tablet", "The gods grant you power above wisdom.")
        doTabletLevelUp()
    else
        GamePrintImportant("Divine Tablet", "The gods are silent.")
    end

    SetTimesVisitedTemple(timesVisitedTemple)
end


function PerformNightmareTabletEffect()
    GamePrintImportant("The Shattered God", "Bring me vengeance.")
    local perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3"))
    GeneratePerkList(perk_count, {"EDIT_WANDS_EVERYWHERE"})
end

function GetAvailablePerkIDs()

    local player_entity = get_players()[1]
    local components = EntityGetComponent(player_entity, "VariableStorageComponent", ALIEN_PERK_TAG)

    if (components == nil or #components == 0) then
        do
            return {}
        end
    end

    local perkIDList = {}

    for _, comp in pairs(components) do
        local perk_id = ComponentGetValue(comp, "value_string")
        table.insert(perkIDList, perk_id)
    end

    return perkIDList
end

function GetAvailablePerks()

    local perkIDList = GetAvailablePerkIDs()
    local perkDataList = {}

    for _, perk_id in pairs(perkIDList) do
        local perk_data = get_perk_with_id(perk_list, perk_id)
        table.insert(perkDataList, perk_data)
    end

    return perkDataList
end

function GetAvailablePerkNum()

    player_entity = get_players()[1]
    local components = EntityGetComponent(player_entity, "VariableStorageComponent", ALIEN_PERK_TAG)

    if (components == nil or #components == 0) then
        do
            return 0
        end
    end

    return #components
end

local performPerkRemoval = function(index)

    local kill_other_perks = GetPlayerLevel() ~= 1

    if kill_other_perks then
        local perk_destroy_chance = tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100"))

        -- Do not repeatedly set randomseed
        -- SetRandomSeed(GameGetFrameNum() * GetAvailablePerkNum(), (x + y) * GetAvailablePerkNum())

        if (Random(1, 100) <= perk_destroy_chance) then
            RemoveAllAvailablePerks()
        else
            RemoveAvailablePerkID(index)
            if (GetAvailablePerkNum() == 0) then
                RemovePerkRerollCost()
            end
        end
    else
        RemoveAvailablePerkID(index)
        if (GetAvailablePerkNum() == 0) then
            RemovePerkRerollCost()
        end
    end


end

function SelectPerk(index, perk_data)

    AddPerkToPlayer(perk_data)

    performPerkRemoval(index)

    if (PlayerShouldLevelUp()) then
        PerformLevelUp()
    end
end

function RerollPerkList()

    local available_perks = GetAvailablePerkNum()
    if (available_perks == 0) then
        do
            return false
        end
    end

    local player_entity = get_players()[1]
    local money = 0

    edit_component(player_entity, "WalletComponent", function(comp, vars)
        money = ComponentGetValueInt(comp, "money")
    end)

    local rerollCost = GetPerkRerollCost()

    if (money < rerollCost) then
        GamePrint("Can't afford to reroll perks..")
        do
            return false
        end
    end

    money = money - rerollCost

    edit_component(player_entity, "WalletComponent", function(comp, vars)
        vars.money = money
    end)

    local perk_reroll_count = tonumber(GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT", "0"))
    perk_reroll_count = perk_reroll_count + 1
    GlobalsSetValue("TEMPLE_PERK_REROLL_COUNT", tostring(perk_reroll_count))

    RemoveAllAvailablePerks()
    GeneratePerkList(available_perks)
end

function DiscardPerks()
    RemoveAllAvailablePerks()
    if (PlayerShouldLevelUp()) then
        PerformLevelUp()
    end
end
