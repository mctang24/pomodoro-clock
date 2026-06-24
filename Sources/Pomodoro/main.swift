import Foundation
import PomodoroSupport

do {
    try run()
} catch {
    fputs("Pomodoro: \(error.localizedDescription)\n", stderr)
    Foundation.exit(1)
}

@MainActor
private func run() throws {
    runMenuBarApp(paths: try RuntimePaths.live(create: true))
}
