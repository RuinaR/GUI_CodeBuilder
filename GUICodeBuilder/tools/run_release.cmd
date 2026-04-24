@echo off
setlocal

for %%I in ("%~dp0..") do set "ROOT=%%~fI\"
set "EXE=%ROOT%build\windows\x64\runner\Release\gui_code_builder.exe"

if not exist "%EXE%" (
  echo Release executable was not found.
  echo Run build_release.cmd first.
  pause
  exit /b 1
)

start "" /D "%ROOT%" "%EXE%"
