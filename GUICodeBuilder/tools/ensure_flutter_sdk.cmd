@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI\"
set "FLUTTER_ROOT=%ROOT%.flutter-sdk\flutter"
set "FLUTTER_BIN=%FLUTTER_ROOT%\bin\flutter.bat"
set "DART_BIN=%FLUTTER_ROOT%\bin\cache\dart-sdk\bin\dart.exe"
set "FLUTTER_TOOLS_SNAPSHOT=%FLUTTER_ROOT%\bin\cache\flutter_tools.snapshot"
set "FLUTTER_VERSION=3.41.7"
set "FLUTTER_ZIP=%ROOT%.flutter-sdk\flutter_windows_%FLUTTER_VERSION%-stable.zip"
set "FLUTTER_ZIP_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_%FLUTTER_VERSION%-stable.zip"

if exist "%FLUTTER_BIN%" goto :verify

if not exist "%ROOT%.flutter-sdk" mkdir "%ROOT%.flutter-sdk"
if exist "%FLUTTER_ROOT%" (
  echo Removing incomplete Flutter SDK folder:
  echo %FLUTTER_ROOT%
  rmdir /s /q "%FLUTTER_ROOT%"
  if exist "%FLUTTER_ROOT%" (
    echo Could not remove incomplete Flutter SDK folder.
    echo Close programs using it, delete ".flutter-sdk\flutter", then run again.
    exit /b 1
  )
)
echo Downloading Flutter %FLUTTER_VERSION% archive into:
echo %FLUTTER_ZIP%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%FLUTTER_ZIP_URL%' -OutFile '%FLUTTER_ZIP%'"
if not errorlevel 1 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%FLUTTER_ZIP%' -DestinationPath '%ROOT%.flutter-sdk' -Force"
  if not errorlevel 1 (
    if exist "%FLUTTER_ZIP%" del /f /q "%FLUTTER_ZIP%"
    if exist "%FLUTTER_BIN%" goto :verify
  )
)

if exist "%FLUTTER_ZIP%" del /f /q "%FLUTTER_ZIP%"
if exist "%FLUTTER_ROOT%" rmdir /s /q "%FLUTTER_ROOT%"
echo Flutter archive download failed. Falling back to git clone.

where git >nul 2>nul
if errorlevel 1 (
  echo Git is required for fallback Flutter download.
  echo Install Git or allow access to:
  echo %FLUTTER_ZIP_URL%
  exit /b 1
)
echo Downloading Flutter %FLUTTER_VERSION% into:
echo %FLUTTER_ROOT%
git clone --branch %FLUTTER_VERSION% --depth 1 https://github.com/flutter/flutter.git "%FLUTTER_ROOT%"
if errorlevel 1 (
  if exist "%FLUTTER_ROOT%" rmdir /s /q "%FLUTTER_ROOT%"
  echo Flutter SDK download failed.
  echo Check network/Git access, then run this script again.
  exit /b 1
)

:verify
if not exist "%FLUTTER_BIN%" (
  echo Flutter SDK was not found at:
  echo %FLUTTER_BIN%
  exit /b 1
)

git -C "%FLUTTER_ROOT%" describe --tags --exact-match >nul 2>nul
if errorlevel 1 (
  set "CURRENT_FLUTTER_VERSION=%FLUTTER_VERSION%"
) else (
  for /f "usebackq tokens=*" %%V in (`git -C "%FLUTTER_ROOT%" describe --tags --exact-match`) do set "CURRENT_FLUTTER_VERSION=%%V"
)

if not "%CURRENT_FLUTTER_VERSION%"=="%FLUTTER_VERSION%" (
  echo Flutter SDK is %CURRENT_FLUTTER_VERSION%. Expected %FLUTTER_VERSION%.
  echo If builds fail, remove ".flutter-sdk" and rerun this script.
  exit /b 0
)

if not exist "%DART_BIN%" (
  echo Preparing Flutter cache...
  "%FLUTTER_BIN%" --version
  if errorlevel 1 exit /b 1
)

if not exist "%FLUTTER_TOOLS_SNAPSHOT%" (
  echo Preparing Flutter tool snapshot...
  "%FLUTTER_BIN%" --version
  if errorlevel 1 exit /b 1
)

echo Flutter SDK ready: %CURRENT_FLUTTER_VERSION%

exit /b 0
