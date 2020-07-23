```
cd /etc && yum -y install git \
&& rm -rf /etc/trojan-go-sspanel /etc/trojan-go \
&& git clone https://github.com/frainzy1477/trojan-go-sspanel.git \
&& mv /etc/trojan-go-sspanel /etc/trojan-go \
&& cd /etc/trojan-go \
&& chmod +x install.sh \
&& bash install.sh
```
