﻿$global:ErrorActionPreference = "Stop"
$commonModulePath = "C:\ProgramData\coolOrange\powerGate\Modules"
$modules = Get-ChildItem -path $commonModulePath -Recurse -Filter *.ps*
$modules | ForEach-Object { Import-Module -Name $_.FullName -Global }

$cfgPath = "c:\temp\powerGateCfg\powerGateConfiguration.xml"
$testPath = Test-Path $cfgPath
if ($testPath -eq $false) {
    ShowMessageBox -Message "No config file found. Please download/edit the config file first and then save it back to the Vault server" -Button  "OK" -Icon "Warning" | Out-Null
    return
}

[xml]$cfg = Get-Content $cfgPath
SetConfigFromVault -Content $cfg.InnerXml
ShowMessageBox -Message "Config file saved to Vault server" -Button "OK" -Icon "Information" | Out-Null

Remove-Item $cfgPath -Force