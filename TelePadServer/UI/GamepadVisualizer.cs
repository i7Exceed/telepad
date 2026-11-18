// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Threading;
using System.Windows.Forms;

namespace TelePadServer.UI
{
    public class GamepadVisualizer : Panel
    {
        private readonly object _stateLock = new();
        private readonly HashSet<string> _pressedButtons = new(StringComparer.OrdinalIgnoreCase);
        private float _leftStickX;
        private float _leftStickY;
        private float _rightStickX;
        private float _rightStickY;
        private byte _leftTrigger;
        private byte _rightTrigger;
        private int _repaintQueued;

        public GamepadVisualizer()
        {
            this.DoubleBuffered = true;
            this.ResizeRedraw = true;
            this.TabStop = true;
            this.BackColor = ThemeTokens.BgSidebar;
            this.MinimumSize = new Size(260, 190);
            this.AccessibleName = "Live Controller Preview";
            this.AccessibleDescription = "Displays real-time Xbox 360 button, trigger, and analog stick inputs.";
            this.Enter += (s, e) => Invalidate();
            this.Leave += (s, e) => Invalidate();
        }

        public void SetButtonState(string key, bool isPressed)
        {
            lock (_stateLock)
            {
                if (key == "LT") _leftTrigger = (byte)(isPressed ? 255 : 0);
                else if (key == "RT") _rightTrigger = (byte)(isPressed ? 255 : 0);

                if (isPressed) _pressedButtons.Add(key);
                else _pressedButtons.Remove(key);
            }
        }

        public void SetAnalogState(string axisId, float x, float y)
        {
            lock (_stateLock)
            {
                if (axisId == "LS")
                {
                    _leftStickX = x;
                    _leftStickY = y;
                }
                else if (axisId == "RS")
                {
                    _rightStickX = x;
                    _rightStickY = y;
                }
                else if (axisId == "LT")
                {
                    _leftTrigger = (byte)(Math.Clamp(x, 0f, 1f) * 255f);
                }
                else if (axisId == "RT")
                {
                    _rightTrigger = (byte)(Math.Clamp(x, 0f, 1f) * 255f);
                }
            }
        }

        public void ResetState()
        {
            lock (_stateLock)
            {
                _pressedButtons.Clear();
                _leftStickX = 0;
                _leftStickY = 0;
                _rightStickX = 0;
                _rightStickY = 0;
                _leftTrigger = 0;
                _rightTrigger = 0;
            }
        }

        public (HashSet<string> Pressed, float LsX, float LsY, float RsX, float RsY, byte Lt, byte Rt) GetStateSnapshot()
        {
            lock (_stateLock)
            {
                return (
                    new HashSet<string>(_pressedButtons, StringComparer.OrdinalIgnoreCase),
                    _leftStickX,
                    _leftStickY,
                    _rightStickX,
                    _rightStickY,
                    _leftTrigger,
                    _rightTrigger
                );
            }
        }

        public void RequestRepaint()
        {
            if (IsDisposed || !IsHandleCreated) return;
            if (Interlocked.Exchange(ref _repaintQueued, 1) == 0)
            {
                try
                {
                    BeginInvoke(FlushRepaint);
                }
                catch
                {
                    Interlocked.Exchange(ref _repaintQueued, 0);
                }
            }
        }

        private void FlushRepaint()
        {
            Interlocked.Exchange(ref _repaintQueued, 0);
            if (IsDisposed) return;

            var snap = GetStateSnapshot();
            this.AccessibleDescription = snap.Pressed.Count > 0 || snap.Lt > 0 || snap.Rt > 0
                ? $"Pressed: {string.Join(", ", snap.Pressed)} | LT: {snap.Lt} | RT: {snap.Rt}"
                : "No controller inputs currently active.";
            this.Invalidate();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            var g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            var borderColor = this.Focused ? ThemeTokens.AccentCyan : ThemeTokens.BorderSubtle;
            using (var borderPen = new Pen(borderColor, this.Focused ? 2f : 1f))
            {
                g.DrawRectangle(borderPen, 0, 0, this.Width - 1, this.Height - 1);
            }

            var (pressed, lsX, lsY, rsX, rsY, lt, rt) = GetStateSnapshot();

            const float logicalW = 320f;
            const float logicalH = 230f;
            float scale = Math.Min((this.Width - 16f) / logicalW, (this.Height - 16f) / logicalH);
            if (scale <= 0.1f) scale = 1f;

            float offsetX = (this.Width - logicalW * scale) / 2f;
            float offsetY = (this.Height - logicalH * scale) / 2f;

            var state = g.Save();
            g.TranslateTransform(offsetX, offsetY);
            g.ScaleTransform(scale, scale);

            var activeCyan = ThemeTokens.AccentCyan;
            var idleText = ThemeTokens.TextSecondary;

            // 1. Triggers (clip-masked dual-pass text preserves contrast at any fill level)
            DrawTrigger(g, new Rectangle(24, 14, 96, 18), lt, "LT", activeCyan, idleText);
            DrawTrigger(g, new Rectangle(200, 14, 96, 18), rt, "RT", activeCyan, idleText);

            // 2. Bumpers
            DrawBumper(g, new Rectangle(24, 38, 96, 20), pressed.Contains("LB"), "LB", activeCyan, idleText);
            DrawBumper(g, new Rectangle(200, 38, 96, 20), pressed.Contains("RB"), "RB", activeCyan, idleText);

            // 3. Left & Right Analog Sticks
            DrawStick(g, new Point(72, 102), lsX, lsY, pressed.Contains("LS_CLICK"), activeCyan);
            DrawStick(g, new Point(192, 174), rsX, rsY, pressed.Contains("RS_CLICK"), activeCyan);

            // 4. D-Pad
            DrawDPad(g, new Point(108, 174), pressed, activeCyan);

            // 5. Select, Home, Start
            DrawPillButton(g, new Rectangle(116, 95, 28, 16), pressed.Contains("SELECT"), "SEL", idleText);
            DrawCircleButton(g, new Point(160, 103), 10, pressed.Contains("HOME"), activeCyan);
            DrawPillButton(g, new Rectangle(176, 95, 28, 16), pressed.Contains("START"), "STR", idleText);

            // 6. Face Buttons A/B/X/Y
            DrawFaceButton(g, new Point(248, 78), pressed.Contains("Y"), ThemeTokens.FaceY, "Y");
            DrawFaceButton(g, new Point(248, 130), pressed.Contains("A"), ThemeTokens.FaceA, "A");
            DrawFaceButton(g, new Point(222, 104), pressed.Contains("X"), ThemeTokens.FaceX, "X");
            DrawFaceButton(g, new Point(274, 104), pressed.Contains("B"), ThemeTokens.FaceB, "B");

            g.Restore(state);
        }

        private static void DrawTrigger(Graphics g, Rectangle r, byte val, string label, Color accent, Color idleText)
        {
            using var bgBrush = new SolidBrush(ThemeTokens.BgControlIdle);
            g.FillRoundedRectangle(bgBrush, r, 4);

            DrawCenteredText(g, label, r, idleText);

            if (val > 0)
            {
                float percent = val / 255.0f;
                int fillW = Math.Max(4, (int)(r.Width * percent));
                var fillRect = new Rectangle(r.X, r.Y, fillW, r.Height);

                var clipState = g.Save();
                g.SetClip(fillRect);
                using var fillBrush = new SolidBrush(accent);
                g.FillRoundedRectangle(fillBrush, r, 4);
                DrawCenteredText(g, label, r, ThemeTokens.TextOnAccent);
                g.Restore(clipState);
            }

            using var pen = new Pen(val > 0 ? accent : ThemeTokens.BorderIdle);
            g.DrawRoundedRectangle(pen, r, 4);
        }

        private static void DrawBumper(Graphics g, Rectangle r, bool pressed, string label, Color accent, Color idleText)
        {
            using var bgBrush = new SolidBrush(pressed ? accent : ThemeTokens.BgControlIdle);
            g.FillRoundedRectangle(bgBrush, r, 5);

            using var pen = new Pen(pressed ? accent : ThemeTokens.BorderIdle);
            g.DrawRoundedRectangle(pen, r, 5);

            DrawCenteredText(g, label, r, pressed ? ThemeTokens.TextOnAccent : idleText);
        }

        private static void DrawStick(Graphics g, Point center, float sx, float sy, bool clicked, Color accent)
        {
            const int radius = 26;
            using (var pen = new Pen(clicked ? accent : ThemeTokens.BorderIdle, clicked ? 2f : 1.2f))
            {
                g.DrawCircle(pen, center.X, center.Y, radius);
            }
            using (var pen = new Pen(ThemeTokens.BorderCrosshair))
            {
                g.DrawLine(pen, center.X - radius, center.Y, center.X + radius, center.Y);
                g.DrawLine(pen, center.X, center.Y - radius, center.X, center.Y + radius);
            }

            int kx = center.X + (int)(Math.Clamp(sx, -1f, 1f) * (radius - 6));
            int ky = center.Y - (int)(Math.Clamp(sy, -1f, 1f) * (radius - 6));

            const int knobRadius = 8;
            var knobColor = clicked ? ThemeTokens.AccentIndigo : accent;
            using (var brush = new SolidBrush(knobColor))
            {
                g.FillCircle(brush, kx, ky, knobRadius);
            }
        }

        private static void DrawDPad(Graphics g, Point center, HashSet<string> pressed, Color accent)
        {
            const int size = 16;

            DrawDPadKey(g, new Rectangle(center.X - size / 2, center.Y - size * 3 / 2, size, size), pressed.Contains("DPAD_UP"), accent);
            DrawDPadKey(g, new Rectangle(center.X - size / 2, center.Y + size / 2, size, size), pressed.Contains("DPAD_DOWN"), accent);
            DrawDPadKey(g, new Rectangle(center.X - size * 3 / 2, center.Y - size / 2, size, size), pressed.Contains("DPAD_LEFT"), accent);
            DrawDPadKey(g, new Rectangle(center.X + size / 2, center.Y - size / 2, size, size), pressed.Contains("DPAD_RIGHT"), accent);

            using var brush = new SolidBrush(ThemeTokens.BgControlIdle);
            g.FillRectangle(brush, center.X - size / 2, center.Y - size / 2, size, size);
        }

        private static void DrawDPadKey(Graphics g, Rectangle r, bool pressed, Color accent)
        {
            if (pressed)
            {
                using var brush = new SolidBrush(accent);
                g.FillRectangle(brush, r);
            }
            else
            {
                using var pen = new Pen(ThemeTokens.BorderIdle);
                g.DrawRectangle(pen, r);
            }
        }

        private static void DrawFaceButton(Graphics g, Point center, bool pressed, Color color, string label)
        {
            const int r = 11;
            var bounds = new Rectangle(center.X - r, center.Y - r, r * 2, r * 2);
            if (pressed)
            {
                using var brush = new SolidBrush(color);
                g.FillCircle(brush, center.X, center.Y, r);
                DrawCenteredText(g, label, bounds, ThemeTokens.TextOnAccent);
            }
            else
            {
                using var pen = new Pen(color, 1.5f);
                g.DrawCircle(pen, center.X, center.Y, r);
                DrawCenteredText(g, label, bounds, color);
            }
        }

        private static void DrawPillButton(Graphics g, Rectangle r, bool pressed, string label, Color idleText)
        {
            using var bgBrush = new SolidBrush(pressed ? ThemeTokens.AccentIndigo : ThemeTokens.BgControlIdle);
            g.FillRoundedRectangle(bgBrush, r, 4);
            using var pen = new Pen(pressed ? ThemeTokens.AccentIndigo : ThemeTokens.BorderIdle);
            g.DrawRoundedRectangle(pen, r, 4);
            DrawCenteredText(g, label, r, pressed ? ThemeTokens.TextOnAccent : idleText);
        }

        private static void DrawCircleButton(Graphics g, Point center, int radius, bool pressed, Color color)
        {
            var bounds = new Rectangle(center.X - radius, center.Y - radius, radius * 2, radius * 2);
            if (pressed)
            {
                using var brush = new SolidBrush(color);
                g.FillCircle(brush, center.X, center.Y, radius);
                DrawCenteredText(g, "H", bounds, ThemeTokens.TextOnAccent);
            }
            else
            {
                using var pen = new Pen(color);
                g.DrawCircle(pen, center.X, center.Y, radius);
                DrawCenteredText(g, "H", bounds, color);
            }
        }

        private static void DrawCenteredText(Graphics g, string text, Rectangle bounds, Color color)
        {
            using var brush = new SolidBrush(color);
            g.DrawString(text, ThemeTokens.FontVisualizerText, brush, bounds, ThemeTokens.CenteredStringFormat);
        }
    }
}
