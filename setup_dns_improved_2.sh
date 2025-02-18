#!/bin/bash

# 检查是否以root运行
if [ "$(id -u)" != "0" ]; then
   echo "请以root或使用sudo运行此脚本。"
   exit 1
fi

# 安装dnsmasq并检查错误
echo "正在安装dnsmasq..."
apt-get update && apt-get install -y dnsmasq || {
   echo "安装dnsmasq失败，请检查网络或APT配置。"
   exit 1
}

# 备份原配置文件（带时间戳）
backup_conf="/etc/dnsmasq.conf.backup.$(date +%Y%m%d%H%M%S)"
if [ -f "/etc/dnsmasq.conf" ]; then
   echo "备份原配置文件至 $backup_conf ..."
   cp /etc/dnsmasq.conf "$backup_conf"
else
   echo "原配置文件不存在，跳过备份。"
fi

# 输入验证：要求用户输入有效IPv4/IPv6
valid_dns=0
while [ $valid_dns -eq 0 ]; do
   read -p "请输入用于Netflix的DNS地址（如1.1.1.1或2606:4700:4700::1111）: " NETFLIX_DNS
   # 简易正则校验（IPv4和IPv6）
   if [[ "$NETFLIX_DNS" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || [[ "$NETFLIX_DNS" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]; then
      valid_dns=1
   else
      echo "错误：输入的 '$NETFLIX_DNS' 不是有效IP地址！"
   fi
done

# 可选添加IPv6 DNS
read -p "是否启用IPv6公共DNS？(y/n)[默认n]: " USE_IPV6
IPV6_SERVERS=""
if [[ "$USE_IPV6" =~ [Yy] ]]; then
   IPV6_SERVERS="
server=2001:4860:4860::8888  # Google IPv6 DNS
server=2606:4700:4700::1111  # Cloudflare IPv6 DNS
"
fi

# 生成新配置文件
cat << EOF > /etc/dnsmasq.conf
# 默认DNS服务器
server=8.8.8.8        # Google IPv4
server=1.1.1.1        # Cloudflare IPv4
$IPV6_SERVERS
# Netflix专用DNS
server=/netflix.com/$NETFLIX_DNS
server=/netflix.net/$NETFLIX_DNS   # 覆盖常见关联域名
EOF

# 重启服务并检查状态
echo "重启dnsmasq服务..."
systemctl restart dnsmasq || {
   echo "服务重启失败！请检查配置：/etc/dnsmasq.conf"
   exit 1
}

# 修改DNS设置（带备份）
resolv_backup="/etc/resolv.conf.backup.$(date +%Y%m%d%H%M%S)"
echo "备份原DNS配置至 $resolv_backup ..."
cp /etc/resolv.conf "$resolv_backup" 2>/dev/null || echo "警告：无法备份resolv.conf"
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# 完成提示
echo -e "\n配置完成！当前DNS设置："
echo "----------------------------------"
cat /etc/resolv.conf
echo "----------------------------------"
echo "Netflix流量使用DNS: $NETFLIX_DNS"
echo "其他流量使用：8.8.8.8, 1.1.1.1${IPV6_SERVERS:+ 及IPv6 DNS}"
echo -e "\n注意：若系统使用resolvconf或NetworkManager，请手动设置持久DNS！"
