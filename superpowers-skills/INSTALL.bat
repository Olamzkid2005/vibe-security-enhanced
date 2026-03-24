@echo off
REM Superpowers Skills Framework - Windows Installation Script

echo ===================================
echo Superpowers Skills Framework Installer
echo Version 1.0
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
    set "install_dir=%USERPROFILE%\.kiro\steering"
    goto :install
)
if "%choice%"=="2" (
    set /p project_path="Enter project path: "
    set "install_dir=%project_path%\.kiro\steering"
    goto :install
)
if "%choice%"=="3" (
    set "install_dir=%USERPROFILE%\.claude\steering"
    goto :install
)
if "%choice%"=="4" (
    set /p project_path="Enter project path: "
    set "install_dir=%project_path%\.claude\steering"
    goto :install
)
if "%choice%"=="5" (
    set "install_dir=%USERPROFILE%\.cursor\steering"
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
xcopy /E /I /Y steering\* "%install_dir%\"
echo Installation complete!
goto :done

:install_all
echo Installing for all assistants...
if not exist "%USERPROFILE%\.kiro\steering" mkdir "%USERPROFILE%\.kiro\steering"
xcopy /E /I /Y steering\* "%USERPROFILE%\.kiro\steering\"
echo Installed for Kiro

if not exist "%USERPROFILE%\.claude\steering" mkdir "%USERPROFILE%\.claude\steering"
xcopy /E /I /Y steering\* "%USERPROFILE%\.claude\steering\"
echo Installed for Claude Code

if not exist "%USERPROFILE%\.cursor\steering" mkdir "%USERPROFILE%\.cursor\steering"
xcopy /E /I /Y steering\* "%USERPROFILE%\.cursor\steering\"
echo Installed for Cursor

:done
echo.
echo ===================================
echo Installation Complete!
echo ===================================
echo.
echo The skills will automatically guide development:
echo - Design before implementation (brainstorming)
echo - Test-driven development (TDD)
echo - Systematic debugging (root cause analysis)
echo - Evidence-based verification
echo - Detailed planning
echo - Code review checklists
echo.
echo Skills activate automatically based on context.
echo See README.md for full documentation.
pause
