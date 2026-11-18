// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Globalization;
using System.IO;
using System.Text.Json;

namespace TelePadServer.Config
{
    public class ServerSettings
    {
        public int Port { get; set; } = 8888;
        public float MouseSensitivity { get; set; } = 2.0f;
        public bool MinimizeToTrayOnClose { get; set; } = true;
        public bool RunOnStartup { get; set; } = false;
        public bool StartMinimized { get; set; } = false;
        public bool AutoStartServer { get; set; } = false;
        public string PinCode { get; set; } = "";
        public string Language { get; set; } = "en";

        public static string GetSettingsFilePath()
        {
            var portablePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "settings.json");
            if (File.Exists(portablePath))
            {
                return portablePath;
            }

            var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            if (!string.IsNullOrEmpty(appData))
            {
                return Path.Combine(appData, "TelePadServer", "settings.json");
            }

            return portablePath;
        }

        public static bool TryParsePort(string? raw, out int port)
        {
            if (int.TryParse(raw?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out port) &&
                port >= 1 &&
                port <= 65535)
            {
                return true;
            }
            port = 8888;
            return false;
        }

        public static bool TryParseSensitivity(string? raw, out float sensitivity)
        {
            if (float.TryParse(raw?.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out sensitivity) &&
                !float.IsNaN(sensitivity) &&
                !float.IsInfinity(sensitivity) &&
                sensitivity >= 0.1f &&
                sensitivity <= 10.0f)
            {
                return true;
            }
            sensitivity = 2.0f;
            return false;
        }

        public static ServerSettings Load(string? customPath = null)
        {
            var path = customPath ?? GetSettingsFilePath();
            try
            {
                if (File.Exists(path))
                {
                    string json = File.ReadAllText(path);
                    var settings = JsonSerializer.Deserialize<ServerSettings>(json);
                    if (settings != null)
                    {
                        if (settings.Port < 1 || settings.Port > 65535) settings.Port = 8888;
                        if (settings.MouseSensitivity < 0.1f || settings.MouseSensitivity > 10.0f) settings.MouseSensitivity = 2.0f;
                        if (settings.Language != "en" && settings.Language != "id") settings.Language = "en";
                        return settings;
                    }
                }
            }
            catch
            {
                // Fallback safely to defaults on corrupt JSON
            }
            return new ServerSettings();
        }

        public bool Save(out string errorMessage, string? customPath = null)
        {
            errorMessage = string.Empty;
            var path = customPath ?? GetSettingsFilePath();
            try
            {
                var dir = Path.GetDirectoryName(path);
                if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }

                string json = JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(path, json);
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
