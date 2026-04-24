#include "flutter_window.h"

#include <shellapi.h>

#include <optional>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/method_call.h"
#include "flutter/standard_method_codec.h"
#include "utils.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  file_drop_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "gui_code_builder/file_drop",
          &flutter::StandardMethodCodec::GetInstance());
  DragAcceptFiles(GetHandle(), TRUE);
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }
  file_drop_channel_ = nullptr;

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_DROPFILES: {
      HDROP drop = reinterpret_cast<HDROP>(wparam);
      UINT file_count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
      flutter::EncodableList paths;
      for (UINT i = 0; i < file_count; ++i) {
        UINT path_length = DragQueryFileW(drop, i, nullptr, 0);
        std::vector<wchar_t> path(path_length + 1);
        DragQueryFileW(drop, i, path.data(), static_cast<UINT>(path.size()));
        paths.push_back(flutter::EncodableValue(Utf8FromUtf16(path.data())));
      }
      DragFinish(drop);
      if (file_drop_channel_) {
        file_drop_channel_->InvokeMethod(
            "filesDropped",
            std::make_unique<flutter::EncodableValue>(std::move(paths)));
      }
      return 0;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
