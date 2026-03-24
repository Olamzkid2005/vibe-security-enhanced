@echo off
REM Unified Installer - Superpowers + Vibe Security + Engineering Skills
REM Supports install, upgrade (with backup), and restore

echo ===================================
echo Unified Skills Installer
echo Superpowers + Vibe Security + Engineering
echo Version 2.0
echo ===================================
echo.

echo What would you like to do?
echo 1) Install / Upgrade
echo 2) Restore from backup
echo.
set /p action="Enter choice [1-2]: "

if "%action%"=="2" goto :restore_menu
if "%action%"=="1" goto :install_menu
echo Invalid choice
exit /b 1

REM ===================================
REM INSTALL / UPGRADE
REM ===================================
:install_menu
echo.

REM Validate required source files
if not exist "superpowers-skills\steering\00-using-superpowers.md" (
    echo ERROR: Source files not found. Run this script from the package directory.
    pause & exit /b 1
)
if not exist "vibe-security-enhanced\skill.md" (
    echo ERROR: Source files not found. Run this script from the package directory.
    pause & exit /b 1
)

set HAS_ENGINEERING=0
if exist "engineering-skills\steering\senior-architect.md" (
    set HAS_ENGINEERING=1
    echo [OK] Engineering skills found (18 skills)
)
echo.

echo Select installation target:
echo 1) Kiro (user-level - all projects)
echo 2) Kiro (project-level - one project)
echo 3) Claude Code (user-level)
echo 4) Claude Code (project-level)
echo 5) Cursor (user-level)
echo 6) Custom path
echo 7) Install for all assistants (Kiro, Claude, Cursor)
echo.
set /p choice="Enter choice [1-7]: "

if "%choice%"=="1" (
    set "steering_dir=%USERPROFILE%\.kiro\steering"
    set "skills_dir=%USERPROFILE%\.kiro\skills"
    set "backup_dir=%USERPROFILE%\.kiro\steering\_backup"
    set "backup_skills_dir=%USERPROFILE%\.kiro\skills\_backup"
    goto :do_install
)
if "%choice%"=="2" (
    set /p project_path="Enter project path: "
    set "steering_dir=%project_path%\.kiro\steering"
    set "skills_dir=%project_path%\.kiro\skills"
    set "backup_dir=%project_path%\.kiro\steering\_backup"
    set "backup_skills_dir=%project_path%\.kiro\skills\_backup"
    goto :do_install
)
if "%choice%"=="3" (
    set "steering_dir=%USERPROFILE%\.claude\steering"
    set "skills_dir=%USERPROFILE%\.claude\skills"
    set "backup_dir=%USERPROFILE%\.claude\steering\_backup"
    set "backup_skills_dir=%USERPROFILE%\.claude\skills\_backup"
    goto :do_install
)
if "%choice%"=="4" (
    set /p project_path="Enter project path: "
    set "steering_dir=%project_path%\.claude\steering"
    set "skills_dir=%project_path%\.claude\skills"
    set "backup_dir=%project_path%\.claude\steering\_backup"
    set "backup_skills_dir=%project_path%\.claude\skills\_backup"
    goto :do_install
)
if "%choice%"=="5" (
    goto :do_cursor_install
)
if "%choice%"=="6" (
    set /p base_dir="Enter custom installation path: "
    set "steering_dir=%base_dir%\steering"
    set "skills_dir=%base_dir%\skills"
    set "backup_dir=%base_dir%\steering\_backup"
    set "backup_skills_dir=%base_dir%\skills\_backup"
    goto :do_install
)
if "%choice%"=="7" goto :install_all

echo Invalid choice
exit /b 1

:do_install
echo.
REM Backup existing installation
if exist "%steering_dir%\00-using-superpowers.md" (
    echo Existing installation found. Creating backup...
    if not exist "%backup_dir%" mkdir "%backup_dir%"
    xcopy /I /Y "%steering_dir%\*.md" "%backup_dir%\" >nul
    echo   [OK] Steering files backed up to: %backup_dir%
)
if exist "%skills_dir%\vibe-security-enhanced\skill.md" (
    if not exist "%backup_skills_dir%\vibe-security-enhanced" mkdir "%backup_skills_dir%\vibe-security-enhanced"
    xcopy /E /I /Y "%skills_dir%\vibe-security-enhanced" "%backup_skills_dir%\vibe-security-enhanced\" >nul
    echo   [OK] Vibe Security backed up
)

REM Install
if not exist "%steering_dir%" mkdir "%steering_dir%"
if not exist "%skills_dir%" mkdir "%skills_dir%"
echo.
echo Installing Superpowers Skills Framework...
xcopy /E /I /Y superpowers-skills\steering\* "%steering_dir%\" >nul
echo   [OK] Superpowers installed

echo Installing Vibe Security Enhanced...
xcopy /E /I /Y vibe-security-enhanced "%skills_dir%\vibe-security-enhanced" >nul
echo   [OK] Vibe Security installed

if "%HAS_ENGINEERING%"=="1" (
    echo Installing Engineering Skills...
    xcopy /I /Y "engineering-skills\steering\*.md" "%steering_dir%\" >nul
    echo   [OK] Engineering Skills installed (18 skills)
)
goto :done

:do_cursor_install
echo.
REM Backup existing Cursor installation
if exist "%USERPROFILE%\.cursor\rules\superpowers\00-using-superpowers.md" (
    echo Existing Cursor installation found. Creating backup...
    if not exist "%USERPROFILE%\.cursor\rules\_backup\superpowers" mkdir "%USERPROFILE%\.cursor\rules\_backup\superpowers"
    xcopy /E /I /Y "%USERPROFILE%\.cursor\rules\superpowers\*" "%USERPROFILE%\.cursor\rules\_backup\superpowers\" >nul
    echo   [OK] Superpowers backed up
)
if exist "%USERPROFILE%\.cursor\rules\security\skill.md" (
    if not exist "%USERPROFILE%\.cursor\rules\_backup\security" mkdir "%USERPROFILE%\.cursor\rules\_backup\security"
    xcopy /E /I /Y "%USERPROFILE%\.cursor\rules\security\*" "%USERPROFILE%\.cursor\rules\_backup\security\" >nul
    echo   [OK] Vibe Security backed up
)

REM Install for Cursor
if not exist "%USERPROFILE%\.cursor\rules\superpowers" mkdir "%USERPROFILE%\.cursor\rules\superpowers"
if not exist "%USERPROFILE%\.cursor\rules\security" mkdir "%USERPROFILE%\.cursor\rules\security"
echo.
echo Installing Superpowers Skills Framework...
xcopy /E /I /Y superpowers-skills\steering\* "%USERPROFILE%\.cursor\rules\superpowers\" >nul
echo   [OK] Superpowers installed

echo Installing Vibe Security Enhanced...
xcopy /I /Y vibe-security-enhanced\skill.md "%USERPROFILE%\.cursor\rules\security\" >nul
xcopy /E /I /Y vibe-security-enhanced\references "%USERPROFILE%\.cursor\rules\security\references" >nul
echo   [OK] Vibe Security installed

if "%HAS_ENGINEERING%"=="1" (
    echo Installing Engineering Skills...
    if not exist "%USERPROFILE%\.cursor\rules\engineering" mkdir "%USERPROFILE%\.cursor\rules\engineering"
    xcopy /I /Y "engineering-skills\steering\*.md" "%USERPROFILE%\.cursor\rules\engineering\" >nul
    echo   [OK] Engineering Skills installed (18 skills)
)
goto :done

:install_all
echo.
echo [1/3] Installing for Kiro...
if exist "%USERPROFILE%\.kiro\steering\00-using-superpowers.md" (
    echo   Backing up existing Kiro installation...
    if not exist "%USERPROFILE%\.kiro\steering\_backup" mkdir "%USERPROFILE%\.kiro\steering\_backup"
    xcopy /I /Y "%USERPROFILE%\.kiro\steering\*.md" "%USERPROFILE%\.kiro\steering\_backup\" >nul
    echo   [OK] Kiro steering backed up
)
if exist "%USERPROFILE%\.kiro\skills\vibe-security-enhanced\skill.md" (
    if not exist "%USERPROFILE%\.kiro\skills\_backup\vibe-security-enhanced" mkdir "%USERPROFILE%\.kiro\skills\_backup\vibe-security-enhanced"
    xcopy /E /I /Y "%USERPROFILE%\.kiro\skills\vibe-security-enhanced" "%USERPROFILE%\.kiro\skills\_backup\vibe-security-enhanced\" >nul
    echo   [OK] Kiro security skill backed up
)
if not exist "%USERPROFILE%\.kiro\steering" mkdir "%USERPROFILE%\.kiro\steering"
if not exist "%USERPROFILE%\.kiro\skills" mkdir "%USERPROFILE%\.kiro\skills"
xcopy /E /I /Y superpowers-skills\steering\* "%USERPROFILE%\.kiro\steering\" >nul
xcopy /E /I /Y vibe-security-enhanced "%USERPROFILE%\.kiro\skills\vibe-security-enhanced" >nul
if "%HAS_ENGINEERING%"=="1" (
    xcopy /I /Y "engineering-skills\steering\*.md" "%USERPROFILE%\.kiro\steering\" >nul
    echo   [OK] Engineering Skills installed
)
echo   [OK] Kiro installation complete

echo.
echo [2/3] Installing for Claude Code...
if exist "%USERPROFILE%\.claude\steering\00-using-superpowers.md" (
    echo   Backing up existing Claude installation...
    if not exist "%USERPROFILE%\.claude\steering\_backup" mkdir "%USERPROFILE%\.claude\steering\_backup"
    xcopy /I /Y "%USERPROFILE%\.claude\steering\*.md" "%USERPROFILE%\.claude\steering\_backup\" >nul
    echo   [OK] Claude steering backed up
)
if not exist "%USERPROFILE%\.claude\steering" mkdir "%USERPROFILE%\.claude\steering"
if not exist "%USERPROFILE%\.claude\skills" mkdir "%USERPROFILE%\.claude\skills"
xcopy /E /I /Y superpowers-skills\steering\* "%USERPROFILE%\.claude\steering\" >nul
xcopy /E /I /Y vibe-security-enhanced "%USERPROFILE%\.claude\skills\vibe-security-enhanced" >nul
if "%HAS_ENGINEERING%"=="1" (
    xcopy /I /Y "engineering-skills\steering\*.md" "%USERPROFILE%\.claude\steering\" >nul
    echo   [OK] Engineering Skills installed
)
echo   [OK] Claude Code installation complete

echo.
echo [3/3] Installing for Cursor...
if exist "%USERPROFILE%\.cursor\rules\superpowers\00-using-superpowers.md" (
    echo   Backing up existing Cursor installation...
    if not exist "%USERPROFILE%\.cursor\rules\_backup\superpowers" mkdir "%USERPROFILE%\.cursor\rules\_backup\superpowers"
    xcopy /E /I /Y "%USERPROFILE%\.cursor\rules\superpowers\*" "%USERPROFILE%\.cursor\rules\_backup\superpowers\" >nul
    echo   [OK] Cursor rules backed up
)
if not exist "%USERPROFILE%\.cursor\rules\superpowers" mkdir "%USERPROFILE%\.cursor\rules\superpowers"
if not exist "%USERPROFILE%\.cursor\rules\security" mkdir "%USERPROFILE%\.cursor\rules\security"
xcopy /E /I /Y superpowers-skills\steering\* "%USERPROFILE%\.cursor\rules\superpowers\" >nul
xcopy /I /Y vibe-security-enhanced\skill.md "%USERPROFILE%\.cursor\rules\security\" >nul
xcopy /E /I /Y vibe-security-enhanced\references "%USERPROFILE%\.cursor\rules\security\references" >nul
if "%HAS_ENGINEERING%"=="1" (
    if not exist "%USERPROFILE%\.cursor\rules\engineering" mkdir "%USERPROFILE%\.cursor\rules\engineering"
    xcopy /I /Y "engineering-skills\steering\*.md" "%USERPROFILE%\.cursor\rules\engineering\" >nul
    echo   [OK] Engineering Skills installed
)
echo   [OK] Cursor installation complete
goto :done

REM ===================================
REM RESTORE FROM BACKUP
REM ===================================
:restore_menu
echo.
echo Select which assistant to restore:
echo 1) Kiro (user-level)
echo 2) Claude Code (user-level)
echo 3) Cursor (user-level)
echo 4) Custom path
echo.
set /p restore_choice="Enter choice [1-4]: "

if "%restore_choice%"=="1" (
    set "steering_dir=%USERPROFILE%\.kiro\steering"
    set "skills_dir=%USERPROFILE%\.kiro\skills"
    set "backup_dir=%USERPROFILE%\.kiro\steering\_backup"
    set "backup_skills_dir=%USERPROFILE%\.kiro\skills\_backup"
    goto :do_restore
)
if "%restore_choice%"=="2" (
    set "steering_dir=%USERPROFILE%\.claude\steering"
    set "skills_dir=%USERPROFILE%\.claude\skills"
    set "backup_dir=%USERPROFILE%\.claude\steering\_backup"
    set "backup_skills_dir=%USERPROFILE%\.claude\skills\_backup"
    goto :do_restore
)
if "%restore_choice%"=="3" goto :do_cursor_restore
if "%restore_choice%"=="4" (
    set /p base_dir="Enter custom installation path: "
    set "steering_dir=%base_dir%\steering"
    set "skills_dir=%base_dir%\skills"
    set "backup_dir=%base_dir%\steering\_backup"
    set "backup_skills_dir=%base_dir%\skills\_backup"
    goto :do_restore
)
echo Invalid choice
exit /b 1

:do_restore
if not exist "%backup_dir%" (
    echo ERROR: No backup found at: %backup_dir%
    pause & exit /b 1
)
echo.
echo Restoring from backup...
xcopy /I /Y "%backup_dir%\*.md" "%steering_dir%\" >nul
echo   [OK] Steering files restored from: %backup_dir%
if exist "%backup_skills_dir%\vibe-security-enhanced" (
    xcopy /E /I /Y "%backup_skills_dir%\vibe-security-enhanced" "%skills_dir%\vibe-security-enhanced\" >nul
    echo   [OK] Vibe Security restored
)
goto :restore_done

:do_cursor_restore
set "backup_dir=%USERPROFILE%\.cursor\rules\_backup"
if not exist "%backup_dir%" (
    echo ERROR: No backup found at: %backup_dir%
    pause & exit /b 1
)
echo.
echo Restoring Cursor from backup...
if exist "%backup_dir%\superpowers" (
    xcopy /E /I /Y "%backup_dir%\superpowers\*" "%USERPROFILE%\.cursor\rules\superpowers\" >nul
    echo   [OK] Superpowers rules restored
)
if exist "%backup_dir%\security" (
    xcopy /E /I /Y "%backup_dir%\security\*" "%USERPROFILE%\.cursor\rules\security\" >nul
    echo   [OK] Security rules restored
)
goto :restore_done

:restore_done
echo.
echo ===================================
echo Restore Complete!
echo ===================================
echo Previous version has been restored.
pause
exit /b 0

:done
echo.
echo ===================================
echo Installation Complete!
echo ===================================
echo.
echo SUPERPOWERS SKILLS FRAMEWORK
echo   - Design before implementation (brainstorming)
echo   - Test-driven development (TDD)
echo   - Systematic debugging (root cause analysis)
echo   - Evidence-based verification
echo   - Detailed planning
echo   - Code review checklists
echo.
echo VIBE SECURITY ENHANCED
echo   - 22 security categories
echo   - Automatic vulnerability detection
echo   - Financial/trading security
echo   - ML/AI security
echo   - Comprehensive code audits
echo.
if "%HAS_ENGINEERING%"=="1" (
    echo ENGINEERING SKILLS (18 skills)
    echo   Core:    senior-architect, senior-frontend, senior-backend,
    echo            senior-fullstack, senior-qa, senior-devops,
    echo            senior-secops, senior-security, code-reviewer
    echo   Cloud:   aws-solution-architect, ms365-tenant-manager
    echo   Tools:   tdd-guide, tech-stack-evaluator
    echo   AI/Data: senior-data-scientist, senior-data-engineer,
    echo            senior-ml-engineer, senior-prompt-engineer,
    echo            senior-computer-vision
    echo   Activate with # in chat: e.g. #senior-backend, #tdd-guide
    echo.
)
echo TIP: A backup of your previous version was saved.
echo      Run this installer again and choose option 2 to restore it.
echo.
echo See README.md files for full documentation.
echo.
pause
