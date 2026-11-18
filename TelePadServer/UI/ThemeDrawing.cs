// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace TelePadServer.UI
{
    public enum NavIconKind
    {
        Brand,
        Dashboard,
        Devices,
        Settings,
        Logs,
        Help
    }

    public class DarkListView : ListView
    {
        public DarkListView()
        {
            this.DoubleBuffered = true;
            this.OwnerDraw = true;
            this.FullRowSelect = true;
            this.View = View.Details;
            this.BorderStyle = BorderStyle.None;
            this.BackColor = ThemeTokens.BgSidebar;
            this.ForeColor = ThemeTokens.TextRow;
        }

        protected override void OnDrawColumnHeader(DrawListViewColumnHeaderEventArgs e)
        {
            using var bg = new SolidBrush(ThemeTokens.BgSurfaceAlt);
            e.Graphics.FillRectangle(bg, e.Bounds);

            using var border = new Pen(ThemeTokens.BorderControl);
            e.Graphics.DrawLine(border, e.Bounds.Left, e.Bounds.Bottom - 1, e.Bounds.Right, e.Bounds.Bottom - 1);
            e.Graphics.DrawLine(border, e.Bounds.Right - 1, e.Bounds.Top + 4, e.Bounds.Right - 1, e.Bounds.Bottom - 4);

            using var textBrush = new SolidBrush(ThemeTokens.TextSecondary);
            var textRect = new Rectangle(e.Bounds.X + 8, e.Bounds.Y, Math.Max(0, e.Bounds.Width - 12), e.Bounds.Height);
            e.Graphics.DrawString(e.Header?.Text ?? "", ThemeTokens.FontSmallBold, textBrush, textRect, ThemeTokens.LeftCenterStringFormat);
        }

        protected override void OnDrawItem(DrawListViewItemEventArgs e)
        {
            Color rowColor = e.Item.Selected
                ? ThemeTokens.BgListRowSelected
                : (e.ItemIndex % 2 == 0 ? ThemeTokens.BgSidebar : ThemeTokens.BgListRowAlt);

            using (var rowBrush = new SolidBrush(rowColor))
            {
                e.Graphics.FillRectangle(rowBrush, e.Bounds);
            }

            if ((e.State & ListViewItemStates.Focused) != 0 && this.Focused)
            {
                var focusBounds = new Rectangle(e.Bounds.X + 1, e.Bounds.Y + 1, Math.Max(0, e.Bounds.Width - 2), Math.Max(0, e.Bounds.Height - 2));
                using var focusPen = new Pen(ThemeTokens.AccentCyan, 1f) { DashStyle = DashStyle.Dot };
                e.Graphics.DrawRectangle(focusPen, focusBounds);
            }
        }

        protected override void OnDrawSubItem(DrawListViewSubItemEventArgs e)
        {
            var color = e.ColumnIndex == 2 && (e.SubItem?.Text == "Verified" || e.SubItem?.Text == "Terverifikasi")
                ? ThemeTokens.StatusGreen
                : e.Item?.Selected == true
                    ? (SystemInformation.HighContrast ? SystemColors.HighlightText : ThemeTokens.AccentCyan)
                    : ThemeTokens.TextRow;

            using var brush = new SolidBrush(color);
            var rect = new Rectangle(e.Bounds.X + 8, e.Bounds.Y, Math.Max(0, e.Bounds.Width - 12), e.Bounds.Height);
            e.Graphics.DrawString(e.SubItem?.Text ?? "", ThemeTokens.FontBody, brush, rect, ThemeTokens.LeftCenterStringFormat);
        }
    }

    public static class ThemeDrawing
    {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern bool DestroyIcon(IntPtr handle);

        public static Bitmap CreateNavBitmap(NavIconKind kind, int size, Color color)
        {
            int safeSize = Math.Max(8, size);
            var bmp = new Bitmap(safeSize, safeSize);
            using var g = Graphics.FromImage(bmp);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.Clear(Color.Transparent);

            // Scale logically from 16x16 grid so icons stay sharp across DPI and explicit sizes.
            float scale = safeSize / 16f;
            g.ScaleTransform(scale, scale);

            using var pen = new Pen(color, 1.5f) { LineJoin = LineJoin.Round, StartCap = LineCap.Round, EndCap = LineCap.Round };
            using var brush = new SolidBrush(color);

            switch (kind)
            {
                case NavIconKind.Brand:
                    g.DrawRoundedRectangle(pen, new Rectangle(1, 4, 14, 8), 3);
                    g.FillCircle(brush, 5, 8, 1);
                    g.FillCircle(brush, 11, 8, 1);
                    break;
                case NavIconKind.Dashboard:
                    g.DrawRoundedRectangle(pen, new Rectangle(2, 2, 5, 5), 1);
                    g.DrawRoundedRectangle(pen, new Rectangle(9, 2, 5, 5), 1);
                    g.DrawRoundedRectangle(pen, new Rectangle(2, 9, 5, 5), 1);
                    g.DrawRoundedRectangle(pen, new Rectangle(9, 9, 5, 5), 1);
                    break;
                case NavIconKind.Devices:
                    g.DrawRoundedRectangle(pen, new Rectangle(4, 1, 8, 14), 2);
                    g.FillCircle(brush, 8, 12, 1);
                    break;
                case NavIconKind.Settings:
                    g.DrawCircle(pen, 8, 8, 4);
                    g.DrawLine(pen, 8, 1, 8, 3);
                    g.DrawLine(pen, 8, 13, 8, 15);
                    g.DrawLine(pen, 1, 8, 3, 8);
                    g.DrawLine(pen, 13, 8, 15, 8);
                    break;
                case NavIconKind.Logs:
                    g.DrawRoundedRectangle(pen, new Rectangle(2, 2, 12, 12), 2);
                    g.DrawLine(pen, 5, 6, 11, 6);
                    g.DrawLine(pen, 5, 9, 11, 9);
                    g.DrawLine(pen, 5, 12, 9, 12);
                    break;
                case NavIconKind.Help:
                    g.DrawCircle(pen, 8, 8, 6);
                    g.FillCircle(brush, 8, 11, 1);
                    g.DrawArc(pen, 6, 4, 4, 4, 180, 270);
                    break;
            }
            return bmp;
        }

        public static Icon CreateTelePadIcon(Color accentColor)
        {
            using var bmp = new Bitmap(32, 32);
            using (var g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                using var bg = new SolidBrush(ThemeTokens.BgCanvas);
                g.FillRoundedRectangle(bg, new Rectangle(0, 0, 31, 31), 7);

                using var pen = new Pen(accentColor, 2.2f);
                g.DrawRoundedRectangle(pen, new Rectangle(5, 11, 22, 13), 5);
                g.DrawArc(pen, 9, 4, 14, 8, 200, 140);

                using var dot = new SolidBrush(accentColor);
                g.FillCircle(dot, 11, 17, 2);
                g.FillCircle(dot, 21, 17, 2);
            }

            IntPtr hIcon = bmp.GetHicon();
            try
            {
                using var raw = Icon.FromHandle(hIcon);
                return (Icon)raw.Clone();
            }
            finally
            {
                DestroyIcon(hIcon);
            }
        }
    }
}
