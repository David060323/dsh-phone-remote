# 排错手册

## 1. 手机上出现 `dsh web authentication required; reopen the URL printed by dsh web.`

这是 harness 对**未认证根地址 `/`** 的 401 页面，不是密码错误。

| 触发场景 | 解法 |
|---|---|
| 用微信扫一扫 / App 内置浏览器打开 | 内置 WebView 不支持 Service Worker；改用 **iPhone 相机**扫码，或把链接复制到 **Safari** 地址栏 |
| 还没配对就打开根域名 | 先打开配对链接（`/pair-accept?pair=...`）完成配对 |
| 主屏 App 打开 | 装 `dsh-phone-home` 修复 manifest（见下），并**删掉旧图标重新添加** |

**万能应急入口**：已配对的浏览器直接打开

```
https://<你的域名>/pair-app
```

实测无 Service Worker 也返回 200 并渲染官方界面，可存书签。

## 2. 主屏 App 打开 401

1. 确认宿主已装 `dsh-phone-home`（`/manifest.webmanifest` 应返回 `start_url: "/pair-app"`）；
2. **删除旧主屏图标**（旧图标是旧 manifest 装的）；
3. 用 Safari 打开 `https://<你的域名>/pair-app`，界面出来后 → 分享 → 添加到主屏幕。

仍不行说明该 iOS 版本不认 manifest 的 `start_url`，改用 Web Clip 描述文件（`com.apple.webClip.managed`，URL 固定为 `/pair-app`）。

## 3. 面板显示 `phase: lan-required`，没有二维码

隧道没起来或没有公网地址。检查：

- `autoTunnel: true` 是否写进 profile 的 `cordis.patch.yml`（改完热加载约 10 秒生效）；
- `cloudflared` 二进制是否存在：`<profile>/node_modules/cloudflared/bin/cloudflared.exe`；
- `/api/pair/status` 里 `tunnel.state` 是否 `running`。

## 4. `cloudflared` 安装失败（国内常见）

现象：`could not obtain the cloudflared binary: connect ETIMEDOUT 20.205.243.166:443`（GitHub 被墙）。

解法任选：

```powershell
# a) 先单独用 npm/pnpm 装进 profile，让包自带二进制
cd <profile>
pnpm add cloudflared

# b) 从其它已经装好的 profile 拷贝现成二进制
copy <other-profile>\node_modules\cloudflared\bin\cloudflared.exe <profile>\node_modules\cloudflared\bin\

# c) 给命令行配置代理后再重试安装
$env:HTTPS_PROXY='http://127.0.0.1:7890'
```

> 二进制就位后，`/api/pair/status` 的 `tunnel.state` 会自动变为 `running`；若插件已处于 failed 状态，重启宿主（或重载插件）即可。

## 5. 隧道 `Error 1033` / 手机显示实例离线

Cloudflare 快速隧道边缘掉线（插件已知问题）。插件看门狗会重连并重新注册中继，**域名不变**，等 1~2 分钟即可；手机端刷新页面。

## 6. 电脑重启后手机连不上

按顺序检查：

1. Windows 是否停在登录界面（未登录则没有任何用户进程）→ 需要开启自动登录；
2. 计划任务是否启用：`Get-ScheduledTask -TaskName 'DSH Phone Always-On'`；
3. 桌面版是否在跑：`Get-Process 'DeepSeek Harness'`；
4. 隧道是否恢复：`https://<你的域名>/api/pair/status`（`phase` 应为 `disconnected/connected/waiting`，不是 `lan-required`）。

## 7. 不想每次都被守护拉起

```powershell
Disable-ScheduledTask -TaskName 'DSH Phone Always-On'   # 暂停自愈
Enable-ScheduledTask  -TaskName 'DSH Phone Always-On'   # 恢复
```

## 8. 配对设备太多 / 想撤销

```powershell
# 列表（回环可用，含原始 UA；注意这是凭据信息，别外传）
Get-Content "$env:USERPROFILE\.dsh\remote-web-ui-devices.json" -Raw

# 撤销单台
Invoke-RestMethod -Method Post http://127.0.0.1:<port>/api/pair/revoke `
  -ContentType application/json -Body '{"deviceId":"<id>"}'

# 全部停止（撤销所有设备与令牌）
Invoke-RestMethod -Method Post http://127.0.0.1:<port>/api/pair/stop -Body '{}' -ContentType application/json
```
