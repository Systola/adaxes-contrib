<#
 
    .SYNOPSIS
    Gets users excluded from Adaxes management.
 
    .DESCRIPTION
    Gets unmanaged users accounts and their properties.
 
    .PARAMETER Properties
    Provide a list of properties to query from an excluded account.
  
    .PARAMETER AsMicrosoft
    Return an account as [Microsoft.ActiveDirectory.Management.ADUser] object.

    .PARAMETER AdaxesService
    Specifies the Adaxes services instance to connect to.

    .EXAMPLE
    Get-AdmUnmanagedAccount.ps1 -Properties name,mail,phoneNumber
    Get-AdmUnmanagedAccount.ps1 -AsMicrosoft
    Get-AdmUnmanagedAccount.ps1 -AdaxesService 'adaxes.example.net'
  
#>

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$false)]
    [String[]]
    $Properties = @('objectClass'),

    [Parameter(Mandatory=$false)]
    [Switch]
    $AsMicrosoft,

    [Parameter(Mandatory=$false)]
    $AdaxesService = 'localhost'
)

Import-Module ActiveDirectory, Adaxes

$ns = New-Object 'Softerra.Adaxes.Adsi.AdmNamespace'
$adaxes = $ns.GetServiceDirectly($AdaxesService)

$path = $adaxes.Backend.GetConfigurationContainerPath('ConfigurationSetSettings')
$settings = $adaxes.OpenObject($path, $null, $null, 0)

$accounts = $settings.GetUnmanagedAccounts(@())

if($AsMicrosoft)
{
    $accounts | % { Get-AdmUser -Identity $_.Key -Properties $Properties }
}
else
{
    $accounts | % { Get-AdUser -Identity $_.Key -Properties $Properties }
}
