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

urlEncode() {
  printf %s "$1" | jq -s -R -r @uri
}


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
rm -rf /home/trojan-go/caddy/Caddyfile
cat > /home/trojan-go/caddy/Caddyfile <<-EOF
${your_domain}:80 {
    root /usr/src/trojan
    log /usr/src/caddy.log
    index index.html
}
${your_domain}:443 {
    root /usr/src/trojan
    log /usr/src/caddy.log
    index index.html
}
EOF


rm -rf /home/trojan-go/config.json
cat > /home/trojan-go/config.json <<-EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 443,
  "remote_addr": "__DOCKER_CADDY__",
  "remote_port": 80,
  "password": [
        "$trojan_passwd"
  ],
  "log_level": 1,
  "log_file": "../trojan.log",
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
	  "h2",
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
    "enabled": true,
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
    "geoip": "$PROGRAM_DIR$/geoip.dat",
    "geosite": "$PROGRAM_DIR$/geosite.dat"
  },
  "websocket": {
    "enabled": $enable_websocket,
    "path": "$websocket_path",
    "hostname": "$websocket_host"
  },
  "shadowsocks": {
    "enabled": $enable_ss,
    "method": "$ss_method",
    "password": "$ss_password"
  },
  "transport_plugin": {
    "enabled": $enable_tp,
    "type": "$plugin_type",
    "command": "",
    "plugin_option": "$plugin_option",
    "arg": [],
    "env": []
  },
  "forward_proxy": {
    "enabled": $forward_proxy,
    "proxy_addr": "$proxy_addr",
    "proxy_port": $proxy_port,
    "username": "$username",
    "password": "$password"
  },
  "mysql": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 3306,
    "database": "trojan",
    "username": "root",
    "password": "Eh65cCDX8ARl",
    "check_rate": 30
  },
  "redis": {
    "enabled": false,
    "server_addr": "localhost",
    "server_port": 6379,
    "password": ""
  },
  "api": {
    "enabled": false,
    "api_addr": "127.0.0.1",
    "api_port": 10000,
    "ssl": {
      "enabled": false,
      "key": "",
      "cert": "",
      "verify_client": false,
      "client_cert": []
    }
  }
}
EOF

if [ $? = 0 ]; then
    docker-compose up -d 
	
	if [ "$enable_websocket" == "true" ];then
	$ws="ws=1"
	else
	$ws="ws=0"
	fi
	
	green "======================================================================"
	green "Trojan installation complete"
	blue "Domain:$your_domain"
	blue "Password: $trojan_passwd"
	blue "Port: 443"
	blue "Server Name: $server_name"
	if [ "$enable_websocket" == "true" ];then
	blue "Websocket Path:$websocket_path"
	blue "Websocket Hostname: $websocket_host"
	fi
	echo "======================================================================"
	echo "Trojan URI"
	green "trojan://$trojan_passwd@$your_domain:443?allowinsecure=0&tfo=0&sni=$your_domain&mux=1&$ws&wss=0&wsPath=$websocket_path&wsHostname=$websocket_host&wsObfsPassword=&group=#$server_name"
	echo "Trojan-GO URI"
	green "trojan://$trojan_passwd@$your_domain:443?peer=#$(urlEncode "$server_name")"
	echo "======================================================================"
	if [ "$enable_ss" == "true" ];then
	blue "Shadowsocks Method: $ss_method"
	blue "Shadowsocks Password: $ss_password"
	if [ "$plugin_type" == "shadowsocks" ];then
	blue "Shadowsocks SIP003 Plug-in: $plugin_option"
	fi
	echo "======================================================================"
	fi
	if [ "$forward_proxy" == "true" ];then
	blue "Socks5 Address: $proxy_addr"
	blue "Socks5 Port : $proxy_port "
	blue "Socks5 Username: $username "
	blue "Socks5 Password: $password "
	echo "======================================================================"
	fi
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
	$systemPackage -y install  git python-tools python-pip
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
    
    green "Please enter the password of the trojan server"
    read -p "(There is no default value please make sure you input the right thing):" trojan_passwd
    echo
    echo "---------------------------"
    echo "Trojan Password = ${trojan_passwd}"
    echo "---------------------------"
    echo
    
    green "Please enter the sever remarks"
    read -p "(There is no default value please make sure you input the right thing):" server_name
    echo
    echo "---------------------------"
    echo "Trojan Server Name = ${server_name}"
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
    
    green "Enable Shadowsocks"
    read -p "(Default : false 'true/false'):" enable_ss
    if [ -z "$enable_ss" ];then
	enable_ss="false"
	fi
    echo
    echo "---------------------------"
    echo "Enable Shadowsocks = $enable_ss"
    echo "---------------------------"
    echo  
    
    if [ "$enable_ss" == "true" ];then
	green "Shadowsocks Method"
    read -p "(Default : AES-128-GCM 'CHACHA20-IETF-POLY1305 / AES-128-GCM / AES-256-GCM'):" ss_method
    if [ -z "$ss_method" ];then
	ss_method="AES-128-GCM"
	fi
    echo
    echo "---------------------------"
    echo "Shadowsocks Method = $ss_method"
    echo "---------------------------"
    echo 
	
	
    green "Shadowsocks Password"
    read -p "(Default Password: zCR&3n*E7dut#1^tu$ ):" ss_password
    if [ -z "$ss_password" ];then
	ss_password="zCR&3n*E7dut#1^tu$"
	fi
    echo
    echo "---------------------------"
    echo "Shadowsocks Password = $ss_password"
    echo "---------------------------"
    echo 
    
    green "Enable Transport Plugin"
    read -p "(Default : false 'false/true'):" enable_tp
    if [ -z "$enable_tp" ];then
	enable_tp="false"
	fi
    echo
    echo "---------------------------"
    echo "Enable Transport Plugin = $enable_tp"
    echo "---------------------------"
    echo 
    
    if [ "$enable_tp" == "true" ];then
	
	green "Plugin Type"
    read -p "(Default : plaintext 'shadowsocks / plaintext / other' ):" plugin_type
    if [ -z "$plugin_type" ];then
	plugin_type="plaintext"
	fi
    echo
    echo "---------------------------"
    echo "Plugin Option = $plugin_type"
    echo "---------------------------"
    echo 
	
	
	if [ "$plugin_type" == "shadowsocks" ];then
    green "Plugin Option"
    read -p "(Default : obfs=http;obfs-host=www.baidu.com ):" plugin_option
    if [ -z "$plugin_option" ];then 
	plugin_option="obfs=http;obfs-host=www.baidu.com"
	fi
    echo
    echo "---------------------------"
    echo "Plugin Option = $plugin_option"
    echo "---------------------------"
    echo
	
	fi
    fi
    fi
    
    green "Enable Forward Proxy (socks5)"
    read -p "(Default : false  'false/true'):" forward_proxy
    if [ -z "$forward_proxy" ];then
	forward_proxy="false"
	fi
    echo
    echo "---------------------------"
    echo "Enable Forward Proxy(socks5) = $forward_proxy"
    echo "---------------------------"
    echo 
    
    if [ "$forward_proxy" == "true" ];then
    green "Proxy Address"
    read -p "(Default : ${your_domain} ):" proxy_addr
    if [ -z "$proxy_addr" ];then
	proxy_addr="$your_domain"
	fi
    echo
    echo "---------------------------"
    echo "Proxy Address = $proxy_addr"
    echo "---------------------------"
    echo 
    
    green "Proxy Port"
    read -p "(Default : 1080 ):" proxy_port
    if [ -z "$proxy_port" ];then
	proxy_port="1080"
	fi
    echo
    echo "---------------------------"
    echo "Proxy Port = $proxy_port"
    echo "---------------------------"
    echo 
    
    green "Username"
    read -p "(Default :  ):" username
    echo
    echo "---------------------------"
    echo "Username = $username"
    echo "---------------------------"
    echo 
    
    green "Password"
    read -p "(Default :  ):" password
    echo
    echo "---------------------------"
    echo "Password = $password"
    echo "---------------------------"
    echo 
    fi
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

