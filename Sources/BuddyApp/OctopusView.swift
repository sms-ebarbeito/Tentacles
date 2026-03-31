import Cocoa

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
