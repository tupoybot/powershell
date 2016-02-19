# VM vhd, snapshots and memory size
# Alexey Kharichev, Smart Solutions, 2016
# http://it.kg.ru


$vmtotalmem = 0
$vmtotalhdd = 0
$snapshotshdd = 0 
$snapshotscount = 0
$vmtotalsize = 0
$vmtotalCPU = 0

$hvtotalmem = 0
$avhdd = 0
$avmem = 0
$hvtotalhdd = 0 
$totalsan = 0
$avsan = 0
$hvtotalCPU = 0

$str = @()

$hosts =  Get-SCVMHost

Write-Host ("VMs with snapshots:")
Write-Host
    
foreach ($hst in $hosts) {        
    $hvtotalhdd += ($hst.LocalStorageTotalCapacity -as [double]) / 1TB
    $avhdd += ($hst.LocalStorageAvailableCapacity  -as [double]) / 1TB    
    $hvtotalmem += ($hst.TotalMemory -as [double]) / 1GB
    $avmem += ($hst.AvailableMemory -as [double]) / 1KB
    $hvtotalCPU += ($hst.LogicalCPUCount)

    $vmCPU = 0
    $vms =  Get-SCVirtualMachine  | where {$_.HostID -eq $hst.ID}
        foreach ($vm in $vms) {   
            $vhds = $vm.VirtualHardDisks    
            foreach ($vhd in $vhds) { $vmtotalhdd += ($vhd.Size -as [double]) / 1GB}  
    
            # Snapshots search
            foreach ($vmc in $vm.VMCheckpoints) {
                $snapshotscount++
                $vm.VMCheckpoints.VM.Name
                foreach ($vdd in $vmc.VirtualDiskDrives) {
                    $vhd = Get-SCVirtualHardDisk -ID $vdd.VirtualHardDiskID
                    $snapshotshdd += ($vhd.Size -as [double]) / 1GB 
            
                }
                        }
   
    $vmCPU += $vm.CPUCount
    $vmtotalCPU += $vm.CPUCount
    $vmtotalmem += ($vm.MemoryAssignedMB  -as [double]) / 1KB
    $vmtotalsize += ($vm.TotalSize  -as [double]) / 1GB    

    }
$str += $hst.Name + ": " + $vmCPU + " / " +  $hst.LogicalCPUCount + " = " + "{0:N2}" -f ($vmCPU/($hst.LogicalCPUCount))
}
$hvc = Get-SCVMHostCluster
$totalsan = ($hvc.SharedVolumes[0].Capacity -as [double]) / 1TB
$avsan = ($hvc.SharedVolumes[0].FreeSpace -as [double]) / 1TB



# Data output



$hashv = @{
"1. Total VHD assigned: " = "{0:N2} GB" -f $vmtotalhdd; 
"2. Total RAM assigned: " = "{0:N2} GB" -f $vmtotalmem;
"3. Snapshots count: " = "{0:N0}" -f $snapshotscount; 
"4. Snapshots HDD: " = "{0:N2} GB" -f $snapshotshdd;
"5. Total storage used: " = "{0:N2} GB" -f $vmtotalsize
}

Write-Host

Write-Host ("VMs stat:")
$hashv.GetEnumerator()  |sort Name | ft -HideTableHeaders

Write-Host
$hashv = @{
"1. Total local storage: " = "{0:N2} TB" -f $hvtotalhdd; 
"2. Available local storage: " = "{0:N2} TB" -f $avhdd; 
"3. Total remote storage: " = "{0:N2} TB" -f $totalsan;
"4. Available remote storage: " = "{0:N2} TB" -f $avsan;
"5. Total RAM: " = "{0:N2} GB" -f $hvtotalmem;
"6. Available RAM: " = "{0:N2} GB" -f $avmem
}

Write-Host ("Hosts stat:")
$hashv.GetEnumerator()  |sort Name | ft -HideTableHeaders
Write-Host ("Virtualization ratio:")
$str |sort
Write-Host ("Farm:", $vmtotalCPU,"/",  $hvtotalCPU, "=", ($vmtotalCPU/($hvtotalCPU)))
 

Read-Host

