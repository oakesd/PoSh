
# USAF Edwards AFB IPv4 to Host Name
# Created 2/12/2020 by Dustin Oakes
# 
# Accepts IPv4 address and returns Host Name.
# Does not need to be run as admin
# 
#######################################################################################################################

######################################################################################################################
######################################################################################################################

### Function Declaration ###

Function IPtoHostName {

    param (
        
        [parameter(Mandatory=$true)] 
        [string] $_ip
                
    )
    
    try {
        $hn = [System.Net.Dns]::GetHostByAddress($_ip).HostName
        Write-Host "`r`nHost Name: " -NoNewline
        Write-Host $hn
    } catch {
        Write-Host "`r`nUnable to resolve IP address to Host Name: " -NoNewline
        Write-Host $_
    }
    
}

### End Function Declaration ###


$ip = Read-Host "`r`nType the host's IPv4 address and press enter"

if ($ip -gt "") {

    $pattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
    
    if ($ip -match $pattern){
        
        IPtoHostName $ip

    } else {

        Write-Host "`r`nInvalid IPv4 format."

    }

} else {

    Write-Host "`r`nNo IPv4 address entered."

}


