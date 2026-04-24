@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI\"
set "NO_PAUSE=1"
call "%~dp0build_release.cmd"
if errorlevel 1 exit /b 1

start "" /D "%ROOT%" "%ROOT%build\windows\x64\runner\Release\gui_code_builder.exe"
