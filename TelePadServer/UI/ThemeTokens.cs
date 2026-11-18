// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace TelePadServer.UI
{
    public static class ThemeTokens
    {
        public static Color BgCanvas => SystemInformation.HighContrast ? SystemColors.Window : Color.FromArgb(10, 14, 22);
        public static Color BgSidebar => SystemInformation.HighContrast ? SystemColors.Control : Color.FromArgb(14, 18, 28);
        public static Color BgSurface => SystemInformation.HighContrast ? SystemColors.Control : Color.FromArgb(17, 24, 39);
        public static Color BgSurfaceAlt => SystemInformation.HighContrast ? SystemColors.ControlLight : Color.FromArgb(22, 30, 46);
        public static Color BgField => SystemInformation.HighContrast ? SystemColors.Window : Color.FromArgb(12, 18, 32);
        public static Color BgHover => SystemInformation.HighContrast ? SystemColors.Highlight : Color.FromArgb(24, 34, 52);
        public static Color BgHoverAccent => SystemInformation.HighContrast ? SystemColors.Highlight : Color.FromArgb(26, 44, 70);
        public static Color BgActiveNav => SystemInformation.HighContrast ? SystemColors.Highlight : Color.FromArgb(24, 36, 56);
        public static Color BgButtonStart => SystemInformation.HighContrast ? SystemColors.ButtonFace : Color.FromArgb(18, 30, 48);
        public static Color BgButtonDanger => SystemInformation.HighContrast ? SystemColors.ButtonFace : Color.FromArgb(44, 18, 28);
        public static Color BgLogSurface => SystemInformation.HighContrast ? SystemColors.Window : Color.FromArgb(7, 10, 16);
        public static Color BgListRowAlt => SystemInformation.HighContrast ? SystemColors.Window : Color.FromArgb(18, 24, 36);
        public static Color BgListRowSelected => SystemInformation.HighContrast ? SystemColors.Highlight : Color.FromArgb(24, 52, 76);
        public static Color BgControlIdle => SystemInformation.HighContrast ? SystemColors.Control : Color.FromArgb(20, 26, 40);

        public static Color BorderSubtle => SystemInformation.HighContrast ? SystemColors.WindowFrame : Color.FromArgb(36, 48, 72);
        public static Color BorderControl => SystemInformation.HighContrast ? SystemColors.WindowFrame : Color.FromArgb(46, 62, 92);
        public static Color BorderIdle => SystemInformation.HighContrast ? SystemColors.WindowFrame : Color.FromArgb(55, 70, 100);
        public static Color BorderCrosshair => SystemInformation.HighContrast ? SystemColors.GrayText : Color.FromArgb(28, 38, 58);

        public static Color TextPrimary => SystemInformation.HighContrast ? SystemColors.WindowText : Color.FromArgb(248, 250, 252);
        public static Color TextSecondary => SystemInformation.HighContrast ? SystemColors.WindowText : Color.FromArgb(203, 213, 225);
        public static Color TextMuted => SystemInformation.HighContrast ? SystemColors.GrayText : Color.FromArgb(148, 163, 184);
        public static Color TextOnAccent => SystemInformation.HighContrast ? SystemColors.HighlightText : Color.FromArgb(4, 19, 24);
        public static Color TextRow => SystemInformation.HighContrast ? SystemColors.WindowText : Color.FromArgb(226, 232, 240);

        public static Color AccentCyan => SystemInformation.HighContrast ? SystemColors.HotTrack : Color.FromArgb(0, 229, 255);
        public static Color AccentIndigo => SystemInformation.HighContrast ? SystemColors.Highlight : Color.FromArgb(192, 132, 252);
        public static Color StatusGreen => SystemInformation.HighContrast ? SystemColors.WindowText : Color.FromArgb(74, 222, 128);
        public static Color StatusAmber => SystemInformation.HighContrast ? SystemColors.WindowText : Color.FromArgb(251, 191, 36);
        public static Color StatusRed => SystemInformation.HighContrast ? SystemColors.WindowText : Color.FromArgb(251, 113, 133);
        public static Color StatusHaptic => SystemInformation.HighContrast ? SystemColors.HotTrack : Color.FromArgb(244, 114, 182);

        public static Color FaceY => Color.FromArgb(250, 204, 21);
        public static Color FaceA => Color.FromArgb(74, 222, 128);
        public static Color FaceX => Color.FromArgb(56, 189, 248);
        public static Color FaceB => Color.FromArgb(251, 113, 133);

        // Cached Fonts (shared read-only to prevent per-frame GDI handle allocations)
        public static readonly Font FontBrand = new("Segoe UI", 16f, FontStyle.Bold);
        public static readonly Font FontPageTitle = new("Segoe UI", 14f, FontStyle.Bold);
        public static readonly Font FontMetricValue = new("Segoe UI", 13.5f, FontStyle.Bold);
        public static readonly Font FontCardTitle = new("Segoe UI", 10.5f, FontStyle.Bold);
        public static readonly Font FontInput = new("Segoe UI", 10f, FontStyle.Regular);
        public static readonly Font FontInputBold = new("Segoe UI", 10f, FontStyle.Bold);
        public static readonly Font FontBody = new("Segoe UI", 9.5f, FontStyle.Regular);
        public static readonly Font FontBodyBold = new("Segoe UI", 9.5f, FontStyle.Bold);
        public static readonly Font FontSmall = new("Segoe UI", 9f, FontStyle.Regular);
        public static readonly Font FontSmallBold = new("Segoe UI", 9f, FontStyle.Bold);
        public static readonly Font FontCaption = new("Segoe UI", 8.5f, FontStyle.Regular);
        public static readonly Font FontCaptionBold = new("Segoe UI", 8.5f, FontStyle.Bold);
        public static readonly Font FontVisualizerText = new("Segoe UI", 8f, FontStyle.Bold);
        public static readonly Font FontMono = new("Consolas", 10.5f, FontStyle.Bold);
        public static readonly Font FontMonoSmall = new("Consolas", 9.2f, FontStyle.Regular);

        public static readonly StringFormat CenteredStringFormat = new()
        {
            Alignment = StringAlignment.Center,
            LineAlignment = StringAlignment.Center
        };

        public static readonly StringFormat LeftCenterStringFormat = new()
        {
            Alignment = StringAlignment.Near,
            LineAlignment = StringAlignment.Center,
            Trimming = StringTrimming.EllipsisCharacter
        };

        public static ToolStripRenderer CreateTrayMenuRenderer()
        {
            return SystemInformation.HighContrast
                ? new ToolStripSystemRenderer()
                : new ToolStripProfessionalRenderer(new DarkColorTable());
        }

        private sealed class DarkColorTable : ProfessionalColorTable
        {
            public override Color MenuBorder => BorderControl;
            public override Color MenuItemBorder => AccentCyan;
            public override Color MenuItemSelected => BgHover;
            public override Color MenuItemSelectedGradientBegin => BgHover;
            public override Color MenuItemSelectedGradientEnd => BgHover;
            public override Color MenuStripGradientBegin => BgSurface;
            public override Color MenuStripGradientEnd => BgSurface;
            public override Color ToolStripDropDownBackground => BgSurface;
            public override Color ImageMarginGradientBegin => BgSurface;
            public override Color ImageMarginGradientMiddle => BgSurface;
            public override Color ImageMarginGradientEnd => BgSurface;
            public override Color SeparatorDark => BorderSubtle;
            public override Color SeparatorLight => BorderSubtle;
        }
    }

    public static class SafeClipboard
    {
        public static bool TrySetText(string text, out string errorMessage)
        {
            errorMessage = string.Empty;
            if (string.IsNullOrEmpty(text))
            {
                return false;
            }

            try
            {
                Clipboard.SetText(text);
                return true;
            }
            catch (ExternalException ex)
            {
                errorMessage = ex.Message;
                return false;
            }
            catch (Exception ex)
            {
                errorMessage = ex.Message;
                return false;
            }
        }
    }
}
