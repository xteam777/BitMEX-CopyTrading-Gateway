unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, AdvEdit, rtcFunction, SyncObjs,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI, rtcDataSrv, rtcSrvModule, rtcSystem, rtcInfo, rtcConn, rtcHttpSrv,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, DateUtils,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, Data.DB, FireDAC.Comp.Client, Vcl.WinXCtrls, sgcJSON,
  FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, AdvUtil, Vcl.Grids,
  AdvObj, BaseGrid, AdvGrid, System.IOUtils, rtcLog, Vcl.ExtCtrls;

type
  TFillServersTable = procedure of object;
  TCheckPingsThread = class(TThread)
  protected
    FillServersTable: TFillServersTable;
    procedure Execute; override;
    procedure OnServerDisconnect(address: String);
  end;

  PServerData = ^TServerData;
  TServerData = record
      address: String;
      strategiesInfo: TRtcInfo;
      subscriptionsCount: Integer;
      lastPing: TDateTime;
  end;

  TfGateway = class(TForm)
    Server: TRtcHttpServer;
    Module: TRtcServerModule;
    ServerFunctionGroup: TRtcFunctionGroup;
    Conn: TFDConnection;
    fGetNotifications: TRtcFunction;
    rDoAccountLogin: TRtcFunction;
    rGetSubscriptions: TRtcFunction;
    rSubscriptionIsActive: TRtcFunction;
    rGetConnectionData: TRtcFunction;
    sgServers: TAdvStringGrid;
    rDoServerLogin: TRtcFunction;
    rServerPing: TRtcFunction;
    rDeactivateStrategy: TRtcFunction;
    Panel1: TPanel;
    eAddress: TAdvEdit;
    tsState: TToggleSwitch;
    Label1: TLabel;
    rStrategiesChanges: TRtcFunction;
    rDoServerLogout: TRtcFunction;
    rApiKeysIsActiveStrategy: TRtcFunction;
    rClientPing: TRtcFunction;
    procedure tsStateClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure fGetNotificationsExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rDoAccountLoginExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rGetSubscriptionsExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rSubscriptionIsActiveExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rGetConnectionDataExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure rDoServerLoginExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rServerPingExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rDeactivateStrategyExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rStrategiesChangesExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rDoServerLogoutExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rApiKeysIsActiveStrategyExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure rClientPingExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure LoadSettings;
    procedure SaveSettings;
    procedure GetStrategyDataFromDB(strategyId: String; var apiKey, apiSecret: String; var strategyActive: Boolean; var lastRun: TDateTime);
    procedure DoStart;
    procedure DoStop;
    procedure FillServersTable;
    function GetServerMessageFileContents(address: String): String;
    procedure AppendServerMessageFile(address, msg: String);
    procedure ClearServerMessageFile(address: String);
    function GetClientMessageFileContents(accountId: String): String;
    procedure DeleteOldDataFiles;
    function GetLastClientChanges(accountId: String): Int64;
  end;

  function GetCurrentTimestamp: Int64;

const
  pingTimeout = 30 * 1000; // 5 секунд
  runRetryTimeout = 10 * 60 * 1000; //10 минут

var
  fGateway: TfGateway;
  serversList: TList;
  serversInfo: TRtcInfo; //ƒублирующа€ структура, необходима€ дл€ быстрого поиска по индексу-строке
  CS: TCriticalSection;
  tCPThread: TCheckPingsThread;

implementation

{$R *.dfm}

procedure TfGateway.rDoServerLogoutExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  i: Integer;
  pData: PServerData;
begin
  CS.Acquire;
  try
    if (serversInfo.Child[Param.asString['address']] <> nil) then
    begin
        pData := PServerData(serversInfo.Child[Param.asString['address']].asPtr['data']);
        pData^.strategiesInfo.Free;
        for i := 0 to serversList.Count - 1 do
          if (PServerData(serversList[i])^.address = Param.asString['address']) then
            serversList.Delete(i);
        Dispose(pData);
        serversInfo.SetNil(Param.asString['address']);
    end;

    ClearServerMessageFile(Param.asString['address']);

    xLog('Server disconnected: ' + Param.asString['address']);

    FillServersTable;

    Result.asBoolean := True;
  finally
    CS.Release;
  end;
end;

function TfGateway.GetServerMessageFileContents(address: String): String;
begin
  CS.Acquire;
  try
    Result := '';

    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\');
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\Servers\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\Servers\');

    if FileExists(ExtractFilePath(ParamStr(0)) + 'Data\Servers\' + address + '.msg') then
      Result := TFile.ReadAllText(ExtractFilePath(ParamStr(0)) + 'Data\Servers\' + address + '.msg')
    else
      Result := '';
  finally
    CS.Release;
  end;
end;

function TfGateway.GetClientMessageFileContents(accountId: String): String;
begin
  CS.Acquire;
  try
    Result := '';

    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\');
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\Clients\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\Clients\');

    if FileExists(ExtractFilePath(ParamStr(0)) + 'Data\Clients\' + accountId + '.msg') then
      Result := TFile.ReadAllText(ExtractFilePath(ParamStr(0)) + 'Data\Clients\' + accountId + '.msg')
    else
      Result := '';
  finally
    CS.Release;
  end;
end;

procedure TfGateway.AppendServerMessageFile(address, msg: String);
begin
  CS.Acquire;
  try
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\');
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\Servers\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\Servers\');

    TFile.AppendAllText(ExtractFilePath(ParamStr(0)) + 'Data\Servers\' + address + '.msg', msg + ';');
  finally
    CS.Release;
  end;
end;

procedure TfGateway.ClearServerMessageFile(address: String);
begin
  CS.Acquire;
  try
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\');
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\Servers\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\Servers\');

    if TFile.Exists(ExtractFilePath(ParamStr(0)) + 'Data\Servers\' + address + '.msg') then
      TFile.Delete(ExtractFilePath(ParamStr(0)) + 'Data\Servers\' + address + '.msg');
  finally
    CS.Release;
  end;
end;

procedure TfGateway.DeleteOldDataFiles;
var
  vdate: TDatetime;
  sr: TSearchRec;
  intFileAge: LongInt;
  myfileage: TDatetime;
begin
  try
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\');
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\Servers\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\Servers\');

    if FindFirst(ExtractFilePath(ParamStr(0)) + 'Data\Servers\' + '*.msg', faAnyFile - faDirectory, sr) = 0 then
      repeat
        Delete_File(ExtractFilePath(ParamStr(0)) + 'Data\Servers\' + RtcWideString(sr.name));
      until (FindNext(sr) <> 0);
  finally
    FindClose(sr);
  end;

  try
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\');
    if (not DirectoryExists(ExtractFilePath(ParamStr(0)) + 'Data\Clients\')) then
      CreateDir(ExtractFilePath(ParamStr(0)) + 'Data\Clients\');

    if FindFirst(ExtractFilePath(ParamStr(0)) + 'Data\Clients\' + '*.msg', faAnyFile - faDirectory, sr) = 0 then
      repeat
        Delete_File(ExtractFilePath(ParamStr(0)) + 'Data\Clients\' + RtcWideString(sr.name));
      until (FindNext(sr) <> 0);
  finally
    FindClose(sr);
  end;
end;

procedure TfGateway.rDoServerLoginExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  i, j: Integer;
  pData: PServerData;
begin
  CS.Acquire;
  try
    if (serversInfo.Child[Param.asString['address']] <> nil) then
    begin
      pData := PServerData(serversInfo.Child[Param.asString['address']].asPtr['data']);
      pData^.strategiesInfo.Clear;
      for j := 0 to Param.asRecord['strategies'].FieldCount - 1 do
        pData^.strategiesInfo.NewChild(Param.asRecord['strategies'].asString[Param.asRecord['strategies'].FieldName[j]]);
      pData^.subscriptionsCount := Param.asInteger['subscriptionsCount'];
      pData^.lastPing := Now;
    end
    else
    begin
      New(pData);
      pData^.address := Param.asString['address'];
      pData^.strategiesInfo := TRtcInfo.Create;
      for j := 0 to Param.asRecord['strategies'].FieldCount - 1 do
         pData^.strategiesInfo.NewChild(Param.asRecord['strategies'].asString[Param.asRecord['strategies'].FieldName[j]]);
      pData^.subscriptionsCount := Param.asInteger['subscriptionsCount'];
      pData^.lastPing := Now;
      serversList.Add(pData);
      serversInfo.NewChild(Param.asString['address']).asPtr['data'] := pData;
    end;

    ClearServerMessageFile(Param.asString['address']);

    xLog('Server connected: ' + Param.asString['address']);

    FillServersTable;

    Result.asBoolean := True;
  finally
    CS.Release;
  end;
end;

procedure TfGateway.rGetConnectionDataExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  i, min: Integer;
  strategyActive: Boolean;
  lastRun: TDateTime;
  apiKey, apiSecret: String;
begin
  CS.Acquire;
  try
    with Result.NewRecord do
    begin
      asBoolean['result'] := False;
      strategyActive := False;

      //≈сли не прошло runRetryTimeout, то ищем сервер, на который уже отправлена команда создани€ стратегии
      //или на котором стратеги€ уже запущена
      GetStrategyDataFromDB(Param.asString['strategyId'], apiKey, apiSecret, strategyActive, lastRun);
      if (lastRun > (IncMillisecond(Now, -runRetryTimeout))) then
      begin
        for i := 0 to serversList.Count - 1 do
          if (PServerData(serversList[i])^.strategiesInfo.Child[Param.asString['strategyId']] <> nil) then
          begin
            asBoolean['result'] := True;
            asString['address'] := PServerData(serversList[i])^.address;
            asString['apiKey'] := apiKey;
            asString['apiSecret'] := apiSecret;
            asBoolean['strategyActive'] := strategyActive;
            Exit;
          end;
      end;

      //≈сли runRetryTimeout прошло выдаем наименее загруженный сервер
      //(определ€етс€ по количеству подключенных пользователей и стратегий)
      if serversList.Count > 0 then
      begin
        min := PServerData(serversList[0])^.subscriptionsCount + PServerData(serversList[0])^.strategiesInfo.Count;
        asBoolean['result'] := True;
        asString['address'] := PServerData(serversList[0])^.address;
        asString['apiKey'] := apiKey;
        asString['apiSecret'] := apiSecret;
        asBoolean['strategyActive'] := strategyActive;
      end;
      for i := 0 to serversList.Count - 1 do
        if min < (PServerData(serversList[i])^.subscriptionsCount + PServerData(serversList[i])^.strategiesInfo.Count) then
        begin
          min := (PServerData(serversList[i])^.subscriptionsCount + PServerData(serversList[i])^.strategiesInfo.Count);
          asBoolean['result'] := True;
          asString['address'] := PServerData(serversList[i])^.address;
          asString['apiKey'] := apiKey;
          asString['apiSecret'] := apiSecret;
          asBoolean['strategyActive'] := strategyActive;
        end;
    end;
  finally
    CS.Release;
  end;
end;

procedure TfGateway.rStrategiesChangesExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  i, j: Integer;
  fFound: Boolean;
  pData: PServerData;
begin
  CS.Acquire;

  Result.asBoolean := False;

  try
    if serversInfo.Child[Param.asString['address']] <> nil then
    begin
      pData := PServerData(serversInfo.Child[Param.asString['address']].asPtr['data']);

      if (Param.asString['action'] = 'Add') then
      begin
        if (pData^.strategiesInfo.Child[Param.asString['strategy']] = nil) then
           pData^.strategiesInfo.NewChild(Param.asString['strategy']);

        Result.asBoolean := True;
      end
      else
      if (Param.asString['action'] = 'Remove') then
      begin
        if (pData^.strategiesInfo.Child[Param.asString['strategy']] <> nil) then
           pData^.strategiesInfo.SetNil(Param.asString['strategy']);

        Result.asBoolean := True;
      end
      else
      if (Param.asString['action'] = 'Users') then
      begin
        PServerData(serversList[i])^.subscriptionsCount := Param.asInteger['subscriptionsCount'];

        Result.asBoolean := True;
      end;
    end
    else
      xLog('rStrategiesChangeExecute Server not found: ' + Param.asString['address']);
  finally
    CS.Release;
  end;
end;

procedure TfGateway.GetStrategyDataFromDB(strategyId: String; var apiKey, apiSecret: String; var strategyActive: Boolean; var lastRun: TDateTime);
var
  SP: TFDStoredProc;
  i: Integer;
  fFound: Boolean;
begin
  SP := TFDStoredProc.Create(nil);

  try
    if not Conn.Connected then
      Conn.Connected := True;

    SP := TFDStoredProc.Create(Self);
    try
      SP.Connection := Conn;
      SP.StoredProcName := 'Strategy_GetData';
      SP.Prepare;
      SP.Params.ParamByName('@strategyId').Value := strategyId;
      SP.ExecProc;

      if SP.Params.ParamByName('@active').Value = 1 then
        strategyActive := True
      else
        strategyActive := False;
      apiKey := SP.Params.ParamByName('@apiKey').Value;
      apiSecret := SP.Params.ParamByName('@apiSecret').Value;      
      if not VarIsNull(SP.Params.ParamByName('@lastRun').Value) then
        lastRun := SP.Params.ParamByName('@lastRun').Value
      else
        lastRun := IncDay(Now, -1);
    except
      on E: Exception do
        xLog('GetStrategyState Error: ' + e.Message);
    end;
  finally
    SP.Free;
  end;
end;

procedure TfGateway.FillServersTable;
var
  i: Integer;
begin
  CS.Acquire;
  try
    if (sgServers = nil) then
      Exit;

    sgServers.BeginUpdate;

    sgServers.RowCount := serversList.Count + 1;
    for i := 0 to serversList.Count - 1 do
    begin
      sgServers.Cells[0, i + 1] := PServerData(serversList[i])^.address;
      sgServers.Cells[1, i + 1] := IntToStr(PServerData(serversList[i])^.strategiesInfo.Count);
      sgServers.Cells[2, i + 1] := IntToStr(PServerData(serversList[i])^.subscriptionsCount);
    end;

    if sgServers.RowCount > 1 then
      sgServers.FixedRows := 1;

    sgServers.SortIndexes.Clear;
    sgServers.SortIndexes.AddIndex(0, True);
    sgServers.QSortIndexed;

    sgServers.EndUpdate;
  finally
    CS.Release;
  end;
end;

procedure TfGateway.FormCreate(Sender: TObject);
begin
  RTC_LOGS_LIVE_DAYS := 30;
  StartLog;

  serversList := TList.Create;
  serversInfo := TRtcInfo.Create;

  tCPThread := TCheckPingsThread.Create(True);
  tCPThread.FillServersTable := FillServersTable;
  tCPThread.FreeOnTerminate := False;

  tsState.ThumbColor := RGB(235, 55, 71);

  sgServers.ColCount := 3;
  sgServers.Cells[0, 0] := 'address';
  sgServers.Cells[1, 0] := 'strategiesCount';
  sgServers.Cells[2, 0] := 'subscriptionsCount';
//  sgServers.Cells[3, 0] := 'lastPing';

  LoadSettings;
end;

procedure TfGateway.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  CS.Acquire;
  try
    tCPThread.Terminate;

    for i := 0 to serversList.Count - 1 do
    begin
      PServerData(serversList[i]).strategiesInfo.Free;
      Dispose(PServerData(serversList[i]));
    end;
    FreeAndNil(serversInfo);
    FreeAndNil(serversList);
  finally
    CS.Release;
  end;
end;

procedure TfGateway.rApiKeysIsActiveStrategyExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TFDStoredProc;
  i: Integer;
  fFound: Boolean;
begin
  CS.Acquire;
  try
    //ƒеактиваци€ в базе данных по запросу от сервера или клиента
    SP := TFDStoredProc.Create(nil);

    with Result do
    begin
      asBoolean := False;

      try
        if not Conn.Connected then
          Conn.Connected := True;

        SP := TFDStoredProc.Create(Self);
        try
          SP.Connection := Conn;
          SP.StoredProcName := 'ApiKeysIsActiveStrategy';
          SP.Prepare;
          SP.Params.ParamByName('@apiKey').Value := Param.asString['apiKey'];
          SP.Params.ParamByName('@apiSecret').Value := Param.asString['apiSecret'];
          SP.ExecProc;

          asBoolean := (not VarIsNull(SP.Params.ParamByName('@id').Value));
        except
          on E: Exception do
            xLog('rApiKeysIsActiveStrategyExecute Error: ' + e.Message);
        end;
      finally
        SP.Free;
      end;
    end;
  finally
    CS.Release;
  end;
end;

procedure TfGateway.rClientPingExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  CS.Acquire;
  try
    Result.asLargeInt := GetLastClientChanges(Param.asString['subscriptionId']);
  finally
    CS.Release;
  end;
end;

procedure TfGateway.rDeactivateStrategyExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TFDStoredProc;
  i: Integer;
  fFound: Boolean;
begin
  CS.Acquire;
  try
    //ƒеактиваци€ в базе данных по запросу от сервера или клиента
    SP := TFDStoredProc.Create(nil);

    with Result.NewRecord do
    begin
      asBoolean['result'] := False;

      try
        if not Conn.Connected then
          Conn.Connected := True;

        SP := TFDStoredProc.Create(Self);
        try
          SP.Connection := Conn;
          SP.StoredProcName := 'Strategy_Deactivate';
          SP.Prepare;
          SP.Params.ParamByName('@strategyId').Value := Param.asString['strategyId'];
          SP.Params.ParamByName('@state').Value := Param.asString['state'];
          SP.ExecProc;

          asBoolean['result'] := True;
        except
          on E: Exception do
            xLog('rDeactivateStrategyExecute Error: ' + e.Message);
        end;
      finally
        SP.Free;
      end;
    end;

    //ќповещаем сервера, на которых запущена стратеги€ о ее деактивации
    for i := 0 to serversList.Count - 1 do
      if (PServerData(serversList[i])^.strategiesInfo.Child[Param.asString['strategyId']] <> nil) then
        AppendServerMessageFile(PServerData(serversList[i])^.address, Param.asString['strategyId']);
  finally
    CS.Release;
  end;
end;

procedure TCheckPingsThread.Execute;
var
  i: Integer;
begin
  while not Terminated do
  begin
    CS.Acquire;
    try
      i := serversList.Count - 1;
      while i >= 0 do
      begin
        if (PServerData(serversList[i])^.lastPing < (IncMillisecond(Now, -pingTimeout))) then
        begin
          OnServerDisconnect(PServerData(serversList[i])^.address);

          PServerData(serversList[i]).strategiesInfo.Free;
          serversInfo.SetNil(PServerData(serversList[i])^.address);
          Dispose(PServerData(serversList[i]));
          serversList.Delete(i);
        end;

        i := i - 1;
      end;
    finally
      CS.Release;
    end;

    if not Terminated then
    try
      Synchronize(FillServersTable);
    finally
    end;

    Sleep(1000);
  end;
end;

procedure TCheckPingsThread.OnServerDisconnect(address: String);
begin
  xLog('Server disconnected: ' + address);
end;

procedure TfGateway.rServerPingExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  i: Integer;
begin
  CS.Acquire;
  try
    with Result.NewRecord do
    begin
      if (serversInfo.Child[Param.asString['address']] <> nil) then
      begin
        PServerData(serversInfo.Child[Param.asString['address']].asPtr['data'])^.lastPing := Now;
        asBoolean['needLogin'] := False;
        asString['msg'] := GetServerMessageFileContents(Param.asString['address']);
        ClearServerMessageFile(Param.asString['address']);

        xLog('Server ping: ' + Param.asString['address']);
      end
      else
      begin
        asBoolean['needLogin'] := True;
      end;
    end;
  finally
    Cs.Release;
  end;
end;

procedure TfGateway.rDoAccountLoginExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TFDStoredProc;
  i: Integer;
begin
  CS.Acquire;
  try
    SP := TFDStoredProc.Create(nil);

    With Result.NewRecord do
    begin
      asBoolean['result'] := False;

      try
        if not Conn.Connected then
          Conn.Connected := True;

        SP := TFDStoredProc.Create(Self);
        try
          SP.Connection := Conn;
          SP.StoredProcName := 'Account_DoLogin';
          SP.Prepare;
          SP.Params.ParamByName('@email').Value := Param.asString['email'];
          SP.Params.ParamByName('@password').Value := Param.asString['password'];
          SP.ExecProc;

          if (not VarIsNull(SP.Params.ParamByName('@id').AsString)) then
          begin
            asBoolean['result'] := True;
            asString['accountId'] := SP.Params.ParamByName('@id').AsString;
            asLargeInt['lastChanges'] := GetLastClientChanges(SP.Params.ParamByName('@id').AsString);
          end
          else
            asBoolean['result'] := False;
        except
          on E: Exception do
            xLog('rDoAccountLoginExecute Error: ' + e.Message);
        end;
      finally
        SP.Free;
      end;
    end;
  finally
    CS.Release;
  end;
end;

function GetCurrentTimestamp: Int64;
begin
  Sleep(10);

  Result := MilliSecondsBetween(Now, EncodeDate(1970, 1, 1));
end;

procedure TfGateway.fGetNotificationsExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TFDStoredProc;
  i: Integer;
begin
  CS.Acquire;
  try
    SP := TFDStoredProc.Create(nil);

    try
      if not Conn.Connected then
        Conn.Connected := True;

      SP := TFDStoredProc.Create(Self);
      try
        SP.Connection := Conn;
        SP.StoredProcName := 'Notifications_Get';
        SP.Prepare;
        SP.Params.ParamByName('@accountId').Value := Param.asString['accountId'];
        SP.Open;

        with Result.NewDataSet do
        begin
          FieldType['chatId'] := ft_String;
          SP.FindFirst;
          for i := 0 to SP.RecordCount - 1 do
          begin
            Append;

            asString['chatId'] := SP.FieldByName('chatId').Value;
            SP.Next;
          end;
        end;
      except
        on E: Exception do
          xLog('fGetNotificationsExecute Error: ' + e.Message);
      end;
    finally
      SP.Free;
    end;
  finally
    CS.Release;
  end;
end;

procedure TfGateway.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  SaveSettings;

  StopLog;
end;

procedure TfGateway.rGetSubscriptionsExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  SP: TFDStoredProc;
  i: Integer;
begin
  CS.Acquire;
  try
    SP := TFDStoredProc.Create(nil);

    try
      if not Conn.Connected then
        Conn.Connected := True;

      SP := TFDStoredProc.Create(Self);
      try
        SP.Connection := Conn;
        SP.StoredProcName := 'Subscriptions_Get';
        SP.Prepare;
        SP.Params.ParamByName('@accountId').Value := Param.asString['accountId'];
        SP.Open;

        with Result.NewDataSet do
        begin
          FieldType['strategyId'] := ft_String;
          FieldType['name'] := ft_String;
          FieldType['endDate'] := ft_DateTime;
          FieldType['status'] := ft_String;
          FieldType['maxMultiplier'] := ft_Float;
          SP.FindFirst;
          for i := 0 to SP.RecordCount - 1 do
          begin
            Append;

            asString['strategyId'] := SP.FieldByName('strategyId').Value;
            asString['name'] := SP.FieldByName('name').Value;
            asDateTime['endDate'] := SP.FieldByName('endDate').Value;
            asString['status'] := SP.FieldByName('status').Value;
            asFloat['maxMultiplier'] := SP.FieldByName('maxMultiplier').Value;
            SP.Next;
          end;
        end;
      except
        on E: Exception do
          xLog('rGetSubscriptionsExecute Error: ' + e.Message);
      end;
    finally
      SP.Free;
    end;
  finally
    CS.Release;
  end;
end;

procedure TfGateway.rSubscriptionIsActiveExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
begin
  Result.asBoolean := (Param.asDateTime['endDate'] > Now);
end;

procedure TfGateway.tsStateClick(Sender: TObject);
begin
  tsState.Enabled := False;

  DeleteOldDataFiles;

  if tsState.State = tssOn then
  begin
    DoStart;
  end
  else
  begin
    DoStop;
  end;

  tsState.Enabled := True;
end;

procedure TfGateway.DoStart;
begin
  try
    Conn.Connected := True;

    Server.ServerAddr := eAddress.Text;
    Server.Listen(True);
  except
    on E: Exception do
    begin
      xLog('tsStateClick Error: ' + e.Message);
      Server.StopListen;
      Conn.Connected := False;

      Exit;
    end;
  end;

  tsState.ThumbColor := RGB(33, 115, 56);

  tCPThread.Resume;
end;

procedure TfGateway.DoStop;
var
  i: Integer;
begin
  tCPThread.Suspend;

  Server.StopListen;

  Conn.Connected := False;

  for i := 0 to serversList.Count - 1 do
  begin
    PServerData(serversList[i]).strategiesInfo.Free;
    Dispose(PServerData(serversList[i]));
  end;
  serversList.Clear;
  serversInfo.Clear;
  FillServersTable;

  tsState.ThumbColor := RGB(235, 55, 71);
end;

procedure TfGateway.LoadSettings;
var
  oJSON: TsgcJSON;
  s: String;
  i, j: Integer;
  val: Extended;
  fFound: Boolean;
begin
  if not FileExists(SysUtils.ChangeFileExt(ParamStr(0), '.cfg')) then
    Exit;

  oJSON := TsgcJSON.Create(nil);
  try
    s := TFile.ReadAllText(SysUtils.ChangeFileExt(ParamStr(0), '.cfg'));
    oJSON.Read(s);

    if (oJSON.Node['Address'] <> nil) then
      eAddress.Text := oJSON.Node['Address'].Value;
  finally
    FreeAndNil(oJSON)
  end;
end;

procedure TfGateway.SaveSettings;
var
  oJSON: TsgcJSON;
begin
  oJSON := TsgcJSON.Create(nil);
  try
    oJSON.AddPair('Address', eAddress.Text);
    TFile.WriteAllText(SysUtils.ChangeFileExt(ParamStr(0), '.cfg'), oJSON.Text);
  finally
    FreeAndNil(oJSON)
  end;
end;

function TfGateway.GetLastClientChanges(accountId: String): Int64;
var
  s: String;
  i: Int64;
begin
  CS.Acquire;
  try
    s := GetClientMessageFileContents(accountId);
    if TryStrToInt64(s, i) then
      Result := i
    else
      Result := 0;
  finally
    CS.Release;
  end;
end;

initialization
  CS := TCriticalSection.Create;

finalization
  FreeAndNil(CS);

end.
