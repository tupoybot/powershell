# VM vhd, snapshots and memory size
# Alexey Kharichev, Smart Solutions, 2015
# http://it.kg.ru

$vms =  Get-SCVirtualMachine  #| where {$_.Name -eq "srv-git-01"} # For debug
$totalmem = 0
$totalhdd = 0
$snapshotshdd = 0 
$snapshotscount = 0
$totalsize = 0

Write-Host ("VMs with snapshots:")
Write-Host

foreach ($vm in $vms) {   
    $vhds = $vm.VirtualHardDisks    
    foreach ($vhd in $vhds) { $totalhdd += ($vhd.Size -as [double]) / 1TB}  
    
    # Snapshots search
    foreach ($vmc in $vm.VMCheckpoints) {
        $snapshotscount++
        $vm.VMCheckpoints.VM.Name
        foreach ($vdd in $vmc.VirtualDiskDrives) {
            $vhd = Get-SCVirtualHardDisk -ID $vdd.VirtualHardDiskID
            $snapshotshdd += ($vhd.Size -as [double]) / 1TB 
            
        }
    }
   

    $totalmem += ($vm.MemoryAssignedMB  -as [double]) / 1KB
    $totalsize += ($vm.TotalSize  -as [double]) / 1TB

}

$hashv = @{
"1. Total VHD assigned: " = "{0:N2} TB" -f $totalhdd; 
"2. Total RAM assigned: " = "{0:N2} GB" -f $totalmem;
"3. Snapshots count: " = "{0:N0}" -f $snapshotscount; 
"4. Snapshots HDD: " = "{0:N2} TB" -f $snapshotshdd;
"5. Total storage used: " = "{0:N2} TB" -f $totalsize
}

Write-Host
Write-Host ("VMs stat:")
$hashv.GetEnumerator()  |sort Name | ft -HideTableHeaders


$hosts =  Get-SCVMHost  | where {$_.Name -ne "hv-demo.kg.ru"}
$totalmem = 0
$avhdd = 0
$avmem = 0
$totalhdd = 0 
$totalsan = 0
$avsan = 0
foreach ($hst in $hosts) {        
    $totalhdd += ($hst.LocalStorageTotalCapacity -as [double]) / 1TB
    $avhdd += ($hst.LocalStorageAvailableCapacity  -as [double]) / 1TB    
    $totalmem += ($hst.TotalMemory -as [double]) / 1GB
    $avmem += ($hst.AvailableMemory -as [double]) / 1KB
}
$hvc = Get-SCVMHostCluster
$totalsan = ($hvc.SharedVolumes[0].Capacity -as [double]) / 1TB
$avsan = ($hvc.SharedVolumes[0].FreeSpace -as [double]) / 1TB

Write-Host
 
$hashv = @{
"1. Total local storage: " = "{0:N2} TB" -f $totalhdd; 
"2. Available local storage: " = "{0:N2} TB" -f $avhdd; 
"3. Total remote storage: " = "{0:N2} TB" -f $totalsan;
"4. Available remote storage: " = "{0:N2} TB" -f $avsan;
"5. Total RAM: " = "{0:N2} GB" -f $totalmem;
"6. Available RAM: " = "{0:N2} GB" -f $avmem
}

Write-Host ("Hosts stat:")
$hashv.GetEnumerator()  |sort Name | ft -HideTableHeaders

Read-Host

