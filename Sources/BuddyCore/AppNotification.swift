import Foundation

public struct AppNotification: Equatable, Sendable {
    public let recId: Int
    public let bundleId: String
    public let title: String
    public let subtitle: String
    public let body: String
    public let date: Date

    public init(recId: Int, bundleId: String, title: String, subtitle: String, body: String, date: Date) {
        self.recId = recId
        self.bundleId = bundleId
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.date = date
    }

    public var appName: String {
        let known: [String: String] = [
            "com.tinyspeck.slackmacgap": "Slack",
            "com.apple.mail": "Mail",
            "com.apple.reminders": "Recordatorios",
            "com.apple.calendar": "Calendario",
            "com.apple.facetime": "FaceTime",
            "com.apple.mobilesms": "Mensajes",
            "com.microsoft.teams2": "Teams",
            "com.zoom.xos": "Zoom",
        ]
        return known[bundleId] ?? bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId
    }
}
