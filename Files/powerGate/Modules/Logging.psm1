﻿# WIKI
# https://github.com/PowershellFrameworkCollective/psframework


function Set-LogFilePath {
    param($Path)
    Write-Host "Start to change logging file to: $Path"
    Initialize-CoolOrangeLogging -LogPath $Path
    Write-Host "Set new logging file: $Path"
}

function Initialize-CoolOrangeLogging {
    param(
        $LogPath,
        $DeleteLogFilesOlderThenDays = '4d' # Format example for 30 days: "30d"
    )
    $paramSetPSFLoggingProvider = @{
    
        # For all parameters of the "Logfile" provider read here: https://psframework.org/documentation/documents/psframework/logging/providers/logfile.html
        Name             = 'logfile'
        Enabled          = $true
    
        InstanceName     = 'MyTask'
        FilePath         = $logPath
        LogRotatePath    = $logPath

        #FilePath         = "$logPath\Test-%Date%.log"
        #LogRotatePath    = "$logPath\Test-*.log"
    
        # XML, CSV, Json, Html, CMTrace
        # For CMTrace - Download Microsoft CM Viewer: https://www.microsoft.com/en-us/download/confirmation.aspx?id=50012
        FileType         = 'Json'
        JsonCompress     = $false
        JsonString       = $true
        JsonNoComma      = $false
    
        #Headers         = 'ComputerName', 'File', 'FunctionName', 'Level', 'Line', 'Message', 'ModuleName', 'Runspace', 'Tags', 'TargetObject', 'Timestamp', 'Type', 'Username', 'Data'
        Headers          = 'Timestamp', 'Level', 'Message', 'Data', 'FunctionName', 'Line', 'ModuleName', 'Username', 'ComputerName', 'File'
        TimeFormat       = 'yyyy-MM-dd HH:mm:ss.fff'
    
        LogRetentionTime = $deleteLogFilesOlderThenDays
        LogRotateRecurse = $true
    }
    
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider
    Set-LoggingAliases
    Write-Host -Message "Initialized logging to file: $($logPath)"
}

function Set-LoggingAliases {
    Set-Alias Write-Host Write-PSFMessageProxy -Scope Global
    Set-Alias Write-Warning Write-PSFMessageProxy -Scope Global
    Set-Alias Write-Error Write-PSFMessageProxy -Scope Global
    Set-Alias Write-Verbose Write-PSFMessageProxy -Scope Global
}

function Log {
    param(
        [Parameter(ValueFromPipeline = $True, Position = 1)]
        $Message,
        [switch]$Begin,
        [switch]$End        
    )
    [string[]]$log = @()

    $callStack = Get-PSCallStack

    if ($Begin) {
        if ($callStack -and $callStack.count -gt 1) {
            $log += ">> {0} >>" -f $callStack[1].Command 
            $log += "Parameters: {0} " -f $callStack[1].Arguments
        }
    }

    if ($End) { 
        if ($callStack -and $callStack.count -gt 1) {
            $log += "<< {0} <<" -f $callStack[1].Command 
        }
    }

    if ($Message) {
        $log += $Message
    }
    
    Write-Host $log
}

# PSFramework Version 1.5.172
$commonModulePath = "C:\ProgramData\coolOrange\powerGate\Modules\PSFramework"

$modules = Get-ChildItem -path $commonModulePath -Recurse -Filter *.ps*
$modules | ForEach-Object { Import-Module -Name $_.FullName -Global }

$generalLogPath = Join-Path $env:LOCALAPPDATA "coolOrange\Projects\coolOrange.log"
Initialize-CoolOrangeLogging -LogPath $generalLogPath