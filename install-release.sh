#!/bin/bash

# This file is accessible as https://install.direct/go.sh


# If not specify, default meaning of return value:
# 0: Success
# 1: System error
# 2: Application error
# 3: Network error

CUR_VER=""
NEW_VER=""
ARCH=""
VDIS="64"
ZIPFILE="/tmp/trojan-go/trojan-go.zip"
TROJAN_RUNNING=0
VSRC_ROOT="/tmp/trojan-go"
EXTRACT_ONLY=0
ERROR_IF_UPTODATE=0

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

SYSTEMCTL_CMD=$(command -v systemctl 2>/dev/null)
SERVICE_CMD=$(command -v service 2>/dev/null)

CHECK=""
FORCE=""
HELP=""

#######color code########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message


#########################
while [[ $# > 0 ]];do
    key="$1"
    case $key in
        -p|--proxy)
        PROXY="-x ${2}"
        shift # past argument
        ;;
        -h|--help)
        HELP="1"
        ;;
        -f|--force)
        FORCE="1"
        ;;
        --remove)
        REMOVE="1"
        ;;
        --extract)
        VSRC_ROOT="$2"
        shift
        ;;
        --extractonly)
        EXTRACT_ONLY="1"
        ;;
        -l|--local)
        LOCAL="$2"
        LOCAL_INSTALL="1"
        shift
        ;;
        --panelUrl)
        PANELURL="$2"
        ;;
        --panelKey)
        PANELKEY="$2"
        ;;
        --nodeid)
        NODEID="$2"
        ;;		
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done

###############################
colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

sysArch(){
    ARCH=$(uname -m)
    if [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "i386" ]]; then
        VDIS="32"
    elif [[ "$ARCH" == *"armv7"* ]] || [[ "$ARCH" == "armv6l" ]]; then
        VDIS="arm"
    elif [[ "$ARCH" == *"armv8"* ]] || [[ "$ARCH" == "aarch64" ]]; then
        VDIS="arm64"
    elif [[ "$ARCH" == *"mips64le"* ]]; then
        VDIS="mips64le"
    elif [[ "$ARCH" == *"mips64"* ]]; then
        VDIS="mips64"
    elif [[ "$ARCH" == *"mipsle"* ]]; then
        VDIS="mipsle"
    elif [[ "$ARCH" == *"mips"* ]]; then
        VDIS="mips"
    elif [[ "$ARCH" == *"s390x"* ]]; then
        VDIS="s390x"
    elif [[ "$ARCH" == "ppc64le" ]]; then
        VDIS="ppc64le"
    elif [[ "$ARCH" == "ppc64" ]]; then
        VDIS="ppc64"
    fi
    return 0
}

downloadTrojan(){
    rm -rf /tmp/trojan-go
    mkdir -p /tmp/trojan-go
    colorEcho ${BLUE} "Downloading trojan-go."
    DOWNLOAD_LINK="https://github.com/frainzy1477/trojan-go-sspanel/releases/download/v0.8.2/trojan-go-linux-amd64.zip"
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho ${RED} "Failed to download! Please check your network or try again."
        return 3
    fi
    return 0
}

installSoftware(){
    COMPONENT=$1
    if [[ -n `command -v $COMPONENT` ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        colorEcho ${RED} "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        return 1
    fi
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        colorEcho ${BLUE} "Updating software repo"
        $CMD_UPDATE
        SOFTWARE_UPDATED=1
    fi

    colorEcho ${BLUE} "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to install ${COMPONENT}. Please install it manually."
        return 1
    fi
    return 0
}


getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    elif [[ -n `command -v zypper` ]]; then
        CMD_INSTALL="zypper -y install"
        CMD_UPDATE="zypper ref"
    else
        return 1
    fi
    return 0
}


extract(){
    colorEcho ${BLUE}"Extracting trojan-go package to /tmp/trojan-go."
    mkdir -p /tmp/trojan-go
    unzip $1 -d ${VSRC_ROOT}
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to extract trojan-go."
        return 2
    fi
    if [[ -d "/tmp/trojan-go/trojan-go" ]]; then
      VSRC_ROOT="/tmp/trojan-go/trojan-go"
    fi
    return 0
}



stopTrojan(){
    colorEcho ${BLUE} "Shutting down trojan-go service."
    if [[ -n "${SYSTEMCTL_CMD}" ]] || [[ -f "/lib/systemd/system/trojan-go.service" ]] || [[ -f "/etc/systemd/system/trojan-go.service" ]]; then
        ${SYSTEMCTL_CMD} stop trojan-go
    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to shutdown trojan-go service."
        return 2
    fi
    return 0
}

startV2ray(){
    if [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/lib/systemd/system/trojan-go.service" ]; then
        ${SYSTEMCTL_CMD} start trojan-go
    elif [ -n "${SYSTEMCTL_CMD}" ] && [ -f "/etc/systemd/system/trojan-go.service" ]; then
        ${SYSTEMCTL_CMD} start trojan-go
    fi
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to start trojan-go service."
        return 2
    fi
    return 0
}

copyFile() {
	NAME=$1
    ERROR=`cp "${VSRC_ROOT}/${NAME}" "/usr/bin/trojan-go/trojan-go" 2>&1`
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "${ERROR}"
        return 1
    fi
    return 0
}

makeExecutable() {
    chmod +x "/usr/bin/trojan-go/$1"
}

installTrojan(){
    mkdir -p /usr/bin/trojan-go
    copyFile trojan-go
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to copy trojan-go binary and resources."
        return 1
    fi
    makeExecutable trojan-go
    copyFile trojan-go && makeExecutable trojan-go
    copyFile geoip.dat
    copyFile geosite.dat
    colorEcho ${BLUE} "Setting TimeZone to Shanghai"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"


    if [[ ! -f "/etc/trojan-go/config.json" ]]; then
        mkdir -p /etc/trojan-go
        mkdir -p /var/log/trojan-go
        cp "${VSRC_ROOT}/trojan-go.service/config.json" "/etc/trojan-go/config.json"
        if [[ $? -ne 0 ]]; then
            colorEcho ${YELLOW} "Failed to create trojan-go configuration file. Please create it manually."
            return 1
        fi

        if [ ! -z "${PANELURL}" ]
        then
              sed -i "s|"https://google.com"|"${PANELURL}"|g" "/etc/trojan-go/config.json"
              colorEcho ${BLUE} "PANELURL:${PANELURL}"
        fi
        if [ ! -z "${PANELKEY}" ]
        then
               sed -i "s/"55fUxDGFzH3n"/"${PANELKEY}"/g" "/etc/trojan-go/config.json"
               colorEcho ${BLUE} "PANELKEY:${PANELKEY}"

        fi
        if [ ! -z "${NODEID}" ]
        then
                sed -i "s/123456,/${NODEID},/g" "/etc/trojan-go/config.json"
                colorEcho ${BLUE} "NODEID:${NODEID}"

        fi


    fi
    return 0
}


installInitScript(){
    if [[ -n "${SYSTEMCTL_CMD}" ]];then
        if [[ ! -f "/etc/systemd/system/trojan-go.service" ]]; then
            if [[ ! -f "/lib/systemd/system/trojan-go.service" ]]; then
                cp "${VSRC_ROOT}/example/trojan-go.service" "/etc/systemd/system/trojan-go.service"
                systemctl enable trojan-go.service
            fi
        fi
        return
    fi
    return
}

Help(){
    echo "./install-release.sh [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file]"
    echo "  -h, --help            Show help"
    echo "  -p, --proxy           To download through a proxy server, use -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc"
    echo "  -f, --force           Force install"
    echo "  -l, --local           Install from a local file"
    echo "      --remove          Remove installed trojan-go"
    return 0
}

remove(){
    if [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/etc/systemd/system/trojan-go.service" ]];then
        if pgrep "trojan-go" > /dev/null ; then
            stopTrojan
        fi
        systemctl disable trojan-go.service
        rm -rf "/usr/bin/trojan-go" "/etc/systemd/system/trojan-go.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove trojan-go."
            return 0
        else
            colorEcho ${GREEN} "Removed trojan-go successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    elif [[ -n "${SYSTEMCTL_CMD}" ]] && [[ -f "/lib/systemd/system/trojan-go.service" ]];then
        if pgrep "trojan-go" > /dev/null ; then
            stopTrojan
        fi
        systemctl disable trojan-go.service
        rm -rf "/usr/bin/trojan-go" "/lib/systemd/system/trojan-go.service"
        if [[ $? -ne 0 ]]; then
            colorEcho ${RED} "Failed to remove trojan-go."
            return 0
        else
            colorEcho ${GREEN} "Removed trojan-go successfully."
            colorEcho ${BLUE} "If necessary, please remove configuration file and log file manually."
            return 0
        fi
    else
        colorEcho ${YELLOW} "trojan-go not found."
        return 0
    fi
}



main(){
    #helping information
    [[ "$HELP" == "1" ]] && Help && return
    [[ "$REMOVE" == "1" ]] && remove && return

    sysArch

    if [[ $LOCAL_INSTALL -eq 1 ]]; then
        colorEcho ${YELLOW} "Installing trojan-go via local file. Please make sure the file is a valid trojan-go package, as we are not able to determine that."
        NEW_VER=local
        installSoftware unzip || return $?
        installSoftware "socat" || return $?
        colorEcho  ${YELLOW} "Downloading acme.sh"
        curl https://get.acme.sh | sh
        rm -rf /tmp/trojan-go
        extract $LOCAL || return $?
    else
        # download via network and extract
        installSoftware "curl" || return $?
        installSoftware "socat" || return $?
        colorEcho  ${YELLOW} "Downloading acme.sh"
        curl https://get.acme.sh | sh
        RETVAL="$?"
        if [[ $RETVAL == 0 ]] && [[ "$FORCE" != "1" ]]; then
            colorEcho ${BLUE} "Latest version ${NEW_VER} is already installed."
            if [[ "${ERROR_IF_UPTODATE}" == "1" ]]; then
              return 10
            fi
            return
        elif [[ $RETVAL == 3 ]]; then
            return 3
        else
            colorEcho ${BLUE} "Installing trojan-go  on ${ARCH}"
            downloadTrojan || return $?
            installSoftware unzip || return $?
            extract ${ZIPFILE} || return $?
        fi
    fi

    if [[ "${EXTRACT_ONLY}" == "1" ]]; then
        colorEcho ${GREEN} "trojan-go extracted to ${VSRC_ROOT}, and exiting..."
        return 0
    fi

    if pgrep "trojan-go" > /dev/null ; then
        TROJAN_RUNNING=1
        stopTrojan
    fi
    installTrojan || return $?
    installInitScript || return $?
    if [[ ${TROJAN_RUNNING} -eq 1 ]];then
        colorEcho ${BLUE} "Restarting trojan-go service."
        startV2ray
    fi
    colorEcho ${GREEN} "trojan-go  is installed."
    rm -rf /tmp/trojan-go
    return 0
}

main