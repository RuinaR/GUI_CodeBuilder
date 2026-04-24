@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI\"
set "APPDATA=%ROOT%.dart-home\AppData"
set "LOCALAPPDATA=%ROOT%.dart-home\LocalAppData"
set "PUB_CACHE=%ROOT%.dart-home\PubCache"
set "FLUTTER_ROOT=%ROOT%.flutter-sdk\flutter"

call "%~dp0ensure_flutter_sdk.cmd"
if errorlevel 1 (
  echo.
  echo Flutter SDK setup failed.
  pause
  exit /b 1
)

if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"
if not exist "%ROOT%build\native_assets\windows" mkdir "%ROOT%build\native_assets\windows"
if not exist "%ROOT%.dart_tool\package_config.json" (
  "%ROOT%.flutter-sdk\flutter\bin\cache\dart-sdk\bin\dart.exe" ^
    --packages="%ROOT%.flutter-sdk\flutter\packages\flutter_tools\.dart_tool\package_config.json" ^
    "%ROOT%.flutter-sdk\flutter\bin\cache\flutter_tools.snapshot" pub get
  if errorlevel 1 (
    echo.
    echo Pub get failed.
    pause
    exit /b 1
  )
)
"%ROOT%.flutter-sdk\flutter\bin\cache\dart-sdk\bin\dart.exe" ^
  --packages="%ROOT%.flutter-sdk\flutter\packages\flutter_tools\.dart_tool\package_config.json" ^
  "%ROOT%.flutter-sdk\flutter\bin\cache\flutter_tools.snapshot" build windows --release

if errorlevel 1 (
  echo.
  echo Build failed.
  pause
  exit /b 1
)

echo.
echo Build complete:
echo %ROOT%build\windows\x64\runner\Release\gui_code_builder.exe
if not defined NO_PAUSE pause
