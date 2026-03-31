import Foundation

public struct MeetingDateParser: Sendable {

    public init() {}

    /// Parsea la hora del evento desde el body de una notificación de Calendar.
    /// Formatos soportados: "hoy, 4:00 p. m." / "hoy, 16:00" / "mañana, 10:00 a. m." / "today, 2:00 PM"
    /// Retorna nil si no puede determinar la fecha.
    public func parse(_ body: String) -> Date? {
        let now = Date()
        let cal = Calendar.current
        let lines = body.components(separatedBy: "\n")
        guard let firstLine = lines.first, !firstLine.isEmpty else { return nil }

        // Normalizar: "p. m." → "PM", "a. m." → "AM"
        var normalized = firstLine
            .replacingOccurrences(of: "p. m.", with: "PM")
            .replacingOccurrences(of: "a. m.", with: "AM")
            .replacingOccurrences(of: "p.m.", with: "PM")
            .replacingOccurrences(of: "a.m.", with: "AM")

        var baseDate: Date = now
        var matched = false

        let dayPrefixes: [(String, Int)] = [
            ("mañana", 1), ("tomorrow", 1), ("hoy", 0), ("today", 0)
        ]
        for (prefix, offset) in dayPrefixes {
            if normalized.lowercased().hasPrefix(prefix) {
                baseDate = cal.date(byAdding: .day, value: offset, to: now) ?? now
                if let commaRange = normalized.range(of: ", ") {
                    normalized = String(normalized[commaRange.upperBound...])
                } else {
                    normalized = String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                }
                matched = true
                break
            }
        }

        guard matched else { return nil }

        let fmts = ["h:mm a", "HH:mm", "h:mm"]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        for fmt in fmts {
            df.dateFormat = fmt
            if let parsed = df.date(from: normalized) {
                let comps = cal.dateComponents(in: TimeZone.current, from: parsed)
                return cal.date(bySettingHour: comps.hour ?? 0,
                                minute: comps.minute ?? 0,
                                second: 0, of: baseDate)
            }
        }
        return nil
    }
}
