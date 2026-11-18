// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Drawing;
using System.Windows.Forms;
using TelePadServer.Config;

namespace TelePadServer.UI.Pages
{
    public sealed class LogsPage : UserControl
    {
        private const int MaxLogLines = 500;
        private readonly Button _btnCopyLogs;
        private readonly Button _btnClearLogs;
        private readonly RichTextBox _rtbLog;
        private int _logLineCount;

        public LogsPage()
        {
            this.Dock = DockStyle.Fill;
            this.BackColor = ThemeTokens.BgCanvas;

            var pnlHeader = new Panel { Dock = DockStyle.Top, Height = 44, Padding = new Padding(0, 0, 0, 8) };
            _btnCopyLogs = new Button
            {
                Dock = DockStyle.Right,
                Width = 120,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgSurface,
                ForeColor = ThemeTokens.TextPrimary,
                Font = ThemeTokens.FontSmallBold,
                Cursor = Cursors.Hand
            };
            _btnCopyLogs.FlatAppearance.BorderColor = ThemeTokens.BorderControl;
            _btnCopyLogs.Click += (s, e) => CopyLogs();

            _btnClearLogs = new Button
            {
                Dock = DockStyle.Right,
                Width = 120,
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgSurface,
                ForeColor = ThemeTokens.TextSecondary,
                Font = ThemeTokens.FontSmall,
                Cursor = Cursors.Hand
            };
            _rtbLog = new RichTextBox
            {
                Dock = DockStyle.Fill,
                BackColor = ThemeTokens.BgLogSurface,
                ForeColor = ThemeTokens.AccentCyan,
                BorderStyle = BorderStyle.None,
                ReadOnly = true,
                Font = ThemeTokens.FontMonoSmall
            };

            _btnClearLogs.FlatAppearance.BorderColor = ThemeTokens.BorderControl;
            _btnClearLogs.Click += (s, e) =>
            {
                _rtbLog.Clear();
                _logLineCount = 0;
            };

            pnlHeader.Controls.Add(_btnClearLogs);
            pnlHeader.Controls.Add(_btnCopyLogs);

            this.Controls.Add(_rtbLog);
            this.Controls.Add(pnlHeader);
        }

        public void ApplyLocalization()
        {
            _btnCopyLogs.Text = ServerLocalization.T("copyLogs");
            _btnCopyLogs.AccessibleName = ServerLocalization.T("copyLogs");
            _btnClearLogs.Text = ServerLocalization.T("clearLogs");
            _btnClearLogs.AccessibleName = ServerLocalization.T("clearLogs");
            _rtbLog.AccessibleName = ServerLocalization.T("navLogs");
        }

        public void AppendLog(string message, Color? color = null)
        {
            if (IsDisposed) return;

            if (this.InvokeRequired)
            {
                if (this.IsHandleCreated)
                {
                    this.BeginInvoke(new Action(() => AppendLog(message, color)));
                }
                return;
            }

            if (_logLineCount >= MaxLogLines)
            {
                int secondLineStart = _rtbLog.GetFirstCharIndexFromLine(1);
                if (secondLineStart > 0)
                {
                    _rtbLog.ReadOnly = false;
                    _rtbLog.Select(0, secondLineStart);
                    _rtbLog.SelectedText = string.Empty;
                    _rtbLog.ReadOnly = true;
                    _logLineCount--;
                }
            }

            _rtbLog.SelectionStart = _rtbLog.TextLength;
            _rtbLog.SelectionLength = 0;
            _rtbLog.SelectionColor = color ?? ThemeTokens.AccentCyan;
            _rtbLog.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}\n");
            _rtbLog.ScrollToCaret();
            _logLineCount++;
        }

        private void CopyLogs()
        {
            if (string.IsNullOrEmpty(_rtbLog.Text)) return;

            if (SafeClipboard.TrySetText(_rtbLog.Text, out string err))
            {
                AppendLog(ServerLocalization.T("copiedLogs"), ThemeTokens.StatusGreen);
            }
            else
            {
                AppendLog(ServerLocalization.Tf("logClipboardError", ("err", err)), ThemeTokens.StatusAmber);
            }
        }
    }
}
