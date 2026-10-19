# 发布指南：一次性发布，之后基本不用管

这套东西的目标是「躺平型」：做好一次，之后不需要持续维护。按投入从低到高：

## 1) GitHub 开源仓库（推荐，最省心）

1. 在 GitHub 新建空仓库 `dsh-phone-remote`（Public）；
2. 本目录内容即仓库根：
   ```powershell
   cd <本目录>
   git init
   git add .
   git commit -m "Initial commit: phone remote kit for DeepSeek Harness"
   git remote add origin https://github.com/David060323/dsh-phone-remote.git
   git push -u origin main
   ```
3. 把 README 里的 `<your-org>` 换成你的 GitHub 用户/组织；
4. 可选：在 GitHub 仓库设置里打开 **Sponsors** 或放一个 `FUNDING.yml` 指向爱发电/微信赞赏码。

被动性：★☆☆☆☆（几乎零维护）。有人提 issue 可以不回；唯一要留意的是别把凭据贴进 issue。

## 2) 提交到 DSH 插件目录（白嫖官方流量）

[dshmarket](https://dshmarket.com) 安装受限源白名单：只接受 curated
[awesome-dsh-plugin](https://awesome-dsh-plugin.com) 注册表里的来源。做一次 PR 把
`dsh-phone-home` 登记进去，之后几万 DSH 用户能在插件市场里搜到：

- fork `awesome-dsh-plugin` 仓库 → 按其 README 的格式加一条记录（名称、仓库地址、描述、截图）
- 提 PR，等合并
- 被动性：★★★★☆（一次 PR，之后自动被索引）

## 3) 一篇长文发知乎/公众号（一次写作，长期被动流量）

`publish/ARTICLE-zhihu.md` 是现成的中文文章，替换 GitHub 链接后：

- 知乎专栏 / 公众号 / 即刻 / 少数派 任选，发一次即可；
- 公众号流量主需要粉丝量，知乎/B站有创作激励，收益可有可无；
- 被动性：★★★★☆（文章不会被删除的话，长期有人搜到）

## 4) 小红书 / B站短视频（可选，想要流量再做）

- 录 60~90 秒：手机点图标 → 看任务进度 → 发一句指令；
- 视频发布一次即可，之后不管；私信求配置的可以不做。
- 被动性：★★★☆☆（平台流量波动，但不需持续更新）

## 5) 付费文档（想要被动收入再说）

- 小报童 / 爱发电 / 知识星球 / Gumroad：把 `dsh-phone-remote` 的文档整理成付费阅读（¥9.9~29.9）；
- 平台自动发货，属于真被动；
- 被动性：★★★★☆（平台抽成、偶有客服消息）

## 6) 闲鱼（不建议当主渠道）

- 现成文案见 `XIANYU-listing.md`；
- 问题：每条咨询都要回，不是被动；除非开自动发货且不承诺答疑。

## 要准备的东西清单

- [ ] GitHub 账号（已有则跳过）
- [ ] 把 README 里所有 `<your-org>`、`<本仓库路径>` 占位符替换掉
- [ ]（建议）给自己的仓库加个英文名描述 + topics：`dsh`, `deepseek-harness`, `pwa`, `remote-access`, `ios`
- [ ] 可选：把自己手机上的效果截图换到 `screenshots/mobile-app.png`（别露出自己的域名/设备 id）

## 不要做的事

- 不要把配对链接、设备 id、你的固定域名、日志里的 token 发到公开仓库；
- 不要用 DeepSeek 官方名义宣传（写"基于开源插件"）；
- 不要在文案里暗示"控制他人电脑"；
- 不要承诺"永久可用"（第三方插件/Cloudflare 都可能变）。

## 维护预期（重要）

这个项目依赖第三方插件 `@linxin666/dsh-remote-web-ui` 和 DeepSeek Harness 的版本。
**上游升级后可能失效**——那就放着，等有空再修；作为"玩一玩"的项目完全够用，
不要给自己加"必须长期维护"的压力。
