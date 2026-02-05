unit uMain.UI;

interface

uses
  Winapi.Windows, System.SysUtils, Clipbrd;

procedure UI_Init(AForm: TObject);

procedure UI_Copy(AForm: TObject);
procedure UI_Exit(AForm: TObject);

implementation

uses
  uMain, uMain.UI.Menu, uMain.UI.Messages, uMain.UI.Settings, uMain.UI.Strings;

procedure UI_Init(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  F.Constraints.MinWidth  := F.Width;
  F.Constraints.MinHeight := F.Height;

  UI_LoadSettings(F);
  UI_UpdateMenu(F);
end;

procedure UI_Copy(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  if F.redResult.Text = '' then Exit;

  try
    Clipboard.AsText := F.redResult.Text;
  except
    on E: Exception do
      UI_MessageBox(F, Format(SClipboardCopyErrMsg, [E.Message]), MB_ICONWARNING or MB_OK);
  end;

  UI_UpdateMenu(F);
end;

procedure UI_Exit(AForm: TObject);
var
  F: TfrmMain;
begin
  if not (AForm is TfrmMain) then Exit;
  F := TfrmMain(AForm);

  F.Close;
end;

end.
