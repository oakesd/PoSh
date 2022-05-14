# Delete User Profiles
# 
# Removes all user profiles from one local or remote host, *except those profiles that the admin chooses to keep*.
#
# Admin will be prompted to enter user names for profiles to keep (standard system and admin profiles omitted by default)
# Must be run as admin
#
# Author: Dustin Oakes
# Created: 1/22/2020
 
# Update: 3/4/2020
# Modified script to sort list of profiles in ascending order;

# Update: 6/10/2020
# Added the option of uploading profile names from text file

#
#######################################################################################################################
#######################################################################################################################

#Requires -RunAsAdministrator

######################################################################################################################
######################################################################################################################

### Function Declaration ###


#Get-FileName function by Ed Wilson (Dr Scripto)
Function Get-FileName ($initialDirectory) {

[system.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.InitialDirectory = $initialDirectory
$OpenfileDialog.ShowDialog() | Out-Null
$OpenFileDialog.filename

}

Function Delete-Profiles {

    param (
        
        [parameter(Mandatory=$true)] 
        [string] $_computer,

        [Parameter(Mandatory=$true)] 
        [char] $_remote,

        [Parameter(Mandatory=$true)]
        [string[]] $_ignoreList
                
    )
        
         
    #if script is targeting a remote computer, prompt to restart before continuing.
    if ($_remote -ieq 'R') {                        
            
        $_validEntry = $false
        while (!($_validEntry)) {
                
            Write-Host "`r`nWould you like to restart the target computer before attempting to delete the profiles?"
            $_decision = Read-Host "(Recommended if you have not already restarted the computer) [Y/N]"

            if ($_decision -ieq 'Y') {
                
                Write-Host "`r`nAttempting to restart the target computer. Script will continue after restart."
                $_validEntry = $true

                try {
                    
                    Restart-Computer -ComputerName $_computer -Force -Wait
                    if ($?) {Write-Host "`r`nTarget computer restarted. Resuming profile removal..."}

                } catch {

                    Write-Host "`r`nThere was a problem restarting the target computer."
                    Write-Host $_
                    Write-Host "`r`nScript will attempt to continue without restarting the target."

                }
                
            } elseif ($_decision -ieq 'N') {
                
                    $_validEntry = $true
                
            } else {

                Write-Host "Invalid entry."

            }

        }
                        
    }

    try {
        
        Write-Host "`r`nAttempting to delete profiles..."
        Get-CimInstance -ComputerName $_computer -Class win32_userprofile | Where-Object {$_.LocalPath.split('\')[-1] -notin $_ignoreList} | Remove-CimInstance
        If ($?) {Write-Host "`r`nProfiles have been deleted."}
     
    } catch {
                
        Write-Host "`r`nThere was a problem deleting the profiles`n"
        Write-Host $_
     
    }

} 

### End of Function Declaration ###

######################################################################################################################
######################################################################################################################

#Begin Main

Write-Host "`r`nREAD FIRST! " -ForegroundColor Yellow
Write-Host "`r`nThis script will remove user profiles from a computer. " -ForegroundColor Yellow
Write-Host "`r`nIt must be run as an Administrator. " -ForegroundColor Yellow
Write-Host "`r`nMake sure you read each prompt carefully. " -ForegroundColor Yellow
Write-Host "`r`nYou will have a chance to input user names for any profiles that you do not want to delete. " -ForegroundColor Yellow
Write-Host "`r`nMake sure you have those user names on hand, and VERIFY that they are not included in the list " -NoNewLine -ForegroundColor Yellow
Write-Host "of profiles to be deleted before confirming the delete action." -ForegroundColor Yellow
Write-Host "`r`nIf you are going to run the script to remove profiles on this PC, " -NoNewline -ForegroundColor Yellow
Write-Host "it is recommended to restart the computer before running the script." -ForegroundColor Yellow
Write-Host "`r`nIf you are going to run the script to remove profiles on a remote host, you will be prompted to restart the target computer " -NoNewLine -ForegroundColor Yellow
Write-Host "before attempting to remove the profiles. Make sure nobody is logged on before proceeding." -ForegroundColor Yellow

$finished = $false
$validEntry = $false

while (!($validEntry)) {

    $remote = Read-Host "`r`nDo you want to run the script on the Local (L) host, or on a Remote (R) host ? [L/R/Quit]"

    switch ($remote) {

        'QUIT' {

            $validEntry = $true
            $finished = $true 
            Break

        }

        'R' {

            $computer = Read-Host "`r`nEnter target computer name (Or type 'Quit' to stop the script)."
            $validEntry = $true 
            Break

        }

        'L' {

            $computer = $env:COMPUTERNAME
            $validEntry = $true 
            Break

        }

        Default {

            Write-Host "`r`nInvalid Entry."

        }
    }
}


if ($computer -ieq 'QUIT') {

    $finished = $true

} else {
    
    try {
     
        $profiles = Get-CimInstance -ComputerName $computer -Class win32_userprofile | Sort-Object -Property LocalPath
        
        $ignoreList = "Administrator", "Default", "Public", "TEMP", "USAF_Admin", "NetworkService", "LocalService", "SystemProfile"
        $user = $env:USERNAME
        $ignoreList += $user
        
    } catch {
    
        Write-Host "Could not retrieve list of profiles from target computer."
        $finished = $true

    }
    
}

While (!($finished)) {
    
    Write-Host "`r`nThe following profiles WILL BE DELETED!`n"

    $profileCount = 0

    :OuterLoop
    foreach ($profile in $profiles) {
        
        foreach ($ignored in $IgnoreList) {
            
            if ($profile.LocalPath -like "*\$ignored") {
                
                continue OuterLoop

            }
        }
        
        $profileCount += 1

        Write-Host $profile.LocalPath.split('\')[-1]

    }

    $validEntry = $false

    While (!($validEntry)) {

        Write-Host "`r`n$profileCount profiles will be deleted."
        
        $decision = Read-Host "`r`nWould you like to keep any of the profiles that were listed? [Y/N/Quit]"
        
        switch ($decision) {
            
            'QUIT' {
            
                $validEntry = $true
                $finished = $true
                Break

            }

            'N' {

                $confirm = Read-Host "`r`nAre you SURE you want to DELETE all of the listed profiles? [Y/N/Quit]"
                if ($confirm -ieq 'QUIT') {

                    $validEntry = $true
                    $finished = $true

                } elseif ($confirm -ieq 'Y') {
                    
                    $validEntry = $true
                    $finished = $true

                    Delete-Profiles $computer $remote $ignoreList
                    
                }

                Break
            
            }

            'Y' {
            
                $validEntry = $true

                $validChoice = $false
                
                While (!($validChoice)) {
                
                    Write-Host "`r`nSelect an option"
                    Write-Host "`r`n1. Type in profile names manually."
                    Write-Host "`r`n2. Upload profile names from text file."
                    $choice = Read-Host "`r`n1 or 2?"

                    switch ($choice) {
                
                        '1' {
                    
                            $validChoice = $true

                            Write-Host "`r`nType the name of each profile that you would like to keep, pressing Enter after each."
                            Write-Host "NOTE: Only type the name of the profile, not the entire path to the user profile folder."
                            Write-Host "HINT: You can also copy and paste from the list above."
                            Write-Host "Type 'Done' when finished."
   
                            $userInput = ""
                            While ($userInput -ine 'DONE') {

                                if ($userInput -gt "") { $ignoreList += $userInput }
                                $userInput = Read-Host "`r`nEnter profile, or type 'Done' when finished."
                        
                    
                            }
                
                            Break
                               
                        }

                        '2' {
                            
                            $validChoice = $true
                    
                            Write-Host "`r`nSelect file to upload."
                            $fileName = Get-FileName 'c:\temp'
                        
                            if ( Test-Path -Path $fileName ) {
                        
                                $fileInput = ""
                            
                                try {
                                
                                    $fileInput = Get-Content -Path $fileName
                                    $ignoreList += $fileInput
                            
                                } catch {
                            
                                    Write-Host "Error encountered while reading profile names from file."
                            
                                }
                        
                            } else {
                            
                                Write-Host "File not found."
                            
                            }
                    
                        }

                        Default {
                    
                            Write-Host "Invalid selection."
                    
                        }

                    }

                }
            
                cls 
                Break
            
            }
            
            Default {

                Write-Host "`r`nInvalid command."

            }
        
        }
    
    }

}

