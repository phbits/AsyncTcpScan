@{

RootModule = 'AsyncTcpScan.psm1'

ModuleVersion = '1.0'

GUID = '03332a77-fd18-4801-a48a-7986e4523501'

Author = 'phbits'

CompanyName = 'phbits'

Copyright = '(c) 2019 phbits. All rights reserved.'

Description = 'Scans an IP Address for open TCP ports using Net.Sockets.TcpClient and Runspaces.'

PowerShellVersion = '5.0'

FunctionsToExport = 'Invoke-AsyncTcpScan'

PrivateData = @{

    PSData = @{

        Tags = 'Async','Runspaces','TcpClient','Scan','Troubleshooting','Testing','Network'

        ProjectUri = 'https://github.com/phbits/AsyncTcpScan'

    } # End of PSData hashtable

} # End of PrivateData hashtable

}

