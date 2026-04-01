import Cocoa

class OctopusView: NSView {
    var currentRect: CGRect = Sprite.idle[0]
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

    func setFrame(_ rect: CGRect) {
        currentRect = rect
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let sheet = Self.sheet else { return }

        let s = Sprite.scale
        let drawW = currentRect.width * s
        let drawH = currentRect.height * s
        // Centrado horizontalmente, anclado a la base de la ventana
        let drawX = (bounds.width - drawW) / 2
        let destRect = NSRect(x: drawX, y: 0, width: drawW, height: drawH)

        // NSImage tiene y=0 abajo; el PNG tiene y=0 arriba → invertir Y
        let flipped = CGRect(
            x: currentRect.minX,
            y: sheet.size.height - currentRect.maxY,
            width: currentRect.width,
            height: currentRect.height
        )
        sheet.draw(in: destRect, from: flipped, operation: .copy, fraction: 1.0)
    }

    // MARK: - Mouse

    private var dragStart: NSPoint?
    private var windowOriginAtDragStart: NSPoint?
    private var didDrag = false

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
