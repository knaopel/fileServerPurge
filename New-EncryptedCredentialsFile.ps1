param(
    # Parameter help description
    [Parameter(Mandatory = $false)]
    [string]
    $Username
)

$cred = Get-Credential -UserName $Username -Message "Please enter credentials..."

$cred | Export-Clixml "encrypted-credentials.xml"