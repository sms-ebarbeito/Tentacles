import Foundation

public struct NotificationParser: Sendable {

    public init() {}

    public func parse(_ data: Data, recId: Int, bundleId: String, ts: Double) -> AppNotification? {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict  = plist as? [String: Any],
              let req   = dict["req"] as? [String: Any] else { return nil }
        let title    = req["titl"] as? String ?? ""
        let subtitle = req["subt"] as? String ?? ""
        let body     = req["body"] as? String ?? ""
        let date     = Date(timeIntervalSinceReferenceDate: ts)
        return AppNotification(recId: recId, bundleId: bundleId,
                               title: title, subtitle: subtitle, body: body, date: date)
    }
}
