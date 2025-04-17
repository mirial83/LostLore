-- Lost Lore window handler
-- coding: utf-8 'ä
import "Turbine.UI.Lotro"
import "Vinny.Common.DropMenu"
import "Vinny.Common.ScrollMenu"
import "Vinny.Common.AddField"
import "Vinny.Common.ToolTip"

local labelFont = Turbine.UI.Lotro.Font.TrajanPro14
local textFont = Turbine.UI.Lotro.Font.TrajanPro16
local Green = Turbine.UI.Color( 0, 1, 0 )
local White = Turbine.UI.Color( 1, 1, 1 )
local foreColor = Turbine.UI.Color( 0.9, 0.9, 0 )
local textColor = Turbine.UI.Color( 1, 1, 0.8 )
local backColor = Turbine.UI.Color( 0, 0, 0.1 )
local Alias = Turbine.UI.Lotro.ShortcutType.Alias
local Button = Turbine.UI.Lotro.Button
local CheckBox = Turbine.UI.Lotro.CheckBox
local AddField = Vinny.Common.AddField
local DropMenu = Vinny.Common.DropMenu
local ScrollMenu = Vinny.Common.ScrollMenu
local Label = Turbine.UI.Lotro.GoldButton
local TextBox = Turbine.UI.Lotro.TextBox
local Left = Turbine.UI.ContentAlignment.MiddleLeft
local Center = Turbine.UI.ContentAlignment.MiddleCenter
local Right = Turbine.UI.ContentAlignment.MiddleRight
local Coord = "^(%d+%.%d[ns]),(%d+%.%d[ew])$"
local Dloc = "(%d+%.%d[ns]),(%d+%.%d[ew])"
LL_checked = {}
Map_set,Mnr = {},0

LL_Window = class( Turbine.UI.Lotro.Window )

function LL_Name(area)
	local name = area.d
	if name:find(' ') then 
		if name:sub(-1)==' ' then name = name:sub(1,-2) end
		return name
	end
	return name.." page"
end

function FindMap(group,area)
	for i,t in ipairs(Map_set) do
		if t.g==group and t.a==area then return i end
	end
	return 0
end

function tCopy(t)
	local nt = {}
	for k,v in ipairs(t) do
		nt[k] = {g=v.g, a=v.a}
	end
	return nt
end

function LL_Clist()
	local group = LL_window.groupMenu:GetText()
	local area = LL_window.areaMenu:GetText()
	local pages = Lore[group][area]
	local list = {}
	local lbl = LL_window:IsShiftKeyDown() and 2 or 1
	for ix,loc in ipairs(pages.p) do
		if type(loc)=='table' then
			loc = loc[lbl] 
		end
		list[ix] = loc
	end
	if not LL_Checks[group] then LL_Checks[group] = {} end
	local LL_group = LL_Checks[group]
	if not LL_group[area] then LL_group[area] = {} end
	LL_checked = LL_group[area]
	LL_Cwindow = LL_CWindow(list)
	LL_Cwindow:SetVisible( true )
end

function LL_Area()
	local gname = LL_window.groupMenu:GetText()
	local aname = LL_window.areaMenu:GetText()
	Mnr = FindMap(gname,aname)
	LL_window.mapSet:SetText( Mnr..'/'..#Map_set )
	local group = Lore[gname]
	local area = group[aname]
	if not area then return end
	LL_window.doneBox:SetEnabled(false) -- Flag for SetChecked
	local cgroup = LL_Checks[LL_window.groupMenu:GetText()]
	local done = cgroup and (cgroup[aname]==true)
	LL_window.checkButton:SetEnabled( not done )
	LL_window.doneBox:SetChecked( done )
	LL_window.doneBox:SetEnabled( true )
	if LL_Cwindow and LL_Cwindow:IsVisible() then
		if done then LL_Cwindow:Close()
		else LL_Clist() end
	end
	if LL_Mwindow:IsVisible() then LL_Map() end
	LL_compass:SetVisible(false)
	LL_checked = cgroup and cgroup[aname] or {}
	LL_window.pageType:SetText( LL_Name(area) )
	LL_window.itemMenu:SetText( "" )
	LL_window.itemMenu.z = nil
	LL_window.nearButton:SetEnabled( true )
	LL_window.pageLoc:SetText( "" )
	LL_Mwindow.dloc = nil
	LL_window.headButton:SetEnabled( false )
	LL_window.pageDesc:SetText( "" )
	LL_window.tbl = area.p
	LL_window.stl = area.s
	region = area.r
	Mloc.r2 = area.r2
	local lvl,t = area.l, area.t
	local act = t and Atype[t] or "action"
	if lvl then 
		local txt = "This is a level "..lvl..' '..act..'.'
		if lvl>plevel then txt = "<rgb=#FFFF00>Warning: "..txt.."</rgb>" end
		print(txt) 
	end
	if area.c then print("Log: "..area.c) end
	if area.R then LL_rewards(area.R) end
	if area.r2 then print("A 2nd map is available.") end
	 LL_window.mapButton.skip = not area.r2
	if area.n then printh("Important Notice:\n"..area.n) end
end

function LL_Page(area,ix)
	local desc,r
	local page = area.p[tonumber(ix)]
	LL_Mwindow.dloc = nil
	if type(page)=='table' then
		LL_window.itemMenu.z = page.z
		r = page.r
		desc = page[2]
		if page[3] then 
			if desc:sub(-1)~=' ' then desc = '('..desc..'): '..page[3]
			else desc = desc:sub(1,-2)..': '..page[3] end
		end
		local y,x = desc:match(Dloc)
		if y then 
			LL_Mwindow.dloc = y..','..x 
			if LL_Mwindow:IsVisible() then LL_Map() end
		end
		page = page[1]
	else LL_window.itemMenu.z = nil end
	LL_window.pageLoc:SetText( page )
	LL_window.pageDesc:SetText( desc or '' )
	return page,desc,r
end

function LL_rewards(str)
	local txt = "Rewards: "..Reward[str:sub(1,1)]
	for i = 2,#str do
		txt = txt..', '..Reward[str:sub(i,i)]
	end
	print(txt)
end

function LL_List(group,area,neg)
	if group=="" then printe("Select a group.") return end
	if area=="" then printe("Select an area.") return end
	local pages = Lore[group][area]
	printh(LL_Name(pages).."s in "..group..":"..area)
	local list,yx = {}, {}
	for ix,loc in ipairs(pages.p) do
		local tb = {i=ix, l=loc}
		if type(loc)=='table' then
			tb.l = loc[1] 
			if loc[3] then tb.n = ' ('..loc[2]..'): '..loc[3] 
			else tb.n = ' '..loc[2] end
		end
		local y,x = tb.l:match(Coord)
		local str = neg=='s' and y or x
		local nbr = tonumber(str:sub(1,-2))
		if neg==str:sub(-1) then nbr = -nbr end
		tb.v = nbr
		table.insert(list,tb)
	end
	table.sort(list,function (a,b) return a.v > b.v end)
	for ix,loc in ipairs(list) do
		print('#'..loc.i..(loc.i<10 and ' ' or '').." @ "..loc.l..(loc.n or ''))
	end
end

function LL_Window:Constructor()
	Turbine.UI.Lotro.Window.Constructor( self )
	self:SetText( "Lost Lore" )
	self:SetSize( 300,311 )

	-- Position the window near the top and left-center of the screen.
	local pos = LL_Settings.pos1 or 
				{ x=Turbine.UI.Display.GetWidth()/5, y=self:GetHeight()/2 }
	self:SetPosition( pos.x, pos.y )

	-- Group label and menu
	AddField(self, Label, "Group:", {x=15,y=45}, {x=45,y=14} )
	self.groupMenu = AddField(self, ScrollMenu, "", {x=65,y=44}, {x=210,y=20} )
	local action = function()
		self.areaMenu:SetText( "" )
		self.itemMenu:SetText( "" )
		self.itemMenu.z = nil
		self.checkButton:SetEnabled( false )
		if LL_Cwindow then LL_Cwindow:SetVisible(false) end
		LL_Mwindow:SetVisible( false )
		self.doneBox:SetEnabled( false )
		self.doneBox:SetChecked( false )
		self.pageType:SetText( "" )
		self.nearButton:SetEnabled( false )
		self.pageLoc:SetText( "" )
		LL_Mwindow.dloc = nil
		self.headButton:SetEnabled( false )
		self.pageDesc:SetText( "" )
	end
	self.groupMenu.MenuBox.Click = function() 
		self.groupMenu:BuildMenu(Groups,17,print,action,nil,GroupC) 
	end

	-- Area label and menu
	AddField(self, Label, "Area:", {x=20,y=73}, {x=40,y=14} )
	self.areaMenu = AddField(self, ScrollMenu, "", {x=65,y=72}, {x=210,y=20} )
	local action = function()
		LL_Area()
		if LL_Mwindow:IsVisible() then LL_Map() end
	end
	self.areaMenu.MenuBox.Click = function()
        local group = self.groupMenu:GetText()
		if group~="" then
			local Area_list,colors,ln = {},{}
			local cgroup = LL_Checks[group]
			local hal = not LL_Settings.Hal
			for name,t in pairs(Lore[group]) do
				if cgroup and cgroup[name] then
					if cgroup[name]==true then colors[name]=Green 
					elseif next(cgroup[name]) then colors[name]=White end
				end
				local lvl = t.l
				if t.t=='Q' then lvl = lvl-6 end
				if plevel<lvl then colors[name]=Red end
				if hal or plevel>=lvl or self:IsShiftKeyDown() then 
					table.insert(Area_list,name) 
				end
			end
			if #Area_list<1 then printe("No usable areas.") return end
			table.sort(Area_list)
			self.areaMenu:BuildMenu(Area_list,15,print,action,nil,colors)
		else printe("Select a group.") end
	end

	-- Item label and menu
	AddField(self, Label, "Item:", {x=20,y=101}, {x=40,y=14} )
	self.itemMenu = AddField(self, ScrollMenu, "", {x=65,y=100}, {x=55,y=20} )
	local action = function(args)
		LL_Mwindow.dloc = nil
		local pages = Lore[self.groupMenu:GetText()][self.areaMenu:GetText()]
		local loc,desc,r = LL_Page(pages, self.itemMenu:GetText())
		self.pageLoc:SetText( loc )
		local str = LL_Name(pages).." @ "..loc
		if self.itemMenu.z then
			str = str.." (height="..self.itemMenu.z..")"
		end
		print( str )
		if desc then print(desc) end
		self.itemMenu.r = r
		self.headButton:SetEnabled( true )
		LL_compass.dot:SetVisible( false )
		LL_compass.box:SetText( '' )
	end
	self.itemMenu.action = action
	self.itemMenu.MenuBox.Click = function()
        local group = self.groupMenu:GetText()
		if group=="" then printe("Select a group.") return end
        local area = self.areaMenu:GetText()
		if area~="" then
			local Loc_list = {}
			for name,t in ipairs(Lore[group][area].p) do
				table.insert(Loc_list,tostring(name))
			end
			--self.itemMenu:BuildMenu(Loc_list,action,nil,print)
			self.itemMenu:BuildMenu(Loc_list,15,print,action,nil)
		else printe("Select an area.") end
	end

	-- Create an Check List button
	self.checkButton = AddField(self, Button, "Check List", {x=130,y=101}, {x=85,y=20} )
	Vinny.Common.ToolTip(self.checkButton,0,-20,"Shift for name list",123)
	self.checkButton:SetEnabled( false )
	self.checkButton.Click = function( sender,args )
		print("Opening Check List window")
		LL_Clist()
	end

	-- Done check box
	self.doneBox = AddField(self, CheckBox, "Done", {x=225,y=103}, {x=55,y=16} )
	Vinny.Common.ToolTip(self.doneBox,-70,-20,"All locations found",142)
	self.doneBox:SetEnabled( false )
	self.doneBox.CheckedChanged = function( sender,args )
		if not self.doneBox:IsEnabled() then return end
		Done = sender:IsChecked()
		print((Done and "Set " or "Cleared ").."Done.")
		self.checkButton:SetEnabled(not Done)
        local group = self.groupMenu:GetText()
        local area = self.areaMenu:GetText()
		local LL_group = LL_Checks[group]
		if Done then
			if not LL_group then
				LL_Checks[group] = {}
				LL_group = LL_Checks[group]
			end
			LL_group[area] = true
			if LL_Cwindow then LL_Cwindow:SetVisible(false) end
			Turbine.PluginData.Save(Turbine.DataScope.Character,"LL_Checks",LL_Checks)
		elseif LL_group and LL_group[area]==true then LL_group[area] = nil end
	end

	-- Page type
	AddField(self, Label, "Type:", {x=11,y=130}, {x=40,y=14} )
	self.pageType = AddField(self, TextBox, "", {x=50,y=132}, {x=162,y=18} )
	self.pageType:SetFont( Turbine.UI.Lotro.Font.TrajanPro15 )

	-- Nearest button
	self.nearButton = AddField(self, Button, "Nearest", {x=215,y=131}, {x=66,y=15} )
	self.nearButton:SetEnabled( false )
	local slot = Turbine.UI.Lotro.Quickslot()
	slot:SetParent( self.nearButton )
    slot:SetPosition( 0,0 )
    slot:SetOpacity( 0 )
    slot:SetSize( 70,15 )
    slot:SetShortcut(Turbine.UI.Lotro.Shortcut( Alias, "/llr ;loc" ))
    slot:SetAllowDrop( false )

	-- Page location
	AddField(self, Label, "Loc:", {x=11,y=151}, {x=40,y=14} )
	self.pageLoc = AddField(self, TextBox, "", {x=50,y=153}, {x=162,y=18} )
	
	-- Heading button
	self.headButton = AddField(self, Button, "Heading", {x=215,y=152}, {x=68,y=15} )
	Vinny.Common.ToolTip(self.headButton,-40,-20,"Shift for Compass",123)
	self.headButton:SetEnabled( false )
	self.headButton.Click = function( sender,args )
		LL_compass:SetVisible( true )
		if sender:IsShiftKeyDown() then LL_compass.slot:SetVisible( true ) end
	end
	local slot = Turbine.UI.Lotro.Quickslot()
	slot:SetParent( self.headButton )
    slot:SetPosition( 0,0 )
    slot:SetOpacity( 0 )
    slot:SetSize( 70,15 )
    slot:SetShortcut(Turbine.UI.Lotro.Shortcut( Alias, "/llh ;loc" ))
    slot:SetAllowDrop( false )

	-- Page description
	self.pageDesc = AddField(self, TextBox, "", {x=15,y=173}, {x=275,y=18} )

	-- Create a List items button
	self.itemsButton = AddField(self, Button, "List Items", {x=27,y=197}, {x=88,y=20} )
	Vinny.Common.ToolTip(self.itemsButton,0,-20,"Shift for not found",138)
	self.itemsButton.Click = function( sender,args )
        local group = self.groupMenu:GetText()
		if group=="" then printe("Select a group.") return end
        local area = self.areaMenu:GetText()
		if area=="" then 
			printh("Areas in "..group..":")
			for area,tb in pairs(Lore[group]) do
				local l = tb.l
				if plevel<l then l = "<rgb=#FF6040>"..l.."</rgb>" end
				print(area..", level="..l)
			end
			return 
		end
		local pages = Lore[group][area]
		local sk = sender:IsShiftKeyDown()
		printh(LL_Name(pages).."s in "..group..":"..area..(sk and " to find" or ''))
		local sk = sender:IsShiftKeyDown()
		if sk and LL_checked==true then print("<none>") return end
		for ix,loc in ipairs(pages.p) do
			if type(loc)=='table' then
				local desc = loc[2] or ''
				if loc[3] then 
					if desc:sub(-1)~=' ' then desc = '('..desc..'): '..loc[3]
					else desc = desc:sub(1,-2)..': '..loc[3] end
				end
				loc = loc[1]..' '..desc 
			end
			if not (sk and LL_checked[ix]) then
				print('#'..ix.." @ "..loc)
			end
		end
	end

	-- Create a N-S items button
	self.nsButton = AddField(self, Button, "List N-S", {x=125,y=197}, {x=70,y=20} )
	self.nsButton.Click = function( sender,args )
        local group = self.groupMenu:GetText()
        local area = self.areaMenu:GetText()
		LL_List(group,area,'s')
	end

	-- Create a E-W items button
	self.ewButton = AddField(self, Button, "List E-W", {x=205,y=197}, {x=70,y=20} )
	self.ewButton.Click = function( sender,args )
        local group = self.groupMenu:GetText()
        local area = self.areaMenu:GetText()
		LL_List(group,area,'w')
	end

	-- Save button
	self.saveButton = AddField(self, Button, "Save Maps", {x=50,y=223}, {x=85,y=18} )
	self.saveButton.Click = function( sender,args )
		if #Map_set>0 then
			LL_Checks.Saved = tCopy(Map_set)
			Turbine.PluginData.Save(Turbine.DataScope.Character,"LL_Checks",LL_Checks)
			print("Current map set saved for recall")
		else printe("No current map set.") end
	end

	-- Restore button
	self.restoreButton = AddField(self, Button, "Restore Maps", {x=145,y=223}, {x=105,y=18})
	self.restoreButton.Click = function( sender,args )
		local S = LL_Checks.Saved
		if S and #S>0 then
			self.mapSet:SetText( '1/'..#S )
			Map_set = tCopy(S)
			Mnr = 1
			local S1 = S[1]
			SetItem(S1.g, S1.a)
			if LL_Mwindow:IsVisible() then LL_Map() end
			if LL_compass:IsVisible() then
				LL_compass.box:SetText( '' )
				LL_compass.dot:SetVisible( false )
			end
			print("Saved map set restored.")
		else printe("No map set is Saved.") end
	end

	-- Find button
	self.findButton = AddField(self, Button, "Find what's here", {x=50,y=249}, {x=140,y=19})
	Vinny.Common.ToolTip(self.findButton,0,-20,"Shift for Find Nearby",147)
	local slot = Turbine.UI.Lotro.Quickslot()
	slot:SetParent( self.findButton )
    slot:SetPosition( 1,1 )
    slot:SetSize( 135,16 )
    slot:SetShortcut(Turbine.UI.Lotro.Shortcut( Alias, "/llf ;loc" ))
    slot:SetAllowDrop( false )

	-- Map button
	self.mapButton = AddField(self, Button, "Map", {x=200,y=249}, {x=50,y=19} )
	Vinny.Common.ToolTip(self.mapButton,-20,-20,"Shift for 2nd map",120)
	self.mapButton.skip = true
	local slot = Turbine.UI.Lotro.Quickslot()
	slot:SetParent( self.mapButton )
    slot:SetPosition( 1,1 )
    slot:SetSize( 45,16 )
    slot:SetShortcut(Turbine.UI.Lotro.Shortcut( Alias, "/llm ;loc" ))
    slot:SetAllowDrop( false )
	self.mapButton.slot = slot

	-- Map set
	AddField(self, Label, "Map #", {x=25,y=275}, {x=40,y=14} )
	self.mapSet = AddField(self, TextBox, "0/0", {x=69,y=275}, {x=33,y=18} )
	
	-- Remove button
	self.remButton = AddField(self, Button, "-", {x=107,y=275}, {x=10,y=19} )
	self.remButton.Click = function( sender,args )
		local area = self.areaMenu:GetText()
		if area=="" then printe("No area selected.") return end
		local group = self.groupMenu:GetText()
		local nr = FindMap(group,area)
		if nr==0 then printe("Area not in map set.") return end
		table.remove(Map_set,nr)
		Mnr = Mnr-1
		self.mapSet:SetText( "0/"..#Map_set )
		print("Map area removed.")
	end
	
	-- Add button
	self.addButton = AddField(self, Button, "+", {x=156,y=275}, {x=10,y=19} )
	self.addButton.Click = function( sender,args )
		local area = self.areaMenu:GetText()
		if area=="" then printe("No area selected.") return end
		local group = self.groupMenu:GetText()
		if FindMap(group,area)>0 then printe("Duplicate area") return end
		table.insert(Map_set,{g=group,a=area})
		Mnr = #Map_set
		self.mapSet:SetText( Mnr..'/'..Mnr )
		print("Map added.")
	end

	-- Next button
	self.nextButton = AddField(self, Button, "Next", {x=205,y=275}, {x=50,y=19} )
	Vinny.Common.ToolTip(self.nextButton,-30,-20,"Shift for Previous",123)
	self.nextButton.Click = function( sender,args )
		if #Map_set==0 then printe("No maps in set") return end
		local w = "Next"
		if self:IsShiftKeyDown() then
			Mnr = Mnr==1 and #Map_set or Mnr-1
			w = "Previous"
		else Mnr = Mnr==#Map_set and 1 or Mnr+1 end
		self.mapSet:SetText( Mnr..'/'..#Map_set )
		local S = Map_set[Mnr]
		SetItem(S.g, S.a)
		if LL_Mwindow:IsVisible() then LL_Map() end
		if LL_compass:IsVisible() then
			LL_compass.box:SetText( '' )
			LL_compass.dot:SetVisible( false )
		end
		print(w.." map selected.")
	end
end
LL_window = LL_Window()

-- Define checklist window
LL_CWindow = class( Turbine.UI.Lotro.Window )

function LL_CWindow:AddBox(name,line)
	local box = CheckBox()
	box:SetParent( self )
	box:SetForeColor( foreColor )
	box:SetPosition( 45,15+20*line )
	box:SetTextAlignment( Left )
	box:SetFont( textFont )
	local text = " #"..line..": "..name
	box:SetText( text )
	box:SetSize( #text*8+30, 20 )
	box.name = name
	box.line = line
	box:SetChecked(LL_checked[line])
	box.CheckedChanged = function( sender,args )
		local v = sender:IsChecked()
		local str = v and "Set" or "Cleared"
		LL_checked[sender.line] = v or nil
		print(str.." #"..line.." found." )
	end
	return box,#text
end

function LL_CWindow:Constructor(list)
	Turbine.UI.Lotro.Window.Constructor( self )
	self:SetText( "Check List" )

	if list then
		self.box = {}
		local maxw = 0

		-- Create checkboxes and add them to the window.
		for ix,name in ipairs(list) do
			local box,w = self:AddBox(name,ix)
			self.box[ix] = box
			if w>maxw then maxw = w end
		end
		local vsize = 50+20*#list
		self:SetSize( maxw*7+100,vsize )
		-- Position the window on left edge, aligned with the main window.
		local top = LL_window:GetTop()
		local height = LL_window:GetHeight()
		if vsize>height then top = top-vsize+height end
		if top<0 then top = 0 end
		self:SetPosition( 0,top )
	end
end

LL_Compass = class( Turbine.UI.Window )

function LL_Compass:Constructor()
	Turbine.UI.Window.Constructor( self )
	self:SetPosition( Turbine.UI.Display.GetWidth()/2-64, Turbine.UI.Display.GetHeight()/2-64 )
	self:SetSize( 128,128 )
	self:SetBackground( "Vinny/LostLore/Compass.tga" )

	-- Add distance text box
	self.box = AddField(self, TextBox, textFont, {x=42,y=55}, {x=42,y=20} )
	self.box:SetTextAlignment( Center )
	self.box:SetSelectable( false )

	local slot = Turbine.UI.Lotro.Quickslot()
	slot:SetParent( self.box )
    slot:SetPosition( 0,0 )
    slot:SetSize( 42,20 )
    slot:SetShortcut(Turbine.UI.Lotro.Shortcut( Alias, "/llh ;loc" ))
    slot:SetAllowDrop( false )
	slot:SetVisible( false )
	self.slot = slot

	-- creat a red dot direction pointer
	local dot = Turbine.UI.Control()
	dot:SetParent( self )
	dot:SetSize( 12,12 )
	dot:SetBackground( "Vinny/LostLore/Red dot.tga" )
	dot:SetVisible( false )
	self.dot = dot
--	dot.p = 0
end

function LL_Compass:MouseDown( args )
	if ( args.Button == Turbine.UI.MouseButton.Left ) then
		self.X = args.X
		self.Y = args.Y
		self.dragging = true
	end
end

function LL_Compass:MouseMove( args )
	local x, y = self:GetPosition()
	if ( self.dragging ) then
		self:SetPosition( x + args.X-self.X, y + args.Y-self.Y )
	end
end

function LL_Compass:MouseUp( args )
	if ( args.Button == Turbine.UI.MouseButton.Left ) then
		self.dragging = false
	end
end

LL_compass = LL_Compass()

LL_MWindow = class( Turbine.UI.Lotro.Window )
Msize = 400

function LL_MWindow:Constructor(list)
	Turbine.UI.Lotro.Window.Constructor( self )
	self:SetText( "Lore Map" )

	-- Position the window right of the main window
	local x,y = LL_window:GetPosition()
	self:SetPosition( x+305,y-70 )
	self:SetSize( Msize,Msize+14 )
	self:SetZOrder(70) -- On top
	
	-- Location label
	local field = TextBox()
	field:SetParent( self )
	field:SetSize( 80,15 )
	field:SetBackColor( backColor )
	field:SetReadOnly( true )
	field:SetFont( Turbine.UI.Lotro.Font.Verdana12 )
	field:SetTextAlignment( Center )
	field:SetVisible(false)
	field:SetZOrder(60) -- On top
	self.loc = field
	
    self.MouseEnter = function( args )
        self.loc:SetVisible(true)
    end
    self.MouseMove = function( args )
		local x, y = self:GetMousePosition()
		xp,yp = x-20,y-18
		x,y = Mloc.x0+(x-3)/Mloc.dw, Mloc.y0+(415-y)/Mloc.dw
		local xd,yd = 'e','n'
		if x<0 then x = -x; xd = 'w' end
		if y<0 then y = -y; yd = 's' end
		x,y = math.floor(x*10)/10, math.floor(y*10)/10
		local loc = y..yd..','..x..xd
		local xs = #loc*6+12
        self.loc:SetText( loc )
        self.loc:SetSize( xs,15 )
		if xp<0 then xp = 0
		elseif xp+xs>Msize then xp = Msize-xs end
		self.loc:SetPosition( xp,yp )
    end
    self.MouseLeave = function( args )
        self.loc:SetVisible(false)
    end
end

LL_Mwindow = LL_MWindow()

-- Set Escape action
LL_window:SetWantsKeyEvents( true )
LL_window.KeyDown = function(sender, args)
	if( args.Action == Turbine.UI.Lotro.Action.Escape ) then
		LL_window:SetVisible( false )
		LL_Mwindow:SetVisible( false )
		LL_compass:SetVisible( false )
		if LL_Cwindow then LL_Cwindow:SetVisible(false) end
	end
end
