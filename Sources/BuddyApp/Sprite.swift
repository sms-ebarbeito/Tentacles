import Cocoa

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
