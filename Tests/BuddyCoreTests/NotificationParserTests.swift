@testable import BuddyCore
import Foundation

private func makeBplist(titl: String, subt: String = "", body: String = "") -> Data {
    let dict: [String: Any] = [
        "req": ["titl": titl, "subt": subt, "body": body] as [String: Any]
    ]
    return try! PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
}

@MainActor func runNotificationParserTests() {
    let parser = NotificationParser()
    let cal = Calendar.current

    suite("NotificationParser") {

        test("parsea título, subtítulo y body") {
            let data = makeBplist(titl: "MELI", subt: "#team-clips", body: "Hola equipo")
            let r = try expectNotNil(parser.parse(data, recId: 1, bundleId: "com.tinyspeck.slackmacgap", ts: 0))
            try expect(r.title == "MELI", "title: \(r.title)")
            try expect(r.subtitle == "#team-clips", "subtitle: \(r.subtitle)")
            try expect(r.body == "Hola equipo", "body: \(r.body)")
        }

        test("parsea campos vacíos sin crashear") {
            let data = makeBplist(titl: "")
            let r = try expectNotNil(parser.parse(data, recId: 2, bundleId: "com.apple.mail", ts: 0))
            try expect(r.title == "" && r.subtitle == "" && r.body == "")
        }

        test("preserva recId y bundleId") {
            let data = makeBplist(titl: "test")
            let r = try expectNotNil(parser.parse(data, recId: 42, bundleId: "com.apple.ical", ts: 0))
            try expect(r.recId == 42, "recId: \(r.recId)")
            try expect(r.bundleId == "com.apple.ical", "bundleId: \(r.bundleId)")
        }

        test("convierte timestamp Core Data (ts=0 → referenceDate de Apple)") {
            let data = makeBplist(titl: "test")
            let r = try expectNotNil(parser.parse(data, recId: 1, bundleId: "x", ts: 0))
            // Date(timeIntervalSinceReferenceDate: 0) == 2001-01-01 00:00:00 UTC
            // Comparamos directamente contra la fecha de referencia de Apple
            try expect(r.date == Date(timeIntervalSinceReferenceDate: 0),
                       "esperaba referenceDate, got \(r.date)")
        }

        test("data inválida → nil") {
            let garbage = Data([0x00, 0x01, 0x02])
            try expectNil(parser.parse(garbage, recId: 1, bundleId: "x", ts: 0))
        }

        test("data sin clave 'req' → nil") {
            let dict: [String: Any] = ["app": "com.apple.test"]
            let data = try! PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
            try expectNil(parser.parse(data, recId: 1, bundleId: "x", ts: 0))
        }
    }
}
