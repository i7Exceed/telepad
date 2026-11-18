// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';

class I18n {
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('en'));

  static Locale get currentLocale => localeNotifier.value;

  static void setLocale(Locale newLocale) {
    if (newLocale.languageCode == 'id' || newLocale.languageCode == 'en') {
      localeNotifier.value = newLocale;
    }
  }

  static bool get isIndonesian => localeNotifier.value.languageCode == 'id';

  static String t(String key) {
    final lang = isIndonesian ? 'id' : 'en';
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  static String tf(String key, Map<String, Object> params) {
    var result = t(key);
    params.forEach((k, v) {
      result = result.replaceAll('{$k}', v.toString());
    });
    return result;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'TelePad',
      'subtitle': 'Wireless Controller Relay & Virtual Gamepad Hub',
      'byAuthor': 'by i7Exceed',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'reconnect': 'Reconnect',
      'retry': 'Retry',
      'connecting': 'Connecting...',
      'connected': 'Connected',
      'offline': 'Offline',
      'connectionError': 'Connection Failed',
      'scanServer': 'Find PC',
      'scanAgain': 'Scan Again',
      'scanning': 'Scanning local Wi-Fi for TelePad Server...',
      'scanComplete': 'Scan complete. {count} PC server(s) found.',
      'noServersFound': 'No PC server found on this Wi-Fi network.',
      'emptyDiscoveryTips':
          'Check these 3 steps:\n1. TelePad Server is running on your Windows PC.\n2. Phone and PC are on the same Wi-Fi (AP isolation off).\n3. Windows Firewall allows UDP port {port}.',
      'recentServers': 'Recent PCs',
      'discoveredServers': 'Discovered on Wi-Fi',
      'tapToConnect': 'Tap to connect',
      'cancel': 'Cancel',
      'close': 'Close',
      'save': 'Save',
      'manualConnect': 'Manual Connection',
      'manualIp': 'PC IP Address',
      'manualIpHint': 'e.g. 192.168.1.100',
      'port': 'UDP Port',
      'portHint': '8888',
      'pin': 'PIN Code (optional)',
      'pinHint': 'Leave blank if PIN is disabled on PC',
      'invalidIp': 'Enter a valid IPv4 address (e.g. 192.168.1.100) or hostname.',
      'invalidPort': 'Port must be a number between 1 and 65535.',
      'modePhysical': 'Physical',
      'modeVirtual': 'Virtual',
      'modeTouchpad': 'Touchpad',
      'modePhysicalFull': 'Physical Relay',
      'modeVirtualFull': 'Virtual Gamepad',
      'modeTouchpadFull': 'Virtual Touchpad',
      'amoledSaver': 'AMOLED Saver',
      'amoledActiveNotice': 'AMOLED Black Saver Active — Double-tap anywhere to wake',
      'amoledWakeHint': 'Wake Screen',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Color Theme',
      'hapticIntensity': 'Haptic Vibration',
      'hapticOff': 'Off',
      'hapticLight': 'Light',
      'hapticMedium': 'Medium',
      'hapticHeavy': 'Heavy',
      'deadzone': 'Analog Deadzone',
      'logs': 'Event Logs',
      'clearLogs': 'Clear',
      'logsCleared': 'Event logs cleared.',
      'noLogs': 'No events recorded yet.',
      'helpGuide': 'Setup Guide',
      'moreOptions': 'More options',
      'latency': 'Ping',
      'pingValue': '{ms} ms',
      'rumbleActive': 'Rumble active',
      'diagnosticsTitle': 'Controller Input Test',
      'diagnosticsConnected': 'Live Input Active',
      'diagnosticsStandby': 'Test Inputs Locally',
      'waitingController': 'Connect a USB-C OTG or Bluetooth gamepad to begin.',
      'detectedController': 'Detected: {name}',
      'leftStick': 'Left Stick',
      'rightStick': 'Right Stick',
      'relayInfo':
          'Plug in a GameSir, Razer Kishi, Backbone, or Bluetooth controller. Every button press and stick movement lights up above and relays wirelessly to your PC.',
      'touchpadInfo':
          'Swipe: move cursor • 1-finger tap: left click • 2-finger tap: right click • 2-finger drag or right rail: scroll • Double-tap & hold: drag',
      'scrollRailLabel': 'Scroll',
      'leftClick': 'Left Click',
      'rightClick': 'Right Click',
      'offlineControlsHint': 'Not connected to PC — tap Find PC to send inputs',
      'authSuccess': 'Connected and authenticated with PC ({ip}:{port}).',
      'authFailed': 'Incorrect PIN. Check the PIN in TelePad Server Settings on your PC.',
      'editPin': 'Edit PIN',
      'timeoutError':
          'No response from {ip}:{port}. Make sure TelePad Server is started and Windows Firewall allows UDP port {port}.',
      'heartbeatLost': 'Lost connection to PC server (no heartbeat response).',
      'socketError': 'Network socket error: {error}',
      'setupStep1Title': '1. Prepare Windows PC',
      'setupStep1Body':
          'Install the ViGEmBus virtual controller driver, then launch TelePadServer.exe and click Start TelePad Server.',
      'setupStep2Title': '2. Same Wi-Fi & Firewall',
      'setupStep2Body':
          'Connect both devices to the same local Wi-Fi network (with guest/AP isolation disabled) and allow UDP port 8888 (or your custom port) in Windows Defender Firewall.',
      'setupStep3Title': '3. Choose Your Mode',
      'setupStep3Body':
          'Use Physical Relay for USB-C/Bluetooth controllers (supports AMOLED Saver), Virtual for on-screen Xbox 360 controls, or Touchpad for Windows mouse & scroll.',
      'aboutTitle': 'TelePad v1.0.0',
      'aboutAuthor': 'Open-source MIT • Architected by i7Exceed',
      'aboutCredits': 'Xbox 360 emulation powered by ViGEmBus (Nefarius)',
    },
    'id': {
      'appTitle': 'TelePad',
      'subtitle': 'Relay Kontroler Fisik & Gamepad Virtual Nirkabel',
      'byAuthor': 'oleh i7Exceed',
      'connect': 'Hubungkan',
      'disconnect': 'Putuskan',
      'reconnect': 'Sambung Ulang',
      'retry': 'Coba Lagi',
      'connecting': 'Menghubungkan...',
      'connected': 'Terhubung',
      'offline': 'Terputus',
      'connectionError': 'Koneksi Gagal',
      'scanServer': 'Cari PC',
      'scanAgain': 'Pindai Ulang',
      'scanning': 'Memindai Wi-Fi lokal mencari TelePad Server...',
      'scanComplete': 'Pemindaian selesai. Ditemukan {count} server PC.',
      'noServersFound': 'Tidak ada server PC ditemukan di Wi-Fi ini.',
      'emptyDiscoveryTips':
          'Periksa 3 langkah ini:\n1. TelePad Server sudah dijalankan (Start) di PC Windows.\n2. Ponsel dan PC terhubung ke Wi-Fi yang sama (AP isolation nonaktif).\n3. Windows Firewall mengizinkan port UDP {port}.',
      'recentServers': 'PC Terakhir',
      'discoveredServers': 'Ditemukan di Wi-Fi',
      'tapToConnect': 'Ketuk untuk menghubungkan',
      'cancel': 'Batal',
      'close': 'Tutup',
      'save': 'Simpan',
      'manualConnect': 'Koneksi Manual',
      'manualIp': 'Alamat IP PC',
      'manualIpHint': 'misal 192.168.1.100',
      'port': 'Port UDP',
      'portHint': '8888',
      'pin': 'Kode PIN (opsional)',
      'pinHint': 'Kosongkan jika PIN tidak diaktifkan di PC',
      'invalidIp': 'Masukkan alamat IPv4 yang valid (misal 192.168.1.100) atau hostname.',
      'invalidPort': 'Port harus berupa angka antara 1 hingga 65535.',
      'modePhysical': 'Fisik',
      'modeVirtual': 'Virtual',
      'modeTouchpad': 'Touchpad',
      'modePhysicalFull': 'Relay Fisik',
      'modeVirtualFull': 'Gamepad Virtual',
      'modeTouchpadFull': 'Touchpad Virtual',
      'amoledSaver': 'Penghemat AMOLED',
      'amoledActiveNotice': 'Penghemat Layar AMOLED Aktif — Ketuk 2x di mana saja untuk bangun',
      'amoledWakeHint': 'Buka Layar',
      'settings': 'Pengaturan',
      'language': 'Bahasa',
      'theme': 'Tema Warna',
      'hapticIntensity': 'Getaran Haptik',
      'hapticOff': 'Mati',
      'hapticLight': 'Ringan',
      'hapticMedium': 'Sedang',
      'hapticHeavy': 'Kuat',
      'deadzone': 'Deadzone Analog',
      'logs': 'Log Aktivitas',
      'clearLogs': 'Bersihkan',
      'logsCleared': 'Log aktivitas dibersihkan.',
      'noLogs': 'Belum ada aktivitas yang tercatat.',
      'helpGuide': 'Panduan Setup',
      'moreOptions': 'Opsi lainnya',
      'latency': 'Ping',
      'pingValue': '{ms} ms',
      'rumbleActive': 'Getar aktif',
      'diagnosticsTitle': 'Tes Input Kontroler',
      'diagnosticsConnected': 'Input Langsung Aktif',
      'diagnosticsStandby': 'Uji Input Secara Lokal',
      'waitingController': 'Sambungkan gamepad USB-C OTG atau Bluetooth untuk memulai.',
      'detectedController': 'Terdeteksi: {name}',
      'leftStick': 'Analog Kiri',
      'rightStick': 'Analog Kanan',
      'relayInfo':
          'Pasang stik GameSir, Razer Kishi, Backbone, atau gamepad Bluetooth. Setiap tombol dan analog akan menyala di atas dan diteruskan nirkabel ke PC.',
      'touchpadInfo':
          'Geser: gerak kursor • Ketuk 1 jari: klik kiri • Ketuk 2 jari: klik kanan • Geser 2 jari atau rel kanan: scroll • Ketuk 2x & tahan: drag',
      'scrollRailLabel': 'Scroll',
      'leftClick': 'Klik Kiri',
      'rightClick': 'Klik Kanan',
      'offlineControlsHint': 'Belum terhubung ke PC — ketuk Cari PC untuk mengirim input',
      'authSuccess': 'Terhubung & terautentikasi dengan PC ({ip}:{port}).',
      'authFailed': 'Kode PIN salah. Periksa PIN pada Pengaturan TelePad Server di PC Anda.',
      'editPin': 'Ubah PIN',
      'timeoutError':
          'Tidak ada respons dari {ip}:{port}. Pastikan TelePad Server aktif dan Windows Firewall mengizinkan port UDP {port}.',
      'heartbeatLost': 'Koneksi ke server PC terputus (tidak ada respons heartbeat).',
      'socketError': 'Kesalahan soket jaringan: {error}',
      'setupStep1Title': '1. Siapkan PC Windows',
      'setupStep1Body':
          'Pasang driver controller virtual ViGEmBus, lalu jalankan TelePadServer.exe dan klik Start TelePad Server.',
      'setupStep2Title': '2. Wi-Fi Sama & Firewall',
      'setupStep2Body':
          'Hubungkan ponsel dan PC ke Wi-Fi lokal yang sama (matikan AP isolation) serta izinkan port UDP 8888 (atau port pilihan Anda) di Windows Defender Firewall.',
      'setupStep3Title': '3. Pilih Mode Kontrol',
      'setupStep3Body':
          'Pilih Relay Fisik untuk stik USB-C/Bluetooth (mendukung Penghemat AMOLED), Virtual untuk stik layar Xbox 360, atau Touchpad untuk mouse & scroll Windows.',
      'aboutTitle': 'TelePad v1.0.0',
      'aboutAuthor': 'Open-source MIT • Dikembangkan oleh i7Exceed',
      'aboutCredits': 'Emulasi Xbox 360 didukung oleh ViGEmBus (Nefarius)',
    },
  };
}
