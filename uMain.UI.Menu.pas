unit uMain.UI.Menu;

interface

uses
  Winapi.Windows, Winapi.Messages, System.IOUtils, System.SysUtils,
  Vcl.Forms, Vcl.Menus, Clipbrd, ShellAPI;

// Global
procedure UI_UpdateMenu(AForm: TObject);

// File
procedure UI_SaveAs(AForm: TObject);

// View
procedure UI_Refresh(AForm: TObject);
procedure UI_AlwaysOnTop(AForm: TObject; Toggle: Boolean = True);
procedure UI_ShowAllNetworks(AForm: TObject);

// Tool
procedure UI_ClearClipboard(AForm: TObject);

procedure UI_OpenCMD(AForm: TObject; const CmdLine: string);
procedure UI_OpenPowerShell(AForm: TObject; const CmdLine: string);

procedure UI_OpenDeviceManager(AForm: TObject);
procedure UI_OpenRegistryEditor(AForm: TObject);
procedure UI_OpenNetworkConnections(AForm: TObject);
procedure UI_OpenNetworkAndSharingCenter(AForm: TObject);

// Tool - Click handlers
procedure UI_MenuCMDClick(AForm: TObject; Sender: TObject);
procedure UI_MenuPSClick(AForm: TObject; Sender: TObject);

// Help
procedure UI_ShowAbout(AForm: TObject);

implementation

uses
  uExt, uMain, uMain.UI.Format, uMain.UI.Messages, uMain.UI.Strings, uNetworkList;

procedure UI_UpdateMenu(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  if Assigned(F.mmuSaveAs) and Assigned(F.redResult) then
    F.mmuSaveAs.Enabled := F.redResult.Text <> '';

  if Assigned(F.mmuClearClipboard) then
    F.mmuClearClipboard.Enabled := IsClipboardFormatAvailable(CF_UNICODETEXT) or
                                   IsClipboardFormatAvailable(CF_TEXT)        or
                                   IsClipboardFormatAvailable(CF_BITMAP)      or
                                   IsClipboardFormatAvailable(CF_DIB)         or
                                   IsClipboardFormatAvailable(CF_HDROP);

  if Assigned(F.mmuShowAll) then
    F.mmuShowAll.Checked := F.FShowAllNetworks;
end;

procedure UI_SaveAs(AForm: TObject);
var
  F: TfrmMain;
  FileName: string;
  Enc: TEncoding;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  if F.redResult.Text = '' then Exit;
  if not Assigned(F.sSaveDlg) then Exit;

  F.sSaveDlg.FileName := Format('GNP_%s.txt', [FormatDateTime('yyyymmdd_hhnnss', Now)]);

  if not F.sSaveDlg.Execute then Exit;

  FileName := F.sSaveDlg.FileName;
  if ExtractFileExt(FileName) = '' then
    FileName := FileName + '.txt';

  Enc := TUTF8Encoding.Create(False);
  try
    try
      TFile.WriteAllText(FileName, F.redResult.Lines.Text, Enc);
    except
      on E: Exception do
      begin
        UI_MessageBox(F, Format(SFileSaveFailMsg, [FileName, E.Message]), MB_ICONERROR or MB_OK);
        Exit;
      end;
    end;
  finally
    Enc.Free;
  end;

  if UI_ConfirmYesNo(F, Format(SFileSavedMsg, [FileName]) + sLineBreak + sLineBreak + SOpenFileMsg) then
  begin
    if ShellExecute(0, 'open', PChar(FileName), nil, nil, SW_SHOWNORMAL) <= 32 then
      UI_MessageBox(F, SOpenFileFailMsg, MB_ICONWARNING or MB_OK);
  end;
end;

procedure UI_Refresh(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  if not Assigned(F.redResult) then Exit;

  F.redResult.Lines.BeginUpdate;
  try
    F.redResult.Lines.Text := GetNetworkList(F.FShowAllNetworks);
    UI_Format_Result(F);
    UI_UpdateMenu(F);
  finally
    F.redResult.Lines.EndUpdate;
  end;
end;

procedure UI_AlwaysOnTop(AForm: TObject; Toggle: Boolean);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  if Toggle then
    F.FAlwaysOnTop := not F.FAlwaysOnTop;

  if F.FAlwaysOnTop then
    SetWindowPos(F.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE)
  else
    SetWindowPos(F.Handle, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  if Assigned(F.mmuAlwaysOnTop) then
    F.mmuAlwaysOnTop.Checked := F.FAlwaysOnTop;
end;

procedure UI_ShowAllNetworks(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  F.FShowAllNetworks := not F.FShowAllNetworks;
  UI_Refresh(F);
end;

procedure UI_ClearClipboard(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  try
    Clipboard.Clear;
  except
    on E: Exception do
      UI_MessageBox(F, Format(SClipboardClearErrMsg, [E.Message]), MB_ICONWARNING or MB_OK);
  end;
  UI_UpdateMenu(F);
end;

procedure UI_OpenCMD(AForm: TObject; const CmdLine: string);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  DisableWow64FsRedirection(
    procedure
    var
      R: HINST;
      Params: string;
    begin
      Params := '/k ' + CmdLine;

      R := ShellExecute(F.Handle, 'runas', 'cmd.exe', PChar(Params), nil, SW_SHOWNORMAL);

      if NativeInt(R) <= 32 then
      begin
        if NativeInt(R) = SE_ERR_ACCESSDENIED then Exit;
        UI_MessageBox(F, Format(SOpenCmdFailMsg, [NativeInt(R)]), MB_ICONWARNING or MB_OK);
      end;
    end
  );
end;

procedure UI_OpenPowerShell(AForm: TObject; const CmdLine: string);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  DisableWow64FsRedirection(
    procedure
    var
      R: HINST;
      Params: string;
      EscCmd: string;
    begin
      EscCmd := StringReplace(CmdLine, '"', '`"', [rfReplaceAll]);
      Params := '-NoExit -Command "' + EscCmd + '"';

      R := ShellExecute(F.Handle, 'runas', 'powershell.exe', PChar(Params), nil, SW_SHOWNORMAL);

      if NativeInt(R) <= 32 then
      begin
        if NativeInt(R) = SE_ERR_ACCESSDENIED then Exit;
        UI_MessageBox(F, Format(SOpenPowerShellFailMsg, [NativeInt(R)]), MB_ICONWARNING or MB_OK);
      end;
    end
  );
end;

procedure UI_OpenDeviceManager(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  DisableWow64FsRedirection(
    procedure
    var
      R: HINST;
    begin
      R := ShellExecute(F.Handle, 'open', 'explorer.exe',
        'shell:::{74246BFC-4C96-11D0-ABEF-0020AF6B0B7A}', nil, SW_SHOWNORMAL); // devmgmt.msc

      if NativeInt(R) <= 32 then
        UI_MessageBox(F, Format(SOpenDeviceManagerFailMsg, [NativeInt(R)]), MB_ICONWARNING or MB_OK);
    end
  );
end;

procedure UI_OpenRegistryEditor(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  DisableWow64FsRedirection(
    procedure
    var
      R: HINST;
    begin
      R := ShellExecute(F.Handle, 'open', 'regedit.exe', '/m', nil, SW_SHOWNORMAL);

      if NativeInt(R) <= 32 then
        UI_MessageBox(F, Format(SOpenRegistryEditorFailMsg, [NativeInt(R)]), MB_ICONWARNING or MB_OK);
    end
  );
end;

procedure UI_OpenNetworkConnections(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  DisableWow64FsRedirection(
    procedure
    var
      R: HINST;
    begin
      R := ShellExecute(F.Handle, 'open', 'explorer.exe',
        'shell:::{7007ACC7-3202-11D1-AAD2-00805FC1270E}', nil, SW_SHOWNORMAL); // ncpa.cpl

      if NativeInt(R) <= 32 then
        UI_MessageBox(F, Format(SOpenNetworkConnectionsFailMsg, [NativeInt(R)]), MB_ICONWARNING or MB_OK);
    end
  );
end;

procedure UI_OpenNetworkAndSharingCenter(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  DisableWow64FsRedirection(
    procedure
    var
      R: HINST;
    begin
      R := ShellExecute(F.Handle, 'open', 'explorer.exe',
        'shell:::{8E908FC9-BECC-40F6-915B-F4CA0E70D03D}', nil, SW_SHOWNORMAL); // control.exe /name Microsoft.NetworkAndSharingCenter

      if NativeInt(R) <= 32 then
        UI_MessageBox(F, Format(SOpenNetworkSharingCenterFailMsg, [NativeInt(R)]), MB_ICONWARNING or MB_OK);
    end
  );
end;

procedure UI_MenuCMDClick(AForm: TObject; Sender: TObject);
var
  MI: TMenuItem;
begin
  if not (AForm is TfrmMain) then Exit;
  if not (Sender is TMenuItem) then Exit;
  MI := TMenuItem(Sender);

  UI_OpenCMD(AForm, MI.Hint);
end;

procedure UI_MenuPSClick(AForm: TObject; Sender: TObject);
var
  MI: TMenuItem;
begin
  if not (AForm is TfrmMain) then Exit;
  if not (Sender is TMenuItem) then Exit;
  MI := TMenuItem(Sender);

  UI_OpenPowerShell(AForm, MI.Hint);
end;

procedure UI_ShowAbout(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  UI_MessageBoxCustom(F, Format(SAboutMsg, [APP_NAME, APP_VERSION, APP_RELEASE, APP_URL]), MB_OK);
end;

end.
