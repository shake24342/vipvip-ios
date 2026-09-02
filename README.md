# VIPvip iOS

签到面板的原生 iOS 客户端（SwiftUI，非网页套壳），配合私有仓库 `shake24342/VIPvip` 的 `state.json` 使用。

## 功能

- 总览：今日已签 / 延迟中 / 24h VIP / 7~14 天 / 存活 / 失效，签到阶梯可视化
- 账号：搜索、筛选（24h VIP / 7~14 天 / 未获 VIP / 延迟中 / 已失效）、按天数或槽位排序
- 单账号刷新实时状态（直连目标站 API，口径与网页面板一致）
- 复制卡号 / 密码 / Token（左滑操作 + 长按菜单）
- 域名状态与历史记录，一键探测当前域名
- 设置：GitHub Token（Keychain 存储）、仓库 / 分支 / 文件路径、API 域名
- 本地缓存，离线可看上次同步的数据；数据超过 36 小时自动提示陈旧

## 安装（TrollStore）

1. 打开本仓库 Actions，下载最新 `VIPvip.ipa`（或 Releases 页）
2. 用 Safari 打开下载的 ipa → 分享 → TrollStore
3. 在 TrollStore 里点安装，永久有效，无需重签、无需证书

没有 TrollStore 的设备可以用任意签名工具（爱思助手 / AltStore）导入自己的证书安装。

## 构建

推送到 main 或手动触发 `Build IPA` 工作流：

- macOS runner 上用 [xcodegen](https://github.com/yonaskolb/XcodeGen) 生成工程
- `xcodebuild` 编译（不签名）→ `codesign -s -` ad-hoc 签名 → 打包 ipa
- 产物：Actions artifact（90 天）+ Releases（长期）

> TrollStore 安装不校验证书有效性，ad-hoc 签名即可；自有证书不是必需品。

## 目录

```
project.yml                 xcodegen 工程定义
VipPanel/
  App.swift                 入口
  Models.swift              账号 / 域名 / 状态模型（兼容 state.json 与面板内嵌两种字段名）
  Store.swift               Keychain + UserDefaults 存储
  APIClient.swift           目标站 API（jwt-token / signin/info）
  GitHubSync.swift          从 GitHub 拉取 state.json
  PanelViewModel.swift      业务逻辑与统计口径
  Theme.swift               配色与通用组件
  Views/                    四个页面 + 账号行
```
