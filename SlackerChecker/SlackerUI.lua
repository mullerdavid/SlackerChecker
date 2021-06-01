SlackerUI = {}

SlackerUI.ScrollTable = {}
SlackerUI.ScrollTable.RenderBuffs = nil
SlackerUI.ScrollTable.NoSort = nil

SlackerUI.Tooltip = {}
SlackerUI.Tooltip.Show = nil
SlackerUI.Tooltip.ShowSpell = nil
SlackerUI.Tooltip.Hide = nil

SlackerUI.ContextMenu = {}
SlackerUI.ContextMenu.Show = nil
SlackerUI.ContextMenu.Hide = nil

SlackerUI.ConfirmDialog = nil

local function CompareBuffs(first, second)
	first = SlackerData.Buff.extract_id(first)
	second = SlackerData.Buff.extract_id(second)
	return SlackerHelper.buff_compare(first, second)
end

function SlackerUI.ScrollTable.RenderBuffs(rowFrame, cellFrame, data, cols, row, realrow, column, fShow, st, ...)
	local children = { cellFrame:GetChildren() }
	for i, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
		child:ClearAllPoints()
	end
	if fShow
	then
		local buffs = st:GetCell(realrow,column)["value"]
		local sortedbuffs = {}
		for j=1,#buffs,1 do table.insert(sortedbuffs, buffs[j]) end
		table.sort( sortedbuffs, CompareBuffs )
		local x = 0
		local colwidth = cellFrame:GetWidth()
		local width = colwidth/#sortedbuffs-1
		width = math.min(16, width)
		for j=1,#sortedbuffs,1
		do
			local buff = sortedbuffs[j]
			local spellid = SlackerData.Buff.extract_id(buff)
			local name, _, icon = GetSpellInfo(spellid)
			local description = GetSpellDescription(spellid)
			local b = CreateFrame("Frame",nil,cellFrame)
			b:SetWidth(width)
			b:SetHeight(width)
			local t = b:CreateTexture(nil,"BACKGROUND")
			t:SetTexture(icon)
			t:SetAllPoints(b)
			b.texture = t
			b:SetPoint("TOPLEFT", x, -1*(18-width)/2 );
			b.tooltip = { ["id"]=spellid, ["name"]=name, ["description"]=description }
			b:HookScript("OnEnter", function(self) SlackerUI.Tooltip.ShowSpell(self, self.tooltip.name, self.tooltip.description, self.tooltip.id) end)
			b:HookScript("OnLeave", SlackerUI.Tooltip.Hide)
			b:EnableMouse(true)
			b:Show()
			x = x + width+1
		end
	end
end

function SlackerUI.ScrollTable.NoSort(self, rowa, rowb, sortbycol) 
	return rowa<rowb;
end
function SlackerUI.Tooltip.Show(parent, text)
	GameTooltip:SetOwner(parent, "ANCHOR_TOPRIGHT");
	GameTooltip:SetText( text )
	GameTooltip:Show()
end

function SlackerUI.Tooltip.ShowSpell(parent, name, description, spellid)
	local gtt = GameTooltip
	gtt:SetOwner(parent, "ANCHOR_TOPRIGHT");
	gtt:ClearLines()
	gtt:AddLine(name, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1, false)
	if description
	then
		gtt:AddLine(description, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1, true)
	end
	if SlackerHelper.get_setting("debug")
	then
		gtt:AddLine(spellid, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1, true)
	end
	for i=1,gtt:NumLines() do
        local lineL = _G["GameTooltipTextLeft"..tostring(i)]
        local lineR = _G["GameTooltipTextRight"..tostring(i)]
        local fontNameL, fontSizeL = lineL:GetFont()
		local size = 12
		if i==1
		then
			size = 14
		end
        if fontNameL == nil or fontSizeL == 0 then
            lineL:SetFont("Fonts\\FRIZQT__.TTF", size)
            lineL:SetJustifyH("LEFT")
        end
        local fontNameR, fontSizeR = lineR:GetFont()
        if fontNameR == nil or fontSizeR == 0 then
            lineR:SetFont("Fonts\\FRIZQT__.TTF", size)
            lineR:SetJustifyH("RIGHT")
        end
    end 
	gtt:Show()
end

function SlackerUI.Tooltip.Hide()
	GameTooltip:Hide()
end

local dropDown = nil

function SlackerUI.ContextMenu.Hide()
	if dropDown
	then
		dropDown:Hide()
	end
end

-- menu = { {text="display", value="value", func=function} }
function SlackerUI.ContextMenu.Show(parent, menu, hidecancel)
	dropDown = dropDown or CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
	UIDropDownMenu_Initialize(dropDown, 
	function()
		for i=1,#menu,1
		do
			local entry = menu[i]
			local info = { 
				["text"]=entry.text, 
				["value"]=entry.value,
				["arg1"]=entry,
				["notCheckable"]=true,
				["func"]=entry.func,
			}
			UIDropDownMenu_AddButton(info)
		end
		if not hidecancel
		then
			local info = {
				["text"]="Cancel",
				["notCheckable"]=true,
				["func"]=function(self) self:Hide() end
			}
			UIDropDownMenu_AddButton(info)
		end
	end,
	"MENU")
	ToggleDropDownMenu(1, nil, dropDown, parent or "cursor", 0, 0);
end

function SlackerUI.ConfirmDialog(text, onaccept, btn1, btn2)
	local name = "SlackerChecker_SlackerUI.ConfirmDialog"
	StaticPopupDialogs[name] = {
		text = text,
		button1 = btn1 or "Yes",
		button2 = btn2 or "No",
		OnAccept = onaccept,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3
	}
	StaticPopup_Show(name)
end