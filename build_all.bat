@echo off
echo ===================================================
echo   TelePad Project Builder - by i7Exceed
echo   Wireless Controller Relay & Virtual Gamepad Hub
echo ===================================================
echo.

:: Build C# Server
echo ---------------------------------------------------
echo [1/2] Building C# Server (TelePadServer)...
echo ---------------------------------------------------
cd TelePadServer
dotnet build --configuration Release
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] C# Server build failed!
    cd ..
    pause
    exit /b %ERRORLEVEL%
)
cd ..
echo.

:: Build Flutter Client
echo ---------------------------------------------------
echo [2/2] Building Flutter Client (telepad APK)...
echo ---------------------------------------------------
cd telepad
call flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Flutter client build failed!
    cd ..
    pause
    exit /b %ERRORLEVEL%
)
cd ..
echo.

echo ===================================================
echo   BUILD COMPLETED SUCCESSFULLY!
echo ===================================================
echo.
echo C# Server executable location:
echo   TelePadServer\bin\Release\net10.0-windows\TelePadServer.exe
echo.
echo Flutter Client APK location:
echo   telepad\build\app\outputs\flutter-apk\app-release.apk
echo.
pause
