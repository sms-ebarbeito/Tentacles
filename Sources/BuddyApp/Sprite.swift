import CoreGraphics

enum Sprite {
    // Ventana: suficientemente grande para el sprite más alto (crazy ~98px * 2x = 196px)
    static let displaySize = CGSize(width: 160, height: 200)
    static let scale: CGFloat = 1.5

    // Coordenadas exactas en el PNG (y=0 = parte superior)

    // Idle: band_00, criatura de pie
    static let idle: [CGRect] = [
        CGRect(x: 2,  y: 11, width: 34, height: 56),
        CGRect(x: 45, y: 11, width: 34, height: 56),
        CGRect(x: 84, y: 11, width: 34, height: 56),
        CGRect(x: 45, y: 11, width: 34, height: 56),
    ]

    // Alert: band_12, brazos levantados (y=1082 da margen para la cabeza)
    static let alert: [CGRect] = [
        CGRect(x: 13,  y: 1082, width: 32, height: 72),
        CGRect(x: 89,  y: 1082, width: 32, height: 72),
        CGRect(x: 150, y: 1082, width: 32, height: 72),
        CGRect(x: 192, y: 1082, width: 48, height: 72),
    ]

    // Squish: band_04, aplastado
    static let squish = CGRect(x: 2, y: 315, width: 23, height: 17)

    // Crazy: band_08, animación completa (11 frames)
    static let crazy: [CGRect] = [
        CGRect(x: 2,   y: 664, width: 40, height: 97),
        CGRect(x: 52,  y: 664, width: 45, height: 97),
        CGRect(x: 108, y: 664, width: 43, height: 97),
        CGRect(x: 164, y: 664, width: 40, height: 97),
        CGRect(x: 221, y: 664, width: 85, height: 97),
        CGRect(x: 322, y: 664, width: 80, height: 97),
        CGRect(x: 425, y: 664, width: 44, height: 97),
        CGRect(x: 480, y: 664, width: 50, height: 97),
        CGRect(x: 539, y: 664, width: 36, height: 97),
        CGRect(x: 587, y: 664, width: 35, height: 97),
        CGRect(x: 643, y: 664, width: 36, height: 97),
    ]
}
