@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI\"
set "FLUTTER_ROOT=%ROOT%.flutter-sdk\flutter"
set "FLUTTER_BIN=%FLUTTER_ROOT%\bin\flutter.bat"
set "DART_BIN=%FLUTTER_ROOT%\bin\cache\dart-sdk\bin\dart.exe"
set "FLUTTER_TOOLS_SNAPSHOT=%FLUTTER_ROOT%\bin\cache\flutter_tools.snapshot"
set "FLUTTER_VERSION=3.41.7"

if exist "%FLUTTER_BIN%" goto :verify

where git >nul 2>nul
if errorlevel 1 (
  echo Git is required to download Flutter %FLUTTER_VERSION%.
  echo Install Git, then run this script again.
  exit /b 1
)

if not exist "%ROOT%.flutter-sdk" mkdir "%ROOT%.flutter-sdk"
echo Downloading Flutter %FLUTTER_VERSION% into:
echo %FLUTTER_ROOT%
git clone --branch %FLUTTER_VERSION% --depth 1 https://github.com/flutter/flutter.git "%FLUTTER_ROOT%"
if errorlevel 1 (
  echo Flutter SDK download failed.
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
  echo Flutter SDK is present. Expected tag: %FLUTTER_VERSION%
  echo If builds fail, remove ".flutter-sdk" and rerun this script.
  exit /b 0
)

for /f "usebackq tokens=*" %%V in (`git -C "%FLUTTER_ROOT%" describe --tags --exact-match`) do set "CURRENT_FLUTTER_VERSION=%%V"
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
