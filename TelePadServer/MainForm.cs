// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Diagnostics;
using System.Drawing;
using System.Threading.Tasks;
using System.Windows.Forms;
using TelePadServer.Config;
using TelePadServer.Emulation;
using TelePadServer.Network;
using TelePadServer.UI;
using TelePadServer.UI.Pages;

namespace TelePadServer
{
    public class MainForm : Form
    {
        private readonly ServerSettings _settings;
        private readonly VirtualControllerManager _controllerManager = new();
        private readonly VirtualMouseManager _mouseManager = new();
        private readonly UdpInputListener _udpListener = new();

        private DateTime? _serverStartTime;
        private byte _lastLargeMotor;
        private byte _lastSmallMotor;
        private bool _isDriverInstalled;
        private bool _isTogglingServer;
        private int _activePageIndex;

        private Icon _iconOffline = null!;
        private Icon _iconOnline = null!;
        private Icon _iconDegraded = null!;

        private Panel _sidebar = null!;
        private Panel _contentHost = null!;
        private Button[] _navButtons = null!;
        private Label _lblBrand = null!;
        private Label _lblAuthor = null!;
        private Label _lblSidebarStatus = null!;
        private Button _btnSidebarStartStop = null!;

        private Control[] _pages = null!;
        private DashboardPage _dashboardPage = null!;
        private ClientsPage _clientsPage = null!;
        private SettingsPage _settingsPage = null!;
        private LogsPage _logsPage = null!;
        private HelpPage _helpPage = null!;

        private System.Windows.Forms.Timer _uiTimer = null!;
        private NotifyIcon _notifyIcon = null!;
        private ToolStripMenuItem _menuTrayOpen = null!;
        private ToolStripMenuItem _menuTrayStartStop = null!;
        private ToolStripMenuItem _menuTrayExit = null!;

        public MainForm()
        {
            _settings = ServerSettings.Load();
            ServerLocalization.CurrentLanguage = _settings.Language;
            _mouseManager.Sensitivity = _settings.MouseSensitivity;
            _udpListener.PinCode = _settings.PinCode;

            _iconOffline = ThemeDrawing.CreateTelePadIcon(ThemeTokens.StatusRed);
            _iconOnline = ThemeDrawing.CreateTelePadIcon(ThemeTokens.StatusGreen);
            _iconDegraded = ThemeDrawing.CreateTelePadIcon(ThemeTokens.StatusAmber);

            InitializeShell();
            WireEvents();
            ApplyLocalization();
        }

        protected override async void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            try
            {
                RefreshDriverStatus();
                RefreshLanAddress();

                if (_settings.StartMinimized)
                {
                    this.WindowState = FormWindowState.Minimized;
                    if (_settings.MinimizeToTrayOnClose)
                    {
                        this.Hide();
                    }
                }

                if (_settings.AutoStartServer)
                {
                    await ToggleServerSafelyAsync();
                }
            }
            catch (Exception ex)
            {
                _logsPage.AppendLog(ServerLocalization.Tf("logPacketWarning", ("err", ex.Message)), ThemeTokens.StatusRed);
            }
        }

        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.F5)
            {
                _ = ToggleServerSafelyAsync();
                return true;
            }
            if (keyData == (Keys.Control | Keys.D1)) { SwitchPage(0); return true; }
            if (keyData == (Keys.Control | Keys.D2)) { SwitchPage(1); return true; }
            if (keyData == (Keys.Control | Keys.D3)) { SwitchPage(2); return true; }
            if (keyData == (Keys.Control | Keys.D4)) { SwitchPage(3); return true; }
            if (keyData == (Keys.Control | Keys.D5)) { SwitchPage(4); return true; }
            return base.ProcessCmdKey(ref msg, keyData);
        }

        private void InitializeShell()
        {
            this.Size = new Size(980, 650);
            this.MinimumSize = new Size(840, 560);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = ThemeTokens.BgCanvas;
            this.ForeColor = ThemeTokens.TextPrimary;
            this.Font = ThemeTokens.FontBody;
            this.Icon = _iconOffline;
            this.KeyPreview = true;

            _notifyIcon = new NotifyIcon { Visible = true, Icon = _iconOffline };
            _notifyIcon.DoubleClick += (s, e) => RestoreFromTray();

            var trayMenu = new ContextMenuStrip
            {
                Renderer = ThemeTokens.CreateTrayMenuRenderer(),
                BackColor = ThemeTokens.BgSurface,
                ForeColor = ThemeTokens.TextPrimary,
                ShowImageMargin = false
            };
            _menuTrayOpen = new ToolStripMenuItem { ForeColor = ThemeTokens.TextPrimary };
            _menuTrayOpen.Click += (s, e) => RestoreFromTray();

            _menuTrayStartStop = new ToolStripMenuItem { ForeColor = ThemeTokens.TextPrimary };
            _menuTrayStartStop.Click += async (s, e) => await ToggleServerSafelyAsync();

            _menuTrayExit = new ToolStripMenuItem { ForeColor = ThemeTokens.TextPrimary };
            _menuTrayExit.Click += (s, e) => Application.Exit();

            trayMenu.Items.AddRange(new ToolStripItem[]
            {
                _menuTrayOpen,
                _menuTrayStartStop,
                new ToolStripSeparator(),
                _menuTrayExit
            });
            _notifyIcon.ContextMenuStrip = trayMenu;

            _sidebar = new Panel
            {
                Dock = DockStyle.Left,
                Width = 230,
                BackColor = ThemeTokens.BgSidebar,
                Padding = new Padding(10, 12, 10, 12)
            };
            _contentHost = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = ThemeTokens.BgCanvas,
                Padding = new Padding(16)
            };

            BuildSidebarUI();
            BuildPagesUI();

            this.Controls.Add(_contentHost);
            this.Controls.Add(_sidebar);

            _uiTimer = new System.Windows.Forms.Timer { Interval = 1000 };
            _uiTimer.Tick += UiTimer_Tick;
            _uiTimer.Start();
        }

        private void BuildSidebarUI()
        {
            var pnlBrand = new Panel { Dock = DockStyle.Top, Height = 76, Padding = new Padding(8, 6, 8, 6) };
            var picBrand = new PictureBox
            {
                Size = new Size(24, 24),
                Location = new Point(8, 12),
                Image = ThemeDrawing.CreateNavBitmap(NavIconKind.Brand, 24, ThemeTokens.AccentCyan),
                SizeMode = PictureBoxSizeMode.CenterImage
            };
            _lblBrand = new Label
            {
                Font = ThemeTokens.FontBrand,
                ForeColor = ThemeTokens.AccentCyan,
                AutoSize = true,
                Location = new Point(38, 6)
            };
            _lblAuthor = new Label
            {
                Font = ThemeTokens.FontCaption,
                ForeColor = ThemeTokens.TextMuted,
                AutoSize = true,
                Location = new Point(40, 40)
            };
            pnlBrand.Controls.AddRange(new Control[] { picBrand, _lblBrand, _lblAuthor });

            var navPanel = new Panel { Dock = DockStyle.Top, Height = 230 };
            NavIconKind[] kinds = { NavIconKind.Dashboard, NavIconKind.Devices, NavIconKind.Settings, NavIconKind.Logs, NavIconKind.Help };
            _navButtons = new Button[kinds.Length];
            for (int i = 0; i < kinds.Length; i++)
            {
                int pageIdx = i;
                var btn = CreateNavButton(kinds[i], i * 44);
                btn.Click += (s, e) => SwitchPage(pageIdx);
                _navButtons[i] = btn;
                navPanel.Controls.Add(btn);
            }

            var pnlBottom = new Panel { Dock = DockStyle.Bottom, Height = 105, Padding = new Padding(4) };
            _lblSidebarStatus = new Label
            {
                ForeColor = ThemeTokens.StatusRed,
                Font = ThemeTokens.FontSmallBold,
                Dock = DockStyle.Top,
                Height = 28,
                TextAlign = ContentAlignment.MiddleLeft
            };

            _btnSidebarStartStop = new Button
            {
                Dock = DockStyle.Bottom,
                Height = 42,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgButtonStart,
                ForeColor = ThemeTokens.AccentCyan,
                Font = ThemeTokens.FontBodyBold,
                Cursor = Cursors.Hand
            };
            _btnSidebarStartStop.FlatAppearance.BorderColor = ThemeTokens.AccentCyan;
            _btnSidebarStartStop.FlatAppearance.MouseOverBackColor = ThemeTokens.BgHoverAccent;
            _btnSidebarStartStop.Click += async (s, e) => await ToggleServerSafelyAsync();

            pnlBottom.Controls.Add(_lblSidebarStatus);
            pnlBottom.Controls.Add(_btnSidebarStartStop);

            _sidebar.Controls.Add(navPanel);
            _sidebar.Controls.Add(pnlBrand);
            _sidebar.Controls.Add(pnlBottom);
        }

        private static Button CreateNavButton(NavIconKind iconKind, int top)
        {
            var btn = new Button
            {
                Top = top,
                Left = 2,
                Width = 206,
                Height = 40,
                FlatStyle = FlatStyle.Flat,
                TextAlign = ContentAlignment.MiddleLeft,
                ImageAlign = ContentAlignment.MiddleLeft,
                TextImageRelation = TextImageRelation.ImageBeforeText,
                Padding = new Padding(10, 0, 8, 0),
                Tag = iconKind,
                Cursor = Cursors.Hand
            };
            btn.FlatAppearance.BorderSize = 0;
            btn.FlatAppearance.MouseOverBackColor = ThemeTokens.BgHover;
            btn.Paint += (s, e) =>
            {
                if (btn.Focused)
                {
                    using var focusPen = new Pen(ThemeTokens.AccentCyan, 1.5f) { DashStyle = System.Drawing.Drawing2D.DashStyle.Dot };
                    e.Graphics.DrawRectangle(focusPen, 1, 1, btn.Width - 3, btn.Height - 3);
                }
            };
            return btn;
        }

        private void BuildPagesUI()
        {
            _dashboardPage = new DashboardPage();
            _clientsPage = new ClientsPage();
            _settingsPage = new SettingsPage(_settings);
            _logsPage = new LogsPage();
            _helpPage = new HelpPage();

            _pages = new Control[] { _dashboardPage, _clientsPage, _settingsPage, _logsPage, _helpPage };
            foreach (var page in _pages)
            {
                page.Visible = false;
                _contentHost.Controls.Add(page);
            }
            SwitchPage(0);
        }

        private void SwitchPage(int index)
        {
            _activePageIndex = index;
            for (int i = 0; i < _pages.Length; i++)
            {
                _pages[i].Visible = (i == index);
                var btn = _navButtons[i];
                bool active = (i == index);
                btn.BackColor = active ? ThemeTokens.BgActiveNav : Color.Transparent;
                btn.ForeColor = active ? ThemeTokens.AccentCyan : ThemeTokens.TextSecondary;
                btn.Font = active ? ThemeTokens.FontBodyBold : ThemeTokens.FontBody;
                if (btn.Tag is NavIconKind kind)
                {
                    btn.Image?.Dispose();
                    btn.Image = ThemeDrawing.CreateNavBitmap(kind, 16, active ? ThemeTokens.AccentCyan : ThemeTokens.TextMuted);
                }
            }
        }

        private void ApplyLocalization()
        {
            this.Text = ServerLocalization.T("appTitle");
            _lblBrand.Text = ServerLocalization.T("brandTitle");
            _lblAuthor.Text = ServerLocalization.T("brandSubtitle");

            string[] navKeys = { "navDashboard", "navClients", "navSettings", "navLogs", "navHelp" };
            for (int i = 0; i < _navButtons.Length; i++)
            {
                string title = ServerLocalization.T(navKeys[i]);
                _navButtons[i].Text = "  " + title;
                _navButtons[i].AccessibleName = title;
            }

            _dashboardPage.ApplyLocalization();
            _clientsPage.ApplyLocalization();
            _settingsPage.ApplyLocalization();
            _logsPage.ApplyLocalization();
            _helpPage.ApplyLocalization(_settings.Port);

            _menuTrayOpen.Text = ServerLocalization.T("trayOpen");
            _menuTrayExit.Text = ServerLocalization.T("trayExit");

            _dashboardPage.SetDriverStatus(_isDriverInstalled);
            UpdateUiServerState(_udpListener.IsRunning);
            RefreshLanAddress();
        }

        private void WireEvents()
        {
            _dashboardPage.StartStopRequested += async () => await ToggleServerSafelyAsync();
            _dashboardPage.RecheckDriverRequested += RefreshDriverStatus;
            _dashboardPage.OpenUrlRequested += OpenExternalUrl;
            _dashboardPage.LogRequested += (msg, col) => _logsPage.AppendLog(msg, col);

            _clientsPage.DisconnectClientRequested += endpoint =>
            {
                if (_udpListener.DisconnectClient(endpoint))
                {
                    _clientsPage.UpdateSessions(_udpListener.GetActiveSessions());
                }
            };

            _settingsPage.SaveRequested += async req => await SaveSettingsAsync(req);
            _helpPage.OpenUrlRequested += OpenExternalUrl;
            _helpPage.LogRequested += (msg, col) => _logsPage.AppendLog(msg, col);

            _udpListener.OnButtonReceived += (key, pressed) =>
            {
                _controllerManager.SetButton(key, pressed);
                _dashboardPage.Visualizer.SetButtonState(key, pressed);
                _dashboardPage.Visualizer.RequestRepaint();
            };

            _udpListener.OnAnalogReceived += (axis, x, y) =>
            {
                _controllerManager.SetAnalog(axis, x, y);
                _dashboardPage.Visualizer.SetAnalogState(axis, x, y);
                _dashboardPage.Visualizer.RequestRepaint();
            };

            _udpListener.OnMouseMoveReceived += (dx, dy) => _mouseManager.Move(dx, dy);
            _udpListener.OnMouseClickReceived += (btn, pressed) => _mouseManager.Click(btn, pressed);
            _udpListener.OnMouseWheelReceived += delta => _mouseManager.Scroll(delta);
            _udpListener.OnLog += (msg, col) => _logsPage.AppendLog(msg, col);

            _controllerManager.OnVibrationFeedback += async (large, small) =>
            {
                if ((large > 0 || small > 0) && _lastLargeMotor == 0 && _lastSmallMotor == 0)
                {
                    _logsPage.AppendLog(ServerLocalization.T("logHapticSent"), ThemeTokens.StatusHaptic);
                }
                _lastLargeMotor = large;
                _lastSmallMotor = small;
                await _udpListener.SendVibrationAsync(large, small);
            };

            _controllerManager.OnControllerStatusChanged += (msg, ok) =>
            {
                _logsPage.AppendLog(msg, ok ? ThemeTokens.AccentCyan : ThemeTokens.StatusAmber);
            };
        }

        private void RefreshDriverStatus()
        {
            _isDriverInstalled = VirtualControllerManager.ProbeDriver(out _);
            _dashboardPage.SetDriverStatus(_isDriverInstalled);
        }

        private void RefreshLanAddress()
        {
            int port = _udpListener.IsRunning ? _udpListener.CurrentPort : _settings.Port;
            _dashboardPage.SetLanAddress(UdpInputListener.GetLocalIPv4Addresses(), port);
        }

        private async Task ToggleServerSafelyAsync()
        {
            if (_isTogglingServer) return;
            _isTogglingServer = true;
            try
            {
                if (_udpListener.IsRunning)
                {
                    if (_udpListener.ActiveClientCount > 0)
                    {
                        var answer = MessageBox.Show(
                            ServerLocalization.Tf("confirmStopBody", ("count", _udpListener.ActiveClientCount)),
                            ServerLocalization.T("confirmStopTitle"),
                            MessageBoxButtons.YesNo,
                            MessageBoxIcon.Question);
                        if (answer != DialogResult.Yes) return;
                    }
                    StopServer();
                }
                else
                {
                    await StartServerAsync();
                }
            }
            catch (Exception ex)
            {
                _logsPage.AppendLog(ServerLocalization.Tf("logPacketWarning", ("err", ex.Message)), ThemeTokens.StatusRed);
            }
            finally
            {
                _isTogglingServer = false;
            }
        }

        private Task StartServerAsync()
        {
            _logsPage.AppendLog(ServerLocalization.T("logStartingDrivers"), ThemeTokens.AccentCyan);
            _isDriverInstalled = _controllerManager.Connect(out string driverError);
            _dashboardPage.SetDriverStatus(_isDriverInstalled);

            if (!_isDriverInstalled)
            {
                _logsPage.AppendLog($"[DEGRADED] {driverError}", ThemeTokens.StatusAmber);
            }

            int port = _settings.Port;
            if (_udpListener.Start(port, out string udpError))
            {
                _serverStartTime = DateTime.Now;
                UpdateUiServerState(true);
                RefreshLanAddress();
            }
            else
            {
                MessageBox.Show(
                    ServerLocalization.Tf("errNetworkBindBody", ("port", port), ("err", udpError)),
                    ServerLocalization.T("errNetworkTitle"),
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                StopServer();
            }

            return Task.CompletedTask;
        }

        private void StopServer()
        {
            _udpListener.Stop();
            _controllerManager.Disconnect();
            _dashboardPage.Visualizer.ResetState();
            _dashboardPage.Visualizer.Invalidate();
            _serverStartTime = null;
            UpdateUiServerState(false);
            RefreshLanAddress();
            _clientsPage.UpdateSessions(_udpListener.GetActiveSessions());
            _logsPage.AppendLog(ServerLocalization.T("logServerStopped"), ThemeTokens.StatusAmber);
        }

        private void UpdateUiServerState(bool online)
        {
            bool degraded = online && !_isDriverInstalled;
            Color stateColor = !online ? ThemeTokens.StatusRed : degraded ? ThemeTokens.StatusAmber : ThemeTokens.StatusGreen;

            _btnSidebarStartStop.Text = online ? ServerLocalization.T("stopServerShortcut") : ServerLocalization.T("startServerShortcut");
            _btnSidebarStartStop.AccessibleName = _btnSidebarStartStop.Text;
            _btnSidebarStartStop.BackColor = online ? ThemeTokens.BgButtonDanger : ThemeTokens.BgButtonStart;
            _btnSidebarStartStop.ForeColor = online ? ThemeTokens.StatusRed : ThemeTokens.AccentCyan;
            _btnSidebarStartStop.FlatAppearance.BorderColor = _btnSidebarStartStop.ForeColor;

            string sidebarText = !online
                ? ServerLocalization.T("statusOffline")
                : degraded
                    ? ServerLocalization.T("statusDegraded")
                    : ServerLocalization.T("statusOnline");

            _lblSidebarStatus.Text = $"●  {sidebarText}";
            _lblSidebarStatus.ForeColor = stateColor;

            string cardStatus = _dashboardPage.SetServerState(online, _isDriverInstalled);
            _menuTrayStartStop.Text = online ? ServerLocalization.T("stopServer") : ServerLocalization.T("startServer");

            var trayIcon = !online ? _iconOffline : degraded ? _iconDegraded : _iconOnline;
            _notifyIcon.Icon = trayIcon;
            this.Icon = trayIcon;
            _notifyIcon.Text = $"TelePad Server ({cardStatus})";
        }

        private async Task SaveSettingsAsync(SettingsSaveRequest req)
        {
            if (!ServerSettings.TryParsePort(req.RawPort, out int newPort))
            {
                _settingsPage.ShowInlineError(ServerLocalization.T("errInvalidPort"));
                return;
            }

            if (!ServerSettings.TryParseSensitivity(req.RawSensitivity, out float newSens))
            {
                _settingsPage.ShowInlineError(ServerLocalization.T("errInvalidSens"));
                return;
            }

            bool portChanged = newPort != _settings.Port;
            _settings.Port = newPort;
            _settings.MouseSensitivity = newSens;
            _mouseManager.Sensitivity = newSens;
            _settings.PinCode = req.PinCode;
            _udpListener.PinCode = req.PinCode;
            _settings.Language = req.Language;
            ServerLocalization.CurrentLanguage = req.Language;
            _settings.MinimizeToTrayOnClose = req.MinimizeToTrayOnClose;
            _settings.StartMinimized = req.StartMinimized;
            _settings.AutoStartServer = req.AutoStartServer;
            _settings.RunOnStartup = req.RunOnStartup;

            if (!_settings.Save(out string saveError))
            {
                _settingsPage.ShowInlineError(ServerLocalization.Tf("errSaveFailed", ("err", saveError)));
                return;
            }

            StartupRegistryService.Apply(_settings.RunOnStartup, Application.ExecutablePath, out _);
            ApplyLocalization();

            if (portChanged && _udpListener.IsRunning)
            {
                StopServer();
                await StartServerAsync();
                MessageBox.Show(
                    ServerLocalization.Tf("msgPortRebound", ("port", newPort)),
                    ServerLocalization.T("msgSettingsTitle"),
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
            else
            {
                MessageBox.Show(
                    ServerLocalization.T("msgSettingsSaved"),
                    ServerLocalization.T("msgSettingsTitle"),
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }

            _logsPage.AppendLog(ServerLocalization.T("logSettingsUpdated"), ThemeTokens.AccentCyan);
        }

        private void UiTimer_Tick(object? sender, EventArgs e)
        {
            TimeSpan? uptime = (_udpListener.IsRunning && _serverStartTime.HasValue)
                ? DateTime.Now - _serverStartTime.Value
                : null;
            _dashboardPage.UpdateMetrics(uptime, _udpListener.TotalPacketsCount, _udpListener.ActiveClientCount);

            _udpListener.CleanTimedOutClients(5);
            if (this.Visible && _activePageIndex == 1)
            {
                _clientsPage.UpdateSessions(_udpListener.GetActiveSessions());
            }
        }

        private static void OpenExternalUrl(string url)
        {
            try
            {
                Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
            }
            catch { }
        }

        private void RestoreFromTray()
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            this.BringToFront();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (e.CloseReason == CloseReason.UserClosing && _settings.MinimizeToTrayOnClose)
            {
                e.Cancel = true;
                this.Hide();
                _notifyIcon.ShowBalloonTip(2000, "TelePad Server", ServerLocalization.T("trayRunningHint"), ToolTipIcon.Info);
                return;
            }

            _uiTimer.Stop();
            _notifyIcon.Dispose();
            StopServer();
            _iconOffline.Dispose();
            _iconOnline.Dispose();
            _iconDegraded.Dispose();
            base.OnFormClosing(e);
        }
    }
}
