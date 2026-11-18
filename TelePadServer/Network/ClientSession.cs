// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;

namespace TelePadServer.Network
{
    public class ClientSession
    {
        public string Endpoint { get; set; } = string.Empty;
        public string Name { get; set; } = "TelePad Client";
        public DateTime LastActive { get; set; } = DateTime.Now;
        public int PacketCount { get; set; }
        public long LastPingMs { get; set; }
        public bool IsAuthenticated { get; set; }
    }
}
