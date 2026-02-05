unit uMain.UI.Strings;

interface

resourcestring
  APP_NAME                            = 'GetNetworkProfiles';
  APP_VERSION                         = 'v1.0.0.0';
  APP_RELEASE                         = 'February 05, 2026';
  APP_URL                             = 'https://github.com/0x2019/GetNetworkProfiles';

  SFileSavedMsg                       = 'File successfully saved!' + sLineBreak + 'Path: %s';
  SFileSaveFailMsg                    = 'Failed to save the file.' + sLineBreak + 'Path: %s' + sLineBreak + '%s';

  SOpenFileMsg                        = 'Would you like to open the file now?';
  SOpenFileFailMsg                    = 'Failed to open the file.';

  SOpenCMDFailMsg                     = 'Failed to open Command Prompt.' + sLineBreak + 'Error code: %d';
  SOpenPowerShellFailMsg              = 'Failed to open PowerShell.' + sLineBreak + 'Error code: %d';
  SOpenDeviceManagerFailMsg           = 'Failed to open Device Manager.' + sLineBreak + 'Error code: %d';
  SOpenRegistryEditorFailMsg          = 'Failed to open Registry Editor.' + sLineBreak + 'Error code: %d';
  SOpenNetworkConnectionsFailMsg      = 'Failed to open Network Connections.' + sLineBreak + 'Error code: %d';
  SOpenNetworkSharingCenterFailMsg    = 'Failed to open Network and Sharing Center.' + sLineBreak + 'Error code: %d';

  SClipboardClearErrMsg               = 'Unable to clear the clipboard.' + sLineBreak + '%s';
  SClipboardCopyErrMsg                = 'Unable to copy to the clipboard.' + sLineBreak + '%s';

  SAboutMsg                           = '%s %s' + sLineBreak +
                                        'c0ded by 龍, written in Delphi.' + sLineBreak + sLineBreak +
                                        'Release Date: %s' + sLineBreak +
                                        'URL: %s';

implementation

end.
