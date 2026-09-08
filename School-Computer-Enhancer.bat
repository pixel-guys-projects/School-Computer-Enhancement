@echo off
:: Batch script to customize system settings, remove pre-installed apps, and set wallpaper
:: MUST BE RUN AS ADMINISTRATOR

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges.
    echo Please right-click the file and select "Run as administrator".
    pause
    exit /b
)

echo Starting system enhancements...

:: -------------------------------------------------------------------
:: 1. Enable System and App Dark Mode
:: -------------------------------------------------------------------
echo Configuring Dark Mode...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f >nul

:: -------------------------------------------------------------------
:: 2. Enable Fast Boot (Hiberboot)
:: -------------------------------------------------------------------
echo Enabling Fast Boot...
powercfg /hibernate on
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d 1 /f >nul

:: -------------------------------------------------------------------
:: 3. Enable and Select Ultimate Performance Power Plan
:: -------------------------------------------------------------------
echo Unlocking and selecting Ultimate Performance scheme...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1

:: -------------------------------------------------------------------
:: 4. Disable Basic Telemetry Services and Settings
:: -------------------------------------------------------------------
echo Disabling Telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
sc config DiagTrack start= disabled >nul 2>&1
sc stop DiagTrack >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1

:: -------------------------------------------------------------------
:: 5. Remove Target Apps (Clock, Weather, Copilot) via PowerShell
:: -------------------------------------------------------------------
echo Removing specific apps (Clock, Weather, Copilot)...
powershell -Command "Get-AppxPackage *Microsoft.WindowsAlarms* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Microsoft.BingWeather* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Microsoft.Copilot* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *Microsoft.Windows.Ai.Copilot* | Remove-AppxPackage" >nul 2>&1

:: Hide Copilot button from taskbar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCopilotButton" /t REG_DWORD /d 0 /f >nul

:: -------------------------------------------------------------------
:: 6. Download and Apply Desktop Wallpaper
:: -------------------------------------------------------------------
echo Downloading and applying wallpaper...
set "WALLPAPER_DIR=%SystemDrive%\Wallpapers"
set "WALLPAPER_PATH=%WALLPAPER_DIR%\Wallpaper.jpg"
set "WALLPAPER_URL=https://pixel-guys-projects.github.io/School-Computer-Enhancement/Wallpaper.jpg"

if not exist "%WALLPAPER_DIR%" mkdir "%WALLPAPER_DIR%"

powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%WALLPAPER_URL%', '%WALLPAPER_PATH%')"

if exist "%WALLPAPER_PATH%" (
    reg add "HKCU\Control Panel\Desktop" /v "Wallpaper" /t REG_SZ /d "%WALLPAPER_PATH%" /f >nul
    reg add "HKCU\Control Panel\Desktop" /v "WallpaperStyle" /t REG_SZ /d "10" /f >nul
    reg add "HKCU\Control Panel\Desktop" /v "TileWallpaper" /t REG_SZ /d "0" /f >nul
    
    :: Refresh wallpaper instantly
    powershell -Command "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class Wallpaper { [DllImport(\"user32.dll\", CharSet=CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); }'; [Wallpaper]::SystemParametersInfo(20, 0, '%WALLPAPER_PATH%', 3)" >nul
) else (
    echo [WARNING] Failed to download wallpaper image.
)

:: -------------------------------------------------------------------
:: Completion Message
:: -------------------------------------------------------------------
echo System configuration complete! Some changes may require a logoff or restart to take full effect.
pause