// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Drawing;
using System.Globalization;
using System.Windows.Forms;
using TelePadServer.Config;

namespace TelePadServer.UI.Pages
{
    public sealed class SettingsPage : UserControl
    {
        private readonly Label _lblPortLabel;
        private readonly TextBox _txtPort;
        private readonly Label _lblSensLabel;
        private readonly TextBox _txtSensitivity;
        private readonly Label _lblPinLabel;
        private readonly TextBox _txtPin;
        private readonly Button _btnTogglePin;
        private readonly Label _lblLangLabel;
        private readonly ComboBox _cmbLanguage;
        private readonly CheckBox _chkMinimizeTray;
        private readonly CheckBox _chkStartMinimized;
        private readonly CheckBox _chkAutoStartServer;
        private readonly CheckBox _chkRunStartup;
        private readonly Label _lblSettingsError;
        private readonly Button _btnSaveSettings;
        private readonly Button _btnResetSettings;

        public event Action<SettingsSaveRequest>? SaveRequested;

        public SettingsPage(ServerSettings initialSettings)
        {
            this.Dock = DockStyle.Fill;
            this.BackColor = ThemeTokens.BgCanvas;

            var scrollHost = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(4)
            };

            var contentRoot = new Panel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink
            };

            // Responsive 2-column percentage grid prevents horizontal overflow at 840x560 min window.
            var grid = new TableLayoutPanel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                ColumnCount = 2,
                RowCount = 2,
                Padding = new Padding(0, 0, 0, 8)
            };
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50f));
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50f));

            _txtPort = CreateFormTextBox(initialSettings.Port.ToString());
            _txtSensitivity = CreateFormTextBox(initialSettings.MouseSensitivity.ToString(CultureInfo.InvariantCulture));
            _txtPin = CreateFormTextBox(initialSettings.PinCode);
            _txtPin.UseSystemPasswordChar = true;
            _txtPin.Dock = DockStyle.Fill;

            var pnlPinRow = new Panel { Dock = DockStyle.Top, Height = 30 };
            _btnTogglePin = new Button
            {
                Dock = DockStyle.Right,
                Width = 68,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgSurface,
                ForeColor = ThemeTokens.TextSecondary,
                Font = ThemeTokens.FontCaption,
                Cursor = Cursors.Hand
            };
            _btnTogglePin.FlatAppearance.BorderColor = ThemeTokens.BorderControl;
            _btnTogglePin.Click += (s, e) =>
            {
                _txtPin.UseSystemPasswordChar = !_txtPin.UseSystemPasswordChar;
                _btnTogglePin.Text = _txtPin.UseSystemPasswordChar ? ServerLocalization.T("showPin") : ServerLocalization.T("hidePin");
            };
            pnlPinRow.Controls.Add(_txtPin);
            pnlPinRow.Controls.Add(_btnTogglePin);

            _cmbLanguage = CreateDarkLanguageCombo(initialSettings.Language);

            grid.Controls.Add(CreateFieldGroup(out _lblPortLabel, _txtPort, new Padding(0, 0, 12, 12)), 0, 0);
            grid.Controls.Add(CreateFieldGroup(out _lblSensLabel, _txtSensitivity, new Padding(12, 0, 0, 12)), 1, 0);
            grid.Controls.Add(CreateFieldGroup(out _lblPinLabel, pnlPinRow, new Padding(0, 0, 12, 12)), 0, 1);
            grid.Controls.Add(CreateFieldGroup(out _lblLangLabel, _cmbLanguage, new Padding(12, 0, 0, 12)), 1, 1);

            _chkMinimizeTray = CreateFormCheckBox(initialSettings.MinimizeToTrayOnClose);
            _chkStartMinimized = CreateFormCheckBox(initialSettings.StartMinimized);
            _chkAutoStartServer = CreateFormCheckBox(initialSettings.AutoStartServer);
            _chkRunStartup = CreateFormCheckBox(initialSettings.RunOnStartup);

            var pnlChecks = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                FlowDirection = FlowDirection.TopDown,
                AutoSize = true,
                WrapContents = false,
                Padding = new Padding(0, 6, 0, 8)
            };
            pnlChecks.Controls.AddRange(new Control[] { _chkMinimizeTray, _chkStartMinimized, _chkAutoStartServer, _chkRunStartup });

            _lblSettingsError = new Label
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                ForeColor = ThemeTokens.StatusRed,
                Font = ThemeTokens.FontSmallBold,
                Visible = false,
                Padding = new Padding(0, 4, 0, 8)
            };

            var pnlButtons = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                FlowDirection = FlowDirection.LeftToRight,
                AutoSize = true,
                WrapContents = true,
                Padding = new Padding(0, 8, 0, 0)
            };
            _btnSaveSettings = new Button
            {
                Width = 200,
                Height = 40,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.AccentCyan,
                ForeColor = ThemeTokens.TextOnAccent,
                Font = ThemeTokens.FontBodyBold,
                Cursor = Cursors.Hand
            };
            _btnSaveSettings.FlatAppearance.BorderSize = 0;
            _btnSaveSettings.Click += (s, e) => EmitSave();

            _btnResetSettings = new Button
            {
                Width = 150,
                Height = 40,
                Margin = new Padding(12, 0, 0, 0),
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgSurface,
                ForeColor = ThemeTokens.TextSecondary,
                Font = ThemeTokens.FontBody,
                Cursor = Cursors.Hand
            };
            _btnResetSettings.FlatAppearance.BorderColor = ThemeTokens.BorderControl;
            _btnResetSettings.Click += (s, e) => ResetForm();

            pnlButtons.Controls.Add(_btnSaveSettings);
            pnlButtons.Controls.Add(_btnResetSettings);

            // Dock top-to-bottom requires reverse Add order
            contentRoot.Controls.Add(pnlButtons);
            contentRoot.Controls.Add(_lblSettingsError);
            contentRoot.Controls.Add(pnlChecks);
            contentRoot.Controls.Add(grid);

            scrollHost.Controls.Add(contentRoot);
            this.Controls.Add(scrollHost);
        }

        private static Panel CreateFieldGroup(out Label label, Control inputControl, Padding margin)
        {
            var container = new Panel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                Margin = margin
            };
            label = new Label
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                Font = ThemeTokens.FontSmallBold,
                ForeColor = ThemeTokens.TextSecondary,
                Padding = new Padding(0, 0, 0, 4),
                TabIndex = 0
            };
            inputControl.TabIndex = 1;
            container.Controls.Add(inputControl);
            container.Controls.Add(label);
            return container;
        }

        private static TextBox CreateFormTextBox(string initial) => new()
        {
            Text = initial,
            Dock = DockStyle.Top,
            BackColor = ThemeTokens.BgField,
            ForeColor = ThemeTokens.TextPrimary,
            BorderStyle = BorderStyle.FixedSingle,
            Font = ThemeTokens.FontInput
        };

        private static CheckBox CreateFormCheckBox(bool initial) => new()
        {
            Checked = initial,
            AutoSize = true,
            ForeColor = ThemeTokens.TextPrimary,
            Font = ThemeTokens.FontBody,
            Margin = new Padding(0, 4, 0, 4)
        };

        private static ComboBox CreateDarkLanguageCombo(string language)
        {
            var cmb = new ComboBox
            {
                Dock = DockStyle.Top,
                DropDownStyle = ComboBoxStyle.DropDownList,
                DrawMode = DrawMode.OwnerDrawFixed,
                ItemHeight = 24,
                BackColor = ThemeTokens.BgField,
                ForeColor = ThemeTokens.TextPrimary,
                FlatStyle = FlatStyle.Flat,
                Font = ThemeTokens.FontBody
            };
            cmb.Items.Add("English (EN)");
            cmb.Items.Add("Bahasa Indonesia (ID)");
            cmb.SelectedIndex = language == "id" ? 1 : 0;

            cmb.DrawItem += (s, e) =>
            {
                if (e.Index < 0) return;
                bool selected = (e.State & DrawItemState.Selected) != 0;
                Color bg = selected ? ThemeTokens.BgHover : ThemeTokens.BgField;
                Color fg = selected ? ThemeTokens.AccentCyan : ThemeTokens.TextPrimary;
                using var bgBrush = new SolidBrush(bg);
                using var fgBrush = new SolidBrush(fg);
                e.Graphics.FillRectangle(bgBrush, e.Bounds);
                var textRect = new Rectangle(e.Bounds.X + 6, e.Bounds.Y, Math.Max(0, e.Bounds.Width - 10), e.Bounds.Height);
                e.Graphics.DrawString(cmb.Items[e.Index]?.ToString() ?? "", ThemeTokens.FontBody, fgBrush, textRect, ThemeTokens.LeftCenterStringFormat);
                e.DrawFocusRectangle();
            };
            return cmb;
        }

        public void ApplyLocalization()
        {
            _lblPortLabel.Text = ServerLocalization.T("setPort");
            _txtPort.AccessibleName = ServerLocalization.T("setPort");

            _lblSensLabel.Text = ServerLocalization.T("setSensitivity");
            _txtSensitivity.AccessibleName = ServerLocalization.T("setSensitivity");

            _lblPinLabel.Text = ServerLocalization.T("setPin");
            _txtPin.AccessibleName = ServerLocalization.T("setPin");
            _btnTogglePin.Text = _txtPin.UseSystemPasswordChar ? ServerLocalization.T("showPin") : ServerLocalization.T("hidePin");
            _btnTogglePin.AccessibleName = ServerLocalization.T("a11yPinToggle");

            _lblLangLabel.Text = ServerLocalization.T("setLanguage");
            _cmbLanguage.AccessibleName = ServerLocalization.T("setLanguage");

            _chkMinimizeTray.Text = ServerLocalization.T("setMinimizeTray");
            _chkStartMinimized.Text = ServerLocalization.T("setStartMinimized");
            _chkAutoStartServer.Text = ServerLocalization.T("setAutoStartServer");
            _chkRunStartup.Text = ServerLocalization.T("setRunStartup");

            _btnSaveSettings.Text = ServerLocalization.T("saveSettings");
            _btnSaveSettings.AccessibleName = ServerLocalization.T("saveSettings");
            _btnResetSettings.Text = ServerLocalization.T("resetSettings");
            _btnResetSettings.AccessibleName = ServerLocalization.T("resetSettings");
        }

        public void ShowInlineError(string message)
        {
            _lblSettingsError.Text = message;
            _lblSettingsError.Visible = true;
        }

        public void ClearInlineError()
        {
            _lblSettingsError.Visible = false;
        }

        private void EmitSave()
        {
            ClearInlineError();
            SaveRequested?.Invoke(new SettingsSaveRequest(
                _txtPort.Text,
                _txtSensitivity.Text,
                _txtPin.Text.Trim(),
                _cmbLanguage.SelectedIndex == 1 ? "id" : "en",
                _chkMinimizeTray.Checked,
                _chkStartMinimized.Checked,
                _chkAutoStartServer.Checked,
                _chkRunStartup.Checked));
        }

        private void ResetForm()
        {
            _txtPort.Text = "8888";
            _txtSensitivity.Text = "2.0";
            _txtPin.Text = "";
            _chkMinimizeTray.Checked = true;
            _chkStartMinimized.Checked = false;
            _chkAutoStartServer.Checked = false;
            _chkRunStartup.Checked = false;
            ClearInlineError();
        }
    }

    public sealed record SettingsSaveRequest(
        string RawPort,
        string RawSensitivity,
        string PinCode,
        string Language,
        bool MinimizeToTrayOnClose,
        bool StartMinimized,
        bool AutoStartServer,
        bool RunOnStartup);
}
