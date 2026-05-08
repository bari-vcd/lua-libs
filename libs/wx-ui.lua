-- WX-UI Library

-- new version (0.3) written by vcd_ | year 2026

-- old version: https://raw.githubusercontent.com/hsddhdidj-ops/h/refs/heads/main/lib

------------ Variables ------------
cloneref = cloneref or function(object) return object; end;

gethui = gethui or function() return cloneref(game:GetService('CoreGui')) end;

local UserInputService = cloneref(game:GetService("UserInputService"));
local TweenService     = cloneref(game:GetService("TweenService"));

local WX_UI            = {...};

local UI_BIBDS_ARRAY   = {...} :: {any}

local sex_frame_grad_animation;

if not game:IsLoaded() then
	local load_message = Instance.new('Message', gethui());
	load_message.Text = 'WX-UI Library is waiting for the game to load'; game.Loaded:Wait(); load_message:Destroy();
end;

-- executor supports functions
local get_cc                 = getconnections or get_signal_cons;
local queueteleport          = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) 
local httprequest            = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request 
local executor_name: string? = getexecutorname() or identifyexecutor() :: string

-- configuration (dark theme)
local Theme = {
	-- Backgrounds
	Background = Color3.fromRGB(10, 10, 12),
	BackgroundLight = Color3.fromRGB(17, 17, 24),
	BackgroundPanel = Color3.fromRGB(13, 13, 17),

	-- Accent Colors (Purple/Pink gradient feel)
	Accent = Color3.fromRGB(120, 75, 200),
	AccentLight = Color3.fromRGB(150, 100, 220),
	AccentDark = Color3.fromRGB(80, 50, 150),

	-- Interactive
	ButtonPrimary = Color3.fromRGB(35, 20, 70),
	ButtonHover = Color3.fromRGB(50, 30, 90),
	ButtonActive = Color3.fromRGB(70, 40, 120),

	-- Text
	TextPrimary = Color3.fromRGB(220, 220, 240),
	TextSecondary = Color3.fromRGB(170, 165, 220),
	TextMuted = Color3.fromRGB(120, 120, 158),

	-- Strokes
	Stroke = Color3.fromRGB(40, 40, 56),
	StrokeLight = Color3.fromRGB(55, 50, 85),
	StrokeAccent = Color3.fromRGB(100, 70, 180),

	-- Status
	Success = Color3.fromRGB(61, 255, 160),
	Error = Color3.fromRGB(255, 90, 90),
	Warning = Color3.fromRGB(255, 200, 100),
}

-- Helper functions
local function ApplyStroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke", parent)
	s.Color = color or Theme.Stroke
	s.Thickness = thickness or 1
	return s :: UIStroke
end

local function ApplyCorner(parent: Instance, radius: number?): UICorner
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 12)
	return c :: UICorner
end

------------ Create UI schemas ------------
function WX_UI:Wind(is_coreui: boolean, ...)
	local wx_ui_main          = Instance.new('GuiMain', is_coreui and gethui());
	wx_ui_main.Name           = 'WX-UI';
	wx_ui_main.IgnoreGuiInset, wx_ui_main.ResetOnSpawn = true, false;
	wx_ui_main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	self.wx_ui_main = wx_ui_main;

	local main_frame = Instance.new('Frame', wx_ui_main)
	main_frame.BackgroundTransparency = 1
	main_frame.Size = UDim2.new(1, 0, 1, 0)
	main_frame.Visible = true
	main_frame.Name = 'main-frame'
	self.main_frame = main_frame

	-- Toggle Button
	local ui_button = Instance.new('TextButton', main_frame);
	ui_button.Text  = 'WX'
	ui_button.Font  = Enum.Font.GothamBold
	ui_button.TextColor3 = Theme.TextPrimary
	ui_button.TextScaled = true
	ui_button.TextSize = 14
	ui_button.TextWrapped = true
	ui_button.BackgroundColor3 = Theme.BackgroundPanel
	ui_button.BackgroundTransparency = 0.15
	ui_button.Size = UDim2.new(0, 52, 0, 52)
	ui_button.Position = UDim2.new(0.20120573, 0, 0.256144881, 0)
	ui_button.Visible = true
	self.ui_button = ui_button

	ApplyCorner(ui_button, 26)
	ApplyStroke(ui_button, Theme.StrokeAccent, 1.5)

	-- Hover effect
	ui_button.MouseEnter:Connect(function()
		TweenService:Create(ui_button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ButtonHover}):Play()
	end)
	ui_button.MouseLeave:Connect(function()
		TweenService:Create(ui_button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.BackgroundPanel}):Play()
	end)

	-- Main Panel
	local sex_frame = Instance.new("Frame", main_frame)
	sex_frame.Name = 'sex'
	sex_frame.BackgroundColor3 = Theme.BackgroundPanel
	sex_frame.BackgroundTransparency = 0.05
	sex_frame.Size = UDim2.new(0, 380, 0, 420)
	sex_frame.Position = UDim2.new(0.35, 0, 0.18, 0)
	self.sex_frame = sex_frame

	ApplyCorner(sex_frame, 16)

	local stroke = ApplyStroke(sex_frame, Theme.Stroke, 1.5)

	-- Animated gradient border
	local s_grad = Instance.new('UIGradient', stroke)
	s_grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Theme.AccentLight),
		ColorSequenceKeypoint.new(0.5, Theme.Accent),
		ColorSequenceKeypoint.new(1, Theme.AccentDark)
	};
	s_grad.Rotation = 0;

	-- Gradient animation loop
	sex_frame_grad_animation = task.spawn(function(...)
		local dir, speed = 1, 0
		while s_grad.Parent do
			speed += 0.008 * dir;
			s_grad.Rotation += speed;

			if speed > 8 then dir = -1 end;
			if speed < 0.3 then dir = 1 end;

			task.wait(0.016);
		end;
	end);

	-- Header / Title Bar
	local titleBar = Instance.new("Frame", sex_frame)
	titleBar.Name = 'TitleBar'
	titleBar.BackgroundColor3 = Theme.Background
	titleBar.BackgroundTransparency = 0
	titleBar.Size = UDim2.new(1, 0, 0, 48)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BorderSizePixel = 0
	ApplyCorner(titleBar, 16)

	-- Fill bottom corners of title bar
	local titleFill = Instance.new("Frame", titleBar)
	titleFill.Name = 'TitleFill'
	titleFill.Size = UDim2.new(1, 0, 0, 20)
	titleFill.Position = UDim2.new(0, 0, 1, -20)
	titleFill.BackgroundColor3 = Theme.Background
	titleFill.BorderSizePixel = 0
	titleFill.ZIndex = titleBar.ZIndex - 1

	local status_dot = Instance.new("Frame", titleBar)
	status_dot.Name = 'StatusDot'
	status_dot.Size = UDim2.new(0, 10, 0, 10)
	status_dot.Position = UDim2.new(0, 16, 0.5, -5)
	status_dot.BackgroundColor3 = Theme.Success
	status_dot.BorderSizePixel = 0
	status_dot.ZIndex = 10
	ApplyCorner(status_dot, 999)

	task.spawn(function()
		while status_dot.Parent do
			TweenService:Create(status_dot, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				Size = UDim2.new(0, 12, 0, 12),
				Position = UDim2.new(0, 15, 0.5, -6)
			}):Play()
			task.wait(1)
			TweenService:Create(status_dot, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				Size = UDim2.new(0, 10, 0, 10),
				Position = UDim2.new(0, 16, 0.5, -5)
			}):Play()
			task.wait(1)
		end
	end)

	-- Title text
	local nyanlose = Instance.new("TextLabel", titleBar)
	nyanlose.Font = Enum.Font.GothamBold
	nyanlose.Text = 'WX-UI'
	nyanlose.Name = 'NYANLOSE'
	nyanlose.TextColor3 = Theme.TextPrimary
	nyanlose.TextScaled = false
	nyanlose.TextSize = 16
	nyanlose.TextWrapped = true
	nyanlose.BackgroundColor3 = Theme.Background
	nyanlose.BackgroundTransparency = 1
	nyanlose.BorderSizePixel = 0
	nyanlose.Size = UDim2.new(1, -80, 1, 0)
	nyanlose.Position = UDim2.new(0, 32, 0, 0)
	nyanlose.Visible = true
	nyanlose.ZIndex = 10

	-- Scroll container
	local sex_scroll = Instance.new("ScrollingFrame", sex_frame)
	sex_scroll.Name = 'ContentScroll'
	sex_scroll.ScrollBarImageColor3 = Theme.AccentDark
	sex_scroll.ScrollBarThickness = 4;
	sex_scroll.Active = true;
	sex_scroll.BackgroundColor3 = Theme.Background
	sex_scroll.BackgroundTransparency = 1
	sex_scroll.BorderSizePixel = 0
	sex_scroll.Position = UDim2.new(0, 0, 0, 52, 0)
	sex_scroll.Size = UDim2.new(1, -8, 1, -60)
	sex_scroll.Position = UDim2.new(0, 4, 0, 52)
	sex_scroll.Visible = true;
	self.sex_scroll = sex_scroll

	local scrollPadding = Instance.new('UIPadding', sex_scroll)
	scrollPadding.PaddingTop = UDim.new(0, 8)
	scrollPadding.PaddingBottom = UDim.new(0, 8)
	scrollPadding.PaddingLeft = UDim.new(0, 4)
	scrollPadding.PaddingRight = UDim.new(0, 4)

	local s1 = Instance.new('UIListLayout', sex_scroll)
	s1.Padding = UDim.new(0, 8)
	s1.HorizontalAlignment = Enum.HorizontalAlignment.Center
	s1.SortOrder = Enum.SortOrder.LayoutOrder

	-- KeyBinds Panel
	local key_binds_frame = Instance.new("Frame", main_frame)
	key_binds_frame.Name = 'KeyBindsFrame'
	key_binds_frame.BackgroundColor3 = Theme.BackgroundPanel
	key_binds_frame.BackgroundTransparency = 0.05
	key_binds_frame.Size = UDim2.new(0, 200, 0, 180)
	key_binds_frame.Position = UDim2.new(0.75, 0, 0.04, 0)
	key_binds_frame.Visible = false;
	self.key_binds_frame = key_binds_frame

	ApplyCorner(key_binds_frame, 12)
	ApplyStroke(key_binds_frame, Theme.Stroke, 1)

	-- Keybinds header
	local key_binds = Instance.new('TextLabel', key_binds_frame)
	key_binds.Name = 'Header'
	key_binds.Font  = Enum.Font.GothamBold
	key_binds.Text  = "Active"
	key_binds.TextColor3  = Theme.TextPrimary
	key_binds.TextScaled  = false
	key_binds.TextSize    = 14
	key_binds.TextWrapped = true
	key_binds.BackgroundColor3 = Theme.Background
	key_binds.BackgroundTransparency = 0
	key_binds.Size    = UDim2.new(1, 0, 0, 36)
	key_binds.Position = UDim2.new(0, 0, 0, 0)
	key_binds.Visible = true

	ApplyCorner(key_binds, 12)

	-- Fill for keybinds header
	local keyHeaderFill = Instance.new("Frame", key_binds)
	keyHeaderFill.Size = UDim2.new(1, 0, 0, 14)
	keyHeaderFill.Position = UDim2.new(0, 0, 1, -14)
	keyHeaderFill.BackgroundColor3 = Theme.Background
	keyHeaderFill.BorderSizePixel = 0
	keyHeaderFill.ZIndex = key_binds.ZIndex - 1

	local keyBindsScroll = Instance.new('ScrollingFrame', key_binds_frame);
	keyBindsScroll.Name = 'KeyBindsScroll'
	keyBindsScroll.ScrollBarImageColor3 = Theme.AccentDark
	keyBindsScroll.ScrollBarThickness   = 2
	keyBindsScroll.Active, keyBindsScroll.Visible = true, true;
	keyBindsScroll.BackgroundColor3 = Theme.Background
	keyBindsScroll.BackgroundTransparency = 1
	keyBindsScroll.BorderSizePixel = 0
	keyBindsScroll.Position        = UDim2.new(0, 4, 0, 40)
	keyBindsScroll.Size            = UDim2.new(1, -8, 1, -44)

	self.keyBindsScroll = keyBindsScroll

	local keyListLayout = Instance.new('UIListLayout', keyBindsScroll)
	keyListLayout.Padding = UDim.new(0, 6)
	keyListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	keyListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- UIDragDetector for dragging panels
	local UIDragDetector = Instance.new('UIDragDetector', sex_frame)
	UIDragDetector.Enabled = true

	local UIDragDetector2 = Instance.new('UIDragDetector', key_binds_frame)
	UIDragDetector2.Enabled = true

	-- Open/close toggle
	WX_UI:BindOnClickButton(ui_button, function()
		sex_frame.Visible = not sex_frame.Visible
	end);
end;

function WX_UI:DestroyButton(button_name: string)
	if button_name and self.sex_scroll:FindFirstChild(button_name) then
		self.sex_scroll:FindFirstChild(button_name):Destroy();
	end;
end;

-- UI Functions
function WX_UI:WX_CreateButton(
	opts: {
		text:           string?, 
		ButtonTextSize: number?, 
		ButtonColor3:   Color3?,
		buttonStrokeColor: Color3?, 
		FrameSize: UDim2?
	}
): TextButton

	local f = Instance.new('Frame', self.sex_scroll)
	f.Name  = `{opts.text}-{math.random(1, 999)}`
	f.Size  = opts.FrameSize or UDim2.new(1, -8, 0, 44)
	f.BackgroundTransparency = 1

	local b = Instance.new('TextButton', f)
	b.Name = 'Button'
	b.Text      = opts.text or "Button";
	b.Font      = Enum.Font.GothamBold
	b.TextColor3= Theme.TextPrimary
	b.TextScaled= false
	b.TextSize  = opts.ButtonTextSize or 14
	b.TextWrapped = true
	b.BackgroundColor3 = opts.ButtonColor3 or Theme.ButtonPrimary
	b.BackgroundTransparency = 0
	b.Size = UDim2.new(1, 0, 1, 0)
	b.BorderSizePixel = 0

	ApplyCorner(b, 10)
	ApplyStroke(b, opts.buttonStrokeColor or Theme.StrokeLight, 1)

	-- Hover effects
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = Theme.ButtonHover,
			TextColor3 = Theme.AccentLight
		}):Play()
	end)

	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {
			BackgroundColor3 = opts.ButtonColor3 or Theme.ButtonPrimary,
			TextColor3 = Theme.TextPrimary
		}):Play()
	end)

	b.ButtonDown:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.1), {
			BackgroundColor3 = Theme.ButtonActive
		}):Play()
	end)

	b.ButtonUp:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.1), {
			BackgroundColor3 = Theme.ButtonHover
		}):Play()
	end)

	return b;
end;

function WX_UI:WX_TextButtonAndBox(
	opts: {
		ButtonText:     string?, 
		ButtonTextSize: number?,
		ButtonColor3:   Color3?,
		buttonStrokeColor: Color3?,

		TextBoxText: string?,
		TextBoxTextSize: number?,
		BoxStrokeColor: Color3?,

		FocusLostCallback:   (...any?) -> (),
		FocusedCallback:     (...any?) -> (),
		ClickButtonCallback: (...any?) -> ()
	}
): (Frame, TextButton, TextBox)

	local f = Instance.new('Frame', self.sex_scroll)
	f.Name  = `{opts.ButtonText}-input-{math.random(1, 999)}`
	f.Size  = UDim2.new(1, -8, 0, 90)
	f.BackgroundTransparency = 1

	local layout = Instance.new('UIListLayout', f)
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Button
	local b = Instance.new('TextButton', f)
	b.Name = 'Button'
	b.Text = opts.ButtonText or "Button"
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Theme.TextPrimary
	b.TextScaled = false
	b.TextSize = opts.ButtonTextSize or 14
	b.BackgroundColor3 = opts.ButtonColor3 or Theme.ButtonPrimary
	b.BackgroundTransparency = 0
	b.Size = UDim2.new(1, 0, 0, 38)
	b.BorderSizePixel = 0

	ApplyCorner(b, 10)
	ApplyStroke(b, opts.buttonStrokeColor or Theme.StrokeLight, 1)

	-- Hover
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Theme.ButtonHover}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = opts.ButtonColor3 or Theme.ButtonPrimary}):Play()
	end)

	-- TextBox
	local t = Instance.new('TextBox', f)
	t.Name = 'TextBox'
	t.PlaceholderText = 'Enter value...'
	t.PlaceholderColor3 = Theme.TextMuted
	t.Text = opts.TextBoxText or '';
	t.Font = Enum.Font.Gotham
	t.TextColor3 = Theme.TextPrimary
	t.TextScaled = false
	t.TextSize = opts.TextBoxTextSize or 13
	t.BackgroundColor3 = Theme.BackgroundLight
	t.BackgroundTransparency = 0
	t.Size = UDim2.new(1, 0, 0, 38)
	t.BorderSizePixel = 0

	ApplyCorner(t, 10)
	ApplyStroke(t, opts.BoxStrokeColor or Theme.Stroke, 1)

	-- Focus effects
	t.Focused:Connect(function()
		TweenService:Create(t, TweenInfo.new(0.15), {
			BackgroundColor3 = Theme.ButtonPrimary,
			BorderColor3 = Theme.Accent
		}):Play()
	end)

	t.FocusLost:Connect(function()
		TweenService:Create(t, TweenInfo.new(0.15), {
			BackgroundColor3 = Theme.BackgroundLight
		}):Play()
	end)

	-- Bind callbacks
	if opts.FocusLostCallback then t.FocusLost:Connect(opts.FocusLostCallback) end
	if opts.FocusedCallback then t.Focused:Connect(opts.FocusedCallback) end
	if opts.ClickButtonCallback then b.MouseButton1Click:Connect(opts.ClickButtonCallback) end

	return f, b, t;
end;

-- Slider (FIXED: Y position no longer jumps)
function WX_UI:CreateSlider(text: string, min_value: number, max_value: number, callback)
	local frame = Instance.new("Frame", self.sex_scroll)
	frame.Name = text.."Slider"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, -8, 0, 80)
	frame.Visible = true

	local layout = Instance.new("UIListLayout", frame)
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	-- Label with value
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Label"
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = text.." "..tostring(min_value)
	textLabel.TextColor3 = Theme.TextPrimary
	textLabel.TextScaled = false
	textLabel.TextSize = 14
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 0, 24)
	textLabel.Parent = frame

	-- Slider track container
	local sliderContainer = Instance.new("Frame")
	sliderContainer.Name = "SliderContainer"
	sliderContainer.BackgroundTransparency = 1
	sliderContainer.Size = UDim2.new(1, -16, 0, 28)
	sliderContainer.Parent = frame

	-- Track background
	local trackBg = Instance.new("Frame")
	trackBg.Name = "TrackBg"
	trackBg.BackgroundColor3 = Theme.BackgroundLight
	trackBg.BorderSizePixel = 0
	trackBg.Size = UDim2.new(1, 0, 0, 6)
	trackBg.Position = UDim2.new(0, 0, 0.5, -3)
	trackBg.Parent = sliderContainer
	ApplyCorner(trackBg, 3)

	-- Active track fill
	local trackFill = Instance.new("Frame")
	trackFill.Name = "TrackFill"
	trackFill.BackgroundColor3 = Theme.Accent
	trackFill.BorderSizePixel = 0
	trackFill.Size = UDim2.new(0, 0, 1, 0)
	trackFill.Parent = trackBg
	ApplyCorner(trackFill, 3)

	-- Slider handle
	local sliderBt = Instance.new("TextButton", sliderContainer)
	sliderBt.Name = "Handle"
	sliderBt.Text = ''
	sliderBt.BackgroundColor3 = Theme.AccentLight
	sliderBt.BorderSizePixel = 0
	sliderBt.Size = UDim2.new(0, 18, 0, 18)
	sliderBt.Position = UDim2.new(0, 0, 0.5, -9)
	sliderBt.ZIndex = 5
	ApplyCorner(sliderBt, 9)
	ApplyStroke(sliderBt, Theme.TextPrimary, 1.5)

	local initial_Y_position, initial_Y_scale = 
		sliderBt.Position.Y.Offset, 
	    sliderBt.Position.Y.Scale 

	local dragging = false :: boolean;

	local function update_slider(input)
		local relativeX = math.clamp(
			input.Position.X - trackBg.AbsolutePosition.X,
			0,
			trackBg.AbsoluteSize.X
		)

		local percent = relativeX / trackBg.AbsoluteSize.X
		local handleOffset = relativeX - sliderBt.AbsoluteSize.X / 2

		sliderBt.Position = UDim2.new(
			0,
			handleOffset,
			initial_Y_scale,
			initial_Y_position
		)

		trackFill.Size = UDim2.new(0, relativeX, 1, 0)

		local value = math.floor(min_value + (max_value - min_value) * percent)
		textLabel.Text = text.." "..tostring(value)

		if callback then
			pcall(callback, value)
		end
	end

	sliderBt.MouseButton1Down:Connect(function()
		dragging = true
		-- Visual feedback
		TweenService:Create(sliderBt, TweenInfo.new(0.1), {
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(sliderBt.Position.X.Scale, sliderBt.Position.X.Offset, initial_Y_scale, initial_Y_position - 2)
		}):Play()
	end);

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if dragging then
				dragging = false
				-- Reset visual
				TweenService:Create(sliderBt, TweenInfo.new(0.1), {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(sliderBt.Position.X.Scale, sliderBt.Position.X.Offset, initial_Y_scale, initial_Y_position)
				}):Play()
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update_slider(input);
		end;
	end);

	-- Click on track to set value
	trackBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			update_slider(input)
		end
	end)

	return frame;
end;

-- Key binds line
function WX_UI:AddKeyBinds(
	opts: {
		text:        string?,
		KeyBindText: string?, 
		TextSize:    number?, 
		TextColor3:  Color3?, 
		callback:   (...any?) -> ()
	}
): TextLabel
	self.key_binds_frame.Visible = true

	local label = Instance.new('TextLabel', self.keyBindsScroll)
	label.Name        = opts.KeyBindText or opts.text or 'Unknown';
	label.Font        = Enum.Font.Gotham
	label.Text        = `• {opts.KeyBindText or opts.text}`;
	label.TextColor3  = opts.TextColor3 or Theme.Success
	label.TextScaled  = false
	label.TextSize    = opts.TextSize or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundColor3 = Theme.BackgroundLight
	label.BackgroundTransparency = 0
	label.Size = UDim2.new(1, -8, 0, 24)
	label.Visible = true

	ApplyCorner(label, 6)

	return label :: TextLabel;
end;

-- delete key binds by keyName
function WX_UI:deleteKeyBinds(keyName: string)
	if keyName and self.keyBindsScroll:FindFirstChild(keyName) then
		self.keyBindsScroll:FindFirstChild(keyName):Destroy();

		-- Hide keybinds frame if empty
		if #self.keyBindsScroll:GetChildren() <= 1 then -- Only UIListLayout remains
			self.key_binds_frame.Visible = false
		end
	end;
end;

-- check if there key binds by keyName
function WX_UI:IsThereKeyBind(keyName: string): boolean
	return self.keyBindsScroll:FindFirstChild(keyName) and true or false;
end;

-- add toggles func
function WX_UI:AddButtToggle(btn, cb): RBXScriptConnection?
	if btn and typeof(cb) == 'function' then
		return btn.MouseButton1Click:Connect(cb);
	end;
	return nil;
end;

-- change sex frame BackgroundColor3
function WX_UI:ChangeSexFrameColor(NewColor3: Color3)
	self.sex_frame.BackgroundColor3 = NewColor3 or self.sex_frame.BackgroundColor3;
end;

-- stop sex frame gradient/stroke snake animation 
function WX_UI:StopSexFrameGradientAnimation(...)
	if sex_frame_grad_animation then
		task.cancel(sex_frame_grad_animation);
		sex_frame_grad_animation = nil;
	end;
end;

function WX_UI:GetOpUiButton(...)
	return self.ui_button;
end;

-- ui lib functions
function WX_UI:BindOnClickButton(btn: TextButton, callback: (...any) -> ()) -- bind/rebind buttons
	if not (btn and callback) then return;end;

	if UI_BIBDS_ARRAY[btn] and UI_BIBDS_ARRAY[btn].conn then
		UI_BIBDS_ARRAY[btn].conn:Disconnect();
	end;

	local conn = btn.MouseButton1Click:Connect(callback);
	UI_BIBDS_ARRAY[btn] = { callback = callback, conn = conn };
end;

function WX_UI:DragifyEffect(obj: GuiObject)
	local dragToggle: boolean = false
	local dragInput: InputObject? = nil
	local dragStart: Vector3? = nil
	local dragPos: UDim2? = nil
	local dragInfo: TweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local inputChangedConnection: RBXScriptConnection? = nil

	local function _i(input: InputObject) 
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not game:GetService('UserInputService'):GetFocusedTextBox() then

			dragToggle = true
			dragStart = input.Position
			dragPos = obj.Position

			if inputChangedConnection then
				inputChangedConnection:Disconnect()
			end

			inputChangedConnection = game:GetService('UserInputService').InputChanged:Connect(function(input: InputObject)
				if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					if dragStart and dragPos then
						local delta = input.Position - dragStart
						local position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X,dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
						game:GetService('TweenService'):Create(obj, dragInfo, {Position = position}):Play()
					end;
				end;
			end);

			local e_connect: RBXScriptConnection
			e_connect = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false;
					if inputChangedConnection then
						inputChangedConnection:Disconnect();
						inputChangedConnection = nil;
					end;
					e_connect:Disconnect();
				end;
			end);
		end;
	end;
	local _i_beag = obj.InputBegan:Connect(_i);
	obj.Destroying:Connect(function(...)
		if inputChangedConnection then
			inputChangedConnection:Disconnect()
		end;
		if _i_beag then
			_i_beag:Disconnect();
		end;
	end);
end;

return WX_UI;
