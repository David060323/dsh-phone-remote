# DSH Phone Remote

> Turn [DeepSeek Harness](https://deepseek.com) into a full-screen app on your iPhone: watch and drive the AI agents / long-running jobs on your PC from anywhere.

This repo packages the third-party plugin [`@linxin666/dsh-remote-web-ui`](https://github.com/zhu1090093659/dsh-web) (Apache-2.0) into an **install-once, works-always** setup and fixes the iOS problem that the phone icon opens to `401 authentication required`.

Repo: <https://github.com/David060323/dsh-phone-remote>

## What it fixes

| Problem | Fix |
|---|---|
| iOS "Add to Home Screen" opens a 401 page | `dsh-phone-home` overrides `manifest.webmanifest` and sets `start_url` to `/pair-app` (no Service Worker needed) |
| Phone only works while the PC is awake | Logon autostart + tray background + 1-minute self-heal watchdog + sleep disabled |
| Re-scanning the QR every day | Fixed relay hostname + device cookie: pair once, keep forever |

## Quick start

```powershell
# 1) remote access plugin (CLI-managed profile)
dsh plugin --profile web add @linxin666/dsh-remote-web-ui@latest

# 2) the iOS fix plugin
dsh plugin --profile web add link:<repo>\dsh-phone-home

# 3) append to %USERPROFILE%\.dsh\profiles\web\cordis.patch.yml
#    - id: remote-web-ui
#      name: "@linxin666/dsh-remote-web-ui"
#      config:
#        autoTunnel: true
#        relay: true
#        idleExpireMs: 315360000000
#        maxDevices: 8

# 4) start the host
dsh web
```

Then: click the phone icon at the bottom of the sidebar → scan the QR with the **iPhone Camera** (not WeChat) → Safari → Share → **Add to Home Screen**.

Always-on on Windows: `scripts/register-web-guardian.ps1` (dsh web) or `scripts/register-desktop-watchdog.ps1` (desktop app).

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Security

A paired device is a **full-control credential** for that PC. Pair only your own phone; the pairing link is a secret; revoke devices from the panel. The relay (when `relay: true`) forwards traffic through a Cloudflare Worker operated by the plugin author — disable it if that matters to you.

## License

MIT for this repo. Remote-access capability belongs to [`@linxin666/dsh-remote-web-ui`](https://github.com/zhu1090093659/dsh-web) (Apache-2.0) and DeepSeek Harness belongs to DeepSeek. Not affiliated with DeepSeek.
