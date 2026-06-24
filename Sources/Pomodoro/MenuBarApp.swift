import AppKit
import Foundation
import PomodoroCore
import PomodoroSupport
import Dispatch

@MainActor
final class MenuBarApp: NSObject, NSApplicationDelegate {
    private let paths: RuntimePaths
    private let processController: ProcessController
    private let activityMonitor = ActivityMonitor()
    private let notificationClient = NotificationClient()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var state = PomodoroStateMachine(now: Date())
    private var timer: Timer?
    private var terminationSignal: DispatchSourceSignal?

    init(paths: RuntimePaths) {
        self.paths = paths
        self.processController = ProcessController(paths: paths)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { NSApp.terminate(nil) }
        source.resume()
        terminationSignal = source

        try? processController.writeCurrentPID()
        notificationClient.requestAuthorization()
        updateStatusTitle(now: Date())

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        terminationSignal?.cancel()
        try? processController.cleanup()
    }

    private func updateStatusTitle(now: Date) {
        guard let button = statusItem.button else {
            return
        }

        let title = state.title(now: now)
        switch state.status {
        case .resting:
            button.attributedTitle = NSAttributedString(
                string: title,
                attributes: [.foregroundColor: NSColor.systemOrange]
            )
        case .working:
            button.attributedTitle = NSAttributedString(string: title)
        }
    }

    private func tick() {
        let now = Date()
        let event = state.tick(now: now, idleSeconds: activityMonitor.idleSeconds())
        updateStatusTitle(now: now)

        if event == .timeToRest {
            notificationClient.sendTimeToRest()
        }
    }
}

@MainActor
func runMenuBarApp(paths: RuntimePaths) {
    let app = NSApplication.shared
    let delegate = MenuBarApp(paths: paths)
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
    _ = delegate
}
