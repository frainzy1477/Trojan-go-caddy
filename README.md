STANDARD INSTALL
```
cd /home && \
rm -rf install.sh && \
wget  https://raw.githubusercontent.com/frainzy1477/trojan-go-sspanel/master/install.sh && \
chmod +x  install.sh && \
bash install.sh


systemctl enable trojan-go
systemctl start trojan-go
systemctl restart trojan-go
systemctl daemon-reload
systemctl status trojan-go

```

INSTALL DOCKER
```
yum -y install curl
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

```
 
 RUN TROJAN-GO SSPANEL-WEBAPI IN DOCKER
 ```
 docker run -d --name=trojan \
-e NODEID=1 \
-e WEBAPI_URL=https://www.abc.net \
-e WEBAPI_KEY=123456 \
-e SNI_HOST=abc.com \
-e TROJAN_PORT=443 \
--network=host --log-opt max-size=50m \
--log-opt max-file=5 --restart=always \
frainzy1477/plugin:webapi

 ```
