unit uExt;

interface

uses
  Winapi.Windows, System.SysUtils;

function Wow64DisableWow64FsRedirection(var OldValue: Pointer): BOOL; stdcall; external 'kernel32.dll';
function Wow64RevertWow64FsRedirection(OldValue: Pointer): BOOL; stdcall; external 'kernel32.dll';

procedure DisableWow64FsRedirection(const Proc: TProc);

implementation

procedure DisableWow64FsRedirection(const Proc: TProc);
var
  OldState: Pointer;
  FsRedirDisabled: BOOL;
begin
  if not Assigned(Proc) then Exit;

  FsRedirDisabled := Wow64DisableWow64FsRedirection(OldState);
  try
    Proc();
  finally
    if FsRedirDisabled then
      Wow64RevertWow64FsRedirection(OldState);
  end;
end;

end.
