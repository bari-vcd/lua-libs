--!native
--!optimize 2
--!nocheck 

-- [ Variables ]
getgenv = getgenv or getfenv

-- [ Bootstrapper ]
getgenv().Signal = getgenv().Signal or getgenv().PsmSignal or (function()
	return loadstring(game:HttpGetAsync('https://raw.githubusercontent.com/bari-vcd/lua-libs/refs/heads/main/libs/WaxSignal.lua'))()
end);

-- [ Main ]
local Loader = {}
Loader.__index = Loader

function Loader.new<T>(props)
	local self = setmetatable({
		UIParent = props.UIParent;
		UIScale  = props.UIScale or 1.1;
		OnExit   = getgenv().Signal.new();
		OnAuth   = getgenv().Signal.new();
	}, Loader)
	self:MakeUI()
	return self
end

function Loader:MakeUI()
	local guiMain = Instance.new('GuiMain', self.UIParent)
	guiMain.Name = ''
	guiMain.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	guiMain.Enabled, guiMain.ResetOnSpawn, guiMain.AutoLocalize = true, false, false

	local mainFrame = Instance.new('ImageLabel', guiMain)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Size = UDim2.fromOffset(305, 200)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.Image = "rbxassetid://110114120718204"
	mainFrame.ImageColor3 = Color3.fromRGB(234, 234, 234)
	mainFrame.ImageTransparency = 0.13
	mainFrame.ZIndex = 1

	local stroke = Instance.new("UIStroke", mainFrame)
	stroke.Color = Color3.new(0.588235, 0.588235, 0.588235)
	stroke.Thickness = 1.4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local corner = Instance.new("UICorner", mainFrame)
	corner.CornerRadius = UDim.new(0, 20)

	local uiScale = Instance.new('UIScale', mainFrame)
	uiScale.Scale = self.UIScale;

	Instance.new('UIDragDetector', mainFrame)

	local topBar = Instance.new("ImageLabel", mainFrame)
	topBar.BackgroundTransparency = 1
	topBar.BorderSizePixel = 0
	topBar.Size = UDim2.new(1, 0, 0.1, 0)

	local topBarPadding = Instance.new("UIPadding", topBar)
	topBarPadding.PaddingBottom = UDim.new(0, 7)
	topBarPadding.PaddingLeft = UDim.new(0, 17)
	topBarPadding.PaddingRight = UDim.new(0, 17)
	topBarPadding.PaddingTop = UDim.new(0, 7)

	local topBarLayout = Instance.new("UIListLayout")
	topBarLayout.FillDirection = Enum.FillDirection.Horizontal
	topBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	topBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topBarLayout.Padding = UDim.new(0, 8)
	topBarLayout.Parent = topBar

	local exitButton = Instance.new("TextButton", topBar)
	exitButton.BackgroundColor3 = Color3.fromRGB(235, 87, 87)
	exitButton.BorderSizePixel = 0
	exitButton.Size = UDim2.fromOffset(9, 9)
	exitButton.Text = ""

	local exitCorner = Instance.new("UICorner")
	exitCorner.CornerRadius = UDim.new(1, 0)
	exitCorner.Parent = exitButton

	local minimiseButton = Instance.new("TextButton")
	minimiseButton.BackgroundColor3 = Color3.fromRGB(242, 184, 75)
	minimiseButton.BorderSizePixel = 0
	minimiseButton.Size = UDim2.fromOffset(9, 9)
	minimiseButton.Text = ""
	minimiseButton.Parent = topBar

	local minimiseCorner = Instance.new("UICorner")
	minimiseCorner.CornerRadius = UDim.new(1, 0)
	minimiseCorner.Parent = minimiseButton

	local expandButton = Instance.new("TextButton", topBar)
	expandButton.BackgroundColor3 = Color3.fromRGB(56, 204, 107)
	expandButton.BorderSizePixel = 0
	expandButton.Size = UDim2.fromOffset(9, 9)
	expandButton.Text = ""

	local expandCorner = Instance.new("UICorner", expandButton)
	expandCorner.CornerRadius = UDim.new(1, 0)

	local icon = Instance.new("ImageLabel", mainFrame)
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromOffset(7, 4)
	icon.Size = UDim2.fromOffset(27, 27)
	icon.Image = "rbxassetid://121804349448700"

	local title = Instance.new("TextLabel", mainFrame)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.24, 0)
	title.Size = UDim2.fromOffset(130, 25)
	title.BackgroundTransparency = 1
	title.Text = 'Sign in to continue'
	title.Font = Enum.Font.Nunito
	title.TextColor3 = Color3.fromRGB(179, 179, 179)
	title.TextScaled = true
	title.TextWrapped = true

	local titleSize = Instance.new("UITextSizeConstraint", title)
	titleSize.MaxTextSize = 60

	local usernameBox = Instance.new("TextBox", mainFrame)
	usernameBox.AnchorPoint = Vector2.new(0.5, 0.5)
	usernameBox.Position = UDim2.new(0.5, 0, 0.46, 0)
	usernameBox.Size = UDim2.fromOffset(125, 25)
	usernameBox.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	usernameBox.BackgroundTransparency = 0.5
	usernameBox.BorderSizePixel = 0
	usernameBox.Font = Enum.Font.Nunito
	usernameBox.PlaceholderText = 'username'
	usernameBox.Text = ''
	usernameBox.TextColor3 = Color3.fromRGB(197, 197, 197)
	usernameBox.TextSize = 15

	local uc = Instance.new('UICorner', usernameBox); uc.CornerRadius = UDim.new(0, 7)

	local passwordBox = Instance.new("TextBox")
	passwordBox.AnchorPoint = Vector2.new(0.5, 0.5)
	passwordBox.Position = UDim2.new(0.5, 0, 0.64, 0)
	passwordBox.Size = UDim2.fromOffset(125, 25)
	passwordBox.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	passwordBox.BackgroundTransparency = 0.5
	passwordBox.BorderSizePixel = 0
	passwordBox.Font = Enum.Font.Nunito
	passwordBox.PlaceholderText = "password"
	passwordBox.Text = ''
	passwordBox.TextColor3 = Color3.fromRGB(197, 197, 197)
	passwordBox.TextSize = 15
	passwordBox.Parent = mainFrame

	local passwordCorner = Instance.new("UICorner", passwordBox)
	passwordCorner.CornerRadius = UDim.new(0, 7)

	local signInButton = Instance.new("TextButton", mainFrame)
	signInButton.AnchorPoint = Vector2.new(0.5, 0.5)
	signInButton.Position = UDim2.new(0.5, 0, 0.84, 0)
	signInButton.Size = UDim2.fromOffset(125, 25)
	signInButton.BackgroundColor3 = Color3.fromRGB(39, 39, 39)
	signInButton.BackgroundTransparency = 0.3
	signInButton.BorderSizePixel = 0
	signInButton.Font = Enum.Font.SourceSansBold
	signInButton.Text = 'Sign in'
	signInButton.TextColor3 = Color3.fromRGB(207, 207, 207)
	signInButton.TextSize = 14

	local signInCorner = Instance.new("UICorner", signInButton)
	signInCorner.CornerRadius = UDim.new(0, 7)

	local signInGradient = Instance.new("UIGradient", signInButton)
	signInGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 43, 43)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(234, 227, 224))
	}
	signInGradient.Rotation = 265

	exitButton.MouseButton1Click:Connect(function()
		self.OnExit:Fire({ 
			UIScale = uiScale; GuiMain = guiMain 
		})
	end)

	signInButton.MouseButton1Click:Connect(function()
		self.OnAuth:Fire({
			UIScale = uiScale; username = usernameBox.Text; password = passwordBox.Text; GuiMain  = guiMain;
		})
	end)

	self.GET = {
		guiMain = guiMain,
		mainFrame = mainFrame,
		topBar = topBar,
		uiScale = uiScale,
	} 
end

return Loader :: typeof( Loader );

-- // EOF
