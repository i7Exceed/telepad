// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using TelePadServer.Config;
using TelePadServer.UI;

namespace TelePadServer.Network
{
    public class UdpInputListener : IDisposable
    {
        private UdpClient? _udpServer;
        private CancellationTokenSource? _cts;
        private IPEndPoint? _lastClientEndPoint;
        private readonly object _clientsLock = new();
        private readonly Dictionary<string, ClientSession> _clients = new();

        public event Action<string, bool>? OnButtonReceived;
        public event Action<string, float, float>? OnAnalogReceived;
        public event Action<float, float>? OnMouseMoveReceived;
        public event Action<string, bool>? OnMouseClickReceived;
        public event Action<float>? OnMouseWheelReceived;
        public event Action<string, Color?>? OnLog;

        public long TotalPacketsCount { get; private set; }
        public bool IsRunning { get; private set; }
        public int CurrentPort { get; private set; }
        public string PinCode { get; set; } = string.Empty;

        public static List<string> GetLocalIPv4Addresses()
        {
            var results = new List<string>();
            try
            {
                foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (ni.OperationalStatus != OperationalStatus.Up) continue;
                    if (ni.NetworkInterfaceType == NetworkInterfaceType.Loopback ||
                        ni.NetworkInterfaceType == NetworkInterfaceType.Tunnel) continue;

                    var props = ni.GetIPProperties();
                    foreach (var ua in props.UnicastAddresses)
                    {
                        if (ua.Address.AddressFamily == AddressFamily.InterNetwork &&
                            !IPAddress.IsLoopback(ua.Address))
                        {
                            results.Add(ua.Address.ToString());
                        }
                    }
                }
            }
            catch { }

            return results.Distinct().ToList();
        }

        public int ActiveClientCount
        {
            get
            {
                lock (_clientsLock)
                {
                    return _clients.Count;
                }
            }
        }

        public List<ClientSession> GetActiveSessions()
        {
            lock (_clientsLock)
            {
                return _clients.Values.Select(c => new ClientSession
                {
                    Endpoint = c.Endpoint,
                    Name = c.Name,
                    LastActive = c.LastActive,
                    PacketCount = c.PacketCount,
                    LastPingMs = c.LastPingMs,
                    IsAuthenticated = c.IsAuthenticated
                }).ToList();
            }
        }

        public bool DisconnectClient(string endpoint)
        {
            lock (_clientsLock)
            {
                if (_clients.Remove(endpoint))
                {
                    if (_lastClientEndPoint?.ToString() == endpoint)
                    {
                        _lastClientEndPoint = null;
                    }
                    OnLog?.Invoke(ServerLocalization.Tf("logClientManualDisconnect", ("ep", endpoint)), ThemeTokens.StatusAmber);
                    return true;
                }
            }
            return false;
        }

        public void CleanTimedOutClients(int timeoutSeconds = 5)
        {
            lock (_clientsLock)
            {
                var now = DateTime.Now;
                var toRemove = _clients
                    .Where(kvp => (now - kvp.Value.LastActive).TotalSeconds > timeoutSeconds)
                    .Select(kvp => kvp.Key)
                    .ToList();

                foreach (var key in toRemove)
                {
                    _clients.Remove(key);
                    OnLog?.Invoke(ServerLocalization.Tf("logClientTimeout", ("ep", key)), ThemeTokens.StatusAmber);
                }
            }
        }

        public bool Start(int port, out string errorMessage)
        {
            errorMessage = string.Empty;
            try
            {
                Stop();

                _udpServer = new UdpClient(new IPEndPoint(IPAddress.Any, port))
                {
                    EnableBroadcast = true
                };

                _cts = new CancellationTokenSource();
                IsRunning = true;
                CurrentPort = port;
                TotalPacketsCount = 0;

                _ = ReceiveLoopAsync(_cts.Token);
                OnLog?.Invoke(ServerLocalization.Tf("logUdpActive", ("port", port)), ThemeTokens.FaceY);
                return true;
            }
            catch (Exception ex)
            {
                errorMessage = ex.Message;
                OnLog?.Invoke(ServerLocalization.Tf("logUdpBindFailed", ("port", port), ("err", ex.Message)), ThemeTokens.StatusRed);
                Stop();
                return false;
            }
        }

        public void Stop()
        {
            IsRunning = false;
            CurrentPort = 0;
            _cts?.Cancel();
            try { _udpServer?.Close(); } catch { }
            _udpServer = null;
            _lastClientEndPoint = null;

            lock (_clientsLock)
            {
                _clients.Clear();
            }
        }

        public async Task SendVibrationAsync(byte large, byte small)
        {
            var ep = _lastClientEndPoint;
            if (IsRunning && _udpServer != null && ep != null)
            {
                try
                {
                    string packet = $"VIB|{large}|{small}";
                    byte[] data = Encoding.UTF8.GetBytes(packet);
                    await _udpServer.SendAsync(data, data.Length, ep);
                }
                catch { }
            }
        }

        private async Task ReceiveLoopAsync(CancellationToken token)
        {
            while (!token.IsCancellationRequested && _udpServer != null)
            {
                try
                {
                    var result = await _udpServer.ReceiveAsync(token);
                    string payload = Encoding.UTF8.GetString(result.Buffer).Trim();
                    TotalPacketsCount++;

                    if (payload == "DISCOVER_TELEPAD" || payload == "DISCOVER_SIRPAD")
                    {
                        await RespondToDiscoveryAsync(result.RemoteEndPoint);
                        RegisterClient(result.RemoteEndPoint.ToString(), "Searching", 0, promoteFromSearching: false);
                        continue;
                    }

                    if (payload.StartsWith("AUTH|", StringComparison.OrdinalIgnoreCase))
                    {
                        var parts = payload.Split('|');
                        string receivedPin = parts.Length > 1 ? parts[1] : "";
                        var epStr = result.RemoteEndPoint.ToString();
                        string responseStr;

                        if (string.IsNullOrEmpty(PinCode) || receivedPin == PinCode)
                        {
                            RegisterClient(epStr, "Authenticated Device", 0, promoteFromSearching: true, markAuthenticated: true);
                            _lastClientEndPoint = result.RemoteEndPoint;
                            responseStr = "AUTH_OK";
                            OnLog?.Invoke(ServerLocalization.Tf("logClientAuthenticated", ("ep", epStr)), ThemeTokens.StatusGreen);
                        }
                        else
                        {
                            responseStr = "AUTH_FAIL";
                            OnLog?.Invoke(ServerLocalization.Tf("logClientRejected", ("ep", epStr)), ThemeTokens.StatusRed);
                        }

                        var responseAuth = Encoding.UTF8.GetBytes(responseStr);
                        await _udpServer.SendAsync(responseAuth, responseAuth.Length, result.RemoteEndPoint);
                        continue;
                    }

                    if (payload.StartsWith("PING|", StringComparison.OrdinalIgnoreCase))
                    {
                        var pongResponse = Encoding.UTF8.GetBytes(payload.Replace("PING|", "PONG|"));
                        await _udpServer.SendAsync(pongResponse, pongResponse.Length, result.RemoteEndPoint);

                        if (long.TryParse(payload.Split('|')[1], out long sentTime))
                        {
                            long currentPing = Math.Max(0, DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() - sentTime);
                            _lastClientEndPoint = result.RemoteEndPoint;
                            RegisterClient(result.RemoteEndPoint.ToString(), "Active Device", currentPing, promoteFromSearching: true);
                        }
                        continue;
                    }

                    _lastClientEndPoint = result.RemoteEndPoint;
                    ProcessPayload(payload, result.RemoteEndPoint.ToString());
                }
                catch (OperationCanceledException) { break; }
                catch (ObjectDisposedException) { break; }
                catch (SocketException) { break; }
                catch (Exception ex)
                {
                    OnLog?.Invoke(ServerLocalization.Tf("logPacketWarning", ("err", ex.Message)), ThemeTokens.StatusRed);
                }
            }
        }

        private async Task RespondToDiscoveryAsync(IPEndPoint remoteEndpoint)
        {
            var response = Encoding.UTF8.GetBytes(Environment.MachineName);

            try
            {
                var host = Dns.GetHostEntry(Dns.GetHostName());
                var localIps = host.AddressList.Where(ip => ip.AddressFamily == AddressFamily.InterNetwork).ToList();

                foreach (var localIp in localIps)
                {
                    try
                    {
                        using var tempClient = new UdpClient(new IPEndPoint(localIp, 0)) { EnableBroadcast = true };
                        await tempClient.SendAsync(response, response.Length, remoteEndpoint);

                        var clientIpParts = remoteEndpoint.Address.ToString().Split('.');
                        if (clientIpParts.Length == 4)
                        {
                            clientIpParts[3] = "255";
                            var subnetBroadcast = string.Join(".", clientIpParts);
                            if (IPAddress.TryParse(subnetBroadcast, out var broadcastIp))
                            {
                                await tempClient.SendAsync(response, response.Length, new IPEndPoint(broadcastIp, remoteEndpoint.Port));
                            }
                        }
                    }
                    catch { }
                }

                if (_udpServer != null)
                {
                    await _udpServer.SendAsync(response, response.Length, remoteEndpoint);
                    await _udpServer.SendAsync(response, response.Length, new IPEndPoint(IPAddress.Broadcast, remoteEndpoint.Port));
                }
            }
            catch { }
        }

        public void RegisterClient(
            string endpoint,
            string defaultName,
            long lastPing,
            bool promoteFromSearching = true,
            bool? markAuthenticated = null)
        {
            lock (_clientsLock)
            {
                if (!_clients.TryGetValue(endpoint, out var session))
                {
                    session = new ClientSession
                    {
                        Endpoint = endpoint,
                        Name = defaultName,
                        LastActive = DateTime.Now,
                        PacketCount = 0,
                        IsAuthenticated = markAuthenticated ?? string.IsNullOrEmpty(PinCode)
                    };
                    _clients[endpoint] = session;
                    OnLog?.Invoke(ServerLocalization.Tf("logClientRegistered", ("ep", endpoint)), ThemeTokens.StatusGreen);
                }
                else
                {
                    if (promoteFromSearching &&
                        (session.Name == "Searching" || session.Name == "Client (Searching)"))
                    {
                        session.Name = defaultName;
                    }
                    if (markAuthenticated.HasValue)
                    {
                        session.IsAuthenticated = markAuthenticated.Value;
                    }
                }

                session.LastActive = DateTime.Now;
                session.PacketCount++;
                if (lastPing >= 0 && defaultName != "Searching")
                {
                    if (lastPing > 0 || session.LastPingMs == 0)
                    {
                        session.LastPingMs = lastPing;
                    }
                }
            }
        }

        public void ProcessPayload(string payload, string clientEndpoint)
        {
            RegisterClient(clientEndpoint, "Active Device", -1, promoteFromSearching: true);

            if (!string.IsNullOrEmpty(PinCode))
            {
                lock (_clientsLock)
                {
                    if (_clients.TryGetValue(clientEndpoint, out var session))
                    {
                        if (!session.IsAuthenticated) return;
                    }
                    else return;
                }
            }

            var parts = payload.Split('|');
            if (parts.Length < 2) return;

            string type = parts[0];

            if (type == "B" && parts.Length >= 3)
            {
                string key = parts[1];
                bool isPressed = parts[2] == "1";
                OnButtonReceived?.Invoke(key, isPressed);
            }
            else if (type == "A" && parts.Length == 4)
            {
                string key = parts[1];
                if (float.TryParse(parts[2], NumberStyles.Float, CultureInfo.InvariantCulture, out float x) &&
                    float.TryParse(parts[3], NumberStyles.Float, CultureInfo.InvariantCulture, out float y))
                {
                    OnAnalogReceived?.Invoke(key, x, y);
                }
            }
            else if (type == "M" && parts.Length >= 3)
            {
                if (float.TryParse(parts[1], NumberStyles.Float, CultureInfo.InvariantCulture, out float dx) &&
                    float.TryParse(parts[2], NumberStyles.Float, CultureInfo.InvariantCulture, out float dy))
                {
                    OnMouseMoveReceived?.Invoke(dx, dy);
                }
            }
            else if (type == "MC" && parts.Length >= 3)
            {
                string btn = parts[1];
                bool isPressed = parts[2] == "1";
                OnMouseClickReceived?.Invoke(btn, isPressed);
            }
            else if (type == "MW" && parts.Length >= 2)
            {
                if (float.TryParse(parts[1], NumberStyles.Float, CultureInfo.InvariantCulture, out float dy))
                {
                    OnMouseWheelReceived?.Invoke(dy);
                }
            }
        }

        public void Dispose()
        {
            Stop();
        }
    }
}
