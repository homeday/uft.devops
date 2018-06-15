export GOVC_URL=$vCenterServer
export GOVC_USERNAME=$vCenterAccount
export GOVC_PASSWORD=$vCenterPassword
export GOVC_INSECURE=true
export GOVC_GUEST_LOGIN="appsadmin:appsadmin"


VM_NAME=$1
VM_Template=$2

wait_for_vm_guest_tool_on() 
{
    machine=$1
    COUNTER=0
    ret=1
    while [ $COUNTER -lt 10 ] && [ ${ret} -ne 0 ] ; do
        ./govc guest.ls -vm $VM_NAME "C:\\"
        ret=$?
        let COUNTER=$COUNTER+1
        sleep 30
    done
    if [ "$ret" == "0" ]; then
        return 0
    fi
    return 1
}

wait_for_vm_power_state() 
{
    machine=$1
    expected=$2
    actual=""
    COUNTER=0
    while [ $COUNTER -lt 10 ] && [ "${actual}" != "${expected}" ] ; do
        actual=$(./govc.exe vm.info -json ${machine} | jq -r .VirtualMachines[0].Runtime.PowerState)
        echo "the power stat of the machine ${machine} is ${actual}"
        let COUNTER=$COUNTER+1
        sleep 30
    done

    if  [ "${actual}" == "${expected}" ]; then
        return 0
    fi 
    return 1
}

vmcount=$(./govc.exe find -json . -type m -name $VM_NAME | jq length)
if [ $vmcount -gt 0 ]; then
    echo "removing machine ${VM_NAME}"
    ./govc.exe vm.destroy $VM_NAME
    sleep 30
fi

vmcount=$(./govc.exe find -json . -type m -name $VM_NAME | jq length)
if [ $vmcount -ne 0 ] ; then
    echo "removing machine ${VM_NAME} is not successful"
    exit 1
fi

echo "cloning machine ${VM_NAME}"
./govc.exe vm.clone -vm $VM_Template -ds="SHCADMLUN08_GSTS_3PAR" -folder="DEVOPS" -host="shcappsesx03.hpeswlab.net" -on=true $VM_NAME
sleep 30
vmcount=$(./govc.exe find -json . -type m -name $VM_NAME | jq length)
if [ $vmcount -eq 0 ]; then
    echo "the machine is not created successfully!"
    exit 2
fi

wait_for_vm_guest_tool_on $VM_NAME 
ret=$?
if [ "0" != "$ret" ]; then
    ./govc.exe vm.power -on=true $VM_NAME
    wait_for_vm_guest_tool_on $VM_NAME 
    if [ "0" != "$ret" ]; then
        echo "$VM_NAME is not powered on after created!"
        exit 3
    fi
fi

echo "changing the pc name of machine ${VM_NAME}"
pid=$(./govc.exe guest.start -vm $VM_NAME cmd.exe "/c wmic path win32_computersystem where Name='%computername%' CALL rename name='${VM_NAME}'")
status=$(./govc.exe guest.ps -json -vm ${VM_NAME} -p ${pid} -X | jq .ProcessInfo[].ExitCode)
echo "exit code of name changing process is ${status}"
if [ "0" != "${status}" ]; then
    echo "changing name operation is not successed!"
    exit 3
fi

echo "rebooting the machine ${VM_NAME} after its name is changed"
./govc.exe vm.power -r=true $VM_NAME
sleep 10
wait_for_vm_guest_tool_on $VM_NAME 
echo "shut down the machine ${VM_NAME} before creating the snapshot"
./govc.exe vm.power -s=true $VM_NAME
wait_for_vm_power_state $VM_NAME "poweredOff"
ret=$?
if [ "0" != "$ret" ]; then
    echo "$VM_NAME is not powered off!"
    exit 2
fi
./govc snapshot.create -vm=${VM_NAME} "${VM_NAME}_Snapshot" 
echo "power on the machine ${VM_NAME} after creating the snapshot"
./govc.exe vm.power -on=true $VM_NAME
wait_for_vm_guest_tool_on $VM_NAME 
exit 0











