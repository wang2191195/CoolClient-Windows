--local function:
--NowState normal:Normal, down:Down, disable:Disable, hover:Hover
local function ListBox_UpdateRes(self, newState)

    local attr = self:GetAttribute()
    
	local bkgTexture
	
	if newState == "down" then
	    bkgTexture = attr.BkgDownTextureID
	elseif newState == "disable" then
	    bkgTexture = attr.BkgDisableTextureID
	elseif newState == "hover" then
	    bkgTexture = attr.BkgHoverTextureID
	else 
	    bkgTexture = attr.BkgNormalTextureID
		newState = "normal"
	end
	
	local bkgObj = self:GetControlObject("bkg")
	
	if bkgTexture ~= "" and bkgObj then
	    bkgObj:SetTextureID(bkgTexture)
	end
	
	attr.NowState = newState

end


local function InsertItemDataTable(self, index, data)--Item数据表的维护
	--XLMessageBox(data.Name)
    local attr = self:GetAttribute()
	if attr.ItemDataTable == nil then
	    attr.ItemDataTable = {}
	end
	if data == nil then
	    data = {}
	end
	
	if index == -1 then
	    table.insert(attr.ItemDataTable, data)
		--XLMessageBox(attr.ItemDataTable[#attr.ItemDataTable].Name)
	else
	    table.insert(attr.ItemDataTable, index, data)
	end
end

local function DeleteItemDataTable(self, index)
    local attr = self:GetAttribute()
	if attr.ItemDataTable == nil then
	    attr.ItemDataTable = {}
		return false
	end
	if index > #attr.ItemDataTable then
	    return false
	else
	    table.remove(attr.ItemDataTable, index)
		return true
	end
end

local function FindItemDataTable(self, nStartAfter, str)
    local index = 1
	local attr = self:GetAttribute()
	if attr.ItemDataTable == nil then
	    attr.ItemDataTable = {}
		return -1
	end
	if index > #attr.ItemDataTable then
	    return
	else
	    for data in pairs(attr.ItemDataTable) do
		    if data == str then
			    return index    
			end
			index = index + 1
		end 
		return -1
	end
end

local function ListBox_ItemOnSelect(self, name, index)
	--index为选中的索引
    local owner = self:GetOwnerControl()
	local attr = owner:GetAttribute()
    if attr.InstanceTable ~= nil then
	    local InstanceCount = #attr.InstanceTable
	    for i=1, InstanceCount do
		    if i ~= (index + 1) then
			    attr.InstanceTable[i]:SetSelect(false)
			end
		end
	end
	attr.CurSel = index + attr.BeginItem 
	owner:FireExtEvent("OnSelectChanged", index + 1)	
	--XLMessageBox(owner:GetClass())
end

local function ListBox_ItemWidthExtend(self, name, textwidth)--响应每一个item的text的宽度，来决定水平滚动条的显示
    local owner = self:GetOwnerControl()
	local attr = owner:GetAttribute()
	if attr.ItemTextWidth == nil then
	    attr.ItemTextWidth = 0
	end
	if textwidth > attr.ItemTextWidth then
		attr.ItemTextWidth = textwidth
		attr.HScrollBarShow = true
	end
end

local function ListBox_DestroyInstanceItem(self)--销毁创建的listbox_item
    local attr = self:GetAttribute()
    local bkgWndobj = self:GetControlObject("bkgWnd")
    if attr.InstanceTable ~= nil then ---销毁已经创建的对象
	    local InstanceCount = #attr.InstanceTable
	    for i=1, InstanceCount do
		    bkgWndobj:RemoveChild(attr.InstanceTable[1])
		    table.remove(attr.InstanceTable, 1)
		end
	else
	    attr.InstanceTable = {}
	end
end

local function ListBox_CreateInstanceItem(self)--添加item实例，不同type就在这里做处理
    local intIndex = 0
	local attr = self:GetAttribute()
	local xarManager = XLGetObject("Xunlei.UIEngine.XARManager")
	local xarFactory = xarManager:GetXARFactory()
	local bkgWndobj = self:GetControlObject("bkgWnd")
	if attr.BeginItem == nil then
		attr.BeginItem = 1
	end
	local intTop = (attr.BeginItem - 1) * attr.ItemHeight
	if intTop < 0 then
	    intTop = 0
	end
	
	attr.ItemTextWidth = 0
	attr.HScrollBarShow = false
	for i = 1, #attr.ItemDataTable do
		if i > (attr.BeginItem + attr.ItemCountInOnePage * 3+3) then
			--break
		end

		local newListBoxItem = xarFactory:CreateUIObject("listbox"..i, attr.ItemType)		
		local newListBoxItemAttr = newListBoxItem:GetAttribute()
		if attr.ItemType == "BaseUI.ListBox.TaskItem" then
				newListBoxItemAttr.Handle = attr.ItemDataTable[i].Handle
				newListBoxItemAttr.Status = attr.ItemDataTable[i].Status
				newListBoxItemAttr.Type = attr.ItemDataTable[i].Type
				newListBoxItemAttr.Name = attr.ItemDataTable[i].Name
				newListBoxItemAttr.Time = attr.ItemDataTable[i].Retime
				newListBoxItemAttr.Size = attr.ItemDataTable[i].Size
				newListBoxItemAttr.Progress = attr.ItemDataTable[i].Progress
				newListBoxItemAttr.Upload = attr.ItemDataTable[i].UploadSpeed
				if attr.ItemDataTable[i].Progress == 100 then
					newListBoxItemAttr.Download = 0
				else
					newListBoxItemAttr.Download = attr.ItemDataTable[i].DownloadSpeed
				end
			elseif attr.ItemType == "BaseUI.ListBox.ResItem" then
				newListBoxItemAttr.Type = attr.ItemDataTable[i].Type
				newListBoxItemAttr.Name = attr.ItemDataTable[i].Name
				newListBoxItemAttr.Time = attr.ItemDataTable[i].Time
				newListBoxItemAttr.Size = attr.ItemDataTable[i].Size
				newListBoxItemAttr.Upload = attr.ItemDataTable[i].Upload
				newListBoxItemAttr.Download = attr.ItemDataTable[i].Download
				newListBoxItemAttr.TorrentId = attr.ItemDataTable[i].TorrentId
			elseif attr.ItemType == "BaseUI.ListBox.NewTaskItem" then
				if intIndex%2 ~= 0 then
					newListBoxItemAttr.BkgNormalTextureID = "texture.newataskmodal.bkg.odd"
				else
					newListBoxItemAttr.BkgNormalTextureID = "texture.newataskmodal.bkg.even"
				end
				newListBoxItemAttr.Name = attr.ItemDataTable[i].Name
				newListBoxItemAttr.Size = attr.ItemDataTable[i].Size
		end
		newListBoxItemAttr.Index = intIndex
					
		local ctrlLeft, ctrlTop, cltrRight, ctrlBottom = bkgWndobj:GetObjPos()
		bkgWndobj:AddChild(newListBoxItem)
		newListBoxItem:AttachListener("OnSelect", true, ListBox_ItemOnSelect)
		newListBoxItem:AttachListener("OnWidthExtend", true, ListBox_ItemWidthExtend)
	
		if intIndex == (attr.CurSel - attr.BeginItem) then
			newListBoxItem:SetSelect(true, intIndex)    
        end	
					
		table.insert(attr.InstanceTable, newListBoxItem)
		newListBoxItem:SetObjPos(1, intTop, attr.ItemWidth-2, intTop + attr.ItemHeight)
					
		intTop = intTop + attr.ItemHeight
		intIndex = intIndex + 1
	end
end

local function ListBox_ShowScrollBarV(self)
    local attr = self:GetAttribute()
	local selfLeft, selfTop, selfRight, selfBottom = self:GetObjPos()
	local selfWidth, selfHeight = selfRight - selfLeft, selfBottom - selfTop
    local scrollbarvobj = self:GetControlObject("scrollbar.v")
	if (#attr.ItemDataTable * attr.ItemHeight) > selfHeight then
		scrollbarvobj:SetVisible(true)
		attr.VScrollBarShow = true
		attr.ItemWidth = selfWidth - attr.VerticalScrollBarWidth
		--如果有竖向滚动条的话，需要计算从哪个item开始创建listbox_item
		local pos = scrollbarvobj:GetScrollPos()
		local beginItem = math.floor(pos / attr.ItemHeight)
		beginItem = beginItem - attr.ItemCountInOnePage
		if beginItem < 1 then
			beginItem = 1
		end
		attr.BeginItem = beginItem
		attr.HorizontalScrollBarHeight = selfHeight/(#attr.ItemDataTable * attr.ItemHeight)*selfHeight - 35
		--XLMessageBox(attr.HorizontalScrollBarHeight)
		scrollbarvobj:SetThumbLength(attr.HorizontalScrollBarHeight)
	else
		attr.ItemWidth = selfWidth
		scrollbarvobj:SetVisible(false)
		attr.VScrollBarShow = false
		scrollbarvobj:SetScrollPos(0)
		local bkgWndobj = self:GetControlObject("bkgWnd")
		local bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom = bkgWndobj:GetObjPos()
		bkgWndobj:SetObjPos(bkgWndleft, 0, bkgWndright, bkgWndbottom)
	end
	if scrollbarvobj then
		scrollbarvobj:SetScrollRange(0, #attr.ItemDataTable*attr.ItemHeight - attr.ItemCountInOnePage*attr.ItemHeight )
	end
end

local function ListBox_ShowScrollBarH(self) --
    local attr = self:GetAttribute()
	local bkgobj = self:GetControlObject("bkg")
	local selfLeft, selfTop, selfRight, selfBottom = bkgobj:GetObjPos()
	local selfWidth, selfHeight = selfRight - selfLeft, selfBottom - selfTop
	
	local scrollbarhobj = self:GetControlObject("scrollbar.h")--水平滚动条
	local scrollbarvobj = self:GetControlObject("scrollbar.v") --竖向滚动条
    local bkgWndobj = self:GetControlObject("bkgWnd")
	local bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom = bkgWndobj:GetObjPos()
	if attr.ItemTextWidth ~= nil and attr.ItemTextWidth > selfWidth then
		for i=1, #attr.InstanceTable do
			local left, top, right, bottom = attr.InstanceTable[i]:GetObjPos()
			attr.InstanceTable[i]:SetObjPos(left, top, left + attr.ItemTextWidth, bottom)
		end
		scrollbarhobj:SetVisible(true)
		attr.HScrollBarShow = true
		if attr.VScrollBarShow == true then
		    scrollbarhobj:SetObjPos(0, selfBottom - attr.HorizontalScrollBarHeight, 0 + selfRight - attr.VerticalScrollBarWidth, selfBottom)
		else
		    scrollbarhobj:SetObjPos(0, selfBottom - attr.HorizontalScrollBarHeight, 0 + selfRight, selfBottom)
		end
		
		if scrollbarhobj then
		    local pos  = scrollbarhobj:GetScrollPos()
			local scrollBegin, scrollEnd = scrollbarhobj:GetScrollRange()
			local rate = 0
			if (scrollEnd - scrollBegin) > 0 then
			    rate = pos / (scrollEnd - scrollBegin)
				
			end
			if attr.VScrollBarShow == true then
			    pos = math.floor((attr.ItemTextWidth - selfWidth - attr.VerticalScrollBarWidth) * rate)
				scrollbarhobj:SetScrollRange(0, attr.ItemTextWidth - selfWidth - attr.VerticalScrollBarWidth)
			else
			    pos = math.floor((attr.ItemTextWidth - selfWidth) * rate)
				scrollbarhobj:SetScrollRange(0, attr.ItemTextWidth - selfWidth)
			end
			scrollbarhobj:SetScrollPos(pos)
			ListBox_HScrollPosChange(scrollbarhobj)--在竖直滚动条在滚动情况下，也要考虑横向滚动的问题，否则会出现边界问题
		end
	else
		scrollbarhobj:SetVisible(false)
		attr.HScrollBarShow = false
		scrollbarhobj:SetScrollPos(0)
		if attr.VScrollBarShow == true then
			scrollbarvobj:SetObjPos(selfRight - attr.VerticalScrollBarWidth, 0, selfRight, 0 + selfBottom)
		end
		bkgWndobj:SetObjPos(0, bkgWndtop, selfWidth, bkgWndbottom)
	end
end

function UpdateUI(self)
	local attr = self:GetAttribute()
	if attr.ItemDataTable == nil then
	    attr.ItemDataTable = {}
	end
	local selfLeft, selfTop, selfRight, selfBottom = self:GetObjPos()
	local selfWidth, selfHeight = selfRight - selfLeft, selfBottom - selfTop
	
	ListBox_DestroyInstanceItem(self)
	
	if attr.ItemHeight > 0 then
		attr.ItemCountInOnePage = math.floor(selfHeight / attr.ItemHeight)
		if attr.ItemCountInOnePage > 0 then
			attr.PageCount = math.floor(#attr.ItemDataTable / attr.ItemCountInOnePage) + 1
			if attr.PageCount > 0 then
				ListBox_ShowScrollBarV(self) --竖向滚动条
				ListBox_CreateInstanceItem(self) --创建对象
				ListBox_ShowScrollBarH(self) --横向滚动条
			end
		end
	end
	
end

function ListBox_HScrollPosChange(self)
    local owner = self:GetOwnerControl()
	local attr = owner:GetAttribute()
	
	local selfLeft, selfTop, selfRight, selfBottom = owner:GetObjPos()
	local selfWidth, selfHeight = selfRight - selfLeft, selfBottom - selfTop
	
	local bkgWndobj = owner:GetControlObject("bkgWnd")
	local bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom = bkgWndobj:GetObjPos()
	
	local scrollbarhobj = owner:GetControlObject("scrollbar.h")--水平滚动条
	local pos = scrollbarhobj:GetScrollPos()
	
	
	local scrollBegin, scrollEnd = scrollbarhobj:GetScrollRange()
	if scrollEnd == pos then
	    if attr.VScrollBarShow == true then
			bkgWndleft = selfWidth - attr.ItemTextWidth - attr.VerticalScrollBarWidth
		else
		    bkgWndleft = selfWidth - attr.ItemTextWidth
		end
		bkgWndobj:SetObjPos(bkgWndleft, bkgWndtop, bkgWndleft+attr.ItemTextWidth, bkgWndbottom)
	else
	    bkgWndleft = 0 - pos
	    bkgWndobj:SetObjPos(bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom)
	end
end

function ListBox_VScrollPosChange(self)
    local owner = self:GetOwnerControl()
	local attr = owner:GetAttribute()
	local scrollbarvobj = owner:GetControlObject("scrollbar.v")
	local bkgWndobj = owner:GetControlObject("bkgWnd")
	local bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom = bkgWndobj:GetObjPos()
	local bkgWidth = bkgWndright - bkgWndleft
	local bkgHeight = bkgWndbottom - bkgWndtop
	local pos = scrollbarvobj:GetScrollPos()
	--XLMessageBox(pos)
	--XLMessageBox((#attr.ItemDataTable) * attr.ItemHeight/(bkgWndbottom - bkgWndtop) )
	local beginItem = math.floor(pos / attr.ItemHeight)
	beginItem = beginItem - attr.ItemCountInOnePage
	if beginItem < 1 then
	    beginItem = 1
	end
	
	local scrollBegin, scrollEnd = scrollbarvobj:GetScrollRange()
	--XLMessageBox(attr.HorizontalScrollBarHeight)
	if scrollEnd == pos then
	    if attr.HScrollBarShow == true then
		    pos = bkgWndbottom - (#attr.ItemDataTable) * attr.ItemHeight - attr.HorizontalScrollBarHeight
		else
		    pos = bkgWndbottom - (#attr.ItemDataTable) * attr.ItemHeight
		end
		pos = pos * ((#attr.ItemDataTable) * attr.ItemHeight/(bkgWndbottom - bkgWndtop))
	    --bkgWndobj:SetObjPos2(bkgWndleft, pos, bkgWidth, bkgHeight)
	else
		pos = pos * ((#attr.ItemDataTable) * attr.ItemHeight/(bkgWndbottom - bkgWndtop))
	    bkgWndtop = 0 - pos
		bkgWndobj:SetObjPos2(bkgWndleft, bkgWndtop, bkgWidth, bkgHeight)
	end
	--横向滚动条的特殊处理
	--
	--为了让滚动平滑些
	local value = math.abs(beginItem - attr.BeginItem)
	if beginItem > attr.BeginItem and value > (attr.ItemCountInOnePage - 1) then
		UpdateUI(owner)
	elseif beginItem > 5 and beginItem < attr.BeginItem and value > (attr.ItemCountInOnePage - 1) then
		UpdateUI(owner)
	elseif beginItem < 5 and beginItem < attr.BeginItem then
		UpdateUI(owner)
	end
end

--public function:

function DeleteString(self, index)
    local attr = self:GetAttribute()
	local scrollbarvobj = self:GetControlObject("scrollbar.v")
	if index <= -1 or index == nil then
	    return
	end
	local bRet = DeleteItemDataTable(self, index + 1)
	local CurPos = scrollbarvobj:GetScrollPos()
	
	CurPos = CurPos - attr.ItemHeight
	if CurPos < 0 then
	    CurPos = 0
	end
	--设置scroll的边界值
	local minRange, maxRange = scrollbarvobj:GetScrollRange()
	maxRange = maxRange - attr.ItemHeight
	scrollbarvobj:SetScrollPos(CurPos)
	scrollbarvobj:SetScrollRange(0, maxRange)
	--设置wnd的位置
	local bkgWndobj = self:GetControlObject("bkgWnd")
	local bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom = bkgWndobj:GetObjPos()
	local scrollBegin, scrollEnd = scrollbarvobj:GetScrollRange()
	if scrollEnd == CurPos then
	    CurPos = bkgWndbottom - (#attr.ItemDataTable) * attr.ItemHeight
		bkgWndobj:SetObjPos(bkgWndleft, CurPos, bkgWndright, bkgWndbottom)
	else
	    bkgWndtop = 0 - CurPos
		bkgWndobj:SetObjPos(bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom)
	end
	--修改cursel的值
	if bRet == true and index == attr.CurSel  then
	    attr.CurSel = -1
	elseif index < attr.CurSel then
	    attr.CurSel = attr.CurSel - 1
	else
	    attr.CurSel = attr.CurSel + 1
	end
	
end

function DeleteItem(self, index)
    local attr = self:GetAttribute()
	local scrollbarvobj = self:GetControlObject("scrollbar.v")
	if index <= -1 or index == nil then
	    return
	end
	local bRet = DeleteItemDataTable(self, index+1)
	local CurPos = scrollbarvobj:GetScrollPos()
	
	CurPos = CurPos - attr.ItemHeight
	if CurPos < 0 then
	    CurPos = 0
	end
	--设置scroll的边界值
	local minRange, maxRange = scrollbarvobj:GetScrollRange()
	maxRange = maxRange - attr.ItemHeight
	scrollbarvobj:SetScrollPos(CurPos)
	scrollbarvobj:SetScrollRange(0, maxRange)
	--设置wnd的位置
	local bkgWndobj = self:GetControlObject("bkgWnd")
	local bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom = bkgWndobj:GetObjPos()
	local scrollBegin, scrollEnd = scrollbarvobj:GetScrollRange()
	if scrollEnd == CurPos then
	    CurPos = bkgWndbottom - (#attr.ItemDataTable) * attr.ItemHeight
		bkgWndobj:SetObjPos(bkgWndleft, CurPos, bkgWndright, bkgWndbottom)
	else
	    bkgWndtop = 0 - CurPos
		bkgWndobj:SetObjPos(bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom)
	end
	--修改cursel的值
	if bRet == true and index == attr.CurSel  then
	    attr.CurSel = -1
	elseif index < attr.CurSel then
	    attr.CurSel = attr.CurSel - 1
	else
	    attr.CurSel = attr.CurSel + 1
	end
end

function ResetContent(self)
    local attr = self:GetAttribute()
	if attr.ItemDataTable == nil then
	    return
	end
	attr.ItemDataTable = {}
	
	local scrollbarvobj = self:GetControlObject("scrollbar.v")
	local bVisible = scrollbarvobj:GetVisible()
	if bVisible == true then
		scrollbarvobj:SetVisible(false)
		scrollbarvobj:SetScrollPos(0)
	end
	
	local bkgWndobj = self:GetControlObject("bkgWnd")
	local bkgWndleft, bkgWndtop, bkgWndright, bkgWndbottom = bkgWndobj:GetObjPos()
	bkgWndobj:SetObjPos(bkgWndleft, 0, bkgWndright, bkgWndbottom)
end

--table copy
local function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end  -- if
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end  -- for
        return setmetatable(new_table, getmetatable(object))
    end  -- function _copy
    return _copy(object)
end  -- function deepcopy

function AddString(self, str)
	InsertItemDataTable(self, -1, str)
end
function AddItem(self, data)
	local tmpData = deepcopy(data)
	local attr = self:GetAttribute()
	--XLMessageBox(data.Name)
	InsertItemDataTable(self, -1, tmpData)
end
function GetCurSel(self)
    local attr = self:GetAttribute()
	if attr.CurSel == nil then
	    attr.CurSel = -1
	end
	return attr.CurSel
end

function SetCurSel(self, index)
    local attr = self:GetAttribute()
    if index == nil or index < 0 then
	    attr.CurSel = -1
	end
	if attr.CurSel == index then
	    return
	end
	attr.CurSel = index
end

function InsertString(self, index, str)
    if index < 0 then
	    index = 1
	end
	local attr = self:GetAttribute()
	if attr.ItemDataTable == nil then
	    attr.ItemDataTable = {}
	end
	if (index + 1) > #attr.ItemDataTable then
	    InsertItemDataTable(self, -1, str)
	else
	    InsertItemDataTable(self, index+1, str)
	end
end

function FindString(self, nStartAfter, str)
	if nStartAfter < 1 then
	    nStartAfter = 1
	end
	FindItemDataTable(self, nStartAfter, str)
end

function GetItemByIndex(self, index)
	local attr = self:GetAttribute()
	return attr.InstanceTable[index]
end
function GetStringByIndex(self, index)
    local attr = self:GetAttribute()
    return attr.ItemDataTable[index]
end
--private function:

local function InitScrollBar(self)
    local attr = self:GetAttribute()
	local selfLeft, selfTop, selfRight, selfBottom = self:GetObjPos()
	local selfWidth, selfHeight = selfRight - selfLeft, selfBottom - selfTop
	
	    local ScrollBarV = self:GetControlObject("scrollbar.v")
		local ScrollBarH = self:GetControlObject("scrollbar.h")
		local attrScrollBarV = ScrollBarV:GetAttribute()
		--scrollbarV
		--bkg
		if attr.ScrollBarVBkgNormalBitmapID and attr.ScrollBarVBkgNormalBitmapID ~= "" then
		    attrScrollBarV.BkgNormalBitmapID = attr.ScrollBarVBkgNormalBitmapID
		end
		if attr.ScrollBarVBkgHoverBitmapID and attr.ScrollBarVBkgHoverBitmapID ~= "" then
		    attrScrollBarV.BkgHoverBitmapID = attr.ScrollBarVBkgHoverBitmapID
		end
		if attr.ScrollBarVBkgDownBitmapID and attr.ScrollBarVBkgDownBitmapID ~= "" then
		    attrScrollBarV.BkgDownBitmapID = attr.ScrollBarVBkgDownBitmapID
		end
		if attr.ScrollBarVBkgDisableBitmapID and attr.ScrollBarVBkgDisableBitmapID ~= "" then
		    attrScrollBarV.BkgDisableBitmapID = attr.ScrollBarVBkgDisableBitmapID
		end
		--preBtn
		if attr.ScrollBarVPreBtnNormalBitmapID and attr.ScrollBarVPreBtnNormalBitmapID ~= "" then
		    attrScrollBarV.PreBtnNormalBitmapID = attr.ScrollBarVPreBtnNormalBitmapID
		end
		if attr.ScrollBarVPreBtnHoverBitmapID and attr.ScrollBarVPreBtnHoverBitmapID ~= "" then
		    attrScrollBarV.PreBtnHoverBitmapID = attr.ScrollBarVPreBtnHoverBitmapID
		end
		if attr.ScrollBarVPreBtnDownBitmapID and attr.ScrollBarVPreBtnDownBitmapID ~= "" then
		    attrScrollBarV.PreBtnDownBitmapID = attr.ScrollBarVPreBtnDownBitmapID
		end
		if attr.ScrollBarVPreBtnDisableBitmapID and attr.ScrollBarVPreBtnDisableBitmapID ~= "" then
		    attrScrollBarV.PreBtnDisableBitmapID = attr.ScrollBarVPreBtnDisableBitmapID
		end
		--nextBtn
		if attr.ScrollBarVNextBtnNormalBitmapID and attr.ScrollBarVNextBtnNormalBitmapID ~= "" then
		    attrScrollBarV.NextBtnNormalBitmapID = attr.ScrollBarVNextBtnNormalBitmapID
		end
		if attr.ScrollBarVNextBtnHoverBitmapID and attr.ScrollBarVNextBtnHoverBitmapID ~= "" then
		    attrScrollBarV.NextBtnHoverBitmapID = attr.ScrollBarVNextBtnHoverBitmapID
		end
		if attr.ScrollBarVNextBtnDownBitmapID and attr.ScrollBarVNextBtnDownBitmapID ~= "" then
		    attrScrollBarV.NextBtnDownBitmapID = attr.ScrollBarVNextBtnDownBitmapID
		end
		if attr.ScrollBarVNextBtnDisableBitmapID and attr.ScrollBarVNextBtnDisableBitmapID ~= "" then
		    attrScrollBarV.NextBtnDisableBitmapID = attr.ScrollBarVNextBtnDisableBitmapID
		end
		--thumbBtn
		if attr.ScrollBarVThumbBtnNormalBitmapID and attr.ScrollBarVThumbBtnNormalBitmapID ~= "" then
		    attrScrollBarV.ThumbBtnNormalBitmapID = attr.ScrollBarVThumbBtnNormalBitmapID
		end
		if attr.ScrollBarVThumbBtnHoverBitmapID and attr.ScrollBarVThumbBtnHoverBitmapID ~= "" then
		    attrScrollBarV.ThumbBtnHoverBitmapID = attr.ScrollBarVThumbBtnHoverBitmapID
		end
		if attr.ScrollBarVThumbBtnDownBitmapID and attr.ScrollBarVThumbBtnDownBitmapID ~= "" then
		    attrScrollBarV.ThumbBtnDownBitmapID = attr.ScrollBarVThumbBtnDownBitmapID
		end
		if attr.ScrollBarVThumbBtnDisableBitmapID and attr.ScrollBarVThumbBtnDisableBitmapID ~= "" then
		    attrScrollBarV.ThumbBtnDisableBitmapID = attr.ScrollBarVThumbBtnDisableBitmapID
		end
		
		--ScrollBarV:UpdateUI()
		ScrollBarV:SetObjPos(selfWidth - attr.ScrollBarLeftOffset - attr.VerticalScrollBarWidth, 0 + attr.ScrollBarTopOffset, selfWidth - attr.ScrollBarLeftOffset, selfHeight - attr.ScrollBarTopOffset - attr.ScrollBarTopOffset)
		
		--scrollbarH
		local attrScrollBarH = ScrollBarH:GetAttribute()
		--bkg
		if attr.ScrollBarHBkgNormalBitmapID and attr.ScrollBarHBkgNormalBitmapID ~= "" then
		    attrScrollBarH.BkgNormalBitmapID = attr.ScrollBarHBkgNormalBitmapID
		end
		if attr.ScrollBarHBkgHoverBitmapID and attr.ScrollBarHBkgHoverBitmapID ~= "" then
		    attrScrollBarH.BkgHoverBitmapID = attr.ScrollBarHBkgHoverBitmapID
		end
		if attr.ScrollBarHBkgDownBitmapID and attr.ScrollBarHBkgDownBitmapID ~= "" then
		    attrScrollBarH.BkgDownBitmapID = attr.ScrollBarHBkgDownBitmapID
		end
		if attr.ScrollBarHBkgDisableBitmapID and attr.ScrollBarHBkgDisableBitmapID ~= "" then
		    attrScrollBarH.BkgDisableBitmapID = attr.ScrollBarHBkgDisableBitmapID
		end
		--preBtn
		if attr.ScrollBarHPreBtnNormalBitmapID and attr.ScrollBarHPreBtnNormalBitmapID ~= "" then
		    attrScrollBarH.PreBtnNormalBitmapID = attr.ScrollBarHPreBtnNormalBitmapID
		end
		if attr.ScrollBarHPreBtnHoverBitmapID and attr.ScrollBarHPreBtnHoverBitmapID ~= "" then
		    attrScrollBarH.PreBtnHoverBitmapID = attr.ScrollBarHPreBtnHoverBitmapID
		end
		if attr.ScrollBarHPreBtnDownBitmapID and attr.ScrollBarHPreBtnDownBitmapID ~= "" then
		    attrScrollBarH.PreBtnDownBitmapID = attr.ScrollBarHPreBtnDownBitmapID
		end
		if attr.ScrollBarHPreBtnDisableBitmapID and attr.ScrollBarHPreBtnDisableBitmapID ~= "" then
		    attrScrollBarH.PreBtnDisableBitmapID = attr.ScrollBarHPreBtnDisableBitmapID
		end
		--nextBtn
		if attr.ScrollBarHNextBtnNormalBitmapID and attr.ScrollBarHNextBtnNormalBitmapID ~= "" then
		    attrScrollBarH.NextBtnNormalBitmapID = attr.ScrollBarHNextBtnNormalBitmapID
		end
		if attr.ScrollBarHNextBtnHoverBitmapID and attr.ScrollBarHNextBtnHoverBitmapID ~= "" then
		    attrScrollBarH.NextBtnHoverBitmapID = attr.ScrollBarHNextBtnHoverBitmapID
		end
		if attr.ScrollBarHNextBtnDownBitmapID and attr.ScrollBarHNextBtnDownBitmapID ~= "" then
		    attrScrollBarH.NextBtnDownBitmapID = attr.ScrollBarHNextBtnDownBitmapID
		end
		if attr.ScrollBarHNextBtnDisableBitmapID and attr.ScrollBarHNextBtnDisableBitmapID ~= "" then
		    attrScrollBarH.NextBtnDisableBitmapID = attr.ScrollBarHNextBtnDisableBitmapID
		end
		--thumbBtn
		if attr.ScrollBarHThumbBtnNormalBitmapID and attr.ScrollBarHThumbBtnNormalBitmapID ~= "" then
		    attrScrollBarH.ThumbBtnNormalBitmapID = attr.ScrollBarHThumbBtnNormalBitmapID
		end
		if attr.ScrollBarHThumbBtnHoverBitmapID and attr.ScrollBarHThumbBtnHoverBitmapID ~= "" then
		    attrScrollBarH.ThumbBtnHoverBitmapID = attr.ScrollBarHThumbBtnHoverBitmapID
		end
		if attr.ScrollBarHThumbBtnDownBitmapID and attr.ScrollBarHThumbBtnDownBitmapID ~= "" then
		    attrScrollBarH.ThumbBtnDownBitmapID = attr.ScrollBarHThumbBtnDownBitmapID
		end
		if attr.ScrollBarHThumbBtnDisableBitmapID and attr.ScrollBarHThumbBtnDisableBitmapID ~= "" then
		    attrScrollBarH.ThumbBtnDisableBitmapID = attr.ScrollBarHThumbBtnDisableBitmapID
		end
		
		--ScrollBarH:UpdateUI()
		ScrollBarH:SetObjPos(attr.ScrollBarLeftOffset, selfHeight - attr.ScrollBarTopOffset - attr.HorizontalScrollBarHeight, selfWidth - attr.ScrollBarLeftOffset - attr.ScrollBarLeftOffset, selfHeight - attr.ScrollBarTopOffset)
end

function ListBox_OnInitControl(self)
    local attr = self:GetAttribute()
	local ctrlObj = self:GetControlObject("ctrl")
	
	if not self:GetVisible() then
		ctrlObj:SetVisible(false)
		ctrlObj:SetChildrenVisible(false)
	end
	
	if not self:GetEnable() then
		ctrlObj:SetEnable(false)
		ctrlObj:SetChildrenEnable(false)
		attr.NowState = "disable"
	end
	
	InitScrollBar(self)
	
	ListBox_UpdateRes(self)
	
	attr.CurSel = -1
end

function ListBox_OnLButtonDown(self)
end

function ListBox_OnLButtonUp(self)
end

function ListBox_OnMouseMove(self)
end

function ListBox_OnMouseLeave(self)
end

function ListBox_OnVisibleChange(self, visible)
    local ctrlObj = self:GetControlObject("ctrl")
	ctrlObj:SetVisible(visible)
	ctrlObj:SetChildrenVisible(visible)
end

function ListBox_OnEnableChange(self)
    local attr = self:GetAttribute()
	local ctrlObj = self:GetControlObject("ctrl")
	ctrlObj:SetEnable(enable)
	ctrlObj:SetChildrenEnable(enable)
	if enable then
	    ListBoxItem_UpdateRes(self,"normal")
	else
	    ListBoxItem_UpdateRes(self,"disable")
	end
end


--ListBoxItem begin:
--local function:
--NowState normal:Normal, down:Down, disable:Disable, hover:Hover
local function ListBoxItem_UpdateRes(self, newState)
    local attr = self:GetAttribute()
    
	local bkgTexture, TextColorID, TextFontID
	
	if newState == "down" then
	    bkgTexture = attr.BkgDownTextureID
		TextColorID = attr.TextDownColorID
		TextFontID = attr.TextDownFontID
	elseif newState == "disable" then
	    bkgTexture = attr.BkgDisableTextureID
		TextColorID = attr.TextDisableColorID
		TextFontID = attr.TextDisableFontID
	elseif newState == "hover" then
	    bkgTexture = attr.BkgHoverTextureID
		TextColorID = attr.TextHoverColorID
		TextFontID = attr.TextHoverFontID
	else 
	    bkgTexture = attr.BkgNormalTextureID
		TextColorID = attr.TextNormalColorID
		TextFontID = attr.TextNormalFontID
		newState = "normal"
	end
	
	local bkgObj = self:GetControlObject("bkg")
	
	if bkgTexture ~= "" and bkgObj then
		bkgObj:SetTextureID(bkgTexture)
	end
	
	attr.NowState = newState
end

function ListBoxItem_OnVisibleChange(self, visible)
	local ctrlObj = self:GetControlObject("ctrl")
	ctrlObj:SetVisible(visible)
	ctrlObj:SetChildrenVisible(visible)
end

--public function:
function ListBoxItem_SetSelect(self, bSelect, index)
    local attr = self:GetAttribute()
	if bSelect == true then
	    ListBoxItem_UpdateRes(self, "down")
		attr.bSelect = true
		attr.Index = index
		self:FireExtEvent("OnSelect", attr.Index)
	else
	    ListBoxItem_UpdateRes(self, "normal")
		attr.bSelect = false
	end
end

function ListBoxItem_GetSelect(self)
    local arrt = self:GetAttribute()
	return attr.Select
end

function ListBoxItem_GetTextWidth(self)
    local textobj = self:GetControlObject("text")
	if attr.Text ~= "" and textobj then
		local textwidth, textheight = textobj:GetTextExtent()
		return textwidth
	end
	return 0
end

--private function :

function ListBoxItem_OnEnableChange(self, enable)
    local attr = self:GetAttribute()
	local ctrlObj = self:GetControlObject("ctrl")
	ctrlObj:SetEnable(enable)
	ctrlObj:SetChildrenEnable(enable)
	if enable then
	    ListBoxItem_UpdateRes(self,"normal")
	else
	    ListBoxItem_UpdateRes(self,"disable")
	end
end

function ListBoxItem_OnInitControl(self)
    local attr = self:GetAttribute()
	local statusobj = self:GetControlObject("status")
	local typeobj = self:GetControlObject("type")
	local nameobj = self:GetControlObject("name")
	local dateobj = self:GetControlObject("date")
	local timeobj = self:GetControlObject("time")
	local sizeobj = self:GetControlObject("size")
	local progressobj = self:GetControlObject("progress")
	local uploadobj = self:GetControlObject("upload")
	local downloadobj = self:GetControlObject("download")
	local ctrlObj = self:GetControlObject("ctrl")
	local KB = 1024
	local MB = KB*1024
	local GB = MB*1024
	--XLMessageBox(attr.Name)
	if attr.Status ~= "" and statusobj then
	    if attr.Status == 0 then
			statusobj:SetResID('bitmap.listbox.taskitem.status.finished')
		elseif attr.Status == 1 then
			statusobj:SetResID('bitmap.listbox.taskitem.status.pause')
		elseif attr.Status == 2 then
			statusobj:SetResID('bitmap.listbox.taskitem.status.downloading')
		elseif attr.Status == 3 then
			statusobj:SetResID('bitmap.listbox.taskitem.status.uploading')
		elseif attr.Status == 4 then
			statusobj:SetResID('bitmap.listbox.taskitem.status.stopped')
		end
	end
	if attr.Name ~= nil and nameobj then
	    nameobj:SetText(attr.Name)
	end
	--XLMessageBox(string.format("status:%d  type:%d"),attr.Status,attr.Type)
	if attr.Type and typeobj then
		if attr.Type == 1 then
			typeobj:SetResID("bitmap.listbox.taskitem.type.movie")
		elseif attr.Type == 2 then
			typeobj:SetResID("bitmap.listbox.taskitem.type.music")
		elseif attr.Type == 4 then
			typeobj:SetResID("bitmap.listbox.taskitem.type.game")
		elseif attr.Type == 8 then
			typeobj:SetResID("bitmap.listbox.taskitem.type.book")
		end
	end
	if attr.Time ~= nil and dateobj then
		--通过模式匹配将时间分开
		local i,j = string.find(attr.Time, ".*|")
	    dateobj:SetText(string.sub(attr.Time, i, j-1))
		i,j = string.find(attr.Time, "|.*")
		timeobj:SetText(string.sub(attr.Time, i+1, j))
	elseif attr.Time and dateobj == nil then
		local minute = 60
		local hour = minute*60
		local content 
		if attr.Time == -1 then
			content = "--"
		else
			if attr.Time > hour then
				content = string.format("%d小时%d分",math.floor(attr.Time/hour),math.floor(attr.Time%hour/minute))
			elseif attr.Time > minute then
				content = string.format("%d分%d秒",math.floor(attr.Time/minute),attr.Time%minute)
			else
				content = string.format("%d秒",attr.Time)
			end		
		end
		timeobj:SetText(content)
	end
	if attr.Size ~= nil and sizeobj then
		local content
		if attr.Size > GB then
			content = string.format("%.2f GB", attr.Size/GB)
		elseif attr.Size > MB then
			content = string.format("%.2f MB", attr.Size/MB)
		elseif attr.Size > KB then
			content = string.format("%.2f KB", attr.Size/KB)
		else
			content = string.format("%d B", attr.Size)
		end
	    sizeobj:SetText(content)
	end
	if attr.Progress ~= nil and progressobj then
		progressobj:SetProgress(attr.Progress)
	end
	if attr.Upload ~= nil and uploadobj then
		if self:GetClass() == "BaseUI.ListBox.TaskItem" then
			local content
			if attr.Upload > MB then
				content = string.format("%.1fMB/s", attr.Upload/MB)
			elseif attr.Upload > KB then
				content = string.format("%dKB/s", attr.Upload/KB)
			else
				content = string.format("%dB/s", attr.Upload)
			end
			uploadobj:SetText(content)
		else
			uploadobj:SetText(attr.Upload)
		end
	end
	if attr.Download ~= nil and downloadobj then
		--XLMessageBox(attr.Download)
		if self:GetClass() == "BaseUI.ListBox.TaskItem" then
			local content
			if attr.Download > MB then
				content = string.format("%.1fMB/s", attr.Download/MB)
			elseif attr.Download > KB then
				content = string.format("%dKB/s", attr.Download/KB)
			else
				content = string.format("%dB/s", attr.Download)
			end
			downloadobj:SetText(content)
		else
			downloadobj:SetText(attr.Download)
		end
	end
	if not self:GetVisible() then
		ctrlObj:SetVisible(false)
		ctrlObj:SetChildrenVisible(false)
	end
	
	if not self:GetEnable() then
		ctrlObj:SetEnable(false)
		ctrlObj:SetChildrenEnable(false)
		attr.NowState = "disable"
	end
	ListBoxItem_UpdateRes(self)
end

function ListBoxItem_OnLButtonDown(self)
    local attr = self:GetAttribute()
	self:SetCaptureMouse(true)
    ListBoxItem_UpdateRes(self,"down")
    
end

function ListBoxItem_OnLButtonUp(self)
    local attr = self:GetAttribute()
    if attr.NowState == "down" then
		attr.bSelect = true
		AsynCall(function() self:FireExtEvent("OnSelect", attr.Index) end)
    end
    self:SetCaptureMouse(false)
end

function ListBoxItem_OnMouseMove(self)
    local attr = self:GetAttribute()
    if attr.NowState == "normal" and attr.bSelect ~= true then
        ListBoxItem_UpdateRes(self,"hover")
    end
end

function ListBoxItem_OnMouseLeave(self)
    local attr = self:GetAttribute()
	if attr.bSelect ~= true then
		ListBoxItem_UpdateRes(self,"normal")
	end
	self:SetCaptureMouse(false)
end

function ListBoxItem_OnPosChange(self)
    local left, top, right, bottom = self:GetObjPos()
	local nameobj = self:GetControlObject("name")
	local textwidth, textheight = nameobj:GetTextExtent()
	if textwidth > (right - left) then
	    self:FireExtEvent("OnWidthExtend", textwidth)
	end
end

function ListBox_OnPosChange(self)
	self:UpdateUI()
end

function OnResItemSave(self)
	local ctrl = self:GetOwnerControl()
	local attr = ctrl:GetAttribute()
	ctrl:GetOwnerControl():FireExtEvent("OnResItemSave", attr.Index+1)
end

function ListBoxItem_OnMouseWheel(self,x,y,distance)
	local scrollbarV = self:GetOwnerControl():GetControlObject("scrollbar.v")
	scrollbarV:OnMouseWheel(x,y,distance)
end

function OnNewTaskItemCheck(self, eventName, isCheck)
	local attr = self:GetOwnerControl():GetAttribute()
	local owner = self:GetOwnerControl():GetOwnerControl()
	owner:FireExtEvent("OnNewTaskItemCheck",attr.Index+1, isCheck)
end