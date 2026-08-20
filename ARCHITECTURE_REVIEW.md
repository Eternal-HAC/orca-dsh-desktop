# OrcaDSH v0.1 架构审查

> **Historical document.** This is the approved 2026-08-17 v0.1 baseline review. It is superseded by [ARCHITECTURE.md](ARCHITECTURE.md), [ROADMAP.md](ROADMAP.md), and [DECISIONS.md](DECISIONS.md), and is retained for project history.

日期：2026-08-17  
状态：已批准，P0 基线验证中

## 基线与来源

本仓库以 [baiqingyuan/deepseek-harness_Desktop](https://github.com/baiqingyuan/deepseek-harness_Desktop) 为直接基线导入。导入锚点：`cf047b58f05b46f9e2890f7b934bdf66e5d8ce88`。

保留上游 `LICENSE`（MIT）、`THIRD_PARTY_NOTICES.md` 和 Git remote，任何后续发布仍须保留相应许可与非官方说明。

DeepSeek Harness 固定为 `@deepseek-ai/dsh@0.1.0-rc.6`。未来 skin 固定为 `kingOfSoySauce/dsh-liang-skin#v0.1.4`，但不属于本次基线验证。

## v0.1 P0 架构

```text
NSIS Setup.exe
  -> %LOCALAPPDATA%\\<产品目录>\\
      -> WinForms + WebView2 桌面壳
      -> 私有 node.exe
      -> @deepseek-ai/dsh 及其完整 node_modules
      -> 127.0.0.1:3080 Web UI
```

桌面壳直接以同目录的 `node.exe` 执行 `node_modules/@deepseek-ai/dsh/lib/bin.js web`，WebView2 再加载 `http://127.0.0.1:3080`。目标机器不依赖系统 Node、npm、pnpm 或 PATH 修改。

基线含有单实例保护、端口检查、服务就绪轮询、WebView2 缺失提示、错误日志、托盘菜单和 NSIS 按用户安装。当前 X 关闭到托盘的行为本阶段保留；托盘菜单中的显式“真正退出”必须清理它启动或接管的 DSH 进程树。

## 用户数据边界

P0 后续改造会令子进程使用独立 `DSH_HOME`，避免读写系统默认 `~/.dsh`。安装目录只放应用 runtime；凭据、会话和用户配置留在独立的用户数据目录。卸载程序默认不得删除该目录。

## 预置 skin 的最小方案

后续构建期在隔离的 `DSH_HOME` 内，使用 DSH 官方 `plugin --profile web add` 机制安装固定版本 skin，并把已解析的 `profiles/web` 模板随安装包携带。首次运行只初始化模板，不执行 pnpm、git 或网络下载。skin 的默认本地偏好为启用，原始 reasoning effort ID 仍由 DSH 的 ModelDirectory 提交。

## 本阶段不做

- 不修改 DSH 核心源码。
- 不导入或启用 skin。
- 不更换任何人物、背景、图标或整体视觉。
- 不引入自动更新、插件市场、Tauri、Electron 或账户功能。
