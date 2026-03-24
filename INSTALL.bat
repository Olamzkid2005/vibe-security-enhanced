@echo off
REM Vibe Security Enhanced - Windows Installation Script

echo ===================================
echo Vibe Security Enhanced Installer
echo Version 2.0
echo ===================================
echo.

echo Select installation type:
echo 1) Kiro (user-level)
echo 2) Kiro (project-level)
echo 3) Claude Code (user-level)
echo 4) Claude Code (project-level)
echo 5) Cursor (user-level)
echo 6) Custom path
echo 7) Install for all (Kiro, Claude, Cursor)
echo.

set /p choice="Enter choice [1-7]: "

if "%choice%"=="1" (
    set "install_dir=%USERPROFILE%\.kiro\skills"
    goto :install
)
if "%choice%"=="2" (
    set /p project_path="Enter project path: "
    set "install_dir=%project_path%\.kiro\skills"
    goto :install
)
if "%choice%"=="3" (
    set "install_dir=%USERPROFILE%\.claude\skills"
    goto :install
)
if "%choice%"=="4" (
    set /p project_path="Enter project path: "
    set "install_dir=%project_path%\.claude\skills"
    goto :install
)
if "%choice%"=="5" (
    set "install_dir=%USERPROFILE%\.cursor\skills"
    goto :install
)
if "%choice%"=="6" (
    set /p install_dir="Enter custom installation path: "
    goto :install
)
if "%choice%"=="7" (
    goto :install_all
)

echo Invalid choice
exit /b 1

:install
echo Installing to: %install_dir%
if not exist "%install_dir%" mkdir "%install_dir%"
xcopy /E /I /Y vibe-security-enhanced "%install_dir%\vibe-security-enhanced"
echo Installation complete!
goto :done

:install_all
echo Installing for all assistants...
if not exist "%USERPROFILE%\.kiro\skills" mkdir "%USERPROFILE%\.kiro\skills"
xcopy /E /I /Y vibe-security-enhanced "%USERPROFILE%\.kiro\skills\vibe-security-enhanced"
echo Installed for Kiro

if not exist "%USERPROFILE%\.claude\skills" mkdir "%USERPROFILE%\.claude\skills"
xcopy /E /I /Y vibe-security-enhanced "%USERPROFILE%\.claude\skills\vibe-security-enhanced"
echo Installed for Claude Code

if not exist "%USERPROFILE%\.cursor\skills" mkdir "%USERPROFILE%\.cursor\skills"
xcopy /E /I /Y vibe-security-enhanced "%USERPROFILE%\.cursor\skills\vibe-security-enhanced"
echo Installed for Cursor

:done
echo.
echo ===================================
echo Installation Complete!
echo ===================================
echo.
echo The skill will automatically activate when you:
echo - Ask about security
echo - Request code reviews
echo - Work with authentication, payments, or sensitive data
echo.
echo For manual activation:
echo - Kiro/Claude: Ask 'run a security audit'
echo - Claude Code: Use /vibe-security-enhanced
echo.
echo See README.md for full documentation.
pause
