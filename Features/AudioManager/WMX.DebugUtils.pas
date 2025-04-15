unit WMX.DebugUtils;
{*******************************************************}
{                                                       }
{                       NVinfo / WMX                    }
{                                                       }
{      Delphi Microvolution Cross-Platform Library      }
{                                                       }
{   Copyright 1998-2025 Walcledson de Paula under MIT   }
{  license which is located in the root folder of this  }
{           library github.com/microvolution.           }
{     More free and/or commercial products/software:    }
{                https://mvinfo.wmx.net.br              }
{                                                       }
{   All rights reserved. Free for non-commercial use.   }
{  For commercial use, please purchase a license from   }
{   the author by email at microvolution@hotmail.com    }
{                                                       }
{*******************************************************}

{*******************************************************}
// version 1.0 12/04/25w
{*******************************************************}

// This unit should only be compiled for Windows and Android

interface

{$IFDEF MSWINDOWS}
  procedure DebugOutput(const Msg: string);
{$ENDIF}

{$IFDEF ANDROID}
  procedure DebugAndroidLog(const Msg: string; IncludeTimestamp: Boolean = True);
{$ENDIF}

implementation

uses
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  {$IFDEF ANDROID}
    Androidapi.Log,
  {$ENDIF}
  System.SysUtils;

{$IFDEF MSWINDOWS}
  procedure DebugOutput(const Msg: string);
  begin
      OutputDebugString(PChar('||WMX_DEBUG|| ' + FormatDateTime('hh:nn:ss.zzz', Now) + ' || ' + Msg));
  end;
{$ENDIF}

// Implementação específica para Android
{$IFDEF ANDROID}
  procedure DebugAndroidLog(const Msg: string; IncludeTimestamp: Boolean = True);
  var
    LogMsg: string;
  begin
    if IncludeTimestamp then
      LogMsg := FormatDateTime('hh:nn:ss.zzz', Now) + ' | ' + Msg
    else
      LogMsg := Msg;

    // LOGI para Info (usar LOGE para erros)
    LOGI(PAnsiChar('WMX_AUDIO/' + UTF8Encode(LogMsg)));
  end;
{$ENDIF}

end.
