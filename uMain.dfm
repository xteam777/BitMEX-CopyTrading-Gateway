object fGateway: TfGateway
  Left = 0
  Top = 0
  Caption = 'MC Gateway'
  ClientHeight = 410
  ClientWidth = 466
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 16
  object sgServers: TAdvStringGrid
    Left = 0
    Top = 49
    Width = 466
    Height = 361
    Cursor = crDefault
    Align = alClient
    ColCount = 4
    DrawingStyle = gdsClassic
    FixedCols = 0
    RowCount = 1
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing]
    ScrollBars = ssBoth
    TabOrder = 0
    HoverRowCells = [hcNormal, hcSelected]
    ActiveCellFont.Charset = DEFAULT_CHARSET
    ActiveCellFont.Color = clWindowText
    ActiveCellFont.Height = -11
    ActiveCellFont.Name = 'Tahoma'
    ActiveCellFont.Style = [fsBold]
    ControlLook.FixedGradientHoverFrom = clGray
    ControlLook.FixedGradientHoverTo = clWhite
    ControlLook.FixedGradientDownFrom = clGray
    ControlLook.FixedGradientDownTo = clSilver
    ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownHeader.Font.Color = clWindowText
    ControlLook.DropDownHeader.Font.Height = -11
    ControlLook.DropDownHeader.Font.Name = 'Tahoma'
    ControlLook.DropDownHeader.Font.Style = []
    ControlLook.DropDownHeader.Visible = True
    ControlLook.DropDownHeader.Buttons = <>
    ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownFooter.Font.Color = clWindowText
    ControlLook.DropDownFooter.Font.Height = -11
    ControlLook.DropDownFooter.Font.Name = 'Tahoma'
    ControlLook.DropDownFooter.Font.Style = []
    ControlLook.DropDownFooter.Visible = True
    ControlLook.DropDownFooter.Buttons = <>
    Filter = <>
    FilterDropDown.Font.Charset = DEFAULT_CHARSET
    FilterDropDown.Font.Color = clWindowText
    FilterDropDown.Font.Height = -11
    FilterDropDown.Font.Name = 'Tahoma'
    FilterDropDown.Font.Style = []
    FilterDropDown.TextChecked = 'Checked'
    FilterDropDown.TextUnChecked = 'Unchecked'
    FilterDropDownClear = '(All)'
    FilterEdit.TypeNames.Strings = (
      'Starts with'
      'Ends with'
      'Contains'
      'Not contains'
      'Equal'
      'Not equal'
      'Larger than'
      'Smaller than'
      'Clear')
    FixedColWidth = 197
    FixedRowHeight = 22
    FixedFont.Charset = DEFAULT_CHARSET
    FixedFont.Color = clWindowText
    FixedFont.Height = -11
    FixedFont.Name = 'Tahoma'
    FixedFont.Style = [fsBold]
    FloatFormat = '%.2f'
    HoverButtons.Buttons = <>
    HoverButtons.Position = hbLeftFromColumnLeft
    HTMLSettings.ImageFolder = 'images'
    HTMLSettings.ImageBaseName = 'img'
    PrintSettings.DateFormat = 'dd/mm/yyyy'
    PrintSettings.Font.Charset = DEFAULT_CHARSET
    PrintSettings.Font.Color = clWindowText
    PrintSettings.Font.Height = -11
    PrintSettings.Font.Name = 'Tahoma'
    PrintSettings.Font.Style = []
    PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
    PrintSettings.FixedFont.Color = clWindowText
    PrintSettings.FixedFont.Height = -11
    PrintSettings.FixedFont.Name = 'Tahoma'
    PrintSettings.FixedFont.Style = []
    PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
    PrintSettings.HeaderFont.Color = clWindowText
    PrintSettings.HeaderFont.Height = -11
    PrintSettings.HeaderFont.Name = 'Tahoma'
    PrintSettings.HeaderFont.Style = []
    PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
    PrintSettings.FooterFont.Color = clWindowText
    PrintSettings.FooterFont.Height = -11
    PrintSettings.FooterFont.Name = 'Tahoma'
    PrintSettings.FooterFont.Style = []
    PrintSettings.PageNumSep = '/'
    SearchFooter.FindNextCaption = 'Find &next'
    SearchFooter.FindPrevCaption = 'Find &previous'
    SearchFooter.Font.Charset = DEFAULT_CHARSET
    SearchFooter.Font.Color = clWindowText
    SearchFooter.Font.Height = -11
    SearchFooter.Font.Name = 'Tahoma'
    SearchFooter.Font.Style = []
    SearchFooter.HighLightCaption = 'Highlight'
    SearchFooter.HintClose = 'Close'
    SearchFooter.HintFindNext = 'Find next occurrence'
    SearchFooter.HintFindPrev = 'Find previous occurrence'
    SearchFooter.HintHighlight = 'Highlight occurrences'
    SearchFooter.MatchCaseCaption = 'Match case'
    ShowDesignHelper = False
    SortSettings.DefaultFormat = ssAutomatic
    Version = '8.1.3.0'
    ColWidths = (
      197
      64
      64
      64)
    RowHeights = (
      22)
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 466
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object Label1: TLabel
      Left = 161
      Top = 17
      Width = 65
      Height = 16
      Caption = 'IP address:'
    end
    object eAddress: TAdvEdit
      Left = 232
      Top = 13
      Width = 226
      Height = 24
      EmptyTextStyle = []
      LabelFont.Charset = DEFAULT_CHARSET
      LabelFont.Color = clWindowText
      LabelFont.Height = -11
      LabelFont.Name = 'Tahoma'
      LabelFont.Style = []
      Lookup.Font.Charset = DEFAULT_CHARSET
      Lookup.Font.Color = clWindowText
      Lookup.Font.Height = -11
      Lookup.Font.Name = 'Arial'
      Lookup.Font.Style = []
      Lookup.Separator = ';'
      Color = clWindow
      TabOrder = 0
      Text = 'localhost'
      Visible = True
      Version = '3.4.1.1'
    end
    object tsState: TToggleSwitch
      Left = 8
      Top = 12
      Width = 133
      Height = 25
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      StateCaptions.CaptionOn = 'Started'
      StateCaptions.CaptionOff = 'Stopped'
      SwitchHeight = 25
      SwitchWidth = 80
      TabOrder = 1
      ThumbColor = clRed
      ThumbWidth = 30
      OnClick = tsStateClick
    end
  end
  object Server: TRtcHttpServer
    MultiThreaded = True
    ServerAddr = 'localhost'
    ServerPort = '8888'
    RestartOn.ListenLost = True
    RestartOn.ListenError = True
    Left = 24
    Top = 246
  end
  object Module: TRtcServerModule
    Server = Server
    Compression = cMax
    EncryptionKey = 16
    SecureKey = '2230897'
    AutoSessions = True
    ModuleFileName = '/gatefunc'
    FunctionGroup = ServerFunctionGroup
    Left = 62
    Top = 246
  end
  object ServerFunctionGroup: TRtcFunctionGroup
    Left = 102
    Top = 244
  end
  object Conn: TFDConnection
    Params.Strings = (
      'Database=MEXCopy'
      'Password=2230897'
      'User_Name=sa'
      'DriverID=MSSQL'
      'Server=localhost')
    LoginPrompt = False
    Left = 22
    Top = 198
  end
  object fGetNotifications: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'GetNotifications'
    OnExecute = fGetNotificationsExecute
    Left = 140
    Top = 244
  end
  object rDoAccountLogin: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Account_DoLogin'
    OnExecute = rDoAccountLoginExecute
    Left = 176
    Top = 246
  end
  object rGetSubscriptions: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'GetSubscriptions'
    OnExecute = rGetSubscriptionsExecute
    Left = 214
    Top = 246
  end
  object rSubscriptionIsActive: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Subscription_IsActive'
    OnExecute = rSubscriptionIsActiveExecute
    Left = 250
    Top = 246
  end
  object rGetConnectionData: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Client_GetConnectionData'
    OnExecute = rGetConnectionDataExecute
    Left = 284
    Top = 246
  end
  object rDoServerLogin: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Server_DoLogin'
    OnExecute = rDoServerLoginExecute
    Left = 140
    Top = 294
  end
  object rServerPing: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Server_Ping'
    OnExecute = rServerPingExecute
    Left = 218
    Top = 292
  end
  object rDeactivateStrategy: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Strategy_Deactivate'
    OnExecute = rDeactivateStrategyExecute
    Left = 326
    Top = 248
  end
  object rStrategiesChanges: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Server_StatChanges'
    OnExecute = rStrategiesChangesExecute
    Left = 258
    Top = 294
  end
  object rDoServerLogout: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Server_DoLogout'
    OnExecute = rDoServerLogoutExecute
    Left = 180
    Top = 296
  end
  object rApiKeysIsActiveStrategy: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'ApiKeysIsActiveStrategy'
    OnExecute = rApiKeysIsActiveStrategyExecute
    Left = 298
    Top = 294
  end
  object rClientPing: TRtcFunction
    Group = ServerFunctionGroup
    FunctionName = 'Client_Ping'
    OnExecute = rClientPingExecute
    Left = 336
    Top = 294
  end
end
