# Security Policy

## 这个项目在做什么

它把一台 Windows 电脑上的 DeepSeek Harness 界面，通过 Cloudflare 隧道 + 设备配对，暴露给手机浏览器/主屏 App。**配对成功的设备拥有这台电脑的完整控制权**（聊天、读写文件、执行命令、改设置、看凭据）——与坐在电脑前等价。

## 使用者的责任

1. **只配对你自己控制的设备。**
2. **配对链接 = 一次性完整控制凭据**，不要发到公开群聊、不要贴进公开 issue。二维码/链接过期后自动失效。
3. 在**面板里撤销设备**或点「停止」可立即切断访问。
4. 本机账户若开启了自动登录（用于无人值守），请自行评估物理安全。
5. 中继流量（`relay: true` 时）经过插件作者运营的 `dsh-market.com` Cloudflare Worker；对隐私敏感请关闭 `relay`，改用自带域名的命名隧道。

## 安全边界（实现层面）

- `/api/pair/*` 控制端点只在回环（`127.0.0.1`）应答；
- `/remote` 通道强制要求有效设备 Cookie，与 LAN 策略无关；
- 设备 Cookie 为 HttpOnly + Secure（https 源） + SameSite=Lax；
- 设备可逐个撤销，撤销后下一次请求即 403。

## 报告漏洞

请**不要**公开提交包含配对凭据、域名、日志中 token 的 issue。用 GitHub Security Advisory 或私下联系仓库维护者。
