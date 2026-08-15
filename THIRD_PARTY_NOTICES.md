# THIRD PARTY NOTICES

本项目（deepseek-harness-desktop）仅包含本仓库的 C# 壳源码。构建产物（dist / Release 压缩包）内置了以下第三方组件，特此声明其许可：

## DeepSeek Harness (dsh)

- 项目：https://github.com/deepseek-ai/DeepSeek-Harness
- npm 包：`@deepseek-ai/dsh` 及 `@deepseek-ai/*` 系列插件
- 许可证：**MIT**（DeepSeek AI）
- 说明：本桌面应用通过本地 `dsh web` 服务驱动，所有 AI 能力由 DeepSeek 模型/API 提供。

## Node.js

- 项目：https://nodejs.org
- 随应用分发 `node.exe`（Windows x64）
- 许可证：**MIT**（Node.js contributors；含第三方许可汇总）
- 完整许可文本见：https://github.com/nodejs/node/blob/main/LICENSE

## Microsoft WebView2 SDK（.NET）

- 程序集：`Microsoft.Web.WebView2.Core.dll` / `Microsoft.Web.WebView2.WinForms.dll` / `WebView2Loader.dll`
- 许可证：Microsoft 可再分发许可（随 NuGet 包分发，允许在应用中再分发）
- 参见：https://www.nuget.org/packages/Microsoft.Web.WebView2

## 其他 npm 依赖

`node_modules` 中的全部 npm 包（如 cordis、hono、node-pty、koffi、protobufjs 等）版权归其各自作者，许可以各包 `package.json` / `LICENSE` 为准。安装命令 `pnpm install` 会在安装时下载，亦可查阅 `pnpm-lock.yaml`。

## 商标

DeepSeek、Node.js、Microsoft、Windows、Edge WebView2 均为其各自所有者的商标。本项目仅为兼容性目的引用，不构成任何背书。
