// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

using System;
using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Exceptions;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using TelePadServer.Config;

namespace TelePadServer.Emulation
{
    public class VirtualControllerManager : IDisposable
    {
        private ViGEmClient? _client;
        private IXbox360Controller? _controller;

        public event Action<byte, byte>? OnVibrationFeedback;
        public event Action<string, bool>? OnControllerStatusChanged;

        public bool IsConnected => _controller != null;

        public static bool ProbeDriver(out string errorMessage)
        {
            errorMessage = string.Empty;
            try
            {
                using var probe = new ViGEmClient();
                return true;
            }
            catch (VigemBusNotFoundException)
            {
                errorMessage = ServerLocalization.T("logDriverMissing");
                return false;
            }
            catch (Exception ex)
            {
                errorMessage = ServerLocalization.Tf("logDriverWarning", ("err", ex.Message));
                return false;
            }
        }

        public bool Connect(out string errorMessage)
        {
            errorMessage = string.Empty;
            try
            {
                Disconnect();

                _client = new ViGEmClient();
                _controller = _client.CreateXbox360Controller();
                _controller.FeedbackReceived += Controller_FeedbackReceived;
                _controller.Connect();

                OnControllerStatusChanged?.Invoke(ServerLocalization.T("logControllerConnected"), true);
                return true;
            }
            catch (VigemBusNotFoundException)
            {
                errorMessage = ServerLocalization.T("logDriverMissing");
                OnControllerStatusChanged?.Invoke(errorMessage, false);
                return false;
            }
            catch (Exception ex)
            {
                errorMessage = ServerLocalization.Tf("logDriverWarning", ("err", ex.Message));
                OnControllerStatusChanged?.Invoke(errorMessage, false);
                return false;
            }
        }

        private void Controller_FeedbackReceived(object sender, Xbox360FeedbackReceivedEventArgs e)
        {
            OnVibrationFeedback?.Invoke(e.LargeMotor, e.SmallMotor);
        }

        public void SetButton(string key, bool isPressed)
        {
            if (_controller == null) return;

            if (key == "LT")
            {
                _controller.SetSliderValue(Xbox360Slider.LeftTrigger, (byte)(isPressed ? 255 : 0));
                _controller.SubmitReport();
                return;
            }
            
            if (key == "RT")
            {
                _controller.SetSliderValue(Xbox360Slider.RightTrigger, (byte)(isPressed ? 255 : 0));
                _controller.SubmitReport();
                return;
            }

            var btn = key switch
            {
                "A" => Xbox360Button.A,
                "B" => Xbox360Button.B,
                "X" => Xbox360Button.X,
                "Y" => Xbox360Button.Y,
                "LB" => Xbox360Button.LeftShoulder,
                "RB" => Xbox360Button.RightShoulder,
                "START" => Xbox360Button.Start,
                "SELECT" => Xbox360Button.Back,
                "HOME" => Xbox360Button.Guide,
                "LS_CLICK" => Xbox360Button.LeftThumb,
                "RS_CLICK" => Xbox360Button.RightThumb,
                "DPAD_UP" => Xbox360Button.Up,
                "DPAD_DOWN" => Xbox360Button.Down,
                "DPAD_LEFT" => Xbox360Button.Left,
                "DPAD_RIGHT" => Xbox360Button.Right,
                _ => null
            };

            if (btn != null)
            {
                _controller.SetButtonState(btn, isPressed);
                _controller.SubmitReport();
            }
        }

        public void SetAnalog(string axisId, float x, float y)
        {
            if (_controller == null) return;

            short normX = (short)Math.Clamp((int)(x * 32767), short.MinValue, short.MaxValue);
            short normY = (short)Math.Clamp((int)(y * 32767), short.MinValue, short.MaxValue);

            if (axisId == "LS")
            {
                _controller.SetAxisValue(Xbox360Axis.LeftThumbX, normX);
                _controller.SetAxisValue(Xbox360Axis.LeftThumbY, normY);
            }
            else if (axisId == "RS")
            {
                _controller.SetAxisValue(Xbox360Axis.RightThumbX, normX);
                _controller.SetAxisValue(Xbox360Axis.RightThumbY, normY);
            }
            else if (axisId == "LT")
            {
                _controller.SetSliderValue(Xbox360Slider.LeftTrigger, (byte)(Math.Clamp(x, 0f, 1f) * 255f));
            }
            else if (axisId == "RT")
            {
                _controller.SetSliderValue(Xbox360Slider.RightTrigger, (byte)(Math.Clamp(x, 0f, 1f) * 255f));
            }

            _controller.SubmitReport();
        }

        public void Disconnect()
        {
            try
            {
                if (_controller != null)
                {
                    _controller.FeedbackReceived -= Controller_FeedbackReceived;
                    _controller.Disconnect();
                    _controller = null;
                }
            }
            catch { }

            try
            {
                _client?.Dispose();
                _client = null;
            }
            catch { }
        }

        public void Dispose()
        {
            Disconnect();
        }
    }
}
