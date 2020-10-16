<#
  Filename: CheckAllVHDUsage_v1.0.ps1
  Author: Kelvin Kam (https://github.com/KelvinKam)
  Description: Check all VHD usage in Azure Files
  Version: 1.0
  Last Updated: 2020-10-16
#>

#Notes
#Administrator privilege required for this script
#You need to login to azure-admin instead of domain users if running on WVD host

#Initial
$AzureFilesConnected = $false
$OutputPath = "VHDUsageReport.csv"
$DiskLetter = "B:"
If (Test-Path $OutputPath){
    Write-Host -ForegroundColor Red "Clearing $OutputPath... (Ctrl+C to abort)"
    Start-Sleep 5
    Clear-Content $OutputPath
}
"Path,TotalFreeBytesInMB,TotalBytesInMB" | Add-Content -Path $OutputPath

#Before mount VHD disk path
$BeforeMountVHD = Get-Partition | select AccessPaths

#Connect to Azure Files
#Cleanup existing Azure Files connection
$null = net use $DiskLetter /delete 2>$null
#Scan all VHD in specific location
$AzureFilesLocation = Read-Host("Please enter Azure Files location: ")
$VaultCredential = Get-Credential -Message "Please enter Vault credential"
$UserName = $VaultCredential.UserName
$Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VaultCredential.Password))

#$PSDrive = New-PSDrive -Name "AzureFiles" -PSProvider FileSystem -Root $AzureFilesLocation -Credential $VaultCredential
Write-Host -ForegroundColor Cyan "Connecting to Azure Files... "
#$null = New-PSDrive -Name "AzureFiles" -PSProvider FileSystem -Root $AzureFilesLocation -Scope Global
$Connection = net use $DiskLetter $AzureFilesLocation /user:$UserName $Password 2>$null

#Check is Azure File connection works
If($Connection -eq "The command completed successfully."){
    $AzureFilesConnected = $true
}

#Main script
If($AzureFilesConnected -eq $true){
    Write-Host -ForegroundColor Cyan "Connected to Azure Files ($AzureFilesLocation)"
    #Loop files
    foreach ($File in Get-ChildItem $DiskLetter -Recurse)
        {
            If ($File -like "*.vhd" -or $File -like "*.vhdx"){
                #Cleanup
                $Output = $null
                $FileFullName = $null
                $MountedVHD = $null
                $TotalFreeBytesInMB = $null
                $TotalBytesInMB = $null
                $Temp1 = $null
                $Temp2 = $null
                $error.clear()

                #Mount VHD
                $FileFullName = $File.FullName
                $DisplayFileFullName = $FileFullName -replace "$DiskLetter\\"
                $Temp1 = $FileFullName -replace "$DiskLetter\\"
                $Output+= "$Temp1,"
                Write-Host -ForegroundColor Yellow "Mounting VHD... $FileFullName"
                Start-Sleep 2
                $MountedVHD = ("Select vdisk file = $FileFullName","attach vdisk readonly") | diskpart
                #Write-Host $MountedVHD
                <#Try{
                    Mount-VHD -ReadOnly -Path $FileFullName -NoDriveLetter -ErrorAction:SilentlyContinue
                }Catch{
                    #Catch is not working here
                }#>
                
                If($MountedVHD -like "*DiskPart successfully attached the virtual disk file.*"){
                    $AfterMountVHD = Get-Partition | select AccessPaths
                    #Write-Host -ForegroundColor Yellow "Mounted VHD... $FileFullName"

                    #Real VHD path
                    $RealVHDPath = Compare-Object -ReferenceObject $BeforeMountVHD -DifferenceObject $AfterMountVHD -Property AccessPaths
                    $RealVHDPath = $RealVHDPath.AccessPaths

                    #Get VHD usage
                    $VHDUsage = fsutil volume diskfree $RealVHDPath
                    If($VHDUsage -like "*(*"){
                        $Temp1 = $VHDUsage[0].IndexOf(":") + 1
                        $Temp2 = $VHDUsage[0].IndexOf("(")
                        $TotalFreeBytes = $VHDUsage[0].Substring($Temp1,$Temp2-$Temp1).Trim()
                        $TotalFreeBytes = $TotalFreeBytes.Replace(",",$null).ToInt64($null)
                        $TotalFreeBytesInMB = [math]::Round($TotalFreeBytes / 1024 / 1024,3)
                        $Output += "$TotalFreeBytesInMB,"

                        $Temp1 = $VHDUsage[1].IndexOf(":") + 1
                        $Temp2 = $VHDUsage[1].IndexOf("(")
                        $TotalBytes = $VHDUsage[1].Substring($Temp1,$Temp2-$Temp1).Trim()
                        $TotalBytes = $TotalBytes.Replace(",",$null).ToInt64($null)
                        $TotalBytesInMB = [math]::Round($TotalBytes / 1024 / 1024,3)
                        $Output += "$TotalBytesInMB"
                    }else{
                        $Temp1 = $VHDUsage[0].IndexOf(":") + 1
                        $TotalFreeBytes = $VHDUsage[0].Substring($Temp1).Trim()
                        $TotalFreeBytes = $TotalFreeBytes.Replace(",",$null).ToInt64($null)
                        $TotalFreeBytesInMB = [math]::Round($TotalFreeBytes / 1024 / 1024,3)
                        $Output += "$TotalFreeBytesInMB,"

                        $Temp1 = $VHDUsage[1].IndexOf(":") + 1
                        $TotalBytes = $VHDUsage[1].Substring($Temp1).Trim()
                        $TotalBytes = $TotalBytes.Replace(",",$null).ToInt64($null)
                        $TotalBytesInMB = [math]::Round($TotalBytes / 1024 / 1024,3)
                        $Output += "$TotalBytesInMB"
                    }
                    Write-Host -ForegroundColor Yellow "Dismounting VHD... $FileFullName"
                    #Dismount-VHD -Path $FileFullName
                    $null = ("Select vdisk file = $FileFullName","detach vdisk") | diskpart

                    $Output | Add-Content -Path $OutputPath
                }else{
                    Write-Host -ForegroundColor Red "Ignored VHD... $FileFullName"
                    $Output | Add-Content -Path $OutputPath
                }
            }
        }
}
#Disconnect Azure Files
Write-Host -ForegroundColor Cyan "Disconnect from Azure Files ($AzureFilesLocation)"
$null = net use $DiskLetter /delete 2>$null
Write-Host -ForegroundColor Green "Script completed"