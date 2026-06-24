import CoreGraphics
import Foundation

struct ActivityMonitor {
    func idleSeconds() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)!
        )
    }
}
