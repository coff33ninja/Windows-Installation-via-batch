@echo off
setlocal

cls
:SelfAdminTest
ECHO.
ECHO =============================
ECHO Running Admin shell
ECHO =============================

:init
setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion

:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
ECHO.
ECHO **************************************
ECHO Invoking UAC for Privilege Escalation
ECHO **************************************

ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
ECHO args = "ELEV " >> "%vbsGetPrivileges%"
ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
ECHO Next >> "%vbsGetPrivileges%"
ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
setlocal & pushd .
cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

:INIT
CLS
ECHO Prepare Hard Disk for Windows Deployment
ECHO -----------------------------------------
ECHO.

ECHO List disk > list.txt
diskpart /s list.txt
pause
REM Close the file before deleting it
type nul > list.txt
DEL list.txt

ECHO.
SET /p disk="Which disk number would you like to prepare? (e.g. 0): "
IF [%disk%] == [] GOTO INIT
ECHO.

ECHO --WARNING-- This will FORMAT the selected disk and ERASE ALL DATA
ECHO.
ECHO You selected disk ---^> %disk%
ECHO.

CHOICE /C YN /M "Is this correct? [Y/N]"
IF %ERRORLEVEL% == 2 GOTO INIT
IF %ERRORLEVEL% == 1 GOTO Disktype_selector

CLS
ECHO Preperation Aborted, No changes have been made...
ECHO.
PAUSE


:Disktype_selector
echo.
echo DO you want to install Windows in a MBR or a GPT enviroment for %disk% drive?
echo.
echo 1. GPT
echo 2. MBR
choice /C:12 /n /m "Choose your enviroment to install Windows"

IF %ERRORLEVEL% == 2 goto:INITMBR
IF %ERRORLEVEL% == 1 goto:INITGPT

:INITMBR
set /p disk=Enter disk number:

SET "b="
FOR %%b IN (Q P O N M L K J I) DO (
IF NOT EXIST "%%b:" SET BOOTDRV=%%b
)
SET "c="
FOR %%c IN (Z Y X W V U T S R) DO (
IF NOT EXIST "%%c:" SET DATADRV=%%c
)

set /p secondary=Do you want a secondary partition? (Y/N)

ECHO Selecting disk %disk%...
ECHO Cleaning...
ECHO Converting to MBR...
ECHO Creating primary partition...
ECHO Formatting primary partition as NTFS...
ECHO Assigning letter %BOOTDRV%...

ECHO select disk %disk% > initmbr.txt
ECHO clean >> initmbr.txt
ECHO convert mbr >> initmbr.txt
ECHO cre pri >> initmbr.txt
ECHO format quick fs=ntfs label="Windows" >> initmbr.txt
ECHO assign letter %BOOTDRV% >> initmbr.txt

if /i "%secondary%"=="Y" (
    ECHO Creating extended partition...
    ECHO Creating logical partition...
    ECHO Formatting logical partition as NTFS...
    ECHO Assigning letter %DATADRV%...

    ECHO cre ext >> initmbr.txt
    ECHO cre log >> initmbr.txt
    ECHO format quick fs=ntfs label="Data" >> initmbr.txt
    ECHO assign letter %DATADRV% >> initmbr.txt
) else (
    ECHO No secondary partition will be created.
)

pause && goto RUNMBR

:RUNMBR
CLS
diskpart /s initmbr.txt
DEL initmbr.txt >nul
ECHO.
ECHO This drive is now prepared for Installing Windows
ECHO.
ECHO The following drive letters have been assigned, and
ECHO will be automatically loaded into the next step
ECHO.
ECHO Boot Drive----------: %BOOTDRV%
ECHO Installation Drive--: %DATADRV%
ECHO.
PAUSE && goto Windows_Instalation

:INITGPT
SET "b="
FOR %%b IN (Q P O N M L K J I) DO (
IF NOT EXIST "%%b:" SET BOOTDRV=%%b
)
SET "c="
FOR %%c IN (Z Y X W V U T S R) DO (
IF NOT EXIST "%%c:" SET DATADRV=%%c
)

ECHO Selecting disk %disk%...
ECHO Cleaning...
ECHO Converting to GPT...
ECHO Creating EFI partition...
ECHO Formatting EFI partition as FAT32...
ECHO Assigning letter %BOOTDRV%...
ECHO Creating MSR partition...
ECHO Creating primary partition...
ECHO Shrinking partition to minimum size...
ECHO Formatting primary partition as NTFS...
ECHO Assigning letter %DATADRV%...
ECHO Creating primary partition...
ECHO Formatting primary partition as NTFS...
ECHO Setting partition ID...

ECHO select disk %disk% >> initgpt.txt
ECHO clean >> initgpt.txt
ECHO convert gpt >> initgpt.txt
ECHO cre par efi size=100 >> initgpt.txt
ECHO format quick fs=fat32 label="System" >> initgpt.txt
ECHO assign letter %BOOTDRV% >> initgpt.txt
ECHO cre par msr size=16 >> initgpt.txt
ECHO cre par pri >> initgpt.txt
ECHO shrink minimum=450 >> initgpt.txt
ECHO format quick fs=ntfs label="Windows" >> initgpt.txt
ECHO assign letter %DATADRV% >> initgpt.txt
ECHO cre par pri >> initgpt.txt
ECHO format quick fs=ntfs label="WinRE" >> initgpt.txt
ECHO set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac" >> initgpt.txt

:RUNGPT
CLS
diskpart /s initgpt.txt
DEL initgpt.txt >nul
ECHO.
ECHO This drive is now prepared for Installing Windows
ECHO.
ECHO The following drive letters have been assigned, and
ECHO will be automatically loaded into the next step
ECHO.
ECHO Boot Drive----------: %BOOTDRV%
ECHO Installation Drive--: %DATADRV%
ECHO.
PAUSE && goto Windows_Instalation


:Windows_Instalation
setlocal EnableDelayedExpansion
@echo off
ECHO.
@echo off
echo Please wait while the Windows installation process starts...

rem SETUP VARIABLES
set WIM_FILE=%~dp0install.wim

rem CHECK IF INSTALL.WIM FILE IS PRESENT
if not exist "%WIM_FILE%" (
    echo install.wim file not found in the current directory.
    set /p WIM_FILE="Do you want to use the file open dialog to locate the file (y/n)? "
    if /i "%WIM_FILE%"=="y" (
        start "" "%SystemRoot%\explorer.exe" /select,"%WIM_FILE%"
        set /p WIM_FILE="Enter the path to the file: "
    )
)

rem CHECK IF INSTALL.ESD FILE IS PRESENT
if not exist "%WIM_FILE%" (
    set WIM_FILE=%~dp0install.esd
    if not exist "%WIM_FILE%" (
        echo install.esd file not found in the current directory.
        set /p WIM_FILE="Do you want to use the file open dialog to locate the file (y/n)? "
        if /i "%WIM_FILE%"=="y" (
            start "" "%SystemRoot%\explorer.exe" /select,"%WIM_FILE%"
            set /p WIM_FILE="Enter the path to the file: "
        )
    )
)

rem DISPLAY AVAILABLE WIM INDEXES
set "ps_command=powershell.exe -Command ""& {dism /Get-ImageInfo /ImageFile:'%WIM_FILE%' | findstr /R /C:""[0-9]"" /C:""[A-Za-z]""}"""
for /f "usebackq delims=" %%i in (`%ps_command%`) do set "indexes=%%i"
echo Available image indexes:
echo %indexes%
set /p WIM_INDEX=Enter the index number of the desired image:

rem DEPLOY THE WIM IMAGE
dism /Apply-Image /ImageFile:%WIM_FILE% /Index:%WIM_INDEX% /ApplyDir:%BOOTDRV%:\ /CheckIntegrity

echo Deployment complete!

pause

REM Create a boot entry for the installed Windows on the boot drive
%DATADRV%\Windows\System32\bcdboot %DATADRV%\Windows /s %BOOTDRV%

REM Create necessary folders and copy the answer file to Panther folder

ECHO Welcome to the final part of the Windows Installation Script!

SET /P COMPUTER_NAME=Enter the desired computer name: 
SET /P TIME_ZONE=Enter the time zone (in standard format, e.g. "Pacific Standard Time"): 
SET /P LOCALE=Enter the locale (in standard format, e.g. "en-US"): 
SET /P USERNAME=Enter the desired username: 
SET /P PASSWORD=Enter the desired password: 

ECHO Modifying unattended.xml file...
powershell -Command "(Get-Content unattended.xml) | ForEach-Object { $_ -replace 'COMPUTER_NAME', '%COMPUTER_NAME%' } | Set-Content unattended.xml"
powershell -Command "(Get-Content unattended.xml) | ForEach-Object { $_ -replace 'TIME_ZONE', '%TIME_ZONE%' } | Set-Content unattended.xml"
powershell -Command "(Get-Content unattended.xml) | ForEach-Object { $_ -replace 'LOCALE', '%LOCALE%' } | Set-Content unattended.xml"
powershell -Command "(Get-Content unattended.xml) | ForEach-Object { $_ -replace 'USERNAME', '%USERNAME%' } | Set-Content unattended.xml"
powershell -Command "(Get-Content unattended.xml) | ForEach-Object { $_ -replace 'PASSWORD', '%PASSWORD%' } | Set-Content unattended.xml"

ECHO.
ECHO The unattended.xml file has been successfully modified.

MD %DATADRV%\Windows\Panther
COPY X:\Scripts\unattend.xml %DATADRV%\Windows\Panther\

:WINRE_PARTITION
CLS
ECHO Creating WinRE partition and setting recovery image location...
ECHO.
MD %DATADRV%\Recovery\WinRE
XCOPY /h %DATADRV%\Windows\System32\Recovery\Winre.wim %DATADRV%\Recovery\WinRE\
%DATADRV%\Windows\System32\Reagentc /Setreimage /Path %DATADRV%\Recovery\WinRE /Target %DATADRV%\Windows

ECHO.
ECHO WinRE partition created and recovery image location set successfully.
ECHO.
PAUSE

ECHO.
ECHO Computer will restart to OOBE in a few seconds...
%DATADRV%\Windows\System32\shutdown -r -t 5
