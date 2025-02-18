#!/bin/bash

# 检查是否以root运行
if [ "$(id -u)" != "0" ]; then
   echo "请以root或使用sudo运行此脚本。"
   exit 1
fi

# 安装dnsmasq
echo "正在安装dnsmasq..."
apt-get update && apt-get install -y dnsmasq

# 备份原配置文件
echo "备份原dnsmasq配置文件..."
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

# 创建新的配置文件
echo "创建新的dnsmasq配置文件..."

# 获取用户输入的Netflix DNS
read -p "请输入用于netflix.com的DNS服务器地址（例如1.1.1.1）: " NETFLIX_DNS

# 配置文件内容
cat << EOF > /etc/dnsmasq.conf
# 指定默认的DNS服务器（IPv4和IPv6）
server=8.8.8.8
server=1.1.1.1
server=2001:4860:4860::8888  # Google IPv6 DNS
server=2606:4700:4700::1111  # Cloudflare IPv6 DNS

# 为netflix.com指定特定的DNS服务器
server=/netflix.com/$NETFLIX_DNS
EOF

# 重启dnsmasq服务
echo "重启dnsmasq服务..."
systemctl restart dnsmasq

# 设置系统使用dnsmasq作为DNS服务器
# 注意：这部分可能需要根据你的系统配置进行调整
echo "nameserver 127.0.0.1" > /etc/resolv.conf

echo "配置完成！你的VPS现在会使用$NETFLIX_DNS访问netflix.com，其他时候使用8.8.8.8, 1.1.1.1, 以及IPv6公共DNS作为备用。"
echo "请注意：如果你使用的是使用resolvconf或netplan的系统，可能需要额外的配置。"
