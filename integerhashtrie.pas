unit IntegerHashTrie;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Trie, Hash_Trie;

type
  EIntegerHashTrie = class(ETrie);
  { TIntegerHashTrie }
  TIntegerHashTrie = class(THashTrie)
  private
    procedure CheckHashSize(ASize: THashSize); inline;
    procedure InternalAdd(key : Pointer; Value : Pointer);
    function InternalFind(key: Pointer; out Value: Pointer): Boolean;
  protected
    function CompareKeys(key1, key2 : Pointer) : Boolean; override;
    function Hash32(key : Pointer): Cardinal; override;
    function Hash16(key : Pointer) : Word; override;
    function Hash64(key : Pointer) : Int64; override;
    procedure FreeKey(key : Pointer); override;
  public
    constructor Create(AHashSize : THashSize = hs32);
    procedure Add(key : Cardinal; Value : Pointer); overload;
    procedure Add(key : Word; Value : Pointer); overload;
    procedure Add(key : Int64; Value : Pointer); overload;
    function Find(key : Cardinal; out Value : Pointer) : Boolean; overload;
    function Find(key : Word; out Value : Pointer) : Boolean; overload;
    function Find(key : Int64; out Value : Pointer) : Boolean; overload;
    function Remove(key : Cardinal) : Boolean; overload;
    function Remove(key : Word) : Boolean; overload;
    function Remove(key : Int64) : Boolean; overload;
    function Next(var AIterator : THashTrieIterator; out key : Cardinal; out Value : Pointer) : Boolean; overload;
    function Next(var AIterator : THashTrieIterator; out key : Word; out Value : Pointer) : Boolean; overload;
    function Next(var AIterator : THashTrieIterator; out key : Int64; out Value : Pointer) : Boolean; overload;
  end;

implementation

{ TIntegerHashTrie }

constructor TIntegerHashTrie.Create(AHashSize: THashSize);
begin
  inherited Create(AHashSize);
end;

function TIntegerHashTrie.CompareKeys(key1, key2: Pointer): Boolean;
begin
  {$IFNDEF FPC}
  Result := False;
  {$ENDIF}
  case HashSize of
    hs16, hs32 : Result := key1 = key2;
    hs64 : Result := PInt64(key1)^ = PInt64(key2)^;
    else RaiseTrieDepthError;
  end;
end;

function TIntegerHashTrie.Hash32(key : Pointer): Cardinal;
begin
  Result := {%H-}Cardinal(key);
end;

function TIntegerHashTrie.Hash16(key: Pointer): Word;
begin
  Result := {%H-}Word(key);
end;

function TIntegerHashTrie.Hash64(key: Pointer): Int64;
begin
  if (HashSize = hs64) and (sizeof(Pointer) <> sizeof(Int64)) then
    Result := PInt64(key)^
  else Result := {%H-}Int64(key);
end;

procedure TIntegerHashTrie.FreeKey(key: Pointer);
begin
  if (HashSize = hs64) and (sizeof(Pointer) <> sizeof(Int64)) then
    Dispose(PInt64(key));
end;

procedure TIntegerHashTrie.Add(key: Cardinal; Value: Pointer);
begin
  CheckHashSize(hs32);
  InternalAdd({%H-}Pointer(key), Value);
end;

procedure TIntegerHashTrie.Add(key: Word; Value: Pointer);
begin
  CheckHashSize(hs16);
  InternalAdd({%H-}Pointer(key), Value);
end;

procedure TIntegerHashTrie.Add(key: Int64; Value: Pointer);
var
  keyInt64 : PInt64;
begin
  CheckHashSize(hs64);
  if (HashSize = hs64) and (sizeof(Pointer) <> sizeof(Int64)) then
  begin
    New(keyInt64);
    keyInt64^ := key;
    InternalAdd(keyInt64, Value);
  end
  else InternalAdd({%H-}Pointer(key), Value);
end;

procedure TIntegerHashTrie.CheckHashSize(ASize: THashSize);
const
  SHashSizeMismatch = 'HashSize mismatch';
begin
  if ASize <> HashSize then
    raise EIntegerHashTrie.Create(SHashSizeMismatch);
end;

function TIntegerHashTrie.Find(key: Cardinal; out Value: Pointer): Boolean;
begin
  CheckHashSize(hs32);
  Result := InternalFind({%H-}Pointer(key), Value);
end;

function TIntegerHashTrie.Find(key: Word; out Value: Pointer): Boolean;
begin
  CheckHashSize(hs16);
  Result := InternalFind({%H-}Pointer(key), Value);
end;

function TIntegerHashTrie.Find(key: Int64; out Value: Pointer): Boolean;
begin
  CheckHashSize(hs64);
  if (HashSize = hs64) and (sizeof(Pointer) <> sizeof(Int64)) then
    Result := InternalFind(@key, Value)
  else Result := InternalFind({%H-}Pointer(key), Value);;
end;

procedure TIntegerHashTrie.InternalAdd(key : Pointer; Value : Pointer);
var
  kvp : TKeyValuePair;
begin
  kvp.Key := key;
  kvp.Value := Value;
  inherited Add(@kvp);
end;

function TIntegerHashTrie.InternalFind(key: Pointer; out Value: Pointer):
    Boolean;
var
  kvp : PKeyValuePair;
  AChildIndex : Byte;
  HashTrieNode : PHashTrieNode;
begin
  kvp := inherited Find(key, HashTrieNode, AChildIndex);
  Result := kvp <> nil;
  if Result then
    Value := kvp^.Value
  else Value := nil;
end;

function TIntegerHashTrie.Remove(key: Cardinal): Boolean;
begin
  CheckHashSize(hs32);
  Result := inherited Remove({%H-}Pointer(key));
end;

function TIntegerHashTrie.Remove(key: Word): Boolean;
begin
  CheckHashSize(hs16);
  Result := inherited Remove({%H-}Pointer(key));
end;

function TIntegerHashTrie.Remove(key: Int64): Boolean;
begin
  CheckHashSize(hs64);
  if (HashSize = hs64) and (sizeof(Pointer) <> sizeof(Int64)) then
    Result := inherited Remove(@key)
  else Result := inherited Remove({%H-}Pointer(key));
end;

function TIntegerHashTrie.Next(var AIterator: THashTrieIterator; out
  key: Cardinal; out Value: Pointer): Boolean;
var
  kvp : PKeyValuePair;
begin
  CheckHashSize(hs32);
  kvp := inherited Next(AIterator);
  if kvp <> nil then
  begin
    key := {%H-}Cardinal(kvp^.Key);
    Value := kvp^.Value;
    Result := True;
  end
  else
  begin
    key := 0;
    Value := nil;
    Result := False;
  end;
end;

function TIntegerHashTrie.Next(var AIterator: THashTrieIterator; out key: Word;
  out Value: Pointer): Boolean;
var
  kvp : PKeyValuePair;
begin
  CheckHashSize(hs16);
  kvp := inherited Next(AIterator);
  if kvp <> nil then
  begin
    key := {%H-}Word(kvp^.Key);
    Value := kvp^.Value;
    Result := True;
  end
  else
  begin
    key := 0;
    Value := nil;
    Result := False;
  end;
end;

function TIntegerHashTrie.Next(var AIterator: THashTrieIterator; out
  key: Int64; out Value: Pointer): Boolean;
var
  kvp : PKeyValuePair;
begin
  CheckHashSize(hs64);
  kvp := inherited Next(AIterator);
  if kvp <> nil then
  begin
    key := PInt64(kvp^.Key)^;
    Value := kvp^.Value;
    Result := True;
  end
  else
  begin
    key := 0;
    Value := nil;
    Result := False;
  end;
end;

end.
