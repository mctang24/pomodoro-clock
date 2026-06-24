import Foundation

public struct RuntimePaths {
    public let supportDirectory: URL
    public let pidFile: URL

    public static func live(create: Bool) throws -> RuntimePaths {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: create
        )
        let supportDirectory = base.appendingPathComponent("Pomodoro", isDirectory: true)

        if create {
            try FileManager.default.createDirectory(
                at: supportDirectory,
                withIntermediateDirectories: true
            )
        }

        return RuntimePaths(
            supportDirectory: supportDirectory,
            pidFile: supportDirectory.appendingPathComponent("pomodoro.pid")
        )
    }
}
