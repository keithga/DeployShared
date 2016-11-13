function get-VMBiosGuid ( $VM )
{

    $newVM = get-VM $VM

    if ( -not $NewVM ) { throw "Virtual Machine not found!" }

    (get-wmiobject -Namespace "Root\virtualization\v2" -class Msvm_VirtualSystemSettingData -Property BIOSGUID -Filter ("InstanceID = 'Microsoft:{0}'" -f $NewVM.VMId.Guid)).BIOSGUID.SubString(1,36) | Out-Default

}

