unit LogModulo;

interface
uses System.JSON, System.Classes, System.StrUtils, System.IOUtils, System.Math,
     System.SysUtils, Constantes
     {$IFDEF MSWINDOWS}
      , VCL.Dialogs
     {$ENDIF};

type
  {$M+}
  TLogModulo = class
    strict private
      class var FInstancia : TLogModulo;
      class var FModuloAtivo: Boolean;
    private
      FLocalLogBD : string;
      FLocalLogSys : string;
      FLocalLogDebug : string;
      FArquivoLogBD : TextFile;
      FArquivoLogSys : TextFile;
      FArquivoLogDebug : TextFile;
      FNomeModulo: String;
      FNomeConexao: String;

      procedure InformarLocalArquivos;

      procedure AtribuirArquivoLogBD;
      procedure AtribuirArquivoLogSys;
      procedure AtribuirArquivoLogDebug;
      procedure LiberarArquivoLogBD;
      procedure LiberarArquivoLogSys;
      procedure LiberarArquivoLogDebug;

      constructor CreatePrivate;
    public
      class function SistemaLog : TLogModulo;
      class procedure Registrar;
      destructor Destroy; override;

      class procedure LogarBancoDados(ADados : TArray<String>);
      class procedure LogarSistema(ADados : TArray<String>);
      class procedure LogarDebug(ADados : TArray<String>);
    published
      property NomeModulo: String read FNomeModulo write FNomeModulo;
      property NomeConexao: String read FNomeConexao write FNomeConexao;
  end;

implementation

{ TLogModulo }

procedure TLogModulo.AtribuirArquivoLogBD;
begin
  InformarLocalArquivos;
  AssignFile(FArquivoLogBD, FLocalLogBD);
  {$I-}
    Append(FArquivoLogBD);
  {$I+}
  if IOResult <> 0 then
    begin
      Rewrite(FArquivoLogBD);
    end;
end;

procedure TLogModulo.AtribuirArquivoLogDebug;
begin
  InformarLocalArquivos;
  AssignFile(FArquivoLogDebug, FLocalLogDebug);
  {$I-}
    Append(FArquivoLogDebug);
  {$I+}
  if IOResult <> 0 then
    begin
      Rewrite(FArquivoLogDebug);
    end;
end;

procedure TLogModulo.AtribuirArquivoLogSys;
begin
  InformarLocalArquivos;
  AssignFile(FArquivoLogSys, FLocalLogSys);
  {$I-}
    Append(FArquivoLogSys);
  {$I+}
  if IOResult <> 0 then
    begin
      Rewrite(FArquivoLogSys);
    end;
end;

constructor TLogModulo.CreatePrivate;
begin
  try
    Self.FModuloAtivo := NAO;
  except
    on e : Exception do
      begin
        {$IFDEF MSWINDOWS}
          MessageDlg('Não foi possível Iniciar a estrutura de LOGs do sistema:'+#13+
          'Mensagem:"'+e.Message+'"',mtError,[mbOK],0);
        {$ENDIF}
      end;
  end;
end;

destructor TLogModulo.Destroy;
begin
  LiberarArquivoLogBD;
  LiberarArquivoLogSys;
  inherited;
end;

procedure TLogModulo.InformarLocalArquivos;
var
  TmpLocal, NomeArquivoBD, NomeArquivoSys,
  NomeArquivoDebug, nomeContar, SContador : string;
  Contador : Integer;
begin
  Self.FLocalLogBD := EmptyStr;
  Self.FLocalLogSys := EmptyStr;
  Self.FLocalLogDebug := EmptyStr;

  Contador := 1;
  SContador := FormatFloat('0000000000', Contador);

  TmpLocal := TPath.GetTempPath;
  NomeArquivoBD := Format(NOME_LOG_BD,[Self.FNomeModulo+'_'+Self.FNomeConexao, SContador]);
  NomeArquivoSys := Format(NOME_LOG_SYS,[Self.FNomeModulo, SContador]);
  NomeArquivoDebug := Format(NOME_LOG_DBG, [Self.FNomeModulo+'_'+FormatDateTime('ddmmyyyyhhnnsszzz', now)]);
  nomeContar := NomeArquivoDebug;

  if FileExists(TmpLocal+nomeContar+'.dbg') then
    begin
      while FileExists(TmpLocal+nomeContar+'_'+Contador.ToString+'.dbg') do
        begin
          Contador := Contador + 1;
        end;

      NomeArquivoDebug := nomeContar+'_'+Contador.ToString+'.dbg';
    end;
  Self.FLocalLogBD := TPath.Combine(TmpLocal, NomeArquivoBD);
  Self.FLocalLogSys := TPath.Combine(TmpLocal, NomeArquivoSys);
  Self.FLocalLogDebug := TPath.Combine(TmpLocal, NomeArquivoDebug);
end;

procedure TLogModulo.LiberarArquivoLogBD;
begin
  AssignFile(FArquivoLogBD, FLocalLogBD);
  {$I-}
    Append(FArquivoLogBD);
  {$I+}
  if IOResult = 0 then
    begin
      CloseFile(FArquivoLogBD);
    end;
end;

procedure TLogModulo.LiberarArquivoLogDebug;
begin
  AssignFile(FArquivoLogDebug, FLocalLogDebug);
  {$I-}
    Append(FArquivoLogDebug);
  {$I+}
  if IOResult = 0 then
    begin
      CloseFile(FArquivoLogDebug);
    end;
end;

procedure TLogModulo.LiberarArquivoLogSys;
begin
  AssignFile(FArquivoLogSys, FLocalLogSys);
  {$I-}
    Append(FArquivoLogSys);
  {$I+}
  if IOResult = 0 then
    begin
      CloseFile(FArquivoLogSys);
    end;
end;

class procedure TLogModulo.LogarBancoDados(ADados: TArray<String>);
var
  LinhaLog : String;
  StrDataHora : String;
begin
  LinhaLog := EmptyStr;
  StrDataHora := FormatDateTime('dd/mm/yyyy hh:nn:ss', NOW);
  SistemaLog.AtribuirArquivoLogBD;

  LinhaLog := StrDataHora + ' - ' + ConcatenarArray(ADados);
  Writeln(SistemaLog.FArquivoLogBD, LinhaLog);
  CloseFile(SistemaLog.FArquivoLogBD);
end;

class procedure TLogModulo.LogarDebug(ADados: TArray<String>);
var
  LinhaLog : String;
  StrDataHora : String;
begin
  LinhaLog := EmptyStr;
  StrDataHora := FormatDateTime('dd/mm/yyyy hh:nn:ss', NOW);
  SistemaLog.AtribuirArquivoLogDebug;

  LinhaLog := 'CRIAÇÃO DO LOG => '+ StrDataHora;
  Writeln(SistemaLog.FArquivoLogDebug, LinhaLog);
  LinhaLog := EmptyStr;
  for LinhaLog in ADados do
    begin
      Writeln(SistemaLog.FArquivoLogDebug, LinhaLog);
    end;
  CloseFile(SistemaLog.FArquivoLogDebug);
end;

class procedure TLogModulo.LogarSistema(ADados: TArray<String>);
var
  LinhaLog : String;
  StrDataHora : String;
begin
  LinhaLog := EmptyStr;
  StrDataHora := FormatDateTime('dd/mm/yyyy hh:nn:ss', NOW);
  SistemaLog.AtribuirArquivoLogSys;

  LinhaLog := StrDataHora + ' - ' + ConcatenarArray(ADados);
  Writeln(SistemaLog.FArquivoLogSys, LinhaLog);
  CloseFile(SistemaLog.FArquivoLogSys);
end;

class procedure TLogModulo.Registrar;
begin
  SistemaLog.FModuloAtivo := SIM;
end;

class function TLogModulo.SistemaLog : TLogModulo;
begin
  if not Assigned(FInstancia) then
    Self.FInstancia := TLogModulo.CreatePrivate;

  Result := FInstancia;
end;

end.
