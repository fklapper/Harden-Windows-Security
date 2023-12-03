function Get-CommonWDACConfig {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $false)][System.Management.Automation.SwitchParameter]$CertCN,
        [parameter(Mandatory = $false)][System.Management.Automation.SwitchParameter]$CertPath,
        [parameter(Mandatory = $false)][System.Management.Automation.SwitchParameter]$SignToolPath,
        [parameter(Mandatory = $false)][System.Management.Automation.SwitchParameter]$SignedPolicyPath,
        [parameter(Mandatory = $false)][System.Management.Automation.SwitchParameter]$UnsignedPolicyPath,
        [parameter(Mandatory = $false, DontShow = $true)][System.Management.Automation.SwitchParameter]$StrictKernelPolicyGUID, # DontShow prevents common parameters from being displayed too
        [parameter(Mandatory = $false, DontShow = $true)][System.Management.Automation.SwitchParameter]$StrictKernelNoFlightRootsPolicyGUID,
        [parameter(Mandatory = $false)][System.Management.Automation.SwitchParameter]$Open,
        [parameter(Mandatory = $false, DontShow = $true)][System.Management.Automation.SwitchParameter]$LastUpdateCheck
    )
    begin {
        # Importing resources such as functions by dot-sourcing so that they will run in the same scope and their variables will be usable
        . "$psscriptroot\Resources.ps1"

        # Stop operation as soon as there is an error anywhere, unless explicitly specified otherwise
        $ErrorActionPreference = 'Stop'

        # Fetch User account directory path
        [System.String]$global:UserAccountDirectoryPath = (Get-CimInstance Win32_UserProfile -Filter "SID = '$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)'").LocalPath

        # Create User configuration folder if it doesn't already exist
        if (-NOT (Test-Path -Path "$global:UserAccountDirectoryPath\.WDACConfig\")) {
            New-Item -ItemType Directory -Path "$global:UserAccountDirectoryPath\.WDACConfig\" -Force -ErrorAction Stop | Out-Null
            Write-Debug -Message "The .WDACConfig folder in current user's folder has been created because it didn't exist."
        }

        # Create User configuration file if it doesn't already exist
        if (-NOT (Test-Path -Path "$global:UserAccountDirectoryPath\.WDACConfig\UserConfigurations.json")) {
            New-Item -ItemType File -Path "$global:UserAccountDirectoryPath\.WDACConfig\" -Name 'UserConfigurations.json' -Force -ErrorAction Stop | Out-Null
            Write-Debug -Message "The UserConfigurations.json file in \.WDACConfig\ folder has been created because it didn't exist."
        }

        if ($Open) {
            . "$global:UserAccountDirectoryPath\.WDACConfig\UserConfigurations.json"
            break
        }

        if ($PSBoundParameters.Count -eq 0) {
            # Display this message if User Configuration file is empty
            if ($null -eq (Get-Content -Path "$global:UserAccountDirectoryPath\.WDACConfig\UserConfigurations.json")) {
                &$WritePink "`nYour current WDAC User Configurations is empty."
            }
            # Display this message if User Configuration file has content
            else {
                &$WritePink "`nThis is your current WDAC User Configurations: "
                Get-Content -Path "$global:UserAccountDirectoryPath\.WDACConfig\UserConfigurations.json" | ConvertFrom-Json | Format-List *
            }
            break
        }

        # Read the current user configurations
        [PSCustomObject]$CurrentUserConfigurations = Get-Content -Path "$global:UserAccountDirectoryPath\.WDACConfig\UserConfigurations.json"
        # If the file exists but is corrupted and has bad values, rewrite it
        try {
            $CurrentUserConfigurations = $CurrentUserConfigurations | ConvertFrom-Json
        }
        catch {
            Write-Warning 'The UserConfigurations.json was corrupted, clearing it.'
            Set-Content -Path "$global:UserAccountDirectoryPath\.WDACConfig\UserConfigurations.json" -Value ''
        }
    }

    process {}

    end {
        # Use a switch statement to check which parameter is present and output the corresponding value from the json file
        switch ($true) {
            $SignedPolicyPath.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.SignedPolicyPath }
            $UnsignedPolicyPath.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.UnsignedPolicyPath }
            $SignToolPath.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.SignToolCustomPath }
            $CertCN.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.CertificateCommonName }
            $StrictKernelPolicyGUID.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.StrictKernelPolicyGUID }
            $StrictKernelNoFlightRootsPolicyGUID.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.StrictKernelNoFlightRootsPolicyGUID }
            $CertPath.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.CertificatePath }
            $LastUpdateCheck.IsPresent { Write-Output -InputObject $CurrentUserConfigurations.LastUpdateCheck }
        }
    }
}

<#
.SYNOPSIS
Query and Read common values for parameters used by WDACConfig module

.LINK
https://github.com/HotCakeX/Harden-Windows-Security/wiki/Get-CommonWDACConfig

.DESCRIPTION
Reads and gets the values from the User Config Json file, used by the module internally and also to display the values on the console for the user

.COMPONENT
Windows Defender Application Control, ConfigCI PowerShell module, WDACConfig module

.FUNCTIONALITY
Reads and gets the values from the User Config Json file, used by the module internally and also to display the values on the console for the user

.PARAMETER SignedPolicyPath
Shows the path to a Signed WDAC xml policy

.PARAMETER UnsignedPolicyPath
Shows the  path to an Unsigned WDAC xml policy

.PARAMETER CertCN
Shows the certificate common name

.PARAMETER SignToolPath
Shows the  path to the SignTool.exe

.PARAMETER CertPath
Shows the path to a .cer certificate file

.PARAMETER Open
Opens the User Configuration file with the default app assigned to open Json files

.PARAMETER StrictKernelPolicyGUID
Shows the GUID of the Strict Kernel mode policy

.PARAMETER StrictKernelNoFlightRootsPolicyGUID
Shows the GUID of the Strict Kernel no Flights root mode policy

#>

# Set PSReadline tab completion to complete menu for easier access to available parameters - Only for the current session
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
