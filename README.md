# HID Driver Hub

A cross-platform (Web & Windows Desktop) HID device configuration driver app built with Flutter.

---

## 1. Build and Deploy Web App (GitHub Pages)

### Step 1: Build the Web release bundle
Run the Flutter web build command with Git Hash and Build Timestamp tracking:
```powershell
powershell -Command "$hash = git rev-parse --short HEAD; $time = Get-Date -Format 'yyyy-MM-dd HH:mm'; flutter build web --release --dart-define=GIT_HASH=$hash --dart-define=BUILD_TIME=$time"
```
This injects the exact Git commit SHA and timestamp into your Web release and updates `build/web/`.

### Step 2: Commit changes in `build/web`
Stage and commit the updated web assets in `build/web`:
```bash
git -C build/web add -A
git -C build/web commit -m "Update web build"
```

### Step 3: Push `build/web` to target GitHub Pages repository

- **Dev Environment (`suman`):**
  ```bash
  git -C build/web push https://github.com/sumanxram23/sumanxram23.github.io.git main --force
  ```

- **Tester Release (`xingui`):**
  ```bash
  git -C build/web push https://<YOUR_PERSONAL_ACCESS_TOKEN>@github.com/xinguisw/xinguisw.github.io.git main --force
  ```
  *(Replace `<YOUR_PERSONAL_ACCESS_TOKEN>` with your GitHub Personal Access Token).*

---

## 2. Build and Package Windows Installer (Inno Setup)

### Prerequisites
- Install **Inno Setup** (e.g., Inno Setup 7 installed at `C:\Program Files\Inno Setup 7\ISCC.exe`).

### Step 1: Build the Windows Release executable
Run the Flutter Windows release build:
```bash
flutter build windows --release
```
This generates the native Windows executable at `build/windows/x64/runner/Release/driver_hub.exe`.

### Step 2: Package the Installer with Inno Setup
Run the packaging script:
```bash
dart run tool/package.dart
```

### Output Location
Upon completion, the installer executable will be generated at:
```
build/installer/hid_driver_hub_installer.exe
```

---

## 3. Architecture & Execution Flows Documentation

- **[Unified Architecture Dashboard (`index.html`)](file:///c:/Users/USER/Desktop/Software/hid-driver-hub/docs/flows/index.html)**: **Primary Interactive Hub** containing all 11 execution sequences, MVC overviews, settings communication, macro studio lifecycles, and layer-by-layer diagnostics.
- **[System Architecture Documentation](file:///c:/Users/USER/Desktop/Software/hid-driver-hub/docs/Architecture_Documentation.md)**: Decoupled 6-layer architecture, BLoC state staging, and resilience matrix.
- **[Flow Diagrams Index (`docs/flows/README.md`)](file:///c:/Users/USER/Desktop/Software/hid-driver-hub/docs/flows/README.md)**: Index and reconciliation logs for all diagrams.
- **[Protocol Engineering & ATK/Telink Reference](file:///c:/Users/USER/Desktop/Software/hid-driver-hub/docs/PROTOCOL_HANDSHAKE_AND_ATK_REFERENCE.md)**: Comprehensive packet breakdown, challenge-response handshake dynamics, CID/MID/Type mappings, opcode references, and write error handling for Telink B80 and ATK (Compx) protocols.

