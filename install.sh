#!/bin/bash
blue(){  
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}


function install_trojan(){

    green "Enter system type By number [1]centos [2]debian/ubuntu "
    read -p "(Default : 1   ):" system_type
    if [ -z "$systemPackage" ];then
	system_type="1"
	fi
	if [ "$system_type" == "1" ];then
	systemPackage="yum"
	elif [ "$system_type" == "2" ];then
	systemPackage="apt-get"
	fi
	
systemctl stop firewalld
systemctl mask firewalld

yum install iptables-services -y
chkconfig iptables on
systemctl start iptables

Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
if [ -n "$Port80" ]; then
    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
    echo "==========================================================="
    red "It is detected that port 80 is occupied, the occupation process is:${process80}，This installation is over"
    echo "==========================================================="
    exit 1
fi
if [ -n "$Port443" ]; then
    process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
    echo "============================================================="
    red "It is detected that port 443 is occupied, the occupation process is：${process443}，This installation is over"
    echo "============================================================="
    exit 1
fi

  
pre_install_docker_compose   
   
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`


if [ $real_addr == $local_addr ] ; then
	echo "=========================================="
	green "Domain name resolution is normal, start installation trojan"
	echo "=========================================="
	sleep 1s
	
$systemPackage -y install curl git  >/dev/null 2>&1

checkDocker=$(which docker)
checkDockerCompose=$(which docker-compose)
if [ "$checkDocker" == "" ]; then
install_docker
fi
if [ "$checkDockerCompose" == "" ]; then
install_docker_compose
fi

wait
docker-compose down
wait
docker-compose stop

rm -rf /etc/trojan-go/Caddyfile 2>/dev/null

cat > /etc/trojan-go/Caddyfile <<-EOF
${your_domain}:80 {
    root /usr/src/trojan
    log /usr/src/caddy.log
    index index.html
    proxy ${websocket_path} 127.0.0.1:${$port} {
     websocket
     header_upstream -Origin
    }
    gzip    
}
${your_domain}:443 {
    root /usr/src/trojan
    log /usr/src/caddy.log
    index index.html
    proxy ${websocket_path} 127.0.0.1:${$port} {
     websocket
     header_upstream -Origin
    }
    gzip
    tls
}
EOF

rm -rf /etc/trojan-go/docker-compose.yml 2>/dev/null
cat > /etc/trojan-go/docker-compose.yml <<-EOF
version: '2'

services:
  caddy:
      image: frainzy1477/caddy
      ports:
        - "80:80"
      restart: always
      volumes:
        - ./wwwroot:/usr/src
        - ./ssl:/root/.caddy/acme/acme-v02.api.letsencrypt.org/sites
        - ./Caddyfile:/etc/Caddyfile
        - /etc/localtime:/etc/localtime:ro
        - /etc/timezone:/etc/timezone:ro
  trojan:
      image: frainzy1477/trojan-go:plugin
      restart: always
      ports:
        - "$port:$port"
      volumes:
        - /etc/trojan-go:/etc/trojan-go
        - ./ssl:/ssl
        - /etc/localtime:/etc/localtime:ro
        - /etc/timezone:/etc/timezone:ro
      links:
        - caddy:__DOCKER_CADDY__
      depends_on: 
          - caddy
EOF


rm -rf /etc/trojan-go/config.json 2>/dev/null
cat > /etc/trojan-go/config.json <<-EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": $port,
  "remote_addr": "__DOCKER_CADDY__",
  "remote_port": 80,
  "password": [],
  "log_level": 1,
  "buffer_size": 32,
  "dns": ["8.8.8.8","1.1.1.1"],
  "disable_http_check": false,
  "udp_timeout": 30,
  "ssl": {
    "verify": true,
    "verify_hostname": true,
    "cert": "../ssl/$your_domain/$your_domain.crt",
    "key": "../ssl/$your_domain/$your_domain.key",
    "key_password": "",
    "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
    "curves": "",
    "prefer_server_cipher": false,
    "sni": "$your_domain",
    "alpn": [
      "http/1.1"
    ],
    "session_ticket": true,
    "reuse_session": true,
    "plain_http_response": "tcp",
    "fallback_addr": "$your_domain",
    "fallback_port": 443,
    "fingerprint": "firefox"
  },
  "tcp": {
    "no_delay": true,
    "keep_alive": true,
    "prefer_ipv4": false
  },
  "mux": {
    "enabled": $enable_mux,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "router": {
    "enabled": false,
    "bypass": [],
    "proxy": [],
    "block": [],
    "default_policy": "proxy",
    "domain_strategy": "as_is",
    "geoip": "$/geoip.dat",
    "geosite": "$/geosite.dat"
  },
  "websocket": {
    "enabled": $enable_websocket,
    "path": "$websocket_path",
    "hostname": "$websocket_host"
  },
  "webapi":{
    "enabled": true, 
    "node_id":   $node_id,
    "panelUrl": "$panelurl",
    "panelKey": "$panelkey",
    "check_rate": $check_rate,
    "speedtestRate": $speedtestRate
  }
}
EOF

if [ $? = 0 ]; then
	green "======================================================================"
	green "Trojan installation complete"
	green "Run docker-compose up to start server"
	blue "Run docker-compose pull to update server"
	red "Run docker-compose down to stop server"
	echo "======================================================================"
fi	
else
	echo "================================"
	red "The domain name resolution address is inconsistent with this VPS IP address"
	red "This installation failed, please make sure the domain name resolution is normal"
	echo "================================"
fi

}


function install_docker(){

curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
systemctl start docker
systemctl enable docker
usermod -aG docker $USER

}

function install_docker_compose(){

	
	$systemPackage install -y epel-release
 	$systemPackage -y update
	$systemPackage -y install  git python-tools python-pip curl wget unzip zip
	wait
    curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose     
}




pre_install_docker_compose(){   
 
    green "Please enter the domain name bound to this VPS"
    read -p "(There is no default value please make sure you input the right thing):" your_domain
    echo
    echo "---------------------------"
    echo "Domain Name = $your_domain"
    echo "---------------------------"
    echo

    green "Trojan Listening Port"
    read -p "(Default : 443 ):" port
    if [ -z "$port" ];then
	port=443
	fi
    echo
    echo "---------------------------"
    echo "Trojan Listening Port = $port"
    echo "---------------------------"
    echo 
    
    green "Enable Mux"
    read -p "(Default : false 'true/false'):" enable_mux
    if [ -z "$enable_mux" ];then 
	enable_mux="false"
	fi
    echo
    echo "---------------------------"
    echo "Enable Mux = $enable_mux"
    echo "---------------------------"
    echo
    
    
    green "Enable websocket"
    read -p "(Default : false 'true/false'):" enable_websocket
    if [ -z "$enable_websocket" ];then 
	enable_websocket="false"
	fi
    echo
    echo "---------------------------"
    echo "Enable websocket = $enable_websocket"
    echo "---------------------------"
    echo
    
    if [ "$enable_websocket" == "true" ];then
    green "Websocket Path"
    read -p "(Default Path: /trojan):" websocket_path
    if [ -z "${websocket_path}" ];then
	websocket_path="/trojan"
	fi
    echo
    echo "---------------------------"
    echo "Websocket Path = $websocket_path"
    echo "---------------------------"
    echo 
    
    green "Websocket Hostname"
    read -p "(Default Hostname: ${your_domain}):" websocket_host
    if [ -z "$websocket_host" ];then
	websocket_host="$your_domain"
	fi
    echo
    echo "---------------------------"
    echo "Websocket Hostname = $websocket_host"
    echo "---------------------------"
    echo     
    fi
    
    green "PanelUrl"
    read -p "(Default : No default value):" panelurl
    echo
    echo "---------------------------"
    echo "PanelUrl = $panelurl"
    echo "---------------------------"
    echo 
	
	
    green "PanelKey"
    read -p "(Default: No default value):" panelkey
    echo
    echo "---------------------------"
    echo "PanelKey = $panelkey"
    echo "---------------------------"
    echo 
    
    green "Node Id"
    read -p "(Default : 1 ):" node_id
    if [ -z "$node_id" ];then
	node_id=1
	fi
    echo
    echo "---------------------------"
    echo "Enable Transport Plugin = $node_id"
    echo "---------------------------"
    echo 
    
    green "Check Rate"
    read -p "(Default : 60 ):" check_rate
    if [ -z "$check_rate" ];then
	check_rate=60
	fi
    echo
    echo "---------------------------"
    echo "Check Rate = $check_rate"
    echo "---------------------------"
    echo 
    
    green "SpeedtestRate"
    read -p "(Default : 6 ):" speedtestRate
    if [ -z "$speedtestRate" ];then
	speedtestRate=6
	fi
    echo
    echo "---------------------------"
    echo "SpeedtestRate = $speedtestRate"
    echo "---------------------------"
    echo 



}   

start_menu(){
    clear
    echo " ======================================= "
    green " Introduction: One-click installation trojan "
    green " System： centos7+/debian9+/ubuntu16.04+ "
    blue " Statement："
    green " *Please do not use this script in any production environment"
    green " *Please do not have other programs occupying ports 80 and 443 "
    echo " ======================================= "
    echo
    green " 1. Install trojan/caddy server "
    red " 0. Quit"
    echo
    read -p "Please enter the number:" num
    case "$num" in
    1)
    install_trojan
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "Please enter the correct number"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu

