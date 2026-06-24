import AppKit
import Darwin
import Foundation
import MachO

public struct ProcessController {
    public static let bundleIdentifier = "com.mctang24.Pomodoro"

    private static let appName = "Pomodoro"
    private static let appExecutableName = "PomodoroApp"

    private let paths: RuntimePaths

    public init(paths: RuntimePaths) {
        self.paths = paths
    }

    @MainActor
    public func startApp() async throws {
        if isAppRunning {
            print("Pomodoro is already running.")
            return
        }

        try cleanup()

        let bundleURL = try AppBundleBuilder(destinationDirectory: paths.supportDirectory).build()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        print("Pomodoro started.")
    }

    @MainActor
    public func stopApp() throws {
        let applications = runningApplications
        let processIDs = applications.map(\.processIdentifier)

        guard !applications.isEmpty else {
            try stopPIDFallback()
            return
        }

        for application in applications {
            application.terminate()
        }

        waitUntilStopped(processIDs)

        let stillRunning = processIDs.filter(isProcessAlive)
        if !stillRunning.isEmpty {
            for processID in stillRunning {
                kill(processID, SIGTERM)
            }
            waitUntilStopped(stillRunning)
        }

        guard processIDs.allSatisfy({ !isProcessAlive($0) }) else {
            throw ProcessControllerError.stopFailed
        }

        try cleanup()
        print("Pomodoro stopped.")
    }

    public func writeCurrentPID() throws {
        try writePIDRecord(pid: getpid(), executablePath: try currentExecutableURL().path)
    }

    public func cleanup() throws {
        if FileManager.default.fileExists(atPath: paths.pidFile.path) {
            try FileManager.default.removeItem(at: paths.pidFile)
        }
    }

    @MainActor
    private var isAppRunning: Bool {
        !runningApplications.isEmpty
    }

    @MainActor
    private var runningApplications: [NSRunningApplication] {
        NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier)
    }

    private func stopPIDFallback() throws {
        guard let record = readPIDRecord(), processMatches(record) else {
            try cleanup()
            print("Pomodoro is not running.")
            return
        }

        guard kill(record.pid, SIGTERM) == 0 else {
            if errno == ESRCH {
                try cleanup()
                print("Pomodoro is not running.")
                return
            }
            throw ProcessControllerError.stopFailed
        }

        for _ in 0..<20 where processMatches(record) {
            usleep(100_000)
        }

        guard !processMatches(record) else {
            throw ProcessControllerError.stopFailed
        }

        try cleanup()
        print("Pomodoro stopped.")
    }

    private func waitUntilStopped(_ processIDs: [pid_t]) {
        for _ in 0..<30 where processIDs.contains(where: isProcessAlive) {
            usleep(100_000)
        }
    }

    private func isProcessAlive(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0 || errno == EPERM
    }

    private func readPIDRecord() -> PIDRecord? {
        guard let text = try? String(contentsOf: paths.pidFile, encoding: .utf8) else {
            return nil
        }

        let lines = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        guard let pidText = lines.first, let pid = Int32(pidText.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        let executablePath = lines.dropFirst().first.map(String.init) ?? ""
        return PIDRecord(pid: pid, executablePath: executablePath)
    }

    private func writePIDRecord(pid: pid_t, executablePath: String) throws {
        try "\(pid)\n\(executablePath)\n".write(
            to: paths.pidFile,
            atomically: true,
            encoding: .utf8
        )
    }

    private func processMatches(_ record: PIDRecord) -> Bool {
        guard kill(record.pid, 0) == 0 || errno == EPERM else {
            return false
        }

        guard !record.executablePath.isEmpty else {
            return false
        }

        return processPath(pid: record.pid) == record.executablePath
    }

    private func processPath(pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 4096)
        let result = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard result > 0 else {
            return nil
        }
        return Self.string(fromNullTerminated: buffer)
    }

    private func currentExecutableURL() throws -> URL {
        try Self.currentExecutableURL()
    }

    private static func currentExecutableURL() throws -> URL {
        var size: UInt32 = 0
        _NSGetExecutablePath(nil, &size)
        var buffer = [CChar](repeating: 0, count: Int(size))

        guard _NSGetExecutablePath(&buffer, &size) == 0 else {
            throw ProcessControllerError.executablePathUnavailable
        }

        return URL(fileURLWithPath: string(fromNullTerminated: buffer)).resolvingSymlinksInPath()
    }

    private static func string(fromNullTerminated buffer: [CChar]) -> String {
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private struct AppBundleBuilder {
        let destinationDirectory: URL

        func build() throws -> URL {
            let productsDirectory = try ProcessController.currentExecutableURL().deletingLastPathComponent()
            let appExecutableURL = productsDirectory.appendingPathComponent(ProcessController.appExecutableName)

            guard FileManager.default.isExecutableFile(atPath: appExecutableURL.path) else {
                throw ProcessControllerError.appExecutableUnavailable
            }

            let bundleURL = destinationDirectory.appendingPathComponent(
                "\(ProcessController.appName).app",
                isDirectory: true
            )
            let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)
            let macOSURL = contentsURL.appendingPathComponent("MacOS", isDirectory: true)
            let resourcesURL = contentsURL.appendingPathComponent("Resources", isDirectory: true)
            let bundledExecutableURL = macOSURL.appendingPathComponent(ProcessController.appExecutableName)
            let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
            let iconURL = resourcesURL.appendingPathComponent("PomodoroIcon.icns")

            try FileManager.default.createDirectory(at: macOSURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

            if FileManager.default.fileExists(atPath: bundledExecutableURL.path) {
                try FileManager.default.removeItem(at: bundledExecutableURL)
            }
            try FileManager.default.copyItem(at: appExecutableURL, to: bundledExecutableURL)

            if FileManager.default.fileExists(atPath: iconURL.path) {
                try FileManager.default.removeItem(at: iconURL)
            }
            try FileManager.default.copyItem(at: try iconResourceURL(), to: iconURL)

            try infoPlist.write(to: infoPlistURL, atomically: true, encoding: .utf8)
            try sign(bundleURL)
            try register(bundleURL)

            return bundleURL
        }

        private func iconResourceURL() throws -> URL {
            guard let url = Bundle.module.url(forResource: "PomodoroIcon", withExtension: "icns") else {
                throw ProcessControllerError.appIconUnavailable
            }
            return url
        }

        private func register(_ bundleURL: URL) throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister")
            process.arguments = ["-f", bundleURL.path]

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                throw ProcessControllerError.appBundleRegistrationFailed
            }
        }

        private func sign(_ bundleURL: URL) throws {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
            process.arguments = ["--force", "--sign", "-", bundleURL.path]

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                throw ProcessControllerError.appBundleSigningFailed
            }
        }

        private var infoPlist: String {
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>CFBundleDevelopmentRegion</key>
                <string>en</string>
                <key>CFBundleExecutable</key>
                <string>\(ProcessController.appExecutableName)</string>
                <key>CFBundleIdentifier</key>
                <string>\(ProcessController.bundleIdentifier)</string>
                <key>CFBundleIconFile</key>
                <string>PomodoroIcon</string>
                <key>CFBundleInfoDictionaryVersion</key>
                <string>6.0</string>
                <key>CFBundleName</key>
                <string>\(ProcessController.appName)</string>
                <key>CFBundlePackageType</key>
                <string>APPL</string>
                <key>CFBundleShortVersionString</key>
                <string>0.1.0</string>
                <key>CFBundleVersion</key>
                <string>1</string>
                <key>LSUIElement</key>
                <true/>
                <key>NSHighResolutionCapable</key>
                <true/>
                <key>NSPrincipalClass</key>
                <string>NSApplication</string>
            </dict>
            </plist>
            """
        }
    }
}

private struct PIDRecord {
    let pid: pid_t
    let executablePath: String
}

public enum ProcessControllerError: LocalizedError {
    case appExecutableUnavailable
    case appIconUnavailable
    case appBundleSigningFailed
    case appBundleRegistrationFailed
    case executablePathUnavailable
    case stopFailed

    public var errorDescription: String? {
        switch self {
        case .appExecutableUnavailable:
            return "Could not find PomodoroApp. Run swift build first."
        case .appIconUnavailable:
            return "Could not find Pomodoro app icon."
        case .appBundleSigningFailed:
            return "Could not sign Pomodoro.app."
        case .appBundleRegistrationFailed:
            return "Could not register Pomodoro.app."
        case .executablePathUnavailable:
            return "Could not resolve current executable path."
        case .stopFailed:
            return "Could not stop Pomodoro."
        }
    }
}
