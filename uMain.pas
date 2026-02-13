unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.ImageList, Vcl.Buttons,
  Vcl.Controls, Vcl.Forms, Vcl.ImgList, Vcl.Menus, sSkinProvider, sSkinManager,
  acAlphaHints, Vcl.StdCtrls, sBitBtn, sMemo, sEdit, sSpinEdit, sLabel, sCheckBox,
  sGroupBox, acAlphaImageList, Vcl.Dialogs, sDialogs, Vcl.ComCtrls, sRichEdit;

const
  mbMessage = WM_USER + 1024;

type
  TfrmMain = class(TForm)
    sAlphaHints: TsAlphaHints;
    sSkinManager: TsSkinManager;
    sSkinProvider: TsSkinProvider;
    MainMenu: TMainMenu;
    mmuFile: TMenuItem;
    mmuView: TMenuItem;
    mmuTool: TMenuItem;
    mmuHelp: TMenuItem;
    mmuAbout: TMenuItem;
    mmuClearClipboard: TMenuItem;
    mmuAlwaysOnTop: TMenuItem;
    sCharImageList_Small: TsCharImageList;
    mmuSaveAs: TMenuItem;
    mmuExit: TMenuItem;
    sSaveDlg: TsSaveDialog;
    redResult: TsRichEdit;
    N1: TMenuItem;
    mmuNASC: TMenuItem;
    mmuDM: TMenuItem;
    sAlphaImageList: TsAlphaImageList;
    mmuNC: TMenuItem;
    N2: TMenuItem;
    mmuRE: TMenuItem;
    N3: TMenuItem;
    mmuCMD: TMenuItem;
    mmuPS: TMenuItem;
    mmuCMDIPC: TMenuItem;
    mmuPSNetIPC: TMenuItem;
    mmuPSNetIPA: TMenuItem;
    mmuPSNetR: TMenuItem;
    mmuPSTC: TMenuItem;
    N4: TMenuItem;
    mmuPSNetAD: TMenuItem;
    mmuCMDARP: TMenuItem;
    N5: TMenuItem;
    mmuCMDIPCDD: TMenuItem;
    mmuCMDIPCFD: TMenuItem;
    mmuCMDRP: TMenuItem;
    N6: TMenuItem;
    mmuCMDNetSanb: TMenuItem;
    mmuCMDIPCRN: TMenuItem;
    mmuRefresh: TMenuItem;
    N7: TMenuItem;
    mmuShowAll: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure mmuAboutClick(Sender: TObject);
    procedure mmuClearClipboardClick(Sender: TObject);
    procedure mmuAlwaysOnTopClick(Sender: TObject);
    procedure mmuSaveAsClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mmuNASCClick(Sender: TObject);
    procedure mmuDMClick(Sender: TObject);
    procedure mmuNCClick(Sender: TObject);
    procedure mmuREClick(Sender: TObject);
    procedure mmuCMDClick(Sender: TObject);
    procedure mmuPSClick(Sender: TObject);
    procedure mmuExitClick(Sender: TObject);
    procedure mmuRefreshClick(Sender: TObject);
    procedure mmuShowAllClick(Sender: TObject);
  private
    procedure ChangeMessageBoxPosition(var Msg: TMessage); message mbMessage;
    procedure WMClipboardUpdate(var Msg: TMessage); message WM_CLIPBOARDUPDATE;
  public
    FAlwaysOnTop: Boolean;
    FShowAllNetworks: Boolean;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  uMain.UI, uMain.UI.Format, uMain.UI.Menu, uMain.UI.Messages, uMain.UI.Settings, uNetworkList;

procedure TfrmMain.ChangeMessageBoxPosition(var Msg: TMessage);
begin
  UI_ChangeMessageBoxPosition(Self);
end;

procedure TfrmMain.WMClipboardUpdate(var Msg: TMessage);
begin
  UI_UpdateMenu(Self);
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  RemoveClipboardFormatListener(Handle);
  UI_SaveSettings(Self);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  UI_Init(Self);
  mmuRefreshClick(Self);
  AddClipboardFormatListener(Handle);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    UI_Exit(Self);
end;

procedure TfrmMain.mmuAboutClick(Sender: TObject);
begin
  UI_ShowAbout(Self);
end;

procedure TfrmMain.mmuAlwaysOnTopClick(Sender: TObject);
begin
  UI_AlwaysOnTop(Self);
end;

procedure TfrmMain.mmuClearClipboardClick(Sender: TObject);
begin
  UI_ClearClipboard(Self);
end;

procedure TfrmMain.mmuCMDClick(Sender: TObject);
begin
  UI_MenuCMDClick(Self, Sender);
end;

procedure TfrmMain.mmuDMClick(Sender: TObject);
begin
  UI_OpenDeviceManager(Self);
end;

procedure TfrmMain.mmuExitClick(Sender: TObject);
begin
  UI_Exit(Self);
end;

procedure TfrmMain.mmuNASCClick(Sender: TObject);
begin
  UI_OpenNetworkAndSharingCenter(Self);
end;

procedure TfrmMain.mmuNCClick(Sender: TObject);
begin
  UI_OpenNetworkConnections(Self);
end;

procedure TfrmMain.mmuPSClick(Sender: TObject);
begin
  UI_MenuPSClick(Self, Sender);
end;

procedure TfrmMain.mmuREClick(Sender: TObject);
begin
  UI_OpenRegistryEditor(Self);
end;

procedure TfrmMain.mmuRefreshClick(Sender: TObject);
begin
  UI_Refresh(Self);
end;

procedure TfrmMain.mmuSaveAsClick(Sender: TObject);
begin
  UI_SaveAs(Self);
end;

procedure TfrmMain.mmuShowAllClick(Sender: TObject);
begin
  UI_ShowAllNetworks(Self);
end;

end.
