dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/ALIEN/scripts/alien_utils.lua")

local ALIEN_gui = GuiCreate()
local show_alien_UI = getAlienSetting("gui_expansion_default") == "yes"
local togglerMenuString = "ALIEN"

local gui_z = -9000
local tooltip_z = -100

local toggler = function(toggle)
    if (toggle) then
        return "[-] "
    else
        return "[+] "
    end
end

local start_btn_id = 2929
local current_btn_id = nil

function next_id()
    if current_btn_id then
        current_btn_id = current_btn_id + 1
    else
        current_btn_id = start_btn_id
    end
    return current_btn_id
end

local perkDataList = {}
local showDiscardBtn = false
local disc_confirm_offset = 60

local prev_level = 0
local level_up_cost = 0
local level_up_cost_str = "0"

GuiZSet(ALIEN_gui, gui_z)

local max_line_length = 40

function renderTooltip(x, y, perk_data)
    local screen_width, screen_height = GuiGetScreenDimensions( ALIEN_gui )
    GuiZSet(ALIEN_gui, tooltip_z)

    local perk_desc = GetPerkDescription(perk_data)

    local sentences = sentence_split(perk_desc, max_line_length)

    GuiLayoutBeginLayer(ALIEN_gui)
        GuiZSet(ALIEN_gui, tooltip_z)
        GuiLayoutBeginVertical(ALIEN_gui, x / screen_width * 100.0, y / screen_height * 100.0 )
            GuiBeginAutoBox(ALIEN_gui)
                for i, sentence in ipairs(sentences) do
                    GuiText(ALIEN_gui, 0, 0, sentence )
                end
                GuiZSetForNextWidget(ALIEN_gui, tooltip_z + 1)
            GuiEndAutoBoxNinePiece(ALIEN_gui)
        GuiLayoutEnd(ALIEN_gui)
    GuiLayoutEndLayer(ALIEN_gui)
    GuiZSet(ALIEN_gui, 1000)
end

local perkFrame = function()

    if (not show_alien_UI and GetAvailablePerkNum() ~= 0) then
        togglerMenuString = " ALIEN (LVL+)"
    else
        togglerMenuString = " ALIEN"
    end

    if GuiButton(ALIEN_gui, 174, 0, toggler(show_alien_UI) .. togglerMenuString, next_id()) then
        show_alien_UI = not show_alien_UI
    end

    if (not show_alien_UI) then
        do
            return false
        end
    end

    if GuiButton(ALIEN_gui, 185, 44, "Gimme nuggies", next_id()) then
        local x, y = EntityGetTransform(get_players()[1])
        for i=1,10 do
            EntityLoad("data/entities/items/pickup/goldnugget_10000.xml", x, y)
        end
    end

    if GuiButton(ALIEN_gui, 400, 44, "Gimme extra", next_id()) then
        AddPerkToPlayer(get_perk_with_id(perk_list, "EXTRA_PERK"))
    end


    if GuiButton(ALIEN_gui, 185, 54, "Gimme chuggies", next_id()) then
        local x, y = EntityGetTransform(get_players()[1])
        local entity_id = EntityLoad("data/entities/items/pickup/potion.xml", x, y)
        AddMaterialInventoryMaterial( entity_id, "mat_magic_liquid_random_polymorph", 1000 ) -- bad
    end

    local current_level = GetPlayerLevel();
    if (current_level ~= prev_level) then
        prev_level = current_level
        level_up_cost = GetLevelUpCost()
        level_up_cost_str = tostring(level_up_cost)
    end
    local current_xp = math.min(GetPlayerXP(), level_up_cost);

    GuiLayoutBeginVertical(ALIEN_gui, 185, 64, true)
    GuiText(ALIEN_gui, 0, 0, "XP : " .. current_xp .. " / " .. level_up_cost_str)
    GuiText(ALIEN_gui, 0, 0, "Level : " .. current_level)
    GuiLayoutEnd(ALIEN_gui)

    local refreshPerkList = false

    if (GetAvailablePerkNum() ~= 0) then
        if (#perkDataList == 0) then
            perkDataList = GetAvailablePerks()
        end

        if (perkDataList ~= nil and #perkDataList ~= 0) then

            local perkRerollCost = GetPerkRerollCost()

            for i, perk_data in ipairs(perkDataList) do
                local button_x = GetPerkButtonX()
                local button_y = GetPerkButtonY(i)
                local perk_name = GameTextGetTranslatedOrNot(perk_data.ui_name)
                GuiImageButton(ALIEN_gui, next_id(), button_x, button_y, "", perk_data.ui_icon)
                local left_click,right_click,hover,x,y,width,height,draw_x,draw_y = GuiGetPreviousWidgetInfo(ALIEN_gui)
                if left_click then
                    SelectPerk(i, perk_data)
                    refreshPerkList = true
                elseif hover then
                    renderTooltip(x + width, y + height, perk_data)
                else
                    -- Do clickable text as well
                    GuiButton(ALIEN_gui, next_id(), button_x + 16, button_y + 3, perk_name)
                    local left_click,right_click,hover,x,y,width,height,draw_x,draw_y = GuiGetPreviousWidgetInfo(ALIEN_gui)
                    if left_click then
                        SelectPerk(i, perk_data)
                        refreshPerkList = true
                    elseif hover then
                        renderTooltip(x + width, y + height, perk_data)
                    end
                end

            end

            local utility_x_offset = 480

            if GuiButton(ALIEN_gui, utility_x_offset, 60, "Reroll (" .. perkRerollCost .. ")", next_id()) then
                RerollPerkList()
                refreshPerkList = true
            end

            if GuiButton(ALIEN_gui, utility_x_offset, 70, "Discard Perks?", next_id()) then
                showDiscardBtn = not showDiscardBtn
            end

            if (showDiscardBtn) then
                if GuiButton(ALIEN_gui, utility_x_offset + disc_confirm_offset, 70, "- CONFIRM", next_id()) then
                    DiscardPerks()
                    showDiscardBtn = false
                    refreshPerkList = true
                end
            end

            if GuiButton(ALIEN_gui, utility_x_offset, 80, "Store Perks", next_id()) then
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
                "Perk Set " .. i .. " (" .. biomeName .. ")", next_id()) then
                LoadStoredPerkSet(i)
                refreshPerkList = true
            end
        end
    end

    if (refreshPerkList) then
        perkDataList = {}
    end
end

local gui_visibility = getAlienSetting("gui_visibility")
if (gui_visibility == "inventory") then
    ui_render_wait = function()
        return (getPlayerEntity() == nil or not InventoryIsOpen())
    end
elseif (gui_visibility == "world") then
    ui_render_wait = function()
        return (getPlayerEntity() == nil or InventoryIsOpen())
    end
else -- always
    ui_render_wait = function()
        return (getPlayerEntity() == nil)
    end
end

async_loop(function()
    if ALIEN_gui ~= nil then
        GuiStartFrame(ALIEN_gui)
    end

    if ui_render_wait() then
        wait(10)
        do
            return
        end
    end


    if perkFrame ~= nil then
        current_btn_id = start_btn_id
        perkFrame()
    end
    wait(0)
end)
