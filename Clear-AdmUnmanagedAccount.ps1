<#
 
    .SYNOPSIS
    Clears accounts excluded from Adaxes management.
 
    .DESCRIPTION
    Removes all users the the list of account excluded from Adaxes
    management. 

    .PARAMETER AdaxesService
    Specifies the Adaxes services instance to connect to.

    .EXAMPLE
    Clear-AdmUnmanagedAccount.ps1
    Clear-AdmUnmanagedAccount.ps1 -AdaxesService 'adx.local.lab'
  
#>

param
(
    [Parameter(Mandatory=$false)]
    $AdaxesService = 'localhost'
)

$ns = New-Object 'Softerra.Adaxes.Adsi.AdmNamespace'
$adaxes = $ns.GetServiceDirectly($AdaxesService)

$path = $adaxes.Backend.GetConfigurationContainerPath('ConfigurationSetSettings')
$settings = $adaxes.OpenObject($path, $null, $null, 0)

$settings.SetUnmanagedAccounts(@())

