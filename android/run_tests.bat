@echo off

echo Cleaning previous test results...
call ./gradlew --quiet :app:cleanTestDebugUnitTest --console=plain

echo.
echo Running unit tests and capturing output...
rem Capture all output to temp file
call ./gradlew --quiet :app:testDebugUnitTest --console=plain --stacktrace > test_output.log 2>&1
set "gradleExit=%ERRORLEVEL%"

echo.
echo Filtered test output:
rem Show only failures, errors, and summary
type test_output.log || echo No failures detected.

echo.

echo Test reports available at:
echo %CD%\..\build\app\reports\tests\testDebugUnitTest\index.html

echo.
echo Press any key to open the report in the browser...
pause > nul
start "" "..\build\app\reports\tests\testDebugUnitTest\index.html" 