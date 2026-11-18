// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using TelePadServer.Config;

namespace TelePadServer.UI.Pages
{
    public sealed class DashboardPage : UserControl
    {
        private readonly Label _lblCardStatusTitle;
        private readonly Label _lblCardUptimeTitle;
        private readonly Label _lblCardPacketsTitle;
        private readonly Label _lblCardClientsTitle;
        private readonly Label _lblDashboardStatus;
        private readonly Label _lblUptime;
        private readonly Label _lblTotalPackets;
        private readonly Label _lblClientCount;
        private readonly Label _lblVisualizerHeader;
        private readonly Label _lblPairingHeader;
        private readonly Label _lblLanIpTitle;
        private readonly Label _lblLanIpValue;
        private readonly Button _btnCopyIp;
        private readonly Label _lblDriverStatus;
        private readonly LinkLabel _lnkInstallDriver;
        private readonly Button _btnRecheckDriver;
        private readonly Button _btnStartStop;
        private readonly Label _lblPairingSteps;
        private string _primaryLanIp = string.Empty;

        public GamepadVisualizer Visualizer { get; }

        public event Action? StartStopRequested;
        public event Action? RecheckDriverRequested;
        public event Action<string>? OpenUrlRequested;
        public event Action<string, Color>? LogRequested;

        public DashboardPage()
        {
            this.Dock = DockStyle.Fill;
            this.BackColor = ThemeTokens.BgCanvas;

            var tlpMetrics = new TableLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 92,
                ColumnCount = 4,
                RowCount = 1,
                Margin = new Padding(0, 0, 0, 12)
            };
            for (int i = 0; i < 4; i++)
            {
                tlpMetrics.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 25f));
            }
            tlpMetrics.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));

            tlpMetrics.Controls.Add(CreateMetricCard(ThemeTokens.StatusRed, out _lblCardStatusTitle, out _lblDashboardStatus), 0, 0);
            tlpMetrics.Controls.Add(CreateMetricCard(ThemeTokens.AccentCyan, out _lblCardUptimeTitle, out _lblUptime), 1, 0);
            tlpMetrics.Controls.Add(CreateMetricCard(ThemeTokens.StatusGreen, out _lblCardPacketsTitle, out _lblTotalPackets), 2, 0);
            tlpMetrics.Controls.Add(CreateMetricCard(ThemeTokens.AccentIndigo, out _lblCardClientsTitle, out _lblClientCount), 3, 0);

            var tlpMain = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 1,
                Padding = new Padding(0, 12, 0, 0)
            };
            tlpMain.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 55f));
            tlpMain.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 45f));
            tlpMain.RowStyles.Add(new RowStyle(SizeType.Percent, 100f));

            var pnlVisCard = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = ThemeTokens.BgSurface,
                Padding = new Padding(14),
                Margin = new Padding(0, 0, 8, 0)
            };
            _lblVisualizerHeader = new Label
            {
                Dock = DockStyle.Top,
                Height = 28,
                Font = ThemeTokens.FontCardTitle,
                ForeColor = ThemeTokens.TextPrimary
            };
            Visualizer = new GamepadVisualizer { Dock = DockStyle.Fill };
            pnlVisCard.Controls.Add(Visualizer);
            pnlVisCard.Controls.Add(_lblVisualizerHeader);

            var pnlRight = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = ThemeTokens.BgSurface,
                Padding = new Padding(16),
                Margin = new Padding(8, 0, 0, 0)
            };

            _lblPairingHeader = new Label
            {
                Dock = DockStyle.Top,
                Height = 28,
                Font = ThemeTokens.FontCardTitle,
                ForeColor = ThemeTokens.TextPrimary
            };

            var pnlIpBox = new Panel
            {
                Dock = DockStyle.Top,
                Height = 76,
                BackColor = ThemeTokens.BgField,
                Padding = new Padding(10),
                Margin = new Padding(0, 6, 0, 6)
            };
            _lblLanIpTitle = new Label
            {
                Dock = DockStyle.Top,
                Height = 20,
                Font = ThemeTokens.FontCaptionBold,
                ForeColor = ThemeTokens.TextMuted
            };
            var pnlIpRow = new Panel { Dock = DockStyle.Fill };
            _lblLanIpValue = new Label
            {
                Dock = DockStyle.Fill,
                Font = ThemeTokens.FontMono,
                ForeColor = ThemeTokens.AccentCyan,
                TextAlign = ContentAlignment.MiddleLeft
            };
            _btnCopyIp = new Button
            {
                Dock = DockStyle.Right,
                Width = 88,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgHover,
                ForeColor = ThemeTokens.TextPrimary,
                Font = ThemeTokens.FontCaptionBold,
                Cursor = Cursors.Hand
            };
            _btnCopyIp.FlatAppearance.BorderColor = ThemeTokens.BorderControl;
            _btnCopyIp.Click += (s, e) => CopyPrimaryIp();
            pnlIpRow.Controls.Add(_lblLanIpValue);
            pnlIpRow.Controls.Add(_btnCopyIp);
            pnlIpBox.Controls.Add(pnlIpRow);
            pnlIpBox.Controls.Add(_lblLanIpTitle);

            var pnlDriverBox = new Panel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                Padding = new Padding(0, 8, 0, 8)
            };
            _lblDriverStatus = new Label
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                Font = ThemeTokens.FontSmallBold,
                ForeColor = ThemeTokens.StatusGreen,
                Margin = new Padding(0, 0, 0, 4)
            };
            var pnlDriverLinks = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = true,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                Margin = new Padding(0, 4, 0, 0)
            };
            _lnkInstallDriver = new LinkLabel
            {
                AutoSize = true,
                LinkColor = ThemeTokens.AccentCyan,
                ActiveLinkColor = ThemeTokens.TextPrimary,
                Font = ThemeTokens.FontCaptionBold,
                Margin = new Padding(0, 4, 12, 4)
            };
            _lnkInstallDriver.LinkClicked += (s, e) => OpenUrlRequested?.Invoke("https://github.com/ViGEm/ViGEmBus/releases");

            _btnRecheckDriver = new Button
            {
                AutoSize = true,
                MinimumSize = new Size(88, 28),
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgField,
                ForeColor = ThemeTokens.TextSecondary,
                Font = ThemeTokens.FontCaption,
                Cursor = Cursors.Hand
            };
            _btnRecheckDriver.FlatAppearance.BorderColor = ThemeTokens.BorderControl;
            _btnRecheckDriver.Click += (s, e) => RecheckDriverRequested?.Invoke();

            pnlDriverLinks.Controls.Add(_lnkInstallDriver);
            pnlDriverLinks.Controls.Add(_btnRecheckDriver);
            pnlDriverBox.Controls.Add(pnlDriverLinks);
            pnlDriverBox.Controls.Add(_lblDriverStatus);

            _btnStartStop = new Button
            {
                Dock = DockStyle.Top,
                Height = 44,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgButtonStart,
                ForeColor = ThemeTokens.AccentCyan,
                Font = ThemeTokens.FontInputBold,
                Cursor = Cursors.Hand
            };
            _btnStartStop.FlatAppearance.BorderColor = ThemeTokens.AccentCyan;
            _btnStartStop.FlatAppearance.MouseOverBackColor = ThemeTokens.BgHoverAccent;
            _btnStartStop.Click += (s, e) => StartStopRequested?.Invoke();

            _lblPairingSteps = new Label
            {
                Dock = DockStyle.Fill,
                Padding = new Padding(0, 12, 0, 0),
                Font = ThemeTokens.FontSmall,
                ForeColor = ThemeTokens.TextSecondary
            };

            pnlRight.Controls.Add(_lblPairingSteps);
            pnlRight.Controls.Add(_btnStartStop);
            pnlRight.Controls.Add(pnlDriverBox);
            pnlRight.Controls.Add(pnlIpBox);
            pnlRight.Controls.Add(_lblPairingHeader);

            tlpMain.Controls.Add(pnlVisCard, 0, 0);
            tlpMain.Controls.Add(pnlRight, 1, 0);

            this.Controls.Add(tlpMain);
            this.Controls.Add(tlpMetrics);
        }

        private static Panel CreateMetricCard(Color accent, out Label titleLabel, out Label valueLabel)
        {
            var pnl = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = ThemeTokens.BgSurface,
                Padding = new Padding(12, 10, 12, 10),
                Margin = new Padding(4)
            };

            titleLabel = new Label
            {
                Font = ThemeTokens.FontCaptionBold,
                ForeColor = ThemeTokens.TextMuted,
                Dock = DockStyle.Top,
                Height = 20
            };

            valueLabel = new Label
            {
                Font = ThemeTokens.FontMetricValue,
                ForeColor = accent,
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft
            };

            pnl.Controls.Add(valueLabel);
            pnl.Controls.Add(titleLabel);
            return pnl;
        }

        public void ApplyLocalization()
        {
            _lblCardStatusTitle.Text = ServerLocalization.T("cardStatus");
            _lblCardUptimeTitle.Text = ServerLocalization.T("cardUptime");
            _lblCardPacketsTitle.Text = ServerLocalization.T("cardPackets");
            _lblCardClientsTitle.Text = ServerLocalization.T("cardClients");
            _lblVisualizerHeader.Text = ServerLocalization.T("visualizerTitle");
            _lblPairingHeader.Text = ServerLocalization.T("pairingTitle");
            _lblLanIpTitle.Text = ServerLocalization.T("localIpLabel");
            _btnCopyIp.Text = ServerLocalization.T("copyIp");
            _btnCopyIp.AccessibleName = ServerLocalization.T("copyIp");
            _lnkInstallDriver.Text = ServerLocalization.T("installDriver");
            _lnkInstallDriver.AccessibleName = ServerLocalization.T("installDriver");
            _btnRecheckDriver.Text = ServerLocalization.T("recheckDriver");
            _btnRecheckDriver.AccessibleName = ServerLocalization.T("recheckDriver");
            _lblPairingSteps.Text = ServerLocalization.T("pairingSteps");
        }

        public void SetDriverStatus(bool installed)
        {
            _lblDriverStatus.Text = installed ? ServerLocalization.T("driverReady") : ServerLocalization.T("driverMissing");
            _lblDriverStatus.ForeColor = installed ? ThemeTokens.StatusGreen : ThemeTokens.StatusAmber;
            _lnkInstallDriver.Visible = !installed;
        }

        public void SetLanAddress(IReadOnlyList<string> ips, int port)
        {
            _primaryLanIp = ips.Count > 0 ? ips[0] : string.Empty;
            _btnCopyIp.Enabled = ips.Count > 0;
            _lblLanIpValue.Text = ips.Count > 0
                ? $"{string.Join(" / ", ips.Take(2))} : {port}"
                : ServerLocalization.T("noLanIp");
        }

        public string SetServerState(bool online, bool driverInstalled)
        {
            bool degraded = online && !driverInstalled;
            Color stateColor = !online ? ThemeTokens.StatusRed : degraded ? ThemeTokens.StatusAmber : ThemeTokens.StatusGreen;

            _btnStartStop.Text = online ? ServerLocalization.T("stopServerShortcut") : ServerLocalization.T("startServerShortcut");
            _btnStartStop.AccessibleName = _btnStartStop.Text;
            _btnStartStop.BackColor = online ? ThemeTokens.BgButtonDanger : ThemeTokens.BgButtonStart;
            _btnStartStop.ForeColor = online ? ThemeTokens.StatusRed : ThemeTokens.AccentCyan;
            _btnStartStop.FlatAppearance.BorderColor = _btnStartStop.ForeColor;

            string statusText = !online
                ? ServerLocalization.T("cardStatusOffline")
                : degraded
                    ? ServerLocalization.T("cardStatusDegraded")
                    : ServerLocalization.T("cardStatusOnline");

            _lblDashboardStatus.Text = statusText;
            _lblDashboardStatus.ForeColor = stateColor;
            return statusText;
        }

        public void UpdateMetrics(TimeSpan? uptime, long totalPackets, int clientCount)
        {
            _lblUptime.Text = uptime.HasValue
                ? $"{(int)uptime.Value.TotalHours:D2}:{uptime.Value.Minutes:D2}:{uptime.Value.Seconds:D2}"
                : "00:00:00";
            _lblTotalPackets.Text = totalPackets.ToString("N0", CultureInfo.InvariantCulture);
            _lblClientCount.Text = clientCount.ToString();
        }

        private void CopyPrimaryIp()
        {
            if (string.IsNullOrEmpty(_primaryLanIp)) return;

            if (SafeClipboard.TrySetText(_primaryLanIp, out string err))
            {
                _btnCopyIp.Text = ServerLocalization.T("copiedIp");
                Task.Delay(1600).ContinueWith(_ =>
                {
                    if (!IsDisposed && IsHandleCreated)
                    {
                        BeginInvoke(() => _btnCopyIp.Text = ServerLocalization.T("copyIp"));
                    }
                });
            }
            else
            {
                LogRequested?.Invoke(ServerLocalization.Tf("logClipboardError", ("err", err)), ThemeTokens.StatusAmber);
            }
        }
    }
}
