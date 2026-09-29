@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  overleaf_sync.bat
::  Run this from inside your Overleaf Git repository.
::
::  Usage:  overleaf_sync.bat [push|pull|status]
::          Defaults to "push".
:: ============================================================

:: ── Configuration ───────────────────────────────────────────
set "REMOTE=origin"
set "BRANCH=master"
set "COMMIT_PREFIX=figures: update rendered outputs"

:: ── Argument parsing ─────────────────────────────────────────
set "CMD=%~1"
if "%CMD%"=="" set "CMD=push"

if /i "%CMD%"=="push"   goto :do_push
if /i "%CMD%"=="pull"   goto :do_pull
if /i "%CMD%"=="status" goto :do_status

echo [ERROR] Unknown command: %CMD%
echo Usage: overleaf_sync.bat [push^|pull^|status]
goto :eof

:: ════════════════════════════════════════════════════════════
:do_push
:: ════════════════════════════════════════════════════════════
echo.
echo [overleaf_sync] Fetching remote changes...
git fetch %REMOTE% %BRANCH%
if errorlevel 1 (
    echo [ERROR] git fetch failed. Check your connection and credentials.
    goto :eof
)

echo [overleaf_sync] Staging local changes...
git add -A
git status --short

:: Skip commit if nothing was staged
git diff --cached --quiet
if not errorlevel 1 (
    echo [INFO] Nothing to commit, attempting push anyway...
    goto :push_only
)

:: Build a timestamped commit message
for /f "tokens=1-3 delims=/" %%a in ("%DATE%") do set "DS=%%c-%%a-%%b"
for /f "tokens=1-2 delims=:" %%a in ("%TIME: =0%") do set "TS=%%a:%%b"
set "MSG=%COMMIT_PREFIX% [%DS% %TS%]"

echo [overleaf_sync] Committing: %MSG%
git commit -m "%MSG%"
if errorlevel 1 (
    echo [ERROR] git commit failed.
    goto :eof
)

echo [overleaf_sync] Rebasing onto remote...
git rebase %REMOTE%/%BRANCH%
if errorlevel 1 (
    echo.
    echo [ERROR] Rebase conflict. Resolve the files above, then run:
    echo           git add ^<resolved-file^>
    echo           git rebase --continue
    echo         or to abort: git rebase --abort
    goto :eof
)

:push_only
echo [overleaf_sync] Pushing to Overleaf...
git push %REMOTE% HEAD:%BRANCH%
if errorlevel 1 (
    echo [ERROR] Push failed. See message above.
    goto :eof
)

echo [overleaf_sync] Done.
goto :eof

:: ════════════════════════════════════════════════════════════
:do_pull
:: ════════════════════════════════════════════════════════════
echo.
echo [overleaf_sync] Pulling from Overleaf...
git pull --rebase %REMOTE% %BRANCH%
if errorlevel 1 (
    echo [ERROR] Pull failed. Resolve conflicts and rerun.
    goto :eof
)
echo [overleaf_sync] Done.
goto :eof

:: ════════════════════════════════════════════════════════════
:do_status
:: ════════════════════════════════════════════════════════════
echo.
git fetch %REMOTE% %BRANCH% --quiet

echo --- Local changes ---
git status --short

echo.
echo --- Ahead of remote ---
git log %REMOTE%/%BRANCH%..HEAD --oneline

echo.
echo --- Behind remote ---
git log HEAD..%REMOTE%/%BRANCH% --oneline
goto :eof

endlocal
