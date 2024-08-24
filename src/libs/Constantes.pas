unit Constantes;

interface
uses System.IOUtils, System.Classes, System.StrUtils, System.SysUtils, System.UITypes
  {$IFDEF MSWINDOWS}
    , VCL.Dialogs
  {$ENDIF};

const
  DEF_CONN_SYBASE = 'SIHL_ASA';
  DEF_CONN_MYSQL = 'SIHL_MYSQL';
  DEF_CONN_POSTGRE = 'SIHL_PG';
  DEF_CONN_ODBC = 'SIHL_ODBC';
  DEF_CONN_SQLITE = 'SIHL_SQLITE';
  DEF_CONN_FB = 'SISAIHSUS';

  ID_SYBASE = 'ASA';
  ID_MYSQL = 'MySQL';
  ID_POSTGRE = 'PG';
  ID_ODBC = 'ODBC';
  ID_SQLITE = 'SQLite';
  ID_FB = 'FB';

  PASTA_SIHL = 'C:\SIHL\SVC\';
  PASTA_LOG = PASTA_SIHL+'LOGERROS\';
  PASTA_DEBUG = PASTA_SIHL+'DEBUG\';
  PASTA_BDLIBS = PASTA_SIHL+'DRIVER\';

  NOME_LOG_BD = 'LogBancoDados_%s_%s.log';
  NOME_LOG_SYS = 'LogSistema_%s_%s.log';
  NOME_LOG_DBG = 'Debug_%s.dbg';

  RESULT_PARSER = '{"idMsg":"%s","msgExecucao":"%s","sqlTentativa":"%s","status":"%s"}';

  STATUS_PARSER_OK = 'OK';
  STATUS_PARSER_ERRO = 'ERRO';

  SIM = True;
  NAO = False;

type
  TAcaoParcer = (apSelecionar, apComandoSimples, apComandoComplexo, apAtivar);


var
  FecharAplicacao : Boolean;
  QtdeTentativasReconexao : Integer;

function ConcatenarArray(StringArray : TArray<String>; Separador : string = ' - ') : String;
function PastaTemporaria : string;
function PastaExecutavel : string;
function WindowsRoot : string;
function PostgreDriver : string;
function MySQLDriver : string;
function FirebirdDriver : string;
function DriverCliente(Cliente : string) : string;
function ArquivoCFGManager : String;

implementation
uses LogModulo;

function ConcatenarArray(StringArray : TArray<String>; Separador : string = ' - ') : String;
var
  IArray : Integer;
begin
  Result := EmptyStr;
  for IArray := 0 to Length(StringArray)-1 do
    begin
      Result := Result + StringArray[IArray] +
        IfThen(IArray < (Length(StringArray)-1), Separador, EmptyStr);
    end;
end;

function PastaTemporaria : string;
begin
  Result := TPath.GetTempPath;
end;

function PastaExecutavel : string;
begin
  Result := TPath.GetDirectoryName(ParamStr(0)) + TPath.DirectorySeparatorChar;
end;

function WindowsRoot : string;
begin
  Result := TPath.GetPathRoot(PastaTemporaria) + TPath.DirectorySeparatorChar;
end;

function DriverCliente(Cliente : string) : string;
var
  NomePasta, NomeBD : string;
begin
  NomePasta := EmptyStr;
  NomeBD := EmptyStr;

  if Cliente.Equals(ID_POSTGRE) then
    begin
      NomePasta := 'postgre';
      NomeBD := 'PostgreSQL';
    end
  else if Cliente.Equals(ID_MYSQL) then
    begin
      NomePasta := 'mysql';
      NomeBD := 'MySQL/MariaDB'
    end
  else if Cliente.Equals(ID_FB) then
    begin
      NomePasta := 'firebird';
      NomeBD := 'Firebird';
    end;

  Result := NomePasta;
  try
    if TDirectory.Exists(PASTA_BDLIBS + NomePasta) then
      Result := PASTA_BDLIBS + NomePasta + TPath.DirectorySeparatorChar
    else if TDirectory.Exists(PastaExecutavel + NomePasta) then
      Result := PastaExecutavel+ NomePasta + TPath.DirectorySeparatorChar
    else if TDirectory.Exists(PastaTemporaria + NomePasta) then
      Result := PastaTemporaria + NomePasta + TPath.DirectorySeparatorChar
    else
      raise Exception.Create('Não foi possível encontrar o Driver do Cliente '+NomeBD+'!');
  except
    on e : Exception do
      begin
        FecharAplicacao := SIM;
        {$IFDEF MSWINDOWS}
          MessageDlg(e.Message, mtError, [mbOK], 0);
        {$ENDIF}
        TLogModulo.SistemaLog.LogarSistema(
          ['ERRO AO CARREGAR DRIVER',
           e.Message,
           'Pasta não encontrada: "'+Result+'"']
        );
        Result := EmptyStr;
      end;
  end;
end;

function PostgreDriver : string;
var
  NomeLib : string;
begin
  NomeLib := 'libpq.dll';
  Result := DriverCliente(ID_POSTGRE) + NomeLib;
end;

function MySQLDriver : string;
var
  NomeLib : string;
begin
  NomeLib := 'libmysql.dll';
  Result := DriverCliente(ID_MYSQL) + NomeLib;
end;

function FirebirdDriver : string;
var
  NomeLib : string;
begin
  NomeLib := 'fbclient.dll';
  Result := DriverCliente(ID_FB) + NomeLib;
end;

function ArquivoCFGManager : String;
var
  ArquivoCFG : string;
begin
  ArquivoCFG := 'cfg.ini';
  try
    if not FileExists(PastaExecutavel + ArquivoCFG) then
      begin
        if not FileExists(PASTA_BDLIBS + ArquivoCFG) then
          begin
            FecharAplicacao := SIM;
            raise Exception.Create('Arquivo de Configuração de Conexões não encontrado!');
          end
        else
          begin
            Result := PASTA_BDLIBS + ArquivoCFG;
          end;
      end
    else
      begin
        Result := PastaExecutavel + ArquivoCFG;
      end;
  except
    on e : exception do
      begin
        FecharAplicacao := SIM;
        {$IFDEF MSWINDOWS}
          MessageDlg(e.Message, mtError, [mbOK], 0);
        {$ENDIF}
        TLogModulo.SistemaLog.LogarSistema(
          ['ERRO AO CARREGAR CFG DE CONEXÕES',
            e.Message
          ]
        );
      end;
  end;
end;

end.
