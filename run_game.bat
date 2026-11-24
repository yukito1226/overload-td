@echo off
rem ============================================================
rem  Necro Throne TD launcher (Windows)
rem    run_game.bat          : start the game
rem    run_game.bat 10       : debug mode, jump straight into stage 10
rem    run_game.bat debug    : debug mode (F1 panel, separate save)
rem    run_game.bat edit     : open the project in the Godot editor
rem  Godot is searched in: %%GODOT%% env var, .godot_path, tools\,
rem  PATH, Downloads, Desktop, Program Files, scoop, Steam.
rem ============================================================
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
set "MODE=%~1"
set "CFG=%~dp0.godot_path"
if not exist "%~dp0tools" mkdir "%~dp0tools"

if defined GODOT if exist "%GODOT%" goto found
set "GODOT="
if exist "%CFG%" (
  set /p GODOT=<"%CFG%"
  if exist "!GODOT!" goto found
  set "GODOT="
)

for %%F in ("%~dp0tools\Godot_v4*_win64.exe") do set "GODOT=%%~fF"
for /d %%D in ("%~dp0tools\Godot*") do for %%F in ("%%~fD\Godot_v4*_win64.exe") do set "GODOT=%%~fF"
if defined GODOT goto found

for /f "delims=" %%F in ('where godot 2^>nul') do if not defined GODOT set "GODOT=%%F"
if defined GODOT goto found

for %%B in ("%USERPROFILE%\Downloads" "%USERPROFILE%\Desktop" "%LOCALAPPDATA%\Programs" "%ProgramFiles%" "C:\Godot") do (
  for %%F in ("%%~B\Godot_v4*_win64.exe") do set "GODOT=%%~fF"
  for /d %%D in ("%%~B\Godot*") do for %%F in ("%%~fD\Godot_v4*_win64.exe") do set "GODOT=%%~fF"
)
if defined GODOT goto found

if exist "%USERPROFILE%\scoop\apps\godot\current\godot.exe" set "GODOT=%USERPROFILE%\scoop\apps\godot\current\godot.exe"
if defined GODOT goto found
set "STEAMGODOT=%ProgramFiles(x86)%\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"
if exist "%STEAMGODOT%" set "GODOT=%STEAMGODOT%"
if defined GODOT goto found

echo.
echo  Godot 4 was not found.
echo  1. Download "Godot Engine" for Windows (the normal one, not .NET), version 4.3 or newer.
echo  2. Unzip it into the "tools" folder next to this file and run this file again,
echo     or drag Godot_v4.x_win64.exe onto this window and press Enter.
echo.
start "" "https://godotengine.org/download/windows/"
set /p "GODOT=Godot exe path: "
set "GODOT=!GODOT:"=!"
if not exist "!GODOT!" (
  echo  File not found: !GODOT!
  pause
  exit /b 1
)

:found
> "%CFG%" echo !GODOT!
rem Prefer the console build so logs and errors show in this window.
set "CON=!GODOT:_win64.exe=_win64_console.exe!"
if exist "!CON!" set "GODOT=!CON!"
echo Using Godot: !GODOT!

if /i "%MODE%"=="edit" (
  start "" "!GODOT!" -e --path "%~dp0."
  exit /b 0
)
set "ARGS="
if /i "%MODE%"=="debug" set "ARGS=-- --debug"
if not defined ARGS if not "%MODE%"=="" set "ARGS=-- --stage=%MODE%"

"!GODOT!" --path "%~dp0." !ARGS!
if errorlevel 1 pause
