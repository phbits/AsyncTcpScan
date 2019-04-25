# Script to run in each thread.
[System.Management.Automation.ScriptBlock]$ScriptBlock = {

    $result = New-Object PSObject -Property @{  'IP'         = $args[0];
                                                'Port'       = $args[1];
                                                'Status'     = $false;
                                                'BeginTime'  = Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff'
                                                'EndTime'    = Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff'  }

    try{
        
        $tcpClient = New-Object Net.Sockets.TcpClient([System.Net.IPAddress]::Parse($result.IP),$result.Port)

        if($tcpClient.Connected)
        {            
            $result.Status = $true 
            $result.EndTime = Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff'
        }

    } catch { } finally {

        if($null -ne $tcpClient)
        {            
            $tcpClient.Dispose() 
        }

        if($result.Status -eq $false)
        {
            $result.EndTime = Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff'
        }
    }

    return $result

} # End $ScriptBlock

function Approve-TcpPortList
{
    <#
        .SYNOPSIS
        Approves TcpPortList input parameter.

        .LINK
        https://mikefrobbins.com/2018/04/19/moving-parameter-validation-in-powershell-to-private-functions/
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.String[]]
        # TcpPortList provided by user.
        $Ports
    )

    $result = $true

    foreach($port in $Ports)
    {
        [int]$portInt = 0

        if([System.Int32]::TryParse($port, [ref]$portInt))
        {
            if($portInt -le 0 -or $portInt -gt 65535)
            {
                throw "Invalid port $port"

                $result = $false
            }

        } else {

            throw "Invalid port $port"

            $result = $false
        }
    }

    return $result

} # End function Approve-TcpPortList

function Invoke-AsyncTcpScan
{
    <#
        .SYNOPSIS

        Scans an IP Address for open TCP ports using Net.Sockets.TcpClient and Runspaces.

        .DESCRIPTION

        Scanning an IP address for open ports with just Net.Sockets.TcpClient takes time. 
        
        By leveraging Runspaces, ports can be scanned using parallel threads. 

        This method is much faster than techniques leveraging *-Job cmdlets.

        Thanks to @BornToBeRoot for posting PowerShell_IPv4PortScanner!

            https://github.com/BornToBeRoot/PowerShell_IPv4PortScanner


        .OUTPUTS

        System.Object[]

            Port        - Destination Port
            Status      - True/False
            IP          - Destination IP Address
            BeginTime   - Job Start Time
            EndTime     - Job End Time

        .EXAMPLE

        Invoke-AsyncTcpScan -IPAddress 10.1.1.1 -TcpPortList $(20..1024)

        .EXAMPLE

        Invoke-AsyncTcpScan -IPAddress 10.1.1.1 -TcpPortList $(20..2000) -MaxThreads 20

        .EXAMPLE

        $PortList = '22','25','53','80','88','123','389','443','445','636','3389'

        PS C:\>Invoke-AsyncTcpScan -IPAddress 10.1.1.1 -TcpPortList $PortList -WaitTime 500

        .EXAMPLE

        $PortList = '22','25','53','80','88','123','389','443','445','636','3389'

        PS C:\>$Servers = '10.1.1.1','10.1.1.2','10.1.1.3'

        PS C:\>$AllResults = $Servers | %{ Invoke-AsyncTcpScan -IPAddress $_ -TcpPortList $PortList }

        .LINK

        https://devblogs.microsoft.com/scripting/beginning-use-of-powershell-runspaces-part-1/
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [ValidateScript({[System.Net.IPAddress]::Parse($_)})]
        [System.String]
        # Destination IP address to scan.
        $IPAddress
        ,
        [parameter(Mandatory=$true)]
        [ValidateScript({Approve-TcpPortList $_})]
        [System.String[]]
        # List of TCP ports to scan.
        $TcpPortList
        ,
        [parameter(Mandatory=$false)]
        [ValidateRange(3,10000)]
        [System.Int32]
        # Max number of threads for RunspacePool.
        $MaxThreads = 10
        ,
        [parameter(Mandatory=$false)]
        [ValidateRange(1,100000)]
        [System.Int32]
        # Milliseconds to wait for jobs.
        $WaitTime = 1000
    )
    $Start = Get-Date

    $Results = @()

    $AllJobs = New-Object System.Collections.ArrayList

    $HostRunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(2,$MaxThreads,$Host)

    $HostRunspacePool.Open()

    Write-Verbose -Message "Submitting async jobs."

    foreach($port in $TcpPortList)
    {
        $asyncJob = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddParameters($($IPAddress,$port))

        $asyncJob.RunspacePool = $HostRunspacePool
        
        $asyncJobObj = @{ JobHandle   = $asyncJob;
                          AsyncHandle = $asyncJob.BeginInvoke()    }

        $AllJobs.Add($asyncJobObj) | Out-Null
    }

    Write-Verbose -Message "Finished submitting async jobs."
    Write-Verbose -Message "Processing completed jobs."

    $ProcessingJobs = $true

    Do {

        $CompletedJobs = $AllJobs | Where-Object { $_.AsyncHandle.IsCompleted }

        if($null -ne $CompletedJobs)
        {
            foreach($job in $CompletedJobs)
            {
                $result = $job.JobHandle.EndInvoke($job.AsyncHandle)
            
                if($null -ne $result)
                {
                    $Results += $result
                }

                $job.JobHandle.Dispose()

                $AllJobs.Remove($job)
            } 
        
        } else {

            if($AllJobs.Count -eq 0)
            {
                $ProcessingJobs = $false
            
            } else {

                Start-Sleep -Milliseconds $WaitTime
            }
        }

        Write-Verbose -Message "Jobs in progress $($AllJobs.Count)"

    } While ($ProcessingJobs)
    
    $HostRunspacePool.Close()
    $HostRunspacePool.Dispose()

    Write-Verbose -Message "Start  $($Start.ToString('yyyy/MM/dd HH:mm:ss.fff'))"
    Write-Verbose -Message "Finish $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss.fff')"

    return $Results

} # End function Invoke-AsyncTcpScan
