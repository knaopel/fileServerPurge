param(
    [Parameter(Mandatory = $true)]
    [string]
    $Path,
    [Parameter(Mandatory = $true)]
    [string]
    $EmailRecipient
)

###  script variables ### 
$logName = "PowerShell Purge Files"
$mailTemplate = @"
<html>
    <head>
        <style>
            body {{
                font-family: Calibri, Helvetica, Sans-Serif;
            }}
            h1, h2, h3, h4, h5, h6 {{
                font-family: Cambria, Serif;
            }}
        </style>
    </head>
    <body>
        <h1>Message From PowerShell to Purge Datashare</h1>
        <div>{0}</div>
    </body>
</html>
"@

$errors = [string[]]@()

function Test-EventLogSource {
    param(
        # the name of the source on which to test
        [Parameter(Mandatory = $true)]
        [string]
        $SourceName
    )

    try {
        if (-not ([System.Diagnostics.EventLog]::SourceExists($SourceName))) {
            return $false
        }
        return $true
    } catch [System.Security.SecurityException] {
        return $false
    }
}

function Write-OCEventLog {
    param(
        # Parameter help description
        [Parameter(Mandatory = $false)]
        [string]
        $LogSourceName = "OC-Powershell",
        [Parameter(Mandatory = $false)]
        [int]
        $Category = 0,
        [Parameter(Mandatory = $false)]
        [int]
        $EventId = 1,
        [Parameter(Mandatory = $false)]
        [string]
        $EntryType = "Information",    
        [Parameter(Mandatory = $true)]
        [string]
        $Message    
    )

    if (-not (Test-EventLogSource -SourceName $LogSourceName)) {
        New-EventLog -LogName Application -Source $LogSourceName
    }

    Write-EventLog -LogName Application -Source $LogSourceName -EntryType $EntryType -Category $Category -EventId $EventId -Message $Message
}

function Send-OCMailMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ToEmail,
        [Parameter(Mandatory = $true)]
        [string]
        $Subject,
        [Parameter(Mandatory = $true)]
        [string]
        $Message
    )
    try {
        $from = "do-not-reply@oakgov.com"
        $svr = "smtp.oakgov.com"
        $body = $mailTemplate -f $Message
        Send-MailMessage -To $ToEmail -From $from -Subject $Subject -Body $body -BodyAsHtml -SmtpServer $svr
    }
    catch {
        Write-OCEventLog -LogSourceName $logName -EventId 2 -EntryType Error -Message "Cannot send email."
    }

}

function Clear-FileServerDirectory {
    param(
        # The path which to clear
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [string]
        $Path#,
        # [Parameter(Mandatory = $true)]
        # [string[]]
        # $ErrorArray
    )

    $msg = $null
    
    Write-OCEventLog -LogSourceName $logName -EventId 101 -Message "Preparing to remove files from $Path."
    
    try {
        $ErrorActionPreference = "Stop"
        Remove-Item -Path "$Path\*" -Recurse -Force
        # throw New-Object -TypeName System.Exception
        Write-OCEventLog -LogSourceName $logName -EventId 102 -Message "All files and folders removed from $Path."        
    }
    # catch [System.IOException] {
    #     $ErrorMessage = $_.Exception.Message
    #     $FailedItem = $_.Exception.ItemName
    #     $Message = "Delete content in $Path failed on $FailedItem. The error message was $ErrorMEssage."
    #     $errors += $Message
    #     Write-OCEventLog -LogSourceName $logName -EventId 201 -EntryType Error -Message $Message        
    # }
    catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $Message = "Delete content in $Path failed on `"$FailedItem`". The error message was `"$ErrorMessage`"."
        $msg = $Message
        Write-OCEventLog -LogSourceName $logName -EventId 201 -EntryType Error -Message $Message
    } finally {
        $ErrorActionPreference = "Continue" 
    }
    return $msg   
}

Write-OCEventLog -LogSourceName $logName -Message "Starting periodic purge of files from $Path"

Get-ChildItem -Path $Path -Directory | ForEach-Object {
    $msg = $_.FullName | Clear-FileServerDirectory
    if ($msg -ne $null) {
        $errors += $msg
    }
}

if ($errors.Length -gt 0) {
    $errMsg = "<ul>"
    $errors | ForEach-Object {
        $errMsg += "<li>$_</li>"
    }
    $errMsg += "</ul>"
    Send-OCMailMessage -ToEmail $EmailRecipient -Subject "Errors occured in periodic purge of datashare at $Path" -Message "<p>The following errors occured in periodic purge of datashare at $($Path):</p>$errMsg"
    Write-OCEventLog -LogSourceName $logName -Message "Periodic purge of files from $Path completed with some errors." -EntryType Warning
}
else {
    Write-OCEventLog -LogSourceName $logName -Message "Periodic purge of files from $Path complete."
}
