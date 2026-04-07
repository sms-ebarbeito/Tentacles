import Cocoa
import BuddyCore

struct MeetingReminder {
    let notifId: Int
    let title: String
    let fiveMinTimer: Timer
    let zeroMinTimer: Timer
}

@MainActor
class BuddyController: NSObject, NSWindowDelegate {

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
    private var alertCyclesTarget = 2
    private var crazyMode = false

    // Saltos desde home (esquina derecha): 0 = home, +N = N saltos a la izquierda
    private var jumpOffset = 0
    private var idleStepCount = 0
    private static let maxJumpsLeft = 4
    private static let idleStepsBeforeJump = 16  // ~8s a 0.5s por frame
    private static let idleStepsBeforeBoring = 30  // ~15s a 0.5s por frame

    // Recordatorios de meetings (evita duplicados por rec_id)
    private var meetingReminders: [Int: MeetingReminder] = [:]

    // Servidor HTTP
    private var server = BuddyServer()

    // Globo de Claude
    private var claudeBubble: NSPanel?

    // Panel debug
    private var debugPanel: NSPanel?
    private var debugLoopMode = false

    // Banner de meeting
    private var bannerWindow: NSPanel?

    // Secuencias de animación
    private let idleSequence: [SpriteFrame] = Sprite.idle
    private let alertSequence: [SpriteFrame] = Sprite.alert + Sprite.crazy + Sprite.alert2 + Sprite.alert3 + Sprite.alert4
    private let crazySequence: [SpriteFrame] = Sprite.crazy

    func start() {
        log("Buddy arrancó")
        server.controller = self
        server.start()
        buildOctopusWindow()
        buildNotificationPanel()
        startAnimation()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.poll() }
        }
        poll()
    }

    // MARK: - Construcción de ventanas

    private func buildOctopusWindow() {
        let size = Sprite.displaySize
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
        panel.isMovableByWindowBackground = true

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
            let knownIds = Set(lastNotifications.map { $0.recId })
            let newCalendar = notifications.filter {
                NotificationFilter.calendarBundles.contains($0.bundleId) && !knownIds.contains($0.recId)
            }
            for n in newCalendar {
                scheduleMeetingReminders(for: n)
            }
            lastNotifications = notifications
            updatePanel(notifications)
        }
    }

    // MARK: - Recordatorios de meeting

    private func scheduleMeetingReminders(for n: AppNotification) {
        guard meetingReminders[n.recId] == nil else { return }

        log("MEETING detectado rec_id=\(n.recId) titl=\(n.title) body=\(n.body)")

        let meetingDate = MeetingDateParser().parse(n.body) ?? n.date
        let now = Date()

        log("MEETING fecha parseada=\(meetingDate) secsToMeeting=\(Int(meetingDate.timeIntervalSince(now)))")

        let secsToMeeting = meetingDate.timeIntervalSince(now)
        let secsToFiveMin = secsToMeeting - 5 * 60

        guard secsToMeeting > 0 else {
            log("MEETING ignorada, ya pasó (secsToMeeting=\(Int(secsToMeeting)))")
            return
        }

        var t5: Timer? = nil
        if secsToFiveMin > 0 {
            t5 = Timer.scheduledTimer(withTimeInterval: secsToFiveMin, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in self?.fireMeetingWarning(title: n.title, minutesLeft: 5) }
            }
        } else if secsToMeeting > 60 {
            let minsLeft = max(1, Int(secsToMeeting / 60))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                Task { @MainActor [weak self] in self?.fireMeetingWarning(title: n.title, minutesLeft: minsLeft) }
            }
        }

        let t0 = Timer.scheduledTimer(withTimeInterval: secsToMeeting, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.fireMeetingNow(title: n.title) }
        }

        meetingReminders[n.recId] = MeetingReminder(
            notifId: n.recId, title: n.title,
            fiveMinTimer: t5 ?? t0,
            zeroMinTimer: t0
        )
    }

    private func fireMeetingWarning(title: String, minutesLeft: Int) {
        log("MEETING aviso \(minutesLeft) min para: \(title)")
        triggerAlert(cycles: 4)
        showMeetingBanner(text: "⏰ \(title)", detail: "Empieza en \(minutesLeft) minutos")
    }

    private func fireMeetingNow(title: String) {
        log("MEETING ahora: \(title)")
        triggerCrazy()
        showMeetingBanner(text: "🔴 \(title)", detail: "¡Ahora!")
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
            Task { @MainActor [weak self] in self?.stepAnimation() }
        }
    }

    private func stepAnimation() {
        if crazyMode {
            animFrame = (animFrame + 1) % crazySequence.count
            setFrame(crazySequence[animFrame])
        } else if isAlertMode {
            animFrame = (animFrame + 1) % alertSequence.count
            if animFrame == 0 { alertCycles += 1 }
            if alertCycles >= alertCyclesTarget && !debugLoopMode {
                isAlertMode = false
                alertCycles = 0
                animTimer?.invalidate()
                animTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                    Task { @MainActor [weak self] in self?.stepAnimation() }
                }
            } else if debugLoopMode {
                alertCycles = 0  // resetear para loop infinito
            }
            setFrame(alertSequence[animFrame])
        } else {
            animFrame = (animFrame + 1) % idleSequence.count
            setFrame(idleSequence[animFrame])
            idleStepCount += 1
            if idleStepCount >= Self.idleStepsBeforeJump {
                idleStepCount = 0
                // 1 de cada 3 veces hace boring, el resto salta
                if Int.random(in: 0..<3) == 0 {
                    triggerBoring()
                } else {
                    triggerIdleJump()
                }
            }
        }
    }

    private func setFrame(_ frame: SpriteFrame) {
        octopusView.setFrame(frame)
    }

    func triggerAlert(cycles: Int = 2) {
        crazyMode = false
        alertCyclesTarget = cycles
        isAlertMode = true
        alertCycles = 0
        animFrame = 0
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stepAnimation() }
        }
    }

    func triggerCrazy() {
        crazyMode = true
        isAlertMode = true
        alertCycles = 0
        animFrame = 0
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.stepAnimation() }
        }
    }

    func triggerBoring() {
        crazyMode = false
        isAlertMode = true
        alertCyclesTarget = debugLoopMode ? 999 : 1
        alertCycles = 0
        animFrame = 0
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.animFrame += 1
                if self.animFrame >= Sprite.boring.count {
                    self.animFrame = 0
                    self.alertCycles += 1
                    if self.alertCycles >= self.alertCyclesTarget && !self.debugLoopMode {
                        self.isAlertMode = false
                        self.alertCycles = 0
                        self.animTimer?.invalidate()
                        self.startAnimation()
                        return
                    }
                }
                self.setFrame(Sprite.boring[self.animFrame])
            }
        }
        setFrame(Sprite.boring[0])
    }

    private func triggerIdleJump() {
        // Decidir dirección según posición actual
        let goLeft: Bool
        if jumpOffset <= 0 {
            goLeft = true
        } else if jumpOffset >= Self.maxJumpsLeft {
            goLeft = false
        } else {
            goLeft = Bool.random()
        }
        if goLeft {
            triggerJumpLeft(idle: true)
        } else {
            triggerJumpRight(idle: true)
        }
    }

    private func finishJump(wentLeft: Bool) {
        if wentLeft { jumpOffset += 1 } else { jumpOffset = max(0, jumpOffset - 1) }
        octopusView.mirrored = false
        isAlertMode = false
        alertCycles = 0
        animTimer?.invalidate()
        startAnimation()
    }

    func triggerJumpLeft() { triggerJumpLeft(idle: false) }
    func triggerJumpLeft(idle: Bool) {
        octopusView.mirrored = true
        crazyMode = false
        isAlertMode = true
        alertCyclesTarget = debugLoopMode ? 999 : 1
        alertCycles = 0
        animFrame = 0
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.animFrame += 1
                if self.animFrame >= Sprite.jumpLeft.count {
                    self.animFrame = 0
                    self.alertCycles += 1
                    if self.alertCycles >= self.alertCyclesTarget && !self.debugLoopMode {
                        if idle { self.finishJump(wentLeft: true) } else { self.stopCrazy() }
                        return
                    }
                }
                self.setFrame(Sprite.jumpLeft[self.animFrame])
                if self.animFrame >= 6, let win = self.octopusWindow, let screen = NSScreen.main {
                    let movingFrames = CGFloat(Sprite.jumpLeft.count - 6)
                    let step: CGFloat = 80.0 / movingFrames
                    let newX = max(win.frame.origin.x - step, screen.visibleFrame.minX)
                    win.setFrameOrigin(NSPoint(x: newX, y: win.frame.origin.y))
                }
            }
        }
        setFrame(Sprite.jumpLeft[0])
    }

    func triggerJumpRight() { triggerJumpRight(idle: false) }
    func triggerJumpRight(idle: Bool) {
        crazyMode = false
        isAlertMode = true
        alertCyclesTarget = debugLoopMode ? 999 : 1
        alertCycles = 0
        animFrame = 0
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.animFrame += 1
                if self.animFrame >= Sprite.jumpRight.count {
                    self.animFrame = 0
                    self.alertCycles += 1
                    if self.alertCycles >= self.alertCyclesTarget && !self.debugLoopMode {
                        if idle { self.finishJump(wentLeft: false) } else { self.stopCrazy() }
                        return
                    }
                }
                self.setFrame(Sprite.jumpRight[self.animFrame])
                // Mover la ventana a la derecha: 80px distribuidos en los frames a partir del 3
                if self.animFrame >= 6, let win = self.octopusWindow, let screen = NSScreen.main {
                    let movingFrames = CGFloat(Sprite.jumpRight.count - 6)
                    let step: CGFloat = 80.0 / movingFrames
                    let newX = min(win.frame.origin.x + step, screen.visibleFrame.maxX - win.frame.width)
                    win.setFrameOrigin(NSPoint(x: newX, y: win.frame.origin.y))
                }
            }
        }
        setFrame(Sprite.jumpRight[0])
    }

    func stopCrazy() {
        guard crazyMode || isAlertMode else { return }
        crazyMode = false
        isAlertMode = false
        alertCycles = 0
        idleStepCount = 0
        octopusView.mirrored = false
        animTimer?.invalidate()
        startAnimation()
    }

    // MARK: - Panel debug

    func showDebugPanel() {
        debugPanel?.orderOut(nil)

        let pw: CGFloat = 380
        let ph: CGFloat = 52

        let win = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: pw, height: ph),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered, defer: false
        )
        win.level = .floating
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]

        let bg = NSView()
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor(white: 0.10, alpha: 0.93).cgColor
        bg.layer?.cornerRadius = 10
        bg.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        func makeBtn(_ title: String, action: Selector) -> NSTextField {
            let label = NSTextField(labelWithString: title)
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .white
            label.alignment = .center
            label.wantsLayer = true
            label.layer?.backgroundColor = NSColor(red: 0.35, green: 0.20, blue: 0.55, alpha: 1).cgColor
            label.layer?.cornerRadius = 5
            label.isSelectable = false
            // Usamos un click gesture
            let click = NSClickGestureRecognizer(target: self, action: action)
            label.addGestureRecognizer(click)
            label.widthAnchor.constraint(equalToConstant: 46).isActive = true
            label.heightAnchor.constraint(equalToConstant: 24).isActive = true
            return label
        }

        stack.addArrangedSubview(makeBtn("normal", action: #selector(debugNormal)))
        stack.addArrangedSubview(makeBtn("drag",   action: #selector(debugDrag)))
        stack.addArrangedSubview(makeBtn("alert",  action: #selector(debugAlert)))
        stack.addArrangedSubview(makeBtn("jump",   action: #selector(debugJump)))
        stack.addArrangedSubview(makeBtn("jump←",  action: #selector(debugJumpLeft)))
        stack.addArrangedSubview(makeBtn("boring", action: #selector(debugBoring)))

        let closeBtn = makeBtn("✕", action: #selector(closeDebugPanel))
        closeBtn.layer?.backgroundColor = NSColor(red: 0.5, green: 0.15, blue: 0.15, alpha: 1).cgColor
        stack.addArrangedSubview(closeBtn)

        let container = NSView()
        container.addSubview(bg)
        container.addSubview(stack)
        win.contentView = container

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: container.topAnchor),
            bg.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        if let of = octopusWindow?.frame, let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let wx = min(of.minX + of.width/2 - pw/2, sf.maxX - pw - 4)
            let wy = of.maxY + 8
            win.setFrameOrigin(NSPoint(x: max(wx, sf.minX+4), y: wy))
        }
        win.delegate = self
        win.makeKeyAndOrderFront(nil)
        debugPanel = win
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.debugLoopMode = false
            self?.stopCrazy()
        }
    }

    @objc private func closeClaudeBubble() {
        claudeBubble?.orderOut(nil)
        stopCrazy()
    }

    @objc private func closeDebugPanel() {
        debugLoopMode = false
        stopCrazy()
        debugPanel?.orderOut(nil)
    }

    @objc private func debugNormal() {
        debugLoopMode = false
        stopCrazy()
    }

    @objc private func debugDrag() {
        debugLoopMode = true
        triggerCrazy()
    }

    @objc private func debugAlert() {
        debugLoopMode = true
        triggerAlert(cycles: 999)
    }

    @objc private func debugJump() {
        debugLoopMode = true
        triggerJumpRight()
    }

    @objc private func debugJumpLeft() {
        debugLoopMode = true
        triggerJumpLeft()
    }

    @objc private func debugBoring() {
        debugLoopMode = true
        triggerBoring()
    }

    // MARK: - Globo de Claude

    func showClaudeBubble(message: String) {
        claudeBubble?.orderOut(nil)
        triggerAlert(cycles: 999)

        let bw: CGFloat = 280
        let padding: CGFloat = 12
        let font = NSFont.systemFont(ofSize: 12)

        // Calcular altura según el texto
        let maxW = bw - padding * 2 - 20  // 20 para el botón ✕
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textH = (message as NSString).boundingRect(
            with: CGSize(width: maxW, height: 9999),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs
        ).height
        let bh = max(52, textH + padding * 2)

        let win = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: bw, height: bh),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered, defer: false
        )
        win.level = .floating
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = true
        win.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        win.isMovableByWindowBackground = true

        let bg = NSView()
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor(red: 0.10, green: 0.18, blue: 0.30, alpha: 0.96).cgColor
        bg.layer?.cornerRadius = 10
        bg.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(wrappingLabelWithString: message)
        label.font = font
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false

        let closeBtn = NSButton(title: "✕", target: nil, action: nil)
        closeBtn.bezelStyle = .inline
        closeBtn.isBordered = false
        closeBtn.font = .systemFont(ofSize: 11, weight: .bold)
        closeBtn.contentTintColor = NSColor.white.withAlphaComponent(0.6)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(bg)
        container.addSubview(label)
        container.addSubview(closeBtn)
        win.contentView = container

        closeBtn.target = self
        closeBtn.action = #selector(closeClaudeBubble)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: container.topAnchor),
            bg.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            closeBtn.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            closeBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            closeBtn.widthAnchor.constraint(equalToConstant: 16),
            closeBtn.heightAnchor.constraint(equalToConstant: 16),

            label.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            label.trailingAnchor.constraint(equalTo: closeBtn.leadingAnchor, constant: -4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding),
        ])

        if let of = octopusWindow?.frame, let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let wx = min(of.minX + of.width / 2 - bw / 2, sf.maxX - bw - 4)
            let wy = of.maxY + 8
            win.setFrameOrigin(NSPoint(x: max(wx, sf.minX + 4), y: wy))
        }
        win.makeKeyAndOrderFront(nil)
        claudeBubble = win
    }

    // MARK: - Banner de meeting

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
        win.isMovableByWindowBackground = true

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

        if let of = octopusWindow?.frame, let screen = NSScreen.main {
            let sf = screen.visibleFrame
            let bx = min(of.minX + of.width / 2 - bw / 2, sf.maxX - bw - 4)
            let by = of.maxY + 8
            win.setFrameOrigin(NSPoint(x: max(bx, sf.minX + 4), y: by))
        }

        win.makeKeyAndOrderFront(nil)
        bannerWindow = win

        if !crazyMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak win] in
                win?.orderOut(nil)
            }
        }
    }
}
