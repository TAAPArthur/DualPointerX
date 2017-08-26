#!/bin/bash

########TODO move vars to config file and replace with sane defaults
masters=("Wado Ichimonji" "Sandai Kitetsu" "Yubashiri" "Hana Arashi" "Shusui")


originalKeyboardMaster="3"
originalMouseMaster="2"

originalInputs=("Virtual core pointer" "Virtual core XTEST pointer" "SynPS/2 Synaptics TouchPad" "Virtual core keyboard" "Virtual core XTEST keyboard" "Power Button" "Video Bus" "Power Button" "Sleep Button" "HID 413c:8161" "Laptop_Integrated_Webcam_2M" "AT Translated Set 2 keyboard" "Dell WMI hotkeys")
###################
TYPE_MOUSE=1
TYPE_KEYBOARD=2
TARGET_ALL=0
TARGET_MOVING=1
quiet=false

isNonOriginalInput(){
    i="$1"
    for input in "${originalInputs[@]}"
    do
        if [ "$i" == "$input" ]; then 
            return 1
        fi
    done
    return 0
}

getDeviceType(){
    deviceID="$1"
    target="$2"
    deviceName=$(xinput list --name-only "$deviceID")
    deviceInfo=$(xinput --list "$deviceID")
    
    type=0
    if echo "$deviceInfo" |grep -q "Button"; then
        type=$TYPE_MOUSE
    elif echo "$deviceInfo" |grep -q "Key" ; then
        type=$TYPE_KEYBOARD          
    fi
    if [[ $deviceName != *"XTEST"* ]] && echo $deviceInfo |grep -q "slave" && isNonOriginalInput "$deviceName" ; then
    	if [ $target -eq $TARGET_ALL ]; then
		    return $type        
		   
		else ##TODO better method for only moving currently-in-use mouse/keyboard. 
			master=$(echo "$deviceInfo" |grep -Po "slave\\s*(keyboard|pointer)\\s*\\(\\K[0-9]+")
			if [[ ! $master ]]; then
				return 0
			elif [[ $master -eq originalMouseMaster || $master -eq originalKeyboardMaster ]]; then
				return $type
			elif [ $target -eq $TARGET_MOVING ] && ((read -t .1 info) < <(xinput test "$deviceID")); then
				echo active "master $master device $deviceName $info"
				return $type
			fi
		fi
    fi
    return 0
}
attach(){
    device="$1"
    host="$2"
    #echo "xinput reattach $device $host"
    xinput reattach "$device" "$host"
    
}
dualWield() {
	if [[ "$1" ]]; then
		masterName="$1"
	    $quiet && notify-send "entering poly wield mode - $masterName"
	else 
    	masterName="$masters"
		$quiet && notify-send "entering dual wield mode"
	fi
	echo "ready"

	##TODO need option for target moving
	target=$TARGET_MOVING
    miceToEnslave=()
    keyboardsToEnslave=()
    while read -r deviceId; do
       getDeviceType "$deviceId" $target
       type=$?
        if [[ $type -eq $TYPE_MOUSE ]]; then
            miceToEnslave+=("$deviceId");
        elif [[ $type -eq $TYPE_KEYBOARD ]]; then
            keyboardsToEnslave+=("$deviceId");
        fi                
    done < <(xinput list --id-only | cut -d" " -f2)
    
    echo "createig master"
    xinput create-master "$masterName"

    for device in "${miceToEnslave[@]}"; do
        attach "$device" "$masterName pointer"
    done
    for device in "${keyboardsToEnslave[@]}"; do
        attach "$device" "$masterName keyboard"
    done

}
singleWield() {
    notify-send "exiting dual wield mode"
    for name in "${masters[@]}"; do
		xinput remove-master "$name pointer" AttachToMaster "$originalMouseMaster" &>/dev/null
	done
	# xinput |grep -Po "id=(\K[0-9]+)+\s*\[master pointer" |grep -Po "[0-9]+"

}
noWield(){
	#not working
	echo "option should not be used"
	notify-send "entering no wield mode"
	xinput remove-master "$originalMouseMaster"
}

nextMaster() {
	for name in "${masters[@]}"; do
		#xinput list --name-only |grep "$name" &>/dev/null;
	    if ! xinput --query-state "$name XTEST keyboard" &>/dev/null; then 
	    	echo "$name"
	    	return 0;
    	fi
	done
	return 1;
}

main() {

	numberOfMasterDevices=$(($(xinput |grep -c master)/2))
	if [[ "$1" == "-q" || "$1" == "--quiet" ]]; then
		quiet=1;
		shift;
	fi

##TODO need help message (-h/--help) when given invalid args
    echo "$numberOfMasterDevices master pair"
    if [[ "$1" == "-r" || "$1" == "resume" ]]; then
    	
		if [[ $numberOfMasterDevices > 1 ]]; then
			notify-send "resuming"
			singleWield 
			dualWield
		fi
    elif [ "$numberOfMasterDevices" -eq 1 ]; then
        dualWield
    else
    	if [[ "$1" == "poly" ]] || [[ "$1" == "polywield" ]]; then
			dualWield "$(nextMaster)"
    	else
                singleWield
        fi
    fi
	if [[ "$1" == "nowield" ]]; then
		noWield
	fi
}

main "$1"
