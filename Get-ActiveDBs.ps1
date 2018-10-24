<#
Created:    2018-10-24
Updated:    2018-10-24
Version:    1.0
Author :    Marcus Wahlstam
Company:    Advitum AB

Information:
This script queries specified SQL servers for active connections and appends new information
to a CSV file.
If you don't know which databases is active and in use and which systems that does access
the databases, this script is written for just that! It will log the database, hostname (of the 
connecting computer/server) and username.
It will create a CSV file for every server.
This script is meant to schedule every 10 minutes or so.
There is no other logging or error-handling. Just a quick and dirty script, see disclaimer below.

Change the following variables:
$servers - Array of servers you want to query
$LogFile - Path to where the CSV files should be saved (optional, default is same directory as the script and filename like server1.csv)

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and
is not supported by the author

Updates
1.0 - Initial release

License:
The MIT License (MIT)

Copyright (c) 2018 Marcus Wahlstam, Advitum AB

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

#Array of SQL servers to run query against
$servers = "server1.domain.local","server2.domain.local","server3.domain.local","server4.domain.local"

#SQL query to get active connections
$query = "
SELECT @@ServerName AS SERVER
 ,NAME
 ,hostname
 ,loginame
FROM sys.databases d
LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
WHERE database_id NOT BETWEEN 0
  AND 4
 AND loginame IS NOT NULL
 "

foreach ($server in $servers)
{
    $DBArray = @()
    $LogFile = "$PSScriptRoot\$server.csv"

    #Authenticate to specific server with specific username/password
    if ($server -eq "server2")
    {
        $DBs = Invoke-Sqlcmd -Query $query -ServerInstance "$server" -Username "sa" -Password "passwd" | sort name,hostname -Unique
    }
    #Authenticate to specific servers with specific username/password
    elseif ($server -eq "server3" -or $server -eq "server4")
    {
        $DBs = Invoke-Sqlcmd -Query $query -ServerInstance "$server" -Username "user" -Password "passwd" | sort name,hostname -Unique
    }
    #Authenticate to others using SSO
    else
    {
        $DBs = Invoke-Sqlcmd -Query $query -ServerInstance "$server" | sort name,hostname -Unique
    }

    #Convert dataset to PSObject and store in $DBArray
    foreach ($row in $DBs)
    {
        $database = $row.Name
        $hostname = $row.hostname -replace " ",""
        $loginname = $row.loginame -replace " ",""
        #"$database;$hostname;$loginname"
        $DBArray += New-Object psobject -Property @{
        Database = $database
        Hostname = $hostname
        User = $loginname
        }
    }

    #If logfile exists, compare old data with new and rewrite logfile with old+new data
    if (Test-Path $LogFile)
    {
        $oldDBs = Get-Content $LogFile | ConvertFrom-Csv
        $merged = $DBArray + $oldDBs | sort Database,Hostname -Unique
        $merged | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $LogFile -Force
    }
    #If no logfile exists, write logfile
    else
    {
        $DBArray | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $LogFile
    }
}