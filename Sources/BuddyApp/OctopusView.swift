import Cocoa

class OctopusView: NSView {
    var currentFrame: SpriteFrame = Sprite.idle[0]
    private weak var controller: BuddyController?

    static let sheet: NSImage? = {
        guard let url = Bundle.module.url(forResource: "tentacles-sprites", withExtension: "png"),
              let img = NSImage(contentsOf: url) else { return nil }
        return img
    }()

    init(controller: BuddyController) {
        self.controller = controller
        super.init(frame: NSRect(origin: .zero, size: Sprite.displaySize))
    }
    required init?(coder: NSCoder) { fatalError() }

    func setFrame(_ frame: SpriteFrame) {
        currentFrame = frame
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let sheet = Self.sheet else { return }

        let s = Sprite.scale
        let r = currentFrame.rect
        let drawW = r.width * s
        let drawH = r.height * s
        // Centro el rect horizontalmente y corrijo por offset del pie en x
        let drawX = (bounds.width - drawW) / 2 - currentFrame.ax * s
        // Pie siempre en groundLevel desde el fondo de la ventana
        let drawY = Sprite.groundLevel - currentFrame.ay * s
        let destRect = NSRect(x: drawX, y: drawY, width: drawW, height: drawH)

        // NSImage tiene y=0 abajo; el PNG tiene y=0 arriba → invertir Y
        let flipped = CGRect(
            x: r.minX,
            y: sheet.size.height - r.maxY,
            width: r.width,
            height: r.height
        )
        sheet.draw(in: destRect, from: flipped, operation: .copy, fraction: 1.0)
    }

    // MARK: - Mouse

    private var dragStart: NSPoint?
    private var windowOriginAtDragStart: NSPoint?
    private var didDrag = false

    override func rightMouseDown(with event: NSEvent) {
        controller?.showDebugPanel()
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        windowOriginAtDragStart = window?.frame.origin
        didDrag = false
        controller?.triggerCrazy()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let origin = windowOriginAtDragStart,
              let win = window else { return }
        didDrag = true
        let current = NSEvent.mouseLocation
        win.setFrameOrigin(NSPoint(
            x: origin.x + current.x - start.x,
            y: origin.y + current.y - start.y
        ))
    }

    override func mouseUp(with event: NSEvent) {
        controller?.stopCrazy()
        if !didDrag {
            controller?.togglePanel()
        }
        dragStart = nil
        windowOriginAtDragStart = nil
        didDrag = false
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
