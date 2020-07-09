```
cd /etc && yum -y install git \
&& git clone https://github.com/frainzy1477/trojan-go-caddy.git \
&& mv /etc/trojan-go-caddy /etc/trojan-go \
&& cd /etc/trojan-go \
&& chmod +x install.sh \
&& bash install.sh
```
