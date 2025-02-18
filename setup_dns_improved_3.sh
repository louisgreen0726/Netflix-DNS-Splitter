#!/bin/bash

# 检查是否以root运行
if [ "$(id -u)" != "0" ]; then
   echo "请以root或使用sudo运行此脚本。"
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

# 函数：恢复文件
restore_file() {
    local file="$1"
    local backups=$(ls /etc/${file}.backup.* 2>/dev/null | sort -r)
    if [ -n "$backups" ]; then
        latest_backup=$(echo "$backups" | head -n 1)
        echo "恢复配置文件从 $latest_backup ..."
        cp "$latest_backup" "/etc/$file"
    else
        echo "没有找到备份文件，无法恢复。"
    fi
}

# 函数：安装dnsmasq并检查错误
install_dnsmasq() {
    echo "正在安装dnsmasq..."
    apt-get update && apt-get install -y dnsmasq || {
        echo "安装dnsmasq失败，请检查网络或APT配置。"
        exit 1
    }
}

# 函数：输入验证，要求用户输入有效IPv4/IPv6
get_valid_dns() {
    local prompt="$1"
    local valid_dns=0
    while [ $valid_dns -eq 0 ]; do
        read -p "$prompt" dns
        if [[ "$dns" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || [[ "$dns" =~ ^([0-9a-fA-F]{0,4}:){1,3}[0-9a-fA-F]{0,4}$ ]]; then
            valid_dns=1
        else
            echo "错误：输入的 '$dns' 不是有效IP地址！"
        fi
    done
    echo "$dns"
}

# 主逻辑
main() {
    while true; do
        echo "选择操作:"
        echo "1. 安装和配置Netflix专用DNS"
        echo "2. 卸载并恢复原配置"
        echo "3. 退出"
        read -p "请选择 (1/2/3): " choice

        case $choice in
            1)
                install_dnsmasq
                backup_file "dnsmasq.conf"
                backup_file "resolv.conf"

                NETFLIX_DNS=$(get_valid_dns "请输入用于Netflix的DNS地址（如1.1.1.1或2606:4700:4700::1111）: ")

                read -p "是否启用IPv6公共DNS？(y/n)[默认n]: " USE_IPV6
                IPV6_SERVERS=""
                if [[ "$USE_IPV6" =~ [Yy] ]]; then
                    IPV6_SERVERS="
server=2001:4860:4860::8888  # Google IPv6 DNS
server=2606:4700:4700::1111  # Cloudflare IPv6 DNS
"
                fi

                # 其他域名支持
                declare -A custom_dns
                while true; do
                    read -p "是否为其他域名设置专用DNS？(y/n)[默认n]: " add_more
                    if [[ "$add_more" =~ [Yy] ]]; then
                        read -p "请输入域名（如example.com）: " domain
                        dns=$(get_valid_dns "请输入该域名的DNS地址: ")
                        custom_dns[$domain]=$dns
                    else
                        break
                    fi
                done

                # 生成新配置文件
                cat << EOF > /etc/dnsmasq.conf
# 初始化DNS服务器
server=8.8.8.8        # Google IPv4
server=1.1.1.1        # Cloudflare IPv4
$IPV6_SERVERS
# Netflix专用DNS
server=/netflix.com/$NETFLIX_DNS
server=/netflix.net/$NETFLIX_DNS   # 覆盖常见关联域名
EOF

                # 添加自定义域名DNS配置
                for domain in "${!custom_dns[@]}"; do
                    echo "server=/${domain}/${custom_dns[$domain]}" >> /etc/dnsmasq.conf
                done

                # 重启服务并检查状态
                echo "重启dnsmasq服务..."
                systemctl restart dnsmasq || {
                    echo "服务重启失败！请检查配置：/etc/dnsmasq.conf"
                    exit 1
                }

                echo "nameserver 127.0.0.1" > /etc/resolv.conf

                echo -e "\n配置完成！当前DNS设置："
                echo "----------------------------------"
                cat /etc/resolv.conf
                echo "----------------------------------"
                echo "Netflix流量使用DNS: $NETFLIX_DNS"
                echo "其他流量使用：8.8.8.8, 1.1.1.1${IPV6_SERVERS:+ 及IPv6 DNS}"
                for domain in "${!custom_dns[@]}"; do
                    echo "${domain} 流量使用DNS: ${custom_dns[$domain]}"
                done
                echo -e "\n注意：若系统使用resolvconf或NetworkManager，请手动设置持久DNS！"
                ;;
            2)
                echo "正在卸载并恢复原配置..."
                systemctl stop dnsmasq
                apt-get remove -y dnsmasq
                restore_file "dnsmasq.conf"
                restore_file "resolv.conf"
                echo "卸载完成，系统已恢复到原始配置。"
                ;;
            3)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新选择1、2或3。"
                ;;
        esac
    done
}

main
