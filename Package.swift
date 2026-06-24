// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Pomodoro",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "pomodoro", targets: ["PomodoroCLI"])
    ],
    targets: [
        .target(
            name: "PomodoroCore",
            path: "Sources/PomodoroCore"
        ),
        .target(
            name: "PomodoroSupport",
            path: "Sources/PomodoroSupport",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "PomodoroApp",
            dependencies: ["PomodoroCore", "PomodoroSupport"],
            path: "Sources/Pomodoro"
        ),
        .executableTarget(
            name: "PomodoroCLI",
            dependencies: ["PomodoroSupport"],
            path: "Sources/PomodoroCLI"
        ),
        .testTarget(
            name: "PomodoroTests",
            dependencies: ["PomodoroCore"],
            path: "Tests/PomodoroTests"
        )
    ]
)
