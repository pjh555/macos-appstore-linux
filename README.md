# App Store for Linux

一个使用 **Qt Quick 6** 编写的 macOS 风格 Linux 软件商店，适配当前 Ubuntu 26.04
（arm64）与 niri / Wayland 桌面。目录目前收录 **107 个应用**，包含探索、排行榜、
分类、应用详情、更新、已安装和搜索，可以直接从 Ubuntu 软件源、GitHub Releases、
Flathub 下载并安装，也支持 Web 应用和官网入口。

## 功能

- **macOS 风格窗口**：无边框圆角窗口、红黄绿窗口按钮、半透明侧边栏、玻璃质感
  下载面板与授权弹窗。
- **编辑精选与轮播**：应用商店首页 Hero 轮播、效率/创意/开发精选横向卡片。
- **分类**：创意、效率、娱乐、开发、工具、网络六个分类，仿照 Mac App Store
  的侧边栏与分类网格。
- **排行榜**：按应用热度排序的免费应用排行。
- **详情页**：应用图标、评分、预览示意图、介绍、新功能、来源和安装信息。
- **真实更新检查**：
  - `apt list --upgradable` 检查 Ubuntu 软件源中的更新；
  - `flatpak remote-ls --updates` 检查 Flathub 更新；
  - 侧边栏“更新”徽标、检查更新与“全部更新”按钮。
- **真实下载与安装**：
  - `apt`：通过 `sudo apt-get install` 下载并安装 Ubuntu 软件源中的应用；
  - `githubDeb`：调用 GitHub Releases API 选择 arm64 `.deb`，下载后交给 apt 安装；
  - `directDeb`：从官方固定地址下载 arm64 `.deb` 并安装（如 VS Code）；
  - `githubAppImage`：从 GitHub 下载 arm64 AppImage，展开到 `~/Applications/<id>`，
    自动创建 `.desktop` 启动项（如 Obsidian）；
  - `flatpak`：从 Flathub 安装/更新；系统级安装或更新时会请求管理员授权；
  - `webapp`：创建浏览器 Web 应用启动项（如阿里云盘、夸克网盘）；
  - `npm`：安装/卸载 npm 全局命令行工具（Codex、Gemini、Copilot、Qwen）；
  - `script`：运行厂商官方安装脚本（Claude Code）；
  - `external`：仅提供官网入口（如 Steam 官方客户端仅支持 x86_64）。
- **107 个应用**：新增 ChatGPT、Google Chrome、Steam、QQ、微信、WPS Office、
  ONLYOFFICE、百度网盘、阿里云盘、夸克网盘、迅雷云盘、飞书、钉钉、腾讯会议、网易云音乐、Signal、Element、Firefox、Chromium、Brave、Vivaldi、LibreWolf、
  Tor Browser、LM Studio、OpenCode、Zed、Postman、DBeaver、AnyDesk、Bitwarden、
  Mission Center、Prism Launcher、FEX-Emu、Haruna、Clapper、SMPlayer、QMPlay2、Kodi、Jellyfin Media Player、Stremio、FreeTube、Showtime、Dragon Player、Celluloid、mpv、Olive、wiliwili、Simple Live、Nora、NouTube、YesPlayMusic、LX Music、Cryptomator、Claude Code、Codex CLI、Gemini CLI、GitHub Copilot CLI 等。
- **已安装页面**：展示目录中已安装的应用并支持“打开”。
- **AI 编程工具**：Claude Code、OpenAI Codex CLI、Gemini CLI、GitHub Copilot CLI、
  Qwen Code、OpenCode、LM Studio、GPT4All 等，终端工具会打开 alacritty 运行。
- **卸载应用**：在已安装应用的详情页点击“卸载”，确认后卸载；支持 apt、.deb、Flathub Flatpak 和 AppImage，需要管理员权限时会先弹出密码窗口。
- **本地账户**：无需登录，所有安装操作直接在本机完成；支持深色/浅色外观切换。
- **搜索**：工具栏实时搜索应用名称、简介、分类和开发者。
- **普通平铺窗口**：和终端、浏览器等应用一样由 niri 正常平铺管理，不再浮动置顶。

## 环境要求

- Linux（优先 Ubuntu 24.04+ / Debian 12+；本项目在 Ubuntu 26.04 arm64 上开发）
- Qt 6.10（Quick、Quick Controls、Network、Svg）
- CMake 3.21+、Ninja
- 网络访问（Ubuntu 软件源、GitHub API / Releases、Flathub）
- 可选：`flatpak` 与已配置的 Flathub remote（否则 Flatpak 应用不可安装）
- `sudo`（安装 apt/.deb 应用时由弹窗询问系统密码）

## 构建与运行

```bash
cd ~/Apps/appstore
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
./build/appstore
```

## 安装到应用菜单

```bash
./install.sh
```

安装脚本只写入当前用户的 XDG 目录：

- `~/.local/lib/appstore/appstore`
- `~/.local/bin/appstore`
- `~/.local/share/applications/org.clavis.AppStore.desktop`
- `~/.local/share/icons/hicolor/scalable/apps/org.clavis.AppStore.svg`

之后可以在应用启动器中搜索“应用商店 / App Store”，或在终端运行 `appstore`。



## 使用

- 点击 `获取`：开始下载/安装；安装完成后按钮变为 `打开`。
- 已安装且有更新时按钮变为 `更新`，点击后下载并安装新版本。
- “更新”页面可以检查更新、单独更新或“全部更新”。
- 安装或卸载 apt / .deb 应用时，会弹出密码窗口；密码仅用于本次 `sudo` 授权，
  不会被保存。密码通过标准输入传给 `sudo`，随后立即清空。
- 卸载入口位于已安装应用的详情页。卸载会移除应用文件与启动项，但部分应用在
  `~/.config`、`~/.local/share` 或 Flatpak 沙箱中的数据可能会保留。
- Flatpak 应用优先安装到用户空间（无需管理员权限）；如果 Flathub 只配置在系统
  范围，会自动请求管理员授权改为系统级安装。
- 下载的安装包保存在 `~/下载/App Store/`（具体名称跟随系统的 XDG 下载目录）。
- 安装日志：`~/.local/state/clavis-appstore/install.log`。

## 快捷键

| 快捷键 | 功能 |
| --- | --- |
| `Ctrl+1` | 探索 |
| `Ctrl+2` | 排行榜 |
| `Ctrl+3` | 全部分类 |
| `Ctrl+4` | 更新 |
| `Ctrl+5` | 已安装 |
| `Ctrl+F` | 聚焦搜索框 |
| `Esc` | 清空搜索 / 关闭授权或卸载确认弹窗 |

## 目录与数据

```text
appstore/
├── CMakeLists.txt
├── data/apps.json          # 应用目录（名称、分类、安装方式、下载地址等）
├── assets/icons/           # 应用图标与界面线性图标
├── src/                    # C++ 后端：目录模型、过滤模型、更新扫描、安装器
├── *.qml                   # Qt Quick 界面
└── install.sh
```

### 添加一个应用

在 `data/apps.json` 的 `apps` 数组中添加对象即可。常用字段：

```json
{
  "id": "example",
  "name": "Example",
  "shortName": "Example",
  "subtitle": "一句话介绍",
  "description": "列表中的简短介绍",
  "longDescription": "详情页中的完整介绍",
  "category": "work",
  "icon": "example.svg",
  "iconBg1": "#0a84ff",
  "iconBg2": "#0057d9",
  "version": "1.0.0",
  "size": "20 MB",
  "source": "GitHub Releases",
  "homepage": "https://example.com",
  "method": "githubDeb",
  "package": "example",
  "githubRepo": "owner/repo",
  "assetHint": "arm64.deb",
  "launch": "example",
  "rating": 4.5,
  "popularity": 50,
  "developer": "Example Team"
}
```

`method` 支持：

- `apt`：使用 `package` 字段；
- `directDeb`：使用 `directUrl` 与 `fileName`；
- `githubDeb` / `githubAppImage`：使用 `githubRepo`、`assetHint`；
- `flatpak`：使用 `flatpakId`。

`assetHint` 会先做大小写与连字符归一化再匹配，因此 `arm64.deb` 也能匹配
`linux-arm-64.deb`。`arch`/`architecture` 可选，默认 `arm64`；Steam 等仅 x86_64
的应用会标记为 `x86_64`，目录中只显示官网入口。`script` 方式可以额外提供
`uninstallCommand` 用于卸载。
- `npm` 方式的 `package` 字段是 npm 包名，`launch` 是安装后的命令名。
- `script` 方式的 `directUrl` 是官方安装脚本，`uninstallCommand` 是卸载命令。

## 说明

- ChatGPT 使用 **OpenAI 官方 Linux arm64 apt 源**，当前系统已安装原生客户端
  `chatgpt 26.1016.61520`，商店中可检测到 `26.1103.60933` 更新；本地下载的
  `~/下载/chatgpt_arm64.deb` 也是同一官方客户端。
- **wiliwili** 和 **Simple Live** 是 Flathub 上的第三方 B 站客户端；此外还有
  Nora、NouTube、YesPlayMusic、LX Music 等第三方客户端。
- Steam 已有官方 Linux 客户端，但目前只有 x86_64 构建；当前 arm64 设备需要
  FEX-Emu/Box64 等兼容层，目录中提供官网入口和相关兼容工具。
- Claude Code 使用 Anthropic 官方安装脚本；Codex/Gemini/Copilot/Qwen 使用 npm
  全局包。安装后从应用详情页点击“打开”会在 alacritty 中启动。
- 应用名称、图标与商标归各自所有者所有；本项目仅用于学习与本地使用。
- 详情页中的“预览”是根据应用配色生成的界面示意图，并非应用真实截图。
- 应用目录中的下载来源为 2026 年 11 月可访问的官方地址；如果上游发布页或
  Flathub 应用 ID 变化，请更新 `data/apps.json`。
- App Store 使用普通 Wayland toplevel，由 niri 或其他桌面正常平铺管理。
