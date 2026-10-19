/**
 * dsh-phone-home — iOS 主屏 App 打开停在 401 的修复插件。
 *
 * 背景
 * ----
 * iOS 的「添加到主屏幕」按页面所链 manifest 的 start_url 启动。官方
 * /manifest.webmanifest 的 start_url 是 "./"（= 根地址 /）；根地址由 harness
 * 兜底、需要 harness 的 browser-auth cookie，未认证时返回 401：
 *   "dsh web authentication required; reopen the URL printed by dsh web."
 *
 * 而 @linxin666/dsh-remote-web-ui 的 /pair-app 只凭设备 cookie 就放行 ——
 * 实测在没有 Service Worker 的情况下 /pair-app 依然返回 200 并渲染官方界面。
 *
 * 因此本插件接管 /manifest.webmanifest，把 start_url 改到 /pair-app：
 * 主屏 App 启动即直接进入应用，不再依赖「重开 Service Worker 接管 / 导航」。
 *
 * 同时提供主屏图标资源（本仓库自绘，不含第三方品牌素材）。
 */
import { readFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

export const name = 'dsh-phone-home'
export const inject = ['webServer']

const here = dirname(fileURLToPath(import.meta.url))
const ASSETS = join(here, '..', 'assets')

const MANIFEST = {
  name: 'DeepSeek Harness',
  short_name: 'DSH',
  start_url: '/pair-app',
  scope: '/',
  display: 'fullscreen',
  background_color: '#151517',
  theme_color: '#151517',
  icons: [
    { src: '/phone-home/icon-180.png', sizes: '180x180', type: 'image/png', purpose: 'any' },
    { src: '/phone-home/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
    { src: '/phone-home/icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any' },
    { src: '/favicon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any' },
  ],
}

const FILES = {
  '/phone-home/icon-180.png': { file: 'icon-180.png', type: 'image/png' },
  '/phone-home/icon-512.png': { file: 'icon-512.png', type: 'image/png' },
  '/phone-home/icon.svg': { file: 'icon.svg', type: 'image/svg+xml' },
}

const cache = new Map()

async function assetBytes(file) {
  if (!cache.has(file)) cache.set(file, await readFile(join(ASSETS, file)))
  return cache.get(file)
}

/**
 * Host entry: claim the manifest path and the icon assets.
 * @param ctx - host cordis context carrying `webServer`.
 */
export function apply(ctx) {
  ctx.effect(() => {
    const disposers = [
      ctx.webServer.register({
        kind: 'exact',
        path: '/manifest.webmanifest',
        handler(req, res) {
          const body = JSON.stringify(MANIFEST)
          res.writeHead(200, {
            'content-type': 'application/manifest+json; charset=utf-8',
            'cache-control': 'no-store',
            'content-length': Buffer.byteLength(body),
          })
          res.end(body)
        },
      }),
      ctx.webServer.register({
        kind: 'prefix',
        path: '/phone-home',
        handler: async (req, res) => {
          const path = (req.url ?? '/').split('?')[0]
          const entry = FILES[path]
          if (entry === undefined) {
            res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'no-store' })
            res.end('not found')
            return
          }
          try {
            const bytes = await assetBytes(entry.file)
            res.writeHead(200, {
              'content-type': entry.type,
              'cache-control': 'public, max-age=86400',
              'content-length': bytes.length,
            })
            res.end(bytes)
          } catch {
            res.writeHead(500, { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'no-store' })
            res.end('icon unavailable')
          }
        },
      }),
    ]
    return () => { for (const dispose of disposers) dispose() }
  }, 'dsh-phone-home: routes')
}
