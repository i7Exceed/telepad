// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Drawing;
using System.Windows.Forms;
using TelePadServer.Config;

namespace TelePadServer.UI.Pages
{
    public sealed class HelpPage : UserControl
    {
        private readonly Label _lblHelpTitle;
        private readonly Label _lblHelpStep1Title;
        private readonly Label _lblHelpStep1Body;
        private readonly LinkLabel _lnkHelpVigem;
        private readonly Label _lblHelpStep2Title;
        private readonly Label _lblHelpStep2Body;
        private readonly TextBox _txtFirewallCmd;
        private readonly Button _btnCopyFirewallCmd;

        public event Action<string>? OpenUrlRequested;
        public event Action<string, Color>? LogRequested;

        public HelpPage()
        {
            this.Dock = DockStyle.Fill;
            this.BackColor = ThemeTokens.BgCanvas;

            var scrollHost = new Panel
            {
                Dock = DockStyle.Fill,
                AutoScroll = true,
                Padding = new Padding(4)
            };

            _lblHelpTitle = new Label
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                Font = ThemeTokens.FontPageTitle,
                ForeColor = ThemeTokens.TextPrimary,
                Padding = new Padding(0, 0, 0, 12)
            };

            var card1 = CreateHelpCard(out _lblHelpStep1Title, out _lblHelpStep1Body);
            _lnkHelpVigem = new LinkLabel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                LinkColor = ThemeTokens.AccentCyan,
                ActiveLinkColor = ThemeTokens.TextPrimary,
                Font = ThemeTokens.FontBodyBold,
                Padding = new Padding(0, 8, 0, 0)
            };
            _lnkHelpVigem.LinkClicked += (s, e) => OpenUrlRequested?.Invoke("https://github.com/ViGEm/ViGEmBus/releases");
            card1.Controls.Add(_lnkHelpVigem);
            card1.Controls.SetChildIndex(_lnkHelpVigem, 0);

            var card2 = CreateHelpCard(out _lblHelpStep2Title, out _lblHelpStep2Body);
            _txtFirewallCmd = new TextBox
            {
                Dock = DockStyle.Top,
                ReadOnly = true,
                BackColor = ThemeTokens.BgField,
                ForeColor = ThemeTokens.AccentCyan,
                BorderStyle = BorderStyle.FixedSingle,
                Font = ThemeTokens.FontMonoSmall,
                Margin = new Padding(0, 8, 0, 8)
            };
            var cmdSpacer = new Panel { Dock = DockStyle.Top, Height = 8 };
            var btnRow = new Panel { Dock = DockStyle.Top, Height = 40, Padding = new Padding(0, 4, 0, 0) };
            _btnCopyFirewallCmd = new Button
            {
                Dock = DockStyle.Left,
                AutoSize = true,
                MinimumSize = new Size(220, 34),
                FlatStyle = FlatStyle.Flat,
                BackColor = ThemeTokens.BgHover,
                ForeColor = ThemeTokens.TextPrimary,
                Font = ThemeTokens.FontSmallBold,
                Cursor = Cursors.Hand
            };
            _btnCopyFirewallCmd.FlatAppearance.BorderColor = ThemeTokens.AccentCyan;
            _btnCopyFirewallCmd.Click += (s, e) => CopyFirewallCommand();
            btnRow.Controls.Add(_btnCopyFirewallCmd);

            card2.Controls.Add(btnRow);
            card2.Controls.Add(_txtFirewallCmd);
            card2.Controls.Add(cmdSpacer);
            card2.Controls.SetChildIndex(btnRow, 0);
            card2.Controls.SetChildIndex(_txtFirewallCmd, 1);
            card2.Controls.SetChildIndex(cmdSpacer, 2);

            var cardGap = new Panel { Dock = DockStyle.Top, Height = 12 };

            // Top-docking in reverse add order prevents horizontal overflow at 840x560 min window.
            scrollHost.Controls.Add(card2);
            scrollHost.Controls.Add(cardGap);
            scrollHost.Controls.Add(card1);
            scrollHost.Controls.Add(_lblHelpTitle);

            this.Controls.Add(scrollHost);
        }

        private static Panel CreateHelpCard(out Label title, out Label body)
        {
            var card = new Panel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                BackColor = ThemeTokens.BgSurface,
                Padding = new Padding(16)
            };
            title = new Label
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                Font = ThemeTokens.FontCardTitle,
                ForeColor = ThemeTokens.AccentCyan,
                Padding = new Padding(0, 0, 0, 6)
            };
            body = new Label
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                Font = ThemeTokens.FontBody,
                ForeColor = ThemeTokens.TextSecondary
            };
            card.Controls.Add(body);
            card.Controls.Add(title);
            Label wrappedBody = body;
            card.SizeChanged += (s, e) =>
            {
                int avail = Math.Max(180, card.ClientSize.Width - card.Padding.Horizontal);
                if (wrappedBody.MaximumSize.Width != avail)
                {
                    wrappedBody.MaximumSize = new Size(avail, 0);
                }
            };
            return card;
        }

        public void ApplyLocalization(int port)
        {
            _lblHelpTitle.Text = ServerLocalization.T("helpTitle");
            _lblHelpStep1Title.Text = ServerLocalization.T("helpStep1Title");
            _lblHelpStep1Body.Text = ServerLocalization.T("helpStep1Body");
            _lnkHelpVigem.Text = ServerLocalization.T("installDriver") + " (ViGEmBus Releases)";
            _lnkHelpVigem.AccessibleName = _lnkHelpVigem.Text;
            _lblHelpStep2Title.Text = ServerLocalization.T("helpStep2Title");
            _lblHelpStep2Body.Text = ServerLocalization.T("helpStep2Body");
            _txtFirewallCmd.Text = $"New-NetFirewallRule -DisplayName \"TelePad UDP {port}\" -Direction Inbound -Protocol UDP -LocalPort {port} -Action Allow";
            _txtFirewallCmd.AccessibleName = ServerLocalization.T("a11yFirewallCmd");
            _btnCopyFirewallCmd.Text = ServerLocalization.T("copyFirewallCmd");
            _btnCopyFirewallCmd.AccessibleName = ServerLocalization.T("copyFirewallCmd");
        }

        private void CopyFirewallCommand()
        {
            if (SafeClipboard.TrySetText(_txtFirewallCmd.Text, out string err))
            {
                _btnCopyFirewallCmd.Text = ServerLocalization.T("copiedFirewallCmd");
            }
            else
            {
                LogRequested?.Invoke(ServerLocalization.Tf("logClipboardError", ("err", err)), ThemeTokens.StatusAmber);
            }
        }
    }
}
