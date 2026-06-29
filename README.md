# Pomodoro

**English** | [简体中文](README.zh-CN.md)

Pomodoro is a lightweight macOS menu bar timer that helps you notice long work sessions and take short breaks on time.

| Working | Rest Reminder |
| --- | --- |
| ![Working](docs/images/menubar-working.png) | ![Rest notification](docs/images/rest-notification.png) |

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-111111?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-111111?style=flat-square)

## What It Does

Pomodoro runs locally and stays in the macOS menu bar. It has only two states: `Working` and `Resting`.

It does not include tasks, reports, accounts, sync, or a settings system. The goal is to keep the workflow simple: start it once, let it track active work, and get a quiet reminder when a break is due.

## How It Works

After `pomodoro start`, the app enters `Working` and shows elapsed work time in the menu bar, for example `Working · 32m`.

### `Working` -> `Resting`

Pomodoro switches to `Resting` in either case:

| Condition | Result |
| --- | --- |
| You work for 45 minutes | Sends `Time to rest`, then enters `Resting` |
| Your Mac is idle for 10 minutes | Enters `Resting` without a notification |

### `Resting` -> `Working`

Pomodoro starts the next work session only after both conditions are met:

| Condition | Result |
| --- | --- |
| `Resting` has lasted at least 5 minutes | The minimum rest period is complete |
| You use the Mac again after that period | A new `Working` session begins |

In short: take at least a 5-minute break, then return to your Mac to start the next work session.

## Install

```bash
curl -sSL https://raw.githubusercontent.com/mctang24/pomodoro-clock/main/install.sh | bash
```

Requirements: macOS 13+ with Swift / Xcode Command Line Tools installed.

## Usage

```bash
pomodoro start   # Start the menu bar app
pomodoro stop    # Stop the menu bar app
```

## Project Layout

| Path | Purpose |
| --- | --- |
| `Sources/PomodoroCore/` | Testable state machine logic |
| `Sources/Pomodoro/` | macOS menu bar app |
| `Sources/PomodoroCLI/` | Command-line entry point |
| `Sources/PomodoroSupport/` | Process control, runtime paths, and resources |
| `Tests/PomodoroTests/` | Unit tests |

## License

MIT License
