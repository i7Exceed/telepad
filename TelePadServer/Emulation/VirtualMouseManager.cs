// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace TelePadServer.Emulation
{
    public class VirtualMouseManager
    {
        [DllImport("user32.dll")]
        private static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

        private const int MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const int MOUSEEVENTF_LEFTUP = 0x0004;
        private const int MOUSEEVENTF_RIGHTDOWN = 0x0008;
        private const int MOUSEEVENTF_RIGHTUP = 0x0010;
        private const int MOUSEEVENTF_WHEEL = 0x0800;

        public float Sensitivity { get; set; } = 2.0f;
        private float _residueX = 0f;
        private float _residueY = 0f;

        public void Move(float dx, float dy)
        {
            float exactDx = (dx * Sensitivity) + _residueX;
            float exactDy = (dy * Sensitivity) + _residueY;

            int moveX = (int)Math.Round(exactDx);
            int moveY = (int)Math.Round(exactDy);

            _residueX = exactDx - moveX;
            _residueY = exactDy - moveY;

            if (moveX != 0 || moveY != 0)
            {
                var current = Cursor.Position;
                Cursor.Position = new Point(current.X + moveX, current.Y + moveY);
            }
        }

        public void Click(string button, bool isPressed)
        {
            if (button.Equals("L", StringComparison.OrdinalIgnoreCase))
            {
                mouse_event(isPressed ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
            }
            else if (button.Equals("R", StringComparison.OrdinalIgnoreCase))
            {
                mouse_event(isPressed ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
            }
        }

        public void Scroll(float deltaY)
        {
            mouse_event(MOUSEEVENTF_WHEEL, 0, 0, (int)(deltaY * 120), 0);
        }
    }
}
