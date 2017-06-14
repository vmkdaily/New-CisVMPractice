# New-CisVMPractice
Basic framework to easily get started with Get-CisService to access to the vCenter 6.5 API

Supporting Blog Post:
http://vmkdaily.ghost.io/using-the-vcenter-6-5-api-to-deploy-virtual-machines-with-powercli/


```
.SYNOPSIS
Connects to vCenter 6.5 and creates a Virtual Machine using the vSphere Automation SDK API.

.DESCRIPTION
Connects to vCenter 6.5 and creates a Virtual Machine using the vSphere Automation SDK API.
The VM is built with no hard disk or network adapter.  We leave that for you to learn.

This script is intended for those that want a basic framework to practice with the
SDK API from PowerCLI.  This script builds on Example #2 from 'help Get-CisService -examples'.

This cmdlet makes two connections to your vCenter 6.5 Server:
1. Connect-VIServer (Typical PowerCLI connection to VC like normal)
2. Connect-CisServer (Connection to the same VC)

If you are already connected, we use the existing sessions.  Upon script exit, we leave your
pre-exisiting sessions connected.  We disconnect any sessions that we create at runtime.


.NOTES
Script:     New-CisVMPractice
Author:     Mike Nisk
tested on:  PowerShell 5.1
Tested on:  PowerCLI 6.5.1
Requires:   VMware vCenter Server 6.5 or later

.EXAMPLE
$credsVC = Get-Credential
New-CisVMPractice -Computer vcva02.lab.local -Credential $credsVC -Name TestVM100 -GuestId 'DARWIN_10_64' -Datastore 'vsanDatastore' -Verbose
#This example saves a credential to a variable.
#Then, we create a VM on the desired datastore name.

.EXAMPLE
$credfile = 'C:\Creds\CredsVC1.enc.xml'
New-CisVMPractice -Computer vcva02.lab.local -PathBasedCredential $credfile -Name TestVM200 -Datastore 'vsanDatastore' -Verbose
#In this example we point to a saved credential file from disk.
#Since the GuestId parameter is not populated, the default 'WINDOWS_7_64' is used. 

.EXAMPLE
$vc = 'vcva02.lab.local'
Connect-VIServer -Server $vc
Connect-CisServer -Server $vc
$ds = get-datastore 'vsanDatastore'
New-CisVMPractice -Name TestVM300 -GuestID 'DARWIN_10_64' -Datastore $ds
# In this example, we manually connect to VIServer and CisServer before starting.
# Because we are already connected to VC, the Computer parameter optional.
# Also, we can we pass the datastore as an object instead of string.
# Since no runtime credentials are provided, the script uses existing VIServer and CisServer connections.

.EXAMPLE
New-CisVMPractice -Computer vcva02.lab.local -Name TestVM400 -GuestID 'DARWIN_10_64'
# Since no the Datastore parameter was not provided, the script chooses the datastore with the most free space available.
# Remember, by default this script does not add hard disk, so only the .vmx and virtual machine folder go on the datastore (i.e. no vmdk).
# Tip: Feel free to add logic to create HDD, etc. for VMs (encouraged for API practice).
    
.EXAMPLE
$vc = 'vcva02.lab.local'
Connect-VIServer -Server $vc
Connect-CisServer -Server $vc
$ds = get-datastore 'vsanDatastore'
PS C:\> New-CisVMPractice -Name TestVM500 -GuestID 'DARWIN_10_64' -Datastore $ds -Verbose
VERBOSE: Starting New-CisVMPractice
VERBOSE: Using provided datastore object vsanDatastore
VERBOSE: 6/9/2017 3:02:00 PM Get-CisService Started execution
VERBOSE: 6/9/2017 3:02:00 PM Get-CisService Finished execution
VERBOSE: Successfully retrieved service for VM management
VERBOSE: 6/9/2017 3:02:00 PM Get-VMHost Started execution
VERBOSE: 6/9/2017 3:02:00 PM Get-VMHost Finished execution
VERBOSE: Using random host esx04.lab.local with access to vsanDatastore
VERBOSE: 6/9/2017 3:02:00 PM Get-Folder Started execution
VERBOSE: 6/9/2017 3:02:00 PM Get-Folder Finished execution
VERBOSE: ..Attempting to deploy virtual machine TestVM500
VERBOSE: Successfully deployed virtual machine TestVM500 with Cis Identifier of vm-773
VERBOSE: Performing session cleanup
VERBOSE: Initial VIServer Connection state was Connected
VERBOSE: Existing connection to vcva02.lab.local will remain
VERBOSE: Initial CisServer Connection state was Connected
VERBOSE: Existing connection to vcva02.lab.local will remain
VERBOSE: Ending New-CisVMPractice

Value
-----
vm-773

.EXAMPLE
PS C:\> Get-Item Function:\New-CisVMPractice | Remove-Item -Force
PS C:\> . C:\temp\New-CisVMPractice.ps1
PS C:\> New-CisVMPractice -Name TestVM600

Value
-----
vm-775


#This example removed the function from memory and then reloaded it by dot sourcing it.
#You might do this if you made changes to the script.
#Then, we deployed a VM taking all defaults.
#Finally, we show what the VM looks like with a regular Get-VM


.INPUTS

.OUTPUTS
VMware.VimAutomation.Cis.Core.Types.V1.ID
```
