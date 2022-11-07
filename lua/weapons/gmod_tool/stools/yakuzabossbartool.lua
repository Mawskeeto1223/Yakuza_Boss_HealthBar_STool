-- Credits to Stoneman for the original Boss Health Bar tool!
-- Modified by oteek
TOOL.Category = "Yakuza Tools"
TOOL.Name = "Yakuza Health Bars"

if CLIENT then
	language.Add( "tool.yakuzabossbartool.name", "Yakuza Health Bar Tool" )
	language.Add( "tool.yakuzabossbartool.desc", "Broadcast a Yakuza styled health bar to a server." )
	language.Add( "tool.yakuzabossbartool.0", "Left Click: Select target to become a boss, Right click: Select yourself to become the boss, Reload: Disable all boss health bars." )
end

if SERVER then
    ---Precaching network messages---
    util.AddNetworkString("yakuza_bossbar_start")
    util.AddNetworkString("yakuza_bossbar_stop")
    util.AddNetworkString("yakuza_bossbar_death")
	util.AddNetworkString("yakuza_bossbar_buffer")
end

TOOL.ClientConVar[ "name" ] = "Man Too Angry to Die"
TOOL.ClientConVar[ "icon" ] = ""	--unused
TOOL.ClientConVar[ "style" ] = "0"
TOOL.ClientConVar[ "maxhealth" ] = "5000"
TOOL.ClientConVar[ "health" ] = "5000"
TOOL.ClientConVar[ "onebar" ] = "500"
TOOL.ClientConVar[ "label" ] = ""	--unused
TOOL.ClientConVar[ "dmgscale" ] = "1"

if CLIENT then
	language.Add("bossbar.y0", "Yakuza 0")
	language.Add("bossbar.kiwami", "Yakuza Kiwami")
	language.Add("bossbar.oe", "Yakuza 3/4")
	language.Add("bossbar.y5", "Yakuza 5")
	language.Add("bossbar.ishin", "Yakuza Ishin!")
	language.Add("bossbar.ps2y1", "Yakuza 1 (PS2)")
	language.Add("bossbar.ps2y2", "Yakuza 2 (PS2)")
	language.Add("bossbar.kenzan", "Yakuza Kenzan!")
end

list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.y0", { yakuzabossbartool_style = 0 })
list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.kiwami", { yakuzabossbartool_style = 1 })
list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.ishin", { yakuzabossbartool_style = 2 })
list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.oe", { yakuzabossbartool_style = 3 })
list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.y5", { yakuzabossbartool_style = 4 })
list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.ps2y1", { yakuzabossbartool_style = 5 })
list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.ps2y2", { yakuzabossbartool_style = 6 })
list.Set("YKZ_BOSSBAR_STYLE", "#bossbar.kenzan", { yakuzabossbartool_style = 7 })

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	
	local Options = {
		Default = {
			bossbartool_icon 		= "",
		}
	}

    CPanel:AddControl( "ComboBox", 
	{ 
		MenuButton = 1,
		Folder = "bossbartool",
		Options = { [ "#preset.default" ] = ConVarsDefault },
		CVars = table.GetKeys( ConVarsDefault ) 
	}
	)
	
	CPanel:AddControl("Header",
	{
		Text = "Yakuza Boss Bar Tool",
		Description = [[Left-Click to enable a boss health bar for the entity you're looking at. Right click to disable the boss bar.]]
	}
	)

    CPanel:AddControl( "TextBox",
	{
		Label = "Name:",
		Command = "yakuzabossbartool_name",
		MaxLength = "48"
	}
	)
	
	CPanel:AddControl( "ComboBox", { Label = "Style", Options = list.Get("YKZ_BOSSBAR_STYLE") })
	
	CPanel:AddControl( "slider", 
	{
		Label = "Max Health:",
		Command = "yakuzabossbartool_maxhealth",
		min = "1",
		max = "40000"
	}
	)

    CPanel:ControlHelp("Sets the max health of the boss entity.")

    CPanel:AddControl( "slider", 
	{ 
		Label = "Health:",
		Command = "yakuzabossbartool_health",
		min = "1",
		max = "40000"
	} 
	)

    CPanel:ControlHelp("Sets the current health of the boss entity.")
	
	CPanel:AddControl( "slider", 
	{ 
		Label = "One Bar Value:",
		Command = "yakuzabossbartool_onebar",
		min = "500",
		max = "4000"
	} 
	)

    CPanel:ControlHelp("How much HP should one bar equal to?")

	CPanel:AddControl( "slider", 
	{ 
		type = "float",
		Label = "Damage Scale:",
		Command = "yakuzabossbartool_dmgscale",
		min = "0",
		max = "1000"
	} 
	)

    CPanel:ControlHelp("Multiplies the boss damage by this number.")
	--[[
    CPanel:AddControl( "TextBox", 
	{ 
		Label = "Label:",
		Command = "yakuzabossbartool_label",
		MaxLength = "12"
	} 
	)

    CPanel:ControlHelp("Sets the label.")	
	--]]
end

function TOOL:LeftClick(tr)
	if not IsFirstTimePredicted() then return end
	if Yakuza_bossHealthSystem:IsValidBoss() then return end

	if !IsValid(tr.Entity) then return end
	local ent = tr.Entity
	
	if ent:IsWorld() then return end
	if (!ent:IsPlayer() and !ent:IsNPC() and !ent:IsNextBot() ) then return end
	
	self:SetBoss(ent)
end

function TOOL:RightClick(tr)
	if not IsFirstTimePredicted() then return end
	if Yakuza_bossHealthSystem:IsValidBoss() then return end

	local ent = self:GetOwner()

	self:SetBoss(ent)
end

function TOOL:Reload()
	if not IsFirstTimePredicted() then return end
	if Yakuza_bossHealthSystem:IsValidBoss() then
		Yakuza_bossHealthSystem:RemoveBoss()
		if CLIENT then
			notification.AddLegacy(("Turned off the boss bar"),0,5)
			surface.PlaySound("buttons/button14.wav")
		end
	end
	if not Yakuza_bossHealthSystem:IsValidBoss() then return end
	self:SetBoss(NULL)
end

function TOOL:SetBoss(ent)
	if CLIENT then
		if ent:IsPlayer() then
			notification.AddLegacy(("Turned on the boss bar for " .. ent:Nick()),0,5)
		else
			notification.AddLegacy(("Turned on the boss bar for an NPC"),0,5)
		end
	end
	
	local barstyle =  self:GetClientInfo("style")
	local maxHealth = self:GetClientInfo("maxhealth")
	local health =  self:GetClientInfo("health")
	local name = self:GetClientInfo("name")
	local label = self:GetClientInfo("label")
	local dmgscale = self:GetClientInfo("dmgscale")
	local icon = self:GetClientInfo("icon")
	local netonebar = self:GetClientInfo("onebar")
	Yakuza_bossHealthSystem:AddBoss(ent, maxHealth, health, name, label, dmgscale, icon, netonebar, barstyle)
end