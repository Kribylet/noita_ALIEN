dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.

-- This file can't access other files from this or other mods in all circumstances.
-- Settings will be automatically saved.
-- Settings don't have access unsafe lua APIs.

-- Use ModSettingGet() in the game to query settings.
-- For some settings (for example those that affect world generation) you might want to retain the current value until a certain point, even
-- if the player has changed the setting while playing.
-- To make it easy to define settings like that, each setting has a "scope" (e.g. MOD_SETTING_SCOPE_NEW_GAME) that will define when the changes
-- will actually become visible via ModSettingGet(). In the case of MOD_SETTING_SCOPE_NEW_GAME the value at the start of the run will be visible
-- until the player starts a new game.
-- ModSettingSetNextValue() will set the buffered value, that will later become visible via ModSettingGet(), unless the setting scope is MOD_SETTING_SCOPE_RUNTIME.

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback( mod_id, gui, in_main_menu, setting, old_value, new_value )
	print( tostring(new_value) )
end

local mod_id = "ALIEN" -- This should match the name of your mod's folder.
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value. 
mod_settings = 
{
	{
		id = "_",
		ui_name = "NOTE: ALIEN Mod Setting changes require reloading the game.",
		not_setting = true,
	},
	{
		category_id = "ui_settings",
		ui_name = "UI Settings",
		ui_description = "Configure ALIEN UI Appearance",
		settings = {
			{
				id = "gui_visibility",
				ui_name = "GUI Visibility",
				ui_description = "Controls where the ALIEN UI will be visible.",
				value_default = "inventory",
				values = { {"inventory","Inventory"}, {"world","World"}, {"always","Always"} },
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "gui_expansion_default",
				ui_name = "GUI Default Expanded",
				ui_description = "Set whether the ALIEN UI will be expanded by default.",
				value_default = "no",
				values = { {"no","No"}, {"yes","Yes"} },
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
		},

	},


	{
		category_id = "gameplay_settings",
		ui_name = "Gameplay Settings",
		ui_description = "Configure ALIEN Gameplay",
		settings =
		{
			{
				id = "greed_gold_works",
				ui_name = "Greed Perk Increases XP",
				ui_description = "Extra gold gained from the Greed Perk counts will also give bonus XP.",
				value_default = "no",
				values = { {"no","No"}, {"yes","Yes"} },
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "high_level_growth_mode",
				ui_name = "End Game XP Cost Growth",
				ui_description = "Controls how fast the XP cost for high (8+) levels grows.",
				value_default = "linear",
				values = { {"static", "Does Not Grow"}, {"linear","Linear"}, {"doubles","Doubles"}, {"triples","Triples"}},
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "linear_level_cost_growth",
				ui_name = "Linear Level Cost Growth",
				ui_description = "How much XP level cost grows by in linear mode. Default: 1000",
				value_default = "1000",
				text_max_length = 7,
				allowed_characters = "0123456789",
				scope = MOD_SETTING_SCOPE_NEW_GAME,
				change_fn = mod_setting_change_callback, -- Called when the user interact with the settings widget.
			},
			{
				id = "xp_cost_scaling",
				ui_name = "XP Requirement Scaling",
				ui_description = "Scales all XP requirements by this factor.",
				value_default = "1",
				values = { {"0.5", "0.5x"}, {"1","1x"}, {"2","2x"}, {"3","3x"}},
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "temple_gives_level",
				ui_name = "Temple Level Ups",
				ui_description = "Sets how temples give level ups.",
				value_default = "if_behind",
				values = { {"never", "Never"}, {"if_behind","If behind"}, {"always","Always"} },
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "temple_levels_cost",
				ui_name = "Temple Level Up Cost",
				ui_description = "Sets the cost of temple level ups.",
				value_default = "full",
				values = { {"full", "Full (XP Cost Saved)"}, {"lose_xp","Discount (Pay Current XP)"}, {"keep_xp","Free (Keep Current XP)"} },
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "perk_storage",
				ui_name = "Perk Storage",
				ui_description = "Controls where stored perk sets can be retrieved.",
				value_default = "biome",
				values = { {"biome", "Same Biome"}, {"global","Global"} },
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			--{
			--	id = "ground_gold_works",
			--	ui_name = "Ground Gold Gives XP",
			--	ui_description = "Gold picked up from the ground will count towards XP.",
			--	value_default = "no",
			--	values = { {"no","No"}, {"yes","Yes"} },
			--	scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			--	change_fn = mod_setting_change_callback, -- Called when the user interact with the settings widget.
			--},
		},
	},
}

-- This function is called to ensure the correct setting values are visible to the game via ModSettingGet(). your mod's settings don't work if you don't have a function like this defined in settings.lua.
-- This function is called:
--		- when entering the mod settings menu (init_scope will be MOD_SETTINGS_SCOPE_ONLY_SET_DEFAULT)
-- 		- before mod initialization when starting a new game (init_scope will be MOD_SETTING_SCOPE_NEW_GAME)
--		- when entering the game after a restart (init_scope will be MOD_SETTING_SCOPE_RESTART)
--		- at the end of an update when mod settings have been changed via ModSettingsSetNextValue() and the game is unpaused (init_scope will be MOD_SETTINGS_SCOPE_RUNTIME)
function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id ) -- This can be used to migrate some settings between mod versions.
	mod_settings_update( mod_id, mod_settings, init_scope )
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic.
-- The value will be used to determine whether or not to display various UI elements that link to mod settings.
-- At the moment it is fine to simply return 0 or 1 in a custom implementation, but we don't guarantee that will be the case in the future.
-- This function is called every frame when in the settings menu.
function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

-- This function is called to display the settings UI for this mod. Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )

	--example usage:
	--[[
	local im_id = 124662 -- NOTE: ids should not be reused like we do below
	GuiLayoutBeginLayer( gui )

	GuiLayoutBeginHorizontal( gui, 10, 50 )
    GuiImage( gui, im_id + 12312535, 0, 0, "data/particles/shine_07.xml", 1, 1, 1, 0, GUI_RECT_ANIMATION_PLAYBACK.PlayToEndAndPause )
    GuiImage( gui, im_id + 123125351, 0, 0, "data/particles/shine_04.xml", 1, 1, 1, 0, GUI_RECT_ANIMATION_PLAYBACK.PlayToEndAndPause )
    GuiLayoutEnd( gui )

	GuiBeginAutoBox( gui )

	GuiZSet( gui, 10 )
	GuiZSetForNextWidget( gui, 11 )
	GuiText( gui, 50, 50, "Gui*AutoBox*")
	GuiImage( gui, im_id, 50, 60, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiZSetForNextWidget( gui, 13 )
	GuiImage( gui, im_id, 60, 150, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )

	GuiZSetForNextWidget( gui, 12 )
	GuiEndAutoBoxNinePiece( gui )

	GuiZSetForNextWidget( gui, 11 )
	GuiImageNinePiece( gui, 12368912341, 10, 10, 80, 20 )
	GuiText( gui, 15, 15, "GuiImageNinePiece")

	GuiBeginScrollContainer( gui, 1233451, 500, 100, 100, 100 )
	GuiLayoutBeginVertical( gui, 0, 0 )
	GuiText( gui, 10, 0, "GuiScrollContainer")
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiImage( gui, im_id, 10, 0, "data/ui_gfx/game_over_menu/game_over.png", 1, 1, 0 )
	GuiLayoutEnd( gui )
	GuiEndScrollContainer( gui )

	local c,rc,hov,x,y,w,h = GuiGetPreviousWidgetInfo( gui )
	print( tostring(c) .. " " .. tostring(rc) .." " .. tostring(hov) .." " .. tostring(x) .." " .. tostring(y) .." " .. tostring(w) .." ".. tostring(h) )

	GuiLayoutEndLayer( gui )
	]]--
end
