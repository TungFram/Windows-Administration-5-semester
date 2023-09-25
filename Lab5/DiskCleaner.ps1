Write-Host "Hello, this is a disk cleaner programm."
Write-Host "Choose a disk:"
$(Get-Disk | Where-Object {$_.BusType -eq "SATA"} | Select-Object Number).Number

Write-Host "`nWhich disk you want to clear?"
$diskNumber = Read-Host 
Write-Host "`nAre you sure?`nAll data will be disapeared. [Y/N]"
$option = Read-Host 
if ($option -eq "Y" -or $option -eq "y") {
    $disk = Get-Disk | Where-Object {$_.Number -eq $diskNumber}
    try {
        Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false
    }
    catch {
        Write-Host "$($disk.Location)"
        Write-Host "$($disk.Path)"
    }
    # Set-Disk -Number $disk.Number -IsReadOnly $false -IsOffline $false
    Set-Partition -Number $disk.Number -IsReadOnly:$false -IsActive:$true
    Clear-Disk -Number $disk.Number -RemoveData -RemoveOEM -Confirm:$false
    Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false
    New-Partition -DiskNumber $diskNumber -DriveLetter T -UseMaximumSize
    Format-Volume -DriveLetter T -FileSystem NTFS -NewFileSystemLabel "Lab5Part2Task8" -Confirm:$false
    # Set-Partition -DriveLetter T -IsActive:$true

    Repair-Volume -DriveLetter T -OfflineScanAndFix
    Get-Volume -DriveLetter T
}
else {
    break
}













