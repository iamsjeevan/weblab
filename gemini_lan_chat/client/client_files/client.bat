@echo off
REM Enable delayed expansion for certain variable operations if needed, though not strictly required for this exact script.
SETLOCAL

REM --- Define paths relative to the script's location ---
REM %~dp0 is the drive and path of the batch file itself, always ending with a backslash.
SET "LIBS_DIR=%~dp0libs"
SET "CLIENT_SCRIPT=%~dp0client.py"
SET "BUNDLE_FILENAME=%~dp0requests_bundle.zip"
SET "IP_CACHE_FILE=%~dp0.server_ip_cache"

REM Go to the script's directory to ensure relative paths work consistently
pushd "%~dp0"

REM --- Main Logic ---
REM Check if the libs directory exists. If not, run setup.
IF NOT EXIST "%LIBS_DIR%\" (
    ECHO %LIBS_DIR% not found. Running first-time setup...
    CALL :run_setup
    REM Check the return code from the setup subroutine
    IF %ERRORLEVEL% NEQ 0 (
        ECHO Setup failed. Exiting.
        popd
        EXIT /B %ERRORLEVEL%
    )
)

REM Get the cached server IP
IF NOT EXIST "%IP_CACHE_FILE%" (
    ECHO Server IP not configured. Please run the setup again by deleting the 'libs' folder.
    popd
    EXIT /B 1
) ELSE (
    REM Read the first line of the file into the SERVER_IP variable
    SET /P SERVER_IP=<"%IP_CACHE_FILE%"
)

ECHO Starting client...
REM Run the python client, passing the server IP as an argument
REM Make sure 'python' command is in your system's PATH and points to Python 3.x
python "%CLIENT_SCRIPT%" "%SERVER_IP%"
IF %ERRORLEVEL% NEQ 0 (
    ECHO Python client exited with an error (Error Code: %ERRORLEVEL%).
)

popd
ENDLOCAL
EXIT /B %ERRORLEVEL%

REM --- Subroutine for First-Time Setup ---
:run_setup
    ECHO --- First-time setup: Installing dependencies ---
    SET /P SERVER_IP="Enter the server's Public IP address: "
    IF "%SERVER_IP%"=="" (
        ECHO ERROR: IP cannot be empty.
        EXIT /B 1
    )

    ECHO %SERVER_IP% > "%IP_CACHE_FILE%"

    SET "BUNDLE_URL=http://%SERVER_IP%:5000/download_dependencies"
    ECHO Downloading from %SERVER_IP%...
    REM Curl is generally available on modern Windows versions
    curl -# -L -f -o "%BUNDLE_FILENAME%" "%BUNDLE_URL%"
    
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ERROR: Download failed. Check server IP and connection.
        EXIT /B 1
    )

    ECHO Unpacking libraries...
    REM Use python to perform platform-aware unzipping
    REM Paths passed to python must be valid Windows paths and
    REM correctly quoted within the Python string. Using raw strings r'' is best.
    
    REM Define paths for the Python script
    REM Use %~dp0 directly for dynamic path resolution inside the -c command if needed
    REM For clarity, explicitly set them here
    SET "PY_LIBS_DIR=%LIBS_DIR%"
    SET "PY_BUNDLE_FILENAME=%BUNDLE_FILENAME%"
    SET "PY_TEMP_EXTRACT_PATH=%~dp0temp_bundle_extract"

    python -c "import os, sys, platform, zipfile, shutil; \
    LIBS_DIR = r'%PY_LIBS_DIR%'; \
    BUNDLE_FILENAME = r'%PY_BUNDLE_FILENAME%'; \
    TEMP_EXTRACT_PATH = r'%PY_TEMP_EXTRACT_PATH%'; \
    \
    def get_platform_identifier(): \
        s, m = platform.system().lower(), platform.machine().lower(); \
        if s == 'linux': return 'linux_x86_64' if m in ['x86_64', 'amd64'] else 'linux_aarch64'; \
        if s == 'darwin': return 'macos_arm64' if m == 'arm64' else 'macos_x86_64'; \
        if s == 'windows': \
            if m in ['x86_64', 'amd64']: return 'windows_x86_64'; \
            elif m == 'arm64': return 'windows_arm64'; \
            else: return None; \
        return None; \
    \
    p_dir = get_platform_identifier(); \
    if not p_dir: sys.exit(f'FATAL: Unsupported OS/Architecture ({platform.system()}/{platform.machine()})'); \
    \
    with zipfile.ZipFile(BUNDLE_FILENAME, 'r') as zf: zf.extractall(TEMP_EXTRACT_PATH); \
    source_dir = os.path.join(TEMP_EXTRACT_PATH, p_dir); \
    if not os.path.exists(source_dir): sys.exit(f'FATAL: Bundle missing files for {p_dir}.'); \
    \
    shutil.copytree(source_dir, LIBS_DIR); \
    shutil.rmtree(TEMP_EXTRACT_PATH);"
    
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ERROR: Failed to set up libraries.
        DEL "%BUNDLE_FILENAME%" 2>NUL
        EXIT /B 1
    )
    DEL "%BUNDLE_FILENAME%" 2>NUL
    ECHO --- Setup complete! ---
    EXIT /B 0