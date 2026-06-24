# Pomodoro

macOS 菜单栏极简版番茄时钟：识别长时间工作状态，并发送通知提醒用户短暂休息。

| Working | Resting Reminder |
| --- | --- |
| ![Working](docs/images/menubar-working.png) | ![Rest notification](docs/images/rest-notification.png) |

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-111111?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-111111?style=flat-square)

## 功能

- **轻量设计**：没有暂停、恢复和任务管理，只保留工作与休息。
- **低打扰提醒**：只在长时间工作后发送通知，不弹窗、不强制确认。
- **自动判断休息**：长时间无操作会直接进入休息，避免无意义提醒。
- **本地运行**：无需登录，不依赖网络，不上传数据。

## 状态逻辑

启动后进入 `Working`，菜单栏显示已工作时间，例如 `Working · 32m`。

### `Working` -> `Resting`

满足任一条件就会进入 `Resting`：

| 条件 | 行为 |
| --- | --- |
| 连续工作满 45 分钟 | 发送 `Time to rest`，然后进入 `Resting` |
| 连续 10 分钟没有操作 | 直接进入 `Resting`，不发送通知 |

### `Resting` -> `Working`

必须同时满足两个条件才会回到 `Working`：

| 条件 | 说明 |
| --- | --- |
| 已经处于 `Resting` 至少 5 分钟 | 不满 5 分钟不会重新计时 |
| 5 分钟后检测到新的用户操作 | 没有新操作就继续保持 `Resting` |

一句话：休息满 5 分钟，并且你重新操作电脑，才开始下一轮工作计时。

## 安装

```bash
curl -sSL https://raw.githubusercontent.com/mctang24/pomodoro-clock/main/install.sh | bash
```

要求：macOS 13+，已安装 Swift / Xcode Command Line Tools。

## 使用

```bash
pomodoro start   # 启动菜单栏应用
pomodoro stop    # 停止菜单栏应用
```

## 项目结构

| 路径 | 说明 |
| --- | --- |
| `Sources/PomodoroCore/` | 状态机核心逻辑 |
| `Sources/Pomodoro/` | macOS 菜单栏应用 |
| `Sources/PomodoroCLI/` | CLI 入口 |
| `Sources/PomodoroSupport/` | 进程控制、运行路径、资源文件 |
| `Tests/PomodoroTests/` | 单元测试 |

## License

MIT License
