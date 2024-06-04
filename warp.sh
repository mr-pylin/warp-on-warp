#!/bin/bash

# colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

case "$(uname -m)" in
x86_64 | x64 | amd64)
	cpu=amd64
	;;
i386 | i686)
	cpu=386
	;;
armv8 | armv8l | arm64 | aarch64)
	cpu=arm64
	;;
armv7l)
	cpu=arm
	;;
*)
	echo -e "The current architecture is ${RED}$(uname -m)${RESET}, temporarily not supported"
	exit
	;;
esac

# load subnets from subnets_v4.txt
IFS=$'\n' readarray -t subnets_v4 < <(curl -s "https://raw.githubusercontent.com/mr-pylin/warp-on-warp/main/subnets_v4.txt" | grep -v '^#' | grep -v '^[[:space:]]*$' | cut -d '/' -f 1 | cut -d '.' -f 1-3)

total_possible_ips=$((${#subnets_v4[@]} * 256))
min_possible_ips=$((total_possible_ips / 256))
max_possible_ips=$((total_possible_ips / 8))

min_configs=1
max_configs=50

cfwarpIP() {
	echo "download warp endpoint file base on your CPU architecture"
	if [[ -n $cpu ]]; then
		curl -L -o warpendpoint -# --retry 2 https://raw.githubusercontent.com/mr-pylin/warp-on-warp/main/endpoint/$cpu
	fi
}

endipv4() {
	num_ips=$1

	# check the range of IPs
	if [[ ${num_ips} -lt ${min_possible_ips} ]]; then
		num_ips=${min_possible_ips}
	elif [[ ${num_ips} -gt ${max_possible_ips} ]]; then
		num_ips=${max_possible_ips}
	fi

	declare -ag distinct_ips

	while [[ ${#distinct_ips[@]} -lt $num_ips ]]; do

		for ip in "${subnets_v4[@]}"; do

			if [[ ${#distinct_ips[@]} == $num_ips ]]; then
				break
			fi

			random_ip=$(echo ${ip}.$((RANDOM % 256)))

			if [[ ! "${distinct_ips[@]}" =~ "$random_ip" ]]; then
				distinct_ips+=("$random_ip")
			fi

		done
	done
}

endipresult() {
	num_configs=$1

	# write random distinct IPs into a txt file
	for ip in "${distinct_ips[@]}"; do
		echo "$ip" >>"ip.txt"
	done

	ulimit -n 102400
	chmod +x warpendpoint
	./warpendpoint

	clear
	echo -e "${GREEN}Successfully generated ipv4 endip list${RESET}"
	echo "--------------------------------------------------"
	echo -e "${CYAN}Processing result.csv and requesting for keys from zeroteam.top${RESET}"

	process_result_csv $num_configs 0

	rm -rf ip.txt warpendpoint result.csv warp.json
	exit
}

get_values() {
	local api_output=$(curl -sL "https://api.zeroteam.top/warp?format=sing-box")
	local ipv6=$(echo "$api_output" | grep -oE '"2606:4700:[0-9a-f:]+/128"' | sed 's/"//g')
	local private_key=$(echo "$api_output" | grep -oE '"private_key":"[0-9a-zA-Z\/+]+=+"' | sed 's/"private_key":"//; s/"//')
	local public_key=$(echo "$api_output" | grep -oE '"peer_public_key":"[0-9a-zA-Z\/+]+=+"' | sed 's/"peer_public_key":"//; s/"//')
	local reserved=$(echo "$api_output" | grep -oE '"reserved":\[[0-9]+(,[0-9]+){2}\]' | sed 's/"reserved"://; s/\[//; s/\]//')
	echo "$ipv6@$private_key@$public_key@$reserved"
}

process_result_csv() {
	num_configs=$1
	use_default_ip_port=$2

	# default IP & PORT
	local ip="engage.cloudflareclient.com"
	local port=2408

	# check the range of IPs
	if [[ ${num_configs} -lt ${min_configs} ]]; then
		num_configs=${min_configs}
	elif [[ ${num_configs} -gt ${max_configs} ]]; then
		num_configs=${max_configs}
	fi

	echo ""
	echo "This step might take some time based on how many configs you ordered:"
	echo ""

	# loop over result.csv IPs
	names=""
	counter=0
	for ((i = 2; i <= $((num_configs + 1)); i++)); do

		if [ "$use_default_ip_port" -eq 0 ]; then
			# extract each line
			local line=$(sed -n "${i}p" ./result.csv)

			# extract DELAY and filter DELAY >= 1000
			local delay=$(echo "$line" | awk -F',' '{gsub(/ ms/, "", $3); print $3}')
			if [[ "$delay" -lt 1000 ]]; then

				# extract ip:port
				local endpoint=$(echo "$line" | awk -F',' '{print $1}')
				local ip=$(echo "$endpoint" | awk -F':' '{print $1}')
				local port=$(echo "$endpoint" | awk -F':' '{print $2}')

				values=$(get_values)
				w_ip=$(echo "$values" | cut -d'@' -f1)
				w_pv=$(echo "$values" | cut -d'@' -f2)
				w_pb=$(echo "$values" | cut -d'@' -f3)
				w_res=$(echo "$values" | cut -d'@' -f4)

				i_values=$(get_values)
				i_w_ip=$(echo "$i_values" | cut -d'@' -f1)
				i_w_pv=$(echo "$i_values" | cut -d'@' -f2)
				i_w_pb=$(echo "$i_values" | cut -d'@' -f3)
				i_w_res=$(echo "$i_values" | cut -d'@' -f4)

			else
				continue
			fi

		else
			values=$(get_values)
			w_ip=$(echo "$values" | cut -d'@' -f1)
			w_pv=$(echo "$values" | cut -d'@' -f2)
			w_pb=$(echo "$values" | cut -d'@' -f3)
			w_res=$(echo "$values" | cut -d'@' -f4)

			i_values=$(get_values)
			i_w_ip=$(echo "$i_values" | cut -d'@' -f1)
			i_w_pv=$(echo "$i_values" | cut -d'@' -f2)
			i_w_pb=$(echo "$i_values" | cut -d'@' -f3)
			i_w_res=$(echo "$i_values" | cut -d'@' -f4)

		fi

		counter=$((counter + 1))
		echo -e "${YELLOW}config $((counter)) -> DONE.${RESET}"

		new_json='{
		"type": "wireguard",
		"tag": "National_'$((i - 1))'",
		"server": "'"$ip"'",
		"server_port": '"$port"',
		"local_address": ["172.16.0.2/32","'"$w_ip"'"],
		"private_key": "'"$w_pv"'",
		"peer_public_key": "'"$w_pb"'",
		"reserved": ['$w_res'],
		"mtu": '$(echo $((1280 + RANDOM % 51)))',
		"fake_packets": "2-7",
		"fake_packets_size": "40-100",
		"fake_packets_delay": "20-250"
		},{
		"type": "wireguard",
		"tag": "Warp-on-Warp_'$((i - 1))'",
		"detour": "National_'$((i - 1))'",
		"server": "'"$ip"'",
		"server_port": '"$port"',
		"local_address": ["172.16.0.2/32","'"$i_w_ip"'"],
		"private_key": "'"$i_w_pv"'",
		"peer_public_key": "'"$i_w_pb"'",
		"reserved": ['$i_w_res'],  
		"mtu": '$(echo $((1120 + RANDOM % 161)))'
		},'

		names+="\"National_$((i - 1))\","
		names+="\"Warp-on-Warp_$((i - 1))\","

		config_json+="$new_json"
	done

	echo ""
	echo -e "${GREEN}${counter}${RESET} clean alive IPs found."

	if [ "$counter" -gt "$num_configs" ]; then
		echo -e "${RED}Warning:${RESET} you have requested ${GREEN}${num_configs}${RESET} configs but only ${YELLOW}${counter}${RESET} alive configs found."
		echo -e "${CYAN}Need more?:${RESET} try using a bigger number for scanning IPs"
	fi

	# remove the last trailing comma
	config_json="${config_json%,}"
	names=$(echo "${names}" | sed 's/,$//')

	# complete the json data
	full_json='{
"dns": {
	"servers": [
	{
		"tag": "dns-remote",
		"address": "udp://1.1.1.1",
		"address_resolver": "dns-direct"
	},{
		"tag": "dns-trick-direct",
		"address": "https://sky.rethinkdns.com/",
		"detour": "direct-fragment"
	},{
		"tag": "dns-direct",
		"address": "1.1.1.1",
		"address_resolver": "dns-local",
		"detour": "direct"
	},{
		"tag": "dns-local",
		"address": "local",
		"detour": "direct"
	},{
		"tag": "dns-block",
		"address": "rcode://success"
	}
	],
	"rules": [
	{
		"domain_suffix": ".ir",
		"geosite": "ir",
		"server": "dns-direct"
	},{
		"domain": "cp.cloudflare.com",
		"server": "dns-remote",
		"rewrite_ttl": 3000
	}
	],
	"final": "dns-remote",
	"static_ips": {
	"sky.rethinkdns.com": [
		"104.17.147.22",
		"104.17.148.22",
		"141.101.75.111",
		"162.159.83.123",
		"162.159.178.7",
		"162.159.221.99",
		"188.114.97.3",
		"188.114.96.3",
		"2400:cb01:3131::111",
		"2a06:98c1:3121::3",
		"2a06:98c1:3120::3"
	]
	},
	"independent_cache": true
},
"inbounds": [
	{
		"type": "tun",
		"tag": "tun-in",
		"mtu": 9000,
		"inet4_address": "172.19.0.1/28",
		"auto_route": true,
		"strict_route": true,
		"endpoint_independent_nat": true,
		"stack": "mixed",
		"sniff": true,
		"sniff_override_destination": true
	},{
		"type": "mixed",
		"tag": "mixed-in",
		"listen": "127.0.0.1",
		"listen_port": 2334,
		"sniff": true,
		"sniff_override_destination": true
	},{
		"type": "direct",
		"tag": "dns-in",
		"listen": "127.0.0.1",
		"listen_port": 6450
	}
],
"outbounds": 
	[
		{
			"type": "selector",
			"tag": "select",
			"outbounds": [
			"auto",
			'${names}'
			],
			"default": "auto"
		},{
			"type": "urltest",
			"tag": "auto",
			"outbounds": [
			'${names}'
			],
			"url": "http://cp.cloudflare.com/",
			"interval": "10m0s",
			"idle_timeout": "1h40m0s"
		},
		'"$config_json"',
		{
			"type": "dns",
			"tag": "dns-out"
		},{
			"type": "direct",
			"tag": "direct"
		},{
			"type": "direct",
			"tag": "direct-fragment",
			"tls_fragment": {
			"enabled": true,
			"size": "1-500",
			"sleep": "0-500"
			}
		},{
			"type": "direct",
			"tag": "bypass"
		},{
			"type": "block",
			"tag": "block"
		}
	],
"route": {
	"geoip": {"path": "geo-assets/sagernet-sing-geoip-geoip.db"},
	"geosite": {"path": "geo-assets/sagernet-sing-geosite-geosite.db"},
	"rules": [
		{
			"inbound": "dns-in",
			"outbound": "dns-out"
		},{
			"port": 53,
			"outbound": "dns-out"
		},{
			"clash_mode": "Direct",
			"outbound": "direct"
		},{
			"clash_mode": "Global",
			"outbound": "select"
		},{
			"domain_suffix": ".ir",
			"geosite": "ir",
			"geoip": "ir",
			"outbound": "bypass"
		}
		],
		"final": "select",
		"auto_detect_interface": true,
		"override_android_vpn": true
	}
}'

	echo "$full_json" >warp.json
	echo "--------------------------------------------------"
	echo -e "${GREEN}Your link:${RESET}"
	curl https://bashupload.com/warp.json --data-binary @warp.json | sed -e "s#wget#Your Link:#"
}

menu() {
	clear
	echo -e "Architecture: ${YELLOW}$(uname -m)${RESET}"
	echo "--------------------- Menu -----------------------"
	echo -e "1.Automatic IP scanning ${GREEN}(Android / Linux / Mac)${RESET}"
	echo -e "2.Import custom IPs from result.csv ${GREEN}(windows)${RESET}"
	read -rp "Choose an option [e.g. 1]: " option
	echo ""

	if [ "$option" = "1" ]; then
		echo -e "Number of IPs to scan (min:${min_possible_ips}, max:${max_possible_ips})\nNote: type ${GREEN}0${RESET} to use ${GREEN}engage.cloudflareclient.com:2408${RESET}"
		read -rp $"Number of IPs [500 is recommended]: " number_of_ips
		echo ""

		read -rp $"Number of configurations (min:${min_configs}, max:${max_configs}) [10 is recommended]: " number_of_configs
		clear

		if [ "$number_of_ips" -ne 0 ]; then
			cfwarpIP
			endipv4 $number_of_ips
			endipresult $number_of_configs
		else
			process_result_csv $number_of_configs 1
		fi
	elif [ "$option" = "2" ]; then
		read -rep $"Number of configurations (min:${min_configs}, max:${max_configs}) [10 is recommended]: " number_of_configs
		process_result_csv $number_of_configs 0
	else
		echo "Invalid option"
	fi
}

menu
