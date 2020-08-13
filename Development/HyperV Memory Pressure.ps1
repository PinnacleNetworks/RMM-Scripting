# This script checks the memory allocation and demand on a vm and flags status if the VM is overloaded or critically low on available memory
$VMs = Get-VM
foreach ($VM in $VMs)
{
    #Check if the VM is running
    if ($VM.State -ne "Running") {Continue}
    #Check if the VM is over demand
    if ($VM.MemoryAssigned -le $VM.MemoryDemand) {$critical = "yes"} {Continue}
    #Check if the VM has less than 5% available memory
    $MemoryUtilization = ($VM.MemoryDemand / $VM.MemoryAssigned * 100)
    $MemoryPercentageFree = 100 - $MemoryUtilization
    if ($MemoryPercentageFree -le 5) {$warning = "yes"}
}
