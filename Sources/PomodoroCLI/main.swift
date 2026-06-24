import Foundation
import PomodoroSupport

@main
enum PomodoroCLI {
    @MainActor
    static func main() async {
        do {
            try await run()
        } catch {
            fputs("pomodoro: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    @MainActor
    private static func run() async throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let controller = ProcessController(paths: try RuntimePaths.live(create: arguments.first == "start"))

        switch arguments.first {
        case "start":
            try await controller.startApp()
        case "stop":
            try controller.stopApp()
        default:
            print("Usage: pomodoro start | pomodoro stop")
            Foundation.exit(2)
        }
    }
}
