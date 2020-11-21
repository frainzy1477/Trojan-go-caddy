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


osRelease=""
osSystemPackage=""
osSystemmdPath=""

function getLinuxOSVersion(){
    if [[  -d /etc/systemd/system/ ]] & [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemmdPath="/etc/systemd/system/"
    elif [[ -f /etc/redhat-release ]]; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemmdPath="/usr/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemmdPath="/usr/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "debian"; then
        osRelease="debian"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        osRelease="ubuntu"
        osSystemPackage="apt-get"
        osSystemmdPath="/lib/systemd/system/"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        osRelease="centos"
        osSystemPackage="yum"
        osSystemmdPath="/usr/lib/systemd/system/"
    fi
    echo "OS info: ${osRelease}, ${osSystemPackage}, ${osSystemmdPath}"
}


function checkport(){
	Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
	Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
	if [ -n "$Port80" ]; then
	    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
	    echo "==========================================================="
	    red "It is detected that port 80 is occupied, the occupation process is:${process80}，This installation is cancelled"
	    echo "==========================================================="
	    exit 1
	fi
	if [ -n "$Port443" ]; then
	    process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
	    echo "============================================================="
	    red "It is detected that port 443 is occupied, the occupation process is：${process443}，This installation is cancelled"
	    echo "============================================================="
	    exit 1
	fi
}


function update_trojan(){
	getLinuxOSVersion
	systemctl stop trojan-go-*
	systemctl daemon-reload
	
	cd /etc/trojan-go
	rm -rf trojan-go geosite.dat geoip.dat
	mkdir -p /tmp/trojan-go 
	cd /tmp/trojan-go
	version=`wget -qO- https://github.com/frainzy1477/t-go/tags | grep "/frainzy1477/t-go/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`
	wget https://github.com/frainzy1477/t-go/releases/download/$version/trojan-go-linux-amd64.zip
	unzip trojan-go-linux-amd64
	cp /tmp/trojan-go/trojan-go /etc/trojan-go/
	chmod +x /etc/trojan-go/trojan-go
	rm -rf /tmp/trojan-go >/dev/null 2>&1
	
	cd /etc/trojan-go
	wget https://raw.githubusercontent.com/v2fly/geoip/release/geoip.dat
	wget https://raw.githubusercontent.com/v2fly/domain-list-community/release/dlc.dat -O geosite.dat
	
	
        systemctl restart trojan-go-*
	systemctl daemon-reload
	systemctl status trojan-go-*
	trojanversion=`/etc/trojan-go/trojan-go -version | awk '{print $2}' | sed -n 1P`
	green "======================================================================"
	green "UPDATE COMPLETED"
	green "TROJAN-GO VERSION : ${trojanversion}"
	echo "======================================================================"
}

function install_trojan(){

	getLinuxOSVersion

	checkport

	pre_install  

	if [ "$osRelease" == "centos" ]; then
		if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ; then
		    red "==============="
		    red "System not suppotred"
		    red "==============="
		    exit
		fi

		if  [ -n "$(grep ' 5\.' /etc/redhat-release)" ] ; then
		    red "==============="
		    red "System not suppotred"
		    red "==============="
		    exit
		fi

		sudo systemctl stop firewalld
		sudo systemctl disable firewalld
		rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
		$osSystemPackage update -y
		$osSystemPackage install epel-release curl wget git python-tools unzip zip tar socat -y
		$osSystemPackage install xz -y
		$osSystemPackage install iputils-ping -y

	elif [ "$osRelease" == "ubuntu" ]; then
		if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
		    red "==============="
		    red "System not suppotred"
		    red "==============="
		    exit
		fi
		if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
		    red "==============="
		    red "System not suppotred"
		    red "==============="
		    exit
		fi

		sudo systemctl stop ufw
		sudo systemctl disable ufw
		$osSystemPackage update -y
		$osSystemPackage install curl wget python-tools git unzip zip tar socat -y
		$osSystemPackage install xz-utils -y
		$osSystemPackage install iputils-ping -y
	fi
	    
	rm -rf /tmp/trojan-go 

	if [ ! -d /etc/trojan-go ];then
		mkdir -p /etc/trojan-go
	fi

	mkdir -p /tmp/trojan-go 
	cd /tmp/trojan-go
	version=`wget -qO- https://github.com/frainzy1477/t-go/tags | grep "/frainzy1477/t-go/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`
	wget https://github.com/frainzy1477/t-go/releases/download/$version/trojan-go-linux-amd64.zip
	unzip trojan-go-linux-amd64
	cp /tmp/trojan-go/trojan-go /etc/trojan-go/
	chmod +x /etc/trojan-go/trojan-go
	rm -rf /tmp/trojan-go >/dev/null 2>&1

	cd /etc/trojan-go
	wget https://raw.githubusercontent.com/v2fly/geoip/release/geoip.dat
	wget https://raw.githubusercontent.com/v2fly/domain-list-community/release/dlc.dat -O geosite.dat

	cd /etc/trojan-go

	if [ ! -f /root/.acme/acme.sh ];then
	    curl -sL https://get.acme.sh | bash
	fi

	bash /root/.acme/acme.sh --issue -d $your_domain  --standalone --force
	bash /root/.acme/acme.sh --installcert -d $your_domain --fullchainpath /etc/trojan-go/fullchain.crt --keypath /etc/trojan-go/privkey.key
	
if [ "$enable_websocket" == "true" ];then

	checkDocker=$(which docker)
	checkDockerCompose=$(which docker-compose)

	if [ "$checkDocker" == "" ]; then
		install_docker
	fi

	if [ "$checkDockerCompose" == "" ]; then
		install_docker_compose
	fi

	wget https://raw.githubusercontent.com/frainzy1477/t-go/master/Caddyfile

cat > /etc/trojan-go/docker-compose.yml <<-EOF
version: '2'

services:
  caddy:
    image: frainzy1477/caddyy
    restart: always
    environment:
      - ACME_AGREE=false
      - TROJAN_DOMAIN=$websocket_host
      - TROJAN_PATH=$websocket_path
      - TROJAN_PORT=$trojan_port
      - TROJAN_OUTSIDE_PORT=80
    network_mode: "host"
    volumes:
      - ./.caddy:/root/.caddy
      - ./Caddyfile:/etc/Caddyfile
EOF

fi

firewall_allow

if [ ! -f ${osSystemmdPath}trojan-go-${your_domain}.service ];then	
touch ${osSystemmdPath}trojan-go-${your_domain}.service
cat >${osSystemmdPath}trojan-go-${your_domain}.service << EOF
[Unit]
Description=trojan-go
Documentation=https://github.com/p4gefau1t/trojan-go
After=network.target nss-lookup.target

[Service]
Type=simple
StandardError=journal
PIDFile=/etc/trojan-go/trojan.pid
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/trojan-go/trojan-go -config /etc/trojan-go/${your_domain}.json
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/etc/trojan-go/trojan-go
LimitNOFILE=51200
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target  
EOF
fi

  

rm -rf /etc/trojan-go/$your_domain.json 2>/dev/null
cat > /etc/trojan-go/$your_domain.json <<-EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": $trojan_port,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": [],
  "log_level": 1,
  "buffer_size": 32,
  "dns": ["8.8.8.8","1.1.1.1"],
  "disable_http_check": true,
  "udp_timeout": 60,
  "ssl": {
    "verify": true,
    "verify_hostname": true,
    "cert": "/etc/trojan-go/fullchain.crt",
    "key": "/etc/trojan-go/privkey.key",
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
    "fallback_addr": "www.cloudflare.com",
    "fallback_port": 443,
    "fingerprint": "firefox"
  },
  "tcp": {
    "no_delay": true,
    "keep_alive": true,
    "prefer_ipv4": true
  },
  "mux": {
    "enabled": $enable_mux,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "router": {
    "enabled": true,
    "default_policy": "proxy",
    "domain_strategy": "as_is",
    "geoip": "/etc/trojan-go/geoip.dat",
    "geosite": "/etc/trojan-go/geosite.dat"
  },
  "websocket": {
    "enabled": $enable_websocket,
    "path": "$websocket_path",
    "hostname": "$websocket_host"
  },
  "webapi":{
    "enabled": $enable_webapi,
    "node_id":   $node_id,
    "panelUrl": "$panelurl",
    "panelKey": "$panelkey",
    "check_rate": $check_rate,
    "speedtest_hours": $speedtest_hours
  } 
}
EOF

if [ $? = 0 ]; then
	if [ "$enable_websocket" == "true" ];then
	docker-compose up -d
	sleep 5
	fi
	
	trojanversion=`/etc/trojan-go/trojan-go -version | awk '{print $2}' | sed -n 1P`
	
	systemctl daemon-reload
	systemctl enable trojan-go-$your_domain
        systemctl restart trojan-go-$your_domain
	systemctl daemon-reload
	systemctl status trojan-go-$your_domain
	
	green "======================================================================"
	green "INSTALLATION COMPLETED"
	green "TROJAN-GO VERSION : ${trojanversion}"
	echo "======================================================================"
fi	


}

function firewall_allow(){
	systemctl stop firewalld
	systemctl mask firewalld
	osSystemPackage install iptables-services -y
	chkconfig iptables on
	iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT 
	iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT 
	iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport $trojan_port -j ACCEPT 
	iptables -A INPUT -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT 
	iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
	systemctl restart iptables
}

function install_docker(){
	curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
	systemctl start docker
	systemctl enable docker
	usermod -aG docker $USER
}

function install_docker_compose(){
        curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose     
}

pre_install(){   
 
    green "Please enter the domain name bound to this VPS"
    read -p "(There is no default value please make sure you input the right thing):" your_domain
    echo
    echo "---------------------------"
    echo "Domain Name = $your_domain"
    echo "---------------------------"
    echo
    
    green "Trojan-GO Port"
    read -p "(Default : 443):" trojan_port
    if [ -z "$trojan_port" ];then 
	trojan_port="443"
	fi
    echo
    echo "---------------------------"
    echo "Trojan-GO Port = $trojan_port"
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
    read -p "(Default Path: /):" websocket_path
    if [ -z "${websocket_path}" ];then
	websocket_path="/"
	fi
    echo
    echo "---------------------------"
    echo "Websocket Path = $websocket_path"
    echo "---------------------------"
    echo 
    
    green "Websocket Hostname"
    read -p "(Default Hostname: ${your_domain} or your cdn address here):" websocket_host
    if [ -z "$websocket_host" ];then
	websocket_host="$your_domain"
	fi
    echo
    echo "---------------------------"
    echo "Websocket Hostname = $websocket_host"
    echo "---------------------------"
    echo     
    fi

    green "Enable WebAPI"
    read -p "(Default : true 'true/false'):" enable_webapi
    if [ -z "$enable_webapi" ];then 
	enable_webapi="true"
	fi
    echo
    echo "---------------------------"
    echo "Enable WebAPI = $enable_webapi"
    echo "---------------------------"
    echo
    
    if [ "$enable_webapi" == "true" ];then
    
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
    echo "Node Id = $node_id"
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
    
    green "Speedtest"
    read -p "(Default : 1 ):" speedtest_hours
    if [ -z "$speedtest_hours" ];then
	speedtest_hours=1
	fi
    echo
    echo "---------------------------"
    echo "Speedtest = $speedtest_hours"
    echo "---------------------------"
    echo
    
    fi
    
}   

start_menu(){
    clear
    echo " ======================================= "
    green " Introduction: One-click installation trojan-go/ss-panel "
    green " Supported Systems： centos7+/7.x/8.x+ & ubuntu 16.04/18.04/19.10/20.04"
    blue " Statement："
    green " *Please do not use this script in any production environment"
    green " *Please do not have other programs occupying ports 80 and 443 "
    echo " ======================================= "
    echo
    green " 1. Install trojan-go"
    green " 2. Update trojan-go"
    red " 0. Quit"
    echo
    read -p "Please enter the number:" num
    case "$num" in
    1)
    install_trojan
    ;;
    2)
    update_trojan
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
