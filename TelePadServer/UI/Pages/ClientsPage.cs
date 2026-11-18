// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;
using TelePadServer.Config;
using TelePadServer.Network;

namespace TelePadServer.UI.Pages
{
    public sealed class ClientsPage : UserControl
    {
        private readonly Label _lblClientsHint;
        private readonly DarkListView _lvClients;
        private readonly Button _btnDisconnectClient;

        public event Action<string>? DisconnectClientRequested;

        public ClientsPage()
        {
            this.Dock = DockStyle.Fill;
            this.BackColor = ThemeTokens.BgCanvas;

            var pnlTop = new Panel { Dock = DockStyle.Top, Height = 46, Padding = new Padding(0, 0, 0, 8) };
            _lblClientsHint = new Label
            {
                Dock = DockStyle.Fill,
                ForeColor = ThemeTokens.TextSecondary,
                Font = ThemeTokens.FontBody,
                TextAlign = ContentAlignment.MiddleLeft
            };
            _btnDisconnectClient = new Button
            {
                Dock = DockStyle.Right,
                Width = 220,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgButtonDanger,
                ForeColor = ThemeTokens.StatusRed,
                Font = ThemeTokens.FontSmallBold,
                Cursor = Cursors.Hand,
                Enabled = false
            };
            _lvClients = new DarkListView { Dock = DockStyle.Fill };
            _lvClients.Columns.Add("Endpoint", 170);
            _lvClients.Columns.Add("Device", 150);
            _lvClients.Columns.Add("Auth", 100);
            _lvClients.Columns.Add("Packets", 95);
            _lvClients.Columns.Add("Ping", 95);
            _lvClients.Columns.Add("Last Active", 110);
            _lvClients.SelectedIndexChanged += (s, e) =>
            {
                _btnDisconnectClient.Enabled = _lvClients.SelectedItems.Count > 0;
            };

            _btnDisconnectClient.FlatAppearance.BorderColor = ThemeTokens.StatusRed;
            _btnDisconnectClient.Click += (s, e) =>
            {
                if (_lvClients.SelectedItems.Count > 0)
                {
                    DisconnectClientRequested?.Invoke(_lvClients.SelectedItems[0].Text);
                }
            };

            pnlTop.Controls.Add(_lblClientsHint);
            pnlTop.Controls.Add(_btnDisconnectClient);

            this.Controls.Add(_lvClients);
            this.Controls.Add(pnlTop);
        }

        public void ApplyLocalization()
        {
            _lblClientsHint.Text = ServerLocalization.T("clientsHint");
            _btnDisconnectClient.Text = ServerLocalization.T("disconnectClient");
            _btnDisconnectClient.AccessibleName = ServerLocalization.T("disconnectClient");
            _lvClients.AccessibleName = ServerLocalization.T("navClients");
            _lvClients.Columns[0].Text = ServerLocalization.T("colEndpoint");
            _lvClients.Columns[1].Text = ServerLocalization.T("colName");
            _lvClients.Columns[2].Text = ServerLocalization.T("colAuth");
            _lvClients.Columns[3].Text = ServerLocalization.T("colPackets");
            _lvClients.Columns[4].Text = ServerLocalization.T("colPing");
            _lvClients.Columns[5].Text = ServerLocalization.T("colLastActive");
        }

        public void UpdateSessions(IReadOnlyList<ClientSession> sessions)
        {
            string? selectedKey = _lvClients.SelectedItems.Count > 0 ? _lvClients.SelectedItems[0].Text : null;
            var activeMap = new HashSet<string>(StringComparer.Ordinal);
            foreach (var session in sessions)
            {
                activeMap.Add(session.Endpoint);
            }

            _lvClients.BeginUpdate();
            try
            {
                for (int i = _lvClients.Items.Count - 1; i >= 0; i--)
                {
                    if (!activeMap.Contains(_lvClients.Items[i].Text))
                    {
                        _lvClients.Items.RemoveAt(i);
                    }
                }

                foreach (var s in sessions)
                {
                    ListViewItem? item = null;
                    foreach (ListViewItem existing in _lvClients.Items)
                    {
                        if (existing.Text == s.Endpoint)
                        {
                            item = existing;
                            break;
                        }
                    }

                    string authText = s.IsAuthenticated ? ServerLocalization.T("authVerified") : ServerLocalization.T("authPending");
                    string pingText = s.LastPingMs > 0 ? $"{s.LastPingMs} ms" : ServerLocalization.T("pingPending");
                    string activeText = ServerLocalization.Tf("secondsAgo", ("s", (DateTime.Now - s.LastActive).TotalSeconds.ToString("F0")));

                    if (item == null)
                    {
                        item = new ListViewItem(s.Endpoint);
                        item.SubItems.Add(s.Name);
                        item.SubItems.Add(authText);
                        item.SubItems.Add(s.PacketCount.ToString());
                        item.SubItems.Add(pingText);
                        item.SubItems.Add(activeText);
                        _lvClients.Items.Add(item);
                    }
                    else
                    {
                        item.SubItems[1].Text = s.Name;
                        item.SubItems[2].Text = authText;
                        item.SubItems[3].Text = s.PacketCount.ToString();
                        item.SubItems[4].Text = pingText;
                        item.SubItems[5].Text = activeText;
                    }

                    if (s.Endpoint == selectedKey)
                    {
                        item.Selected = true;
                    }
                }
            }
            finally
            {
                _lvClients.EndUpdate();
            }

            _btnDisconnectClient.Enabled = _lvClients.SelectedItems.Count > 0;
        }
    }
}
