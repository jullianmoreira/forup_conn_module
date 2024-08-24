unit MultiConexao;

interface

uses System.SysUtils, System.StrUtils, System.IOUtils, System.Classes,
  FireDAC.Comp.Client, Constantes, FireDAC.Stan.Intf, FireDAC.Phys.ASADef, FireDAC.Phys.MySQLDef,
  FireDAC.Phys.PGDef, FireDAC.Phys.PG, FireDAC.Phys.MySQL, FireDAC.Phys.ODBCBase,
  FireDAC.Phys.ASA, FireDAC.Phys.FB, FireDAC.Phys.IB, FireDAC.DApt, FireDAC.Stan.Async
{$IFDEF MSWINDOWS}
  , VCL.Dialogs
{$ENDIF};

type
{$M+}
  TObjetoConexao = class(TPersistent)
  private
    FConexao: TFDConnection;
    FTransacao: TFDTransaction;
    FComando: TFDCommand;
    FQuery: TFDQuery;
    FConexaoAtiva: string;
    FBancoDados: string;

    function PegarEstadoTransacao : Boolean;
    function PegarEstadoConexao : Boolean;

    procedure LimparComponentes;

  public
    constructor Criar;
    destructor Destroy; override;

    procedure Conectar;
    procedure Desconectar;
    procedure IniciarTransacao;
    procedure ConcluirTransacao;
    procedure CancelarTransacao;

    function ParseSQL(Acao : TAcaoParcer; Query : TFDQuery;
      IDErro : String = ''; MsgErro : String = ''; HabilitarTransacao : Boolean = SIM) : string; overload;
    function ParseSQL(Acao : TAcaoParcer; SQL : string;
      IDErro : String = ''; MsgErro : String = ''; HabilitarTransacao : Boolean = SIM) : string; overload;

  published
    property Conexao: TFDConnection read FConexao write FConexao;
    property Transacao: TFDTransaction read FTransacao write FTransacao;
    property Comando: TFDCommand read FComando write FComando;
    property Query: TFDQuery read FQuery write FQuery;

    property ConexaoAtiva: string read FConexaoAtiva write FConexaoAtiva;
    property BancoDados: string read FBancoDados write FBancoDados;
    property EmTransacao: Boolean read PegarEstadoTransacao;
    property Conectado: Boolean read PegarEstadoConexao;
  end;

implementation
uses LogModulo, DMManager;

{ TObjetoConexao }

procedure TObjetoConexao.CancelarTransacao;
begin
  if Self.FTransacao.Active then
    Self.FTransacao.Rollback;

  if Self.FConexao.InTransaction then
    Self.FConexao.Rollback;

end;

procedure TObjetoConexao.ConcluirTransacao;
begin
  if Self.FTransacao.Active then
    Self.FTransacao.Commit;

  if Self.FConexao.InTransaction then
    Self.FConexao.Commit;
end;

procedure TObjetoConexao.Conectar;
var
  PassWord : String;
  ODef: IFDStanConnectionDef;
  OASAParam: TFDPhysASAConnectionDefParams;
  OMySQLParam: TFDPhysMySQLConnectionDefParams;
  OPGParam: TFDPhysPGConnectionDefParams;
  OODBCParam, OFirebirdParam: TFDConnectionDefParams;
begin
  try
    ODef := ConnManager.FDManager.ConnectionDefs.FindConnectionDef(Self.FConexaoAtiva);

    with Self.FConexao do
      begin
        Close;
        if Self.FBancoDados = ID_SYBASE then
          begin
            PassWord := 'wm2404!@?';
            OASAParam := TFDPhysASAConnectionDefParams(oDef.Params);
            OASAParam.MonitorBy := ConnManager.GetDefaultMonitor;
            OASAParam.Password := PassWord;
            ConnectionDefName := Self.FConexaoAtiva;
            Params.Clear;
            Params := OASAParam;
          end
        else if Self.FBancoDados = ID_POSTGRE then
          begin
            PassWord := 'wm2404!@?';
            OPGParam := TFDPhysPGConnectionDefParams(oDef.Params);
            OPGParam.MonitorBy := ConnManager.GetDefaultMonitor;
            OPGParam.Password := PassWord;
            ConnectionDefName := Self.FConexaoAtiva;
            Params.Clear;
            Params := OPGParam;
          end
        else if Self.FBancoDados = ID_MYSQL then
          begin
            PassWord := 'suporte#wm';
            OMySQLParam := TFDPhysMySQLConnectionDefParams(oDef.Params);
            OMySQLParam.MonitorBy := ConnManager.GetDefaultMonitor;
            OMySQLParam.Password := PassWord;
            ConnectionDefName := Self.FConexaoAtiva;
            Params.Clear;
            Params := OMySQLParam;
          end
        else if Self.FBancoDados = ID_FB then
          begin
            PassWord := 'masterkey';
            OFirebirdParam := TFDConnectionDefParams(oDef.Params);
            OFirebirdParam.MonitorBy := ConnManager.GetDefaultMonitor;
            OFirebirdParam.Password := PassWord;
            ConnectionDefName := Self.FConexaoAtiva;
            Params.Clear;
            Params := OFirebirdParam;
          end;

        Connected := SIM;
      end;
  except
    on e : Exception do
      begin
        FecharAplicacao := SIM;
        {$IFDEF MSWINDOWS}
          MessageDlg(e.Message, mtError, [mbOK], 0);
        {$ENDIF}
        TLogModulo.SistemaLog.LogarBancoDados([
          'ERRO AO CONECTAR NO BANCO DE DADOS',
          e.Message,
          'NOME CONEXÃO: '+Self.FConexaoAtiva,
          'DRIVER: '+Self.FBancoDados
        ]);
      end;
  end;

end;

constructor TObjetoConexao.Criar;
begin
  inherited Create;
  Self.FTransacao := TFDTransaction.Create(nil);

  Self.FConexao := TFDConnection.Create(nil);
  Self.FConexao.Transaction := Self.Transacao;
  Self.FConexao.LoginPrompt := NAO;
  Self.FConexao.ResourceOptions.KeepConnection := SIM; //IMPLEMENTADO EM 04/07/2024
  Self.FConexao.ResourceOptions.AutoReconnect := SIM;

  Self.FTransacao.Connection := Self.FConexao;

  Self.FComando := TFDCommand.Create(nil);
  Self.FComando.Connection := Self.FConexao;

  Self.Query := TFDQuery.Create(nil);
  Self.Query.Connection := Self.FConexao;

  Self.FConexaoAtiva := ConnManager.GetDefaultDatabase;
  Self.FBancoDados := ConnManager.GetTipoBancoDados();
end;

procedure TObjetoConexao.Desconectar;
begin
  Self.FConexao.Connected := NAO;
  Self.FConexao.Close;
end;

destructor TObjetoConexao.Destroy;
begin
  Self.Desconectar;
  inherited;
end;

procedure TObjetoConexao.IniciarTransacao;
begin
  if not Self.FTransacao.Active then
    Self.FTransacao.StartTransaction
end;

procedure TObjetoConexao.LimparComponentes;
begin
  Self.FQuery.Close;
  Self.FQuery.SQL.Clear;

  Self.FComando.Close;
  Self.FComando.CommandText.Text := EmptyStr;
end;

function TObjetoConexao.ParseSQL(Acao: TAcaoParcer; Query: TFDQuery; IDErro, MsgErro: String;
  HabilitarTransacao: Boolean): string;
var
  SQL : string;
begin
  try
    try
      SQL := Query.SQL.Text;

      if Query.Connection = nil then
        Query.Connection := Self.FConexao;

      if SQL <> EmptyStr then
        Self.FComando.CommandText.Text := SQL
      else raise Exception.Create('Comando SQL não informado!');

      if HabilitarTransacao or (Acao = apAtivar) then
        IniciarTransacao;

      case Acao of
        apSelecionar: Query.Open;
        apComandoSimples: Self.FComando.Execute;
        apComandoComplexo: Self.FComando.Execute;
        apAtivar: Query.Active := SIM;
      end;

      if HabilitarTransacao or (Acao = apAtivar) then
        ConcluirTransacao;

      Result := Format(RESULT_PARSER,[
        '000', 'OK', SQL, STATUS_PARSER_OK
      ]);

    finally
      LimparComponentes;
    end;
  except
    on E : Exception do
      begin
        if EmTransacao then
          CancelarTransacao;

        Result := Format(RESULT_PARSER,[
          IDErro, MsgErro + '(' + E.Message + ')', SQL, STATUS_PARSER_ERRO
        ]);

        {$IFDEF MSWINDOWS}
          MessageDlg(e.Message, mtWarning, [mbOK], 0);
        {$ENDIF}
        TLogModulo.SistemaLog.LogarBancoDados([
          'ERRO AO PROCESSAR O COMANDO SQL',
          e.Message,
          'SQL: '+SQL
        ]);
        LimparComponentes;
      end;
  end;
end;

function TObjetoConexao.ParseSQL(Acao: TAcaoParcer; SQL, IDErro, MsgErro: String;
  HabilitarTransacao: Boolean): string;
begin
  try
    if SQL <> EmptyStr then
      begin
        Self.FQuery.SQL.Text := SQL;
        Result := ParseSQL(Acao, Self.FQuery, IDErro, MsgErro, HabilitarTransacao);
      end
    else raise Exception.Create('Comando SQL não informado!');
  except
    on E : Exception do
      begin
        {$IFDEF MSWINDOWS}
          MessageDlg(e.Message, mtWarning, [mbOK], 0);
        {$ENDIF}
        TLogModulo.SistemaLog.LogarBancoDados([
          'ERRO AO PROCESSAR O COMANDO SQL',
          e.Message
        ]);
        Result := Format(RESULT_PARSER,[
          IDErro, MsgErro + '(' + E.Message + ')', SQL, STATUS_PARSER_ERRO
        ]);
      end;
  end;
end;

function TObjetoConexao.PegarEstadoConexao: Boolean;
begin
  Result := Self.FConexao.Connected;
end;

function TObjetoConexao.PegarEstadoTransacao: Boolean;
begin
  Result := (Self.FTransacao.Active or Self.FConexao.InTransaction);
end;

end.
