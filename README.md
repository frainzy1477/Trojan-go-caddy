STANDARD INSTALL (FOR CENTOS7+/7.x/8.x+ & UBUNTU 16.04/18.04/20.04)
```
cd /home && \
rm -rf install.sh && \
wget  https://raw.githubusercontent.com/frainzy1477/t-go/master/install.sh && \
chmod +x  install.sh && \
bash install.sh

```
```
systemctl enable trojan-go-*
systemctl start trojan-go-*
systemctl stop trojan-go-*
systemctl restart trojan-go-*
systemctl daemon-reload
systemctl status trojan-go-*
  ```

