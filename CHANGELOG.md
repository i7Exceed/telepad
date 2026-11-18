# Changelog

All notable changes to **TelePad** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-29

### Rebranding & Architecture Modernization
* Rebranded project from SirPad to **TelePad** under official ownership of **i7Exceed**.
* Re-architected C# Windows Server into clean decoupled modules (`UdpInputListener`, `VirtualControllerManager`, `VirtualMouseManager`, `GamepadVisualizer`, `ServerSettings`).
* Re-structured Flutter mobile client with clean modular architecture (`core`, `services`, `features`).
* Implemented full **Internationalization (i18n)** with English (`en`) and Indonesian (`id`) language support.
* Modernized UI design with Cyber Neon Dark Theme (#080A0F background, cyan / indigo / pink neon accents).
* Added high-resolution vector SVG logos and icons (`assets/logo.svg`, `assets/icon.svg`).
* Added graceful ViGEmBus driver detection with user-friendly alerts when driver is missing.
* Added comprehensive open-source legal documentation (`LICENSE`, `THIRD_PARTY_LICENSES.md`, `SECURITY.md`, `CONTRIBUTING.md`).
