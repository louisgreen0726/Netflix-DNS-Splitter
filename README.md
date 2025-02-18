# Netflix-DNS-Splitter

Netflix-DNS-Splitter 是一个专为在 VPS 上配置特定 DNS 服务器以优化 Netflix 访问的 Bash 脚本。它允许用户为 Netflix 指定一个专用的 DNS 服务器，而将其他 DNS 查询路由到预设的公共 DNS 服务器，支持 IPv4 和 IPv6。

## 功能概述

- **自动安装和配置 dnsmasq**：脚本会自动安装并配置 dnsmasq，作为本地 DNS 服务器。
- **自定义 Netflix DNS**：用户可以指定专用的 DNS 服务器以优化 Netflix 的访问体验。
- **公共 DNS 支持**：默认使用如 8.8.8.8 (Google DNS)、1.1.1.1 (Cloudflare DNS) 等公共 DNS 服务器，同时支持 IPv6 DNS 配置。
- **用户友好交互**：通过简单的问题与回答交互，简化配置过程。
- **配置备份与恢复**：在修改配置前自动备份关键文件，提供选项来恢复到原始设置。

## 前提条件

- **操作系统**：基于 Debian 的 Linux 发行版（如 Ubuntu）。
- **权限**：需要 root 权限或 sudo 权限。

## 安装与使用

直接从 GitHub 运行脚本，无需克隆仓库：

```bash
sudo bash <(curl -sSL https://raw.githubusercontent.com/louisgreen0726/Netflix-DNS-Splitter/refs/heads/main/setup_dns_improved_3.sh)
```

运行后，请按照以下步骤操作：

1. **选择操作**：
   - 输入 `1` 以开始安装和配置 Netflix 专用 DNS。
   - 输入 `2` 以卸载 dnsmasq 并恢复到公共 DNS。
   - 输入 `3` 以退出脚本。

2. **配置信息输入**：
   - 输入您希望用于 Netflix 的专用 DNS 服务器地址。
   - 选择是否启用 IPv6 DNS。
   - 脚本会提示您是否要更改默认的公共 DNS 服务器（如 8.8.8.8 或 1.1.1.1）。

## 重要提示

- **持久性配置**：如果您的系统使用 `resolvconf` 或 `NetworkManager`，请在脚本执行后手动配置持久 DNS，以防止重启后丢失设置。
- **权限要求**：此脚本需要 root 或 sudo 权限才能正确执行。

## 贡献指南

我们欢迎任何形式的贡献，包括但不限于 bug 修复、功能增强和文档改进。请遵循以下步骤：

1. Fork 此仓库。
2. 创建您的功能分支 (`git checkout -b feature/YourFeature`).
3. 提交您的更改 (`git commit -m 'Add YourFeature'`).
4. 将更改推送到您的分支 (`git push origin feature/YourFeature`).
5. 提交 Pull Request。

## 许可证

本项目遵循 [MIT License](LICENSE)，允许自由使用、修改和分发。

---

如果您在使用过程中遇到任何问题，或者有改进建议，请在 [Issues](issues) 中提出，我们将尽快回应。
