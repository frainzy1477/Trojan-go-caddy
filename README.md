STANDARD INSTALL
```
cd /home && \
rm -rf install.sh && \
wget  https://raw.githubusercontent.com/frainzy1477/trojan-go-sspanel/master/install.sh && \
chmod +x  install.sh && \
bash install.sh

```
```
systemctl enable trojan-go-*
systemctl restart trojan-go-*
systemctl status trojan-go-*
systemctl daemon-reload
  ```

