unit WMX.AppStateMonitor;
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
// version 1.0 11/04/25w
// creation this is Class
// objective: to monitor whether the Android application
// is in focus or not;
// version 2.0 12/04/25w
// remove all comments lines
{*******************************************************}

// This unit should only be compiled for Android
{$IFNDEF ANDROID}
  interface
  implementation
  end.
{$ELSE}

  interface

  uses
    System.Messaging, FMX.Forms, System.Generics.Collections;

  type
    TAppStateHandler = reference to procedure(Active: Boolean);

    IAppStateMonitor = interface
      ['{B6CC8B6D-1F7B-4F8D-A1A3-9C5D3E7F8C2D}']
      procedure RegisterForm(Form: TForm; Handler: TAppStateHandler);
      procedure UnregisterForm(Form: TForm);
    end;

    TAppStateMonitor = class(TInterfacedObject, IAppStateMonitor)
    private
      FForms: TDictionary<TForm, TAppStateHandler>;
      FCurrentForm: TForm;
      procedure AppEventMessageHandler(const Sender: TObject; const M: TMessage);
      procedure FormActivateHandler(Sender: TObject);
    public
      constructor Create;
      destructor Destroy; override;
      procedure RegisterForm(Form: TForm; Handler: TAppStateHandler);
      procedure UnregisterForm(Form: TForm);
    end;

  implementation

  uses
    FMX.Platform;

  { TAppStateMonitor }

  constructor TAppStateMonitor.Create;
  begin
    inherited;
    FForms := TDictionary<TForm, TAppStateHandler>.Create;
    TMessageManager.DefaultManager.SubscribeToMessage(TApplicationEventMessage, AppEventMessageHandler);
  end;

  destructor TAppStateMonitor.Destroy;
  begin
    TMessageManager.DefaultManager.Unsubscribe(TApplicationEventMessage, AppEventMessageHandler);
    FForms.Free;
    inherited;
  end;

  procedure TAppStateMonitor.RegisterForm(Form: TForm; Handler: TAppStateHandler);
  begin
    FForms.AddOrSetValue(Form, Handler);
    Form.OnActivate := FormActivateHandler;
  end;

  procedure TAppStateMonitor.UnregisterForm(Form: TForm);
  begin
    FForms.Remove(Form);
  end;

  procedure TAppStateMonitor.FormActivateHandler(Sender: TObject);
  begin
    FCurrentForm := TForm(Sender);
  end;

  procedure TAppStateMonitor.AppEventMessageHandler(const Sender: TObject; const M: TMessage);
  var
    Handler: TAppStateHandler;
  begin
    if M is TApplicationEventMessage then
    begin
      case TApplicationEventMessage(M).Value.Event of
        TApplicationEvent.BecameActive:
          if (FCurrentForm <> nil) and FForms.TryGetValue(FCurrentForm, Handler) then
            Handler(True);

        TApplicationEvent.EnteredBackground,
        TApplicationEvent.WillBecomeInactive:
          if (FCurrentForm <> nil) and FForms.TryGetValue(FCurrentForm, Handler) then
            Handler(False);
      end;
    end;
  end;

  end.
{$ENDIF}
