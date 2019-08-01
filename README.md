## Usage:
```
Format (simple):
    create_service_wrap.cmd <service_name> [/powerhsell] [/vbs] <program_or_script> [<argument1>] [<argumentN>]
Format (full):
    create_service_wrap.cmd <service_name> [/start <start_type>] [/type <service_type>]
            [/displayName <display_name>] [/description <description>]
            [/folder <working_folder>] [/exit-handle <type>]
            [/powerhsell|/ps] [/vbscript|/vbs] <program_or_script> [<argument1>] [<argumentN>]
Where:
    <start_type> is service start type (boot|system|auto|demand|disabled|delayed-auto) (default: demand)
    <service_type> is service type (own|share|interact|kernel|filesys|rec) (default: own)
    <display_name> is service 'Display Name'
    <description> is service description
    <working_folder> is 'current directory' for service
    <exit-handle> is application exit handle type (restart|ignore|exit) (default: exit)
    [/powerhsell] tells that <program_or_script> is PowerShell script
    [/vbs] tells that <program_or_script> is VB script
```
## Examples:
Running windows calculator as a service (on demand start):
```
        create_service_wrap.cmd MyServiceExe C:\Windows\system32\calc.exe
        net start MyServiceExe
```
Running windows CMD-script as a service (+ auto start on windows boot; + custom folder):
```
        create_service_wrap.cmd MyServiceCMD /start auto /folder "C:\Users\Public" "C:\Test\1.cmd" arg1 "arg 2"
```
Running VBS-script as a service (+ auto-restart on fail):
```
        create_service_wrap.cmd MyServiceVBS /exit-handle restart /vbs "J:\Users\me\Documents\1.vbs" arg1 "arg 2"
```
Running Powershell-script as a service (+ custom service display name):
```
        create_service_wrap.cmd MyServicePS /displayName "Powershell Test" /PS "C:\test1.ps1" "scirpt arg"
```
