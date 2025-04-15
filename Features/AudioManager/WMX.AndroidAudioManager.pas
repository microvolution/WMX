unit WMX.AndroidAudioManager;
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
// version 1.1 10/04/25w
// implementation of directives not to load on windows
// version 1.2 11/04/25w
// creation of the .inc file;
// creation of the VMX.AppState Monitor file to monitor
// whether the Android application is in focus or not;
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
  // sys
  System.SysUtils,
  System.IOUtils, // Adicionado para TPath
  System.Classes,

  // android
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.JavaTypes,
  Androidapi.Helpers,
  Androidapi.JNI.Media,
  Androidapi.Log; // Adicionado para Log

type
  TAndroidAudioManager = class
  private
    FMediaPlayer: JMediaPlayer;
    FAssetManager: JAssetManager;
    FIsLooping: Boolean;
    FCurrentResource: string;
    procedure ReleaseMediaPlayer;
    function GetIsPlaying: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile(const AFileName: string);
    procedure Play;
    procedure Stop;
    procedure SetLooping(ALoop: Boolean);
    procedure Pause;
    procedure Resume;
    procedure DebugLog(const Msg: string);
    property IsPlaying: Boolean read GetIsPlaying;
    procedure SafeRelease;
  end;

implementation

{ TAndroidAudioPlayer }

uses WMX.DebugUtils
;

function TAndroidAudioManager.GetIsPlaying: Boolean;
begin
  Result := False;
  if Assigned(FMediaPlayer) then
    Result := FMediaPlayer.isPlaying;
end;

constructor TAndroidAudioManager.Create;
begin
  inherited;
  FMediaPlayer := TJMediaPlayer.JavaClass.init;
  FAssetManager := TAndroidHelper.Context.getAssets;
  FIsLooping := False;
end;

//destructor TAndroidAudioManager.Destroy;
//begin
//  ReleaseMediaPlayer;
//  inherited;
//end;
//destructor TAndroidAudioManager.Destroy;
//begin
//  // 1. Força a parada segura
//  if Assigned(FMediaPlayer) then
//  begin
//    try
//      // Desativa o looping primeiro
//      FMediaPlayer.setLooping(False);
//
//      if FMediaPlayer.isPlaying then
//      begin
//        FMediaPlayer.stop;
//        Sleep(50); // Pequena pausa para garantir o processamento
//      end;
//
//      FMediaPlayer.release;
//    except
//      on E: Exception do
//        DebugAndroidLog('Destroy error: ' + E.Message);
//    end;
//    FMediaPlayer := nil;
//  end;
//
//  // 2. Limpa referências
//  FAssetManager := nil;
//
//  inherited;
//end;
//destructor TAndroidAudioManager.Destroy;
//begin
//  // Registra para liberação segura
//  TAndroidLifecycleManager.Instance.RegisterObject(Self);
//
//  // Marca para liberação assíncrona
//  TThread.Queue(nil,
//    procedure
//    begin
//      try
//        ReleaseMediaPlayer; // Seu método existente
//        TAndroidLifecycleManager.Instance.UnregisterObject(Self);
//        inherited Destroy;
//      except
//        on E: Exception do
//          DebugAndroidLog('Destruction error: ' + E.Message);
//      end;
//    end);
//end;
destructor TAndroidAudioManager.Destroy;
var
  RetryCount: Integer;
begin
  // 1. Tentativa de liberação segura
  for RetryCount := 1 to 3 do // Tenta no máximo 3 vezes
  begin
    try
      if Assigned(FMediaPlayer) then
      begin
        // Desativa o looping primeiro
        FMediaPlayer.setLooping(False);

        // Para a reprodução se estiver tocando
        if FMediaPlayer.isPlaying then
          FMediaPlayer.stop;

        // Libera os recursos
        FMediaPlayer.release;
        FMediaPlayer := nil;
      end;
      Break; // Sai do loop se bem-sucedido
    except
      on E: Exception do
      begin
        DebugAndroidLog('Destroy attempt ' + IntToStr(RetryCount) + ' failed: ' + E.Message);
        if RetryCount = 3 then
          raise; // Re-lança a exceção na última tentativa
        Sleep(100); // Espera 100ms antes de tentar novamente
      end;
    end;
  end;

  // 2. Liberação final
  inherited;
end;

//procedure TAndroidAudioManager.ReleaseMediaPlayer;
//begin
//  if Assigned(FMediaPlayer) then
//  begin
//    try
//      if FMediaPlayer.isPlaying then
//        FMediaPlayer.stop;
//      FMediaPlayer.release;
//    except
//      on E: Exception do
//        LOGE(PAnsiChar(UTF8Encode('Error releasing MediaPlayer: ' + E.Message)));
//    end;
//    FMediaPlayer := nil;
//  end;
//end;
//procedure TAndroidAudioManager.ReleaseMediaPlayer;
//begin
//  if Assigned(FMediaPlayer) then
//  begin
//    try
//      // Adiciona verificação de estado
//      if FMediaPlayer.isPlaying then
//      begin
//        FMediaPlayer.setLooping(False); // Desativa loop antes de parar
//        FMediaPlayer.stop;
//        Sleep(30); // Pausa mínima
//      end;
//
//      FMediaPlayer.release;
//    except
//      on E: Exception do
//        DebugAndroidLog('ReleaseMediaPlayer error: ' + E.Message);
//    end;
//    FMediaPlayer := nil;
//  end;
//end;
procedure TAndroidAudioManager.ReleaseMediaPlayer;
var
  MP: JMediaPlayer;
begin
  if Assigned(FMediaPlayer) then
  begin
    try
      // Faz uma cópia da referência para evitar race conditions
      MP := FMediaPlayer;
      FMediaPlayer := nil;

      if MP.isPlaying then
      begin
        MP.setLooping(False);
        MP.stop;
        Sleep(50); // Pequena pausa
      end;

      MP.release;
    except
      on E: Exception do
        DebugAndroidLog('ReleaseMediaPlayer error: ' + E.Message);
    end;
  end;
end;

//procedure TAndroidAudioManager.SafeRelease;
//begin
//  TThread.Queue(nil,
//    procedure
//    begin
//      FreeAndNil(Self);
//    end);
//end;
procedure TAndroidAudioManager.SafeRelease;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(100); // Pequeno delay antes de liberar
      Free;
    end).Start;
end;

procedure TAndroidAudioManager.LoadFromFile(const AFileName: string);
var
  LFileDescriptor: JAssetFileDescriptor;
  LFile: JFile;
  LFilePath: JString;
begin
  ReleaseMediaPlayer;
  FMediaPlayer := TJMediaPlayer.JavaClass.init;
  FCurrentResource := AFileName;

  try
    // Tenta carregar de assets primeiro
    LFileDescriptor := FAssetManager.openFd(StringToJString(AFileName));
    FMediaPlayer.setDataSource(LFileDescriptor.getFileDescriptor,
      LFileDescriptor.getStartOffset, LFileDescriptor.getLength);
    LFileDescriptor.close;

    FMediaPlayer.prepare;
    FMediaPlayer.setLooping(FIsLooping);
  except
    // Fallback para arquivo em storage externo
    try
      LFilePath := StringToJString(TPath.Combine(TPath.GetDocumentsPath, AFileName));
      LFile := TJFile.JavaClass.init(LFilePath);

      if LFile.exists then
      begin
        FMediaPlayer.setDataSource(LFilePath);
        FMediaPlayer.prepare;
        FMediaPlayer.setLooping(FIsLooping);
      end;
    except
      on E: Exception do
        LOGE(PAnsiChar(UTF8Encode('Error loading audio file: ' + E.Message)));
    end;
  end;
end;

procedure TAndroidAudioManager.Play;
begin
  if Assigned(FMediaPlayer) then
  begin
    if not FMediaPlayer.isPlaying then
      FMediaPlayer.start;
  end;
end;

procedure TAndroidAudioManager.Stop;
begin
  if Assigned(FMediaPlayer) then
  begin
    if FMediaPlayer.isPlaying then
      FMediaPlayer.stop;
    FMediaPlayer.prepare; // Prepara para próxima execução
  end;
end;

procedure TAndroidAudioManager.SetLooping(ALoop: Boolean);
begin
  FIsLooping := ALoop;
  if Assigned(FMediaPlayer) then
    FMediaPlayer.setLooping(FIsLooping);
end;

procedure TAndroidAudioManager.Pause;
begin
  if Assigned(FMediaPlayer) and FMediaPlayer.isPlaying then
    FMediaPlayer.pause;
end;

//procedure TAndroidAudioManager.Resume;
//begin
//  if Assigned(FMediaPlayer) and not FMediaPlayer.isPlaying then
//    FMediaPlayer.start;
//end;
procedure TAndroidAudioManager.Resume;
begin
  if Assigned(FMediaPlayer) then
  begin
    try
      if not FMediaPlayer.isPlaying then
      begin
        FMediaPlayer.start;
        DebugAndroidLog('Reprodução resumida com sucesso');
      end;
    except
      on E: Exception do
        DebugAndroidLog('Erro ao resumir: ' + E.Message);
    end;
  end;
end;
// Adicione este método para debug
procedure TAndroidAudioManager.DebugLog(const Msg: string);
begin
  {$IFDEF ANDROID}
  LOGI(PAnsiChar(UTF8Encode(Msg)));
  {$ENDIF}
end;

end.
{$ENDIF}
