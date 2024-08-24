unit GerenciadorConexoes;

interface
uses System.Classes, System.StrUtils, System.SysUtils, Generics.Collections,
MultiConexao, DMManager, Constantes
{$IFDEF MSWINDOWS}
{$ENDIF};

type
  {$M+}
  TConexoes = class(TPersistent)
    strict private
      class var FInstancia : TConexoes;
      class var FConexoes : TList<TObjetoConexao>;
      class var FModuloAtivo: Boolean;
    private
      constructor CriarInerno;
      function ConexaoAdicionada(ANome : string) : Boolean;
    public
      class function Gerenciador : TConexoes;
      class procedure Registrar;

      function Conexao(ANome : string = '') : TObjetoConexao;
      function AddConexao(ANome : string = '') : TObjetoConexao;
  end;
implementation

{ TConexoes }

function TConexoes.AddConexao(ANome : string) : TObjetoConexao;
begin
  if not ConexaoAdicionada(ANome) then
    begin
      Result := TObjetoConexao.Criar;
      if ANome.IsEmpty = NAO then
        begin
          Result.ConexaoAtiva := ANome;
          Result.BancoDados := ConnManager.GetTipoBancoDados(ANome);
        end;
      Result.Conectar;

      Self.FConexoes.Add(Result);
    end;
end;

function TConexoes.Conexao(ANome: string): TObjetoConexao;
var
  IConexao: Integer;
  AProcura : string;
begin
  Result := nil;
  AProcura := EmptyStr;
  if ANome.IsEmpty then
    AProcura := ConnManager.GetDefaultDatabase
  else
    AProcura := ANome;

  for IConexao := 0 to Self.FConexoes.Count-1 do
    begin
      if Self.FConexoes.Items[IConexao].ConexaoAtiva.Equals(AProcura) then
        begin
          Result := Self.FConexoes.Items[IConexao];
          Break;
        end
    end;
  if Result = nil then
    begin
      Result := Self.AddConexao(AProcura);
    end;
end;

function TConexoes.ConexaoAdicionada(ANome: string): Boolean;
var
  IConexao: Integer;
  AProcura : string;
begin
  Result := NAO;
  if ANome.IsEmpty then
    AProcura := ConnManager.GetDefaultDatabase
  else
    AProcura := ANome;

  for IConexao := 0 to Self.FConexoes.Count-1 do
    begin
      if Self.FConexoes.Items[IConexao].ConexaoAtiva.Equals(AProcura) then
        begin
          Result := SIM;
          Break;
        end;
    end;
end;

class function TConexoes.Gerenciador: TConexoes;
begin
  if not Assigned(FInstancia) then
    FInstancia := TConexoes.CriarInerno;

  Result := FInstancia;
end;

constructor TConexoes.CriarInerno;
begin
  inherited Create;

  Self.FConexoes := TList<TObjetoConexao>.Create;
end;

class procedure TConexoes.Registrar;
begin
  Gerenciador.FModuloAtivo := SIM;
end;

end.
