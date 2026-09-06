-- ============================================================================
-- TITLE   : 👑 NEXUS-SDA v2.0 (ENTERPRISE LAYERED EDITION)
-- GAME    : Steal an Egg
-- PURPOSE : High-Performance, Anti-Rubberband & Modular Mobile Auto-Farm Engine
-- ============================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

task.defer(function()
    -- ========================================================================
    -- [LAYER 7]: ENGINE & DATA LAYER (Roblox API & Environment References)
    -- ========================================================================
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local PathfindingService = game:GetService("PathfindingService")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer

    if setfpscap then pcall(setfpscap, 60) end

    -- ========================================================================
    -- [LAYER 6]: EXECUTOR COMPATIBILITY LAYER (API Normalization & Fallbacks)
    -- ========================================================================
    local ExecutorEnv = {
        FirePrompt = function(prompt)
            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                if prompt.InputHoldBegin then prompt:InputHoldBegin() end
                task.wait(0.1)
                if prompt.InputHoldEnd then prompt:InputHoldEnd() end
            end
        end,
        
        GetParentGui = function()
            local success, parent = pcall(function() return gethui and gethui() or CoreGui end)
            return (success and parent) or LocalPlayer:WaitForChild("PlayerGui")
        end
    }

    -- ========================================================================
    -- [LAYER 5]: NETWORKING & EVENT LAYER (Target Scanner & Network Caching)
    -- ========================================================================
    local TargetNetwork = {
        ActiveTargets = {},
        Blacklist = {}
    }

    function TargetNetwork:IsBlacklisted(part)
        if not part then return true end
        local id = part:GetDebugId()
        if self.Blacklist[id] and (tick() - self.Blacklist[id] < 8) then
            return true
        end
        return false
    end

    function TargetNetwork:ScanWorkspace()
        table.clear(self.ActiveTargets)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled and obj.Parent then
                local pName = obj.Parent.Name:lower()
                if pName:find("egg") or pName:find("item") or pName:find("pet") then
                    table.insert(self.ActiveTargets, obj)
                end
            end
        end
    end

    -- ========================================================================
    -- [LAYER 4]: CORE GUARD & MASKING LAYER (Error Handling & Human Simulation)
    -- ========================================================================
    local CoreGuard = {}
    
    function CoreGuard.SafeExecute(func, ...)
        local success, result = xpcall(func, function(err)
            return string.format("[NexusFault]: %s", tostring(err))
        end, ...)
        return success, result
    end

    local BehavioralMasking = {
        GaussianNoise = function(minMs, maxMs)
            local u1, u2 = math.random(), math.random()
            local z = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
            local mean, stdDev = (minMs + maxMs) / 2, (maxMs - minMs) / 6
            return math.clamp(math.floor(mean + z * stdDev), minMs, maxMs)
        end
    }

    -- ========================================================================
    -- [LAYER 3]: SERVICE & MODULE LAYER (Movement & Steal Engine Logic)
    -- ========================================================================
    local StealService = {}

    function StealService.GetCharacter()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then return char, root, hum end
        end
        return nil, nil, nil
    end

    function StealService.ProcessTarget(EngineState)
        local char, root, hum = StealService.GetCharacter()
        if not root or not hum then return end

        if #TargetNetwork.ActiveTargets == 0 then TargetNetwork:ScanWorkspace() end

        local selectedPrompt, targetPart = nil, nil
        local minDist = 350

        for i = #TargetNetwork.ActiveTargets, 1, -1 do
            local prompt = TargetNetwork.ActiveTargets[i]
            if prompt and prompt.Parent and prompt.Enabled then
                local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
                if part and not TargetNetwork:IsBlacklisted(part) then
                    local dist = (root.Position - part.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        selectedPrompt = prompt
                        targetPart = part
                    end
                end
            else
                table.remove(TargetNetwork.ActiveTargets, i)
            end
        end

        if selectedPrompt and targetPart then
            EngineState.CurrentTask = "Approaching"
            hum.WalkSpeed = 50 -- Kecepatan ideal Anti-Rubberband
            local targetPos = targetPart.Position + Vector3.new(0, 2, 0)
            local currentDist = (root.Position - targetPos).Magnitude

            -- Pathfinding jika jarak jauh
            if currentDist > 12 then
                local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5 })
                if pcall(function() path:ComputeAsync(root.Position, targetPos) end) and path.Status == Enum.PathStatus.Success then
                    for _, wp in ipairs(path:GetWaypoints()) do
                        if not EngineState.Running or not selectedPrompt.Parent then break end
                        hum:MoveTo(wp.Position)
                        local reached = false
                        local conn = hum.MoveToFinished:Connect(function() reached = true end)
                        local startT = tick()
                        while not reached and tick() - startT < 0.8 do task.wait(0.03) end
                        if conn then conn:Disconnect() end
                    end
                end
            end

            -- Pergerakan Fisika Murni
            if targetPart.Parent and selectedPrompt.Enabled then
                hum:MoveTo(targetPos)
                local reachedClose = false
                local conn = hum.MoveToFinished:Connect(function() reachedClose = true end)
                local startT = tick()
                while not reachedClose and (root.Position - targetPos).Magnitude > 4 and tick() - startT < 1.5 do 
                    task.wait(0.05) 
                end
                if conn then conn:Disconnect() end

                -- Masking Jeda Manusia
                EngineState.CurrentTask = "Human Delay"
                task.wait(BehavioralMasking.GaussianNoise(100, 200) / 1000)

                -- Eksekusi Interaksi
                EngineState.CurrentTask = "Stealing"
                ExecutorEnv.FirePrompt(selectedPrompt)
                EngineState.StolenCount = EngineState.StolenCount + 1
                task.wait(0.2)
            else
                TargetNetwork.Blacklist[targetPart:GetDebugId()] = tick()
            end
        else
            EngineState.CurrentTask = "Standby"
        end
    end

    -- ========================================================================
    -- [LAYER 2]: STATE CONTROLLER LAYER (State Management & Loop Drivers)
    -- ========================================================================
    local EngineState = {
        Running = false,
        GlobalMutex = false,
        StolenCount = 0,
        CurrentTask = "Standby"
    }

    local StateController = {}

    function StateController.Init()
        TargetNetwork:ScanWorkspace()

        -- Worker Task
        task.spawn(function()
            while true do
                if EngineState.Running and not EngineState.GlobalMutex then
                    EngineState.GlobalMutex = true
                    CoreGuard.SafeExecute(function()
                        StealService.ProcessTarget(EngineState)
                    end)
                    EngineState.GlobalMutex = false
                end
                task.wait(0.2)
            end
        end)

        -- Garbage Collector & Memory Cleaner
        task.spawn(function()
            while true do
                task.wait(30)
                TargetNetwork:ScanWorkspace()
                if collectgarbage then collectgarbage("collect") end
            end
        end)
    end

    -- ========================================================================
    -- [LAYER 1]: UI / INTERFACE LAYER (Native User GUI Engine)
    -- ========================================================================
    local UI = {}

    function UI.Build()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "NexusSDAEnterprise"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = ExecutorEnv.GetParentGui()

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 220, 0, 130)
        Frame.Position = UDim2.new(0.05, 0, 0.2, 0)
        Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        Frame.BorderSizePixel = 0
        Frame.Active = true
        Frame.Draggable = true
        Frame.Parent = ScreenGui

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 30)
        Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        Title.Text = "👑 NEXUS-SDA v2.0 (LAYERED)"
        Title.TextColor3 = Color3.fromRGB(0, 255, 150)
        Title.TextSize = 12
        Title.Font = Enum.Font.SourceSansBold
        Title.Parent = Frame

        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0.9, 0, 0, 32)
        ToggleBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        ToggleBtn.Text = "Auto-Steal: OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleBtn.TextSize = 12
        ToggleBtn.Font = Enum.Font.SourceSansBold
        ToggleBtn.Parent = Frame

        local StatusLbl = Instance.new("TextLabel")
        StatusLbl.Size = UDim2.new(0.9, 0, 0, 40)
        StatusLbl.Position = UDim2.new(0.05, 0, 0.62, 0)
        StatusLbl.BackgroundTransparency = 1
        StatusLbl.Text = "Status: Standby | Stolen: 0"
        StatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        StatusLbl.TextSize = 11
        StatusLbl.Font = Enum.Font.SourceSans
        StatusLbl.Parent = Frame

        -- Interaksi UI ke Layer 2 State Controller
        ToggleBtn.MouseButton1Click:Connect(function()
            EngineState.Running = not EngineState.Running
            if EngineState.Running then
                ToggleBtn.Text = "Auto-Steal: ON"
                ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            else
                ToggleBtn.Text = "Auto-Steal: OFF"
                ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                EngineState.CurrentTask = "Standby"
            end
        end)

        -- Realtime Status Loop
        task.spawn(function()
            while true do
                task.wait(0.4)
                StatusLbl.Text = string.format("Task: %s\nStolen Total: %d", EngineState.CurrentTask, EngineState.StolenCount)
            end
        end)
    end

    -- ========================================================================
    -- BOOTSTRAP INITIALIZATION
    -- ========================================================================
    StateController.Init()
    UI.Build()

    print("[NEXUS-SDA v2.0]: Enterprise Layered Architecture Loaded Successfully.")
end)
