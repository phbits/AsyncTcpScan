# AsyncTcpScan #

Scans an IP Address for open TCP ports using Net.Sockets.TcpClient and Runspaces.

## Description ##

Scanning an IP address for open ports with just Net.Sockets.TcpClient takes time. 
        
By leveraging Runspaces, ports can be scanned using parallel threads. 

This method is much faster than techniques leveraging *-Job cmdlets.

Thanks to [@BornToBeRoot](https://github.com/BornToBeRoot) for posting [PowerShell_IPv4PortScanner](https://github.com/BornToBeRoot/PowerShell_IPv4PortScanner)!

## Outputs ##

System.Object[]

    Port        - Destination Port
    Status      - True/False
    IP          - Destination IP Address
    BeginTime   - Job Start Time
    EndTime     - Job End Time

## Example ##

```powershell
Import-Module AsyncTcpScan
Invoke-AsyncTcpScan -IPAddress 10.1.1.1 -TcpPortList $(20..1024)
```

## Example ##

```powershell
Invoke-AsyncTcpScan -IPAddress 10.1.1.1 -TcpPortList $(20..2000) -MaxThreads 20
```

## Example ##

```powershell
$PortList = '22','25','53','80','88','123','389','443','445','636','3389'
Invoke-AsyncTcpScan -IPAddress 10.1.1.1 -TcpPortList $PortList -WaitTime 500
```

## Example ##

```powershell
$PortList = '22','25','53','80','88','123','389','443','445','636','3389'
$Servers = '10.1.1.1','10.1.1.2','10.1.1.3'
$AllResults = $Servers | %{ Invoke-AsyncTcpScan -IPAddress $_ -TcpPortList $PortList }
```

## Reference ##

[https://devblogs.microsoft.com/scripting/beginning-use-of-powershell-runspaces-part-1/](https://devblogs.microsoft.com/scripting/beginning-use-of-powershell-runspaces-part-1/)
