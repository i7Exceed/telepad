// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System.Drawing;
using System.Net;
using System.Net.Sockets;
using System.Text;
using TelePadServer.Config;
using TelePadServer.Emulation;
using TelePadServer.Network;
using TelePadServer.UI;
using TelePadServer.UI.Pages;
using Xunit;

namespace TelePadServer.Tests;

public class ServerSettingsTests
{
    [Theory]
    [InlineData("1", true, 1)]
    [InlineData("8888", true, 8888)]
    [InlineData("65535", true, 65535)]
    [InlineData("0", false, 0)]
    [InlineData("65536", false, 0)]
    [InlineData("-1", false, 0)]
    [InlineData("abc", false, 0)]
    [InlineData(null, false, 0)]
    public void TryParsePort_ValidatesBounds(string? raw, bool expectedValid, int expectedPort)
    {
        bool actual = ServerSettings.TryParsePort(raw, out int port);

        Assert.Equal(expectedValid, actual);
        if (expectedValid)
        {
            Assert.Equal(expectedPort, port);
        }
    }

    [Theory]
    [InlineData("0.1", true, 0.1f)]
    [InlineData("1.0", true, 1.0f)]
    [InlineData("2.5", true, 2.5f)]
    [InlineData("10.0", true, 10.0f)]
    [InlineData("0.05", false, 0f)]
    [InlineData("10.5", false, 0f)]
    [InlineData("bad", false, 0f)]
    [InlineData(null, false, 0f)]
    public void TryParseSensitivity_ValidatesBounds(string? raw, bool expectedValid, float expectedValue)
    {
        bool actual = ServerSettings.TryParseSensitivity(raw, out float sensitivity);

        Assert.Equal(expectedValid, actual);
        if (expectedValid)
        {
            Assert.Equal(expectedValue, sensitivity, precision: 2);
        }
    }

    [Fact]
    public void SaveAndLoad_RoundTripsAllFieldsInCustomPath()
    {
        string tempDir = Path.Combine(Path.GetTempPath(), $"telepad-test-{Guid.NewGuid():N}");
        Directory.CreateDirectory(tempDir);
        string path = Path.Combine(tempDir, "settings.json");

        try
        {
            var original = new ServerSettings
            {
                Port = 9001,
                MouseSensitivity = 2.75f,
                MinimizeToTrayOnClose = false,
                RunOnStartup = false,
                StartMinimized = true,
                AutoStartServer = false,
                PinCode = "4242",
                Language = "id"
            };

            bool saved = original.Save(out string saveError, path);
            Assert.True(saved, saveError);
            Assert.Equal(string.Empty, saveError);

            ServerSettings loaded = ServerSettings.Load(path);
            Assert.Equal(9001, loaded.Port);
            Assert.Equal(2.75f, loaded.MouseSensitivity, precision: 2);
            Assert.False(loaded.MinimizeToTrayOnClose);
            Assert.True(loaded.StartMinimized);
            Assert.False(loaded.AutoStartServer);
            Assert.Equal("4242", loaded.PinCode);
            Assert.Equal("id", loaded.Language);
        }
        finally
        {
            Directory.Delete(tempDir, recursive: true);
        }
    }
}

public class ServerLocalizationTests
{
    [Fact]
    public void EnglishAndIndonesianDictionaries_HaveExactKeyParityAndNonEmptyValues()
    {
        IReadOnlyDictionary<string, string> en = ServerLocalization.GetDictionary("en");
        IReadOnlyDictionary<string, string> id = ServerLocalization.GetDictionary("id");

        Assert.NotEmpty(en);
        Assert.Equal(en.Keys.OrderBy(k => k), id.Keys.OrderBy(k => k));

        foreach (var pair in en)
        {
            Assert.False(string.IsNullOrWhiteSpace(pair.Value), $"EN key '{pair.Key}' is empty");
        }

        foreach (var pair in id)
        {
            Assert.False(string.IsNullOrWhiteSpace(pair.Value), $"ID key '{pair.Key}' is empty");
        }
    }
}

public class UdpInputListenerTests
{
    [Fact]
    public void ProcessPayload_RoutesButtonsAnalogMouseAndEnforcesPin()
    {
        var listener = new UdpInputListener { PinCode = "1234" };
        string? btn = null;
        bool btnState = false;
        string? axis = null;
        float axisX = 0f, axisY = 0f;
        float mouseDx = 0f, mouseDy = 0f;
        string? clickBtn = null;
        bool clickDown = false;
        float wheelDelta = 0f;

        listener.OnButtonReceived += (k, s) => { btn = k; btnState = s; };
        listener.OnAnalogReceived += (a, x, y) => { axis = a; axisX = x; axisY = y; };
        listener.OnMouseMoveReceived += (dx, dy) => { mouseDx = dx; mouseDy = dy; };
        listener.OnMouseClickReceived += (b, d) => { clickBtn = b; clickDown = d; };
        listener.OnMouseWheelReceived += w => wheelDelta = w;

        const string clientEp = "192.168.1.50:55000";

        // Unauthenticated client cannot drive inputs when PIN is set.
        listener.RegisterClient(clientEp, "Searching", 12, promoteFromSearching: false, markAuthenticated: false);
        listener.ProcessPayload("B|A|1", clientEp);
        Assert.Null(btn);

        // Authenticate session and verify promotion from Searching -> Active Device.
        listener.RegisterClient(clientEp, "Authenticated Device", 12, promoteFromSearching: true, markAuthenticated: true);
        Assert.Contains(listener.GetActiveSessions(), s => s.Endpoint == clientEp && s.IsAuthenticated);

        listener.RegisterClient(clientEp, "Active Device", 15, promoteFromSearching: true);
        Assert.Contains(listener.GetActiveSessions(), s => s.Endpoint == clientEp && s.Name == "Active Device");

        listener.ProcessPayload("B|A|1", clientEp);
        Assert.Equal("A", btn);
        Assert.True(btnState);

        listener.ProcessPayload("A|LS|0.5|-0.25", clientEp);
        Assert.Equal("LS", axis);
        Assert.Equal(0.5f, axisX, precision: 2);
        Assert.Equal(-0.25f, axisY, precision: 2);

        listener.ProcessPayload("M|12.5|-4.5", clientEp);
        Assert.Equal(12.5f, mouseDx, precision: 2);
        Assert.Equal(-4.5f, mouseDy, precision: 2);

        listener.ProcessPayload("MC|LEFT|1", clientEp);
        Assert.Equal("LEFT", clickBtn);
        Assert.True(clickDown);

        listener.ProcessPayload("MW|1.5", clientEp);
        Assert.Equal(1.5f, wheelDelta, precision: 2);

        Assert.True(listener.DisconnectClient(clientEp));
        Assert.Equal(0, listener.ActiveClientCount);
    }

    [Fact]
    public async Task LiveLoopbackUdp_DiscoveryAuthAndPingRoundTrip()
    {
        int port = Random.Shared.Next(38000, 48000);
        var listener = new UdpInputListener { PinCode = "7777" };
        bool started = listener.Start(port, out string error);
        Assert.True(started, error);

        try
        {
            using var discoveryClient = new UdpClient(0);
            discoveryClient.Client.ReceiveTimeout = 2000;
            var serverEp = new IPEndPoint(IPAddress.Loopback, port);

            byte[] discoverBytes = Encoding.UTF8.GetBytes("DISCOVER_TELEPAD");
            await discoveryClient.SendAsync(discoverBytes, discoverBytes.Length, serverEp);
            UdpReceiveResult discoverReply = await discoveryClient.ReceiveAsync();
            string discoverText = Encoding.UTF8.GetString(discoverReply.Buffer);
            Assert.Equal(Environment.MachineName, discoverText);

            using var sessionClient = new UdpClient(0);
            sessionClient.Client.ReceiveTimeout = 2000;

            byte[] authBytes = Encoding.UTF8.GetBytes("AUTH|7777");
            await sessionClient.SendAsync(authBytes, authBytes.Length, serverEp);
            UdpReceiveResult authReply = await sessionClient.ReceiveAsync();
            Assert.Equal("AUTH_OK", Encoding.UTF8.GetString(authReply.Buffer));

            byte[] pingBytes = Encoding.UTF8.GetBytes("PING|12345");
            await sessionClient.SendAsync(pingBytes, pingBytes.Length, serverEp);
            UdpReceiveResult pingReply = await sessionClient.ReceiveAsync();
            Assert.Equal("PONG|12345", Encoding.UTF8.GetString(pingReply.Buffer));
        }
        finally
        {
            listener.Stop();
        }
    }
}

public class UiComponentsTests
{
    [Fact]
    public void GamepadVisualizer_ThreadSafeStateAndReset()
    {
        using var viz = new GamepadVisualizer();
        viz.SetButtonState("X", true);
        viz.SetAnalogState("LS", 0.75f, -0.5f);
        viz.SetAnalogState("LT", 0.5f, 0f);

        var snapshot = viz.GetStateSnapshot();
        Assert.Contains("X", snapshot.Pressed);
        Assert.Equal(0.75f, snapshot.LsX, precision: 2);
        Assert.Equal(-0.5f, snapshot.LsY, precision: 2);
        Assert.True(snapshot.Lt > 100);

        viz.ResetState();
        var cleared = viz.GetStateSnapshot();
        Assert.Empty(cleared.Pressed);
        Assert.Equal(0f, cleared.LsX);
        Assert.Equal((byte)0, cleared.Lt);
    }

    [Fact]
    public void ThemeDrawing_CreatesNonEmptyVectorAssets()
    {
        foreach (NavIconKind kind in Enum.GetValues<NavIconKind>())
        {
            using Bitmap bmp18 = ThemeDrawing.CreateNavBitmap(kind, 18, Color.Cyan);
            using Bitmap bmp32 = ThemeDrawing.CreateNavBitmap(kind, 32, Color.Cyan);
            Assert.Equal(18, bmp18.Width);
            Assert.Equal(32, bmp32.Height);
        }

        using Icon appIcon = ThemeDrawing.CreateTelePadIcon(Color.Cyan);
        Assert.True(appIcon.Width > 0);
        Assert.True(appIcon.Height > 0);
    }

    [Fact]
    public void PagesAndSafetyGuards_ApplyLocalizationAndHandleEdgeCases()
    {
        ServerLocalization.CurrentLanguage = "id";
        using var dash = new DashboardPage();
        using var clients = new ClientsPage();
        using var settings = new SettingsPage(new ServerSettings());
        using var logs = new LogsPage();
        using var help = new HelpPage();

        dash.ApplyLocalization();
        clients.ApplyLocalization();
        settings.ApplyLocalization();
        logs.ApplyLocalization();
        help.ApplyLocalization(8888);

        for (int i = 0; i < 510; i++)
        {
            logs.AppendLog($"Entry {i}");
        }

        Assert.False(SafeClipboard.TrySetText(string.Empty, out _));

        using var vcm = new VirtualControllerManager();
        vcm.SetAnalog("LT", 0.5f, 0f);
        vcm.SetAnalog("RT", 0.8f, 0f);

        ServerLocalization.CurrentLanguage = "en";
    }
}
