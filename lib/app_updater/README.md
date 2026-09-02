# App Updater: Developer Release & Deployment Guide

This document outlines how to create signed Windows installers, generate AppCast XML feeds, and deploy updates for **HID Driver Hub**.

---

## 1. Windows Authenticode Code Signing (`.pfx`)

Signing your binaries with a digital certificate ensures Windows Defender and SmartScreen recognize your installer as safe and authentic.

### Step A: Generate Certificate on Windows (One-Time)
Run in Administrator PowerShell:
```powershell
# 1. Create a Self-Signed Code Signing Certificate
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject "CN=HID Driver Hub Team" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(5)

# 2. Export to .pfx file (create C:\certs folder first if it doesn't exist)
New-Item -ItemType Directory -Force -Path "C:\certs"
$password = ConvertTo-SecureString -String "HubPass123" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "C:\certs\driver_hub_cert.pfx" -Password $password
```

### Step B: Trust the Certificate Locally on Developer Machine
```powershell
Import-Certificate -FilePath "C:\certs\driver_hub_cert.pfx" -CertStoreLocation "Cert:\LocalMachine\Root"
```

---

## 2. Packaging & Automatic Signing

We have integrated Authenticode signing directly into [`tool/package.dart`](file:///c:/Users/rd02e/Desktop/Software/hid-driver-hub/tool/package.dart).

When you build the release installer:
```powershell
flutter build windows --release
dart run tool/package.dart
```

This automated script:
1. Signs `build/windows/x64/runner/Release/driver_hub.exe`.
2. Compiles Inno Setup installer script (`build/innosetup.iss`).
3. Signs the final output: `build/installer/hid_driver_hub_installer.exe`.

---

## 3. Sparkle / WinSparkle DSA Signing & AppCast XML

In addition to Windows Authenticode (`.pfx`), **WinSparkle** verifies updates using DSA cryptographic signatures inside `appcast.xml`.

### Step A: Generate DSA Keys (One-Time)
```powershell
dart run auto_updater:generate_keys
```
This generates:
- `dsa_priv.pem` (Keep private! Do NOT commit to public Git).
- `dsa_pub.pem` (Included in your repository / Windows resource bundle).

### Step B: Sign the Installer & Generate Signature
```powershell
dart run auto_updater:sign_update build/installer/hid_driver_hub_installer.exe
```
This outputs the DSA signature string:
```text
sparkle:dsaSignature="MC0CFQCWx7...="
```

---

## 4. AppCast XML Feed (`dist/appcast.xml`)

Host this XML file in your GitHub repository (`dist/appcast.xml`) or web server:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>HID Driver Hub Updates</title>
    <link>https://github.com/sumanram23/hid-driver-hub</link>
    <description>Latest updates and improvements for HID Driver Hub</description>
    <language>en</language>
    <item>
      <title>Version 1.0.1</title>
      <sparkle:releaseNotesLink>
        https://github.com/sumanram23/hid-driver-hub/releases/tag/v1.0.1
      </sparkle:releaseNotesLink>
      <pubDate>Wed, 02 Sep 2026 12:00:00 +0000</pubDate>
      <enclosure
        url="https://github.com/sumanram23/hid-driver-hub/releases/download/v1.0.1/hid_driver_hub_installer.exe"
        sparkle:version="1.0.1"
        sparkle:os="windows"
        sparkle:dsaSignature="PASTE_DSA_SIGNATURE_HERE"
        length="52428800"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
```

---

## 5. Releasing an Update Workflow Checklist

1. Update `version` in `pubspec.yaml` (e.g. `version: 1.0.1+2`).
2. Build and package the signed installer:
   ```powershell
   flutter build windows --release
   dart run tool/package.dart
   ```
3. Sign the installer with DSA:
   ```powershell
   dart run auto_updater:sign_update build/installer/hid_driver_hub_installer.exe
   ```
4. Create a GitHub Release with tag `v1.0.1` and upload `build/installer/hid_driver_hub_installer.exe`.
5. Update `dist/appcast.xml` with the new version and DSA signature, then push to `main`.
6. Done! When users click **"Check for Updates"** or restart their app, WinSparkle will automatically detect the new version and offer the update.
