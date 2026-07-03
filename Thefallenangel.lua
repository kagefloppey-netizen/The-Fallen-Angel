-- The Fallen Angel
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local WALK_SPEED = 7
local RUN_SPEED = 27
local ANGRY_SPEED = 175
local ANGRY_DURATION = 4
local DASH_SPEED = 1000
local DASH_DURATION = 0.2

local RUN_COOLDOWN = 2.5
local ANGRY_COOLDOWN = 5
local DASH_COOLDOWN = 1.5
local SMITE_COOLDOWN = 2 

local AWAKEN_SPEED = 80
local AWAKEN_DURATION = 100
local AWAKEN_COOLDOWN = 30

-- Animations
local IDLE_ANIM_ID = "rbxassetid://123349905320515"
local WALK_ANIM_ID = "rbxassetid://100425249271090"
local RUN_ANIM_ID  = "rbxassetid://116881956670910"
local EMOTE_ANIM_ID = "rbxassetid://105522886401681"
local ANGRY_ANIM_ID = "rbxassetid://132105268936736"
local DASH_ANIM_ID = "rbxassetid://109621871839352" 
local AWAKEN_ANIM_ID = "rbxassetid://123178564946946"
local AWAKEN_MOVE_ANIM = "rbxassetid://72840399233287" 

local started, runEnabled, emoteEnabled = false, false, false
local angryActive, dashActive = false, false
local awakeningActive, buffActive, flying = false, false, false

local runCooldownActive, angryCooldownActive, dashCooldownActive = false, false, false
local awakeningCooldownActive, smiteCooldownActive = false, false

local currentHumanoid, currentAnimator = nil, nil
local idleTrack, walkTrack, runTrack, emoteTrack, angryTrack, dashTrack, awakenTrack, awakenMoveTrack = nil, nil, nil, nil, nil, nil, nil, nil

local moveConn, diedConn, jumpConn = nil, nil, nil
local gui, crackImage, countdownLabel = nil, nil, nil
local startButton, runButton, emoteButton, angryButton, dashButton, awakenButton, smiteButton, flyButton = nil, nil, nil, nil, nil, nil, nil, nil

-- HỆ THỐNG ÂM THANH
local function playSound(id, volume, pitch, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = volume
	sound.PlaybackSpeed = pitch
	if typeof(parent)=="Instance" then sound.Parent=parent else sound.Parent=workspace end
	sound:Play()
	Debris:AddItem(sound, 10)
end

-- RUNG MÀN HÌNH
local function cameraShake(duration, intensity)
	task.spawn(function()
		local cam = workspace.CurrentCamera
		local start = os.clock()
		while os.clock() - start < duration do
			local rx = (math.random() - 0.5) * intensity
			local ry = (math.random() - 0.5) * intensity
			local rz = (math.random() - 0.5) * intensity
			cam.CFrame = cam.CFrame * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
			task.wait()
		end
	end)
end

-- HỆ THỐNG HẠT
local function createParticle(parent, pType)
	local emitter = Instance.new("ParticleEmitter")
	emitter.LightEmission = 0.8
	emitter.Parent = parent
	
	if pType == "Aura" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 0, 50), Color3.fromRGB(30, 0, 0))
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0.5)})
		emitter.Lifetime = NumberRange.new(0.6, 1.2)
		emitter.Rate = 100
		emitter.Speed = NumberRange.new(1, 4)
		emitter.SpreadAngle = Vector2.new(45, 45)
	elseif pType == "Lightning" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 0, 255))
		emitter.Size = NumberSequence.new(0.6, 1.2)
		emitter.Lifetime = NumberRange.new(0.1, 0.3)
		emitter.Rate = 80
		emitter.Speed = NumberRange.new(5, 15)
		emitter.SpreadAngle = Vector2.new(360, 360)
	elseif pType == "Wind" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200), Color3.fromRGB(50, 50, 50))
		emitter.Size = NumberSequence.new(2, 5)
		emitter.Transparency = NumberSequence.new(0.6, 1)
		emitter.Lifetime = NumberRange.new(0.4, 0.7)
		emitter.Rate = 70
		emitter.Speed = NumberRange.new(8, 16)
	elseif pType == "Smoke" then
		emitter.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80))
		emitter.Size = NumberSequence.new(1.5, 4)
		emitter.Transparency = NumberSequence.new(0.4, 1)
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Rate = 100
		emitter.Speed = NumberRange.new(3, 7)
	end
	return emitter
end

local function emitAfterimages(char, duration)
	local endTime = os.clock() + duration
	task.spawn(function()
		while os.clock() < endTime and char and char:FindFirstChild("HumanoidRootPart") do
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					local shadow = Instance.new("Part")
					shadow.Size = part.Size
					shadow.CFrame = part.CFrame
					shadow.Anchored = true; shadow.CanCollide = false
					shadow.Material = Enum.Material.Neon
					shadow.Color = Color3.fromRGB(130, 0, 255)
					shadow.Transparency = 0.4
					shadow.Parent = workspace
					TweenService:Create(shadow, TweenInfo.new(0.3), {Transparency = 1}):Play()
					Debris:AddItem(shadow, 0.3)
				end
			end
			task.wait(0.04)
		end
	end)
end

local function toggleESP(state)
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			if state then
				if not p.Character:FindFirstChild("AwakenHighlight") then
					local h = Instance.new("Highlight")
					h.Name = "AwakenHighlight"
					h.FillColor = Color3.fromRGB(255, 215, 0)
					h.OutlineColor = Color3.fromRGB(255, 255, 255)
					h.Parent = p.Character

					local bbg = Instance.new("BillboardGui")
					bbg.Name = "AwakenName"
					bbg.Size = UDim2.new(0, 150, 0, 30)
					bbg.StudsOffset = Vector3.new(0, 3.5, 0)
					bbg.AlwaysOnTop = true
					
					local txt = Instance.new("TextLabel")
					txt.Text = p.Name
					txt.Size = UDim2.new(1, 0, 1, 0)
					txt.BackgroundTransparency = 1
					txt.TextColor3 = Color3.fromRGB(255, 215, 0)
					txt.TextStrokeTransparency = 0.3
					txt.Font = Enum.Font.GothamBold
					txt.TextScaled = false
					txt.TextSize = 14
					txt.Parent = bbg
					bbg.Parent = p.Character
				end
			else
				if p.Character:FindFirstChild("AwakenHighlight") then p.Character.AwakenHighlight:Destroy() end
				if p.Character:FindFirstChild("AwakenName") then p.Character.AwakenName:Destroy() end
			end
		end
	end
end

local function startVisualCooldown(button, duration, defaultText, defaultColor, callback)
	task.spawn(function()
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		for i = duration, 1, -1 do
			button.Text = "CD: " .. i .. "S"
			task.wait(1)
		end
		button.Text = defaultText
		button.BackgroundColor3 = defaultColor
		if callback then callback() end
	end)
end

local function createTrack(animator, animId, priority)
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	local track = animator:LoadAnimation(anim)
	track.Looped = (priority ~= Enum.AnimationPriority.Action4)
	track.Priority = priority
	return track
end

local function stopTrack(track)
	if track and track.IsPlaying then track:Stop(0.15) end
end

local function stopAllTracks()
	stopTrack(idleTrack); stopTrack(walkTrack); stopTrack(runTrack)
	stopTrack(emoteTrack); stopTrack(angryTrack); stopTrack(dashTrack)
	stopTrack(awakenTrack); stopTrack(awakenMoveTrack)
end

local function baseSpeed()
	return runEnabled and RUN_SPEED or WALK_SPEED
end

local function updateAnimation()
	if not started or not currentHumanoid or currentHumanoid.Health <= 0 or angryActive or dashActive then
		if not started or (currentHumanoid and currentHumanoid.Health <= 0) then stopAllTracks() end
		return
	end

	local moving = currentHumanoid.MoveDirection.Magnitude > 0.05

	if buffActive then
		if moving then
			stopTrack(idleTrack)
			if awakenMoveTrack and not awakenMoveTrack.IsPlaying then awakenMoveTrack:Play(0.15) end
		else
			stopTrack(awakenMoveTrack)
			if idleTrack and not idleTrack.IsPlaying then idleTrack:Play(0.15) end
		end
		return
	end

	if awakeningActive and not buffActive then return end 

	if emoteEnabled then
		if moving then
			emoteEnabled = false
			emoteButton.Text = "EMOTE: OFF"; emoteButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
			stopTrack(emoteTrack)
		else
			stopTrack(idleTrack); stopTrack(walkTrack); stopTrack(runTrack)
			if emoteTrack and not emoteTrack.IsPlaying then emoteTrack:Play(0.15) end
			currentHumanoid.WalkSpeed = WALK_SPEED
			return
		end
	end

	if runEnabled then
		currentHumanoid.WalkSpeed = RUN_SPEED
		if moving then
			stopTrack(idleTrack); stopTrack(walkTrack); stopTrack(emoteTrack)
			if runTrack and not runTrack.IsPlaying then runTrack:Play(0.15) end
		else
			stopTrack(walkTrack); stopTrack(runTrack); stopTrack(emoteTrack)
			if idleTrack and not idleTrack.IsPlaying then idleTrack:Play(0.15) end
		end
	else
		currentHumanoid.WalkSpeed = WALK_SPEED
		if moving then
			stopTrack(idleTrack); stopTrack(runTrack); stopTrack(emoteTrack)
			if walkTrack and not walkTrack.IsPlaying then walkTrack:Play(0.15) end
		else
			stopTrack(walkTrack); stopTrack(runTrack); stopTrack(emoteTrack)
			if idleTrack and not idleTrack.IsPlaying then idleTrack:Play(0.15) end
		end
	end
end

-- CHIÊU TẤN CÔNG SMITE (Đã Fix Lỗi Chỉ Đánh Được 1 Lần)
local function activateSmite()
	-- Chỉ cho phép dùng Smite khi đang có Buff Awakening (buffActive = true)
	if not started or smiteCooldownActive or not buffActive or not currentHumanoid or currentHumanoid.Health <= 0 then return end
	smiteCooldownActive = true

	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local target = nil
	local dist = 60
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
			if d < dist then
				dist = d
				target = p.Character.HumanoidRootPart
			end
		end
	end

	-- Đẩy vị trí nổ xa ra 30 studs để bạn không bị dính sát thương của chính mình
	local hitPos = target and target.Position or (hrp.CFrame.LookVector * 30 + hrp.Position)
	local p1 = hitPos + Vector3.new(0, 150, 0)
	
	-- 1. TẠO TIA SÉT ZIGZAG CHÂN THỰC
	local segments = 8
	local lastPos = p1
	local boltGroup = Instance.new("Folder")
	boltGroup.Name = "SmiteLightning"
	boltGroup.Parent = workspace
	Debris:AddItem(boltGroup, 3.5)

	for i = 1, segments do
		local nextPos = (i == segments) and hitPos or p1:Lerp(hitPos, i/segments) + Vector3.new(math.random(-10,10), math.random(-5,5), math.random(-10,10))
		local distance = (nextPos - lastPos).Magnitude
		
		local boltPart = Instance.new("Part")
		boltPart.Anchored = true; boltPart.CanCollide = false
		boltPart.Material = Enum.Material.Neon
		boltPart.Color = Color3.fromRGB(0, 255, 255)
		boltPart.Size = Vector3.new(2.5, distance, 2.5)
		boltPart.CFrame = CFrame.lookAt(lastPos, nextPos) * CFrame.Angles(math.pi/2, 0, 0) * CFrame.new(0, -distance/2, 0)
		boltPart.Parent = boltGroup
		
		TweenService:Create(boltPart, TweenInfo.new(3), {Transparency = 1, Size = Vector3.new(0.5, distance, 0.5)}):Play()
		lastPos = nextPos
	end

	-- 2. TẠO VỤ NỔ (EXPLOSION) CÓ SÁT THƯƠNG
	local explosion = Instance.new("Explosion")
	explosion.Position = hitPos
	explosion.BlastRadius = 15 
	explosion.BlastPressure = 15000 -- Đã giảm xuống từ 500k để tránh văng bạn ra khỏi map gây chết nhân vật
	explosion.DestroyJointRadiusPercent = 0 
	explosion.Parent = workspace

	-- 3. ÂM THANH & RUNG MÀN HÌNH
	playSound("178452221", 3, 1, hrp) 
	playSound("142070127", 2.5, 1, hrp) 
	cameraShake(0.8, 0.6)
	
	-- 4. SÓNG XUNG KÍCH BỀ MẶT (SHOCKWAVE)
	local wave = Instance.new("Part")
	wave.Shape = Enum.PartType.Ball
	wave.Size = Vector3.new(2,2,2)
	wave.Color = Color3.fromRGB(0, 255, 255)
	wave.Material = Enum.Material.Neon
	wave.Anchored = true; wave.CanCollide = false
	wave.Position = hitPos
	wave.Parent = workspace
	TweenService:Create(wave, TweenInfo.new(0.6), {Size = Vector3.new(60,60,60), Transparency = 1}):Play()
	Debris:AddItem(wave, 0.6)

	-- Cooldown 2s
	startVisualCooldown(smiteButton, SMITE_COOLDOWN, "SMITE", Color3.fromRGB(0, 200, 255), function()
		smiteCooldownActive = false
	end)
end

local function activateAngryAngel()
	if not started or angryActive or angryCooldownActive or dashActive or awakeningActive then return end
	if not currentHumanoid or currentHumanoid.Health <= 0 then return end
	local char = player.Character; local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	angryActive = true
	runEnabled = false; if runButton then runButton.Text = "RUN: OFF"; runButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) end
	stopAllTracks()

	local auraFx = createParticle(hrp, "Aura")
	local lightningFx = createParticle(hrp, "Lightning")
	playSound("4522312676", 1, 1.2, hrp)
	cameraShake(4, 0.05)

	if angryTrack then angryTrack:Play(0.05); angryTrack:AdjustSpeed(ANGRY_ANIM_PLAYBACK_SPEED) end
	currentHumanoid.WalkSpeed = ANGRY_SPEED

	task.delay(ANGRY_DURATION, function()
		auraFx:Destroy(); lightningFx:Destroy()
		angryActive = false
		if currentHumanoid and currentHumanoid.Health > 0 then currentHumanoid.WalkSpeed = baseSpeed() end
		stopTrack(angryTrack); updateAnimation()
		angryCooldownActive = true
		startVisualCooldown(angryButton, ANGRY_COOLDOWN, "ANGRY ANGEL", Color3.fromRGB(255, 0, 0), function() angryCooldownActive = false end)
	end)
end

local function activateFallenDash()
	if not started or dashActive or dashCooldownActive or angryActive or awakeningActive then return end
	if not currentHumanoid or currentHumanoid.Health <= 0 then return end
	local char = player.Character; local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	dashActive = true
	stopAllTracks()
	emitAfterimages(char, DASH_DURATION)
	
	playSound("2319358253", 2, 1, hrp)
	local dashLight = createParticle(hrp, "Lightning")
	dashLight.EmissionDirection = Enum.NormalId.Back

	if dashTrack then dashTrack:Play(0.05) end
	currentHumanoid.WalkSpeed = DASH_SPEED

	task.delay(DASH_DURATION, function()
		dashLight:Destroy()
		dashActive = false
		if currentHumanoid and currentHumanoid.Health > 0 then currentHumanoid.WalkSpeed = baseSpeed() end
		stopTrack(dashTrack); updateAnimation()
		dashCooldownActive = true
		startVisualCooldown(dashButton, DASH_COOLDOWN, "FALLEN DASH", Color3.fromRGB(130, 0, 255), function() dashCooldownActive = false end)
	end)
end

-- CHIÊU AWAKENING 
local function activateAwakening()
	if not started or awakeningActive or awakeningCooldownActive or angryActive or dashActive then return end
	if not currentHumanoid or currentHumanoid.Health <= 0 then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	awakeningActive = true
	buffActive = false

	runEnabled = false; if runButton then runButton.Text = "RUN: OFF"; runButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) end
	stopAllTracks()

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(0, 50000, 0)
	bv.Velocity = Vector3.new(0, 4, 0) 
	bv.Parent = hrp

	if awakenTrack then awakenTrack:Play() end

	local auraFx = createParticle(hrp, "Aura"); auraFx.Size = NumberSequence.new(8, 1); auraFx.Rate = 500
	local lightFx = createParticle(hrp, "Lightning"); lightFx.Size = NumberSequence.new(3, 5); lightFx.Rate = 300

	local circle = Instance.new("Part")
	circle.Size = Vector3.new(20, 0.2, 20)
	circle.Anchored = true; circle.CanCollide = false; circle.Transparency = 1
	circle.Position = hrp.Position - Vector3.new(0, 5, 0)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://13110996884" 
	decal.Face = Enum.NormalId.Top
	decal.Color3 = Color3.fromRGB(255, 215, 0)
	decal.Parent = circle
	circle.Parent = workspace
	
	task.spawn(function()
		while not buffActive and circle.Parent do
			circle.CFrame = circle.CFrame * CFrame.Angles(0, math.rad(5), 0)
			task.wait()
		end
		circle:Destroy()
	end)

	playSound("4522312676", 2, 0.8, hrp) 
	cameraShake(5, 0.1)

	task.wait(5)

	if not currentHumanoid or currentHumanoid.Health <= 0 then
		awakeningActive = false; buffActive = false
		if bv then bv:Destroy() end
		return
	end

	bv:Destroy()
	if awakenTrack then awakenTrack:Stop() end
	auraFx:Destroy(); lightFx:Destroy()

	local rayResult = workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), RaycastParams.new())
	local groundPos = rayResult and rayResult.Position or (hrp.Position - Vector3.new(0, 3, 0))

	playSound("165969964", 3, 0.7, hrp) 
	cameraShake(1.5, 0.6)

	for i = 1, 50 do
		local rock = Instance.new("Part")
		rock.Size = Vector3.new(math.random(20, 40)/10, math.random(20, 35)/10, math.random(20, 40)/10)
		rock.Position = groundPos + Vector3.new(math.random(-25, 25)/10, 0, math.random(-25, 25)/10)
		rock.Velocity = Vector3.new(math.random(-80, 80), math.random(60, 120), math.random(-80, 80))
		rock.Material = Enum.Material.Rock
		rock.Color = rayResult and rayResult.Instance.Color or Color3.fromRGB(70, 65, 60)
		rock.CanCollide = false
		rock.Parent = workspace
		TweenService:Create(rock, TweenInfo.new(3), {Transparency = 1}):Play()
		Debris:AddItem(rock, 3)
	end

	buffActive = true
	currentHumanoid.WalkSpeed = AWAKEN_SPEED
	toggleESP(true)
	flyButton.Visible = true 
	smiteButton.Visible = true -- Đã sửa: Nút Smite chỉ hiện khi Awakening kích hoạt
	crackImage.Visible = true 

	updateAnimation() 

	if not jumpConn then
		jumpConn = UserInputService.JumpRequest:Connect(function()
			if buffActive and currentHumanoid and currentHumanoid.Health > 0 then
				currentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end

	countdownLabel.Visible = true
	task.spawn(function()
		for t = AWAKEN_DURATION, 1, -1 do
			if not buffActive then break end
			countdownLabel.Text = "AWAKENING: " .. t .. "S"
			task.wait(1)
		end
	end)

	task.delay(AWAKEN_DURATION, function()
		buffActive = false
		awakeningActive = false
		flying = false
		flyButton.Visible = false; flyButton.Text = "FLY: OFF"; flyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		smiteButton.Visible = false -- Đã sửa: Ẩn nút Smite khi hết Awakening
		
		crackImage.Visible = false
		countdownLabel.Visible = false
		toggleESP(false)
		if jumpConn then jumpConn:Disconnect(); jumpConn = nil end

		if currentHumanoid and currentHumanoid.Health > 0 then
			currentHumanoid.WalkSpeed = baseSpeed()
		end
		updateAnimation()

		awakeningCooldownActive = true
		startVisualCooldown(awakenButton, AWAKEN_COOLDOWN, "AWAKENING", Color3.fromRGB(255, 215, 0), function()
			awakeningCooldownActive = false
		end)
	end)
end

local function toggleFlight()
	if not buffActive then return end
	flying = not flying
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if flying and hrp then
		flyButton.Text = "FLY: ON"
		flyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		flyButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		
		local flyBv = Instance.new("BodyVelocity")
		flyBv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyBv.Parent = hrp
		
		task.spawn(function()
			while flying and buffActive and currentHumanoid and currentHumanoid.Health > 0 do
				local cam = workspace.CurrentCamera
				local moveDir = currentHumanoid.MoveDirection 
				
				if moveDir.Magnitude > 0 then
					local camXZ = (cam.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
					local dotForward = moveDir:Dot(camXZ)
					local flyY = cam.CFrame.LookVector.Y * 100 * dotForward
					
					flyBv.Velocity = Vector3.new(moveDir.X * 100, flyY, moveDir.Z * 100)
				else
					flyBv.Velocity = Vector3.new(0, 0, 0)
				end
				task.wait()
			end
			if flyBv then flyBv:Destroy() end
		end)
	else
		flying = false
		flyButton.Text = "FLY: OFF"
		flyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function disconnectCharacterConnections()
	if moveConn then moveConn:Disconnect(); moveConn = nil end
	if diedConn then diedConn:Disconnect(); diedConn = nil end
	if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
end

local function setupCharacter(character)
	disconnectCharacterConnections()

	currentHumanoid = character:WaitForChild("Humanoid")
	currentAnimator = currentHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", currentHumanoid)

	idleTrack  = createTrack(currentAnimator, IDLE_ANIM_ID, Enum.AnimationPriority.Idle)
	walkTrack  = createTrack(currentAnimator, WALK_ANIM_ID, Enum.AnimationPriority.Movement)
	runTrack   = createTrack(currentAnimator, RUN_ANIM_ID, Enum.AnimationPriority.Action)
	emoteTrack = createTrack(currentAnimator, EMOTE_ANIM_ID, Enum.AnimationPriority.Action4)
	angryTrack = createTrack(currentAnimator, ANGRY_ANIM_ID, Enum.AnimationPriority.Action3)
	dashTrack  = createTrack(currentAnimator, DASH_ANIM_ID, Enum.AnimationPriority.Action4)
	awakenTrack = createTrack(currentAnimator, AWAKEN_ANIM_ID, Enum.AnimationPriority.Action4)
	awakenMoveTrack = createTrack(currentAnimator, AWAKEN_MOVE_ANIM, Enum.AnimationPriority.Action4)

	angryActive, dashActive, awakeningActive, buffActive, flying = false, false, false, false, false
	currentHumanoid.WalkSpeed = WALK_SPEED

	moveConn = currentHumanoid:GetPropertyChangedSignal("MoveDirection"):Connect(updateAnimation)
	diedConn = currentHumanoid.Died:Connect(function()
		stopAllTracks()
		awakeningActive, buffActive, flying = false, false, false
		toggleESP(false)
		if flyButton then flyButton.Visible = false end
		if dragButton then dragButton.Visible=false end
		if runButton then runButton.Visible=false end
		if emoteButton then emoteButton.Visible=false end
		if angryButton then angryButton.Visible=false end
		if dashButton then dashButton.Visible=false end
		if awakenButton then awakenButton.Visible=false end
		if smiteButton then smiteButton.Visible = false end -- Đã sửa: Ẩn nút Smite nếu chết
		if crackImage then crackImage.Visible = false end
		if countdownLabel then countdownLabel.Visible = false end
	end)

	if started then updateAnimation() else stopAllTracks() end
end

local function createUI()
	gui = Instance.new("ScreenGui")
	gui.Name = "TheFallenAngelUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	crackImage = Instance.new("ImageLabel")
	crackImage.Size = UDim2.new(1, 0, 1, 0)
	crackImage.BackgroundTransparency = 1
	crackImage.Image = "rbxassetid://13788326694"
	crackImage.ImageTransparency = 0.3
	crackImage.Visible = false
	crackImage.ZIndex = -1
	crackImage.Parent = gui

	countdownLabel = Instance.new("TextLabel")
	countdownLabel.Size = UDim2.new(0, 300, 0, 50)
	countdownLabel.Position = UDim2.new(0.5, -150, 0, 20)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	countdownLabel.TextStrokeTransparency = 0
	countdownLabel.Font = Enum.Font.GothamBlack
	countdownLabel.TextScaled = true
	countdownLabel.Visible = false
	countdownLabel.Parent = gui

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 320, 0, 120); mainFrame.Position = UDim2.new(0.5, -160, 0.15, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); mainFrame.BackgroundTransparency = 0.15; mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", mainFrame); stroke.Thickness = 2
	task.spawn(function()
		local hue = 0
		while stroke.Parent do hue = (hue + 0.01) % 1; stroke.Color = Color3.fromHSV(hue, 1, 1); task.wait(0.03) end
	end)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 45); titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1; titleLabel.Text = "The Fallen Angel by KageFloppey"
	titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextScaled = true
	titleLabel.Parent = mainFrame
	task.spawn(function()
		local h=0
		while titleLabel.Parent do
			h=(h+0.01)%1
			titleLabel.TextColor3=Color3.fromHSV(h,1,1)
			titleLabel.TextTransparency=0.2+0.2*math.sin(os.clock()*6)
			task.wait(0.03)
		end
	end)

	startButton = Instance.new("TextButton")
	startButton.Size = UDim2.new(0, 140, 0, 42); startButton.Position = UDim2.new(0.5, -70, 1, -52)
	startButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30); startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.Text = "START"; startButton.Font = Enum.Font.GothamBold; startButton.TextSize = 22
	startButton.Parent = mainFrame
	Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 10)
	local startStroke = Instance.new("UIStroke", startButton); startStroke.Color = Color3.fromRGB(255, 255, 255); startStroke.Thickness = 1.5

	local function createSideButton(name, yPos, color, text)
		local btn = Instance.new("TextButton")
		btn.Name = name; btn.Size = UDim2.new(0, 110, 0, 36)
		btn.Position = UDim2.new(1, -120, 0, yPos)
		btn.BackgroundColor3 = color; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
		btn.Visible = false; btn.Parent = gui
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		return btn
	end

	runButton = createSideButton("RunButton", 20, Color3.fromRGB(0, 170, 0), "RUN: OFF")
	emoteButton = createSideButton("EmoteButton", 62, Color3.fromRGB(0, 120, 255), "EMOTE: OFF")
	angryButton = createSideButton("AngryButton", 104, Color3.fromRGB(255, 0, 0), "ANGRY ANGEL")
	dashButton = createSideButton("DashButton", 146, Color3.fromRGB(130, 0, 255), "FALLEN DASH")
	awakenButton = createSideButton("AwakenButton", 188, Color3.fromRGB(255, 215, 0), "AWAKENING"); awakenButton.TextColor3 = Color3.fromRGB(0,0,0)
	smiteButton = createSideButton("SmiteButton", 230, Color3.fromRGB(0, 200, 255), "SMITE")
	flyButton = createSideButton("FlyButton", 272, Color3.fromRGB(50, 50, 50), "FLY: OFF")

	local dragToggle = createSideButton("DragButton", 314, Color3.fromRGB(255,140,0), "DRAG: OFF")
	local dragEnabled = false
	local UIS = game:GetService("UserInputService")
	local function makeDraggable(btn)
		local dragging=false; local dragStart; local startPos
		btn.InputBegan:Connect(function(input)
			if not dragEnabled then return end
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
				dragging=true; dragStart=input.Position; startPos=btn.Position
				input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
			end
		end)
		btn.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
				local d=input.Position-dragStart
				btn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
			end
		end)
	end
	for _,b in ipairs({runButton,emoteButton,angryButton,dashButton,awakenButton,smiteButton,flyButton}) do makeDraggable(b) end
	dragToggle.Visible=true
	dragToggle.MouseButton1Click:Connect(function()
		dragEnabled=not dragEnabled
		dragToggle.Text=dragEnabled and "DRAG: ON" or "DRAG: OFF"
		dragToggle.BackgroundColor3=dragEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(255,140,0)
	end)


	startButton.MouseButton1Click:Connect(function()
		started = true
		mainFrame.Visible = false
		runButton.Visible = true; emoteButton.Visible = true; angryButton.Visible = true
		dashButton.Visible = true; awakenButton.Visible = true
		-- Đã sửa: Xóa lệnh bật smiteButton ở đây để nó không hiện từ đầu
		if currentHumanoid then currentHumanoid.WalkSpeed = WALK_SPEED end
		updateAnimation()
	end)

	runButton.MouseButton1Click:Connect(function()
		if not started or angryActive or dashActive or awakeningActive or runCooldownActive then return end
		runEnabled = not runEnabled
		runButton.Text = runEnabled and "RUN: ON" or "RUN: OFF"
		runButton.BackgroundColor3 = runEnabled and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 170, 0)
		updateAnimation()
		if not runEnabled then
			runCooldownActive = true
			startVisualCooldown(runButton, RUN_COOLDOWN, "RUN: OFF", Color3.fromRGB(0, 170, 0), function() runCooldownActive = false end)
		end
	end)

	emoteButton.MouseButton1Click:Connect(function()
		if not started or angryActive or dashActive or awakeningActive then return end
		if currentHumanoid and currentHumanoid.MoveDirection.Magnitude > 0.05 then return end
		emoteEnabled = not emoteEnabled
		emoteButton.Text = emoteEnabled and "EMOTE: ON" or "EMOTE: OFF"
		emoteButton.BackgroundColor3 = emoteEnabled and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(0, 120, 255)
		updateAnimation()
	end)

	angryButton.MouseButton1Click:Connect(activateAngryAngel)
	dashButton.MouseButton1Click:Connect(activateFallenDash)
	awakenButton.MouseButton1Click:Connect(activateAwakening)
	smiteButton.MouseButton1Click:Connect(activateSmite)
	flyButton.MouseButton1Click:Connect(toggleFlight)
end

createUI()
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

-- NOTE: Include dragButton in draggable buttons list.
