import Foundation

@MainActor func runAll() {
    runNotificationFilterTests()
    runNotificationParserTests()
    runMeetingDateParserTests()
    results()
}

RunLoop.main.perform { Task { @MainActor in runAll() } }
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))
