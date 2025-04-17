-- Lost Lore reference plugin by David Down
-- coding: utf-8 'ä
import "Turbine.Gameplay"
import "Turbine.UI"
import "Vinny.Common"
import "Vinny.LostLore.LL_Data"
import "Vinny.Common.Help"

function print(text) Turbine.Shell.WriteLine("<rgb=#00FFFF>LL:</rgb> "..text) end
function printh(text) print("<rgb=#00FF00>"..text.."</rgb>") end
function printe(text) print("<rgb=#FF6040>Error: "..text.."</rgb>") end

local lPat = "You are on %a* server "
local locPat = "You are on %a* server %d* at r(%d) lx%d+ ly%d+ ox.-%d+%.?%d* oy.-%d+%.?%d* oz(.-%d+%.?%d*)"
local liPat = "You are on %a* server %d* at r(%d) lx%d+ ly%d+ i%d* ox.-%d+%.?%d* oy.-%d+%.?%d* oz(.-%d+%.?%d*)"
local iPat = "You are on %a* server %d* at r(%d) lx%d+ ly%d+ cInside ox.-%d+%.?%d* oy.-%d+%.?%d* oz(.-%d+%.?%d*)"
local Coord = "(%d+%.%d[NnSs]), ?(%d+%.%d[EeWw])$"
local Zloc = "^(.+): .+: (%d+%.%d[NS]), (%d+%.%d[EW])$"
red,yel,grn,mag = "FF0000", "FFFF00", "00FF00", "FF00FF"
Red = Turbine.UI.Color( 1, 0, 0 )
local snl,enl = " <rgb=#00FF00>(", ")</rgb>"
local LLv = "Lost Lore "..Plugins["LostLore"]:GetVersion()
local CD = {[0]='S','SSW','SW','WSW','W','WNW','NW','NNW',
				'N','NNE','NE','ENE','E','ESE','SE','SSE'}
Mloc = {x0=0, y0=0, dw=1}

player = Turbine.Gameplay.LocalPlayer.GetInstance()
pname = player:GetName()
if pname:sub(1,1)=="~" then
	printe("Session Play detected.")
	return
end
plevel = player:GetLevel()
region = 0 -- no validation if 0

LL_Settings = Turbine.PluginData.Load(Turbine.DataScope.Server,"LostLore_Settings")
if type(LL_Settings) ~= "table" then
	LL_Settings = { }
    printh(LLv..", settings initialized.")
else printh(LLv..", settings loaded.") end
LL_Checks = Turbine.PluginData.Load(Turbine.DataScope.Character,"LL_Checks")
if type(LL_Checks) ~= "table" then LL_Checks = {} end
for i,n in pairs(Fix) do
	if LL_Checks[i] then
		LL_Checks[n] = LL_Checks[i]
		LL_Checks[i] = nil
		print("Renamed the group '"..i.."' to '"..n.."'")
	end
end

-- sorted group list
Groups,GroupC = {},{}
local hal = LL_Settings.Hal
for name,t in pairs(Lore) do
	local ok = not hal
	for n,at in pairs(t) do
		local lvl = at.l
		if at.t=='Q' then lvl = lvl-6 end
		if plevel>=lvl then ok = 1 break end
	end
    if ok then 
		table.insert(Groups,name)
		if ok==true then GroupC[name] = Red end
	 end
end
table.sort(Groups)

import "Vinny.LostLore.LL_Window"
if LL_Checks.Last then
	local last = LL_Checks.Last
	LL_window.groupMenu:SetText(last.group or last.map)
	if last.area then
		LL_window.areaMenu:SetText(last.area)
		LL_Area()
	end
end

Plugins.LostLore.Open = function(sender,args)
	LL_window:SetVisible( true )
	LL_window:SetZOrder( 2 )
end

Turbine.Chat.Received = function (sender,args)
	local msg = args.Message
	if not msg:match(lPat) then return end
	local r,oz = msg:match(locPat)
	if not r then r,oz = msg:match(liPat) end
	if not r then r,oz = msg:match(iPat) end
	if not r then printe("Unknown pattern") return end
	local z = math.floor((tostring(oz)+1)/2)/10
	local z0 = LL_window.itemMenu.z
	if z0 then
		dz = math.floor(z-z0)
		local s = dz<-.1 and -dz.." below" or dz>.1 and dz.." above" or "level with"
		print("You are "..s.." the current item")
	else print("Height="..z) end
end

--local sa1,sa2,sa3 = 0.19509,0.38268,0.55557
local function distance(dy,dx,head)
	local d = math.sqrt(dy*dy+dx*dx)
	if (not head) or d<0.1 then return d end
	return d, math.atan2(dx,dy)
end

local function locV(str,neg)
    local nbr = tonumber(str:sub(1,-2))
    if neg:find(str:sub(-1)) then nbr = -nbr end
    return nbr
end

function Cfind(loc)
	for group,Atbl in pairs(Lore) do
		for area,Itbl in pairs(Atbl) do
			if Itbl.r==region or Itbl.r==0 then
				for ix,c in pairs(Itbl.p) do
					local r
					if type(c)=="table" then r = c.r; c = c[1] end
					if c==loc and not (r and math.abs(r)~=region) then return group,area,ix end
				end
			end
		end
	end
end

function LL_Map(ploc,msg)
	if not ploc then ploc = Ploc end
	Ploc = nil
	local tbl = LL_window.tbl
	if not tbl then printe("No area selected.") return end
	local Dloc = LL_Mwindow.dloc
	LL_Mwindow = LL_MWindow()
	LL_Mwindow:SetVisible( true )
	LL_Mwindow.dloc = Dloc
	local list,mr = {}, region
	mr = LL_Mwindow:IsShiftKeyDown() and Mloc.r2 or nil
	for ix,loc in ipairs(tbl) do
		local r,s
		if type(loc)=='table' then r = loc.r; s = loc[2]; loc = loc[1] end
--		print("mr="..(mr or '')..', r='..(r or ''))
		if mr==r then
			local y,x = loc:match(Coord)
			list[ix] = {y=locV(y,"Ss"), x=locV(x,"Ww"), s=s}
		end
	end
	local xh,xl,yh,yl = -999,999,-999,999
	for ix,loc in pairs(list) do
		if loc.x>xh then xh=loc.x end
		if loc.x<xl then xl=loc.x end
		if loc.y>yh then yh=loc.y end
		if loc.y<yl then yl=loc.y end
	end
	local dx,dy = xh-xl, yh-yl
	if dx<1 then dx = 1 end
	if dy<1 then dy = 1 end
	local cx,cy = (xh+xl)/2, (yh+yl)/2
	local w = (dx>dy and dx or dy)*1.1
	local w2 = w/2
	local dw = Msize/w
	Mloc.x0 = cx-w2
	Mloc.y0 = cy-w2
	Mloc.dw = dw
	-- Add any stable locations
	local stl = LL_window.stl
	if stl then 
		for ix,loc in pairs(stl) do
			local y,x = loc:match(Coord)
			if not x or not y then printe("loc="..loc) end
			y,x = locV(y,"Ss"), locV(x,"Ww")
			local stb = Turbine.UI.Control()
			stb:SetParent( LL_Mwindow )
			stb:SetSize( 12,12 )
			stb:SetPosition( Msize/2-6+(x-cx)*dw,Msize/2+9+(cy-y)*dw )
			stb:SetBackground( "Vinny/LostLore/Stable.tga" )
			if type(ix)=="string" then
				stb.MouseEnter = function( args )
					LL_Mwindow.loc:SetText( ix )
					LL_Mwindow.loc:SetSize( #ix*6+12,15 )
				end
			end
		end
	end
	for ix,loc in pairs(list) do
		-- Add location text box
		local box = Turbine.UI.Lotro.TextBox()
		box:SetParent( LL_Mwindow )
		local dx = ix>9 and 10 or 7
		box:SetPosition( Msize/2-dx+(loc.x-cx)*dw,Msize/2+8+(cy-loc.y)*dw )
		box:SetSize( ix>9 and 23 or 16, 15 )
		box:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleCenter )
		box:SetFont( Turbine.UI.Lotro.Font.Verdana12 )
		box:SetSelectable( false )
		box:SetReadOnly( true )
		box:SetText( ix )
		box:SetBackColor( Turbine.UI.Color( 0, 0, 0 ) )
		if LL_checked~=true and LL_checked[ix] then
			box:SetForeColor( Turbine.UI.Color( 0, 0.9, 0 ) )
		end
		box.MouseClick = function( args )
			print("Selected "..ix)
			LL_window.itemMenu:SetText( ix )
			LL_window.itemMenu.action( ix )
		end
		if loc.s then
			box.MouseEnter = function( args )
				LL_Mwindow.loc:SetText( loc.s )
				LL_Mwindow.loc:SetSize( #loc.s*6+15,15 )
			end
		end
	end
	-- destination location
	if Dloc then
		local y,x = Dloc:match(Coord)
		local y1,x1 = locV(y,"Ss"), locV(x,"Ww")
		local dot = Turbine.UI.Control()
		dot:SetParent( LL_Mwindow )
		dot:SetSize( 6,6 )
		dot:SetPosition( Msize/2-2+(x1-cx)*dw,Msize/2+13+(cy-y1)*dw )
		dot:SetBackground( "Vinny/LostLore/Cyan dot.tga" )
	end
	-- check current location
	if not ploc then return end
	local reg,y,x = ploc:match(Zloc)
	if not y then 
		y,x = ploc:match(Coord)
	end
	if not y then printe("No Loc in instance.") return end
	if region>0 and reg and Region[reg]~=region then 
		if msg then printe("Not in this region.") end
		return 
	end
	local y1,x1 = locV(y,"Ss"), locV(x,"Ww")
	if y1<cy-w2 or y1>cy+w2 or x1<cx-w2 or x1>cx+w2 then 
		if msg then print("Warning: Position not on this map.") end
		return 
	end
	-- create a red dot for current location
	local dot = Turbine.UI.Control()
	dot:SetParent( LL_Mwindow )
	dot:SetSize( 6,6 )
	dot:SetPosition( Msize/2-2+(x1-cx)*dw,Msize/2+13+(cy-y1)*dw )
	dot:SetBackground( "Vinny/LostLore/Red dot2.tga" )
	Ploc = ploc
end

function locD(loc,y0,x0)
	local r
	if type(loc)=="table" then 
		r = loc.r
		if r and r<0 then r = -r end
		loc = loc[1] 
	end
	local y,x = loc:match(Coord)
	if not y or not x then printe("Bad loc: "..loc) end
	y,x = locV(y,"Ss"), locV(x,"Ww")
	return distance(y-y0,x-x0), r
end

function Near(loc)
	local y0,x0,g,a,tbl = loc:match(Coord)
	y0,x0 = locV(y0,"Ss"), locV(x0,"Ww")
	local found = 0
	local add = #Map_set==0
	for group,Atbl in pairs(Lore) do
		local cgroup = LL_Checks[group]
		for area,Itbl in pairs(Atbl) do
			if (Itbl.r==region or Itbl.r==0) and plevel>=Itbl.l
					and not (cgroup and (cgroup[area]==true)) then
				for ix,p in pairs(Itbl.p) do
					local d,r = locD(p,y0,x0)
					if d and d<6 and not (r and r~=region) then
						found = found+1
						print(group..':'..area..', d='..(math.floor(d*10+0.5)/10))
						g = group; a = area; tbl = Itbl
						if add then table.insert(Map_set,{g=group,a=area}) end
						break
					end
				end
			end
		end
	end
	if found==0 then print("(None found)")
	elseif found==1 then SetItem(g,a) end
	if add and #Map_set>1 then 
		printh("Map set created.") 
		local gname = LL_window.groupMenu:GetText()
		local aname = LL_window.areaMenu:GetText()
		Mnr = FindMap(gname,aname)
		LL_window.mapSet:SetText( Mnr..'/'..#Map_set )
	end
end

function Location(args,find)
	local reg,y,x = args:match(Zloc)
	if not y then printe("No location data in instance.") return end
	reg = Region[reg]
	if region>0 and reg~=region and reg~=LL_window.itemMenu.r then 
		printe("Not in this region.") return end
	if LL_Mwindow:IsVisible() then LL_Map(args) end
	local y1,x1 = locV(y,"Ss"), locV(x,"Ww")
	local mi, loc, desc
	if find then
		local group = LL_window.groupMenu:GetText()
		local area = LL_window.areaMenu:GetText()
		if #area<1 then return end
		print("Finding the nearest unvisited location:")
		local pages = Lore[group][area]
		local checked = LL_Checks[group]
		if checked then checked = checked[area] end
		if checked==true then printe("All locations found.") return end
		local md = 9999
		for ix,p in ipairs(pages.p) do
			local d,r = locD(p,y1,x1)
			if d and d<md and not (checked and checked[ix] or r and reg~=r) then 
				md = d
				mi = ix
			end
		end
		if not mi then printe("No locations to find here.") return end
		LL_window.itemMenu:SetText( mi )
		loc, desc = LL_Page(pages, mi)
		LL_window.headButton:SetEnabled( true )
	else loc = LL_window.pageLoc:GetText() end
	if #loc<1 then return end
	local y0,x0 = loc:match(Coord)
	y2,x2 = locV(y0,"Ss"), locV(x0,"Ww")
	local d,r = distance(y2-y1,x2-x1,true)
	d = string.format("%.1f",d)
	if mi then loc = '#'..mi..' @ '..loc end
	if LL_compass:IsVisible() then
		LL_compass.box:SetText( d )
		local y,x = 58,58
		if r then
			x = math.floor(-math.cos(r)*58+58.5)
			y = math.floor(math.sin(r)*58+58.5)
		end
		LL_compass.dot:SetPosition( y,x )
		LL_compass.dot:SetVisible( true )
	end
	if find or not LL_compass:IsVisible() and not LL_Mwindow:IsVisible() then
		if r then 
			local h = math.floor(r/math.pi*8+8.5)
			if h>15 then h = 0 end
			print(loc.." is "..d..'m '..CD[h])
		else print(loc.." is here.") end
		if desc and find then print(desc) end
	end
	if r or not LL_Cwindow or not LL_Cwindow:IsVisible() then return end
	local ix = tonumber(LL_window.itemMenu:GetText())
	desc = LL_window.pageDesc:GetText()
	if ix and not (desc and desc:sub(1,1)=='(' and 
			desc:sub(-2)~=': ' and not desc:find('@')) then 
		LL_Cwindow.box[ix]:SetChecked(true)
	end
end

function CheckList( done )
	printh("Check Lists that are "..(done and "done:" or "active:"))
	local found = false
	for group,tbl in pairs(LL_Checks) do
		local areas = Lore[group]
		if areas then
			for name,list in pairs(tbl) do
				local str = group..":"..name
				if list ~= true then
					if not done then
					local tot = #areas[name].p
					local cnt = 0
					for i,v in pairs(list) do
						if v then cnt = cnt+1 end
					end
					print(str.." ("..cnt.."/"..tot..")")
					found = true
					end
				elseif done then print(str); found = true end
			end
		end
	end
	if not found then print("(None found)") end
end

function SetItem(group,aname,ix)
	LL_window.groupMenu:SetText( group )
	LL_window.areaMenu:SetText( aname )
	LL_window.itemMenu:SetText( ix )
	area = Lore[group][aname]
	region = area.r
	Mloc.r2 = area.r2
	LL_window.tbl = area.p
	LL_window.stl = area.s
	LL_Page(area, ix)
	local cgroup = LL_Checks[group]
	local done = cgroup and (cgroup[aname]==true)
	if LL_Cwindow and LL_Cwindow:IsVisible() then 
		if done then LL_Cwindow:Close()
		else LL_Clist() end
	end
	LL_window.checkButton:SetEnabled( not done )
	LL_window.doneBox:SetEnabled( true )
	LL_window.doneBox:SetChecked( done )
	LL_window.pageType:SetText( LL_Name(area) )
	LL_window.nearButton:SetEnabled( true )
	LL_window.headButton:SetEnabled( true )
	if LL_Mwindow:IsVisible() then LL_Map() end
end

LL_Command = Turbine.ShellCommand()
function LL_Command:GetShortHelp() return Vinny.Common.Help(help,"??") end
function LL_Command:GetHelp() return Vinny.Common.Help(help,"help") end

-- Main command processing
function LL_Command:Execute( cmd,args,str )
	if Vinny.Common.HelpCmd(cmd,args,help) then return end
	if cmd=="llw" then
		if args=='c' then 
			local v = LL_compass:IsVisible()
			LL_compass:SetVisible( not v )
			print("Toggled Compass window")
		elseif args=='cc' then 
			local v = LL_compass.slot:IsVisible()
			LL_compass.slot:SetVisible( not v )
			print("Toggled Compass click o"..(v and 'ff' or 'n'))
		else LL_window:SetVisible( true ) end
		return
	end
	if cmd=="llr" then
		Location(args,true)
		return
	end
	if cmd=="llh" then
		Location(args)
		if LL_compass.slot:IsShiftKeyDown() then 
			LL_compass:SetVisible( true )
			LL_compass.slot:SetVisible( true )
		end
		return
	end
	if cmd=="llm" then
		if args=="list" then
			if #Map_set==0 then print("Map set is empty.") return end
			printh("Map set list:")
			for i,t in ipairs(Map_set) do
				print(t.g..':'..t.a)
			end
			return
		end
		LL_Map(args,true)
		return
	end
	if cmd=="lln" then
		printh("Finding matching names for '"..args.."':")
		args = args:lower()
		local found
		for group,Atbl in pairs(Lore) do
			for area in pairs(Atbl) do
				if area:lower():find(args) then
					found = true
					print(group..':'..area)
				end
			end
		end
		if not found then print("(None found)") end
		return
	end
	if cmd=="lld" then
		local y,x = args:lower():match(Coord)
		if y then
			loc = y..','..x
			print("Destination set to "..loc)
			LL_window.pageLoc:SetText( loc )
			LL_window.headButton:SetEnabled( true )
			local area = LL_window.areaMenu:GetText()
			if #area>1 then
				LL_Mwindow.dloc = loc
				if LL_Mwindow:IsVisible() then LL_Map() end
			end
		else printe("No coordinates in "..args) end
		return
	end
	if cmd=="llf" then
		local y,x = args:match(Coord)
		if y then
			local loc = y:lower()..','..x:lower()
			local reg = args:match(Zloc)
			region = Region[reg]
			if LL_window:IsShiftKeyDown() then
				printh("Finding collections near "..loc.." in "..reg)
				Near(loc)
				return
			end
			local group,area,ix = Cfind(loc)
			if group then
				print(group..':'..area..'#'..ix..' = '..loc)
				SetItem(group,area,ix)
			else printe("No exact match found for "..loc) end
		else printe("No coordinates in "..args) end
		return
	end
	if args=="show" then
		LL_window:SetVisible( true )
		return
	end
	if args=="groups" then
		printh("Group names found:")
		for i,name in pairs(Groups) do
			print('  '..name)
		end
		return
	end
	if args=="done" then
		CheckList( true )
		return
	end
	if args=="part" then
		CheckList( false )
		return
	end
	if args=="quest" or args=="deed" then
		printh("Checking for available "..args..'s:')
		local t,found = args=="deed" and 'D' or 'Q'
		for group,mt in pairs(Lore) do
			local ch = LL_Checks[group]
			for area,at in pairs(mt) do
				if at.l<=plevel and at.t==t and not (ch and ch[area]) then
					found = true
					print(group..':'..area..', level='..at.l)
				end
			end
		end
		if not found then print("None found") end
		return
	end
	local m = Lore[args]
	if m then
		printh("Object categories in "..args)
		for name in pairs(m) do
			print('  '..name)
		end
		return
	end
    Vinny.Common.Help(help,args)
end

Turbine.Shell.AddCommand( "ll;lld;llf;llh;llm;lln;llr;llw;ll?",LL_Command )

Plugins.LostLore.Unload = function(sender,args)
	local group = LL_window.groupMenu:GetText()
	if group~='' then
		last = {group=group}
		local area = LL_window.areaMenu:GetText()
		if #area>1 then last.area = area end
	end
	LL_Checks.Last = last
    Turbine.PluginData.Save(Turbine.DataScope.Character,"LL_Checks",LL_Checks)
    print(LLv..", settings saved.")
end

-- Options panel
import "Vinny.Common.Options"
OP = Vinny.Common.Options_Init(print,LL_Settings,LL_window,"LostLore_Settings")

local Hal = Vinny.Common.Options_Box(OP,30," Hide above level")
if LL_Settings.Hal then Hal:SetChecked(true) end
Hal.CheckedChanged = function( sender, args )
	LL_Settings.Hal = sender:IsChecked()
    Turbine.PluginData.Save(Turbine.DataScope.Server,"LostLore_Settings",LL_Settings)
	print((LL_Settings.Hal and "En" or "Dis").."abled Hide above level.")
end

-- Help text
help = {
	pre = "ll",
	arg = {
		deed = "Show availabe deeds.",
		quest = "Show availabe quests.",
		done = "Show finished check lists.",
		part = "Show active check lists.",
		groups = "List known group names.",
		show = "Open Lost Lore window.",
		["<group>"] = "Get categories in the group area <group>",
	},
	cmd = {
		["lld <loc>"] = "Set destination to find.",
		["llf ;loc"] = "Find item at this location.",
		llm = "Open/update the Lore Map window",
		["lln <str>"] = "Find names matching <str>",
		["llr ;loc"] = "Find item nearest this location.",
		llw = {
			[" "] = "Open Lost Lore window.",
			c = "Toggle Compass window visibility.",
			cc = "Toggle Compass window click.",
		},
	},
}
