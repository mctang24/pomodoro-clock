import Foundation

public enum PomodoroStatus: Equatable {
    case resting
    case working(startedAt: Date)
}

public struct PomodoroStateMachine {
    public static let restProtection: TimeInterval = 5 * 60
    public static let workLimit: TimeInterval = 45 * 60
    public static let idleLimit: TimeInterval = 10 * 60
    public static let recentActivityLimit: TimeInterval = 5

    public private(set) var status: PomodoroStatus
    private var restingStartedAt: Date
    public init(now: Date) {
        status = .working(startedAt: now)
        restingStartedAt = now
    }

    public mutating func tick(now: Date, idleSeconds: TimeInterval) -> PomodoroEvent? {
        switch status {
        case .resting:
            guard now.timeIntervalSince(restingStartedAt) >= Self.restProtection else {
                return nil
            }

            if idleSeconds <= Self.recentActivityLimit {
                status = .working(startedAt: now)
            }
            return nil

        case .working(let startedAt):
            if idleSeconds >= Self.idleLimit {
                enterResting(now: now)
                return nil
            }

            if now.timeIntervalSince(startedAt) >= Self.workLimit {
                enterResting(now: now)
                return .timeToRest
            }

            return nil
        }
    }

    public func title(now: Date) -> String {
        switch status {
        case .resting:
            return "Resting"
        case .working(let startedAt):
            let minutes = max(0, Int(now.timeIntervalSince(startedAt) / 60))
            return "Working · \(minutes)m"
        }
    }

    private mutating func enterResting(now: Date) {
        status = .resting
        restingStartedAt = now
    }
}

public enum PomodoroEvent {
    case timeToRest
}
