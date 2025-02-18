# Netflix-DNS-Splitter

一个用于在VPS上配置特定DNS服务器以访问Netflix的脚本。它允许用户为Netflix指定一个特定的DNS服务器，而其他DNS查询则使用预设的公共DNS服务器，包括IPv4和IPv6选项。

## 功能

- 自动安装和配置`dnsmasq`。
- 用户可以自定义用于Netflix的DNS服务器。
- 使用8.8.8.8, 1.1.1.1等公共DNS作为默认DNS，同时支持IPv6 DNS。
- 提供简单的用户交互。

## 前提条件

- 基于Debian的Linux发行版（如Ubuntu）。
- root权限或sudo权限。

## 使用方法

1. 克隆仓库：
   ```bash
   git clone https://github.com/louisgreen0726/Netflix-DNS-Splitter.git
   cd Netflix-DNS-Splitter
   
2.给脚本执行权限：
   chmod +x setup_dns_improved.sh

3.运行脚本：
   sudo ./setup_dns_improved.sh

运行脚本时，你将被提示输入用于Netflix的DNS服务器地址。
