dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/ALIEN/scripts/alien_utils.lua")

local ALIEN_gui = GuiCreate()
local show_alien_UI = false
local togglerMenuString = "ALIEN"
local use_alt_res = UseAlternateResolution()
local use_inventory_gui = UseInventoryGui()
local show_mode_swap_button = ShowModeSwapButton()

local toggler = function(toggle)
    if (toggle) then
        return "[-] "
    else
        return "[+] "
    end
end

function GuiLayoutCoordinates()
    if (not use_alt_res) then
        return 27, 18
    else
        return 22, 14
    end
end

local start_btn_id = 2929
local alien_gui_mode_switcher_id = 3029
local alien_gui_toggler_id = 3030
local perkDataList = {}
local showDiscardBtn = false
local disc_confirm_offset = 60

local prev_level = 0
local level_up_cost = 0
local level_up_cost_str = "0"

local perkFrame = function()

    if (not show_alien_UI and GetAvailablePerkNum() ~= 0) then
        togglerMenuString = " ALIEN (LVL+)"
    else
        togglerMenuString = " ALIEN"
    end

    if GuiButton(ALIEN_gui, 174, 0, toggler(show_alien_UI) .. togglerMenuString, alien_gui_toggler_id) then
        show_alien_UI = not show_alien_UI
    end

    if show_mode_swap_button and GuiButton(ALIEN_gui, 280, 0, "Swap UI Mode", alien_gui_mode_switcher_id) then
        use_inventory_gui = not use_inventory_gui
    end

    if (not show_alien_UI) then
        do
            SetPerkIconsVisible(false)
            return false
        end
    end

    SetPerkIconsVisible(true)

    local current_level = GetPlayerLevel();
    if (current_level ~= prev_level) then
        prev_level = current_level
        level_up_cost = GetLevelUpCost()
        level_up_cost_str = tostring(level_up_cost)
    end
    local current_xp = math.min(GetPlayerXP(), level_up_cost);

    Gui_X, Gui_Y = GuiLayoutCoordinates(use_alt_res)

    GuiLayoutBeginVertical(ALIEN_gui, Gui_X, Gui_Y)
    GuiText(ALIEN_gui, 0, 0, "XP : " .. current_xp .. " / " .. level_up_cost_str)
    GuiText(ALIEN_gui, 0, 0, "Level : " .. current_level)
    GuiLayoutEnd(ALIEN_gui)

    local storeBtnPos = start_btn_id
    local refreshPerkList = false

    if (GetAvailablePerkNum() ~= 0) then
        if (#perkDataList == 0) then
            perkDataList = GetAvailablePerks()
        end

        if (perkDataList ~= nil and #perkDataList ~= 0) then

            local perkRerollCost = GetPerkRerollCost()

            for i, perkData in ipairs(perkDataList) do
                if (GuiButton(ALIEN_gui, GetPerkButtonX(), GetPerkButtonY(i), perkData.ui_name, start_btn_id + i)) then
                    SelectPerk(i, perkData)
                    refreshPerkList = true
                end
            end

            local rerollBtnPos = start_btn_id + #perkDataList + 1

            local utility_x_offset = 480

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
    if ALIEN_gui ~= nil then
        GuiStartFrame(ALIEN_gui)
    end

    if not get_players() or ALIEN_xor(InventoryIsOpen(), use_inventory_gui) then -- !XOR logic for gui preference + current state, write it out on paper..
        SetPerkIconsVisible(false)
        wait(10)
        do
            return
        end
    end

    if perkFrame ~= nil then
        perkFrame()
    end
    wait(0)
end)
