dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/ALIEN/scripts/alien_utils.lua")

local ALIEN_gui = GuiCreate()
local showUI = true
local togglerMenuString = "ALIEN"

local toggler = function(showUI)
    local toggleString = "[-] "
    if (not showUI) then
        toggleString = "[+] "
    end
    return toggleString
end

local start_btn_id = 2929
local perkDataList = {}
local showDiscardBtn = false
local disc_confirm_offset = 60

local prev_level = 0
local level_up_cost = 0
local level_up_cost_str = "0"

local perkFrame = function()

    if GuiButton(ALIEN_gui, 185, 54, toggler(showUI) .. togglerMenuString, 3030) then
        showUI = not showUI
    end

    if (not showUI) then
        do
            return false
        end
    end

    local current_level = GetPlayerLevel();
    if (current_level ~= prev_level) then
        prev_level = current_level
        level_up_cost = GetLevelUpCost()
        level_up_cost_str = tostring(level_up_cost)
    end
    local current_xp = math.min(GetPlayerXP(), level_up_cost);

    GuiLayoutBeginVertical(ALIEN_gui, 29, 18)
    GuiText(ALIEN_gui, 0, 0, "XP : " .. current_xp .. " / " .. level_up_cost_str)
    GuiText(ALIEN_gui, 0, 0, "Level : " .. current_level)
    GuiLayoutEnd(ALIEN_gui)

    if GuiButton(ALIEN_gui, 185, 44, "Gimme nuggies", 3030) then
        local x, y = EntityGetTransform(get_players()[1])
		EntityLoad("data/entities/items/pickup/goldnugget_10000.xml", x, y)
    end

    local storeBtnPos = start_btn_id
    local refreshPerkList = false

    if (GetAvailablePerkNum() ~= 0) then
        if (#perkDataList == 0) then
            perkDataList = GetAvailablePerks()
        end

        if (perkDataList ~= nil and #perkDataList ~= 0) then

            local perkRerollCost = GetPerkRerollCost()

            for i, perkData in ipairs(perkDataList) do
                if GuiButton(ALIEN_gui, 300, 44 + 10 * i, perkData.ui_name, start_btn_id + i) then
                    SelectPerk(perkData)
                    refreshPerkList = true
                end
            end

            local rerollBtnPos = start_btn_id + #perkDataList + 1

            local utility_x_offset = 430

            if GuiButton(ALIEN_gui, utility_x_offset, 54, "Reroll (" .. perkRerollCost .. ")", rerollBtnPos) then
                RerollPerkList()
                refreshPerkList = true
            end

            local showDiscardBtnPos = rerollBtnPos + 1

            if GuiButton(ALIEN_gui, utility_x_offset, 64, "Discard Perks?", showDiscardBtnPos) then
                showDiscardBtn = not showDiscardBtn
            end

            local discardBtnPos = showDiscardBtnPos + 1

            if (showDiscardBtn) then
                if GuiButton(ALIEN_gui, utility_x_offset + disc_confirm_offset, 64, "- CONFIRM", discardBtnPos) then
                    DiscardPerks()
                    showDiscardBtn = false
                    refreshPerkList = true
                end
            end

            storeBtnPos = discardBtnPos + 1

            if GuiButton(ALIEN_gui, utility_x_offset, 74, "Store Perks", storeBtnPos) then
                StorePerkSet()
                refreshPerkList = true
            end
        end
    end

    local StoredPerkSetIndices = GetStoredPerkSetIndices()

    if (#StoredPerkSetIndices ~= 0) then
        local x_offset = 0
        local y_offset = 0
        for _, i in pairs(StoredPerkSetIndices) do
            local biomeName = GetStoredBiome(i)
            if (biomeName == nil) then
                break
            end
            if (i >= 4) then
                x_offset = 100
                y_offset = -30
            end
            if GuiButton(ALIEN_gui, 185 + x_offset, 114 + 10 * i + y_offset,
                "Perk Set " .. i .. " (" .. biomeName .. ")", storeBtnPos + i) then
                LoadStoredPerkSet(i)
                refreshPerkList = true
            end
        end
    end

    if (refreshPerkList) then
        perkDataList = {}
    end
end

async_loop(function()
    if not InventoryIsOpen() or GameHasFlagRun("ending_game_completed") or not get_players() then
        wait(10)
        do
            return
        end
    end

    if ALIEN_gui ~= nil then
        GuiStartFrame(ALIEN_gui)
    end

    if perkFrame ~= nil then
        perkFrame()
    end
    wait(0)
end)
