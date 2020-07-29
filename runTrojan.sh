#!/usr/bin/env bash

if [ ! -z "${api_port}" ]
    then
          sed -i "s|\"local_port\": 443,|\"local_port\": ${api_port},|"  "/etc/trojan-go/config.json"
fi
if [ ! -z "${panelUrl}" ]
    then
         sed -i "s|\"https://google.com\"|\"${panelUrl}\"|g" "/etc/trojan-go/config.json"
fi
if [ ! -z "${panelKey}" ]
    then
         sed -i "s/\"55fUxDGFzH3n\"/\"${panelKey}\"/g" "/etc/trojan-go/config.json"
fi

if [ ! -z "${node_id}" ]
    then
         sed -i "s/123456/${node_id}/g" "/etc/trojan-go/config.json"
fi

if [ ! -z "${node_id}" ]
    then
         sed -i "s/123456/${node_id}/g" "/etc/trojan-go/config.json"
fi

sed -i "s|\"x.com\"|\"${server}\"|g" "/etc/trojan-go/config.json"

sed -i "s|\"/etc/trojan-go/x.com.crt\"|\"/etc/trojan-go/${server}.crt\"|g" "/etc/trojan-go/config.json"

sed -i "s|\"/etc/trojan-go/x.com.key\"|\"/etc/trojan-go/${server}.key\"|g" "/etc/trojan-go/config.json"


cat /etc/trojan-go/config.json
./etc/trojan-go/trojan-go -config /etc/trojan-go/config.json