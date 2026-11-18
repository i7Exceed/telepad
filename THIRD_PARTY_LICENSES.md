# Third-Party Notices & Open Source Licenses

**TelePad** is an open-source project created and maintained by **i7Exceed**.
This document lists the open-source libraries, drivers, dependencies, and third-party intellectual property utilized in TelePad, along with their respective license terms and attribution requirements.

---

## 1. Windows Virtual Gamepad Emulation & Driver

### ViGEmBus Driver & Nefarius.ViGEm.Client
* **Author / Maintainer:** Benjamin Höglinger-Stelzer (Nefarius Software Solutions e.U.)
* **Official Repositories:** 
  * [ViGEmBus](https://github.com/ViGEm/ViGEmBus)
  * [ViGEm.NET Client](https://github.com/ViGEm/ViGEm.NET)
* **License:** MIT License / BSD-3-Clause
* **Purpose:** Provides kernel-mode virtual bus emulation for emulating Xbox 360 and DualShock 4 controllers on Microsoft Windows.
* **Legal Note:** ViGEmBus is a separate kernel-mode driver required by the TelePad Windows Server. TelePad links against `Nefarius.ViGEm.Client` via NuGet to dispatch virtual gamepad reports to the installed driver.

```
Copyright (c) Benjamin Höglinger-Stelzer (Nefarius Software Solutions e.U.)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## 2. Flutter Client Dependencies (Android)

### `gamepads`
* **Maintainer:** Flame Engine / Giancarlo Rocha
* **Repository:** [https://github.com/flame-engine/gamepads](https://github.com/flame-engine/gamepads)
* **License:** MIT License
* **Purpose:** Low-level cross-platform native hardware gamepad event capture on Android devices.

### `vibration`
* **Maintainer:** Ben Kuka
* **Repository:** [https://pub.dev/packages/vibration](https://pub.dev/packages/vibration)
* **License:** MIT License
* **Purpose:** Android haptic and vibration actuator motor management for force-feedback emulation.

### `wakelock_plus`
* **Maintainer:** CreativeCreatorORM & Flutter Community
* **Repository:** [https://github.com/fluttercommunity/plus_plugins](https://github.com/fluttercommunity/plus_plugins)
* **License:** BSD-3-Clause
* **Purpose:** Keeps device screen from falling asleep during active gaming sessions.

---

## 3. Trademarks & Legal Disclaimers

* **Xbox, Xbox 360, and Windows** are registered trademarks of Microsoft Corporation in the United States and other countries.
* **Razer, Razer Kishi, GameSir, Backbone, PlayStation, DualShock**, and other commercial product names, logos, or trademarks referenced in this repository are the property of their respective owners.
* Reference to any third-party products, services, or brands does not constitute or imply endorsement, sponsorship, or affiliation with the TelePad project or its author. All trademarks are used solely for descriptive compatibility and interoperability purposes under fair use.
