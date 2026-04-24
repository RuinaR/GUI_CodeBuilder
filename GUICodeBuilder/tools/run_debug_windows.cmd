@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI\"
set "APPDATA=%ROOT%.dart-home\AppData"
set "LOCALAPPDATA=%ROOT%.dart-home\LocalAppData"
set "PUB_CACHE=%ROOT%.dart-home\PubCache"
set "FLUTTER_ROOT=%ROOT%.flutter-sdk\flutter"

if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"

"%ROOT%.flutter-sdk\flutter\bin\cache\dart-sdk\bin\dart.exe" ^
  --packages="%ROOT%.flutter-sdk\flutter\packages\flutter_tools\.dart_tool\package_config.json" ^
  "%ROOT%.flutter-sdk\flutter\bin\cache\flutter_tools.snapshot" run -d windows

pause
