-- WX-UI Library

------------ Variables ------------
local cloneref = cloneref or function(o) return o; end;

local coreui = cloneref(game:GetService('CoreGui'));
local UserInputService = cloneref(game:GetService("UserInputService"));

local sex_frame_grad_animation;

local WX_UI          = {...};

local UI_BIBDS_ARRAY = {...} :: {any}

local _load_script_a_teleport: boolean = true;

if not game:IsLoaded() or not game.Loaded then
	local load_message = Instance.new('Message', coreui); load_message.Text = 'WX-UI Library is waiting for the game to load'; game.Loaded:Wait(); load_message:Destroy();
end;

-- executor supports functions // %unc%
local get_cc = getconnections or get_signal_cons;
local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) 
local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request 
local executor_name: string? = getexecutorname() or identifyexecutor() :: string

------------ Create UI schemas ------------
function WX_UI:Wind(is_coreui: boolean, ...)
	local wx_ui_main = Instance.new('GuiMain', is_coreui and coreui or game:GetService('Players').PlayerGui)
	wx_ui_main.Name           = 'WX-UI';
	wx_ui_main.IgnoreGuiInset, wx_ui_main.ResetOnSpawn = false, false;
	wx_ui_main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	self.wx_ui_main = wx_ui_main;

	local main_frame = Instance.new('Frame', wx_ui_main)
	main_frame.BackgroundTransparency = 1
	main_frame.Size = UDim2.new(1, 0, 1, 0)
	main_frame.Visible = true
	main_frame.Name = 'main-frame'
	self.main_frame = main_frame

	local ui_button = Instance.new('TextButton', main_frame);
	ui_button.Text  = 'NYAN'
	
	--local ui_button = Instance.new('ImageButton', main_frame);
	--ui_button.Image = 'rbxassetid://17725832986';
	
	ui_button.Font  = Enum.Font.DenkOne
	ui_button.TextColor3 = Color3.new(0.286275, 0.129412, 0.756863)
	ui_button.TextScaled = true
	ui_button.TextSize = 14
	ui_button.TextWrapped = true
	ui_button.BackgroundColor3 = Color3.new(0, 0, 0)
	ui_button.BackgroundTransparency = 0.20000000298023224
	ui_button.BorderColor3 = Color3.new(0, 0, 0)
	ui_button.Position = UDim2.new(0.20120573, 0, 0.256144881, 0)
	ui_button.Size = UDim2.new(0, 50, 0, 50)
	ui_button.Visible = true
	self.ui_button = ui_button

	local uicorner = Instance.new("UICorner", ui_button)
	uicorner.CornerRadius = UDim.new(0, 50)

	local uistroke = Instance.new("UIStroke", ui_button)
	uistroke.Color = Color3.new(1, 1, 1)

	local uistroke_2 = Instance.new('UIStroke', ui_button)
	uistroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uistroke_2.Color = Color3.new(1, 1, 1)
	uistroke_2.Thickness = 2

	-- create sex
	local sex_frame = Instance.new("Frame", main_frame)
	sex_frame.Name = 'sex'
	sex_frame.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	sex_frame.BackgroundTransparency = 0.1
	sex_frame.Size = UDim2.new(0.295, 0, 0.609, 0)
	sex_frame.Position = UDim2.new(0.361, 0, 0.195, 0)
	self.sex_frame = sex_frame

	local stroke = Instance.new("UIStroke", sex_frame)
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2

	local s_grad = Instance.new("UIGradient", stroke)
	s_grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.286, 0.129, 0.757))
	};
	s_grad.Rotation = 0;

	-- gradient animation
	sex_frame_grad_animation = task.spawn(function(...)
		local dir, speed = 1, 0
		while s_grad.Parent do
			speed += 0.01 * dir;
			s_grad.Rotation += speed;

			if speed > 10 then dir = -1 end;
			if speed < 0.5 then dir = 1 end;

			task.wait(0.01);
		end;
	end);

	local uicorner_2 = Instance.new('UICorner', sex_frame)
	uicorner_2.CornerRadius = UDim.new(0, 50)

	local sex_scroll = Instance.new("ScrollingFrame", sex_frame)
	sex_scroll.ScrollBarImageColor3 = Color3.new(0, 0, 0)
	sex_scroll.ScrollBarThickness = 4;
	sex_scroll.Active = true;
	sex_scroll.BackgroundColor3 = Color3.new(1, 1, 1)
	sex_scroll.BackgroundTransparency = 1
	sex_scroll.BorderColor3 = Color3.new(0, 0, 0)
	sex_scroll.Position = UDim2.new(0, 0, 0.0955414027, 0)
	sex_scroll.Size = UDim2.new(1, 0, 0.904458582, 0)
	sex_scroll.Visible = true;
	self.sex_scroll = sex_scroll

	local s1 = Instance.new('UIListLayout', sex_scroll)
	s1.Padding = UDim.new(0, 10)
	s1.HorizontalAlignment = Enum.HorizontalAlignment.Center
	s1.SortOrder = Enum.SortOrder.LayoutOrder

	local nyanlose = Instance.new("TextLabel", sex_frame)
	nyanlose.Font = Enum.Font.DenkOne
	nyanlose.Text = 'NYANLOSE'
	nyanlose.Name = 'NYANLOSE'
	nyanlose.TextColor3 = Color3.new(0.286275, 0.129412, 0.756863)
	nyanlose.TextScaled = true
	nyanlose.TextSize = 14
	nyanlose.TextWrapped = true
	nyanlose.BackgroundColor3 = Color3.new(1, 1, 1)
	nyanlose.BackgroundTransparency = 1
	nyanlose.BorderColor3 = Color3.new(0, 0, 0)
	nyanlose.BorderSizePixel = 0
	nyanlose.Size = UDim2.new(1.00000012, 0, 0.0955414101, 0)
	nyanlose.Visible = true;

	local uistroke_6 = Instance.new("UIStroke", nyanlose)
	uistroke_6.Color = Color3.new(1, 1, 1)

	-- create keyBinds
	local key_binds_frame = Instance.new("Frame", main_frame)
	key_binds_frame.BackgroundColor3 = Color3.new(0.235294, 0.172549, 0.709804)
	key_binds_frame.BackgroundTransparency = 0.20000000298023224
	key_binds_frame.BorderColor3 = Color3.new(0, 0, 0)
	key_binds_frame.BorderSizePixel = 0
	key_binds_frame.Position = UDim2.new(0.766390383, 0, 0.0349288546, 0)
	key_binds_frame.Size = UDim2.new(0.168801814, 0, 0.159120306, 0)
	key_binds_frame.Visible = false;
	key_binds_frame.Name = 'KeyBindsFrame';
	self.key_binds_frame = key_binds_frame

	local key_binds = Instance.new('TextLabel', key_binds_frame)
	key_binds.Font  = Enum.Font.DenkOne
	key_binds.Text  = "KeyBinds"
	key_binds.TextColor3  = Color3.new(0.286275, 0.129412, 0.756863)
	key_binds.TextScaled  = true
	key_binds.TextSize    = 14
	key_binds.TextWrapped = true
	key_binds.BackgroundColor3 = Color3.new(0.235294, 0.172549, 0.709804)
	key_binds.BackgroundTransparency = 1
	key_binds.BorderColor3    = Color3.new(0, 0, 0)
	key_binds.BorderSizePixel = 0
	key_binds.Size    = UDim2.new(1, 0, 0.25, 0)
	key_binds.Visible = true

	local strok1, stroke2 = Instance.new('UIStroke', key_binds), Instance.new('UIStroke', key_binds_frame);
	strok1.Color, stroke2.Color = Color3.new(1, 1, 1), Color3.new(1, 1, 1);
	stroke2.Thickness = 2;

	local cor = Instance.new('UICorner', key_binds_frame);cor.CornerRadius = UDim.new(0, 10);

	local keyBindsScroll = Instance.new('ScrollingFrame', key_binds_frame);
	keyBindsScroll.ScrollBarImageColor3 = Color3.new(0, 0, 0)
	keyBindsScroll.ScrollBarThickness   = 2
	keyBindsScroll.Active, keyBindsScroll.Visible = true, true;
	keyBindsScroll.BackgroundColor3 = Color3.new(1, 1, 1)
	keyBindsScroll.BackgroundTransparency = 1
	keyBindsScroll.BorderColor3    = Color3.new(0, 0, 0)
	keyBindsScroll.BorderSizePixel = 0
	keyBindsScroll.Position        = UDim2.new(0, 0, 0.25, 0)
	keyBindsScroll.Size            = UDim2.new(1, 0, 0.75, 0)
	
	self.keyBindsScroll = keyBindsScroll
	
	-- ui styling and optimize 
	local ui_ratio1, ui_ratio2, ui_ratio3, ui_ratio4 = Instance.new('UIAspectRatioConstraint'), Instance.new('UIAspectRatioConstraint'), Instance.new('UIAspectRatioConstraint'), Instance.new('UIAspectRatioConstraint');
	ui_ratio1.Parent, ui_ratio2.Parent, ui_ratio3.Parent = sex_scroll, key_binds_frame, sex_frame;
	ui_ratio1.AspectRatio, ui_ratio2.AspectRatio, ui_ratio3.AspectRatio = 0.920187771320343, 1.8211382627487183, 0.8322717547416687;

	-- UIDragDetector 
	local UIDragDetector, UIDragDetector2 = Instance.new('UIDragDetector', sex_frame), Instance.new('UIDragDetector', key_binds_frame);
	UIDragDetector.Enabled, UIDragDetector2.Enabled = true, true;

	-- open/clsoe ui Button
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
	f.Size  = opts.FrameSize or UDim2.new(0, 350, 0, 50)
	f.BackgroundTransparency = 1

	local b = Instance.new('TextButton', f)
	b.Text      = opts.text;
	b.Font      = Enum.Font.DenkOne
	b.TextColor3= Color3.new(0.286, 0.129, 0.757)
	b.TextScaled= true
	b.TextSize  = 14
	b.TextWrapped = true
	b.BackgroundColor3 = opts.ButtonColor3 or Color3.new(1,1,1)
	b.BackgroundTransparency = 0.5
	b.Size = UDim2.new(0.6, 0, 0.85, 0)

	local corn = Instance.new('UICorner', b)
	corn.CornerRadius = UDim.new(0, 50)

	local size = Instance.new('UITextSizeConstraint', b);size.MaxTextSize = opts.ButtonTextSize or 25;

	local s1, s2 = Instance.new('UIStroke', b), Instance.new('UIStroke', b);
	s1.Color,     s2.Color = opts.buttonStrokeColor or Color3.new(1,1,1), Color3.new(1,1,1);
	s1.Thickness, s2.Thickness = 2, 2;
	s1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local list = Instance.new('UIListLayout', f)
	list.Padding             = UDim.new(0, 10);
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	list.VerticalAlignment   = Enum.VerticalAlignment.Center;
	list.SortOrder           = Enum.SortOrder.LayoutOrder;

	--local ar1, ar2 = Instance.new('UIAspectRatioConstraint', f), Instance.new('UIAspectRatioConstraint', b);
	--ar1.AspectRatio, ar2.AspectRatio = 7, 5;
	local ar1 = Instance.new('UIAspectRatioConstraint', b);
	ar1.AspectRatio = 5;

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
	local b = WX_UI:WX_CreateButton({
		text = opts.ButtonText,
		ButtonTextSize = opts.ButtonTextSize,
		ButtonColor3 = opts.ButtonColor3,
		buttonStrokeColor = opts.buttonStrokeColor,
		FrameSize = UDim2.new(0, 350, 0, 101)
	});
	
	local f = b.Parent;

	local t = Instance.new('TextBox', f)
	t.PlaceholderText = 'write this...'
	t.Text = opts.TextBoxText or '';
	t.Font = Enum.Font.DenkOne
	t.TextColor3 = Color3.fromRGB(72, 32, 193)
	t.TextScaled = true
	t.BackgroundColor3 = Color3.fromRGB(73, 33, 193)
	t.BackgroundTransparency = 0.5
	t.Size = UDim2.new(0.6, 0, 0.85, 0)

	local size = Instance.new('UITextSizeConstraint', t);size.MaxTextSize = opts.TextBoxTextSize or 25

	local st1 = Instance.new("UIStroke", t) st1.Color = Color3.new(1,1,1) st1.Thickness = 2
	local st2 = Instance.new("UIStroke", t) st2.Color = opts.BoxStrokeColor or Color3.fromRGB(116, 33, 218) st2.Thickness = 2 st2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local c = Instance.new("UICorner", t);c.CornerRadius = UDim.new(0, 50)
	local s = Instance.new("UIAspectRatioConstraint", t);s.AspectRatio = 5
	
	-- Bind callbacks
	if opts.FocusLostCallback then t.FocusLost:Connect(opts.FocusLostCallback) end
	if opts.FocusedCallback then t.Focused:Connect(opts.FocusedCallback) end
	if opts.ClickButtonCallback then b.MouseButton1Click:Connect(opts.ClickButtonCallback) end
	
	return f, b, t;
end;

-- slider
function WX_UI:CreateSlider(text: string, min_value: number, max_value: number, callback)
	local frame = Instance.new("Frame", self.sex_scroll)
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(0, 350, 0, 100)
	frame.Visible = true
	frame.Name = "loopspeed"

	local uilist_layout = Instance.new("UIListLayout", frame)
	uilist_layout.Padding = UDim.new(0, 10)
	uilist_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uilist_layout.SortOrder = Enum.SortOrder.LayoutOrder
	uilist_layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local textLabel = Instance.new("TextLabel")
	textLabel.Font = Enum.Font.DenkOne
	textLabel.Text = text
	textLabel.TextColor3 = Color3.new(0.286275, 0.129412, 0.756863)
	textLabel.TextScaled = true
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 0.3, 0)
	textLabel.Name = "TEXT"
	textLabel.Parent = frame

	local uistroke = Instance.new("UIStroke")
	uistroke.Color = Color3.new(1, 1, 1)
	uistroke.Parent = textLabel

	local slider = Instance.new("Frame")
	slider.BackgroundTransparency = 1
	slider.Size = UDim2.new(0, 350, 0, 50)
	slider.Name = "slider"
	slider.Parent = frame

	local line = Instance.new("Frame")
	line.BackgroundColor3 = Color3.new(0.286275, 0.129412, 0.756863)
	line.BorderSizePixel = 0
	line.Position = UDim2.new(0.12, 0, 0.6, 0)
	line.Size = UDim2.new(0, 250, 0, 5)
	line.Name = "slider-line"
	line.Parent = slider

	local uistroke_2 = Instance.new("UIStroke")
	uistroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uistroke_2.Color = Color3.new(1, 1, 1)
	uistroke_2.Thickness = 1.5
	uistroke_2.Parent = line

	local uicorner = Instance.new("UICorner")
	uicorner.CornerRadius = UDim.new(1, 0)
	uicorner.Parent = line

	local sliderBt = Instance.new("TextButton", slider)
	sliderBt.Text = ''
	sliderBt.BackgroundColor3 = Color3.new(0.286275, 0.129412, 0.756863)
	sliderBt.BorderSizePixel = 0
	sliderBt.Position = UDim2.new(0, 250, 0.4, 0)
	sliderBt.Size = UDim2.new(0, 20, 0, 20)
	sliderBt.Name = "SL"

	local uicorner_2 = Instance.new("UICorner")
	uicorner_2.CornerRadius = UDim.new(1, 0)
	uicorner_2.Parent = sliderBt

	local uistroke_3 = Instance.new("UIStroke")
	uistroke_3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uistroke_3.Color = Color3.new(1, 1, 1)
	uistroke_3.Thickness = 1.5
	uistroke_3.Parent = sliderBt

	local num = Instance.new("TextLabel")
	num.Font = Enum.Font.DenkOne
	num.Text = tostring(min_value)
	num.TextColor3 = Color3.new(0.286275, 0.129412, 0.756863)
	num.TextScaled = true
	num.BackgroundTransparency = 1
	num.Position = UDim2.new(0.29, 0, 0.05, 0)
	num.Size = UDim2.new(0.4, 0, 0.5, 0)
	num.Name = "num"
	num.Parent = slider

	local uistroke_4 = Instance.new("UIStroke")
	uistroke_4.Color = Color3.new(1, 1, 1)
	uistroke_4.Parent = num

	local uitext_size_constraint = Instance.new("UITextSizeConstraint")
	uitext_size_constraint.MaxTextSize = 23
	uitext_size_constraint.Parent = num

	local dragging = false :: boolean;
	
	local function move(input)
		local relativeX = math.clamp(
			input.Position.X - line.AbsolutePosition.X,
			0,
			line.AbsoluteSize.X
		)

		sliderBt.Position = UDim2.new(
			0,
			line.Position.X.Offset + relativeX - sliderBt.AbsoluteSize.X/2,
			sliderBt.Position.Y.Scale, 
			- sliderBt.AbsoluteSize.Y/2
		)

		local percent = relativeX / line.AbsoluteSize.X
		local value = math.floor(min_value + (max_value - min_value) * percent)

		num.Text = tostring(value)
		if callback then
			pcall(callback, value)
		end
	end

	sliderBt.MouseButton1Down:Connect(function()
		dragging = true
	end);

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			move(input);
		end;
	end);

	return frame;
end;

-- key binds line
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
	label.Name        = opts.KeyBindText or opts.text or 'Unknow';
	label.Font        = Enum.Font.DenkOne
	label.Text        = ` {opts.KeyBindText or opts.text}`;
	label.TextColor3  = opts.TextColor3 or Color3.new(1, 1, 1)
	label.TextScaled  = true
	label.TextSize    = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 210, 0, 20)
	label.Visible = true

	local size = Instance.new('UITextSizeConstraint', label); size.MaxTextSize = opts.TextSize or 16;

	local list = Instance.new('UIListLayout', self.keyBindsScroll)
	list.Padding = UDim.new(0, 8);
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	list.SortOrder = Enum.SortOrder.LayoutOrder;

	return label :: TextLabel;
end;

-- delete key binds by keyName
function WX_UI:deleteKeyBinds(keyName: string)
	if keyName and self.keyBindsScroll:FindFirstChild(keyName) then
		self.keyBindsScroll:FindFirstChild(keyName):Destroy();
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
	local dragInfo: TweenInfo = TweenInfo.new(0.15)
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

--game:GetService('Players').LocalPlayer.OnTeleport:Connect(function(...)
--	if queueteleport and _load_script_a_teleport then
--		_load_script_a_teleport = false :: boolean
--		queueteleport("loadstring(game:HttpGet('https://fluffycookies.space/Assets/WX-LUAU'))()");
--	else
--		warn('Incompatible Exploit', 'Your executor does not support queue_on_teleport');
--	end;
--end);

return WX_UI;
