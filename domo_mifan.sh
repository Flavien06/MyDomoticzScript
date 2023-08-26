#!/bin/bash
# INSTALL 1ST :
# https://github.com/rytilahti/python-miio
# pip install python-miio

## MI HOME ##
ip="192.168.x.xx"
token="xxxxxxxxxxxxxxx"

## DOMOTICZ ##
url_base="http://127.0.0.1:8080/json.htm"
# Create 11 "Light/Swith" on domoticz : and call "script:///home/pi/domo_mifan.sh <action>"

idx_power=xxx			#On/Off		action on: "on"					Action Off: "off"				
idx_mode=xxx			#On/Off		action on: "set_mod nature"		Action Off: "set_mod normal"		
idx_oscillate=xxx		#On/Off		action on: "set_oscillate on"	Action Off: "set_oscillate off"				 
idx_led=xxx				#On/Off		action on: "set_led on"			Action Off: "set_led off"
idx_buzzer=xxx			#On/Off		action on: "set_buzzer on"		Action Off: "set_buzzer off"
idx_lock=xxx			#On/Off		action on: "set_child_lock on"	Action Off: "set_child_lock off"

idx_speedpourcent=xxx	#Dimmer		action on: "domo_spc"		Action Off: "domo_spc"	
idx_timer=xxx			#Dimmer		action on: "domo_timer"		Action Off: "domo_timer"

idx_angle=xxx			#Selector (Hide Off) 	10=30° : "set_angle 30" / 20=60° : "set_angle 60"  / 30=90° : "set_angle 90"  / 40=120° : "set_angle 120"  / 50=140° : "set_angle 140" 
idx_speed=xxx			#Selector (Hide Off) 	10=Speed1 : "1" / 20=Speed2 : "2" / 40=Speed3 : "2" / 50=Speed4 : "3"
idx_turn=xxx			#Selector (Hide Off) 	10=Left : "set_rotate left" / 20=Right : "set_rotate right"
#############

function domoticz_update() {
    case $value in 
		"on" | "Nature" | "True" )  value_domo="1" ;;
		"off" | "Normal" | "False" ) value_domo="0" ;;
	esac
	url_update="$url_base?type=command&param=udevice&idx=$idx&nvalue=$value_domo&svalue="
	curl -s -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET "$url_update" > /dev/null
}
function domoticz_updatespeed() {
	if [ $value -ge 1 ] && [ $value -lt 15 ]; then #Speed 1
		value_domo="10"
	elif [ $value -ge 15 ] && [ $value -lt 50 ]; then #Speed 2
		value_domo="20"
	elif [ $value -ge 50 ] && [ $value -lt 85 ]; then #Speed 3
		value_domo="30"
	elif [ $value -ge 85 ] && [ $value -le 100 ]; then #Speed 4
		value_domo="40"
	fi
	url_updatelevel="$url_base?type=command&param=udevice&idx=$idx&svalue=$value_domo"
	curl -s -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET "$url_updatelevel" > /dev/null
}
function domoticz_updatepourcent() {
	domo_svalue=$value
	if [[ $domo_svalue == "0" ]]; then
		url_updatelevel="$url_base?type=command&param=udevice&idx=$idx&nvalue=1&svalue=1"
		curl -s -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET "$url_updatelevel" #> /dev/null
		domo_nvalue="0"
	else domo_nvalue="1"
	fi
	url_updatelevel="$url_base?type=command&param=udevice&idx=$idx&nvalue=$domo_nvalue&svalue=$domo_svalue"
	curl -s -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET "$url_updatelevel" #> /dev/null
}
function domoticz_updateangle() {
    case $value in 
		"0" | "left" | "right" )   value_domo="0" ;;
		"30" )  value_domo="10" ;;
		"60" )  value_domo="20" ;;
		"90" )  value_domo="30" ;;
        "120" ) value_domo="40" ;;
        "140" ) value_domo="50" ;;
	esac
	url_updatelevel="$url_base?type=command&param=udevice&idx=$idx&svalue=$value_domo"
	curl -s -i -H "Accept: application/json" -H "Content-Type: application/json" -X GET "$url_updatelevel" > /dev/null
}


action=$1
value=$2

case $action in 
	"info" | "update" | "i" | "u")
		# Exécute la commande miiocli et stocke la sortie dans une variable
		result=$(miiocli fanmiot --ip $ip --token $token status)

		# Fonction pour extraire la valeur d'une clé spécifique
		extract_value() {
			echo "$result" | grep -o "$1: [^ ]*" | cut -d' ' -f2-
		}

		# Extraire les valeurs
		power=$(extract_value "Power")
		operation_mode=$(extract_value "Operation mode" | sed 's/mode: OperationMode\.//')
		speed=$(extract_value "Speed")
		oscillate=$(extract_value "Oscillate")
		angle=$(extract_value "Angle")
		led=$(extract_value "LED")
		buzzer=$(extract_value "Buzzer")
		child_lock=$(extract_value "Child lock" | sed 's/lock: //')
		power_off_time=$(extract_value "Power-off time" | sed 's/time: //')

		# Affiche les valeurs pour vérification et ajout dans domoticz
		echo "Power: $power"					&& idx=$idx_power 			&& value=$power 			&& domoticz_update
		echo "Operation mode: $operation_mode"  && idx=$idx_mode 			&& value=$operation_mode 	&& domoticz_update
		echo "Speed: $speed"					&& idx=$idx_speed 			&& value=$speed 			&& domoticz_updatespeed
												   idx=$idx_speedpourcent 	&& value=$speed 			&& domoticz_updatepourcent
		echo "Oscillate: $oscillate"			&& idx=$idx_oscillate 		&& value=$oscillate			&& domoticz_update
		echo "Angle: $angle"					&& idx=$idx_angle 			&& value=$angle				&& domoticz_updateangle
		echo "LED: $led"						&& idx=$idx_led 			&& value=$led 				&& domoticz_update
		echo "Buzzer: $buzzer"					&& idx=$idx_buzzer 			&& value=$buzzer 			&& domoticz_update
		echo "Child lock: $child_lock"			&& idx=$idx_lock 			&& value=$child_lock		&& domoticz_update
		echo "Power-off time: $power_off_time"	&& idx=$idx_timer 			&& value=$power_off_time	&& domoticz_updatepourcent
		exit 0
	 ;;
	 
 	"power" | "on" | "off") # Supported values: on, off
		case $action in 
			"on")  value="on"  ;;
			"off") value="off" ;;
		esac
		set_action=""
		idx=$idx_power && domoticz_update ;;
	"set_mod" | "mode") # Supported values: nature, normal
		set_action="set_mod"
		idx=$idx_mode && domoticz_update ;;
	"set_angle" | "angle") # Supported values: 30, 60, 90, 120, 140
		set_action="set_angle"
		idx=$idx_angle && domoticz_updateangle ;;

 	"set_buzzer" | "buzzer" ) # Supported values: on, off
		set_action="set_buzzer"
		idx=$idx_buzzer && domoticz_update ;;
 	"set_led" | "led" ) # Supported values: on, off
		set_action="set_led"
		idx=$idx_led && domoticz_update ;;
	"set_child_lock" | "lock" ) # Supported values: on, off
		set_action="set_child_lock"
		idx=$idx_lock && domoticz_update ;;	
	"set_oscillate" | "oscillate" ) # Supported values: on, off
		set_action="set_oscillate"
		idx=$idx_oscillate && domoticz_update ;;


	"set_speed" | "speed" | "1" | "2" | "3"| "4") # Supported values: min 1 to max 100 /   1 is 1   2 is 35  /  3 is 70  / 4 is 100
		case $action in 
			"1") value="1"   ;;
			"2") value="35"  ;;
			"3") value="70"  ;;
			"4") value="100" ;;
		esac
		set_action="set_speed"
		idx=$idx_speed 			&& domoticz_updatespeed
		idx=$idx_speedpourcent 	&& domoticz_updatepourcent
	;;
	
	"domo_spc" )
		idx=$idx_speedpourcent
		url_id="$url_base?type=command&param=getdevices&rid=$idx"
		value=$(curl -s "$url_id" | jq -r '.result[].Data | sub("Set Level: "; "") | sub(" %"; "")')
		case $value in 
			"On")	value="100"	&& domoticz_updatepourcent ;;
			"Off")	value="1"	&& domoticz_updatepourcent ;;
		esac
		set_action="set_speed"
		idx=$idx_speed 			&& domoticz_updatespeed
	;;
	
	
	"delay_off" | "timer" ) # Supported values: min 1mim to max 480mim (8h)
		set_action="delay_off"
		if [[ $value == *h ]]; then
			value="${value%h}"
			value=$((value * 60))
		elif [[ $value == "off" ]] || [[ $value == "Off" ]]; then
			value="0"
		fi
		echo "timer of $value min"
		idx=$idx_timer 	&& domoticz_updatepourcent
	;;
		

	"domo_timer" )
		idx=$idx_timer
		url_id="$url_base?type=command&param=getdevices&rid=$idx"
		value=$(curl -s "$url_id" | jq -r '.result[].Data | sub("Set Level: "; "") | sub(" %"; "")')
		case $value in 
			"On")	value="100"	&& domoticz_updatepourcent ;;
			"Off")	value="0"	&& domoticz_updatepourcent ;;
		esac
		set_action="delay_off"
	;;

		
	"set_rotate" | "rotate" | "gauche" | "droit" | "droite" ) # Supported values: left, right
		case $action in 
			"gauche")  				value="left"  ;;
			"droit" | "droite") 	value="right" ;;
		esac
		set_action="set_rotate"
		# Vérifie si l'argument est un chiffre
		if [[ $2 =~ ^[0-9]+$ ]]; then
			loop_rotate=$2
		elif [[ $3 =~ ^[0-9]+$ ]]; then
			loop_rotate=$3
		else
			loop_rotate=1
		fi
		# Boucle for qui s'exécute loop_rotate fois
		for ((i = 1; i <= loop_rotate; i++)); do
			miiocli fanmiot --ip $ip --token $token $set_action $value
		done
		idx=$idx_turn && domoticz_updateangle
		exit 0		
		;;	
	
	*)
		echo "error : domo_mifan.sh $1 $2 $3"
		exit 1
	
esac


miiocli fanmiot --ip $ip --token $token $set_action $value


exit 0
