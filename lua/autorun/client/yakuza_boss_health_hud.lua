-- Credits to Stoneman for the original Boss Health Bar tool and Kurgan for the concept.
-- Modified by oteek

-- MAJOR BUGS/MISSING FEATURES:
-- 1. Lerp animation can go out of bounds because of poor implementation.
-- 2. (FIXED) Doesn't properly update when used on NPCs/SNPCs but works fine for player and NextBots.
-- 3. Doesn't scale on different resolutions but positions itself correctly at least.
-- 4. Y3/Y5/Ishin!/Y0/Kiwami health bar styles should decrease from left to right instead from right to left.
-- 5. No support for multiple bosses (no multiple health bars on screen).
-- 6. Health bar shatter animation on defeat is not implemented.

    surface.CreateFont('YakuzaBossFont_Default',{
		font='Tahoma',
		size=29,
		weight = 100
	})
	surface.CreateFont('YakuzaPS2_BossFont',{
		font='Tahoma',
		size=35,
		weight = 100
	})
	surface.CreateFont('YakuzaIshin_BossFont',{
		font='Tahoma',
		size=33,
		weight = 100
	})
	surface.CreateFont('YakuzaOE_BossFont',{
		font='Tahoma',
		size=35,
		weight = 100
	})
	
	surface.CreateFont('Yakuza_HPFont',{
		font='Tahoma',
		size=24,
		weight = 100
	})
	
    local totalbar = 0.392		//used for width formula
    local totalbar_ps2 = 0.276
	local barmax = 752.64		//default width value for ishin/y0/kiwami static bars in pixels
	local barmax_ps2 = 529
	local barmax_h = 12			//bar height in pixels
	local bossbg_empt = Material("yak_bossbar/bossbar_empt.png")
	local bossbg_0 = Material("yak_bossbar/bossbar_0.png")
	local bossbg_kiwami = Material("yak_bossbar/bossbar_kiwami.png")
	local bossbg_oe = Material("yak_bossbar/bossbar_oe.png")
	local bossbg_kenzan = Material("yak_bossbar/bossbar_kenzan.png")
	local bossbg_5 = Material("yak_bossbar/bossbar_5.png")
	local bossbg_ishin = Material("yak_bossbar/bossbar_ishin_st.png")
	local bossbg_ishin_bg = Material("yak_bossbar/bossbar_ishin_bg.png")
	local bossbg_ps2y1 = Material("yak_bossbar/bossbar_1_ps2.png")
	local bossbg_ps2y2 = Material("yak_bossbar/bossbar_2_ps2.png")
	local armorgauge = Material("yak_bossbar/armorgauge.png")
	local oegauge = Material("yak_bossbar/oe/6.png")
	
	-- this is probably not needed
	local oegauge1 = Material("yak_bossbar/oe/1.png")
	local oegauge2 = Material("yak_bossbar/oe/2.png")
	local oegauge3 = Material("yak_bossbar/oe/3.png")
	local oegauge4 = Material("yak_bossbar/oe/4.png")
	local oegauge5 = Material("yak_bossbar/oe/5.png")
	local oegauge6 = Material("yak_bossbar/oe/6.png")
	local oegauge7 = Material("yak_bossbar/oe/7.png")
	local oegauge8 = Material("yak_bossbar/oe/8.png")
	local oegauge9 = Material("yak_bossbar/oe/9.png")
	local oegauge10 = Material("yak_bossbar/oe/10.png")
	local oegauge11 = Material("yak_bossbar/oe/11.png")
	local oegauge12 = Material("yak_bossbar/oe/12.png")
	local oegauge13 = Material("yak_bossbar/oe/13.png")
	--
	
	local gauge = Material("yak_bossbar/gauge.png")		-- active bar (we arent actually drawing all 16 bars at once, just 2 at a time)
	local gauge2 = Material("yak_bossbar/gauge.png")	-- inactive static bar behind the active one (gauge)
	local gaugedmg = Material("yak_bossbar/gauge.png")	
	local smoothHP = 1		-- used for lerp animation
	local lerpMult = 10		-- lerp multiplier (varies by style)
	
	local barf_color = Color (165, 0, 0,255)	-- only if bar cannot go any further
	//local bossmat_start = Material("yakuza/hud/enemybar_0_start.png")
	//local bossmat_mid = Material("yakuza/hud/enemybar_0_mid.png")
	//local bossmat_end = Material("yakuza/hud/enemybar_0_end.png")
	

----LOCALIZATION-----------------
	local Yakuza_BossDataTable = {}
	local Yakuza_BossBarBody
	local Yakuza_BossBarImage
	local Yakuza_BossBarLoss
	local Yakuza_BossBarHP
	local Yakuza_BossBarName
	local Yakuza_BossBarLabel
------------------------------------

local function RemoveBossHealth() -- Removes boss bar
	if !Yakuza_bossHealthSystem:IsValidBoss() then return end
	local pos = Vector(9999,99999,99999) -- Banishes the skull sprite on bosses (left over from the original addon)
	timer.Create ("Yakuza_Bossbar_closetimer", 0.5, 1, function ()
	Yakuza_bossHealthSystem:RemoveBoss()
	timer.Remove("HealthUpdate")
	end)
end

net.Receive("yakuza_boss_data", function(len) 
	local ent = net.ReadEntity()
	local name = net.ReadString()
	local label = net.ReadString()
	local icon = net.ReadString()
	local netonebar = net.ReadString()
	local style = net.ReadString()
	if icon == "" then
		icon = "bossbar/default.png"
	end
	Yakuza_BossDataTable = {}
	Yakuza_BossDataTable.Name = name
	Yakuza_BossDataTable.Label = label
	Yakuza_BossDataTable.Icon = icon
	Yakuza_BossDataTable.OneBar = netonebar
	Yakuza_BossDataTable.BarStyle = style
end)

net.Receive("yakuza_healthupdate", function()
	local hp = net.ReadFloat()
	local boss = Yakuza_bossHealthSystem:GetBoss()
	if IsValid(boss) then boss:SetNWFloat("Health", hp) end
end)

hook.Add("HUDPaint", "Yakuza_BossHealthBar.Render", function()
	if !Yakuza_bossHealthSystem:IsValidBoss() then return end
	if Yakuza_BossDataTable.Name == nil then return end
	
	local boss = Yakuza_bossHealthSystem:GetBoss()
	local boss_health = boss:GetNWFloat("Health",0)
	local boss_max_health = boss:GetMaxHealth()
	local onebar = GetConVar("yakuzabossbartool_onebar"):GetInt()
	local barscr_w = 945	--bar x position
	local barscr_h = 75		--bar y position
	local bossbar_style = GetConVar("yakuzabossbartool_style"):GetInt()
	//local boss_health_percent = math.Clamp(boss_health / boss_max_health,0,1)
	//local boss_health_bar_percent = math.Clamp(boss_health / onebar,-1,0)
	//local boss_health_bar_width = totalbar * ScrW() * boss_health_bar_percent
	local sscale = ScreenScale(640) -- different res scaling not implemented but this is what you'll need to use
	
	local isY3 = false
	local isY2 = false
	
	
	if bossbar_style == 0 then
		surface.SetMaterial(bossbg_0) -- Use our cached material
		surface.SetDrawColor(255, 255, 255, 225) -- Set the drawing color
		surface.DrawTexturedRect( ScrW()-1040, ScrH()-85, 1000,31) -- Actually draw the boss bar
		gauge = Material("yak_bossbar/gauge.png")
		gauge2 = Material("yak_bossbar/gauge.png")
		barscr_w = 945
		barscr_h = 75
		totalbar = 0.392
		barmax = 752.64
		barmax_h = 12
		isY3 = false
		isY2 = false
		lerpMult = 15
	elseif bossbar_style == 1 then
		surface.SetMaterial(bossbg_kiwami)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect( ScrW()-1040, ScrH()-85, 1000,31)
		gauge = Material("yak_bossbar/gauge.png")
		gauge2 = Material("yak_bossbar/gauge.png")
		barscr_w = 945
		barscr_h = 75
		totalbar = 0.392
		barmax = 752.64
		barmax_h = 12
		isY3 = false
		isY2 = false
		lerpMult = 15
	elseif bossbar_style == 2 then
		surface.SetMaterial(bossbg_ishin_bg)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect(ScrW()-1140, ScrH()-155, 1000,150)
		surface.SetMaterial(bossbg_empt)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect(ScrW()-1040, ScrH()-85, 1000,31)
		surface.SetMaterial(bossbg_ishin)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect(ScrW()-180, ScrH()-100, 40.3,46.8)
		gauge = Material("yak_bossbar/gaugey5.png")
		gauge2 = Material("yak_bossbar/gaugey5.png")
		barscr_w = 945
		barscr_h = 75
		totalbar = 0.392
		barmax = 752.64
		barmax_h = 12
		isY3 = false
		isY2 = false
		lerpMult = 15
	elseif bossbar_style == 3 then
		surface.SetMaterial(bossbg_oe)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect( ScrW()-950, ScrH()-130, 850,72)
		barscr_w = 894
		barscr_h = 78
		totalbar = 0.3808
		barmax = 731
		barmax_h = 11
		isY3 = true
		isY2 = false
		lerpMult = 10
	elseif bossbar_style == 4 then
		surface.SetMaterial(bossbg_5)
		surface.SetDrawColor(200, 200, 200, 225)
		surface.DrawTexturedRect( ScrW()-746, ScrH()-83, 698,23)
		gauge = Material("yak_bossbar/gaugey5.png")
		gauge2 = Material("yak_bossbar/gaugey5.png")
		barscr_w = 680
		barscr_h = 76
		totalbar = 0.2734375
		barmax = 525
		barmax_h = 9
		isY3 = false
		isY2 = false
		lerpMult = 13
	elseif bossbar_style == 5 then
		surface.SetMaterial(bossbg_ps2y1)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect( ScrW()-1040, ScrH()-85, 1000,45)
		gauge = Material("yak_bossbar/gauge.png")
		gauge2 = Material("yak_bossbar/gauge.png")
		barscr_w = 658
		barscr_h = 68
		totalbar = totalbar_ps2
		barmax = barmax_ps2
		barmax_h = 11
		isY3 = false
		isY2 = false
		lerpMult = 3
	elseif bossbar_style == 6 then
		surface.SetMaterial(bossbg_ps2y2)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect( ScrW()-1040, ScrH()-85, 1000,45)
		gauge = Material("yak_bossbar/oe/6.png")
		gauge2 = Material("yak_bossbar/oe/6.png")
		barscr_w = 658
		barscr_h = 68
		totalbar = totalbar_ps2
		barmax = barmax_ps2
		barmax_h = 11
		isY3 = false
		isY2 = true
		lerpMult = 3
	elseif bossbar_style == 7 then
		surface.SetMaterial(bossbg_kenzan)
		surface.SetDrawColor(255, 255, 255, 225)
		surface.DrawTexturedRect( ScrW()-915, ScrH()-115, 920,62)
		barscr_w = 857
		barscr_h = 77
		totalbar = 0.382
		barmax = 731
		barmax_h = 12
		isY3 = true
		isY2 = false
		lerpMult = 10
	end
	
	//testing
	//print(gauge)
	//print("Old: "..gauge2)
	//print(boss_health_bar_width)

	-- below is a leftover from original attempt by Kurgan
	--[[
	surface.SetFont( "MainFont" ) // LABEL
	surface.SetTextColor( 255, 242, 211 )
	surface.SetTextPos( ScrW()-1040, ScrH()-80 ) 
	surface.DrawText(BossDataTable.Label)
	--]]
	
	-- boss name
	if bossbar_style < 2 then
		draw.SimpleTextOutlined(Yakuza_BossDataTable.Name, "YakuzaBossFont_Default",ScrW()-195, ScrH()-117, Color(255, 242, 211, 225), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 1.5, Color(0,0,0,255))
	elseif bossbar_style == 2 then
		draw.SimpleTextOutlined(Yakuza_BossDataTable.Name, "YakuzaIshin_BossFont", ScrW()-195, ScrH()-112, Color(255, 242, 211, 225), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 1.5, Color(0,0,0,255))
	elseif bossbar_style == 3 then
		draw.SimpleTextOutlined(Yakuza_BossDataTable.Name, "YakuzaOE_BossFont", ScrW()-165, ScrH()-126, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 1.5, Color(0,0,0,255))
	elseif bossbar_style == 4 then
		draw.SimpleTextOutlined(Yakuza_BossDataTable.Name, "YakuzaOE_BossFont", ScrW()-155, ScrH()-120, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 1.5, Color(0,0,0,255))
	elseif bossbar_style < 7 && bossbar_style > 4 then
		draw.SimpleText(Yakuza_BossDataTable.Name, "YakuzaPS2_BossFont", ScrW()-700, ScrH()-82, color_white, TEXT_ALIGN_RIGHT)
	elseif bossbar_style == 7 then
		draw.SimpleTextOutlined(Yakuza_BossDataTable.Name, "YakuzaIshin_BossFont", ScrW()-855, ScrH()-112, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, 1.5, Color(0,0,0,255))
	end
	
	local function drawHPBar(baramount) -- yuck
		local bar1_color = Color (255, 121, 0,255)
		local bar2_color = Color (239, 198, 74,255)
		local bar3_color = Color (41, 162, 49,255)
		local bar4_color = Color (41, 198, 239,255)
		local bar5_color = Color (148, 125, 181,255)
		local bar6_color = Color (165, 158, 165,255)
		local bar7_color = Color (33, 170, 255,255)
		local bar8_color = Color (49, 93, 222,255)
		local bar9_color = Color (148, 81, 165,255)	-- aizawa
		local bar10_color = Color (123, 105, 132,255)
		local bar11_color = Color (189, 157, 200,255)
		local bar12_color = Color (50, 66, 56,255)	-- ishin dark
		local bar13_color = Color (110, 0, 0,255)	-- only if above 30k health
		local bard_color = Color (173, 8, 82,255)	--damage color
		
		--ps2 y1:
		local bard_ps2_color = Color (233, 62, 174,255)	-- dmg
		//local barf_ps2_color = Color (255, 0, 128,255)	-- full (unused)
		
		local bar1_y1ps2_color = Color (185, 205, 37,255)
		local bar2_y1ps2_color = Color (53, 57, 227,255)
		local bar3_y1ps2_color = Color (174, 66, 227,255)
		
		--ps2 y2:
		local bar1_y2ps2_color = Color (207, 182, 72,255)
		local bar2_y2ps2_color = Color (48, 71, 172,255)
		local bar3_y2ps2_color = Color (154, 198, 72,255)
		local bar4_y2ps2_color = Color (105, 53, 211,255)
		local bar5_y2ps2_color = Color (90, 197, 44,255)
		local bar6_y2ps2_color = Color (157, 50, 204,255)
		
		--y3oe
		local bard_oe_color = Color (197, 66, 153,255)	-- dmg
		
		if bossbar_style < 3 then
			bar1_color = Color (255, 121, 0,255)
			bar2_color = Color (239, 198, 74,255)
			bar3_color = Color (41, 162, 49,255)
			bar4_color = Color (41, 198, 239,255)
			bar5_color = Color (148, 125, 181,255)
			bar6_color = Color (165, 158, 165,255)
			bar7_color = Color (33, 170, 255,255)
			bar8_color = Color (49, 93, 222,255)
			bar9_color = Color (148, 81, 165,255)
			bar10_color = Color (123, 105, 132,255)
			bar11_color = Color (189, 157, 200,255)
			bard_color = Color (173, 8, 82,255)
			isY3 = false
		elseif bossbar_style == 3 or bossbar_style == 7 then
			-- since we are using actual bar textures from Y3, we don't need to color them using SetDrawColor
			bar1_color = Color (255, 255, 255,255)
			bar2_color = Color (255, 255, 255,255)
			bar3_color = Color (255, 255, 255,255)
			bar4_color = Color (255, 255, 255,255)
			bar5_color = Color (255, 255, 255,255)
			bar6_color = Color (255, 255, 255,255)
			bar7_color = Color (255, 255, 255,255)
			bar8_color = Color (255, 255, 255,255)
			bar9_color = Color (255, 255, 255,255)
			bar10_color = Color (255, 255, 255,255)
			bar11_color = Color (255, 255, 255,255)
			bard_color = bard_oe_color
			isY3 = true
		elseif bossbar_style > 4 && bossbar_style < 7 then
			isY3 = false
			bard_color = bard_ps2_color	-- dmg
			if bossbar_style == 5 then
				bar1_color = bar1_y1ps2_color
				bar2_color = bar2_y1ps2_color
				bar3_color = bar3_y1ps2_color
				bar4_color = bar4_y2ps2_color
				bar5_color = bar5_y2ps2_color
				bar6_color = bar6_y2ps2_color
			elseif bossbar_style == 6 then
				bar1_color = bar1_y2ps2_color
				bar2_color = bar2_y2ps2_color
				bar3_color = bar3_y2ps2_color
				bar4_color = bar4_y2ps2_color
				bar5_color = bar5_y2ps2_color
				bar6_color = bar6_y2ps2_color
			end
		end
		
		local boss_health_bar_percent = math.Clamp(boss_health / onebar, 0.0015, baramount)
		local boss_health_bar_width = totalbar * ScrW() * (boss_health_bar_percent - (baramount - 1))
		smoothHP = Lerp(lerpMult * FrameTime(), smoothHP, boss_health_bar_percent)
		local boss_health_bar_smooth_w = totalbar * ScrW() * (smoothHP - (baramount - 1))
		
		//print(boss_health_bar_width)
		if baramount == 16 then		-- dark blood red bar, on the verge of reaching the maximum limit of health bars available.
			-- behold the abysmal implementation, hence my reluctantness on releasing it.
			-- 1st DrawTexturedRect is gauge2 (static bar which is drawn behind the active one)
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar12_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)

			-- 2nd is for the smooth animation when bar decreases (due to the way it's done, if receiving too much damage, visual bugs are to be expected)
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			-- the active bar
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar13_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then	-- exclusively used by Y3 and Kenzan styles, disgusting implementation YandereDev style.
				gauge = Material("yak_bossbar/oe/6.png")
				gauge2 = Material("yak_bossbar/oe/6.png")
			end
		elseif baramount == 15 then
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar9_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar12_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/6.png")
				gauge2 = Material("yak_bossbar/oe/9.png")
			end
		elseif baramount == 14 then		-- Jo & So Amon from Yakuza 0
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar11_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar9_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/9.png")
				gauge2 = Material("yak_bossbar/oe/11.png")
			end
		elseif baramount == 13 then
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar10_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar11_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/11.png")
				gauge2 = Material("yak_bossbar/oe/10.png")
			end
		elseif baramount == 12 then
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar9_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar10_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/10.png")
				gauge2 = Material("yak_bossbar/oe/9.png")
			end
		elseif baramount == 11 then
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar10_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar9_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/9.png")
				gauge2 = Material("yak_bossbar/oe/10.png")
			end
		elseif baramount == 10 then		-- Blood-Drunk Master from Lost Judgment
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar9_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar10_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/10.png")
				gauge2 = Material("yak_bossbar/oe/9.png")
			end
		elseif baramount == 9 then		-- Masato Aizawa from Yakuza 5
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar8_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar9_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/9.png")
				gauge2 = Material("yak_bossbar/oe/8.png")
			end
		elseif baramount == 8 then
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar7_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar8_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/8.png")
				gauge2 = Material("yak_bossbar/oe/7.png")
			end
		elseif baramount == 7 then
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar6_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar7_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/7.png")
				gauge2 = Material("yak_bossbar/oe/6.png")
			end
		elseif baramount == 6 then
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar5_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar6_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/6.png")
				gauge2 = Material("yak_bossbar/oe/5.png")
			end
		elseif baramount == 5 then		-- light purple (Keiji Shibusawa) (5th)
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar4_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar5_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/5.png")
				gauge2 = Material("yak_bossbar/oe/4.png")
			end
		elseif baramount == 4 then		-- light blue (4th)
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar3_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar4_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/4.png")
				gauge2 = Material("yak_bossbar/oe/3.png")
			end
		elseif baramount == 3 then		-- green (3rd)
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar2_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar3_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/3.png")
				gauge2 = Material("yak_bossbar/oe/2.png")
			end
		elseif baramount == 2 then		-- yellow (2nd)
			surface.SetMaterial(gauge2)
			surface.SetDrawColor(bar1_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,barmax,barmax_h)
			
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar2_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/2.png")
				gauge2 = Material("yak_bossbar/oe/1.png")
			end
		elseif baramount == 1 then		-- orange (1st)
			surface.SetMaterial(gaugedmg)
			surface.SetDrawColor(bard_color)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_smooth_w,barmax_h)
			
			surface.SetMaterial(gauge)
			surface.SetDrawColor(bar1_color) -- Set the drawing color
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_health_bar_width,barmax_h)
			if isY3 then
				gauge = Material("yak_bossbar/oe/1.png")
				//gauge2 = Material("yak_bossbar/oe/0.png")
			end
			//print(barmax)
		end
	end
	
	local hOverflow = false
	
	-- core
	if boss_health > onebar * 16 then
		hOverflow = true
		gauge2 = Material("yak_bossbar/oe/6.png")
	elseif boss_health <= onebar * 16 && boss_health > onebar * 15 then
		drawHPBar(16)
	elseif boss_health <= onebar * 15 && boss_health > onebar * 14 then
		drawHPBar(15)
	elseif boss_health <= onebar * 14 && boss_health > onebar * 13 then
		drawHPBar(14)
	elseif boss_health <= onebar * 13 && boss_health > onebar * 12 then
		drawHPBar(13)
	elseif boss_health <= onebar * 12 && boss_health > onebar * 11 then
		drawHPBar(12)
	elseif boss_health <= onebar * 11 && boss_health > onebar * 10 then
		drawHPBar(11)
	elseif boss_health <= onebar * 10 && boss_health > onebar * 9 then
		drawHPBar(10)
	elseif boss_health <= onebar * 9 && boss_health > onebar * 8 then
		drawHPBar(9)
	elseif boss_health <= onebar * 8 && boss_health > onebar * 7 then
		drawHPBar(8)
	elseif boss_health <= onebar * 7 && boss_health > onebar * 6 then
		drawHPBar(7)
	elseif boss_health <= onebar * 6 && boss_health > onebar * 5 then
		drawHPBar(6)
	elseif boss_health <= onebar * 5 && boss_health > onebar * 4 then
		drawHPBar(5)
	elseif boss_health <= onebar * 4 && boss_health > onebar * 3 then
		drawHPBar(4)
	elseif boss_health <= onebar * 3 && boss_health > onebar * 2 then
		drawHPBar(3)
	elseif boss_health <= onebar * 2 && boss_health > onebar then
		drawHPBar(2)
	elseif boss_health <= onebar then
		drawHPBar(1)
	end

	//print(isY3)
	//print("Current: "..whichbar)
	//print("Old: "..whichbarOld)
	
	-- bonus feature
	if boss:IsPlayer() then					--TODO: add lerp when armor damaged
		local boss_armor = boss:Armor()
		local boss_max_armor = boss:GetMaxArmor()
		local boss_armor_percent = math.Clamp(boss_armor / boss_max_armor,0,1)
		local boss_armor_bar_percent = math.Clamp(boss_armor / 100,0,1)
		local boss_armor_bar_width = totalbar * ScrW() * boss_armor_bar_percent
		if boss_armor > 0 then
			surface.SetMaterial(armorgauge)
			surface.SetDrawColor(255,255,255)
			surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,boss_armor_bar_width,barmax_h) -- Boss HP Rectangle
		end
	end
	
	if hOverflow == true then				--TODO: fix value positioning for different styles
		-- what happens when you try to go above 16 health bars?
		local fwidth = totalbar * ScrW() * 1
		if isY3 or isY2 then
			gauge2 = Material("yak_bossbar/oe/6.png")
		else
			gauge2 = Material("yak_bossbar/gauge.png")
		end
		surface.SetMaterial(gauge2)
		surface.SetDrawColor(barf_color)
		surface.DrawTexturedRect(ScrW()-barscr_w, ScrH()-barscr_h,fwidth,barmax_h)
		local overflownHealth = boss_health - (onebar * 16) + onebar
		draw.SimpleTextOutlined(overflownHealth.."/"..onebar, "Yakuza_HPFont",ScrW()-195, ScrH()-83, Color(255, 255, 255, 225), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 1.5, Color(0,0,0,255))
		--perhaps maybe it's best to display it as percentage instead
		//draw.SimpleTextOutlined("Overflow!", "Yakuza_HPFont",ScrW()-195, ScrH()-83, Color(255, 255, 255, 225), TEXT_ALIGN_RIGHT, TEXT_ALIGN_RIGHT, 1.5, Color(0,0,0,255))
	end
	
	//print(boss_health_bar_percent)
	//print(boss_armor_bar_percent)
	
end)