unit DMManager;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Phys, FireDAC.FMXUI.Wait,
  FireDAC.Moni.FlatFile, FireDAC.Moni.Base, FireDAC.Moni.RemoteClient, FireDAC.Comp.UI,
  FireDAC.Comp.Client, FireDAC.Phys.ASADef, FireDAC.Phys.PGDef, FireDAC.Phys.MySQLDef,
  FireDAC.Phys.ODBCDef, FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite,
  FireDAC.Phys.ODBC, FireDAC.Phys.MySQL, FireDAC.Phys.PG, FireDAC.Phys.ODBCBase, FireDAC.Phys.ASA,

  Constantes, FireDAC.Phys.FBDef, FireDAC.Phys.IBBase, FireDAC.Phys.FB, System.IniFiles
  , FireDAC.Phys.SQLiteWrapper.Stat
  {$IFDEF MSWINDOWS}
    , VCL.Dialogs
  {$ENDIF};

type
  TConnManager = class(TDataModule)
    FDManager: TFDManager;
    WaitCursor: TFDGUIxWaitCursor;
    RemoteLog: TFDMoniRemoteClientLink;
    FileLog: TFDMoniFlatFileClientLink;
    SybaseLink: TFDPhysASADriverLink;
    PostgreLink: TFDPhysPgDriverLink;
    MySQLLink: TFDPhysMySQLDriverLink;
    ODBCLink: TFDPhysODBCDriverLink;
    SQLLiteLink: TFDPhysSQLiteDriverLink;
    FirebirdLink: TFDPhysFBDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
    Default_Database : string;
    Default_Monitor : TFDMonitorBy;
    procedure CarregarLibs;
    procedure CarregarManager;
    procedure CarregarLocalCFG;
  public
    { Public declarations }
    function GetDefaultMonitor : TFDMonitorBy;
    procedure SetDefaultMonitor(AMonitor : TFDMonitorBy);
    function GetTipoBancoDados(AConexao : String = '') : String;
    function GetDefaultDatabase : String;
  end;

var
  ConnManager: TConnManager;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

uses LogModulo;

{$R *.dfm}

procedure TConnManager.CarregarLibs;
var
  PGDriver, SMySQLDriver, SFirebirdDriver : string;
begin
  try
    PGDriver := PostgreDriver;
    if not FecharAplicacao then
      begin
        if not FileExists(PGDriver) then
          begin
            raise Exception.Create('Cliente de Conexão PostgreSQL não encontrado: "'+
              PGDriver+'"');
          end
        else
          begin
            PostgreLink.VendorLib := PGDriver;
            PostgreLink.VendorLib := PostgreLink.VendorLib.Replace('\\','\');
          end;
      end;

    SMySQLDriver := MySQLDriver;
    if not FecharAplicacao then
      begin
        if not FileExists(SMySQLDriver) then
          begin
            raise Exception.Create('Cliente de Conexão MySQL não encontrado: "'+
              SMySQLDriver+'"');
          end
        else
          begin
            MySQLLink.VendorLib := SMySQLDriver;
            MySQLLink.VendorLib := MySQLLink.VendorLib.Replace('\\','\');
          end;
      end;

    SFirebirdDriver := FirebirdDriver;
    if not FecharAplicacao then
      begin
        if not FileExists(SFirebirdDriver) then
          begin
            raise Exception.Create('Cliente de Conexão Firebird não encontrado: "'+
              SFirebirdDriver+'"');
          end
        else
          begin
            FirebirdLink.VendorLib := SFirebirdDriver;
            FirebirdLink.VendorLib := FirebirdLink.VendorLib.Replace('\\','\');
          end;
      end;
  except
    on e : Exception do
      begin
        FecharAplicacao := SIM;
        {$IFDEF MSWINDOWS}
          MessageDlg(e.Message, mtError, [mbOK], 0);
        {$ENDIF}

        TLogModulo.SistemaLog.LogarBancoDados([
          'ERRO AO CARREGAR DRIVER',
          e.Message
        ]);
      end;
  end;
end;

procedure TConnManager.CarregarLocalCFG;
var
  LocalCFG : string;
  IniLocalCFG : TIniFile;
  IntDefMon : Integer;
begin
  try
    LocalCFG := PastaExecutavel+'localcfg.ini';
    if not FileExists(LocalCFG) then
      begin
        LocalCFG := PastaTemporaria+'localcfg.ini';
        if not FileExists(LocalCFG) then
          begin
            LocalCFG := PASTA_BDLIBS+'localcfg.ini';
            if not FileExists(LocalCFG) then
              raise Exception.Create('Arquivo de Configuração Local não encontrado!');
          end;
      end;

    IniLocalCFG := TIniFile.Create(LocalCFG);
    Self.Default_Database := IniLocalCFG.ReadString('CONFIGURACAO','DEFBD',EmptyStr);

    if Self.Default_Database.IsEmpty then
      raise Exception.Create('Conexão padrão não foi definida no arquivo: "'+LocalCFG+'"');

    IntDefMon := IniLocalCFG.ReadInteger('CONFIGURACAO','MONITOR',0);
    case IntDefMon of
      0 : Self.SetDefaultMonitor(mbNone);
      1 : Self.SetDefaultMonitor(mbFlatFile);
      2 : Self.SetDefaultMonitor(mbRemote);
    end;
  except
    on e : exception do
      begin
        FecharAplicacao := SIM;
        {$IFDEF MSWINDOWS}
          MessageDlg(e.Message, mtError, [mbOK], 0);
        {$ENDIF}
        TLogModulo.SistemaLog.LogarSistema([
          'ERRO AO CARREGAR O ARQUIVO DE CONFIGURAÇÃO PADRÃO',
          e.Message,
          'Arquivo: '+LocalCFG
        ]);
      end;
  end;
end;

procedure TConnManager.CarregarManager;
var
  ManagerLocal : string;
begin
  ManagerLocal := ArquivoCFGManager;
  if not FecharAplicacao then
    begin
      if not FDManager.ConnectionDefFileLoaded then
        begin
          FDManager.Active := NAO;
          FDManager.ConnectionDefFileName := ManagerLocal;
          FDManager.LoadConnectionDefFile;
          FDManager.Active := SIM;
        end;
    end;

end;

procedure TConnManager.DataModuleCreate(Sender: TObject);
begin
  FecharAplicacao := False;
  SetDefaultMonitor(mbNone);
  CarregarLibs;
  CarregarManager;
  CarregarLocalCFG;
end;

function TConnManager.GetDefaultDatabase: String;
begin
  Result := Self.Default_Database;
end;

function TConnManager.GetDefaultMonitor: TFDMonitorBy;
begin
  Result := Default_Monitor;
end;

function TConnManager.GetTipoBancoDados(AConexao: String): String;
var
  ODef: IFDStanConnectionDef;
begin
  if AConexao = EmptyStr then
    ODef := FDManager.ConnectionDefs.ConnectionDefByName(Self.Default_Database)
  else
    ODef := FDManager.ConnectionDefs.ConnectionDefByName(AConexao);

  Result := ODef.Params.DriverID;
end;

procedure TConnManager.SetDefaultMonitor(AMonitor: TFDMonitorBy);
begin
  FileLog.Tracing := False;
  RemoteLog.Tracing := False;
  Self.Default_Monitor := AMonitor;

  case Self.Default_Monitor of
    mbFlatFile: FileLog.Tracing := True;
    mbRemote: RemoteLog.Tracing := True;
  end;
end;

end.
