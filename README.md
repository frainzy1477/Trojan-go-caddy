STANDARD INSTALL (FOR CENTOS7+/7.x/8.x+ & UBUNTU 16.04/18.04/20.04)
```
yum -y install epel-release wget bash zip unzip update && wget https://github.com/frainzy1477/t-go/releases/download/v0.8.2.2/trojan-go.zip && unzip /root/trojan-go && cd /root/trojan-go && chmod +x  trojan-go && bash trojan-go.sh


```
```
systemctl enable trojan-go-*
systemctl start trojan-go-*
systemctl daemon-reload
systemctl status trojan-go-*

systemctl disable trojan-go-*
systemctl stop trojan-go-*
systemctl status trojan-go-*

systemctl restart trojan-go-*
systemctl daemon-reload
systemctl status trojan-go-*
  ```

