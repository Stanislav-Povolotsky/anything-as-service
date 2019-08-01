::.SYNOPSIS 
::    This script helps to create windows service wrapper for usual applications/scripts.
::.DESCRIPTION 
::    This script helps to create windows service wrapper for exe/cmd/ps1/vbs applications, which does
::    not support to run as windows service
::.NOTES 
::    File Name:    create_service_wrap.cmd
::    Author:       Stanislav Povolotsky <stas.dev[at]povolotsky.info>
::    Depends:      srvany.exe (from 'Windows Server 2003 Resource Kit Tools')
::.EXAMPLE  
::    create_service_wrap.cmd MyServiceExe %windir%\system32\calc.exe
::    create_service_wrap.cmd MyServicePS /start auto /powershell C:\1.ps1
::.LINK 
::    https://github.com/Stanislav-Povolotsky/anything-as-service/srvany(old)/
@echo off
goto run

:show_format
echo Format (simple):
echo 	create_service_wrap.cmd ^<service_name^> [/powerhsell] [/vbs] ^<program_or_script^> [^<argument1^>] [^<argumentN^>]
echo Format (full):
echo 	create_service_wrap.cmd ^<service_name^> [/start ^<start_type^>] [/type ^<service_type^>] 
echo 		[/displayName ^<display_name^>] [/description ^<description^>]
echo 		[/folder ^<working_folder^>] 
echo 		[/powerhsell^|/ps] [/vbscript^|/vbs] ^<program_or_script^> [^<argument1^>] [^<argumentN^>]
echo Where:   
echo 	^<start_type^> is service start type (boot^|system^|auto^|demand^|disabled^|delayed-auto) (default: demand)
echo 	^<service_type^> is service type (own^|share^|interact^|kernel^|filesys^|rec) (default = own)
echo 	^<display_name^> is service 'Display Name'
echo 	^<description^> is service description
echo 	^<working_folder^> is 'current directory' for service
echo 	[/powerhsell] tells that ^<program_or_script^> is PowerShell script
echo 	[/vbs] tells that ^<program_or_script^> is VB script
echo Examples:
echo 	create_service_wrap.cmd MyServiceExe %windir%\system32\calc.exe
echo 	create_service_wrap.cmd MyServiceCMD /start auto /folder "%public%" "C:\Test\1.cmd" arg1 "arg 2" 
echo 	create_service_wrap.cmd MyServiceVBS /vbs "%userprofile%\Documents\1.vbs" arg1 "arg 2" 
echo 	create_service_wrap.cmd MyServicePS /PS "C:\Users\Stanislav Povolotsky\Documents\test1.ps1" ps_argument1 "ps_argument 2"
echo 	create_service_wrap.cmd MyServicePS /displayName "Powershell Test" /start auto /powershell "C:\1.ps1"
exit /b 1

:run
if /I ["%~1"] == ["/?"] goto show_format
if /I ["%~1"] == ["/help"] goto show_format
if /I ["%~1"] == ["--help"] goto show_format

set script_type=
set svc_description=^^^<empty^^^>
set opt_deploy_srvany_to_system32=1

set service_name=%~1
shift

:arg_process_loop

if /I ["%~1"] == ["/powershell"] (
 set script_type=powershell
 shift
 goto arg_process_loop
)
if /I ["%~1"] == ["/PS"] (
 set script_type=powershell
 shift
 goto arg_process_loop
)
if /I ["%~1"] == ["/vbscript"] (
 set script_type=vbscript
 shift
 goto arg_process_loop
)
if /I ["%~1"] == ["/vbs"] (
 set script_type=vbscript
 shift
 goto arg_process_loop
)

rem type= <own|share|interact|kernel|filesys|rec>
rem       (default = own)
if /I ["%~1"] == ["/Type"] (
 set sc_args=%sc_args% type= "%~2"
 shift
 shift
 goto arg_process_loop
)
rem start= <boot|system|auto|demand|disabled|delayed-auto>
rem       (default = demand)
if /I ["%~1"] == ["/start"] (
 set sc_args=%sc_args% start= "%~2"
 shift
 shift
 goto arg_process_loop
)
rem DisplayName= <display name>
if /I ["%~1"] == ["/DisplayName"] (
 set sc_args=%sc_args% DisplayName= "%~2"
 shift
 shift
 goto arg_process_loop
)
rem error= <normal|severe|critical|ignore>
rem       (default = normal)
if /I ["%~1"] == ["/error"] (
 set sc_args=%sc_args% error= "%~2"
 shift
 shift
 goto arg_process_loop
)
rem depend= <Dependencies(separated by / (forward slash))>
if /I ["%~1"] == ["/depend"] (
 set sc_args=%sc_args% depend= "%~2"
 shift
 shift
 goto arg_process_loop
)
rem obj= <AccountName|ObjectName>
rem       (default = LocalSystem)
if /I ["%~1"] == ["/obj"] (
 set sc_args=%sc_args% obj= "%~2"
 shift
 shift
 goto arg_process_loop
)
rem password= <password>
if /I ["%~1"] == ["/password"] (
 set sc_args=%sc_args% password= "%~2"
 shift
 shift
 goto arg_process_loop
)
if /I ["%~1"] == ["/Description"] (
 set svc_description=%~2
 shift
 shift
 goto arg_process_loop
)
if /I ["%~1"] == ["/folder"] (
 set working_folder=%2
 set working_folder_found=1
 shift
 shift
 goto arg_process_loop
)

set program=%~1
if [%script_type%] == [powershell] (
 set script_path=%program%
 set program=%windir%\System32\WindowsPowerShell\v1.0\powershell.exe
)
if [%script_type%] == [vbscript] (
 set script_path=%program%
 set program=%windir%\system32\wscript.exe
)
shift

if ["%service_name%"] == [""] goto show_format
if ["%program%"] == [""] goto show_format

set escape="""

set arguments=
:add_argument
if ["%~1"] == [""] goto no_more_arguments
set arguments=%arguments% %escape%%~1%escape%
shift
goto add_argument
:no_more_arguments

set def_svc_description=Application %program%

if [%script_type%] == [powershell] (
 set arguments=-NonInteractive -NoProfile -ExecutionPolicy ByPass -File %escape%%script_path%%escape% %arguments%
 set def_svc_description=Powershell script %script_path%
)
if [%script_type%] == [vbscript] (
 set arguments=%escape%%script_path%%escape% %arguments%
 set def_svc_description=VB script %script_path%
)

if not ["%script_path%"] == [""] (
  if not exist "%script_path%" (
    echo Warning: script "%script_path%" does not exists
  )
)

if /I ["%svc_description%"] == ["^<empty^>"] set svc_description=%def_svc_description%

set srvany=%~dp0srvany.exe
if exist "%windir%\System32\srvany.exe" set srvany="%windir%\System32\srvany.exe"

if not exist "%srvany%" (
 echo Error: required file "srvany.exe" was not found. 
 echo You should download and place "srvany.exe" in %windir%\System32\ folder or
 echo in the same folder as create_service_wrap.cmd file.
 echo You can take "srvany.exe" from 'Windows Server 2003 Resource Kit Tools' 
 echo https://www.microsoft.com/en-us/download/details.aspx?id=17657
 echo Please check 'srvany.exe' file hash:
 echo 	MD5:  4635935fc972c582632bf45c26bfcb0e
 echo 	SHA1: 7c5329229042535fe56e74f1f246c6da8cea3be8
 exit /b 1
)

if [%opt_deploy_srvany_to_system32%] == [1] (
  if not exist "%windir%\System32\srvany.exe" (
    echo Deploying %srvany% to %windir%\System32\
    copy /Y "%srvany%" %windir%\System32\
    if errorlevel 1 exit /b
  )
  set srvany=%windir%\System32\srvany.exe
)

if not exist "%program%" (
  echo Warning: application "%program%" does not exists
)

sc stop "%service_name%" >nul 2>nul
sc delete "%service_name%" >nul 2>nul
echo Creating service "%service_name%"
sc create "%service_name%" BinPath= "%srvany%" %sc_args%
if errorlevel 1 exit /b
sc description "%service_name%" "%svc_description%" >nul 2>nul

echo Setting service arguments (Application: %program%)
set param_path=HKLM\SYSTEM\CurrentControlSet\Services\%service_name%\Parameters
reg add "%param_path%" /f /v "Application" /t REG_SZ /d "%program%"
if errorlevel 1 exit /b
echo Setting service arguments (Arguments: %arguments%)
reg add "%param_path%" /f /v "AppParameters" /t REG_SZ /d "%arguments%"
if errorlevel 1 exit /b
if [%working_folder_found%] == [1] (
  echo Setting service directory ^(%working_folder%^)
  reg add "%param_path%" /f /v "AppDirectory" /t REG_SZ /d %working_folder%
  if errorlevel 1 exit /b
)

exit /b

