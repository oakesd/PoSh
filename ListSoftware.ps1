#######################################################################################################################
#######################################################################################################################

# USAF Edwards AFB List Software script

# Created 3/5/2020 by Dustin Oakes
# 
# Provides an alphabetical listing of all software programs installed on a computer
# Gives Admin option to uninstall a program by number

#######################################################################################################################
#######################################################################################################################

# Updated 5/28/2020: Added 'Create-Directory' and 'Output-SoftwareList' functions. 
# Allows user to export software list to text file.

######################################################################################################################
######################################################################################################################

# Updated 5/29/2020: Removed Requirement to run as Admin. Script will now only prompt to uninstall software if run
# as Admin, but can be run without Admin rights on local machine.

#######################################################################################################################
#######################################################################################################################


### Function Declaration ###

Function IsNumeric ($Value) {
    
    Return $Value -match "^[\d\.]+$"

}

Function IsAdmin {

   Return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] “Administrator”)

}

Function IsInstalled {

    param (
            
        [parameter(Mandatory=$true)]
        [string] $Computer,
        
        [parameter(Mandatory=$true)]
        [string] $SoftwareId    

    )

    [object[]]$software = Get-WmiObject Win32_Product -ComputerName $Computer | 
                            Where-Object {$_.IdentifyingNumber -eq $SoftwareId}
    
    if ($software.Length -gt 0) { 
    
        Return $true

    } else {
    
        Return $false
    }
    
}

Function Get-SoftwareList {

    param (

        [parameter(Mandatory=$true)] 
        [string] $Computer                
    
    )

    try {

        Get-WmiObject Win32_Product -ComputerName $Computer | Sort-Object -Property Name

    } catch {

        Write-Host "`r`nError retrieving software listing"
        Write-Host $_
    }
}

Function Display-SoftwareList {

    param (

        [parameter(Mandatory=$true)]
        [string] $Computer,

        [parameter(Mandatory=$true)] 
        [object[]] $Programs
    
    )

    Write-Host "`r`nThe following programs are installed on $Computer`r`n"

    $i = 1
    foreach ($program in $Programs) {

        Write-Host "`n"$i" |" $program.Name
        
        for ($n = 1; $n -le (($program.Name.Length) + 10); $n++) {
        
            Write-Host "-" -NoNewLine
        
        }

        $i++
    
    }

    Write-Host

}

Function Create-Directory {

    param (
 
        [parameter(Mandatory=$true)]
        [string] $Directory

    )
    
    if (!( Test-Path -Path $Directory )) {
    
        try {
            
            New-Item -ItemType "directory" -Path $Directory

        } catch {

        Write-Host "`r`nError creating directory."
        Write-Host $_

        }
    } 

}

Function Export-SoftwareList {

    param (
 
        [parameter(Mandatory=$true)]
        [string] $Computer,

        [parameter(Mandatory=$true)] 
        [object[]] $Programs
    
    )

    $directory = "C:\Temp\SoftwareLists"
      
    Create-Directory $directory

    $filedate = Get-Date -Format "_HHmmyyMMdd"
    $timestamp = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
    $file = $directory + "\" + $Computer + $filedate + ".txt"
    $title = $Computer + ": " + $timestamp

    Write-Host "`r`nExporting software list to " $file "..."
        
    Set-Content -Path $file -Value ""
    $title | Add-Content -Path $file
    Add-Content -Path $file -Value ""
    
    $i = 1
    foreach ($program in $Programs) {

        if ($i -lt 10) { 
            
            $output = "0" + $i + " | " + $program.Name

        } else {
        
            $output = [string]$i + " | " + $program.Name

        }

        $output | Add-Content -Path $file    

        $i++
    
    }

       
    if (Test-Path -Path $file) {
        
        Write-Host "`r`nExport complete."
        
        Invoke-Item $file

    } else {
    
        Write-Host "'r'nExport failed."
    
    }
        
}


Function Ask-UninstallChoice {

     param (
    
        [parameter(Mandatory=$true)] 
        [object[]] $Programs
    
    )

    $isValidInput = $false
    $invalidInput = "`r`nInvalid entry. Try again or type 'Quit'." 
    
    While (!($isValidInput)) {

        $input = Read-Host "`r`nEnter the number corresponding to the program that you want to uninstall, or type 'Quit'" 
        
        if (!(IsNumeric $input)) {

            if ($input -ieq "QUIT") {
            
                $isValidInput = $true
                Return 0
            
            } else {
                
                Write-Host $invalidInput
                Continue

            }

        } else {

            if (([int]$input -gt 0) -and ([int]$input -le $Programs.Length)) {
            
                $isValidInput = $true
                Return $input
        
            } else {
        
                Write-Host $invalidInput
        
            }
        }
    }
    
    
}


Function Uninstall-Software {

    param (
    
        [parameter(Mandatory=$true)]
        [int] $Number,

        [parameter(Mandatory=$true)]
        [string] $Computer,

        [parameter(Mandatory=$true)] 
        [object[]] $Programs
    
    )

    if ($Number -eq 0) {Return}
    
    $index = $Number - 1

    $isValidInput = $false
    While (!($isValidInput)){
    
        $decision = Read-Host "`r`nAre you sure you want to uninstall "$Programs[$index].Name"? [Y/N]"

        Switch ($decision) {
        
            'Y' {
            
                $isValidInput = $true
                $softwareId = $Programs[$index].IdentifyingNumber
                Write-Host "`r`nAttempting to uninstall" $Programs[$index].Name "..."

                try{                        
                     
                    (Get-WmiObject Win32_Product -ComputerName $Computer | 
                    Where-Object {$_.IdentifyingNumber -eq $softwareId}).Uninstall()

                    if ($?) {
                    
                        Clear
                        Write-Host "`r`nVerifying Uninstall..."
                                               
                        if ( IsInstalled $Computer $softwareId ) {
                            Clear
                            Write-Host "`r`nUninstall FAILED.`r`n"

                        } else {
                            Clear
                            Write-Host "`r`nUninstall SUCCEEDED.`r`n"

                        }
                    
                    }
                    
    
                } catch {
        
                    Write-Host "`r`nAn error occurred while attempting the uninstall."
                    Write-Host $_
    
                }

                Break
            }
        
            'N' {
            
                $isValidInput = $true
                Write-Host "`r`nUninstall aborted."                           
                Break
            }

            Default {
            
                Write-Host "`r`nInvalid Selection. Type 'Y' for yes or 'N' for no."    
                
            }
        
        }
    
    }

}

Function Ask-Finished {

    $isValidInput = $false

    While (!($isValidInput)) {

        $input = Read-Host "`r`nWould you like to scan the computer again? [Y/N]"

        Switch ($input) {
        
            'Y' {

            $isValidInput = $true
            Return $false
            Break
            }

            'N' {
            
            $isValidInput = $true
            Return $true
            Break
            }

            Default {
            
                Write-Host "`r`nInvalid Selection. Type 'Y' for yes or 'N' for no."      

            }
        
        }
    
    }

}

### End of Function Declaration ###

######################################################################################################################
######################################################################################################################

### Begin Main ###


Write-Host "`r`nREAD FIRST! "-ForegroundColor Yellow
Write-Host "`r`nThis script will list all software programs installed on a computer. " -ForegroundColor Yellow
Write-Host "`r`nIf you run the script as Admin, you will be given an option to uninstall any of the listed software programs. " -ForegroundColor Yellow
Write-Host "`r`nMake sure you read each prompt carefully. " -ForegroundColor Yellow
Write-Host "`r`nOnce you confirm an uninstall, you will not be able to undo. " -ForegroundColor Yellow

$computer = (Read-Host "`r`nEnter name of target computer").ToUpper()

$finished = $false

While (!($finished)){

    Clear
    Write-Host "`r`nScanning $computer for installed software..."
    $programs = Get-SoftwareList $computer
        
    Display-SoftwareList $computer $programs

    $isValidInput = $false
    While (!($isValidInput)) {

        $decision = Read-Host "`r`nWould you like to export the list to a text file? [Y/N]" 

        switch ($decision) {

            'Y' {

                $isValidInput = $true
                Export-SoftwareList $computer $programs
                Break

            }

            'N' {
    
                $isValidInput = $true
                Break

            }

            Default {

                Write-Host "`r`nInvalid Selection. Type 'Y' for yes or 'N' for no." 
    
            }
        
        }

    }
    

    if ( IsAdmin ) {

        $isValidInput = $false
        While (!($isValidInput)) {

            $decision = Read-Host "`r`nWould you like to UNINSTALL any of the listed software? [Y/N]" 

            switch ($decision) {

                'Y' {

                    $isValidInput = $true
                    $number = (Ask-UninstallChoice $programs)
                    Uninstall-Software $number $computer $programs
                    $finished = Ask-Finished
                    Break

                }

                'N' {
    
                    $isValidInput = $true
                    $finished = $true
                    Break

                }

                Default {

                    Write-Host "`r`nInvalid Selection. Type 'Y' for yes or 'N' for no." 
    
                }
        
            }

        }
    
    } Else {
    
        $finished = $true
    
    }

}

### End Main ###