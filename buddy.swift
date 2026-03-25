import Cocoa
import SQLite3

// MARK: - Logger

func log(_ msg: String) {
    let path = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("buddy.log").path
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(msg)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: path) {
            if let fh = FileHandle(forWritingAtPath: path) {
                fh.seekToEndOfFile()
                fh.write(data)
                fh.closeFile()
            }
        } else {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}

// MARK: - Modelo

struct AppNotification: Equatable {
    let recId: Int
    let bundleId: String
    let title: String
    let subtitle: String
    let body: String
    let date: Date

    var appName: String {
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

// MARK: - Lector de DB

class NotificationReader {
    private let dbPath: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        dbPath = "\(home)/Library/Group Containers/group.com.apple.usernoted/db2/db"
    }

    func readActive() -> [AppNotification] {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOFOLLOW
        guard sqlite3_open_v2(dbPath, &db, flags, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_close(db) }

        let sql = """
            SELECT r.rec_id, a.identifier, r.data, r.delivered_date, r.presented
            FROM record r
            JOIN app a ON r.app_id = a.app_id
            WHERE r.presented = 1
               OR a.identifier IN ('com.apple.ical', 'com.apple.calendar')
            ORDER BY r.delivered_date DESC
            LIMIT 80
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var results: [AppNotification] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let recId       = Int(sqlite3_column_int(stmt, 0))
            let bundleId    = String(cString: sqlite3_column_text(stmt, 1))
            let deliveredTs = sqlite3_column_double(stmt, 3)
            let presented   = sqlite3_column_int(stmt, 4)
            guard let dataPtr = sqlite3_column_blob(stmt, 2) else { continue }
            let data = Data(bytes: dataPtr, count: Int(sqlite3_column_bytes(stmt, 2)))
            if let n = parse(data, recId: recId, bundleId: bundleId, ts: deliveredTs) {
                log("DB rec_id=\(recId) presented=\(presented) bundle=\(bundleId) titl=\(n.title) body=\(n.body.prefix(60))")
                if passes(n) { results.append(n) }
            }
        }
        return results
    }

    // Bundle IDs conocidos de Calendar (puede variar)
    static let calendarBundles: Set<String> = [
        "com.apple.ical",
        "com.apple.calendar",
    ]

    // Reglas de filtrado:
    // - Slack: solo si el mensaje menciona "Enrique"
    // - Resto de apps: pasan todas
    private func passes(_ n: AppNotification) -> Bool {
        if n.bundleId == "com.tinyspeck.slackmacgap" {
            let text = "\(n.title) \(n.subtitle) \(n.body)"
            return text.localizedCaseInsensitiveContains("Enrique")
        }
        return true
    }

    private func parse(_ data: Data, recId: Int, bundleId: String, ts: Double) -> AppNotification? {
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

// MARK: - Pixel art del pulpo

enum Sprite {
    static let pixelSize: CGFloat = 5

    // Paleta de colores retro
    static let palette: [Character: NSColor] = [
        ".": .clear,
        "B": NSColor(red: 0.58, green: 0.18, blue: 0.78, alpha: 1.0),  // cuerpo violeta
        "D": NSColor(red: 0.28, green: 0.04, blue: 0.42, alpha: 1.0),  // contorno oscuro
        "E": NSColor(red: 0.96, green: 0.94, blue: 1.00, alpha: 1.0),  // ojo blanco
        "P": NSColor(red: 0.10, green: 0.02, blue: 0.18, alpha: 1.0),  // pupila
    ]

    // Idle: tentáculos abajo
    static let idle0: [String] = [
        "..DDDDDD..",
        ".DBBBBBBD.",
        ".DBEPEPBD.",
        ".DBBBBBBD.",
        ".DBBBBBBD.",
        "..DDDDDD..",
        ".D.DD.DD..",
        "D...D..D..",
        "D...D..D..",
        ".D.....D..",
    ]

    // Idle: tentáculos alternados (bob)
    static let idle1: [String] = [
        "..DDDDDD..",
        ".DBBBBBBD.",
        ".DBEPEPBD.",
        ".DBBBBBBD.",
        ".DBBBBBBD.",
        "..DDDDDD..",
        "D..DD.DD.D",
        ".D..D..D..",
        "..D.D..D..",
        "...D....D.",
    ]

    // Alert: ojos abiertos, salto (frame A)
    static let alert0: [String] = [
        "..DDDDDD..",
        ".DBBBBBBD.",
        ".DEPBBEPD.",
        ".DBBBBBBD.",
        ".DBBBBBBD.",
        "..DDDDDD..",
        "D..DD.DD.D",
        ".D.....D..",
        "D.......D.",
        ".D.....D..",
    ]

    // Alert: ojos abiertos (frame B)
    static let alert1: [String] = [
        "..DDDDDD..",
        ".DBBBBBBD.",
        ".DEPBBEPD.",
        ".DBBBBBBD.",
        ".DBBBBBBD.",
        "..DDDDDD..",
        ".D.DD.DD..",
        "D...D..D..",
        ".D..D..D..",
        "..D....D..",
    ]

    // Squish: aplastado al caer
    static let squish: [String] = [
        "..DDDDDD..",
        ".DBBBBBBD.",
        ".DBBBBBBD.",
        ".DEPBBEPD.",
        ".DBBBBBBD.",
        "..DDDDDD..",
        "DD.DD.DDDD",
        ".D......D.",
        "..D....D..",
        "...D..D...",
    ]

    static let cols = 10
    static let rows = 10
    static var size: CGSize {
        CGSize(width: CGFloat(cols) * pixelSize, height: CGFloat(rows) * pixelSize)
    }
}

// MARK: - Vista del pulpo

class OctopusView: NSView {
    var frame_pixels: [String] = Sprite.idle0
    private weak var controller: BuddyController?

    init(controller: BuddyController) {
        self.controller = controller
        let size = Sprite.size
        super.init(frame: NSRect(origin: .zero, size: size))

        // Sombra para visibilidad sobre cualquier fondo
        wantsLayer = true
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        self.shadow = shadow
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        let ps = Sprite.pixelSize
        for (row, line) in frame_pixels.enumerated() {
            for (col, char) in line.enumerated() {
                guard let color = Sprite.palette[char], char != "." else { continue }
                color.setFill()
                let rect = NSRect(
                    x: CGFloat(col) * ps,
                    y: bounds.height - CGFloat(row + 1) * ps,
                    width: ps,
                    height: ps
                )
                NSBezierPath(rect: rect).fill()
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        controller?.stopCrazy()
        controller?.togglePanel()
    }

    // Cursor de mano al pasar por encima
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

// MARK: - Panel de notificaciones

class NotificationRow: NSView {
    private let appLabel  = NSTextField(labelWithString: "")
    private let timeLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let bodyLabel  = NSTextField(labelWithString: "")

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
        layer?.cornerRadius = 6

        appLabel.font  = .systemFont(ofSize: 9, weight: .bold)
        appLabel.textColor = NSColor(red: 0.72, green: 0.45, blue: 0.95, alpha: 1)
        timeLabel.font = .systemFont(ofSize: 9)
        timeLabel.textColor = NSColor.white.withAlphaComponent(0.35)
        timeLabel.alignment = .right
        titleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.font = .systemFont(ofSize: 10)
        bodyLabel.textColor = NSColor.white.withAlphaComponent(0.65)
        bodyLabel.maximumNumberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail

        for v in [appLabel, timeLabel, titleLabel, bodyLabel] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }
        NSLayoutConstraint.activate([
            appLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            appLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            appLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -4),

            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
            timeLabel.widthAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: appLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -7),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with n: AppNotification) {
        appLabel.stringValue = n.appName.uppercased()
        titleLabel.stringValue = n.title.isEmpty ? n.appName : n.title
        let text = [n.subtitle, n.body].filter { !$0.isEmpty }.joined(separator: " · ")
        bodyLabel.stringValue = text
        bodyLabel.isHidden = text.isEmpty

        let fmt = DateFormatter()
        fmt.dateFormat = Calendar.current.isDateInToday(n.date) ? "HH:mm" : "dd/MM"
        timeLabel.stringValue = fmt.string(from: n.date)
    }
}

// MARK: - Recordatorio de meeting

struct MeetingReminder {
    let notifId: Int       // rec_id de la notificación original
    let title: String
    let fiveMinTimer: Timer
    let zeroMinTimer: Timer
}

// MARK: - Controlador principal

class BuddyController: NSObject {

    // Ventana del pulpo
    private var octopusWindow: NSPanel!
    private var octopusView: OctopusView!

    // Panel de notificaciones
    private var panel: NSPanel!
    private var stackView: NSStackView!
    private var emptyLabel: NSTextField!
    private var panelVisible = false

    // Estado
    private let reader = NotificationReader()
    private var lastNotifications: [AppNotification] = []
    private var pollTimer: Timer?

    // Animación
    private var animTimer: Timer?
    private var animFrame = 0
    private var isAlertMode = false
    private var alertCycles = 0
    private var crazyMode = false   // meeting inminente: animación sin parar

    // Recordatorios de meetings (evita duplicados por rec_id)
    private var meetingReminders: [Int: MeetingReminder] = [:]

    // Secuencia de animación: idle=bob suave, alert=salto+squish
    private let idleSequence: [[String]] = [
        Sprite.idle0, Sprite.idle0,
        Sprite.idle1, Sprite.idle1,
    ]
    private let alertSequence: [[String]] = [
        Sprite.alert0, Sprite.alert1,
        Sprite.alert0, Sprite.squish,
        Sprite.alert1, Sprite.alert0,
        Sprite.alert1, Sprite.squish,
    ]

    func start() {
        log("Buddy arrancó")
        buildOctopusWindow()
        buildNotificationPanel()
        startAnimation()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.poll()
        }
        poll()
    }

    // MARK: - Construcción de ventanas

    private func buildOctopusWindow() {
        let size = Sprite.size
        octopusView = OctopusView(controller: self)

        octopusWindow = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        octopusWindow.level = .floating
        octopusWindow.isOpaque = false
        octopusWindow.backgroundColor = .clear
        octopusWindow.hasShadow = false
        octopusWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        octopusWindow.isMovableByWindowBackground = true
        octopusWindow.contentView = octopusView

        // Posición: esquina inferior derecha
        if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let x = sf.maxX - size.width - 16
            let y = sf.minY + 16
            octopusWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }
        octopusWindow.makeKeyAndOrderFront(nil)
    }

    private func buildNotificationPanel() {
        let panelWidth: CGFloat  = 290
        let panelHeight: CGFloat = 360

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]

        // Fondo
        let bg = NSView()
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor(white: 0.10, alpha: 0.93).cgColor
        bg.layer?.cornerRadius = 10
        bg.translatesAutoresizingMaskIntoConstraints = false

        let header = NSTextField(labelWithString: "NOTIFICACIONES")
        header.font = .systemFont(ofSize: 10, weight: .bold)
        header.textColor = NSColor(red: 0.72, green: 0.45, blue: 0.95, alpha: 0.9)
        header.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel = NSTextField(labelWithString: "No hay notificaciones")
        emptyLabel.font = .systemFont(ofSize: 11)
        emptyLabel.textColor = NSColor.white.withAlphaComponent(0.3)
        emptyLabel.alignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 5
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.documentView = stackView
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(bg)
        container.addSubview(header)
        container.addSubview(scroll)
        container.addSubview(emptyLabel)
        container.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = container

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: container.topAnchor),
            bg.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            header.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            header.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 5),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),

            emptyLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            stackView.widthAnchor.constraint(equalTo: scroll.widthAnchor),
        ])
    }

    // MARK: - Mostrar/ocultar panel

    func togglePanel() {
        if panelVisible {
            panel.orderOut(nil)
            panelVisible = false
        } else {
            repositionPanel()
            panel.makeKeyAndOrderFront(nil)
            panelVisible = true
        }
    }

    private func repositionPanel() {
        guard let of = octopusWindow?.frame,
              let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let pw = panel.frame.width
        let ph = panel.frame.height

        // Centrado sobre el pulpo, clampeado dentro de la pantalla
        let px = min(of.minX + of.width / 2 - pw / 2, sf.maxX - pw - 4)
        let py = min(of.maxY + 8, sf.maxY - ph - 4)
        panel.setFrameOrigin(NSPoint(x: max(px, sf.minX + 4), y: py))
    }

    // MARK: - Polling

    private func poll() {
        let notifications = reader.readActive()
        let hasNew = notifications.first.map { !lastNotifications.contains($0) } ?? false
        if hasNew && !lastNotifications.isEmpty {
            triggerAlert()
        }
        if notifications != lastNotifications {
            // Detectar nuevas notificaciones de Calendario
            let knownIds = Set(lastNotifications.map { $0.recId })
            let newCalendar = notifications.filter {
                NotificationReader.calendarBundles.contains($0.bundleId) && !knownIds.contains($0.recId)
            }
            for n in newCalendar {
                scheduleMeetingReminders(for: n)
            }
            lastNotifications = notifications
            DispatchQueue.main.async { self.updatePanel(notifications) }
        }
    }

    // MARK: - Recordatorios de meeting

    private func scheduleMeetingReminders(for n: AppNotification) {
        guard meetingReminders[n.recId] == nil else { return }

        log("MEETING detectado rec_id=\(n.recId) titl=\(n.title) body=\(n.body)")

        // Intentar extraer la hora del evento del body ("hoy, 4:00 p. m.")
        // Si no se puede parsear, asumir que el evento es en 10 minutos (comportamiento anterior)
        // Si no se puede parsear la hora del body, asumir que el evento es ahora mismo
        let meetingDate = parseMeetingDate(from: n.body) ?? n.date
        let now = Date()

        log("MEETING fecha parseada=\(meetingDate) secsToMeeting=\(Int(meetingDate.timeIntervalSince(now)))")

        // Calcular delays relativos a ahora
        let secsToMeeting   = meetingDate.timeIntervalSince(now)
        let secsToFiveMin   = secsToMeeting - 5 * 60

        // Solo programar si la reunión es en el futuro
        guard secsToMeeting > 0 else {
            log("MEETING ignorada, ya pasó (secsToMeeting=\(Int(secsToMeeting)))")
            return
        }

        var t5: Timer? = nil
        if secsToFiveMin > 0 {
            t5 = Timer.scheduledTimer(withTimeInterval: secsToFiveMin, repeats: false) { [weak self] _ in
                self?.fireMeetingWarning(title: n.title, minutesLeft: 5)
            }
        } else if secsToMeeting > 60 {
            // Menos de 5 min pero todavía falta → aviso inmediato con minutos reales
            let minsLeft = max(1, Int(secsToMeeting / 60))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.fireMeetingWarning(title: n.title, minutesLeft: minsLeft)
            }
        }

        let t0 = Timer.scheduledTimer(withTimeInterval: secsToMeeting, repeats: false) { [weak self] _ in
            self?.fireMeetingNow(title: n.title)
        }

        meetingReminders[n.recId] = MeetingReminder(
            notifId: n.recId, title: n.title,
            fiveMinTimer: t5 ?? t0,   // t5 puede ser nil si ya pasó
            zeroMinTimer: t0
        )
    }

    // Parsea la hora del evento desde el body de Calendar
    // Formatos conocidos: "hoy, 4:00 p. m." / "hoy, 16:00" / "mañana, 10:00 a. m."
    private func parseMeetingDate(from body: String) -> Date? {
        let now = Date()
        let cal = Foundation.Calendar.current
        let lines = body.components(separatedBy: "\n")
        guard let firstLine = lines.first else { return nil }

        // Normalizar: "p. m." → "PM", "a. m." → "AM"
        var normalized = firstLine
            .replacingOccurrences(of: "p. m.", with: "PM")
            .replacingOccurrences(of: "a. m.", with: "AM")
            .replacingOccurrences(of: "p.m.", with: "PM")
            .replacingOccurrences(of: "a.m.", with: "AM")

        var baseDate: Date = now

        // Extraer prefijo de día y dejar solo la hora
        let dayPrefixes: [(String, Int)] = [
            ("mañana", 1), ("tomorrow", 1), ("hoy", 0), ("today", 0)
        ]
        for (prefix, offset) in dayPrefixes {
            if normalized.lowercased().hasPrefix(prefix) {
                baseDate = cal.date(byAdding: .day, value: offset, to: now) ?? now
                // Quitar todo hasta después de la primera coma+espacio
                if let commaRange = normalized.range(of: ", ") {
                    normalized = String(normalized[commaRange.upperBound...])
                } else {
                    normalized = String(normalized.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                }
                break
            }
        }

        // Intentar parsear la hora (en zona horaria local)
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

    private func fireMeetingWarning(title: String, minutesLeft: Int) {
        log("MEETING aviso \(minutesLeft) min para: \(title)")
        DispatchQueue.main.async {
            self.triggerAlert(cycles: 4)
            self.showMeetingBanner(text: "⏰ \(title)", detail: "Empieza en \(minutesLeft) minutos")
        }
    }

    private func fireMeetingNow(title: String) {
        log("MEETING ahora: \(title)")
        DispatchQueue.main.async {
            self.triggerCrazy()
            self.showMeetingBanner(text: "🔴 \(title)", detail: "¡Ahora!")
        }
    }

    private func updatePanel(_ notifications: [AppNotification]) {
        for v in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        emptyLabel.isHidden = !notifications.isEmpty

        for n in notifications.prefix(40) {
            let row = NotificationRow(frame: NSRect(x: 0, y: 0, width: 278, height: 66))
            row.configure(with: n)
            row.widthAnchor.constraint(equalToConstant: 278).isActive = true
            stackView.addArrangedSubview(row)
        }
    }

    // MARK: - Animación

    private func startAnimation() {
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.stepAnimation()
        }
    }

    private func stepAnimation() {
        if isAlertMode {
            animFrame = (animFrame + 1) % alertSequence.count
            if animFrame == 0 { alertCycles += 1 }
            // crazyMode no para; alertMode normal para después de N ciclos
            if !crazyMode && alertCycles >= alertCyclesTarget {
                isAlertMode = false
                alertCycles = 0
                animTimer?.invalidate()
                animTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                    self?.stepAnimation()
                }
            }
            setFrame(alertSequence[animFrame])
        } else {
            animFrame = (animFrame + 1) % idleSequence.count
            setFrame(idleSequence[animFrame])
        }
    }

    private var alertCyclesTarget = 2

    private func setFrame(_ pixels: [String]) {
        DispatchQueue.main.async {
            self.octopusView.frame_pixels = pixels
            self.octopusView.needsDisplay = true
        }
    }

    func triggerAlert(cycles: Int = 2) {
        crazyMode = false
        alertCyclesTarget = cycles
        isAlertMode = true
        alertCycles = 0
        animFrame = 0
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.stepAnimation()
        }
    }

    func triggerCrazy() {
        // Animación sin parar hasta que el usuario haga click
        crazyMode = true
        isAlertMode = true
        alertCycles = 0
        animFrame = 0
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] _ in
            self?.stepAnimation()
        }
    }

    func stopCrazy() {
        guard crazyMode else { return }
        crazyMode = false
        isAlertMode = false
        animTimer?.invalidate()
        startAnimation()
    }

    // MARK: - Banner de meeting

    private var bannerWindow: NSPanel?

    private func showMeetingBanner(text: String, detail: String) {
        bannerWindow?.orderOut(nil)

        let bw: CGFloat = 260
        let bh: CGFloat = 52

        let win = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: bw, height: bh),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered, defer: false
        )
        win.level = .screenSaver
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]

        let bg = NSView()
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor(red: 0.75, green: 0.1, blue: 0.1, alpha: 0.95).cgColor
        bg.layer?.cornerRadius = 10
        bg.translatesAutoresizingMaskIntoConstraints = false

        let mainLabel = NSTextField(labelWithString: text)
        mainLabel.font = .systemFont(ofSize: 12, weight: .bold)
        mainLabel.textColor = .white
        mainLabel.translatesAutoresizingMaskIntoConstraints = false

        let detailLabel = NSTextField(labelWithString: detail)
        detailLabel.font = .systemFont(ofSize: 10)
        detailLabel.textColor = NSColor.white.withAlphaComponent(0.8)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeBtn = NSButton(title: "✕", target: nil, action: nil)
        closeBtn.bezelStyle = .inline
        closeBtn.isBordered = false
        closeBtn.font = .systemFont(ofSize: 11, weight: .bold)
        closeBtn.contentTintColor = NSColor.white.withAlphaComponent(0.7)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(bg)
        container.addSubview(mainLabel)
        container.addSubview(detailLabel)
        container.addSubview(closeBtn)
        win.contentView = container

        // Capturar win débilmente para el botón de cierre
        let winRef = win
        closeBtn.target = winRef
        closeBtn.action = #selector(NSWindow.orderOut(_:))

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: container.topAnchor),
            bg.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            closeBtn.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            closeBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            closeBtn.widthAnchor.constraint(equalToConstant: 16),
            closeBtn.heightAnchor.constraint(equalToConstant: 16),

            mainLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 9),
            mainLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            mainLabel.trailingAnchor.constraint(equalTo: closeBtn.leadingAnchor, constant: -4),
            detailLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 2),
            detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
        ])

        // Posición: encima del pulpo
        if let of = octopusWindow?.frame, let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let bx = min(of.minX + of.width / 2 - bw / 2, sf.maxX - bw - 4)
            let by = of.maxY + 8
            win.setFrameOrigin(NSPoint(x: max(bx, sf.minX + 4), y: by))
        }

        win.makeKeyAndOrderFront(nil)
        bannerWindow = win

        // Auto-cierre a los 8 segundos (para el aviso de 5 min)
        // El de "ahora" no se cierra solo — lo cierra el click en el pulpo
        if !crazyMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak win] in
                win?.orderOut(nil)
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = BuddyController()
    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
