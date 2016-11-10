#requires -version 2
<#
.SYNOPSIS
    <Overview of script>
  
.DESCRIPTION
    <Brief description of script>
  
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>

.PARAMETER <$Vcenter_Array>
    Creates an array of the vcenter servers you want to run this script against

.INPUTS
    Credential XMl files need to be stored in folder relative to the script in \CredentialStore
    Credential files need to be named 
  
.OUTPUTS
    Log file stored in folder relative to the script in \Output\Vmware_Active_Snapshots_Report.log
  
.NOTES
    Version:        1.0.0
    Author:         Scripting-Cactus
    Creation Date:  10/11/2016
    Purpose/Change: Inital script cloned from @9to5IT/powercli_script_template.ps1
                    Added loops for multiple vCenters
                    Changed to use credential files
                    Changed Method of logging to not require seperate function
  
.EXAMPLE
    $Vcenter_Array = @("vCenter-1", "vCenter-2", "etc")
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$Project_Author = "Scripting-Cactus"
$Project_Name = "Powercli-Script-Template"
$Local_Version = "Version 1.0.0"

#Path Decloration
$Invocation = (Get-Variable MyInvocation).Value
$Directory_Path = Split-Path $Invocation.MyCommand.Path

#Log File Info
$Log_Path = $Directory_Path + "\Output"
$Log_Name = $Project_Name + ".log"
$Log_File = Join-Path -Path $Log_Path -ChildPath $Log_Name


#Array of vCenter servers to connect to
$Vcenter_Array = @("vCenter-1")

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Start Logging
Add-content $Log_File -value "$Project_Name"
Add-content $Log_File -value "$(Get-Date) : Initialising Script"
write-host "Initialising Script"

#Add VMware PowerCLI Snap-Ins
try{
	Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop
}
catch{
	write-host "VMware Snapin could not be loaded. Is VMware PowerCli installed?"
	Add-content $Log_File -value "$Log_Date : $_"
	break
}
Finally{
	Add-content $Log_File -value  "$(Get-Date) : VMware Snapin successfully loaded"
	write-host "VMware Snapin successfully loaded"
}

#Set Error Preferences
$WarningActionPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

# Set user to run script as
$Credentials_User = "username"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#Function to connect to vCenters
Function Connect-VMwareServer{
    Param([Parameter(Mandatory=$true)][string]$Vcenter_Server)
    Begin{
            Add-content $Log_File -value "$(Get-Date) : Attempting to connect to $Vcenter_Server"
    }
    Process{
            Try{
				$Credentials = Get-VICredentialStoreItem -Host $Vcenter_Server | where {$_.User -eq $Credentials_User}
				Connect-VIServer $Vcenter_Server -User $Credentials.User -Password $Credentials.Password
            }
            Catch{
				Add-content $Log_File -value "$(Get-Date) : $_"
				write-host "Error connecting to vCenter $Vcenter_Server. See log file $Log_File for details."
				$Connected = "False"
				$Errors_Encounterd = "True"
                return
            }
    }
    End{
            If($Connected -eq "True"){
                Add-content $Log_File -value  "$(Get-Date) : Successfully connected to $Vcenter_Server"
                write-host "Successfully connected to $Vcenter_Server"
            }
    }
}

#Function to connect to vCenters
Function Disconnect-VMwareServer{
    Param([Parameter(Mandatory=$true)][string]$Vcenter_Server)
    Begin{
            Add-content $Log_File -value "$(Get-Date) : Attempting to Disconnect from $Vcenter_Server"
    }
    Process{
		$Connection_State = $defaultviserver | foreach {$_.IsConnected}
        if($Connection_State -eq "True"){
            disconnect-VIServer -server $Vcenter_Server -confirm:$false
            $Disconnected = "True"
        }
        else{
            Add-content $Log_File -value  "$(Get-Date) : Cannot disconnect from $Vcenter_Server as it is not connected"
            write-host "Cannot disconnect from $Vcenter_Server as it is not connected"
			$Errors_Encounterd = "True"
            return
        }
    }
    End{
        If($Disconnected -eq "True"){
            Add-content $Log_File -value  "$(Get-Date) : Successfully disconnected from $Vcenter_Server"
            write-host "Successfully disconnected from $Vcenter_Server"
        }
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

foreach($vCenter in $vCenter_Array)
	{
        Connect-VMwareServer -Vcenter_Server $Vcenter
        #AdditionalScript Execution goes here
        Disconnect-VMwareServer $Vcenter
    }

#-----------------------------------------------------------[Finalisation]---------------------------------------------------------

if($Errors_Encounterd = "True")
	{
		Add-content $Log_File -value "$(Get-Date) : Script has completed with errors"
		write-host "Script has completed with errors. Please review the log file located at $Log_File"
	}
else
	{
		Add-content $Log_File -value "$(Get-Date) : Script has been successfully completed"
		write-host "Script has been successfully completed"
	}
