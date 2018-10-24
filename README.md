# Get-ActiveDBs
Get a grip of your databases that you thought was active but is not.

This script queries specified SQL servers for active connections and appends new information
to a CSV file.
If you don't know which databases is active and in use and which systems that does access
the databases, this script is written for just that! It will log the database, hostname (of the 
connecting computer/server) and username.
It will create a CSV file for every server.
This script is meant to be scheduled every 10 minutes or so.
There is no other logging or error-handling. Just a quick and dirty script, see disclaimer below.

Change the following variables:
$servers - Array of servers you want to query
$LogFile - Path to where the CSV files should be saved (optional, default is same directory as the script and filename like server1.csv)

Disclaimer:
This script is provided "AS IS" with no warranties, confers no rights and
is not supported by the author
