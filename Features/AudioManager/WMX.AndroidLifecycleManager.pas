unit WMX.AndroidLifeCycleManager;
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
{                 https://mvinfo.wmx.net.br             }
{                                                       }
{   All rights reserved. Free for non-commercial use.   }
{  For commercial use, please purchase a license from   }
{   the author by email at microvolution@hotmail.com    }
{                                                       }
{*******************************************************}

{*******************************************************}
// version 1.0 06/04/25w
// creation of the Class
{*******************************************************}

// This unit should only be compiled for Android
{$IFNDEF ANDROID}
  interface
  implementation
  end.
{$ELSE}
  interface

  uses
    System.Generics.Collections, // Adicionar esta unit
    Androidapi.JNI.JavaTypes
    ;

  type
    TAndroidLifecycleManager = class
    private
      class var FInstance: TAndroidLifecycleManager;
      FActiveObjects: TList<TObject>;
    public
      constructor Create;
      destructor Destroy; override;
      procedure RegisterObject(AObject: TObject);
      procedure UnregisterObject(AObject: TObject);
      class function Instance: TAndroidLifecycleManager;
    end;

  implementation

  { TAndroidLifecycleManager }

  constructor TAndroidLifecycleManager.Create;
  begin
    inherited;
    FActiveObjects := TList<TObject>.Create;
  end;

  destructor TAndroidLifecycleManager.Destroy;
  begin
    // Limpeza segura de todos os objetos registrados
    while FActiveObjects.Count > 0 do
    begin
      FActiveObjects.Last.Free;
      FActiveObjects.Delete(FActiveObjects.Count - 1);
    end;
    FActiveObjects.Free;
    inherited;
  end;

  class function TAndroidLifecycleManager.Instance: TAndroidLifecycleManager;
  begin
    if FInstance = nil then
      FInstance := TAndroidLifecycleManager.Create;
    Result := FInstance;
  end;

  procedure TAndroidLifecycleManager.RegisterObject(AObject: TObject);
  begin
    FActiveObjects.Add(AObject);
  end;

  procedure TAndroidLifecycleManager.UnregisterObject(AObject: TObject);
  begin
    FActiveObjects.Remove(AObject);
  end;

  initialization

  finalization
    TAndroidLifecycleManager.FInstance.Free;

  end.
{$ENDIF}
