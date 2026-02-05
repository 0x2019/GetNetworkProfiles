unit uMain.UI.Settings;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms, IniFiles;

procedure UI_LoadSettings(AForm: TObject);
procedure UI_SaveSettings(AForm: TObject);

implementation

uses
  uMain, uMain.UI.Menu;

procedure UI_LoadSettings(AForm: TObject);
var
  F: TfrmMain;
  xIni: TMemIniFile;
  xIniFileName: string;
  FirstRun: Boolean;
  FormLeft, FormTop, FormWidth, FormHeight: Integer;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  xIniFileName := ChangeFileExt(Application.ExeName, '.ini');
  xIni := TMemIniFile.Create(xIniFileName, TEncoding.UTF8);
  try
    FirstRun := not FileExists(xIniFileName);
    if FirstRun then
      F.Position := poDesktopCenter
    else
    begin
      FormLeft := xIni.ReadInteger('Form', 'Left', F.Left);
      FormTop  := xIni.ReadInteger('Form', 'Top', F.Top);
      FormWidth  := xIni.ReadInteger('Form', 'Width', F.Width);
      FormHeight := xIni.ReadInteger('Form', 'Height', F.Height);

      var StateInt := xIni.ReadInteger('Form', 'WindowState', Ord(wsNormal));

      if StateInt = Ord(wsMinimized) then
        StateInt := Ord(wsNormal);

      if (FormLeft >= Screen.Width)
        or (FormTop  >= Screen.Height)
        or (FormLeft + FormWidth  <= 0)
        or (FormTop + FormHeight <= 0) then
      begin
        F.Position := poDesktopCenter;
        F.WindowState := wsNormal;
      end
      else
      begin
        F.Position := poDesigned;
        F.SetBounds(FormLeft, FormTop, FormWidth, FormHeight);
        F.WindowState := TWindowState(StateInt);
      end;
    end;

    F.FAlwaysOnTop := xIni.ReadBool('Main', 'AlwaysOnTop', False);
    UI_AlwaysOnTop(F, False);

  finally
    xIni.Free;
  end;
end;

procedure UI_SaveSettings(AForm: TObject);
var
  F: TfrmMain;
  xIni: TMemIniFile;
  WindowState: TWindowState;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  xIni := TMemIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'), TEncoding.UTF8);
  try
    WindowState := F.WindowState;
    xIni.WriteInteger('Form', 'WindowState', Ord(WindowState));

    if WindowState = wsNormal then
    begin
      xIni.WriteInteger('Form', 'Left', F.Left);
      xIni.WriteInteger('Form', 'Top', F.Top);
      xIni.WriteInteger('Form', 'Width', F.Width);
      xIni.WriteInteger('Form', 'Height', F.Height);
    end;

    xIni.WriteBool('Main', 'AlwaysOnTop', F.FAlwaysOnTop);

    xIni.UpdateFile;
  finally
    xIni.Free;
  end;
end;

end.
