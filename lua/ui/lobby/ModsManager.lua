-- ==========================================================================================
-- * File       : lua/modules/ui/lobby/ModsManager.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : Contains UI for managing mods in FA lobby
-- ==========================================================================================
local Mods = import("/lua/mods.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Group  = import("/lua/maui/group.lua").Group
local Text   = import("/lua/maui/text.lua").Text
local Edit   = import("/lua/maui/edit.lua").Edit
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Combo  = import("/lua/ui/controls/combo.lua").Combo

local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local RadioButton = import("/lua/ui/controls/radiobutton.lua").RadioButton
local Prefs = import("/lua/user/prefs.lua")
-- this version of Checkbox allows scaling of checkboxes
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local ToggleButton = import("/lua/ui/controls/togglebutton.lua").ToggleButton
local RestrictedData = import("/lua/ui/lobby/unitsrestrictions.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local ModsBlacklist = import("/etc/faf/blacklist.lua").Blacklist
local SetUtils = import("/lua/system/setutils.lua")
local Links = import("/lua/system/utils.links.lua")

local GUI = { 
    isOpen = false, 
    modListCounter = 1,
    modListExpandedIcon = '/textures/ui/common/mods/mod_list_expand.dds', 
    modListColapsedIcon = '/textures/ui/common/mods/mod_list_collapse.dds', 
    modFallbackIcon = '/textures/ui/common/mods/generic-icon_bmp.dds',
    modFavoriteIcon = '/textures/ui/common/mods/mod_favorite.dds', 
    modSearchIcon = '/textures/ui/common/mods/mod_search.dds', 
    modWebisteIcon = '/textures/ui/common/mods/mod_url_website.dds', 
    modSourceIcon = '/textures/ui/common/mods/mod_url_source.dds', 
}

local IsHost = false

local controlList = {}
local controlMap = {}

local dialogWidth = 850
local dialogHeight = 750
local modIconSize = 50
local modInfoPosition = modIconSize + 20
local modInfoHeight = modIconSize + 20
local modInfoDesciptionMax = 235
-- calculates how many number of mods to show per page based on dialog height
local modsPerPage = math.floor((dialogHeight - 100) / modInfoHeight)

-- Counters for the benefit of the UI.
local numEnabledUIMods = 0
local numEnabledSimMods = 0

local scrollGroup
local dialogContent
local subtitle
local modsDialog
local modSearch = {}

local callback

local mods = {
    -- lookup table with uid of mods that are selectable
    selectable = {},
    -- lookup table with uid of mods that are activated
    activated = {},
    -- mods that are disabled by the mod_info flag
    disabled = {},
    -- mods that are disabled by the FAF blacklist
    blacklisted = {},
    -- mods that are disabled because not everyone has them
    missingByOthers = {},
    -- mods that are disabled because dependencies are not installed
    missingDependencies = {},
    -- mods that change sim/game
    sim = { active = {}, inactive = {} },
    -- mods that change UI
    ui = { active = {}, inactive = {} },
    -- mods that are available to all players (passed from lobby.lua)
    availableToAll = {},
    -- mods added as favorite mods by a local player - saved in Game.prefs file
    favorite = {},
    -- mods sort key used to order mod list - saved in Game.prefs file
    sortKey = 'status',
    -- mods list expanded or collapsed (show/hide mod descriptions/icons) - saved in Game.prefs file
    expanded = true,
    -- store mod search keyword
    searchKeyword = false,
}

local modSortConfigurations = {
    { id = 'status', name = 'Status', tooltip = 'sorts mods by activation status, type, and name' },
    { id = 'type', name = 'Type', tooltip = 'sorts mods by type and name' },
    { id = 'title', name = 'Name', tooltip = 'sorts mods by name' },
    { id = 'author', name = 'Author', tooltip = 'sorts mods by author and name' },
    { id = 'version', name = 'Version', tooltip = 'sorts mods by version and name' },
}

-- Maps uids to the output of Mods.GetDependencies(uid)
local modDependencyMap = {}

-- Maps uids to sets of uids of mods that depend on the first uid
local modBackwardDependencyMap = {}

function UpdateClientModStatus()
    if GUI.isOpen then
        modsDialog:Close()
        GUI.isOpen = false
    end
end

-- Returns true iff every peer in the game reports having a mod with the given id installed.
local function EveryoneHasMod(modID)
    if not IsHost then
        return true
    end
    for _, peerMods in mods.availableToAll do
        if not peerMods[modID] then
            return false
        end
    end
    return true
end

local modsTags = {
 UI = {
    icon  = '/textures/ui/common/mods/mod_type_gui.dds', 
    label = LOC('<LOC uiunitmanager_10>UI MODS'),
    text  = LOC('<LOC uiunitmanager_03>Filter UI Mods'),
    body  = LOC('<LOC uiunitmanager_04>Toggle visibility of all UI mods in above list of mods.') },
 GAME = {
    icon  = '/textures/ui/common/mods/mod_type_sim.dds', 
    label = LOC('<LOC uiunitmanager_11>GAME MODS'),
    text  = LOC('<LOC uiunitmanager_01>Filter Game Mods'),
    body  = LOC('<LOC uiunitmanager_02>Toggle visibility of all game mods in above list of mods.') },
 BLACKLISTED = {
    icon  = '/textures/ui/common/mods/mod_type_blacklisted.dds', 
    label = LOC('<LOC uiunitmanager_13>BLACKLISTED'),
    text  = LOC('<LOC uiunitmanager_05>Filter Blacklisted Mods'),
    body  = LOC('<LOC uiunitmanager_06>Toggle visibility of blacklisted mods in above list of mods.')},
 LOCAL = {
    icon  = '/textures/ui/common/mods/mod_type_warning.dds', 
    label = LOC('<LOC uiunitmanager_14>LOCAL MODS'),
    text  = LOC('<LOC uiunitmanager_18>Filter Local Mods'),
    body  = LOC('<LOC uiunitmanager_19>Toggle visibility of game mods that are missing by other players') },
 NO_DEPENDENCY = {
    icon  = '/textures/ui/common/mods/mod_type_warning.dds', 
    label = LOC('<LOC uiunitmanager_15>NO DEPENDENCY'),
    text  = LOC('<LOC uiunitmanager_16>Filter Missing Dependency Mods'),
    body  = LOC('<LOC uiunitmanager_17>Toggle visibility of mods that are missing dependency in above list of mods.') },
}

-- Create the dialog for Mod Manager
-- @param parent UI control to create the dialog within.
-- @param IsHost Is the user opening the control the host (and hence able to edit?)
-- @param availableMods Present only if user is host. The availableMods map from lobby.lua.
function CreateDialog(parent, isHost, availableMods, saveBehaviour)
    IsHost = isHost
    callback = saveBehaviour
    mods.availableToAll = availableMods

    LoadPreferences() -- loading preference for favorite mods, mods sorting order, mod list expanded/collapsed
    LoadMods() -- loading mods before creating mod filters so they show correct count of mods

    dialogHeight = GetFrame(0).Height() - LayoutHelpers.ScaleNumber(120)
    dialogContent = Group(parent)
    LayoutHelpers.SetWidth(dialogContent, dialogWidth)
    dialogContent.Height:Set(dialogHeight)

    modsDialog = Popup(parent, dialogContent)
    modsDialog.OnClose = function()
        GUI.isOpen = false
    end

    -- Title
    local title = UIUtil.CreateText(dialogContent, '<LOC _Mod_Manager>Mods Manager', 20, UIUtil.titleFont)
    title:SetColor('B9BFB9')
    title:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent, 0)
    LayoutHelpers.AtTopIn(title, dialogContent, 5)

    -- SubTitle: display counts of how many mods are enabled.
    subtitle = UIUtil.CreateText(dialogContent, '', 12, 'Arial')
    subtitle:SetColor('B9BFB9')
    subtitle:SetDropShadow(true)
    LayoutHelpers.AtHorizontalCenterIn(subtitle, dialogContent, 0)
    LayoutHelpers.AtTopIn(subtitle, dialogContent, 26)

    CreateSortComboBox()

    -- creating a toggle for activating favorite mods
    local favoriteModsToggle = CreateFavoriteButton(dialogContent, 25, false, true)
    LayoutHelpers.AtLeftIn(favoriteModsToggle.Icon, dialogContent, 18)
    LayoutHelpers.AtTopIn(favoriteModsToggle.Icon, dialogContent, 14)
    favoriteModsToggle.isCheckable = false 
    favoriteModsToggle.Fill:SetSolidColor('FF999898')  -- '#FF999898'
    favoriteModsToggle.Icon.Depth:Set(function() return dialogContent.Depth() + 100 end)
    favoriteModsToggle.OnClick = function(self, event)
        if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then 
            if event.Modifiers.Right then
                mods.favorite = {}
                RefreshModsList()
            elseif event.Modifiers.Left then
                for uid, _ in mods.activated do
                    local mod = mods.selectable[uid]
                    -- deactivating GAME mods if player is hosting
                    if mod and not mod.ui_only and IsHost then
                        mods.activated[uid] = nil
--                        WARN('deactivate SIM mod ' .. tostring(uid) )
                    end
                    -- deactivating UI mods
                    if mod and mod.ui_only then
                       mods.activated[uid] = nil
--                       WARN('deactivate UI mod ' .. tostring(uid) )
                    end 
                end
                
               for uid, _ in mods.favorite do
                   local mod = mods.selectable[uid]
                    -- activating favorite GAME mods if player is hosting
                   if mod and not mod.ui_only and IsHost then
                       ActivateMod(uid, true) 
--                       WARN('activate SIM mod ' .. tostring(uid) )
                   end
                    -- activating favorite UI mods 
                   if mod and mod.ui_only then
                      ActivateMod(uid, true) 
--                      WARN('activate UI mod ' .. tostring(uid) )
                   end
               end
               RefreshModsList()
            end
        end
        return true
    end
    AddTooltip(favoriteModsToggle, 'Activate Favorite Mods', 
    'Activate mods that you marked as your favorite mods. \n' .. 
    'For host player, left click activates your favorite UI mods and GAME mods. \n' ..
    'For other players, left click activates only your favorite UI mods. \n\n' ..
    'For any player, right click clears the list of your favorite mods.', 480)

    local listExpander = Bitmap(dialogContent, GUI.modListExpandedIcon) 
    listExpander:EnableHitTest()
    LayoutHelpers.SetDimensions(listExpander, 25, 25)
    LayoutHelpers.AnchorToRight(listExpander, favoriteModsToggle, 4)
    LayoutHelpers.AtTopIn(listExpander, dialogContent, 14)
    listExpander.HandleEvent = function(self, event)
        OnButtonHighlight(self, event)
        if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            mods.expanded = not mods.expanded
            RefreshModsList()
            listExpander:Update()
        end
        return true
    end
    listExpander.Update = function(self)
        if mods.expanded then
            self.tooltip = { text = 'Collapse Mod List', body = "Collapse the list of mods by hiding mods' icons and descriptions " }
            self:SetTexture(GUI.modListColapsedIcon)
        else
            self.tooltip = { text = 'Expand Mod List', body = "Expand the list of mods by showing mods' icons and descriptions " }
            self:SetTexture(GUI.modListExpandedIcon)
        end
    end
    listExpander:Update()
    AddTooltip(listExpander, 'Toggle Mod List', "Toggle visibility of mod icons and descriptions in the list below")

    -- Save button
    local SaveButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _OK>OK", -1)
    LayoutHelpers.AtHorizontalCenterIn(SaveButton, dialogContent)
    LayoutHelpers.AtBottomIn(SaveButton, dialogContent, 15)
    
    controlList = {}

    CreateFilters()

    scrollGroup = Group(dialogContent)
    LayoutHelpers.AtLeftIn(scrollGroup, dialogContent, 5)
    LayoutHelpers.AnchorToBottom(scrollGroup, subtitle, 10)
    LayoutHelpers.AnchorToTop(scrollGroup, modSearch.Group, 10)
    scrollGroup.Width:Set(function() return dialogContent.Width() - LayoutHelpers.ScaleNumber(30) end)
    scrollGroup.Height:Set(function() return scrollGroup.Bottom() - scrollGroup.Top() end)

    --modsPerPage = math.floor((scrollGroup.Height() - 10) / LayoutHelpers.ScaleNumber(modInfoHeight))

    UIUtil.CreateLobbyVertScrollbar(scrollGroup, 1, 0, 0, 10)
    scrollGroup.top = 1
    
    scrollGroup.GetScrollValues = function(self, axis)
        local controlsCount = table.getsize(self:GetFilteredControls())
        return 1, controlsCount, self.top, math.min(self.top + modsPerPage - 1, controlsCount)
    end

    scrollGroup.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    scrollGroup.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * modsPerPage)
    end

    scrollGroup.ScrollSetTop = function(self, axis, top)
        local controlsCount = table.getsize(self:GetFilteredControls())
        top = math.floor(top)
        if top == self.top then return end
        self.top = math.max(math.min(controlsCount - modsPerPage + 1, top), 1)
        self:CalcVisible()
    end

    scrollGroup.CalcVisible = function(self)
        local top = self.top
        local bottom = self.top + modsPerPage - 1
        local visibleIndex = 1
        local lineIndex = 1
        for index, control in ipairs(controlList) do
            if control.filtered then
                control:Hide()
            elseif visibleIndex < top or visibleIndex > bottom then
                control:Hide()
                visibleIndex = visibleIndex + 1
            else
                control:Show()
                local c = control
                local i = lineIndex
                control.Top:Set(function() return self.Top() + ((i-1) * (c.Height() +2)) end)
                visibleIndex = visibleIndex + 1
                lineIndex = lineIndex + 1
            end
        end
    end

    scrollGroup.GetFilteredControls = function(self)
        local filteredControls = {}
        for index, control in ipairs(controlList) do
            if not control.filtered then
                table.insert(filteredControls, control)
            end
        end
        return filteredControls
    end

    SaveButton.OnClick = function(self)
        SavePreferences() -- saving favorite mods, mods sorting order, mod list expanded/collapsed
        
        mods.searchKeyword = false -- clear mod search input for the next time
        modsDialog:Close()
        GUI.isOpen = false
        if callback then
            mods.ui.active = SetUtils.PredicateFilter(mods.activated,
                function(uid)
                    return mods.selectable[uid].ui_only
                end
            )
            mods.sim.active = SetUtils.Subtract(mods.activated, mods.ui.active)
            table.print(mods.sim.active, 'mods.sim.active')
            table.print(mods.ui.active, 'mods.ui.active')

            callback(mods.sim.active, mods.ui.active)
        else
            import("/lua/mods.lua").SetSelectedMods(mods.activated)
        end

        return mods.activated
    end
    UIUtil.MakeInputModal(dialogContent, function() SaveButton:OnClick() end, function() SaveButton:OnClick() end)

    RefreshModsList()
    
    scrollGroup.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
            return true
        end

        return false
    end
    
    GUI.isOpen = true

    return modsDialog
end

function OnButtonHighlight(self, event)
    if event.Type == 'MouseEnter' then
        self:SetAlpha(1.0, false)
    elseif event.Type == 'MouseExit' then
        self:SetAlpha(0.7, false)
    end
end

function CreateFilters()
    local position = 30
    local offset = 150
    local filterGameMods = CreateFilterButton(dialogContent, 'GAME')
    LayoutHelpers.AtLeftIn(filterGameMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterGameMods, dialogContent, 65)

    position = position + offset
    local filterUIMods = CreateFilterButton(dialogContent, 'UI')
    LayoutHelpers.AtLeftIn(filterUIMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterUIMods, dialogContent, 65)

    position = position + offset
    local filterDisabledMods = CreateFilterButton(dialogContent, 'BLACKLISTED')
    LayoutHelpers.AtLeftIn(filterDisabledMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterDisabledMods, dialogContent, 65)

    position = position + offset
    local filterNoDependencyMods = CreateFilterButton(dialogContent, 'NO_DEPENDENCY')
    LayoutHelpers.AtLeftIn(filterNoDependencyMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterNoDependencyMods, dialogContent, 65)

    position = position + offset
    local filterLocalMods = CreateFilterButton(dialogContent, 'LOCAL')
    LayoutHelpers.AtLeftIn(filterLocalMods, dialogContent, position)
    LayoutHelpers.AtBottomIn(filterLocalMods, dialogContent, 65)

    -- mod search box
    modSearch.Group = Bitmap(dialogContent)
    modSearch.Group:SetSolidColor('FF292828') -- #FF292828 
    modSearch.Group.Height:Set(function() return LayoutHelpers.ScaleNumber(30) end)
    LayoutHelpers.AtLeftIn(modSearch.Group, dialogContent, 15)
    LayoutHelpers.AtRightIn(modSearch.Group, dialogContent, 10)
    LayoutHelpers.AnchorToTop(modSearch.Group, filterGameMods, 10)
    modSearch.Group.Width:Set(function() return modSearch.Group.Right() - modSearch.Group.Left() end)

    modSearch.Icon = Bitmap(dialogContent, GUI.modSearchIcon)
    LayoutHelpers.SetDimensions(modSearch.Icon, 20, 20)
    LayoutHelpers.AtVerticalCenterIn(modSearch.Icon, modSearch.Group, 0)
    LayoutHelpers.AtLeftIn(modSearch.Icon, modSearch.Group, 6)
    
    local text = LOC("<LOC key_mod_manager_search>search for mods by name or author")
    modSearch.Hint = UIUtil.CreateText(modSearch.Group, text, 17, UIUtil.titleFont)
    modSearch.Hint:SetColor('FF727171') -- #FF727171
    modSearch.Hint:DisableHitTest()
    LayoutHelpers.AtHorizontalCenterIn(modSearch.Hint, modSearch.Group)
    LayoutHelpers.AtVerticalCenterIn(modSearch.Hint, modSearch.Group, 0)
    
    modSearch.Clear = UIUtil.CreateText(modSearch.Group, 'X', 17, "Arial Bold")
    modSearch.Clear:SetColor('FF8A8A8A') -- #FF8A8A8A
    modSearch.Clear:EnableHitTest()
    LayoutHelpers.AtVerticalCenterIn(modSearch.Clear, modSearch.Group, 1)
    LayoutHelpers.AtRightIn(modSearch.Clear, modSearch.Group, 9)
    modSearch.Clear.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:SetColor('FFC9C7C7') -- #FFC9C7C7
        elseif event.Type == 'MouseExit' then
            self:SetColor('FF8A8A8A') -- #FF8A8A8A
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            modSearch.Input:SetText('')
            modSearch.Input:AcquireFocus()
        end
        return true
    end

    modSearch.Input = Edit(modSearch.Group)
    modSearch.Input:SetForegroundColor('FFF1ECEC') -- #FFF1ECEC
    modSearch.Input:SetBackgroundColor('001D87B8') -- #001D87B8
    modSearch.Input:SetHighlightForegroundColor(UIUtil.highlightColor)
    modSearch.Input:SetHighlightBackgroundColor("880085EF") --#880085EF
    LayoutHelpers.AnchorToRight(modSearch.Input, modSearch.Icon, 5)
    LayoutHelpers.AtRightIn(modSearch.Input, modSearch.Group, 5)
    LayoutHelpers.AtTopIn(modSearch.Input, modSearch.Group, 4)
    LayoutHelpers.AtBottomIn(modSearch.Input, modSearch.Group, 2)
    modSearch.Input:AcquireFocus()
    modSearch.Input:SetText('')
    modSearch.Input:SetFont(UIUtil.titleFont, 17)
    modSearch.Input:SetMaxChars(30)
    modSearch.Input.OnTextChanged = function(self, newText, oldText)
        mods.searchKeyword = newText:lower():gsub("[%[%]%(%)]",""):gsub(" +"," ")
        if mods.searchKeyword == ' ' or string.len(mods.searchKeyword) == 0 then
           mods.searchKeyword = false
        end
        FilterMods()
    end
end

function FilterMods()
    for i, control in ipairs(controlList) do
        local mod = control.modInfo
        -- check if a mod is filtered by a tag, GUI, SIM, etc.
        local filteredByTag = true
        for name, tag in modsTags do
            if control.modInfo.tags[name] then
                filteredByTag = tag.filtered
            end
        end
        -- check if a mod is filtered by a keyword
        local filteredByKeyword = false
        if mods.searchKeyword then
            if string.find(mod.keywords, mods.searchKeyword) then
                filteredByKeyword = false
            else
                filteredByKeyword = true
            end
        end
        control.filtered = filteredByKeyword or filteredByTag

--        WARN('FilterMods ' .. ' filteredByTag ' .. tostring(filteredByTag) .. ' filteredByKeyword ' .. tostring(filteredByKeyword) .. ' ' .. repr(mod.tags) .. ' ' .. tostring(mod.title))
           
    end
    scrollGroup:ScrollSetTop(nil,2)
    scrollGroup:ScrollSetTop(nil,1)
end

function CreateFilterButton(parent, tag)
    local states = {
        normal   = UIUtil.SkinnableFile('/BUTTON/medium/_btn_up.dds'),
        active   = UIUtil.SkinnableFile('/BUTTON/medium/_btn_down.dds'),
        over     = UIUtil.SkinnableFile('/BUTTON/medium/_btn_over.dds'),
        disabled = UIUtil.SkinnableFile('/BUTTON/medium/_btn_dis.dds'),
    }
    local count = 0
    if tag == 'UI' then
        count = table.getsize(mods.ui.active) + table.getsize(mods.ui.inactive)
    elseif tag == 'GAME' then
        count = table.getsize(mods.sim.active) + table.getsize(mods.sim.inactive)
    elseif tag == 'BLACKLISTED' then
        count = table.getsize(mods.blacklisted) + table.getsize(mods.disabled)
    elseif tag == 'LOCAL' then
        count = table.getsize(mods.missingByOthers)
    elseif tag == 'NO_DEPENDENCY' then
        count = table.getsize(mods.missingDependencies)
    end

    local filterToggle = UIUtil.CreateButton(parent,
            states.active,
            states.active,
            states.highlight,
            states.disabled,
            --' - '.. count,
            modsTags[tag].label .. ' - '.. count,
            11)

    local height = filterToggle.label.Height() + 30
    local width = 180
    filterToggle.tag = tag
    filterToggle.checked = true
    filterToggle.Height:Set(height)
    LayoutHelpers.SetWidth(filterToggle, width)
    filterToggle.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            if not self.checked then
                self.checked = true
                self:SetTexture(states.active)
            else
                self.checked = false
                self:SetTexture(states.normal)
            end
            if modsTags[self.tag] then
               modsTags[self.tag].filtered = not self.checked
            end
            FilterMods()
            return true
        elseif event.Type == 'MouseEnter' then
            self:OnRolloverEvent('enter')
            return true
        elseif event.Type == 'MouseExit' then
            self:OnRolloverEvent('exit')
            return true
        end
    end

    AddTooltip(filterToggle, modsTags[tag].text,  modsTags[tag].body)
    return filterToggle
end

local function UpdateModsCounters()
    subtitle:SetText(LOCF("<LOC uimod_0027>%d game mods and %d UI mods activated", numEnabledSimMods, numEnabledUIMods))
end

function GetModsFiles(mod, pattern)
    local units = '*_unit.bp'
    for k,file in DiskFindFiles(mod.location, pattern) do
        BlueprintLoaderUpdateProgress()
        safecall("loading mod blueprint "..file, doscript, file)
    end
end

-- Gets a name and actual version for specified mod
function GetModNameVersion(mod)
    local name = mod.name

    -- remove old mod version from mod name
    name = string.gsub(name, '[%[%<%{%(%s]+[vV]+%s*%d+[%.%d]*[%]%>%}%)%s]*', '')
    name = StringCapitalize(name)
    name = name:gsub("-", "", 1)

    -- append new mod version to mod name
    if not mod.version then
        name = name .. ' ---- (v1.0)'
    elseif type(mod.version) == 'number' then
        local ver = string.format("v%01.2f", mod.version)
        ver = ver:gsub("%.*0$", "")
        -- append actual mod version to mod name
        name = name .. ' ---- (' .. ver .. ')'
    elseif type(mod.version) == 'string' then
        local ver = mod.version
        -- correct mod version (e.g. 1.1.1 --> 1.11)
        if string.find(ver, "%d%.%d%.%d") then
            ver = StringReverse(ver)
            ver = ver:gsub("%.", "", 1)
            ver = StringReverse(ver)
        elseif not string.find(ver, "%.") then
            ver = ver .. '.0'
        end
        name = name .. ' ---- (v' .. ver .. ')'
    end
    return name
end
-- Gets a name and type for specified mod
function GetModNameType(uid)
    local mod = mods.selectable[uid]
    return mod.type  .. ' mod - '.. mod.title .. ' - ' .. mod.location
end

-- Gets author's name for specified mod
function GetModAuthor(mod)
    local author = 'UNKNOWN'
    if mod and mod.author and mod.author ~= '' then
        if string.len(mod.author) < 20 then
            author = mod.author
        elseif string.find(mod.author, ",") then
            author = StringSplit(mod.author, ',')[1]
        elseif string.find(mod.author, " ") then
            author = StringSplit(mod.author, ' ')[1]
        end
    end
    author = author:gsub("_", "", 1)
    return author
end

-- Append the given list of mods to the UI, applying the given label and activeness state to each.
function AppendMods(modlist, active, enabled, labelParam, labelSet)
    for k, mod in modlist do
        if not mod.uid or not mod.title then
            table.print(mod, 'Invalid Mod \n', WARN)
        else
            GUI.modListCounter = GUI.modListCounter + 1
            local label = labelParam or LOC(labelSet[k])
            local listItem = CreateListElement(scrollGroup, mod, GUI.modListCounter)
            if not enabled then
                listItem.bg:Disable()
                listItem.name:SetColor('FF959595')   -- #FF959595 
                listItem.author:SetColor('FF959595') -- #FF959595
            else
                listItem.name:SetColor('FFE9ECE9')  --  #FFE9ECE9
                listItem.author:SetColor('FFE9ECE9') -- #FFE9ECE9 
            end
            if active then
                LOG('ModsManager activated: ' .. GetModNameType(mod.uid))
            end
            listItem.bg:SetCheck(active, true)
        end
    end
end

-- load mods
function LoadMods()

    local modsLoaded = false

    if table.empty(mods.selectable) then
        mods.selectable = Mods.AllSelectableMods()
        modsLoaded = true
--        WARN('LoadMods ' .. table.getsize(mods.selectable))
    end
    if table.empty(mods.activated) then
        mods.activated = Mods.GetSelectedMods()
        modsLoaded = true
    end
    
    -- skip parsing mods if they were previously loaded
    -- this saves a bit of time on re-opening mods manager
--    if not modsLoaded then return end

    -- reset state of mods
    mods.sim.active = {}
    mods.sim.inactive = {}
    mods.ui.active = {}
    mods.ui.inactive = {}
    -- mods that are disabled by the mod_info flag
    mods.disabled = {}
    -- mods that are disabled because not everyone has them
    mods.missingByOthers = {}
    -- mods that are disabled because dependencies are not installed
    mods.missingDependencies = {}
    -- mods that are disabled by the FAF blacklist
    mods.blacklisted = {}

    -- Construct various filtered lists of mods. We then concatenate these to form the list.
    for uid, mod in mods.selectable do
        mod.units = {}
        mod.title = GetModNameVersion(mod)
        mod.author = GetModAuthor(mod)
        mod.url    = Links.validate(mod.url)
        mod.github = Links.validate(mod.github)

        if not mod.icon or mod.icon == '' or not DiskGetFileInfo(mod.icon) then
            mod.icon = GUI.modFallbackIcon
        end
        -- creating keywords for quick search of mods
        mod.keywords = string.lower(mod.name .. '+' .. (mod.author or '') .. '+' .. (mod.version or '') )

        if mod.ui_only then
            mod.type = 'UI'
        else
            mod.type = 'GAME'
        end

        if ModsBlacklist[uid] then
            -- value is a message explaining why it's blacklisted
            mod.type = 'BLACKLISTED'
            mods.blacklisted[uid] = mod
        elseif mod.enabled == false then
            mod.type = 'BLACKLISTED'
            mods.disabled[uid] = mod
        else
            -- check for the dependencies of mods are installed
            local dependencies = Mods.GetDependencies(uid)
            modDependencyMap[uid] = dependencies
            if dependencies.missing then
                mod.type = 'NO_DEPENDENCY'
                mods.missingDependencies[uid] = mod

            elseif dependencies.requires then
                -- Construct backward-dependency map for this mod (so we can disable this one if
                -- someone turns off something we depend on)
                for k, v in dependencies.requires do
                    -- Dependency on a blacklisted mod?
                    if ModsBlacklist[k] then
                        mod.type = 'NO_DEPENDENCY'
                        mods.missingDependencies[uid] = mod
                    end

                    if not modBackwardDependencyMap[k] then
                        modBackwardDependencyMap[k] = {}
                    end

                    modBackwardDependencyMap[k][uid] = true
                end
            end

            if mod.ui_only then
                -- Is this a UI mod that depends on a sim mod that is turned off?
                if not IsHost and dependencies.requires then
                    for innerUid in dependencies.requires do
                        if not mods.selectable[innerUid].ui_only and not mods.sim.active[innerUid] then
                            mod.type = 'NO_DEPENDENCY'
                            mods.missingDependencies[uid] = mod
                            break
                        end
                    end
                end

                if mods.missingDependencies[uid] then
                    mod.type = 'NO_DEPENDENCY'
                else
                    mod.type = 'UI'
                    if mods.activated[uid] then
                        mods.ui.active[uid] = mod
                    else
                        mods.ui.inactive[uid] = mod
                    end
                end
            else
                -- check if everyone has sim mod otherwise disable it.
                if not EveryoneHasMod(uid) then
                    mod.type = 'LOCAL'
                    mods.missingByOthers[uid] = mod
                -- excluding sim mods that are missing dependency
                elseif mods.missingDependencies[uid] then
                    mod.type = 'NO_DEPENDENCY'
                else
                    mod.type = 'GAME'
                    if mods.activated[uid] then
                        mods.sim.active[uid] = mod
                    else
                        mods.sim.inactive[uid] = mod
                    end
                end
            end
        end
    end

    -- set status and filter tags for all mods
    for uid, mod in mods.selectable do
        mod.tags = {}
        
        if not mod.type then
            mod.type = 'GAME'
        end
        
        if mod.type == 'GAME' or mod.type == 'UI' then
           mod.sort = mod.type 
        else
           mod.sort = 'X' -- ensures blacklisted/disabled mods are sorted last
        end

        mod.tags[mod.type] = true

        if mod.type == 'GAME' then
           mod.status = LOC('<LOC uimod_0029>Game Mod')
        elseif mod.type == 'UI' then
           mod.status = LOC('<LOC uimod_0028>UI Mod')
        elseif mod.type == 'NO_DEPENDENCY' then
           mod.status = LOC('<LOC uimod_0020>Missing dependency')
        elseif mod.type == 'LOCAL' then
           mod.status = LOC('<LOC uimod_0019>Players missing mod')
        elseif mod.type == 'BLACKLISTED' then
           mod.status = ModsBlacklist[uid] or 'Disabled'
        else
           mod.status = 'Unknown Mod'
        end
    end

    -- Make the conflict relation commutative.
    for uid, deps in modDependencyMap do
        if deps.conflicts then
            for conflicter, _ in deps.conflicts do
                -- If the conflicting mod is installed, add a backwards conflict relation.
                if modDependencyMap[conflicter] then
                    if not modDependencyMap[conflicter].conflicts then
                        modDependencyMap[conflicter].conflicts = {}
                    end
                    if not modDependencyMap[conflicter].conflicts[uid] then
--                        WARN("A mod defines a non-commutative conflict set!")
--                        WARN("Adding mod conflict from "..conflicter.." to " .. uid)
                        modDependencyMap[conflicter].conflicts[uid] = true
                    end
                end
            end
        end
    end

    mods.sim.selecatable = {}
    for uid, mod in mods.sim.active do
        mods.sim.selecatable[uid] = mod
    end
    for uid, mod in mods.sim.inactive do
        mods.sim.selecatable[uid] = mod
    end

    mods.ui.selecatable = {}
    for uid, mod in mods.ui.active do
        mods.ui.selecatable[uid] = mod
    end
    for uid, mod in mods.ui.inactive do
        mods.ui.selecatable[uid] = mod
    end
end

-- Refreshes the mod list UI.
function StringReplace(str, remove, add)
    local words = StringSplit(str, remove)
    return StringJoin(words, add)
end

-- Refreshes the mod list UI.
function RefreshModsList()
    if controlList then
        for k, v in controlList do
            v:Destroy()
        end
    end

    controlList = {}
    controlMap = {}
    LoadMods()

    GUI.modListCounter = 0
    if mods.expanded then
        modIconSize = 50
        modInfoPosition = modIconSize + 20
        modInfoHeight = modIconSize + 22 
    else
        modIconSize = 25
        modInfoPosition = 12
        modInfoHeight = modIconSize + 8
     end

    modsScrollableHeight = modSearch.Group.Top() - subtitle.Bottom()
    modsPerPage = math.floor((modsScrollableHeight - 10) / LayoutHelpers.ScaleNumber(modInfoHeight))
 
    -- Create entries for the list of interesting mods
    AppendMods(mods.sim.active, true, true)
    AppendMods(mods.ui.active, true, true)
    if IsHost then
        AppendMods(mods.sim.inactive, false, true)
    end
    AppendMods(mods.ui.inactive, false, true)
    AppendMods(mods.disabled, false, false)

    for uid, mod in mods.missingByOthers do
        LOG('ModsManager others players are missing mod: ' .. mod.title .. ' - ' .. mod.location)
    end
    AppendMods(mods.missingByOthers, false, false, LOC('<LOC uimod_0019>Players missing mod'))
    for uid, mod in mods.missingDependencies do
        LOG('ModsManager is missing dependency for mod: ' .. mod.title .. ' - ' .. mod.location)
    end
    AppendMods(mods.missingDependencies, false, false, LOC('<LOC uimod_0020>Missing dependency'))
    AppendMods(mods.blacklisted, false, false, nil, ModsBlacklist)

    numEnabledUIMods = table.getsize(mods.ui.active)
    numEnabledSimMods = table.getsize(mods.sim.active)

    UpdateModsCounters()

    FilterMods()
    SortMods(mods.sortKey)
end
-- Activates the mod with the given uid
-- @param isRecursing Indicates this is a recursive call (usually pulling in dependencies), so should not prompt the user for input.
function ActivateMod(uid, isRecursing)
    if mods.activated[uid] then
        return
    end

    mods.activated[uid] = true

    -- Dependency checking time!
    local deps = modDependencyMap[uid]

    if deps then
        -- Any conflicting mods activated? We discard exclusive mods to a universal conflict set, so
        -- those are handled here, too.
        if deps.conflicts then
            -- List of uids that need to be disabled for this mod to work.
            local activatedConflictingMods = {}
            for uid, _ in deps.conflicts do
                if mods.activated[uid] then
                    LOG("ModsManager found conflicting: ".. GetModNameType(uid))
                    table.insert(activatedConflictingMods, uid)
                end
            end
            -- Closure copy
            local thisUID = uid
            local doEnable = function()
                for k, uid in activatedConflictingMods do
                    DeactivateMod(uid)
                    ActivateMod(thisUID, true)
                    LOG("ModsManager activated: ".. GetModNameType(thisUID))
                end
            end
            -- Prompt the user, and if they approve, turn off all conflicting mods.
            if not table.empty(activatedConflictingMods) then
                if isRecursing then
                    -- Just quietly get on and do it if it's a recursive call.
                    doEnable()
                else
                    local target = controlMap[uid].bg
                    UIUtil.QuickDialog(dialogContent,
                        "<LOC uimod_0010>This mod conflicts with some of the other mods you have active. Shall we turn those mods off and this one on?",
                        "<LOC _Yes>", doEnable,
                        "<LOC _No>", function() target:SetCheck(false, true) end)
                end
                return
            end
        end
        -- Activate any dependencies. We guaranteed that these all exist earlier on.
        if deps.requires then
            for uid, _ in deps.requires do
                ActivateMod(uid, true)
                LOG("ModsManager activated dependency: ".. GetModNameType(uid))
            end
        end
    end
    controlMap[uid].bg:SetCheck(true, true)

    if mods.selectable[uid].ui_only then
        numEnabledUIMods = numEnabledUIMods + 1
    else
        numEnabledSimMods = numEnabledSimMods + 1
    end

    UpdateModsCounters()
end

function DeactivateMod(uid)
    if not mods.activated[uid] then
        return
    end

    mods.activated[uid] = nil

    -- Check for backward dependencies: do other mods require this one? If so, we should disable
    -- those mods, as well.
    local victims = modBackwardDependencyMap[uid]
    if victims then
        for k, v in victims do
            DeactivateMod(k, true)
        end
    end

    controlMap[uid].bg:SetCheck(false, true)

    if mods.selectable[uid].ui_only then
        numEnabledUIMods = numEnabledUIMods - 1
    else
        numEnabledSimMods = numEnabledSimMods - 1
    end
    UpdateModsCounters()
end

function SortMods(byKey)
    mods.sortKey = byKey
    -- update highlight of sort button based on the sort key
    for id, button in GUI.sortButtons or {} do
        if id == byKey then
            GUI.sortButtons[id]:SetSolidColor(UIUtil.factionTextColor)
        else
            GUI.sortButtons[id]:SetSolidColor('7E414141') -- '#7E414141'
        end
    end
    
    if byKey == 'title' or byKey == 'author' or byKey == 'type' or byKey == 'version' then
        -- simple sorting by title, author, type, or version
        table.sort(controlList, function(a,b)
            local aSortKey = a.modInfo[byKey]
            local bSortKey = b.modInfo[byKey]
            if aSortKey == bSortKey then
                return a.modInfo.title < b.modInfo.title -- sort by title if mods in same category
            elseif byKey == 'type'  then
                return aSortKey > bSortKey -- prioritize UI/SIM mods over disabled mods
            else 
                return aSortKey < bSortKey -- alphabetical sort by mod title, author, version
            end 
        end) 
    else 
        -- default sorting by mod's status -> mod's type -> mod's title
        table.sort(controlList, function(a,b)
            -- sort mods by active state, then by type and finally by name
            if mods.activated[a.modInfo.uid] and
               not mods.activated[b.modInfo.uid] then
               return true -- ensure activated mods are sorted higher in the list
            elseif not mods.activated[a.modInfo.uid] and
                       mods.activated[b.modInfo.uid] then
               return false -- ensure inactivate mods are sorted lower in the list
            elseif a.modInfo.sort == 'UI' and
                   b.modInfo.sort == 'GAME' then
               return true -- ensure GAME mods are sorted lower in the list
            elseif a.modInfo.sort == 'GAME' and
                   b.modInfo.sort == 'UI' then
               return false -- ensure UI mods are sorted higher in the list
            else
                -- first sort mods by their type, SIM, GUI, BLACKLISTED, LOCAL, NO_DEPENDENCY
                if a.modInfo.sort == b.modInfo.sort then
                    -- secondly sort mods by status of activated/inactive mods 
                    if a.modInfo.status ~= b.modInfo.status then
                        return tostring(a.modInfo.status) < tostring(b.modInfo.status)
                    elseif a.modInfo.name == b.modInfo.name then
                        return tostring(a.modInfo.version) < tostring(b.modInfo.version)
                    else
                        -- lastly sort mods by their title (cleanup version of mod name)
                        return a.modInfo.title < b.modInfo.title
                    end
                else
                    return a.modInfo.sort < b.modInfo.sort
                end
            end
        end)
    end

    scrollGroup.top = 1
    scrollGroup:CalcVisible()
end

function CreateListElement(parent, mod, index)
    local group = Bitmap(parent)
--     group:SetSolidColor('8DDE671C') -- #8DDE671C

    -- changed fixed-size checkboxes to scalable checkboxes
    group.filtered = false
    group.index = index
    group.modInfo = mod
    group:EnableHitTest()
    LayoutHelpers.SetHeight(group, modInfoHeight)
    LayoutHelpers.SetWidth(group, dialogWidth - 40)
    LayoutHelpers.AtLeftTopIn(group, parent, 8, modInfoHeight * (index - 1))
    group.Bottom:Set(function() return group.Top() + group.Height() end)
    
    -- creating a toggle for marking mods as favorite
    group.favToggle = CreateFavoriteButton(group, 25, true)
    group.favToggle.Top:Set(function() return group.Top() end)
    group.favToggle.Bottom:Set(function() return group.Bottom() end)
    group.favToggle.Height:Set(function() return group.Height() end)
    group.favToggle.OnClick = function(self)
        if mods.favorite[mod.uid] then
           mods.favorite[mod.uid] = nil
        else 
           mods.favorite[mod.uid] = true
        end
        self.isChecked = mods.favorite[mod.uid]
        self:Update() 
    end
    group.favToggle.isChecked = mods.favorite[mod.uid]
    group.favToggle:Update()

    -- creating background checkbox for enabling/disabling a given mod
    group.bg = Checkbox(group,
        UIUtil.SkinnableFile('/MODS/blank.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/single.dds'),
        UIUtil.SkinnableFile('/MODS/double.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
        UIUtil.SkinnableFile('/MODS/disabled.dds'),
            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
    LayoutHelpers.FillParent(group.bg, group)
    LayoutHelpers.AnchorToRight(group.bg, group.favToggle, 5)

    if mods.expanded then 
        group.icon = Bitmap(group.bg, mod.icon)
        group.icon:DisableHitTest()
        LayoutHelpers.SetDimensions(group.icon, modIconSize, modIconSize)
        LayoutHelpers.AtLeftIn(group.icon, group.bg, 10)
        LayoutHelpers.AtVerticalCenterIn(group.icon, group.bg)
    end

    group.name = UIUtil.CreateText(group.bg, mod.title, 14, UIUtil.bodyFont)
    group.name:SetColor('FFE9ECE9') -- #FFE9ECE9
    group.name:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.name, group.bg, modInfoPosition, 8)

    group.createdBy = UIUtil.CreateText(group.bg, ' created by ', 14, UIUtil.bodyFont)
    group.createdBy:DisableHitTest()
    group.createdBy:SetColor('FFA2A5A2') -- #FFA2A5A2
    LayoutHelpers.AtTopIn(group.createdBy, group.bg, 7)
    LayoutHelpers.RightOf(group.createdBy, group.name, 2)
    
    group.author = UIUtil.CreateText(group.bg, mod.author, 14, UIUtil.bodyFont)
    group.author:DisableHitTest()
    group.author:SetColor('FFE9ECE9') -- #FFE9ECE9 
    LayoutHelpers.AtTopIn(group.author, group.bg, 7)
    LayoutHelpers.RightOf(group.author, group.createdBy, 2)
    
    if not mods.expanded then 
        local tooltipText = mod.description .. '\n\n' .. 'Location: ' .. tostring(mod.location)
        group.tooltip = Bitmap(group.bg)
        group.tooltip:DisableHitTest()
        group.tooltip:SetAlpha(0.5, false)
        group.tooltip.Depth:Set(function() return group.name.Depth() + 2 end)
        group.tooltip:EnableHitTest()
        LayoutHelpers.FillParent(group.tooltip, group.bg)
        AddTooltip(group.tooltip, mod.title, tooltipText, 420)
    else
        group.desc = MultiLineText(group.bg, UIUtil.bodyFont, 12, 'FFA2A5A2')
        group.desc:DisableHitTest()
        LayoutHelpers.AnchorToRight(group.desc, group.icon, 10)
        group.desc.Right:Set(function() return group.bg.Right() - LayoutHelpers.ScaleNumber(5) end)
        group.desc.Width:Set(function() return group.desc.Right() - group.desc.Left() end)

        group.desc.Top:Set(function() return group.name.Bottom() + LayoutHelpers.ScaleNumber(6) end)
        group.desc.Bottom:Set(function() return group.bg.Bottom() - LayoutHelpers.ScaleNumber(2) end)
        group.desc.Height:Set(function() return group.desc.Bottom() - group.desc.Top() end)
        
        if not mod.description then
            WARN('Missing mod description in "' .. tostring(mod.title) .. '" located in ' .. tostring(mod.location))
            group.desc:SetText('MISSING MOD DECRIPTION IN \n'  .. tostring(mod.location))
        elseif string.len(mod.description) > modInfoDesciptionMax then
            local description = string.sub(mod.description, 1, modInfoDesciptionMax) .. '...'
            group.desc:SetText(description)
        else
            group.desc:SetText(mod.description)
        end
    end

    local icon = modsTags[mod.type].icon or '/textures/ui/common/mods/mod_type_warning.dds'
    group.type = Bitmap(group.bg, icon)
    group.type:DisableHitTest()
    group.type:SetAlpha(0.5, false)
    group.type.Depth:Set(function() return dialogContent.Depth() + 10000 end)
    group.type:EnableHitTest()
    group.type.HandleEvent = function(self, event) 
        if event.Type == 'MouseEnter' then
            self:SetAlpha(1.0, false) return true 
        elseif event.Type == 'MouseExit' then
            self:SetAlpha(0.5, false) return true 
        end
        return false 
    end
    LayoutHelpers.SetDimensions(group.type, 30, 24) 

    if mod.type == 'GAME' then
        AddTooltip(group.type, mod.status, 'This mod is changing game for all players and it will prevent ranking of the current game', 400, nil, nil, 'right')
    elseif mod.type == 'UI' then
        AddTooltip(group.type, mod.status, 'This mod is changing only UI for current player and it will not prevent ranking of the current game', 400, nil, nil, 'right')
    else 
        AddTooltip(group.type, mod.status, nil, 200, nil, nil, 'right')
    end

    group.ui = mod.ui_only
    LayoutHelpers.AtRightTopIn(group.type, group.bg, 10, 6)

    -- check if the mod has 2 website links: mod info website and Github website
    if mod.url and mod.github then  
        -- creating a link for opening a website with info about the mod
        group.website = CreateLinkButton(group.bg, mod.url, GUI.modWebisteIcon, 'Open website with information about the mod \n' .. mod.url) 
        LayoutHelpers.SetDimensions(group.website, 20, 20)
        LayoutHelpers.LeftOf(group.website, group.type, 5)
         
        -- creating a link for opening a website with source code for the mod 
        group.github = CreateLinkButton(group.bg, mod.github, GUI.modSourceIcon, 'Open website with source code for the mod \n' .. mod.url) 
        LayoutHelpers.SetDimensions(group.github, 20, 20)
        LayoutHelpers.LeftOf(group.github, group.website, 5)

    -- check if the mod has website URL or Github URL
    elseif mod.url then 
        if Links.repo(mod.url) then  
            -- creating a link for opening a website with source code for the mod 
            group.website = CreateLinkButton(group.bg, mod.url, GUI.modSourceIcon, 'Open website with source code for the mod \n' .. mod.url)  
            LayoutHelpers.SetDimensions(group.website, 20, 20)
            LayoutHelpers.LeftOf(group.website, group.type, 5)
        else
            -- creating a link for opening a website with info about the mod
            group.website = CreateLinkButton(group.bg, mod.url, GUI.modWebisteIcon, 'Open website with information about the mod \n' .. mod.url) 
            LayoutHelpers.SetDimensions(group.website, 20, 20)
            LayoutHelpers.LeftOf(group.website, group.type, 5)
        end
    end

    table.insert(controlList, group)
    controlMap[mod.uid] = group

    if IsHost or mod.ui_only then
        local uid = mod.uid
        group.bg.OnCheck = function(self, checked)
            if checked then
                LOG('ModsManager selected: ' .. GetModNameType(uid))
                ActivateMod(uid)
            else
                LOG('ModsManager deselected: ' .. GetModNameType(uid))
                DeactivateMod(uid)
            end
        end
    else
        -- Disable all mouse interactivity with the control, but don't _disable_ it, as that alters
        -- what it looks like.
        group.bg.HandleEvent = function() return true end
    end

    if mod.type == 'NO_DEPENDENCY' then
        local body = 'This mod is missing mod dependencies:\n'
        if not table.empty(mod.requiresNames) then
            for k, v in mod.requiresNames do
                body = body .. ' ' .. v .. '\n' 
            end
        elseif not table.empty(mod.requires) then
            for k, v in mod.requires do
                body = body .. ' ' .. v .. '\n'  
            end
        else
            body = nil
        end

        if body then
            group.type:EnableHitTest()
            AddTooltip(group.type, mod.status, body, 400, nil, nil, 'right')
        end
    end
    
    return group
end

function CreateLinkButton(parent, url, iconPath, description)
    local btn = Bitmap(parent) 
    btn.url = url
--    btn:SetSolidColor('FFFF0B0B') -- #FFFF0B0B
    btn:SetTexture(iconPath) 
    btn:SetAlpha(0.5, false)
    btn.Depth:Set(function() return dialogContent.Depth() + 100 end)
    btn:EnableHitTest()
    btn.HandleEvent = function(self, event) 
        if event.Type == 'MouseEnter' then
            self:SetAlpha(1.0, false)
        elseif event.Type == 'MouseExit' then
            self:SetAlpha(0.5, false)
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            Links.open(self.url)
        end
        return true 
    end
    AddTooltip(btn, 'Open URL', description, 400, nil, nil, 'right')

    return btn
end

function CreateFavoriteButton(parent, iconSize, isCentered, isChecked)
    local toggle = Bitmap(parent)
    toggle.isChecked = isChecked
    toggle.isCheckable = true 
    toggle.uncheckColor = 'ff434343' -- #ff434343
    toggle.checkedTooltip = 'Remove this mod from the list of favorite mods'
    toggle.uncheckTooltip = 'Add this mod to the list of favorite mods that you can later activate by clicking on the Star button located in top left corner of this dialog'
    
    if UIUtil.GetCurrentSkinName() == 'random' then
       toggle.checkedColor = 'FFFFFF' -- #FFFFFF
    else
       toggle.checkedColor = UIUtil.factionTextColor
    end

    toggle.Icon = Bitmap(parent, GUI.modFavoriteIcon)
    toggle.Icon:DisableHitTest()
    LayoutHelpers.SetDimensions(toggle.Icon, iconSize, iconSize)
    LayoutHelpers.AtLeftIn(toggle.Icon, parent, 5)
    
    toggle.Fill = Bitmap(toggle.Icon)
    toggle.Fill:SetAlpha(0.9, false)
    toggle.Fill:DisableHitTest()
    toggle.Fill:SetSolidColor(toggle.uncheckColor)
    toggle.Fill.Depth:Set(function() return toggle.Icon.Depth() - 1 end)
    LayoutHelpers.FillParent(toggle.Fill, toggle.Icon)

    if isCentered then
        LayoutHelpers.AtVerticalCenterIn(toggle.Icon, parent)
    else 
        LayoutHelpers.AtTopIn(toggle.Icon, parent, 5) 
    end
     
--    toggle:SetSolidColor('4BFAA2A2') -- '#00F7F4F4'  #4BFAA2A2
    toggle.Depth:Set(function() return parent.Depth() + 100 end)
    LayoutHelpers.FillParentFixedBorder(toggle, toggle.Icon, -8)
     
    toggle.HandleEvent = function(self, event)
        OnButtonHighlight(self.Fill, event)
        if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then 
            if self.OnClick then
               self:OnClick(event)
            end
        end
        return true
    end
    toggle:EnableHitTest()
    
    toggle.Update = function(self)
        if self.isCheckable then
            if self.isChecked then
                self.Fill:SetSolidColor(self.checkedColor) 
                AddTooltip(self, 'Toggle Favorite Mod', self.checkedTooltip)
            else 
                self.Fill:SetSolidColor(self.uncheckColor) 
                AddTooltip(self, 'Toggle Favorite Mod', self.uncheckTooltip)
            end
        else
            self.Fill:SetSolidColor(self.uncheckColor)
        end
    end
    toggle:Update()
    return toggle
end

function CreateSortComboBox()
    local sortCombo = Combo(dialogContent, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    LayoutHelpers.SetWidth(sortCombo, 75) 
    LayoutHelpers.AtTopIn(sortCombo, dialogContent, 20)
    LayoutHelpers.AtRightIn(sortCombo, dialogContent, 10)
    sortCombo.OnClick = function(self, index, text, skipUpdate)
       mods.sortKey = modSortConfigurations[index].id
       mods.sortName = modSortConfigurations[index].name
       Tooltip.DestroyMouseoverDisplay()
            RefreshModsList()
    end
    
    sortCombo:ClearItems()
    sortCombo.itemNames = {}
    sortCombo.items = {}
    sortCombo.itemTooltips = {}
    sortCombo.tooltip = ''
    for index, config in modSortConfigurations do
        sortCombo.items[index] = config
        sortCombo.itemTooltips[index] = config.tooltip
        sortCombo.itemNames[index] = config.name
        sortCombo.tooltip = ' ' .. sortCombo.tooltip .. config.name .. ' - ' .. config.tooltip .. '\n'
        if index == 1 then
           sortCombo.itemNames[index] = config.name
        end 
    end

    sortCombo:AddItems(sortCombo.itemNames, 1)
    AddTooltip(sortCombo, 'Sort Mod List', sortCombo.tooltip, 375, nil, nil, 'right')

    local sortByLabel = UIUtil.CreateText(dialogContent, ' Sort mods by ', 14, UIUtil.bodyFont)
    sortByLabel:SetColor('B9BFB9')
    sortByLabel:SetDropShadow(true) 
    LayoutHelpers.LeftOf(sortByLabel, sortCombo, 5)

    GUI.sortCombo = sortCombo
end

function AddTooltip(control, title, description, width, padding, fontSize, position)
    if not fontSize then fontSize = 14 end
    if not position then position = 'left' end
    import("/lua/ui/game/tooltip.lua").AddControlTooltipManual(control, title, description, 0, width, 6, fontSize, fontSize, position)
end

-- saves favorite mods, mods sorting order, mods expanded/collapsed
function SavePreferences()
    if not mods or not mods.favorite then return end
    SetPreference('mods_expanded', mods.expanded)
    SetPreference('mods_favorite', mods.favorite or {})
--    SetPreference('mods_sortKey', mods.sortKey or 'status')
end

-- loads favorite mods, mods sorting order, mod list expanded/collapsed
function LoadPreferences()
    mods.expanded = GetPreference('mods_expanded')
    if mods.expanded == nil then mods.expanded = true end

    mods.favorite = GetPreference('mods_favorite')
    if not mods.favorite then mods.favorite = {} end

--    mods.sortKey = GetPreference('mods_sortKey')  
--    if not mods.sortKey then mods.sortKey = 'status' end
end