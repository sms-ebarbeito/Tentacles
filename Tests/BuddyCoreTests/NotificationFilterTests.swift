@testable import BuddyCore

private func makeNotif(bundleId: String, title: String = "", subtitle: String = "", body: String = "") -> AppNotification {
    AppNotification(recId: 1, bundleId: bundleId, title: title, subtitle: subtitle, body: body, date: .now)
}

@MainActor func runNotificationFilterTests() {
    let filter = NotificationFilter()

    suite("NotificationFilter — Slack") {

        test("pasa cuando 'Enrique' está en el body") {
            let n = makeNotif(bundleId: "com.tinyspeck.slackmacgap", body: "Enrique mandó un mensaje")
            try expect(filter.passes(n))
        }

        test("pasa cuando 'Enrique' está en el título") {
            let n = makeNotif(bundleId: "com.tinyspeck.slackmacgap", title: "Enrique", body: "hola")
            try expect(filter.passes(n))
        }

        test("pasa cuando 'Enrique' está en el subtítulo") {
            let n = makeNotif(bundleId: "com.tinyspeck.slackmacgap", subtitle: "DM de Enrique")
            try expect(filter.passes(n))
        }

        test("pasa con 'enrique' en minúscula (case insensitive)") {
            let n = makeNotif(bundleId: "com.tinyspeck.slackmacgap", body: "enrique estuvo aqui")
            try expect(filter.passes(n))
        }

        test("se bloquea sin mención de Enrique") {
            let n = makeNotif(bundleId: "com.tinyspeck.slackmacgap", title: "MELI", body: "Otro mensaje random")
            try expect(!filter.passes(n))
        }

        test("se bloquea cuando está vacío") {
            let n = makeNotif(bundleId: "com.tinyspeck.slackmacgap")
            try expect(!filter.passes(n))
        }
    }

    suite("NotificationFilter — Otras apps") {

        test("Mail siempre pasa") {
            let n = makeNotif(bundleId: "com.apple.mail", body: "cualquier cosa")
            try expect(filter.passes(n))
        }

        test("Calendar siempre pasa") {
            let n = makeNotif(bundleId: "com.apple.ical", title: "Reunión", body: "hoy, 10:00 a. m.")
            try expect(filter.passes(n))
        }

        test("App desconocida siempre pasa") {
            let n = makeNotif(bundleId: "com.alguna.app.desconocida")
            try expect(filter.passes(n))
        }
    }
}
