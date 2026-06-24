import Foundation
import XCTest
@testable import PomodoroCore

final class StateMachineTests: XCTestCase {
    func testStartsWorking() {
        let now = Date()
        let machine = PomodoroStateMachine(now: now)

        XCTAssertEqual(machine.title(now: now), "Working · 0m")
    }

    func testUsesFullRestProtectionAfterReturningToRest() {
        let now = Date()
        var machine = PomodoroStateMachine(now: now)
        let workStart = now

        let restStart = workStart.addingTimeInterval(60)
        _ = machine.tick(
            now: restStart,
            idleSeconds: PomodoroStateMachine.idleLimit
        )

        _ = machine.tick(
            now: restStart.addingTimeInterval(PomodoroStateMachine.restProtection - 1),
            idleSeconds: 0
        )

        XCTAssertEqual(machine.title(now: restStart.addingTimeInterval(PomodoroStateMachine.restProtection - 1)), "Resting")

        _ = machine.tick(
            now: restStart.addingTimeInterval(PomodoroStateMachine.restProtection),
            idleSeconds: 0
        )

        XCTAssertEqual(machine.title(now: restStart.addingTimeInterval(PomodoroStateMachine.restProtection)), "Working · 0m")
    }

    func testIdleWorkReturnsToRestWithoutNotification() {
        let now = Date()
        var machine = PomodoroStateMachine(now: now)
        let workStart = now

        let event = machine.tick(
            now: workStart.addingTimeInterval(60),
            idleSeconds: PomodoroStateMachine.idleLimit
        )

        XCTAssertNil(event)
        XCTAssertEqual(machine.title(now: workStart.addingTimeInterval(60)), "Resting")
    }

    func testWorkLimitReturnsToRestWithNotification() {
        let now = Date()
        var machine = PomodoroStateMachine(now: now)
        let workStart = now

        let event = machine.tick(
            now: workStart.addingTimeInterval(PomodoroStateMachine.workLimit),
            idleSeconds: 0
        )

        XCTAssertEqual(event, .timeToRest)
        XCTAssertEqual(machine.title(now: workStart.addingTimeInterval(PomodoroStateMachine.workLimit)), "Resting")
    }
}
