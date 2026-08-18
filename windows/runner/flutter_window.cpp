#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <shellapi.h>

#include <optional>
#include <string>
#include <vector>

#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include "flutter/generated_plugin_registrant.h"
#include "resource.h"

namespace {

constexpr int kOsdWindowWidth = 240;
constexpr int kOsdWindowHeight = 88;
constexpr int kOsdWindowMargin = 24;
constexpr wchar_t kNativeOsdWindowClass[] = L"DRIVER_HUB_NATIVE_OSD";
constexpr UINT_PTR kNativeOsdTimerId = 1;
constexpr UINT kNativeOsdDurationMilliseconds = 3000;
constexpr UINT kTrayCallbackMessage = WM_APP + 1;
constexpr UINT kTrayIconId = 1;
constexpr UINT kTrayRestoreCommand = 1001;
constexpr UINT kTrayExitCommand = 1002;

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return {};
  }

  const int required_size = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, value.data(), static_cast<int>(value.size()),
      nullptr, 0);
  if (required_size == 0) {
    return {};
  }

  std::wstring wide_value(required_size, L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, value.data(),
                      static_cast<int>(value.size()), wide_value.data(),
                      required_size);
  return wide_value;
}

class NativeOsdWindow {
 public:
  void Show(HWND owner, const std::string& title,
            const std::vector<std::string>& lines) {
    title_ = Utf8ToWide(title);
    lines_.clear();
    lines_.reserve(lines.size());
    for (const auto& line : lines) {
      lines_.push_back(Utf8ToWide(line));
    }

    if (!EnsureWindow(owner)) {
      return;
    }

    const HMONITOR monitor =
        MonitorFromWindow(owner, MONITOR_DEFAULTTOPRIMARY);
    MONITORINFO monitor_info{};
    monitor_info.cbSize = sizeof(monitor_info);
    int x = kOsdWindowMargin;
    int y = kOsdWindowMargin;
    if (monitor != nullptr && GetMonitorInfo(monitor, &monitor_info)) {
      x = monitor_info.rcWork.right - kOsdWindowWidth - kOsdWindowMargin;
      y = monitor_info.rcWork.bottom - kOsdWindowHeight - kOsdWindowMargin;
    }

    InvalidateRect(window_, nullptr, FALSE);
    KillTimer(window_, kNativeOsdTimerId);
    SetWindowPos(window_, HWND_TOPMOST, x, y, kOsdWindowWidth,
                 kOsdWindowHeight,
                 SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_SHOWWINDOW);
    SetTimer(window_, kNativeOsdTimerId, kNativeOsdDurationMilliseconds,
             nullptr);
  }

 private:
  static LRESULT CALLBACK WindowProc(HWND window, UINT message, WPARAM wparam,
                                     LPARAM lparam) {
    auto* osd = reinterpret_cast<NativeOsdWindow*>(
        GetWindowLongPtr(window, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
      const auto* const create = reinterpret_cast<CREATESTRUCT*>(lparam);
      osd = static_cast<NativeOsdWindow*>(create->lpCreateParams);
      SetWindowLongPtr(window, GWLP_USERDATA,
                       reinterpret_cast<LONG_PTR>(osd));
      if (osd != nullptr) {
        osd->window_ = window;
      }
    }

    if (osd != nullptr) {
      switch (message) {
        case WM_ERASEBKGND:
          return 1;
        case WM_NCHITTEST:
          return HTTRANSPARENT;
        case WM_SIZE:
          osd->ApplyRoundedRegion();
          return 0;
        case WM_TIMER:
          if (wparam == kNativeOsdTimerId) {
            KillTimer(window, kNativeOsdTimerId);
            ShowWindow(window, SW_HIDE);
          }
          return 0;
        case WM_PAINT:
          osd->Paint();
          return 0;
      }
    }

    return DefWindowProc(window, message, wparam, lparam);
  }

  bool EnsureWindow(HWND owner) {
    if (window_ != nullptr) {
      return true;
    }

    WNDCLASSEXW window_class{};
    window_class.cbSize = sizeof(window_class);
    window_class.lpfnWndProc = WindowProc;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kNativeOsdWindowClass;
    if (RegisterClassExW(&window_class) == 0 &&
        GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
      return false;
    }

    window_ = CreateWindowExW(
        WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW, kNativeOsdWindowClass, L"",
        WS_POPUP, 0, 0, kOsdWindowWidth, kOsdWindowHeight, owner, nullptr,
        GetModuleHandle(nullptr), this);
    return window_ != nullptr;
  }

  void ApplyRoundedRegion() const {
    RECT client{};
    if (!GetClientRect(window_, &client)) {
      return;
    }
    const HRGN region = CreateRoundRectRgn(client.left, client.top,
                                            client.right + 1,
                                            client.bottom + 1, 12, 12);
    if (region != nullptr) {
      SetWindowRgn(window_, region, TRUE);
    }
  }

  void Paint() const {
    PAINTSTRUCT paint{};
    HDC const context = BeginPaint(window_, &paint);
    if (context == nullptr) {
      return;
    }

    RECT client{};
    GetClientRect(window_, &client);
    const HBRUSH background = CreateSolidBrush(RGB(32, 32, 32));
    FillRect(context, &client, background);
    DeleteObject(background);

    SetBkMode(context, TRANSPARENT);
    SetTextColor(context, RGB(255, 255, 255));
    const HFONT title_font = CreateFontW(-14, 0, 0, 0, FW_SEMIBOLD, FALSE,
                                         FALSE, FALSE, DEFAULT_CHARSET,
                                         OUT_DEFAULT_PRECIS,
                                         CLIP_DEFAULT_PRECIS,
                                         CLEARTYPE_QUALITY,
                                         DEFAULT_PITCH | FF_DONTCARE,
                                         L"Segoe UI");
    const HFONT body_font = CreateFontW(-12, 0, 0, 0, FW_NORMAL, FALSE, FALSE,
                                        FALSE, DEFAULT_CHARSET,
                                        OUT_DEFAULT_PRECIS,
                                        CLIP_DEFAULT_PRECIS,
                                        CLEARTYPE_QUALITY,
                                        DEFAULT_PITCH | FF_DONTCARE,
                                        L"Segoe UI");

    const HGDIOBJ previous_font = SelectObject(context, title_font);
    RECT title_rect{12, 9, client.right - 12, 27};
    DrawTextW(context, title_.c_str(), -1, &title_rect,
              DT_SINGLELINE | DT_END_ELLIPSIS | DT_NOPREFIX);

    SelectObject(context, body_font);
    int line_top = 33;
    for (const auto& line : lines_) {
      RECT line_rect{12, line_top, client.right - 12, line_top + 18};
      DrawTextW(context, line.c_str(), -1, &line_rect,
                DT_SINGLELINE | DT_END_ELLIPSIS | DT_NOPREFIX);
      line_top += 19;
    }

    SelectObject(context, previous_font);
    DeleteObject(title_font);
    DeleteObject(body_font);
    EndPaint(window_, &paint);
  }

  HWND window_ = nullptr;
  std::wstring title_;
  std::vector<std::wstring> lines_;
};

NativeOsdWindow native_osd;

void ConfigureOsdWindow(HWND hwnd, HWND child_hwnd) {
  if (hwnd == nullptr) {
    return;
  }

  // Configure the secondary engine's HWND directly; nativeapi's focused-window
  // lookup can return the main window while the hidden OSD engine is starting.
  const LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
  const LONG_PTR frame_styles = WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX |
                                WS_MAXIMIZEBOX | WS_SYSMENU;
  SetWindowLongPtr(hwnd, GWL_STYLE, (style & ~frame_styles) | WS_POPUP);

  const LONG_PTR extended_style = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  const LONG_PTR osd_extended_style =
      (extended_style & ~WS_EX_APPWINDOW) | WS_EX_TOOLWINDOW |
      WS_EX_NOACTIVATE | WS_EX_TRANSPARENT;
  SetWindowLongPtr(hwnd, GWL_EXSTYLE, osd_extended_style);

  int x = 0;
  int y = 0;
  const HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO monitor_info{};
  monitor_info.cbSize = sizeof(monitor_info);
  if (monitor != nullptr && GetMonitorInfo(monitor, &monitor_info)) {
    x = monitor_info.rcWork.right - kOsdWindowWidth - kOsdWindowMargin;
    y = monitor_info.rcWork.bottom - kOsdWindowHeight - kOsdWindowMargin;
  }

  SetWindowPos(hwnd, HWND_TOPMOST, x, y, kOsdWindowWidth, kOsdWindowHeight,
               SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOOWNERZORDER);

  // why: the child Flutter surface was attached before the popup's final
  // client bounds were applied, so synchronize it after the native resize.
  if (child_hwnd != nullptr) {
    RECT client{};
    if (GetClientRect(hwnd, &client)) {
      MoveWindow(child_hwnd, client.left, client.top,
                 client.right - client.left, client.bottom - client.top, TRUE);
    }
  }

  ShowWindow(hwnd, SW_HIDE);
}

}  // namespace

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
  flutter::MethodChannel<> osd_channel(
      flutter_controller_->engine()->messenger(), "driver_hub/osd_overlay",
      &flutter::StandardMethodCodec::GetInstance());
  osd_channel.SetMethodCallHandler(
      [this](const flutter::MethodCall<>& call,
             std::unique_ptr<flutter::MethodResult<>> result) {
        if (call.method_name() != "show") {
          result->NotImplemented();
          return;
        }

        const auto* const arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments", "OSD arguments must be a map");
          return;
        }

        const auto title_entry =
            arguments->find(flutter::EncodableValue("title"));
        const auto lines_entry =
            arguments->find(flutter::EncodableValue("lines"));
        if (title_entry == arguments->end() ||
            lines_entry == arguments->end()) {
          result->Error("invalid_arguments",
                        "OSD arguments require title and lines");
          return;
        }

        const auto* const title =
            std::get_if<std::string>(&title_entry->second);
        const auto* const lines =
            std::get_if<flutter::EncodableList>(&lines_entry->second);
        if (title == nullptr || lines == nullptr || lines->empty()) {
          result->Error("invalid_arguments",
                        "OSD title and at least one text line are required");
          return;
        }

        std::vector<std::string> text_lines;
        text_lines.reserve(lines->size());
        for (const auto& line : *lines) {
          const auto* const text = std::get_if<std::string>(&line);
          if (text == nullptr) {
            result->Error("invalid_arguments", "OSD lines must be text");
            return;
          }
          text_lines.push_back(*text);
        }

        native_osd.Show(GetHandle(), *title, text_lines);
        result->Success();
      });
  DesktopMultiWindowSetWindowCreatedCallback([](void *controller) {
    auto *flutter_view_controller =
        reinterpret_cast<flutter::FlutterViewController *>(controller);
    const HWND view_hwnd = flutter_view_controller->view()->GetNativeWindow();
    const HWND window_hwnd = GetAncestor(view_hwnd, GA_ROOT);
    ConfigureOsdWindow(window_hwnd != nullptr ? window_hwnd : view_hwnd,
                       view_hwnd);
    RegisterPlugins(flutter_view_controller->engine());
    // why: native sizing can occur before the child engine paints its first
    // frame; request the same redraw used by the main runner startup path.
    flutter_view_controller->ForceRedraw();
  });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  taskbar_created_message_ = RegisterWindowMessageW(L"TaskbarCreated");
  AddTrayIcon();

  return true;
}

void FlutterWindow::OnDestroy() {
  RemoveTrayIcon();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_CLOSE) {
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }
  if (message == WM_DESTROY) {
    RemoveTrayIcon();
    PostQuitMessage(0);
    return 0;
  }
  if (taskbar_created_message_ != 0 && message == taskbar_created_message_) {
    AddTrayIcon();
    return 0;
  }
  if (message == kTrayCallbackMessage) {
    switch (LOWORD(lparam)) {
      case WM_LBUTTONUP:
      case WM_LBUTTONDBLCLK:
      case NIN_SELECT:
        RestoreFromTray();
        return 0;
      case WM_RBUTTONUP:
      case WM_CONTEXTMENU:
        ShowTrayMenu();
        return 0;
    }
  }

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
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::AddTrayIcon() {
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }

  NOTIFYICONDATAW icon{};
  icon.cbSize = sizeof(icon);
  icon.hWnd = hwnd;
  icon.uID = kTrayIconId;
  icon.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
  icon.uCallbackMessage = kTrayCallbackMessage;
  icon.hIcon = LoadIconW(GetModuleHandle(nullptr),
                         MAKEINTRESOURCEW(IDI_APP_ICON));
  wcscpy_s(icon.szTip, L"HID Driver Hub");
  if (!Shell_NotifyIconW(NIM_ADD, &icon)) {
    tray_icon_added_ = false;
    return;
  }

  icon.uVersion = NOTIFYICON_VERSION_4;
  Shell_NotifyIconW(NIM_SETVERSION, &icon);
  tray_icon_added_ = true;
}

void FlutterWindow::RemoveTrayIcon() {
  if (!tray_icon_added_) {
    return;
  }
  NOTIFYICONDATAW icon{};
  icon.cbSize = sizeof(icon);
  icon.hWnd = GetHandle();
  icon.uID = kTrayIconId;
  Shell_NotifyIconW(NIM_DELETE, &icon);
  tray_icon_added_ = false;
}

void FlutterWindow::RestoreFromTray() {
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }
  if (IsIconic(hwnd)) {
    ShowWindow(hwnd, SW_RESTORE);
  } else {
    ShowWindow(hwnd, SW_SHOW);
  }
  SetForegroundWindow(hwnd);
  BringWindowToTop(hwnd);
}

void FlutterWindow::ShowTrayMenu() {
  const HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }

  HMENU menu = CreatePopupMenu();
  if (menu == nullptr) {
    return;
  }
  AppendMenuW(menu, MF_STRING, kTrayRestoreCommand, L"Open HID Driver Hub");
  AppendMenuW(menu, MF_STRING, kTrayExitCommand, L"Exit");

  POINT cursor{};
  GetCursorPos(&cursor);
  SetForegroundWindow(hwnd);
  const UINT command = TrackPopupMenu(
      menu, TPM_RETURNCMD | TPM_RIGHTBUTTON, cursor.x, cursor.y, 0, hwnd,
      nullptr);
  DestroyMenu(menu);
  PostMessageW(hwnd, WM_NULL, 0, 0);

  if (command == kTrayRestoreCommand) {
    RestoreFromTray();
  } else if (command == kTrayExitCommand) {
    DestroyWindow(hwnd);
  }
}
