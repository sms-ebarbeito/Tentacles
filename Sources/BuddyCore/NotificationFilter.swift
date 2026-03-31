import Foundation

public struct NotificationFilter: Sendable {

    public static let calendarBundles: Set<String> = [
        "com.apple.ical",
        "com.apple.calendar",
    ]

    public init() {}

    /// Devuelve true si la notificación debe mostrarse según las reglas configuradas.
    /// - Slack: solo si el texto menciona "Enrique"
    /// - Resto de apps: pasan todas
    public func passes(_ n: AppNotification) -> Bool {
        if n.bundleId == "com.tinyspeck.slackmacgap" {
            let text = "\(n.title) \(n.subtitle) \(n.body)"
            return text.localizedCaseInsensitiveContains("Enrique")
        }
        return true
    }
}
