@echo off
REM Vibe Security Enhanced - Windows Installation Script

echo ===================================
echo Vibe Security Enhanced Installer
echo Version 2.0
echo ===================================
echo.

REM Validation: Check if source directory exists
if not exist "vibe-security-enhanced" (
    echo ERROR: Source directory 'vibe-security-enhanced' not found!
    echo Please run this script from the directory containing the vibe-security-enhanced folder.
    pause
    exit /b 1
)

REM Validation: Check if required files exist
if not exist "vibe-security-enhanced\skill.md" (
    echo ERROR: Required file 'skill.md' not found!
    echo Installation package may be incomplete.
    pause
    exit /b 1
)

if not exist "vibe-security-enhanced\README.md" (
    echo ERROR: Required file 'README.md' not found!
    echo Installation package may be incomplete.
    pause
    exit /b 1
)

if not exist "vibe-security-enhanced\references\secrets-and-env.md" (
    echo ERROR: Required reference file 'secrets-and-env.md' not found!
    echo Installation package may be incomplete.
    pause
    exit /b 1
)

echo [OK] Source files validated
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

REM Check for existing installation
if exist "%install_dir%\vibe-security-enhanced" (
    echo.
    echo WARNING: Installation already exists at:
    echo   %install_dir%\vibe-security-enhanced
    echo.
    set /p confirm="Overwrite existing installation? [y/N]: "
    if /i not "%confirm%"=="y" (
        echo Installation cancelled.
        goto :done_with_error
    )
    echo Removing existing installation...
    rmdir /S /Q "%install_dir%\vibe-security-enhanced"
)

if not exist "%install_dir%" mkdir "%install_dir%"
xcopy /E /I /Y vibe-security-enhanced "%install_dir%\vibe-security-enhanced" >nul

REM Verify installation
if exist "%install_dir%\vibe-security-enhanced\skill.md" (
    echo [OK] Installed to: %install_dir%\vibe-security-enhanced
    goto :done
) else (
    echo [FAILED] Installation verification failed!
    goto :done_with_error
)

:install_all
echo Installing for all assistants...
echo.

REM Install for Kiro
set "kiro_dir=%USERPROFILE%\.kiro\skills"
if exist "%kiro_dir%\vibe-security-enhanced" (
    echo WARNING: Kiro installation already exists
    set /p confirm_kiro="Overwrite Kiro installation? [y/N]: "
    if /i "%confirm_kiro%"=="y" (
        rmdir /S /Q "%kiro_dir%\vibe-security-enhanced"
    ) else (
        echo Skipping Kiro installation
        goto :install_claude
    )
)
if not exist "%kiro_dir%" mkdir "%kiro_dir%"
xcopy /E /I /Y vibe-security-enhanced "%kiro_dir%\vibe-security-enhanced" >nul
if exist "%kiro_dir%\vibe-security-enhanced\skill.md" (
    echo [OK] Installed for Kiro
) else (
    echo [FAILED] Kiro installation verification failed
)

:install_claude
REM Install for Claude Code
set "claude_dir=%USERPROFILE%\.claude\skills"
if exist "%claude_dir%\vibe-security-enhanced" (
    echo WARNING: Claude Code installation already exists
    set /p confirm_claude="Overwrite Claude Code installation? [y/N]: "
    if /i "%confirm_claude%"=="y" (
        rmdir /S /Q "%claude_dir%\vibe-security-enhanced"
    ) else (
        echo Skipping Claude Code installation
        goto :install_cursor
    )
)
if not exist "%claude_dir%" mkdir "%claude_dir%"
xcopy /E /I /Y vibe-security-enhanced "%claude_dir%\vibe-security-enhanced" >nul
if exist "%claude_dir%\vibe-security-enhanced\skill.md" (
    echo [OK] Installed for Claude Code
) else (
    echo [FAILED] Claude Code installation verification failed
)

:install_cursor
REM Install for Cursor
set "cursor_dir=%USERPROFILE%\.cursor\skills"
if exist "%cursor_dir%\vibe-security-enhanced" (
    echo WARNING: Cursor installation already exists
    set /p confirm_cursor="Overwrite Cursor installation? [y/N]: "
    if /i "%confirm_cursor%"=="y" (
        rmdir /S /Q "%cursor_dir%\vibe-security-enhanced"
    ) else (
        echo Skipping Cursor installation
        goto :done
    )
)
if not exist "%cursor_dir%" mkdir "%cursor_dir%"
xcopy /E /I /Y vibe-security-enhanced "%cursor_dir%\vibe-security-enhanced" >nul
if exist "%cursor_dir%\vibe-security-enhanced\skill.md" (
    echo [OK] Installed for Cursor
) else (
    echo [FAILED] Cursor installation verification failed
)
goto :done

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
exit /b 0

:done_with_error
echo.
echo ===================================
echo Installation Failed or Cancelled
echo ===================================
echo.
echo Please check the error messages above.
pause
exit /b 1
