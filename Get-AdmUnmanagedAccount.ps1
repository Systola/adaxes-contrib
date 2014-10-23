<#
 
    .SYNOPSIS
    Gets users excluded from Adaxes management.
 
    .DESCRIPTION
    Gets unmanaged users accounts and their properties.
 
    .PARAMETER Properties
    Provide a list of properties to query from an excluded account.
 
    .PARAMETER AsAdaxes
    Return an account as [Softerra.Adaxes.PowerShellModule.Directory.ADUser] object.
 
    .PARAMETER AsMicrosoft
    Return an account as [Microsoft.ActiveDirectory.Management.ADUser] object.

    .PARAMETER AdaxesService
    Specifies the Adaxes services instance to connect to.

    .EXAMPLE
    Get-AdmUnmanagedAccount.ps1 -Properties name,email,phoneNumber
    Get-AdmUnmanagedAccount.ps1 -AsMicrosoft
    Get-AdmUnmanagedAccount.ps1 -AdaxesService 'adaxes.example.net'
  
#>

[CmdletBinding(DefaultParameterSetName='None')]
param
(
    [Parameter(Mandatory=$false)]
    [String[]]
    $Properties = @('distinguishedName', 'objectGUID'),

    [Parameter(Mandatory=$false, ParameterSetName='Adaxes')]
    [Switch]
    $AsAdaxes,

    [Parameter(Mandatory=$false, ParameterSetName='Microsoft')]
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

$accounts = $settings.GetUnmanagedAccounts($Properties)

if($AsAdaxes)
{
    $accounts | % { Get-AdmUser -Identity $_.Key -Properties $Properties }
}
elseif($AsMicrosoft)
{
    $accounts | % { Get-AdUser -Identity $_.Key -Properties $Properties }
}
else
{
    $accounts    
}
