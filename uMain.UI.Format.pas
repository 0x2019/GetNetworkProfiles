unit uMain.UI.Format;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, Vcl.Graphics,
  sRichEdit;

const
  CNetworkProfile                   = 'Network Profile';
  CMappingFail                      = 'Name/MAC mapping failed.';
  CNoConnectedProfiles              = 'No connected network profiles found.';
  CLinePrefixKV                     = '- ';
  CKeyValueSeparator                = ':';

  CValueTrue                        = 'True';
  CValueFalse                       = 'False';

  CKeyCategory                      = 'Category';
  CTokenDomainType                  = 'DomainType';
  CTokenConnectivityText            = 'ConnectivityText';
  CTokenID                          = 'ID';
  CTokenMAC                         = 'MAC';
  CTokenCreated                     = 'Created';
  CTokenLastConnected               = 'LastConnected';

  CCategoryPublic                   = 'Public';
  CCategoryPrivate                  = 'Private';
  CCategoryDomainAuthenticated      = 'DomainAuthenticated';

  CDomainAuthenticated              = 'DomainAuthenticated';
  CDomain                           = 'Domain';

  CConnInternet                     = 'Internet';
  CConnDisconnected                 = 'Disconnected';

  CNetworkGUID                      = 'GUIDs:';
  CNetworkGUIDOpenBrace             = '{';
  CNetworkGUIDCloseBrace            = '}';

procedure UI_Format_Result(AForm: TObject);

implementation

uses
  uMain;

procedure ApplyStyle(ARichEdit: TsRichEdit; StartPos, Len: Integer;
  const Style: TFontStyles; const Color: TColor);
begin
  if (ARichEdit = nil) or (Len <= 0) or (StartPos < 0) then
    Exit;

  ARichEdit.SelStart := StartPos;
  ARichEdit.SelLength := Len;
  ARichEdit.SelAttributes.Style := Style;
  ARichEdit.SelAttributes.Color := Color;
end;

procedure UI_Format_Result(AForm: TObject);
var
  F: TfrmMain;
  R: TsRichEdit;
  Component: TComponent;
  i: Integer;

  Line, Key, Value: string;
  LineStart: Integer;
  ColonIdx: Integer;
  ValIdx: Integer;

  SavedSelStart, SavedSelLen: Integer;
  DefaultColor, KeyColor, ValueColor: TColor;
begin
  R := nil;

  if AForm is TfrmMain then
  begin
    F := TfrmMain(AForm);
    if Assigned(F.redResult) then
      R := F.redResult;
  end;

  if (R = nil) and (AForm is TComponent) then
  begin
    for i := 0 to TComponent(AForm).ComponentCount - 1 do
    begin
      Component := TComponent(AForm).Components[i];
      if Component is TsRichEdit then
      begin
        R := TsRichEdit(Component);
        Break;
      end;
    end;
  end;

  if R = nil then
    Exit;

  DefaultColor := R.Font.Color;
  KeyColor := clWindowText;

  SavedSelStart := R.SelStart;
  SavedSelLen := R.SelLength;

  SendMessage(R.Handle, WM_SETREDRAW, 0, 0);
  R.Lines.BeginUpdate;
  try
    R.SelectAll;
    R.SelAttributes.Style := [];
    R.SelAttributes.Color := DefaultColor;
    R.SelLength := 0;

    for i := 0 to R.Lines.Count - 1 do
    begin
      Line := R.Lines[i];
      if Line = '' then
        Continue;

      LineStart := R.Perform(EM_LINEINDEX, i, 0);
      if LineStart < 0 then
        Continue;

      if Line.StartsWith(CNetworkProfile) or Line.StartsWith('[' + CNetworkProfile) then
      begin
        ApplyStyle(R, LineStart, Length(Line), [fsBold], DefaultColor);
        Continue;
      end;

      if SameText(Line, CNetworkGUID) then
      begin
        ApplyStyle(R, LineStart, Length(Line), [fsBold], DefaultColor);
        Continue;
      end;

      if Line.StartsWith(CMappingFail) or Line.StartsWith('(' + CMappingFail) then
      begin
        ApplyStyle(R, LineStart, Length(Line), [fsItalic], clOlive);
        Continue;
      end;

      if Line.StartsWith(CLinePrefixKV) then
      begin
        ColonIdx := Line.IndexOf(CKeyValueSeparator);
        if ColonIdx >= 0 then
        begin
          ApplyStyle(R, LineStart, ColonIdx + 1, [fsBold], KeyColor);

          Key := Trim(Copy(Line, 3, (ColonIdx + 1) - 3));

          ValIdx := ColonIdx + 1;
          while (ValIdx < Length(Line)) and (Line[ValIdx + 1] = ' ') do
            Inc(ValIdx);

          Value := '';
          if ValIdx < Length(Line) then
            Value := Trim(Copy(Line, ValIdx + 1, MaxInt));

          ValueColor := DefaultColor;

          if SameText(Value, CValueTrue) then
            ValueColor := clGreen
          else if SameText(Value, CValueFalse) then
            ValueColor := clRed

          else if SameText(Key, CKeyCategory) then
          begin
            if SameText(Value, CCategoryPublic) then ValueColor := clMaroon
            else if SameText(Value, CCategoryPrivate) then ValueColor := clMaroon
            else if SameText(Value, CCategoryDomainAuthenticated) then ValueColor := clMaroon;
          end

          else if Key.Contains(CTokenDomainType) then
          begin
            if SameText(Value, CDomainAuthenticated) then ValueColor := clGreen
            else ValueColor := KeyColor;
          end

          else if Key.Contains(CTokenConnectivityText) then
          begin
            if Value.Contains(CConnInternet) then ValueColor := clGreen
            else if Value.Contains(CConnDisconnected) then ValueColor := clRed
            else if Value <> '' then ValueColor := KeyColor;
          end

          else if Key.Contains(CTokenID) then
          begin
            if (Pos(CNetworkGUIDOpenBrace, Value) > 0) and (Pos(CNetworkGUIDCloseBrace, Value) > 0) then
              ValueColor := clBlue;
          end

          else if Key.Contains(CTokenMAC) then
            ValueColor := clWebDodgerBlue

          else if Key.Contains(CTokenCreated) or Key.Contains(CTokenLastConnected) then
            ValueColor := clWebSlateBlue;

          if (ValIdx < Length(Line)) and (Value <> '') then
            ApplyStyle(R, LineStart + ValIdx, Length(Line) - ValIdx, [], ValueColor);
        end
        else
        begin
          ApplyStyle(R, LineStart, Length(Line), [fsBold], DefaultColor);
        end;

        Continue;
      end;

      if SameText(Line, CNoConnectedProfiles) then
        ApplyStyle(R, LineStart, Length(Line), [fsItalic], KeyColor);
    end;

  finally
    R.Lines.EndUpdate;
    SendMessage(R.Handle, WM_SETREDRAW, 1, 0);
    InvalidateRect(R.Handle, nil, True);

    R.SelStart := SavedSelStart;
    R.SelLength := SavedSelLen;
  end;
end;

end.
