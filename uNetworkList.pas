unit uNetworkList;

interface

uses
  Winapi.Windows, System.SysUtils, ActiveX, ComObj, IpHlpApi, IpTypes, WinSock2,
  uNetworkList_TLB;

function GetNetworkList(ShowAllNetworks: Boolean = False): string;

implementation

type
  TNetInfo = record
    Id: TGUID;
    Name: string;
    Desc: string;
    CategoryStr: string;
    DomainTypeStr: string;
    ConnFlags: NLM_CONNECTIVITY;
    ConnText: string;
    CreatedStr: string;
    ConnectedStr: string;
    IsConnected: Boolean;
    IsConnectedToInternet: Boolean;
  end;

  TConnInfo = record
    Id: TGUID;
    AdapterId: TGUID;
    AdapterName: string;
    DriverDesc: string;
    Mac: string;
  end;

procedure AddToken(var S: string; const Token: string);
begin
  if Token = '' then Exit;
  if S <> '' then S := S + ', ';
  S := S + Token;
end;

function FileTimeToDateTime(Low, High: LongWord): string;
var
  Ft: TFileTime;
  St: TSystemTime;
begin
  Result := '';
  if (Low = 0) and (High = 0) then Exit;

  Ft.dwLowDateTime := Low;
  Ft.dwHighDateTime := High;
  if FileTimeToSystemTime(Ft, St) then
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', SystemTimeToDateTime(St));
end;

function CategoryToString(C: NLM_NETWORK_CATEGORY): string;
begin
  case C of
    NLM_NETWORK_CATEGORY_PUBLIC: Result := 'Public';
    NLM_NETWORK_CATEGORY_PRIVATE: Result := 'Private';
    NLM_NETWORK_CATEGORY_DOMAIN_AUTHENTICATED: Result := 'DomainAuthenticated';
  else
    Result := 'Unknown';
  end;
end;

function DomainTypeToString(D: NLM_DOMAIN_TYPE): string;
begin
  case D of
    NLM_DOMAIN_TYPE_NON_DOMAIN_NETWORK: Result := 'NonDomain';
    NLM_DOMAIN_TYPE_DOMAIN_NETWORK: Result := 'Domain';
    NLM_DOMAIN_TYPE_DOMAIN_AUTHENTICATED: Result := 'DomainAuthenticated';
  else
    Result := 'Unknown';
  end;
end;

function ConnectivityToString(Flags: NLM_CONNECTIVITY): string;
begin
  Result := '';

  if Flags = NLM_CONNECTIVITY_DISCONNECTED then
  begin
    Result := 'Disconnected';
    Exit;
  end;

  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV4_NOTRAFFIC)) <> 0 then
    AddToken(Result, 'IPv4:NoTraffic');
  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV4_SUBNET)) <> 0 then
    AddToken(Result, 'IPv4:Subnet');
  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV4_LOCALNETWORK)) <> 0 then
    AddToken(Result, 'IPv4:Local');
  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV4_INTERNET)) <> 0 then
    AddToken(Result, 'IPv4:Internet');

  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV6_NOTRAFFIC)) <> 0 then
    AddToken(Result, 'IPv6:NoTraffic');
  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV6_SUBNET)) <> 0 then
    AddToken(Result, 'IPv6:Subnet');
  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV6_LOCALNETWORK)) <> 0 then
    AddToken(Result, 'IPv6:Local');
  if (Integer(Flags) and Integer(NLM_CONNECTIVITY_IPV6_INTERNET)) <> 0 then
    AddToken(Result, 'IPv6:Internet');
end;

function MACAddressToString(const Bytes: PByte; Len: ULONG): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Integer(Len) - 1 do
  begin
    if i > 0 then Result := Result + '-';
    Result := Result + IntToHex(Bytes[i], 2);
  end;
end;

function FindAdapterByGUID(const AdapterId: TGUID; out AdapterName, AdapterDesc, Mac: string): Boolean;
const
  FLAGS = GAA_FLAG_SKIP_ANYCAST or GAA_FLAG_SKIP_MULTICAST or GAA_FLAG_SKIP_DNS_SERVER;
var
  Size: ULONG;
  Ret: ULONG;
  Buf, Cur: PIP_ADAPTER_ADDRESSES;
  S: UnicodeString;
  G: TGUID;
  HR: HRESULT;
  FN, Desc: string;
begin
  Result := False;
  AdapterName := '';
  AdapterDesc := '';
  MAC := '';

  Size := 0;
  Ret := GetAdaptersAddresses(ULONG(AF_UNSPEC), FLAGS, nil, nil, @Size);
  if Ret <> ERROR_BUFFER_OVERFLOW then
    Exit;

  GetMem(Buf, Size);
  try
    Ret := GetAdaptersAddresses(ULONG(AF_UNSPEC), FLAGS, nil, Buf, @Size);
    if Ret <> NO_ERROR then
      Exit;

    Cur := Buf;
    while Cur <> nil do
    begin
      S := UnicodeString(AnsiString(PAnsiChar(Cur.AdapterName)));

      HR := CLSIDFromString(PWideChar(S), G);

      if (HR <> S_OK) and (Length(S) = 36) then
        HR := CLSIDFromString(PWideChar('{' + S + '}'), G);

      if (HR = S_OK) and IsEqualGUID(G, AdapterId) then
      begin
        FN := '';
        if (Cur.FriendlyName <> nil) and (Cur.FriendlyName^ <> #0) then
          FN := string(Cur.FriendlyName);

        Desc := '';
        if Cur.Description <> nil then
          Desc := string(Cur.Description);

        AdapterName := FN;
        AdapterDesc := Desc;

        if (AdapterName = '') and (AdapterDesc <> '') then
          AdapterName := AdapterDesc;

        if Cur.PhysicalAddressLength > 0 then
          Mac := MACAddressToString(@Cur.PhysicalAddress[0], Cur.PhysicalAddressLength);

        Exit(True);
      end;

      Cur := Cur.Next;
    end;
  finally
    FreeMem(Buf);
  end;
end;

function GetNetworkList(ShowAllNetworks: Boolean): string;
var
  NLM: INetworkListManager;
  EnumNetworks: IEnumNetworks;
  Net: INetwork;
  Fetched: ULONG;

  EnumConns: IEnumNetworkConnections;
  Conn: INetworkConnection;
  ConnFetched: ULONG;

  NetInfo: TNetInfo;
  ConnInfo: TConnInfo;
  NoteLine: string;

  SB: TStringBuilder;
  HasAny, AnyConn: Boolean;
  ProfileIndex: Integer;

  procedure FillNetInfo(const N: INetwork; out NI: TNetInfo);
  var
    LowCreated, HighCreated, LowConnected, HighConnected: LongWord;
  begin
    NI.Id := N.GetNetworkId;
    NI.Name := string(N.GetName);
    NI.Desc := string(N.GetDescription);

    NI.ConnFlags := N.GetConnectivity;
    NI.CategoryStr := CategoryToString(N.GetCategory);
    NI.DomainTypeStr := DomainTypeToString(N.GetDomainType);
    NI.ConnText := ConnectivityToString(NI.ConnFlags);

    LowCreated := 0; HighCreated := 0; LowConnected := 0; HighConnected := 0;
    N.GetTimeCreatedAndConnected(LowCreated, HighCreated, LowConnected, HighConnected);
    NI.CreatedStr := FileTimeToDateTime(LowCreated, HighCreated);
    NI.ConnectedStr := FileTimeToDateTime(LowConnected, HighConnected);

    NI.IsConnected := N.IsConnected;
    NI.IsConnectedToInternet := N.IsConnectedToInternet;
  end;

  procedure FillConnInfo(const C: INetworkConnection; out CI: TConnInfo; out Note: string);
  begin
    CI.AdapterId := C.GetAdapterId;
    CI.Id := C.GetConnectionId;

    CI.AdapterName := '';
    CI.DriverDesc := '';
    CI.Mac := '';

    FindAdapterByGUID(CI.AdapterId, CI.AdapterName, CI.DriverDesc, CI.Mac);

    Note := '';
    if (CI.AdapterName = '') and (CI.DriverDesc = '') and (CI.Mac = '') then
      Note := 'Name/MAC mapping failed.';
  end;

  procedure AppendProfile(const NI: TNetInfo; const CI: TConnInfo;
    const IncludeDomainType: Boolean; const Note: string);

    procedure AppendKV(const Key, Value: string);
    begin
      SB.AppendLine('- ' + Key + ': ' + Value);
    end;

  begin
    Inc(ProfileIndex);
    SB.AppendLine(Format('[Network Profile #%d]', [ProfileIndex]));

    AppendKV('Name', NI.Name);
    AppendKV('AdapterName', CI.AdapterName);
    AppendKV('DriverName', CI.DriverDesc);
    AppendKV('Description', NI.Desc);
    AppendKV('Category', NI.CategoryStr);
    AppendKV('MACAddress', CI.Mac);

    if IncludeDomainType then
      AppendKV('DomainType', NI.DomainTypeStr);

    AppendKV('Created', NI.CreatedStr);
    AppendKV('LastConnected', NI.ConnectedStr);
    AppendKV('IsConnected', BoolToStr(NI.IsConnected, True));
    AppendKV('IsConnectedToInternet', BoolToStr(NI.IsConnectedToInternet, True));
    AppendKV('ConnectivityFlags', IntToStr(Integer(NI.ConnFlags)));
    AppendKV('ConnectivityText', NI.ConnText);

    SB.AppendLine;
    SB.AppendLine('GUIDs:');

    AppendKV('AdapterID', GUIDToString(CI.AdapterId));
    AppendKV('NetworkID', GUIDToString(NI.Id));
    AppendKV('ConnectionID', GUIDToString(CI.Id));

    if Note <> '' then
      SB.AppendLine(Note);

    SB.AppendLine;
  end;

begin
  SB := TStringBuilder.Create;
  try
    HasAny := False;
    ProfileIndex := 0;

    OleCheck(CoInitializeEx(nil, COINIT_APARTMENTTHREADED));
    try
      NLM := CoNetworkListManager.Create;
      if ShowAllNetworks then
        EnumNetworks := NLM.GetNetworks(NLM_ENUM_NETWORK_ALL)
      else
        EnumNetworks := NLM.GetNetworks(NLM_ENUM_NETWORK_CONNECTED);

      while True do
      begin
        Net := nil;
        Fetched := 0;
        EnumNetworks.Next(1, Net, Fetched);
        if (Fetched = 0) or (Net = nil) then Break;

        HasAny := True;

        FillNetInfo(Net, NetInfo);

        AnyConn := False;
        EnumConns := Net.GetNetworkConnections;
        if EnumConns <> nil then
        begin
          while True do
          begin
            Conn := nil;
            ConnFetched := 0;
            EnumConns.Next(1, Conn, ConnFetched);
            if (ConnFetched = 0) or (Conn = nil) then Break;

            AnyConn := True;

            FillConnInfo(Conn, ConnInfo, NoteLine);
            AppendProfile(NetInfo, ConnInfo, False, NoteLine);
          end;
        end;

        if not AnyConn then
        begin
          ConnInfo.AdapterName := '';
          ConnInfo.DriverDesc := '';
          ConnInfo.Mac := '';
          ConnInfo.AdapterId := GUID_NULL;
          ConnInfo.Id := GUID_NULL;

          AppendProfile(NetInfo, ConnInfo, True, 'No connected adapters.');
        end;
      end;

      if not HasAny then
        SB.AppendLine('No connected network profiles found.');
    finally
      CoUninitialize;
    end;

    Result := SB.ToString.TrimRight;
  finally
    SB.Free;
  end;
end;

end.

