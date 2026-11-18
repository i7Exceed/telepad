// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using Microsoft.Win32;

namespace TelePadServer.Config
{
    public static class StartupRegistryService
    {
        private const string RunSubKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
        private const string AppValueName = "TelePadServer";

        public static bool Apply(bool runOnStartup, string executablePath, out string errorMessage)
        {
            errorMessage = string.Empty;
            try
            {
                using var key = Registry.CurrentUser.OpenSubKey(RunSubKey, true);
                if (key == null)
                {
                    errorMessage = "Windows startup registry key could not be opened.";
                    return false;
                }

                if (runOnStartup)
                {
                    key.SetValue(AppValueName, $"\"{executablePath}\"");
                }
                else
                {
                    key.DeleteValue(AppValueName, false);
                }
                return true;
            }
            catch (Exception ex)
            {
                errorMessage = ex.Message;
                return false;
            }
        }
    }
}
