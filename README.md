```
cd /home && \
rm -rf install.sh && \
wget  https://raw.githubusercontent.com/frainzy1477/trojan-go-sspanel/master/install.sh && \
chmod +x  install.sh && \
bash install.sh

```

```
systemctl enable trojan-go
systemctl start trojan-go
systemctl restart trojan-go
systemctl daemon-reload
systemctl status trojan-go

```

INSTALL DOCKER
```
yum -y install  git python-tools python-pip curl
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

```


INSTALL DOCKER-COMPOSE
```
yum -y install  git python-tools python-pip curl
sudo curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose 
  
 ```
 
 RUN TROJAN-GO-SSPANEL IN DOCKER
 ```
 docker run -d --name=trojan \
-e NODEID=1 \
-e WEBAPI_URL=https://www.abc.net \
-e WEBAPI_KEY=123456 \
-e SNI_HOST=abc.com \
-e TROJAN_PORT=443 \
-e CHECKRATE=60 \
--network=host --log-opt max-size=50m --log-opt max-file=5 --restart=always \
frainzy1477/plugin:webapi

 ```
