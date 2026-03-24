@echo off
REM Engineering Skills - Windows Installation Script
REM Installs 18 engineering role skills for Kiro, Claude Code, and Cursor

echo ===================================
echo Engineering Skills Installer
echo 18 Senior Engineering Role Skills
echo Version 1.0
echo ===================================
echo.

REM Validate source files
if not exist "engineering-skills\steering" (
    echo ERROR: Source directory 'engineering-skills\steering' not found!
    echo Please run this script from the directory containing the engineering-skills folder.
    pause
    exit /b 1
)

if not exist "engineering-skills\steering\senior-architect.md" (
    echo ERROR: Required skill files not found in engineering-skills\steering\
    echo Installation package may be incomplete.
    pause
    exit /b 1
)

echo [OK] Source files validated
echo.

echo Select installation target:
echo 1) Kiro (user-level - all projects)
echo 2) Kiro (project-level - one project)
echo 3) Claude Code (user-level)
echo 4) Claude Code (project-level)
echo 5) Cursor (user-level)
echo 6) Custom path
echo 7) Install for all (Kiro, Claude, Cursor)
echo.
set /p choice="Enter choice [1-7]: "

if "%choice%"=="1" (
    set "steering_dir=%USERPROFILE%\.kiro\steering"
    goto :do_install
)
if "%choice%"=="2" (
    set /p project_path="Enter project path: "
    set "steering_dir=%project_path%\.kiro\steering"
    goto :do_install
)
if "%choice%"=="3" (
    set "steering_dir=%USERPROFILE%\.claude\steering"
    goto :do_install
)
if "%choice%"=="4" (
    set /p project_path="Enter project path: "
    set "steering_dir=%project_path%\.claude\steering"
    goto :do_install
)
if "%choice%"=="5" (
    goto :do_cursor_install
)
if "%choice%"=="6" (
    set /p steering_dir="Enter custom steering path: "
    goto :do_install
)
if "%choice%"=="7" (
    goto :install_all
)
echo Invalid choice
exit /b 1

:do_install
echo.
echo Installing to: %steering_dir%

REM Backup existing engineering skills
if exist "%steering_dir%\senior-architect.md" (
    echo Existing engineering skills found. Creating backup...
    if not exist "%steering_dir%\_backup_engineering" mkdir "%steering_dir%\_backup_engineering"
    for %%f in ("%steering_dir%\senior-*.md") do copy /Y "%%f" "%steering_dir%\_backup_engineering\" >nul
    for %%f in (code-reviewer.md aws-solution-architect.md ms365-tenant-manager.md tdd-guide.md tech-stack-evaluator.md) do (
        if exist "%steering_dir%\%%f" copy /Y "%steering_dir%\%%f" "%steering_dir%\_backup_engineering\" >nul
    )
    echo   [OK] Backed up to: %steering_dir%\_backup_engineering
)

if not exist "%steering_dir%" mkdir "%steering_dir%"
xcopy /I /Y "engineering-skills\steering\*.md" "%steering_dir%\" >nul

if exist "%steering_dir%\senior-architect.md" (
    echo [OK] Skills installed to: %steering_dir%
    goto :done
) else (
    echo [FAILED] Installation verification failed!
    goto :done_error
)

:do_cursor_install
echo.
set "cursor_dir=%USERPROFILE%\.cursor\rules\engineering"
echo Installing to: %cursor_dir%
if not exist "%cursor_dir%" mkdir "%cursor_dir%"
xcopy /I /Y "engineering-skills\steering\*.md" "%cursor_dir%\" >nul
if exist "%cursor_dir%\senior-architect.md" (
    echo [OK] Skills installed to: %cursor_dir%
    goto :done
) else (
    echo [FAILED] Cursor installation verification failed!
    goto :done_error
)

:install_all
echo.
echo [1/3] Installing for Kiro...
if not exist "%USERPROFILE%\.kiro\steering" mkdir "%USERPROFILE%\.kiro\steering"
if exist "%USERPROFILE%\.kiro\steering\senior-architect.md" (
    if not exist "%USERPROFILE%\.kiro\steering\_backup_engineering" mkdir "%USERPROFILE%\.kiro\steering\_backup_engineering"
    for %%f in ("%USERPROFILE%\.kiro\steering\senior-*.md") do copy /Y "%%f" "%USERPROFILE%\.kiro\steering\_backup_engineering\" >nul
    echo   [OK] Kiro backup created
)
xcopy /I /Y "engineering-skills\steering\*.md" "%USERPROFILE%\.kiro\steering\" >nul
echo   [OK] Kiro installation complete

echo.
echo [2/3] Installing for Claude Code...
if not exist "%USERPROFILE%\.claude\steering" mkdir "%USERPROFILE%\.claude\steering"
if exist "%USERPROFILE%\.claude\steering\senior-architect.md" (
    if not exist "%USERPROFILE%\.claude\steering\_backup_engineering" mkdir "%USERPROFILE%\.claude\steering\_backup_engineering"
    for %%f in ("%USERPROFILE%\.claude\steering\senior-*.md") do copy /Y "%%f" "%USERPROFILE%\.claude\steering\_backup_engineering\" >nul
    echo   [OK] Claude backup created
)
xcopy /I /Y "engineering-skills\steering\*.md" "%USERPROFILE%\.claude\steering\" >nul
echo   [OK] Claude Code installation complete

echo.
echo [3/3] Installing for Cursor...
if not exist "%USERPROFILE%\.cursor\rules\engineering" mkdir "%USERPROFILE%\.cursor\rules\engineering"
xcopy /I /Y "engineering-skills\steering\*.md" "%USERPROFILE%\.cursor\rules\engineering\" >nul
echo   [OK] Cursor installation complete

goto :done

:done
echo.
echo ===================================
echo Installation Complete!
echo ===================================
echo.
echo 18 Engineering Skills installed:
echo   Core:    senior-architect, senior-frontend, senior-backend,
echo            senior-fullstack, senior-qa, senior-devops,
echo            senior-secops, senior-security, code-reviewer
echo   Cloud:   aws-solution-architect, ms365-tenant-manager
echo   Tools:   tdd-guide, tech-stack-evaluator
echo   AI/Data: senior-data-scientist, senior-data-engineer,
echo            senior-ml-engineer, senior-prompt-engineer,
echo            senior-computer-vision
echo.
echo Skills are set to manual inclusion - activate with # in chat:
echo   e.g. #senior-backend, #senior-devops, #tdd-guide
echo.
echo See README.md for full documentation.
pause
exit /b 0

:done_error
echo.
echo ===================================
echo Installation Failed
echo ===================================
echo Please check the error messages above.
pause
exit /b 1
