```
cd /etc && yum -y install git \
&& rm -rf /etc/trojan-go-ss-panel /etc/trojan-go \
&& git clone https://github.com/frainzy1477/trojan-go-ss-panel.git \
&& mv /etc/trojan-go-ss-panel /etc/trojan-go \
&& cd /etc/trojan-go \
&& chmod +x install.sh \
&& bash install.sh
```
