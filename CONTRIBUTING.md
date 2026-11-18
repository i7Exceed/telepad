# Contributing to TelePad

Thank you for your interest in contributing to **TelePad**! As an open-source project by **i7Exceed**, we welcome contributions ranging from bug fixes and localization to performance optimizations and documentation improvements.

---

## 🛠️ Development Setup

### 1. Windows Server (`TelePadServer`)
* Requires **.NET 10.0 SDK** or newer.
* Requires **ViGEmBus** installed on your Windows development machine.
* To build:
  ```powershell
  cd TelePadServer
  dotnet build --configuration Release
  ```

### 2. Android Mobile Client (`telepad`)
* Requires **Flutter 3.27+** and **Dart 3.6+**.
* To run in debug mode on connected device:
  ```powershell
  cd telepad
  flutter run
  ```

---

## 📜 Contribution Guidelines

1. **Fork & Branch**: Create a feature branch with a descriptive name (`git checkout -b feature/low-latency-tuning`).
2. **SPDX License Headers**: Ensure new source code files include the project license header:
   ```csharp
   // SPDX-License-Identifier: MIT
   // Copyright (c) 2026 i7Exceed. All rights reserved.
   // TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub
   ```
3. **Coding Standards**:
   - Follow standard C# and Dart formatting guidelines (`dotnet format`, `flutter format`).
   - Keep UI strings localized using the localization system in `lib/core/localization.dart`.
4. **Submitting Pull Requests**:
   - Provide a clear summary of changes, rationale, and testing steps.
   - Ensure the builds pass cleanly (`build_all.bat`).
