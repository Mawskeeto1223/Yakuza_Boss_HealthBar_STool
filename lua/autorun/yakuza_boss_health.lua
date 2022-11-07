
Yakuza_bossHealthSystem = Yakuza_bossHealthSystem or {}

if SERVER then
	util.AddNetworkString("yakuza_add_boss")
	util.AddNetworkString("yakuza_remove_boss")
	util.AddNetworkString("yakuza_boss_data")
end

-- Getters and setters
function Yakuza_bossHealthSystem:GetBoss()
	return self.bossEntity
end

function Yakuza_bossHealthSystem:GetMult()
	return self.bossDmgscale
end

function Yakuza_bossHealthSystem:AddBoss(ent, maxHealth, health, name, label, dmgscale, icon, netonebar, barstyle)
	if SERVER then
		ent:SetHealth(health)
		ent:SetMaxHealth(maxHealth)
	end

	self.bossEntity = ent
	self.bossName = name
	self.bossLabel = label
	self.bossDmgscale = dmgscale
	self.bossIcon = icon
	self.bossOnebar = netonebar
	self.bossBarStyle = barstyle
	
	if SERVER then
		net.Start("yakuza_add_boss")
			net.WriteEntity(self.bossEntity)
			net.WriteString(name)
			net.WriteString(label)
			net.WriteString(icon)
			net.WriteString(netonebar)
			net.WriteEntity(barstyle)
		net.Broadcast()

		net.Start("yakuza_boss_data")
			net.WriteEntity(self.bossEntity)
			net.WriteString(name)
			net.WriteString(label)
			net.WriteString(icon)
			net.WriteString(netonebar)
			net.WriteEntity(barstyle)
		net.Broadcast()
	end
end

function Yakuza_bossHealthSystem:RemoveBoss()
	self.bossEntity = nil

	if SERVER then
		net.Start("yakuza_remove_boss")
		net.Broadcast()
	end
end

function Yakuza_bossHealthSystem:IsValidBoss()
	return IsValid(self.bossEntity)
end

if CLIENT then
	net.Receive("yakuza_add_boss", function(len) 
		local ent = net.ReadEntity()
		local name = net.ReadString()
		local label = net.ReadString()
		local icon = net.ReadString()
		local onebar = net.ReadString()
		local barstyle = net.ReadEntity()

		Yakuza_bossHealthSystem:AddBoss(ent, name, label, icon, onebar, barstyle)
	end)

	net.Receive("yakuza_remove_boss", function(len)
		Yakuza_bossHealthSystem:AddBoss(NULL)
	end)
end

--SERVER HOOKS!!!!!!--
hook.Add("OnNPCKilled","Yakuza_BossNPCDeath",function(npc)
	if not IsValid(Yakuza_bossHealthSystem:GetBoss()) then return end
	if npc == Yakuza_bossHealthSystem:GetBoss() then
		Yakuza_bossHealthSystem:RemoveBoss()
	end
end)

hook.Add("PlayerDeath","Yakuza_BossDeath",function(victim)
	if not IsValid(Yakuza_bossHealthSystem:GetBoss()) then return end
	if victim == Yakuza_bossHealthSystem:GetBoss() then
		Yakuza_bossHealthSystem:RemoveBoss()
	end
end)

hook.Add("EntityRemoved","Yakuza_BossRemoved",function(ent)
	if not IsValid(Yakuza_bossHealthSystem:GetBoss()) then return end
	if ent == Yakuza_bossHealthSystem:GetBoss() then
		Yakuza_bossHealthSystem:RemoveBoss()
	end
end)

hook.Add("PlayerDisconnected","Yakuza_BossDisconnected",function(ply)
	if not IsValid(Yakuza_bossHealthSystem:GetBoss()) then return end
	if ply == Yakuza_bossHealthSystem:GetBoss() then
		Yakuza_bossHealthSystem:RemoveBoss()
	end
end)

hook.Add("EntityTakeDamage","Yakuza_BossDamageMult",function(ply,dmg)
	if not IsValid(Yakuza_bossHealthSystem:GetBoss()) then return end
	local bossent = dmg:GetAttacker()
	if bossent == Yakuza_bossHealthSystem:GetBoss() then
		dmg:ScaleDamage(Yakuza_bossHealthSystem:GetMult())
	end
end) 