#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

std::wstring WindowTitleFromEnvironment() {
  constexpr wchar_t kDefaultTitle[] = L"gui_code_builder";
  constexpr wchar_t kTitleEnvName[] = L"GUI_CODE_BUILDER_WINDOW_TITLE";

  DWORD length = ::GetEnvironmentVariableW(kTitleEnvName, nullptr, 0);
  if (length == 0) {
    return kDefaultTitle;
  }

  std::wstring title(length, L'\0');
  DWORD written =
      ::GetEnvironmentVariableW(kTitleEnvName, title.data(), length);
  if (written == 0) {
    return kDefaultTitle;
  }

  title.resize(written);
  return title.empty() ? kDefaultTitle : title;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  const std::wstring window_title = WindowTitleFromEnvironment();
  if (!window.Create(window_title, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
