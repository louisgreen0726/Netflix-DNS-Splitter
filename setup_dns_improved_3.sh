#!/bin/bash

# 检查是否以 root 身份运行脚本
if [ "$(id -u)" != "0" ]; then
   echo "请以 root 或使用 sudo 运行此脚本。"
   exit 1
fi

# 函数：备份文件
backup_file() {
    local file="$1"
    local backup="/etc/${file}.backup.$(date +%Y%m%d%H%M%S)"
    if [ -f "/etc/$file" ]; then
        echo "备份原配置文件至 $backup ..."
        cp "/etc/$file" "$backup"
    else
        echo "原配置文件不存在，跳过备份。"
    fi
}

# 函数：安装 dnsmasq 并检查错误
install_dnsmasq() {
    echo "正在安装 dnsmasq..."
    apt-get update && apt-get install -y dnsmasq || {
        echo "安装 dnsmasq 失败，请检查网络或 APT 配置。"
        exit 1
    }
}

# 函数：输入验证，要求用户输入有效 IPv4/IPv6 地址
get_valid_dns() {
    local prompt="$1"
    local valid_dns=0
    while [ $valid_dns -eq 0 ]; do
        read -p "$prompt" dns
        if [[ "$dns" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || [[ "$dns" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]; then
            valid_dns=1
        else
            echo "错误：输入的 '$dns' 不是有效 IP 地址！"
        fi
    done
    echo "$dns"
}

# 主逻辑
main() {
    while true; do
        echo "选择操作:"
        echo "1. 安装和配置 Netflix 专用 DNS"
        echo "2. 卸载并强制设置公共 DNS（支持 IPv4 和 IPv6）"
        echo "3. 退出"
        read -p "请选择 (1/2/3): " choice

        case $choice in
            1)
                install_dnsmasq
                backup_file "dnsmasq.conf"
                backup_file "resolv.conf"

                # 获取 Netflix 专用 DNS 地址
                NETFLIX_DNS=$(get_valid_dns "请输入用于 Netflix 的 DNS 地址（如 1.1.1.1 或 2606:4700:4700::1111）: ")

                # 是否启用 IPv6 公共 DNS
                read -p "是否启用 IPv6 公共 DNS？(y/n)[默认 n]: " USE_IPV6
                IPV6_SERVERS=""
                if [[ "$USE_IPV6" =~ [Yy] ]]; then
                    IPV6_SERVERS="
server=2001:4860:4860::8888  # Google IPv6 DNS
server=2606:4700:4700::1111  # Cloudflare IPv6 DNS
"
                fi

                # 配置其他域名的专用 DNS
                declare -A custom_dns
                while true; do
                    read -p "是否为其他域名设置专用 DNS？(y/n)[默认 n]: " add_more
                    if [[ "$add_more" =~ [Yy] ]]; then
                        read -p "请输入域名（如 example.com）: " domain
                        dns=$(get_valid_dns "请输入该域名的 DNS 地址: ")
                        custom_dns[$domain]=$dns
                    else
                        break
                    fi
                done

                # 生成新的 dnsmasq 配置文件
                cat << EOF > /etc/dnsmasq.conf
# 初始化 DNS 服务器
server=8.8.8.8        # Google IPv4
server=1.1.1.1        # Cloudflare IPv4
$IPV6_SERVERS
# Netflix 专用 DNS
server=/netflix.com/$NETFLIX_DNS
server=/netflix.net/$NETFLIX_DNS   # 覆盖常见关联域名
EOF

                # 添加自定义域名的 DNS 配置
                for domain in "${!custom_dns[@]}"; do
                    echo "server=/${domain}/${custom_dns[$domain]}" >> /etc/dnsmasq.conf
                done

                # 重启 dnsmasq 服务并检查状态
                echo "重启 dnsmasq 服务..."
                systemctl restart dnsmasq || {
                    echo "服务重启失败！请检查配置：/etc/dnsmasq.conf"
                    exit 1
                }

                # 更新 resolv.conf 文件
                echo "nameserver 127.0.0.1" > /etc/resolv.conf

                # 显示完成信息
                echo -e "\n配置完成！当前 DNS 设置："
                echo "----------------------------------"
                cat /etc/resolv.conf
                echo "----------------------------------"
                echo "Netflix 流量使用 DNS: $NETFLIX_DNS"
                echo "其他流量使用：8.8.8.8, 1.1.1.1${IPV6_SERVERS:+ 及 IPv6 DNS}"
                for domain in "${!custom_dns[@]}"; do
                    echo "${domain} 流量使用 DNS: ${custom_dns[$domain]}"
                done
                echo -e "\n注意：若系统使用 resolvconf 或 NetworkManager，请手动设置持久 DNS！"
                ;;
            2)
                echo "正在卸载 dnsmasq 并设置公共 DNS..."
                systemctl stop dnsmasq
                apt-get remove -y dnsmasq

                # 强制设置公共 DNS，包括 IPv4 和 IPv6
                echo "强制将 /etc/resolv.conf 设置为公共 DNS（IPv4 和 IPv6）..."
                cat << EOF > /etc/resolv.conf
nameserver 1.1.1.1    # Cloudflare IPv4
nameserver 8.8.8.8    # Google IPv4
nameserver 2001:4860:4860::8888    # Google IPv6
nameserver 2606:4700:4700::1111    # Cloudflare IPv6
EOF

                echo "卸载完成，并已设置公共 DNS 为 IPv4 和 IPv6 的地址。"
                ;;
            3)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新选择 1、2 或 3。"
                ;;
        esac
    done
}

main
