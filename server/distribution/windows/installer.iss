#define MyAppName "Open Integration Engine"
#define MyAppVersion "4.7.0"
#define MyAppPublisher "Open Integration Engine Project"
#define MyAppURL "https://openintegrationengine.org"
#define MyAppExeName "oieservice.exe"

#ifndef OutputBaseFilename
  #define OutputBaseFilename "oie_windows-x64_4.7.0-with-JRE"
#endif
#ifndef IncludeJre
  #define IncludeJre "true"
#endif
#ifndef ArchMode
  #define ArchMode "x64compatible"
#endif

[Setup]
AppId={{4145-9206-7630-8076}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer
OutputBaseFilename={#OutputBaseFilename}
Compression=lzma2/max
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode={#ArchMode}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[CustomMessages]
english.DeleteDataPrompt=Do you also want to remove local data, certificates, and configuration files?
spanish.DeleteDataPrompt=¿Desea eliminar también los datos locales, certificados y registros de configuración?
english.DeleteDataCheckbox=Delete all data, certificates, and configuration files (clean uninstall)
spanish.DeleteDataCheckbox=Eliminar todos los datos locales, certificados y archivos de configuración (desinstalación limpia)

[Files]
; 1. Compress JRE folder tree
#if IncludeJre == "true"
Source: "jre\*"; DestDir: "{app}\jre"; Flags: ignoreversion recursesubdirs createallsubdirs
#endif

; 2. Copy everything except installer and scripts not related to Windows, conf or jre
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "installer.iss,installer\*,conf\*,oieserver,oieserver.ps1,jre\*"

; 3. Copy conf with rule 'No overwrite' to harness previous installations
Source: "conf\*"; DestDir: "{app}\conf"; Flags: onlyifdoesntexist recursesubdirs createallsubdirs

[Dirs]
Name: "{app}\appdata"
Name: "{app}\logs"

[Icons]
#if IncludeJre == "true"
Name: "{group}\{#MyAppName} CLI"; Filename: "{app}\jre\bin\java.exe"; Parameters: "-jar ""{app}\mirth-cli-launcher.jar"""; WorkingDir: "{app}"
#else
Name: "{group}\{#MyAppName} CLI"; Filename: "java.exe"; Parameters: "-jar ""{app}\mirth-cli-launcher.jar"""; WorkingDir: "{app}"
#endif
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
; Install and start service when finishing installation
Filename: "{app}\{#MyAppExeName}"; Parameters: "install"; Flags: runhidden
Filename: "{app}\{#MyAppExeName}"; Parameters: "start"; Flags: runhidden

[UninstallRun]
; 1. Stop service WinSW
Filename: "{app}\{#MyAppExeName}"; Parameters: "stop"; Flags: runhidden
; 2. Force any Java or WinSW process termination that still stores log files. 
Filename: "taskkill.exe"; Parameters: "/F /IM {#MyAppExeName} /T"; Flags: runhidden
Filename: "taskkill.exe"; Parameters: "/F /IM java.exe /T"; Flags: runhidden
Filename: "taskkill.exe"; Parameters: "/F /IM javaw.exe /T"; Flags: runhidden
; 3. Uninstall Windows service
Filename: "{app}\{#MyAppExeName}"; Parameters: "uninstall"; Flags: runhidden

[UninstallDelete]
; Selective deletion checked by Inno Setup
Type: filesandordirs; Name: "{app}\appdata"
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\conf"
Type: filesandordirs; Name: "{app}\jre"
Type: files; Name: "{app}\*.*"
Type: dirifempty; Name: "{app}"