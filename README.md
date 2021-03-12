STANDARD INSTALL
```
yum -y install epel-release wget bash zip unzip update && \
cd /root && \
rm -rf trojan-go.zip trojan-go 2>/dev/null && \
wget https://github.com/frainzy1477/trojan-go-webapi/releases/download/v0.8.3/trojan-go.zip && \
unzip /root/trojan-go && \
cd /root/trojan-go && \
chmod +x  trojan-go && \
bash trojan-go.sh


```
```
--------- ENABLE/START ---------
systemctl enable trojan-go
systemctl start trojan-go
systemctl daemon-reload
systemctl status trojan-go

--------- DISABLE/STOP ---------
systemctl disable trojan-go
systemctl stop trojan-go
systemctl status trojan-go

--------- RESTART/RELOAD ---------
systemctl restart trojan-go
systemctl resload trojan-go
systemctl daemon-reload
systemctl status trojan-go
  ```
```
--------- COMMANDS ---------
trojan-go start
trojan-go restart
trojan-go stop
trojan-go status
trojan-go log
trojan-go version
trojan-go install
trojan-go uninstall
```
