@testable import BuddyCore

@MainActor func runMeetingDateParserTests() {
    let parser = MeetingDateParser()
    let cal = Calendar.current

    func hour(_ d: Date) -> Int { cal.component(.hour, from: d) }
    func minute(_ d: Date) -> Int { cal.component(.minute, from: d) }
    func day(_ d: Date) -> Int { cal.component(.day, from: d) }
    func tomorrowDay() -> Int { day(cal.date(byAdding: .day, value: 1, to: Date())!) }

    suite("MeetingDateParser — Formato español AM/PM") {

        test("hoy, 4:00 p. m. → 16:00 hoy") {
            let r = try expectNotNil(parser.parse("hoy, 4:00 p. m."))
            try expect(hour(r) == 16, "esperaba hora 16, got \(hour(r))")
            try expect(minute(r) == 0)
            try expect(cal.isDateInToday(r), "debería ser hoy")
        }

        test("hoy, 10:30 a. m. → 10:30 hoy") {
            let r = try expectNotNil(parser.parse("hoy, 10:30 a. m."))
            try expect(hour(r) == 10, "esperaba hora 10, got \(hour(r))")
            try expect(minute(r) == 30)
        }

        test("hoy, 12:00 p. m. → mediodía") {
            let r = try expectNotNil(parser.parse("hoy, 12:00 p. m."))
            try expect(hour(r) == 12, "esperaba hora 12, got \(hour(r))")
        }

        test("hoy, 12:00 a. m. → medianoche") {
            let r = try expectNotNil(parser.parse("hoy, 12:00 a. m."))
            try expect(hour(r) == 0, "esperaba hora 0, got \(hour(r))")
        }
    }

    suite("MeetingDateParser — Formato 24h") {

        test("hoy, 16:00 → 16:00") {
            let r = try expectNotNil(parser.parse("hoy, 16:00"))
            try expect(hour(r) == 16, "esperaba hora 16, got \(hour(r))")
            try expect(minute(r) == 0)
        }

        test("hoy, 9:45 → 9:45") {
            let r = try expectNotNil(parser.parse("hoy, 9:45"))
            try expect(hour(r) == 9)
            try expect(minute(r) == 45)
        }
    }

    suite("MeetingDateParser — Mañana") {

        test("mañana, 3:00 p. m. → 15:00 mañana") {
            let r = try expectNotNil(parser.parse("mañana, 3:00 p. m."))
            try expect(hour(r) == 15, "esperaba hora 15, got \(hour(r))")
            try expect(day(r) == tomorrowDay(), "debería ser mañana")
        }
    }

    suite("MeetingDateParser — Formato inglés") {

        test("today, 2:00 PM → 14:00 hoy") {
            let r = try expectNotNil(parser.parse("today, 2:00 PM"))
            try expect(hour(r) == 14, "esperaba hora 14, got \(hour(r))")
            try expect(cal.isDateInToday(r))
        }

        test("tomorrow, 10:00 AM → 10:00 mañana") {
            let r = try expectNotNil(parser.parse("tomorrow, 10:00 AM"))
            try expect(hour(r) == 10)
            try expect(day(r) == tomorrowDay())
        }
    }

    suite("MeetingDateParser — Body multilinea") {

        test("usa solo la primera línea (ignora link de Meet)") {
            let body = "hoy, 4:00 p. m.\nmeet.google.com/abc-def-ghi"
            let r = try expectNotNil(parser.parse(body))
            try expect(hour(r) == 16)
        }
    }

    suite("MeetingDateParser — Casos inválidos") {

        test("body vacío → nil") {
            try expectNil(parser.parse(""))
        }

        test("sin hora → nil") {
            try expectNil(parser.parse("Reunión de equipo"))
        }

        test("formato desconocido → nil") {
            try expectNil(parser.parse("at some point today"))
        }
    }
}
