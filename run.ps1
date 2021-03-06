##########################################################################
# This is build bootstrapper script for PowerShell.
##########################################################################

<#

.SYNOPSIS
This is a Powershell script to run newman with collections for EHR Store. 

.DESCRIPTION
This Powershell script will execute newman with the parameters you provide. 

.PARAMETER Url
Base url for ehr store server
.PARAMETER Iterations
Number of iterations to run
.PARAMETER Help
Prints script synoposis, description, parameters and link

.LINK
http://www.github.com/DIPSAS/EhrStore.Postman

.EXAMPLE
./run.ps1
Default 
.EXAMPLE
./run.ps1 -Url "http://localhost:9000"
Set url
.EXAMPLE
./run.ps1 -Url "http://localhost:9000" -Iterations 10
Set url and iterations
#>

[CmdletBinding()]

Param(
    [string]$Url = "http://localhost:9000",
    [int]$Iterations = 1,
    [switch]$Help
)


###########################################################################
# PRINT HELP
###########################################################################
if ($Help) {
    Get-Help .\run.ps1 -full
    exit 0
}

$ErrorActionPreference = 'Stop'

function Exec([scriptblock]$cmd, [string]$errorMessage = "Error executing command: " + $cmd) {
    & $cmd
    if ($LastExitCode -ne 0) {
        throw $errorMessage
    }
}

exec { & npm install -g newman newman-reporter-teamcity }

$uri = [System.Uri]$Url

$serverPort = $uri.Port
$serverHostname = $uri.Host 
$serverProtocol = $uri.Scheme

$message = "Running API test against $serverProtocol" + "://$serverHostname" + ":$serverPort"
Write-Host $message

# Run newman tests for all json files named *collection.json in the src/ folder
exec { &  Get-ChildItem -Path "src\*collection.json" -Recurse | Sort-Object Length -Descending | ForEach-Object {
    newman run $_.FullName  --global-var "Protocol=$serverProtocol" --global-var "ServerHostname=$serverHostname" --global-var "ServerPort=$serverPort" --global-var "BasePath=openehr" -k -n $iterations -r teamcity,cli
    }
}

Write-Output "##teamcity[message text='$serverHostname']"
