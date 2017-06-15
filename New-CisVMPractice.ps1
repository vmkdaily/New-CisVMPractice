#Requires -Version 3

Function New-CisVMPractice {
<#

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

.INPUTS

.OUTPUTS
VMware.VimAutomation.Cis.Core.Types.V1.ID

#>

  [CmdletBinding(DefaultParameterSetName='Default')]
  Param(

  #String.  IP Address or DNS Name of a vCenter Server to connect to (optional if already connected)
  [Parameter(ParameterSetName='Default')]
  [Parameter(ParameterSetName='Credential', Mandatory)]
  [Parameter(ParameterSetName='PathBasedCredential', Mandatory)]
  [string]$Computer,

  ## PSCredential. Login info for vCenter using PSCredential.
  [Parameter(ParameterSetName='Credential',HelpMessage='PSCredential for vCenter Login.  Only mandatory in the Credential parameterset', Mandatory)]
  [pscredential]$Credential,

  ## String. Path to an encryted xml credential file.  Optionally use this instead of providing PSCredential directly.
  [Parameter(ParameterSetName='PathBasedCredential',HelpMessage='Path to an encrypted xml credential file with ability to login to vCenter Server.  Only mandatory in the PathBasedCredential parameterset', Mandatory)]
  [ValidateScript({Test-Path -Path $_})]
  [string]$PathBasedCredential,

  #String.  Name for new virtual machine
  [Parameter(Mandatory,HelpMessage='Specifies a name for the new virtual machine')]
  [Parameter(ParameterSetName='Default', Mandatory)]
  [Parameter(ParameterSetName='Credential')]
  [Parameter(ParameterSetName='PathBasedCredential')]
  [ValidateNotNullOrEmpty()]
  [string]$Name,

  #String.  Type of guest operating system to deploy (i.e. 'DARWIN_10_64').  The default is 'WINDOWS_7_64'.
  [Parameter(ParameterSetName='Default')]
  [Parameter(ParameterSetName='Credential')]
  [Parameter(ParameterSetName='PathBasedCredential')]
  [string]$GuestId,

  #String or datastore object.  Datastore on which to register the VM.
  [Parameter(ParameterSetName='Default')]
  [Parameter(ParameterSetName='Credential')]
  [Parameter(ParameterSetName='PathBasedCredential')]
  [PSObject]$Datastore

  )

  Begin {

    #Startup message
    Write-Verbose -Message "Starting $($MyInvocation.Mycommand) at $(Get-Date) local time"
    Write-Debug -Message "Using parameter set $($PSCmdlet.ParameterSetName)"
    Write-Debug -Message ($PSBoundParameters | Out-String)
  } #End Begin

  Process {
      
      #region credential from file (optional)
      Function Import-PSCredential {

        <#
          .DESCRIPTION
            Imports a PSCredential from an encrypted xml file on disk.
            
          .NOTES
            Script:         Import-PSCredential.ps1
            Type:           Function
            Author:         Hal Rottenberg
            Organization:   vmkdaily
            Updated:        05April2017

          .EXAMPLE
          Import-PSCredential -Path <path to cred file>

        #>

          [CmdletBinding()]
          param (
            
          [ValidateScript({Test-Path -Path $_})]
          [string]$Path = 'credentials.enc.xml' )

          Process {

              if($Path) {
                  # Import credential file
                  $import = Import-Clixml -Path $Path 

                  # Test for valid import
                  if(!$import.UserName -or !$import.EncryptedPassword) {
                      Throw 'Input is not a valid ExportedPSCredential object, exiting.'
                  }
                  $Username = $import.Username

                  # Decrypt the password and store as a SecureString object for safekeeping
                  $SecurePass = $import.EncryptedPassword | ConvertTo-SecureString

                  # Build the new credential object
                  $CredObj = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePass
                  Write-Output -InputObject $CredObj
              }
              Else {
                  Write-Warning -Message ('Problem importing credential from path {0}' -f $Path)
              }
          } #End process
      } #End Function

      ## If using encrypted xml credential from file
      If($PathBasedCredential){
        try {
          $Credential = Import-PSCredential -Path $PathBasedCredential -ErrorAction Stop
          Write-Verbose -Message ('Using Credential of {0}' -f ($Credential.GetNetworkCredential().UserName))
        }
        catch {
          Write-Error -Message $Error[0].exception.Message
        }
      } #End If
      #endregion

      #region connections
      #If Computer parameter is not populated, use existing VIServer Name
      If((-Not($Computer)) -and ($Global:DefaultVIServer.IsConnected)){
        [string]$Computer = $Global:DefaultViserver | Select-Object -ExpandProperty Name
      }

      # Regular VC Connection
      If(-Not($Global:DefaultVIServer.IsConnected)) {

          [string]$InitialVIServerConState = 'NotConnected'
        
          If($Computer){
              try {
                  $null = Connect-VIServer -Server $Computer -Credential $Credential -ErrorAction Stop
              }
              catch {
                  Write-Error -Message $Error[0].exception.Message
                  Throw 'Problem connecting to VIServer!'
              }
          }
          Else {
            Write-Warning -Message 'Please connect to vCenter VIServer before running script, or populate the Computer parameter at runtime'
            throw 'vCenter connection required!'
          }
      }

      # Connect to the vSphere Automation SDK API Server Service
      If((-Not($Global:DefaultCisServers)) -or (-Not($Global:DefaultCisServers.IsConnected))){

          [string]$InitialCisConState = 'NotConnected'
          If($Credential){
              If($Computer) {
                
                  try {
                      $null = Connect-CisServer -Server $Computer -Credential $Credential -Verbose -ErrorAction Stop
                  }
                  catch {
                      Write-Error -Message $Error[0].exception.Message
                      Throw 'Problem connecting to vCenter CisServer!'
                  }
              }
              Else {
                  try {
                      $null = Connect-CisServer -Server $Global:DefaultVIServer -Credential $Credential -Verbose
                  }
                  catch {
                      Write-Error -Message $Error[0].exception.Message
                      Throw 'Problem connecting to vCenter CisServer!'
                  }
              }
          }
          Else {

          <#
            If there is no runtime credential, and the CisServer is not connected, the user will be
            prompted for both user name and password (unless they are a credential store user).
          #>
              Write-Warning -Message 'Login for vCenter CisServer required!'
              
              try {
                $null = Connect-CisServer -Server ($Global:DefaultVIServer | Select-Object -ExpandProperty Name) -User ($global:DefaultVIServer | Select-Object -ExpandProperty User)
              }
              catch {
                Write-Error -Message $Error[0].exception.Message
                throw 'vCenter CisServer login required!'
              }
          } #End Else
      } #End If

      #Confirm VIServer and CisServer names match
      If(($Global:DefaultVIServer | Select-Object -ExpandProperty Name) -notmatch ($Global:DefaultCisServers | Select-Object -ExpandProperty Name)){
          Throw 'VIServer and CisServer are different!'
      }
      #endregion

      #region manual settings
      <#
        Here we add things like datastore to use and VMHost to choose, etc.
        You may consider replacing these with the api.
        replace using api instead of cmdlets (optional).
      #>
      If($Datastore) {
          
          If($Datastore -is [string]){
            
              try{
                  $dsImpl = Get-Datastore -Name $Datastore -ErrorAction Stop
                  Write-Verbose -Message "Using datastore of $($dsImpl)"
              }
              catch {
                  Write-Error -Message $Error[0].exception.Message
                  throw 'Cannot enumerate datastore from provided string!'
              }
          }
          Else{
              if($Datastore -is [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.StorageResource]){
                  $dsImpl = $Datastore
                  Write-Verbose -Message "Using provided datastore object $($dsImpl)"
              }
          }
      }
      Else {
          try {
              $ds = Get-Datastore -ErrorAction Stop
              $dsImpl = ($ds | Sort-Object -Property $_.FreeSpaceGB -Descending)[0]
              Write-Verbose -Message "Using first enumerable datastore $($dsImpl)"
          }
          catch {
              Write-Error -Message $Error[0].exception.Message
              throw 'Unable to enumerate datastore!'
          }
      }

      ## Choose VMHost
      If($dsImpl) {
        $EsxImpl = $dsImpl | Get-VMHost | Where-Object { $_.ConnectionState -eq 'Connected'} | Get-Random
        Write-Verbose -Message "Using random host $($EsxImpl) with access to $($dsImpl)"
      }
      Else {
        $EsxImpl = (Get-VMHost)[0] 
        Write-Verbose -Message "Using first enumerated host $($EsxImpl)"
      }
      #endregion

      #region guest os ID
      #Set default selection for GuestId in case user does not populate
      If(-Not($GuestId)) {
        [string]$GuestId = 'WINDOWS_7_64'
        Write-Verbose -Message "No GOS type provided, using script default of $($GuestId)"
      }
      #endregion

      #region api
      # Get the service for VM management
      try {
        $vmService = Get-CisService -Name 'com.vmware.vcenter.VM' -ErrorAction Stop
        Write-Verbose -Message 'Successfully retrieved service for VM management'
      }
      catch {
        Write-Warning -Message 'Problem retrieving the service for VM management'
        Write-Error -Message $Error[0].exception.Message
      }

      # Create a VM creation specification
      try {
        $createSpec = $vmService.Help.create.spec.CreateExample()
      }
      catch {
        Write-Error -Message $Error[0].exception.Message
      }
 
      # Fill in the creation details
      $createSpec.name = $Name
      $createSpec.memory.size_MiB = 2048
      $createSpec.guest_os = $GuestId
      $createSpec.placement.folder = (Get-Folder -Name 'vm').ExtensionData.MoRef.Value
      $createSpec.placement.host = $EsxImpl.ExtensionData.MoRef.Value
      $createSpec.placement.datastore = $DsImpl.ExtensionData.MoRef.Value
      $createSpec.placement.cluster = $null
      $createSpec.placement.resource_pool = $null
      #endregion api

      #region private function
      Function Invoke-DeployVmSpec {

       <#
        .DESCRIPTION
          Quick function to deploy VM with SDK API.
       #>  
     
      [CmdletBinding()]
      Param()
        
        Process { 

          # Call the create method passing the specification
          try {
            Write-Verbose -Message "..Attempting to deploy virtual machine $($Name)"
            [VMware.VimAutomation.Cis.Core.Types.V1.ID]$NewCisVmId = $vmService.create( $createSpec )
          }
          catch {
            Write-Warning -Message 'Problem calling create method to deploy VM!'
            Write-Error -Message $Error[0].exception.Message
          }

          If($NewCisVmId) {
              Write-Verbose -Message "Successfully deployed virtual machine $($Name) with Cis Identifier of $($NewCisVmId)"
              return $NewCisVmId
          } #End If
        } #End Process
      } #End Function
      #endregion
      
      #region deploy virtual machine
      try{
        $DeployVM = Invoke-DeployVmSpec -ErrorAction Continue
      }
      catch {
        Write-Error -Message $Error[0].exception.Message
      } #End Catch
      #endregion

      #region results
      If($DeployVM -is [VMware.VimAutomation.Cis.Core.Types.V1.ID]) {
        return $DeployVM
      }
      #endregion

  } #End Process

  End {

    #Disconnect the VIServer runtime connection, if needed
    Write-Verbose -Message 'Performing session cleanup'
    If($InitialVIServerConState -eq 'NotConnected'){
        $null = Disconnect-VIServer -Server $Computer -Confirm:$false -Force
    }
    Else {
        Write-Verbose -Message 'Initial VIServer Connection state was Connected'
        Write-Verbose -Message ('Existing connection to {0} will remain' -f ($Global:DefaultVIServer).Name)
    }

    #Disconnect the CisServer runtime connection, if needed
    If($InitialCisConState -eq 'NotConnected'){
        $null = Disconnect-CisServer -Server $Computer -Confirm:$false -Force
    }
    Else {
        Write-Verbose -Message 'Initial CisServer Connection state was Connected'
        Write-Verbose -Message ('Existing connection to {0} will remain' -f ($Global:DefaultCisServers).Name)
    }

    #Completion message
    Write-Verbose -Message "Ending $($MyInvocation.Mycommand) at $(Get-Date) local time"

  } #End End
} #End Function
