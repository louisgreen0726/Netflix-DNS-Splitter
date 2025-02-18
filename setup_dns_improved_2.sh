#!/bin/bash

# 设置错误处理和未定义变量捕获
set -eu

# 初始化日志记录
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>/var/log/setup_dns_improved.log 2>&1

echo "开始执行脚本..."

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
fi

# 安装dnsmasq
echo "正在安装dnsmasq..."
if [[ "$OS" == "Ubuntu" || "$OS" == "Debian GNU/Linux" ]]; then
    if ! apt-get update && apt-get install -y dnsmasq; then
        echo "安装dnsmasq失败，请检查网络连接或手动安装。"
        exit 1
    fi
elif [[ "$OS" == "CentOS Linux" ]]; then
    if ! yum install -y dnsmasq; then
        echo "安装dnsmasq失败，请检查网络连接或手动安装。"
        exit 1
    fi
else
    echo "不支持的操作系统: $OS"
    exit 1
fi

# 备份原始配置文件
echo "备份原始dnsmasq配置文件..."
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

# 用户输入DNS服务器地址
read -p "请输入用于netflix.com的DNS服务器地址（IPv4或IPv6，例如1.1.1.1或2001:4860:4860::8888）: " NETFLIX_DNS

# 验证并配置DNS服务器地址
if [[ $NETFLIX_DNS =~ : ]]; then
    # IPv6地址
    server=/netflix.com/$NETFLIX_DNS
else
    # IPv4地址
    if ! [[ $NETFLIX_DNS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "输入的DNS地址不正确，请输入有效的IPv4或IPv6地址。"
        exit 1
    fi
    server=/netflix.com/$NETFLIX_DNS
fi

# 配置dnsmasq
echo "正在配置dnsmasq..."

cat << EOF > /etc/dnsmasq.conf
# 自定义DNS配置
$server

# 公共DNS服务器
server=8.8.8.8
server=1.1.1.1
server=2001:4860:4860::8888
server=2606:4700:4700::1111

# 其他配置保持不变
EOF

# 重启dnsmasq服务
echo "重启dnsmasq服务..."
if ! systemctl restart dnsmasq; then
    echo "重启dnsmasq服务失败，请检查服务状态。"
    exit 1
fi

echo "DNS配置完成。"

# 提供撤销更改的选项
read -p "是否要撤销更改？(y/n): " undo_choice
if [[ "$undo_choice" == "y" || "$undo_choice" == "Y" ]]; then
    undo_changes
else
    echo "配置已保存。"
fi

# 撤销更改函数
undo_changes() {
    echo "正在撤销更改..."
    mv /etc/dnsmasq.conf.backup /etc/dnsmasq.conf
    if ! systemctl restart dnsmasq; then
        echo "重启dnsmasq服务失败，请手动检查。"
    else
        echo "已恢复到原始配置。"
    fi
}
