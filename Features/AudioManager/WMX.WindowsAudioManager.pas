unit WMX.WindowsAudioManager;
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
// version 2.0 12/04/25w
// remove all comments lines
{*******************************************************}

// This unit should only be compiled for Windows

{$IFNDEF MSWINDOWS}
  interface
  implementation
  end.
{$ELSE}

  interface

  uses
    // sys
    System.Classes, System.SysUtils,

    // fmx
    FMX.Media, FMX.Types,

    // win
    Winapi.Windows, System.TypInfo, // Adicione esta unit para OutputDebugString

    // units
    WMX.DebugUtils
    ;
  type
    TPositionChangeEvent = procedure(const CurrentPos, Duration: string) of object;

    TWindowsAudioManager = class
    private
      FMediaPlayer: TMediaPlayer;
      FTimer: TTimer;
      FIsLooping: Boolean;
      FFileName: string;
      FOnPositionChange: TPositionChangeEvent; // novo evento que é executado em segundo plano
      procedure CheckMediaPosition(Sender: TObject);
      function MediaTimeToSeconds(Time: TMediaTime): Double;
      procedure SafeRestart;
    protected
      procedure DoPositionChange(const CurrentPos, Duration: string);
    public
      constructor Create;
      destructor Destroy; override;
      procedure Release;
      procedure LoadFromFile(const AFileName: string);
      procedure Play;
      procedure Stop;
      procedure Pause;
      procedure Resume;
      procedure SetLooping(ALoop: Boolean);
      property IsLooping: Boolean read FIsLooping;
      property OnPositionChange: TPositionChangeEvent read FOnPositionChange write FOnPositionChange;
    end;

  implementation

  { TWindowsAudioManager }

  constructor TWindowsAudioManager.Create;
  begin
    inherited;
    FMediaPlayer := TMediaPlayer.Create(nil);
    FTimer := TTimer.Create(nil);
    FTimer.Interval := 100; // Verifica a cada 100ms (mais preciso) // estava 500
    FTimer.OnTimer := CheckMediaPosition;
    FTimer.Enabled := False;
    FIsLooping := True; // Deixa looping ativado por padrão
  end;

  destructor TWindowsAudioManager.Destroy;
  var
    I: Integer;
  begin
    // 1. Para o timer de forma gradual
    if Assigned(FTimer) then
    begin
      FTimer.OnTimer := nil;
      FTimer.Enabled := False;

      // Espera até 500ms pelo máximo de 5 tentativas
      for I := 1 to 5 do
      begin
        if not FTimer.Enabled then Break;
        Sleep(100); // 100ms entre tentativas
      end;

      FreeAndNil(FTimer);
    end;

    // 2. Libera o media player
    if Assigned(FMediaPlayer) then
    begin
      try
        if FMediaPlayer.State = TMediaState.Playing then
          FMediaPlayer.Stop;
      except
        on E: Exception do
          OutputDebugString(PChar('MediaPlayer stop error: ' + E.Message));
      end;
      FreeAndNil(FMediaPlayer);
    end;

    inherited;
  end;
  procedure TWindowsAudioManager.Release;
  begin
    // Método seguro para liberação externa
    TThread.Queue(nil,
      procedure
      begin
        Self.Free;
      end);
  end;

  procedure TWindowsAudioManager.DoPositionChange(const CurrentPos, Duration: string);
  begin
    if Assigned(FOnPositionChange) then
      FOnPositionChange(CurrentPos, Duration);
  end;

  procedure TWindowsAudioManager.CheckMediaPosition(Sender: TObject);
  const
    LOOP_MARGIN = 3000000; // Aumentamos para 300ms (3000000 unidades de 100-ns)
  var
    CurrentPos, Duration: Double;
  begin
    if FMediaPlayer.State <> TMediaState.Playing then Exit;

    try
      CurrentPos := MediaTimeToSeconds(FMediaPlayer.CurrentTime);
      Duration := MediaTimeToSeconds(FMediaPlayer.Duration);
      DebugOutput(Format('Pos: %.2f/%.2f segundos', [CurrentPos, Duration]));
      // Verificação de final com margem maior
      if (FMediaPlayer.Duration > 0) and
         (FMediaPlayer.CurrentTime >= FMediaPlayer.Duration - LOOP_MARGIN) then
      begin
        if FIsLooping then
        begin
          DebugOutput('Reiniciando música (loop ativado)');
          // Método seguro para reinício
          SafeRestart;
        end
        else
        begin
          DebugOutput('Parando reprodução');
          Stop;
        end;
      end;

      // Atualização da interface com formatação profissional
      DoPositionChange(
        Format('%.2d:%.2d', [Trunc(FMediaPlayer.CurrentTime / 10000000) div 60,  // Minutos
                              Trunc(FMediaPlayer.CurrentTime / 10000000) mod 60]), // Segundos
        Format('%.2d:%.2d', [Trunc(FMediaPlayer.Duration / 10000000) div 60,      // Minutos
                              Trunc(FMediaPlayer.Duration / 10000000) mod 60])     // Segundos
      );
    except
      on E: Exception do
        DebugOutput('CheckMediaPosition Error: ' + E.Message);
    end;
  end;

  procedure TWindowsAudioManager.SafeRestart;
  begin
    FTimer.Enabled := False;
    try
      DebugOutput('Iniciando reinício seguro');

      FMediaPlayer.Stop;
      FMediaPlayer.CurrentTime := 0;

      // Pequena pausa para garantir o reset
      Sleep(50);

      FMediaPlayer.Play;

      DebugOutput('Reinício concluído');
    finally
      FTimer.Enabled := True;
    end;
  end;

  function TWindowsAudioManager.MediaTimeToSeconds(Time: TMediaTime): Double;
  const
    // 1 segundo = 10.000.000 unidades de 100-ns
    UNITS_PER_SECOND = 10000000;
  begin
    Result := Time / UNITS_PER_SECOND;
  end;

  procedure TWindowsAudioManager.LoadFromFile(const AFileName: string);
  begin
    if not FileExists(AFileName) then
      begin
        DebugOutPut(PChar('Erro: Arquivo não encontrado - ' + AFileName));
        raise Exception.Create('||WMX_DEBUG|| ' + 'Arquivo de áudio não encontrado: ' + AFileName);
      end;

    FFileName := AFileName;
    FMediaPlayer.FileName := AFileName;
    DebugOutPut(PChar('Arquivo carregado: ' + AFileName));
    DebugOutput(Format('Duração reportada: %d unidades (%.2f segundos)',
      [FMediaPlayer.Duration, FMediaPlayer.Duration / 10000000]));
  end;

  procedure TWindowsAudioManager.Play;
  begin
    if FMediaPlayer.State = TMediaState.Playing then Exit;

    DebugOutput(Format('Play chamado - Current: %d ms, Duration: %d ms',
      [FMediaPlayer.CurrentTime, FMediaPlayer.Duration]));

    if FMediaPlayer.State <> TMediaState.Playing then
    begin
  //    // Garante que comece do início se estiver no final
      // Reinicia se estiver no final
      if (FMediaPlayer.Duration > 0) and
        (FMediaPlayer.CurrentTime >= FMediaPlayer.Duration - 5000000) then // 500ms
      begin
        DebugOutput('Reiniciando do início');
        FMediaPlayer.CurrentTime := 0;
      end;

      FMediaPlayer.Play;
      FTimer.Enabled := True;
      DebugOutPut('Reprodução iniciada com sucesso');
    end
  end;

  procedure TWindowsAudioManager.Pause;
  begin
    if FMediaPlayer.State = TMediaState.Playing then
    begin
      FMediaPlayer.Stop; // Simula pause
      FTimer.Enabled := False;
    end;
  end;

  procedure TWindowsAudioManager.Resume;
  begin
    if FMediaPlayer.State <> TMediaState.Playing then
    begin
      FMediaPlayer.Play;
      FTimer.Enabled := True;
    end;
  end;

  procedure TWindowsAudioManager.Stop;
  begin
    if not Assigned(FMediaPlayer) or not Assigned(FTimer) then Exit;

    try
      DebugOutput('Stop - Estado antes: ' +
        GetEnumName(TypeInfo(TMediaState), Ord(FMediaPlayer.State)));

      // Desativa o timer de forma segura
      FTimer.Enabled := False;

      // Pequena pausa para garantir a parada
      Sleep(20);

      // Para a reprodução
      FMediaPlayer.Stop;

      DebugOutput('Stop - Estado depois: ' +
        GetEnumName(TypeInfo(TMediaState), Ord(FMediaPlayer.State)));
    except
      on E: Exception do
        DebugOutput('Erro em Stop: ' + E.Message);
    end;
  end;

  procedure TWindowsAudioManager.SetLooping(ALoop: Boolean);
  begin
    FIsLooping := ALoop;
  end;

  end.
{$ENDIF}
