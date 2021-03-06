<#
 
    .SYNOPSIS
    Removes accounts excluded from Adaxes management.
 
    .DESCRIPTION
    Removes speficified users the the list of account excluded from Adaxes
    management. 
    You can perform a batch removal by specifing a security group or an 
    organizational unit either recursively or not.

    .PARAMETER User
    A single user to remove.

    .PARAMETER Group
    A security group whose members should be removed form Adaxes exclusion.

    .PARAMETER Recursive
    When 'Group' parameter is used, specifies whether to process
    nested groups' members. By default is false.

    .PARAMETER OrganizationalUnit
    An organizational unit members of which should be removed form 
    Adaxes exclusion.

    .PARAMETER Subtree
    When 'OrganizationalUnit' parameter is used, specifies whether 
    to process subtree objects. By default only OU children are 
    processed.

    .PARAMETER AdaxesService
    Specifies the Adaxes services instance to connect to.

    .EXAMPLE
    Remove-AdmUnmanagedAccount.ps1 -User cavejonson@aperture.com
    Remove-AdmUnmanagedAccount.ps1 -Group Summer-Externs -Recursive
    Remove-AdmUnmanagedAccount.ps1 -OrganizationalUnit MassDyn -Subtree
  
#>

[CmdletBinding(DefaultParameterSetName='User')]
param
(
    [Parameter(Mandatory=$true, ParameterSetName='User')]
    $User,
    
    [Parameter(Mandatory=$true, ParameterSetName='Group')]
    $Group,

    [Parameter(Mandatory=$false, ParameterSetName='Group')]
    [Switch]
    $Recursive,
    
    [Parameter(Mandatory=$true, ParameterSetName='OU')]
    [Alias('ou')]
    $OrganizationalUnit,

    [Parameter(Mandatory=$false, ParameterSetName='OU')]
    [Switch]
    $Subtree,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName='Pipeline')]
    $InputObject,

    [Parameter(Mandatory=$false)]
    $AdaxesService = 'localhost'
)

begin
{
    Import-Module ActiveDirectory

    [Reflection.Assembly]::LoadWithPartialName('Softerra.Adaxes.Adsi')

    $ns = New-Object 'Softerra.Adaxes.Adsi.AdmNamespace'
    $adaxes = $ns.GetServiceDirectly($AdaxesService)

    $path = $adaxes.Backend.GetConfigurationContainerPath('ConfigurationSetSettings')
    $settings = $adaxes.OpenObject($path, $null, $null, 0)

    $global:sids = $settings.GetUnmanagedAccounts(@()) | % { $a = @{} }{ $a[$_.Key] = $null }{ $a }
    
    function Process-SingleIdentity($Object)
    {
        if ($Object -isnot [Softerra.Adaxes.PowerShellModule.Directory.ADUser] -and 
            $Object -isnot [Microsoft.ActiveDirectory.Management.ADUser] -and
            $Object -isnot [Microsoft.ActiveDirectory.Management.ADPrincipal])
        {
            $Object = Get-AdUser -Identity $Object
        }

        $global:sids.Remove($Object.SID.ToString())
    }
}
process
{
    if ($User)
    {
        Write-Verbose "User: $User"
        Process-SingleIdentity $User
    }
    elseif($Group)
    {
        Write-Verbose "Group: $Group, Recursive: $Recursive"
        Get-ADGroupMember -Identity $Group -Recursive:$Recursive | % { Process-SingleIdentity $_ }
    } 
    elseif($OrganizationalUnit)
    {
        Write-Verbose "OU: $OrganizationalUnit, Subtree: $Subtree"

        if ($OrganizationalUnit -isnot [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -and 
            $OrganizationalUnit -isnot [Softerra.Adaxes.PowerShellModule.Directory.ADOrganizationalUnit])
        {
            $OrganizationalUnit = Get-ADOrganizationalUnit -Identity $OrganizationalUnit
        }        

        if ($Subtree) 
        {
            $scope = 'Subtree'
        }
        else
        {
            $scope = 'OneLevel' 
        }
        
        Get-AdUser -LdapFilter '(&(objectCategory=Person)(objectClass=User))' -SearchBase $OrganizationalUnit.DistinguishedName -SearchScope $scope | % { Process-SingleIdentity $_ }
    }
    elseif($InputObject)
    {
        Write-Verbose "InputObject: $InputObject"
        Process-SingleIdentity $InputObject
    }
}
end
{
    $global:sids = $global:sids.GetEnumerator() | % { $_.Key }
    Write-Verbose "$global:sids"
    $settings.SetUnmanagedAccounts($global:sids)
}
