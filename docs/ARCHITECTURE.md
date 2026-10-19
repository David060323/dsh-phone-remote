# 架构与实现细节

## 数据流

```
手机 Safari / 主屏 PWA
   │  GET /pair-app         （启动页，只认设备 cookie，不需要 harness browser-auth）
   │  GET /remote/...       （门控通道：插件把请求代理到 127.0.0.1 的 harness，
   │                          并附上进程自己兑换的 harness browser-auth cookie）
   ▼
Cloudflare 快速隧道 ──► 固定域名中继 https://<id>.dsh-market.com
   ▼
DSH 宿主（127.0.0.1:<port>）
   ├─ harness webserver（SPA dist + /api + browser-auth 401 兜底）
   └─ @linxin666/dsh-remote-web-ui
        ├─ /api/pair/*        控制端点（仅回环）
        ├─ /pair-accept       限时令牌 → 303 /pair-app?grant=...
        ├─ /pair-app          官方 index 壳 + 注入脚本（设备 cookie 或 grant 放行）
        ├─ /pair-app.sw.js    Service Worker（https 源，接管对 / 的重开导航）
        └─ /remote            门控通道（强制设备 cookie → 改写 Host/凭据后转发回环）
```

## 为什么主屏会 401

1. iOS 安装主屏 Web App 时读取页面所链的 manifest，并按 `start_url` 启动。
2. 官方 `/manifest.webmanifest` 是 `start_url: "./"` → 根地址 `/`。
3. 根地址由 harness 兜底，未持有 browser-auth cookie → 401。
4. 插件原本依赖“配对页注册的 Service Worker 接管 `/` 导航”；但 iOS 主屏 App 的首个启动导航发生在该上下文注册 SW 之前（SW 与 Safari 标签页不共享该生命周期），于是 401。

## 修复：dsh-phone-home

- 注册 `exact /manifest.webmanifest`，返回 `start_url: "/pair-app"`、`scope: "/"`、`display: fullscreen`；
- `/pair-app` 仅凭设备 cookie 放行（服务端路径，实测禁用 SW 也 200）；
- 附带 `/phone-home/icon-{180,512}.png` 与 `icon.svg`。

因此主屏 App 的启动导航直接落在 `/pair-app`，全程不依赖 Service Worker。

> 该插件只覆盖 manifest 一个路径，不影响桌面端 GUI 的 `/`（harness 兜底保持原样）。

## 常驻链路

```
Windows 登录
  └─ 计划任务（AtLogOn + 每 1 分钟）
       └─ wscript run-hidden.vbs → 隐藏 PowerShell
            └─ 桌面版在跑？ ──是──► 退出（0 开销、无窗口）
                          └─否──► Start-Process 桌面版 → 插件自动重连隧道
```

- 每 1 分钟一次检查约 0.3 秒、瞬时几 MB、**0 token**（不调用任何模型）；
- 桌面版关闭主窗口只是隐藏到托盘，任务继续跑；
- 隧道/中继由插件自己看门狗重连，固定域名不变。

## 配对与凭据

- 令牌 TTL 10 分钟、窗口内可配多台；
- 每台设备独立 device id + 设备 Cookie（HttpOnly/Secure/Lax，约 1 年）；
- 设备记录 10 年（`idleExpireMs`）；域名身份存在 `~/.dsh/remote-web-ui-registry/<profile>.json`；
- 撤销单台 / 全部停止都在面板，或回环 `/api/pair/revoke|stop`。

## 备份建议

把这两个文件备份起来，重装/迁移后可以恢复成同一域名与同一设备，免重新扫码：

```
~/.dsh/remote-web-ui-registry/<profile>.json   # 固定域名身份
~/.dsh/remote-web-ui-devices.json              # 已配对设备
```
